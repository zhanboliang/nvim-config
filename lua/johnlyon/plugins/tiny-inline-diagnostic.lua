-- 把 LSP 诊断(报错/警告)的「信息文字」自动显示在光标所在行旁边的圆角气泡里,
-- 按严重级别上色、长信息自动换行 —— 不用再按 <leader>d 弹浮窗才知道错在哪。
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "LspAttach",
  priority = 1000,
  config = function()
    -- 关掉内置行尾 virtual_text,否则气泡 + 行尾文字会重影显示两遍
    vim.diagnostic.config({ virtual_text = false })
    require("tiny-inline-diagnostic").setup({
      preset = "modern", -- 可选: modern / classic / minimal / powerline / ghost / simple
      options = {
        show_source = true,        -- 末尾标出来源(如 [rustc] / [pyright])
        multilines = { enabled = true }, -- 多行错误也完整显示
      },
    })
  end,
}
