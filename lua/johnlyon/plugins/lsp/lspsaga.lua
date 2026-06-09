return {
  "nvimdev/lspsaga.nvim",
  event = "LspAttach",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("lspsaga").setup({
      ui = {
        border = "rounded",
        code_action = "",
      },
      scroll_preview = {
        scroll_down = "<C-d>",
        scroll_up = "<C-u>",
      },
      hover = {
        max_width = 0.6,
        max_height = 0.5,
      },
      lightbulb = {
        enable = false,
      },
      symbol_in_winbar = {
        enable = false,
      },
    })

    -- 智能滚动：若 hover / 诊断 浮窗存在则滚动它，否则走默认翻页
    -- 涵盖：
    --   - lspsaga hover (ft = sagahover / markdown)
    --   - vim.diagnostic.open_float （ft = "" + buftype = nofile，诊断浮窗）
    --   - 其他 LSP info 类浮窗（lspinfo）
    -- 排除当前窗口本身（避免 floating 编辑器自己滚自己）
    local function find_hover_win()
      local cur = vim.api.nvim_get_current_win()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= cur then
          local cfg = vim.api.nvim_win_get_config(win)
          if cfg.relative ~= nil and cfg.relative ~= "" then
            local buf = vim.api.nvim_win_get_buf(win)
            local ft = vim.bo[buf].filetype
            local bt = vim.bo[buf].buftype
            if ft == "sagahover" or ft == "markdown" or ft == "lspinfo"
               or (ft == "" and bt == "nofile") then
              return win
            end
          end
        end
      end
    end

    local function smart_scroll(noice_delta, keys, fallback)
      return function()
        -- 1) noice 接管的 hover / signature 弹窗(你的 K 文档就是 noice 渲染的)→
        --    用 noice 自己的滚动 API。这样按【一下】K 之后直接 <C-f>/<C-b> 就能滚文档,
        --    不用再按一下 K 进浮窗。
        local ok, scrolled = pcall(function()
          return require("noice.lsp").scroll(noice_delta)
        end)
        if ok and scrolled then
          return
        end
        -- 2) lspsaga / 标准浮窗(含 <leader>d 诊断浮窗)→ 在浮窗里发滚动键
        local win = find_hover_win()
        if win then
          vim.api.nvim_win_call(win, function()
            vim.cmd("normal! " .. keys)
          end)
          return
        end
        -- 3) 都没有 → 翻 buffer
        vim.cmd("normal! " .. fallback)
      end
    end

    -- \x06 = ^F, \x02 = ^B, \x04 = ^D, \x15 = ^U;noice 用 ±4 行
    vim.keymap.set("n", "<C-f>", smart_scroll(4, "\x04", "\x06"), { desc = "Scroll hover/doc / page down" })
    vim.keymap.set("n", "<C-b>", smart_scroll(-4, "\x15", "\x02"), { desc = "Scroll hover/doc / page up" })
  end,
}
