return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		local opts = { noremap = true, silent = true }
		local on_attach = function(client, bufnr)
			opts.buffer = bufnr

			-- 启用 inlay hints (类型/参数行内提示) — 需要 nvim 0.10+
			if client:supports_method("textDocument/inlayHint") then
				pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
			end

			-- toggle inlay hints
			opts.desc = "Toggle inlay hints"
			keymap.set("n", "<leader>ih", function()
				local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
				vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
			end, opts)

			-- set keybinds
			opts.desc = "Show LSP references"
			keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts) -- show definition, references

			opts.desc = "Go to declaration"
			keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

			opts.desc = "Show LSP definitions"
			keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts) -- show lsp definitions

			opts.desc = "Go to definition (LSP, replaces default gf)"
			-- 默认 gf 是按 <cfile> 当文件路径打开 —— 在 rust/python/ts 这种用模块路径的语言里
			-- 经常会误开成 cwd 下的同名目录（exercises/ solutions/ 等）。
			-- 改成走 LSP definition 直接跳源码定义。
			keymap.set("n", "gf", vim.lsp.buf.definition, opts)

			opts.desc = "Show LSP implementations"
			keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<CR>", opts) -- show lsp implementations

			opts.desc = "Show LSP type definitions"
			keymap.set("n", "gt", "<cmd>FzfLua lsp_typedefs<CR>", opts) -- show lsp type definitions

			opts.desc = "See available code actions"
			keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

			opts.desc = "Smart rename"
			keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

			opts.desc = "Show buffer diagnostics"
			keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics_document<CR>", opts) -- show  diagnostics for file

			opts.desc = "Show line diagnostics"
			keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

			opts.desc = "Go to previous diagnostic"
			keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

			opts.desc = "Go to next diagnostic"
			keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

			-- 注:<leader>k 已删除。文档查看走默认 K(vim.lsp.buf.hover),
			-- 滚动浮窗用 <C-f> / <C-b>(见 lspsaga.lua 的 smart_scroll)。

			opts.desc = "Restart LSP"
			keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
		end

		-- used to enable autocompletion (assign to every lsp server config)
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Change the Diagnostic symbols in the sign column (gutter)
		-- (not in youtube nvim video)
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		local server_settings = {
			zls = {
				enable_inlay_hints = true,
				inlay_hints_show_variable_type_hints = true,
				inlay_hints_show_parameter_name = true,
				inlay_hints_show_builtin = true,
				inlay_hints_exclude_single_argument = true,
				inlay_hints_hide_redundant_param_names = true,
				inlay_hints_hide_redundant_param_names_last_token = true,
			},
			lua_ls = {
				Lua = {
					hint = { enable = true, arrayIndex = "Disable", setType = true },
				},
			},
			taplo = {
				evenBetterToml = {
					schema = {
						enabled = true,
						-- 不用在线 catalogs (网络慢会触发 LSP timeout 警告),
						-- 改用本地下载好的 schema. 重新拉:
						--   curl -sSL -o ~/.config/nvim/schemas/cargo.json https://json.schemastore.org/cargo.json
						catalogs = {},
						associations = {
							["Cargo\\.toml$"] = "file:///Users/liangzhanbo/.config/nvim/schemas/cargo.json",
							["pyproject\\.toml$"] = "file:///Users/liangzhanbo/.config/nvim/schemas/pyproject.json",
						},
						cache = {
							memoryExpiration = 60,
							diskExpiration = 600,
						},
					},
					formatter = { alignEntries = false },
				},
			},
		}

		local servers = {
			"pyright",
			"html",
			"cssls",
			"ts_ls",
			"jsonls",
			"lua_ls",
			"zls",
			"taplo",
		}

		for _, server in ipairs(servers) do
			vim.lsp.config(server, {
				capabilities = capabilities,
				on_attach = on_attach,
				settings = server_settings[server],
			})
			vim.lsp.enable(server)
		end
	end,
}
