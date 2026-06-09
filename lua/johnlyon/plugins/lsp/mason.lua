-- mason —— 瘦身版:纯按命令懒加载,平时启动【完全不加载】。
-- 它只负责「装工具」(:Mason 界面 / :MasonInstall xxx),装好的工具一直在。
--   - 不再依赖 mason-tool-installer(启动自动装/更新的那个 —— 之前 fd 报错、pylint 装一半都是它)
--   - 不再依赖 mason-lspconfig(LSP 已由 lspconfig.lua 的原生 vim.lsp.enable() 配好,多余;
--     还顺带去掉了「automatic_enable 要 exclude rust_analyzer」那个坑)
--   - 「让 nvim 找到 mason / Homebrew 装的工具」的 PATH 设置已挪到 core/options.lua,
--     所以即使 mason 没加载,LSP / 格式化 / lint 也照常能找到工具。
--
-- 装工具:打开 :Mason 按 i 安装,或 :MasonInstall lua-language-server stylua prettier …
return {
	"williamboman/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
	opts = {
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
	},
}
