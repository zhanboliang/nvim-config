return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    local colors = {
      orange      = "#CE422B",
      insert      = "#E8845A",
      violet      = "#7A4E3E",
      yellow      = "#FABB3E",
      red         = "#A0522D",
      fg          = "#E8DDD4",
      bg          = "#1C0F0A",
      inactive_bg = "#1d1714",
      inactive_fg = "#7b818c",
      location_bg = "#3D1F14",
      location_fg = "#E8DDD4",
    }

    local fixed_z = { bg = colors.location_bg, fg = colors.location_fg, gui = "bold" }
    local fixed_y = { bg = "#2a1810", fg = colors.yellow }

    local my_lualine_theme = {
      normal = {
        a = { bg = colors.orange, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
        x = { bg = colors.bg, fg = colors.fg },
        y = fixed_y,
        z = fixed_z,
      },
      insert = {
        a = { bg = colors.insert, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
        x = { bg = colors.bg, fg = colors.fg },
        y = fixed_y,
        z = fixed_z,
      },
      visual = {
        a = { bg = colors.violet, fg = colors.fg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
        x = { bg = colors.bg, fg = colors.fg },
        y = fixed_y,
        z = fixed_z,
      },
      command = {
        a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
        x = { bg = colors.bg, fg = colors.fg },
        y = fixed_y,
        z = fixed_z,
      },
      replace = {
        a = { bg = colors.red, fg = colors.fg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
        x = { bg = colors.bg, fg = colors.fg },
        y = fixed_y,
        z = fixed_z,
      },
      inactive = {
        a = { bg = colors.inactive_bg, fg = colors.inactive_fg, gui = "bold" },
        b = { bg = colors.inactive_bg, fg = colors.inactive_fg },
        c = { bg = colors.inactive_bg, fg = colors.inactive_fg },
        x = { bg = colors.inactive_bg, fg = colors.inactive_fg },
        y = { bg = colors.inactive_bg, fg = colors.inactive_fg },
        z = { bg = colors.inactive_bg, fg = colors.inactive_fg },
      },
    }

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
    -- 图标用 Devicons 私用区码点的 UTF-8 字节序列（避免拷贝时丢失）
    -- color 字段保留备用（当前不应用）
    local lang_badges = {
      zig        = { icon = "\xee\x9a\xa9", color = "#F69A1B" }, -- U+E6A9 devicon-zig
      rust       = { icon = "\xee\x9a\x8b", color = "#DEA584" }, -- U+E68B devicon-rust
      go         = { icon = "\xee\x98\xa7", color = "#519ABA" }, -- U+E627
      typescript = { icon = "\xee\x98\xa8", color = "#519ABA" }, -- U+E628
      javascript = { icon = "\xee\x98\x8c", color = "#CBCB41" }, -- U+E60C
      python     = { icon = "\xee\x98\x86", color = "#FFE873" }, -- U+E606
      java       = { icon = "\xee\x9c\xb8", color = "#CC3E44" }, -- U+E738
      kotlin     = { icon = "\xee\x98\xb4", color = "#7F52FF" }, -- U+E634
      ruby       = { icon = "\xee\x9e\x91", color = "#701516" }, -- U+E791
      php        = { icon = "\xee\x98\x88", color = "#A074C4" }, -- U+E608
      swift      = { icon = "\xee\x9d\x95", color = "#E37933" }, -- U+E755
      dart       = { icon = "\xee\x9e\x98", color = "#03589C" }, -- U+E798
      elixir     = { icon = "\xee\x98\xad", color = "#A074C4" }, -- U+E62D
      scala      = { icon = "\xee\x9c\xb7", color = "#CC3E44" }, -- U+E737
      haskell    = { icon = "\xee\x98\x9f", color = "#A074C4" }, -- U+E61F
      cpp        = { icon = "\xee\x98\x9d", color = "#519ABA" }, -- U+E61D
      c          = { icon = "\xee\x98\x9e", color = "#599EFF" }, -- U+E61E
    }

    -- 颜色混合（模拟 alpha 透明度）：把 hex_fg 按 alpha 比例混进 hex_bg
    -- alpha 0.0=完全暗背景, 1.0=纯品牌色, 0.25=轻染色
    local function blend(hex_fg, hex_bg, alpha)
      local function parse(h)
        return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
      end
      local r1, g1, b1 = parse(hex_fg)
      local r2, g2, b2 = parse(hex_bg)
      local r = math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5)
      local g = math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5)
      local bb = math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
      return string.format("#%02X%02X%02X", r, g, bb)
    end

    -- 图标组件
    local function project_icon()
      local ft = detect_project()
      local b = ft and lang_badges[ft]
      return b and b.icon or ""
    end

    -- 实底 badge：bg 用品牌色、fg 用暗底色 → 一眼可见（比原来 25% 轻染色更显眼）。
    -- 想换回轻染色版本，把下面那行改成：
    --   badge_color_cache[ft] = { fg = b.color, bg = blend(b.color, colors.bg, 0.25), gui = "bold" }
    local badge_color_cache = {}
    local function project_badge_color()
      local ft = detect_project()
      local b = ft and lang_badges[ft]
      if not b then return {} end
      if badge_color_cache[ft] then return badge_color_cache[ft] end
      badge_color_cache[ft] = { fg = colors.bg, bg = b.color, gui = "bold" }
      return badge_color_cache[ft]
    end

    -- 文件类型名（共用 badge 背景）；只对已知语言显示，未知 filetype 不显示裸文字
    local function project_ft()
      local ft = detect_project()
      return (ft and lang_badges[ft]) and ft or ""
    end

    lualine.setup({
      options = {
        theme = my_lualine_theme,
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
            color = { bg = colors.bg },
            symbols = { error = "E", warn = "W", info = "I", hint = "H" },
          },
          { "progress" },
        },
        lualine_z = {
          { "location" },
        },
      },
    })

    vim.api.nvim_set_hl(0, "StatusLine", { bg = colors.bg, fg = colors.fg })
    vim.api.nvim_set_hl(0, "StatusLineNC", { bg = colors.inactive_bg, fg = colors.inactive_fg })
  end,
}