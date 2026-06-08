return {
	"williamboman/mason.nvim",
	cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog", "MasonToolsInstall", "MasonToolsUpdate" },
	event = "VeryLazy",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		local homebrew_bin = "/opt/homebrew/bin"
		if vim.fn.isdirectory(homebrew_bin) == 1 then
			local path_entries = vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })
			local filtered = {}
			for _, entry in ipairs(path_entries) do
				if entry ~= homebrew_bin then
					table.insert(filtered, entry)
				end
			end
			vim.env.PATH = table.concat(vim.list_extend({ homebrew_bin }, filtered), ":")
		end

		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		local lsp_servers = {
			"pyright",
			"html",
			"cssls",
			"ts_ls",
			"jsonls",
			"lua_ls",
			"zls",
			"taplo",
		}

		local mason_packages = {
			"pyright",
			"html-lsp",
			"css-lsp",
			"typescript-language-server",
			"json-lsp",
			"lua-language-server",
			"zls",
			"taplo",
			"stylua",
			"black",
			"isort",
			"eslint_d",
			"prettier",
			-- 注：fd / ripgrep 不放这里 —— mason 仓库没有这两个包(会报
			-- "Cannot find package fd")。它们是通用 CLI,交给 Homebrew 装即可
			-- (brew install fd ripgrep);fzf-lua 会自动用系统 PATH 里的版本。
		}

		mason_lspconfig.setup({
			ensure_installed = lsp_servers,
			-- auto-install configured servers (with lspconfig)
			automatic_installation = true, -- not the same as ensure_installed
			-- mason-lspconfig 2.x 默认 automatic_enable = true，会把 mason 里
			-- 所有装过的服务器自动 enable。rust_analyzer 已经由 rustaceanvim 接管，
			-- 不能让 mason 再起一个，否则 :LspInfo 里会有两个 rust-analyzer 同时跑，
			-- gf / gd 之类会返回重复定义。
			automatic_enable = {
				exclude = { "rust_analyzer" },
			},
		})

		mason_tool_installer.setup({
			ensure_installed = mason_packages,
		})
	end,
}
