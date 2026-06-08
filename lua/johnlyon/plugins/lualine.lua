return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local devicons = require("nvim-web-devicons")

    -- 项目标记 -> 语言信息（按优先级；前面的优先匹配）
    local project_markers = {
      { files = { "build.zig" },                                              ft = "zig",        name = "Zig" },
      { files = { "Cargo.toml" },                                             ft = "rust",       name = "Rust" },
      { files = { "go.mod" },                                                 ft = "go",         name = "Go" },
      { files = { "tsconfig.json" },                                          ft = "typescript", name = "TypeScript" },
      { files = { "package.json" },                                           ft = "javascript", name = "JavaScript" },
      { files = { "pyproject.toml", "setup.py", "requirements.txt", "Pipfile" }, ft = "python",  name = "Python" },
      { files = { "build.gradle.kts" },                                       ft = "kotlin",     name = "Kotlin" },
      { files = { "pom.xml", "build.gradle" },                                ft = "java",       name = "Java" },
      { files = { "Gemfile" },                                                ft = "ruby",       name = "Ruby" },
      { files = { "composer.json" },                                          ft = "php",        name = "PHP" },
      { files = { "Package.swift" },                                          ft = "swift",      name = "Swift" },
      { files = { "pubspec.yaml" },                                           ft = "dart",       name = "Dart" },
      { files = { "mix.exs" },                                                ft = "elixir",     name = "Elixir" },
      { files = { "build.sbt" },                                              ft = "scala",      name = "Scala" },
      { files = { "stack.yaml" },                                             ft = "haskell",    name = "Haskell" },
      { files = { "CMakeLists.txt" },                                         ft = "cpp",        name = "C++" },
      { files = { "Makefile" },                                               ft = "c",          name = "C" },
    }

    -- 缓存：把 cwd 的检测结果缓存，避免每次重绘都做文件系统查询
    local detect_cache = { cwd = nil, ft = nil, name = nil }

    local function detect_project()
      local cwd = vim.fn.getcwd()
      if detect_cache.cwd == cwd then
        return detect_cache.ft, detect_cache.name
      end

      -- 起点：当前 buffer 的所在目录；buffer 没文件时用 cwd
      local bufname = vim.api.nvim_buf_get_name(0)
      local start_dir = (bufname ~= "" and vim.fn.filereadable(bufname) == 1)
        and vim.fs.dirname(bufname) or cwd

      local all_files = {}
      for _, m in ipairs(project_markers) do
        for _, f in ipairs(m.files) do table.insert(all_files, f) end
      end

      local found = vim.fs.find(all_files, {
        upward = true,
        path = start_dir,
        stop = vim.loop.os_homedir(),
        type = "file",
      })

      local ft, name = nil, nil
      if found and found[1] then
        local base = vim.fs.basename(found[1])
        for _, m in ipairs(project_markers) do
          for _, f in ipairs(m.files) do
            if f == base then ft, name = m.ft, m.name; break end
          end
          if ft then break end
        end
      end

      -- 没匹配到项目根标记 → 回落到当前 buffer 的 filetype，
      -- 这样在项目外单独打开一个 .py / .rs 也能显示语言徽章。
      -- （BufEnter 会让 cwd 缓存失效，切 buffer 时按各自 filetype 重算）
      if not ft then ft = vim.bo.filetype end

      detect_cache = { cwd = cwd, ft = ft, name = name }
      return ft, name
    end

    -- 把检测结果缓存的 cwd 失效，让下一次绘制重新探测
    vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
      callback = function() detect_cache.cwd = nil end,
    })

    -- 显式 filetype -> { icon, color } 徽章表
    -- 语言图标 / 颜色不再手写 Nerd Font 码点(裸码点会随字体版本被重映射 → 指到旧字形变丑),
    -- 改成运行时从 nvim-web-devicons 按检测到的项目 filetype 取,跟着字体 / devicons 升级自动更新。
    --
    -- 唯一例外:Rust。devicons 给 .rs 用的也是 U+E68B(nf-dev-rust),老槽位渲染成发糊的齿轮;
    -- 只把【字形】覆盖成清晰的 nf-md-language_rust(U+F1617),【颜色等其它字段沿用 devicons
    -- 自己分配的】——读出 devicons 原本的 .rs 配置、只改 icon 一项回写,不写死任何颜色。
    local rs_cfg = vim.tbl_extend("force", {}, devicons.get_icons_by_extension()["rs"] or {})
    rs_cfg.icon = "\u{f1617}"
    devicons.set_icon({ rs = rs_cfg })

    -- 按品牌色亮度自动选深/浅文字,保证 badge 上的字在任何语言色块上都清晰可读。
    local function readable_fg(hex)
      local r = tonumber(hex:sub(2, 3), 16)
      local g = tonumber(hex:sub(4, 5), 16)
      local b = tonumber(hex:sub(6, 7), 16)
      local lum = 0.299 * r + 0.587 * g + 0.114 * b
      return lum > 140 and "#11121a" or "#e8e8e8"
    end

    -- 图标组件:字形从 devicons 按检测到的项目 ft 取(devicons 认不出就不显示)
    local function project_icon()
      local ft = detect_project()
      if not ft or ft == "" then return "" end
      local glyph = devicons.get_icon_by_filetype(ft, { default = false })
      return glyph or ""
    end

    -- 实底 badge：bg 用 devicons 的语言品牌色(故意不跟随主题——一眼认出在写什么语言),
    -- fg 按亮度自动取深/浅保证可读。颜色也从 devicons 取,不再手写。
    local badge_color_cache = {}
    local function project_badge_color()
      local ft = detect_project()
      if not ft or ft == "" then return {} end
      if badge_color_cache[ft] then return badge_color_cache[ft] end
      local _, color = devicons.get_icon_colors_by_filetype(ft, { strict = false, default = false })
      if not color then return {} end
      local c = { fg = readable_fg(color), bg = color, gui = "bold" }
      badge_color_cache[ft] = c
      return c
    end

    -- 文件类型名(共用 badge 背景);只对 devicons 认识的语言显示
    local function project_ft()
      local ft = detect_project()
      if not ft or ft == "" then return "" end
      return devicons.get_icon_name_by_filetype(ft) and ft or ""
    end

    lualine.setup({
      options = {
        -- "auto"：模式色块 + 底栏背景都从当前 colorscheme 生成,换主题自动跟随,
        -- 不再写死暖色。语言徽章(lualine_b)仍用品牌色,见 project_badge_color。
        theme = "auto",
        globalstatus = true,
        section_separators = { left = "", right = "" },
        component_separators = { left = "│", right = "│" },
      },
      sections = {
        lualine_b = {
          {
            project_icon,
            color = project_badge_color,
            padding = { left = 1, right = 0 },
            separator = "",
          },
          {
            project_ft,
            color = project_badge_color,
            padding = { left = 1, right = 1 },
          },
          "branch",
          "diff",
        },
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "encoding" },
          { "fileformat" },
        },
        lualine_y = {
          {
            "diagnostics",
            symbols = { error = "E", warn = "W", info = "I", hint = "H" },
          },
          { "progress" },
        },
        lualine_z = {
          { "location" },
        },
      },
    })
  end,
}