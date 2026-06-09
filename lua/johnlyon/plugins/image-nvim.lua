-- 在 nvim buffer 里渲染【真·图片】(Ghostty 实现了 kitty 图形协议)。
-- 主要用途:Markdown 里的 ![](图片路径) 直接内联显示出来。
-- 依赖:ImageMagick(brew install imagemagick)—— 用 magick 命令行处理图片,不用 luarocks。
--
-- 注:看「单张图片文件」用终端的 chafa 更稳;image.nvim 强在「图嵌在 nvim/markdown 里」。
-- 和 render-markdown 共存:render-markdown 管文字样式,image.nvim 渲染真实图片。
return {
  "3rd/image.nvim",
  event = "VeryLazy",
  opts = {
    backend = "kitty", -- Ghostty 走 kitty 图形协议
    processor = "magick_cli", -- 用 magick 命令行(只需 brew install imagemagick)
    integrations = {
      markdown = {
        enabled = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown" },
      },
    },
    max_height_window_percentage = 50, -- 图最多占窗口一半高,免得撑满
    window_overlap_clear_enabled = true, -- 被浮窗/补全挡住时先清掉图,避免残影
    editor_only_render_when_focused = true,
  },
}
