return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    -- 500ms 对 leader 链来说太紧, 经常出现"按空格变成光标右移"的现象 (空格 timeout 后落回默认行为).
    -- 1000ms 给手指足够缓冲, 又不至于让 chord 弹菜单变慢.
    vim.o.timeoutlen = 1000
    vim.o.ttimeoutlen = 10 -- 终端 escape 序列超时，避免影响 insert 模式按键响应
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
}
