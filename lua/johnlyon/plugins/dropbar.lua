-- 顶部面包屑:显示文件路径 + 当前光标所在的 struct / 函数 / 模块,
-- 正好填上删掉 bufferline 后空出来的顶栏。用你已有的 LSP + treesitter,无需额外依赖。
-- <leader>; 进入键盘 pick 模式,直接跳到某层符号。
return {
  "Bekaboo/dropbar.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("dropbar").setup({
      bar = {
        -- 复刻 dropbar 默认 enable 判定,只把「终端」那条从「显示」改成「不显示」。
        -- 默认会对终端 buffer 专门开面包屑(上游 configs.lua),我们不要;
        -- 其余行为保留:help / 大文件(>1MB)/ 特殊窗口 不显示,
        -- 普通文件在 markdown / 有 treesitter parser / 有 LSP 时才显示。
        enable = function(buf, win, _)
          buf = vim._resolve_bufnr(buf)
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ""
            or vim.wo[win].winbar ~= ""
            or vim.bo[buf].ft == "help"
            or vim.bo[buf].bt == "terminal" -- ← 终端不显示面包屑
          then
            return false
          end

          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stat and stat.size > 1024 * 1024 then
            return false
          end

          return vim.bo[buf].ft == "markdown"
            or (function()
              local ok, parser = pcall(vim.treesitter.get_parser, buf)
              return ok and parser ~= nil
            end)()
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = buf,
              method = "textDocument/documentSymbol",
            }))
        end,
      },
    })
    vim.keymap.set("n", "<leader>;", require("dropbar.api").pick, { desc = "Dropbar pick mode" })
  end,
}
