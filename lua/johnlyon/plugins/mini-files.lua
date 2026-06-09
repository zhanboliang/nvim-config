-- 浮窗式文件管理器(mini.files):改 buffer 文本即「增删改 / 拷贝移动」,按 = 确认同步。
-- 和 nvim-tree 共存 —— tree 看全局侧栏,mini.files 做快速浮窗增删改。
--
-- 打开:<leader>em(在当前文件所在目录打开并定位到它;再按一次关闭)
-- 窗口里:
--   l / <CR>  进目录 / 打开文件      h  返回上一级       q  关闭
--   =         把你的改动落到磁盘      g?  看全部快捷键
-- 文件操作(都是「改文本 + 按 =」):
--   新建:在空行打文件名(目录名后加 / );  删除:删掉那一行
--   重命名:直接改那行的名字
--   移动 / 拷贝:在某目录里 dd/yy 一个条目 → 进到另一目录 p 粘贴 → = 确认
return {
  "echasnovski/mini.files",
  version = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    {
      "<leader>em",
      function()
        local mf = require("mini.files")
        if mf.close() then return end -- 已开 → 关闭(toggle)
        local name = vim.api.nvim_buf_get_name(0)
        mf.open(name ~= "" and name or vim.fn.getcwd(), true) -- true = 定位到当前文件
      end,
      desc = "File manager (mini.files, float)",
    },
  },
  opts = {
    windows = {
      preview = true,
      width_focus = 35,
      width_preview = 55,
    },
    options = {
      use_as_default_explorer = false, -- 不劫持目录打开,不影响 nvim-tree
    },
  },
}
