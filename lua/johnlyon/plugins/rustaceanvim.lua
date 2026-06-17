return {
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		lazy = false,
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
		},
		init = function()
			local cmp_nvim_lsp = require("cmp_nvim_lsp")
			local keymap = vim.keymap

			local capabilities = cmp_nvim_lsp.default_capabilities()

			local on_attach = function(client, bufnr)
				-- 启用 inlay hints
				if client:supports_method("textDocument/inlayHint") then
					pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
				end

				-- toggle inlay hints
				keymap.set("n", "<leader>ih", function()
					local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
					vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
				end, { buffer = bufnr, desc = "Toggle inlay hints" })

				-- 清理 rust-analyzer hover 响应里的 HTML 标签，修复 Lspsaga hover_doc 渲染
				local original_request = client.request
				client.request = function(method, params, handler, req_bufnr)
					if method == "textDocument/hover" then
						return original_request(method, params, function(err, result, ctx, config)
							if result and result.contents and result.contents.value then
								local v = result.contents.value
								v = v:gsub("\\<", "\1"):gsub("\\>", "\2")
								v = v:gsub("<[^>]+>", "")
								v = v:gsub("\1", "<"):gsub("\2", ">")
								result.contents.value = v
							end
							if handler then
								handler(err, result, ctx, config)
							end
						end, req_bufnr)
					end
					return original_request(method, params, handler, req_bufnr)
				end

				local opts = { noremap = true, silent = true, buffer = bufnr }

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts)

				opts.desc = "Go to definition (LSP, replaces default gf)"
				-- 默认 gf 在 rust 里经常误开成 cwd 下的同名目录（exercises / solutions 等）。
				-- 改成走 LSP definition 直接跳源码定义。
				keymap.set("n", "gf", vim.lsp.buf.definition, opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>FzfLua lsp_typedefs<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics_document<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				-- 注:<leader>k 已删除。文档查看走默认 K(vim.lsp.buf.hover),
				-- 滚动浮窗用 <C-f> / <C-b>(见 lspsaga.lua 的 smart_scroll)。

				opts.desc = "Rust hover actions (go to trait/impl)"
				keymap.set("n", "<leader>ha", function()
					vim.cmd.RustLsp({ "hover", "actions" })
				end, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":RustAnalyzer restart<CR>", opts)
			end

			vim.g.rustaceanvim = {
				tools = {
					float_win_config = {
						border = "rounded",
						max_width = 100,
						max_height = 30,
					},
				},
				server = {
					capabilities = capabilities,
					on_attach = on_attach,
					settings = function(project_root, default_settings)
						local settings = vim.deepcopy(default_settings or {})
						local ra = settings["rust-analyzer"] or {}

						ra.procMacro = {
							enable = true,
							attributes = { enable = true },
							ignored = {
								["tracing-attributes"] = { "instrument" },
								["async-trait"] = { "async_trait" },
							},
						}

						ra.cargo = {
							buildScripts = { enable = true },
							-- 关键性能项:给 RA 单独的 target 子目录(target/rust-analyzer),
							-- 与终端的 cargo build/run 分开,避免抢同一个文件锁导致互相卡死。
							targetDir = true,
							-- 只检查主 target,跳过 tests/benches/examples,大幅减少 check 工作量。
							-- 如果你需要测试代码也有诊断,把这行删掉。
							allTargets = false,
						}

						-- 关掉启动时的缓存预热:多 crate 的 workspace 启动会少占一波 CPU。
						-- 代价:首次跳转/补全略慢一点点,之后无差别。
						ra.cachePriming = { enable = false }

						-- 别让 RA 去扫描这些目录,减少文件监听开销。
						ra.files = {
							excludeDirs = { ".git", "target", "node_modules" },
						}

						-- 关掉 rust-analyzer 的「实时」原生诊断:Neovim 0.12 在打字时会
						-- 打断 proc-macro 展开(#[tokio::main] 等),导致整段函数体级联标红。
						-- 改为只靠保存时的 cargo check 报错 —— 打字时绝不闪红,保存后才显示真实错误。
						ra.diagnostics = {
							enable = false,
						}

						-- 保存时跑 cargo check(默认就是开的,这里显式写明)。
						ra.checkOnSave = true
						ra.check = {
							command = "check",
						}

						ra.inlayHints = {
							bindingModeHints = { enable = false },
							chainingHints = { enable = true },
							closingBraceHints = { enable = true, minLines = 25 },
							closureReturnTypeHints = { enable = "never" },
							lifetimeElisionHints = { enable = "never", useParameterNames = false },
							maxLength = 25,
							parameterHints = { enable = true },
							reborrowHints = { enable = "never" },
							renderColons = true,
							typeHints = {
								enable = true,
								hideClosureInitialization = false,
								hideNamedConstructor = false,
							},
						}

						-- 单文件模式：无 Cargo.toml 时将当前文件作为独立项目告知 rust-analyzer
						local has_cargo = vim.fn.filereadable(project_root .. "/Cargo.toml") == 1
						if not has_cargo then
							local current_file = vim.fn.expand("%:p")
							if current_file:match("%.rs$") then
								ra.linkedProjects = { current_file }
							end
						end

						settings["rust-analyzer"] = ra
						return settings
					end,
				},
			}
		end,
	},
}
