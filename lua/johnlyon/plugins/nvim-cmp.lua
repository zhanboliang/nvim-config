return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- LSP source
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "hrsh7th/cmp-cmdline", -- source for : / ? cmdline completion (Helix-like)
    "L3MON4D3/LuaSnip", -- snippet engine
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },
  config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")

    local lspkind = require("lspkind")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    -- ===== 让补全弹窗背景跟编辑器背景明显区分(避免糊在一起)=====
    -- 不写死颜色:从当前主题的 Normal 背景算出一个区分色 ——
    -- 深色主题提亮一档、亮色主题压暗一档。切主题时(ColorScheme)自动重算。
    local function shade(hex, amount)
      local r = tonumber(hex:sub(2, 3), 16)
      local g = tonumber(hex:sub(4, 5), 16)
      local b = tonumber(hex:sub(6, 7), 16)
      local dir = (vim.o.background == "light") and -1 or 1
      r = math.max(0, math.min(255, r + amount * dir))
      g = math.max(0, math.min(255, g + amount * dir))
      b = math.max(0, math.min(255, b + amount * dir))
      return string.format("#%02x%02x%02x", r, g, b)
    end

    local function style_pmenu()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
      local bg = normal.bg and string.format("#%06x", normal.bg) or "#1a1a1a"
      vim.api.nvim_set_hl(0, "Pmenu", { bg = shade(bg, 20) })           -- 弹窗主体
      vim.api.nvim_set_hl(0, "PmenuSel", { bg = shade(bg, 50), bold = true }) -- 当前选中项
      vim.api.nvim_set_hl(0, "PmenuSbar", { bg = shade(bg, 12) })       -- 滚动条槽
      vim.api.nvim_set_hl(0, "PmenuThumb", { bg = shade(bg, 70) })      -- 滚动条滑块
      vim.api.nvim_set_hl(0, "FloatBorder", { fg = shade(bg, 80), bg = shade(bg, 20) })
    end

    vim.api.nvim_create_autocmd("ColorScheme", { callback = style_pmenu })
    style_pmenu()

    cmp.setup({
      completion = {
        completeopt = "menu,menuone,preview,noselect",
      },
      window = {
        completion = cmp.config.window.bordered({
          -- 弹窗主体走 Pmenu(上面 style_pmenu 给了区分背景),而不是糊背景的 NormalFloat
          winhighlight = "Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
        }),
        documentation = cmp.config.disable,
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-n>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
      }),
      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        format = lspkind.cmp_format({
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })

    -- ===== Helix 风格的命令行实时补全 =====
    -- 在 / 或 ? 搜索时：从当前 buffer 中实时模糊匹配
    cmp.setup.cmdline({ "/", "?" }, {
      mapping = cmp.mapping.preset.cmdline({
        ["<C-n>"] = { c = cmp.mapping.select_next_item() },
        ["<C-p>"] = { c = cmp.mapping.select_prev_item() },
      }),
      sources = {
        { name = "buffer" },
      },
    })

    -- 在 : 命令行时：实时列出命令、子命令、文件路径
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline({
        ["<C-n>"] = { c = cmp.mapping.select_next_item() },
        ["<C-p>"] = { c = cmp.mapping.select_prev_item() },
      }),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        { name = "cmdline" },
      }),
      matching = { disallow_symbol_nonprefix_matching = false },
    })
  end,
}
