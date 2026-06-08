return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		-- Set header
		dashboard.section.header.val = {
			"                                                   ",
			"███████╗██╗  ██╗ █████╗ ███╗   ██╗██████╗  ██████╗ ",
			"╚══███╔╝██║  ██║██╔══██╗████╗  ██║██╔══██╗██╔═══██╗",
			"  ███╔╝ ███████║███████║██╔██╗ ██║██████╔╝██║   ██║",
			" ███╔╝  ██╔══██║██╔══██║██║╚██╗██║██╔══██╗██║   ██║",
			"███████╗██║  ██║██║  ██║██║ ╚████║██████╔╝╚██████╔╝",
			"╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝ ",
			"                                                   ",
		}
		dashboard.section.header.opts.hl = "AlphaHeader"
		vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#CE422B" })

		-- Set menu
		dashboard.section.buttons.val = {
			dashboard.button("e", "  > New File", "<cmd>ene<CR>"),
			dashboard.button("SPC ee", "  > Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("SPC ff", "󰱼  > Find File", "<cmd>FzfLua files<CR>"),
			dashboard.button("SPC fs", "  > Find Word", "<cmd>FzfLua live_grep_native<CR>"),
			dashboard.button("q", "  > Quit NVIM", "<cmd>qa<CR>"),
		}

		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

		-- 启动布局：左树 + 右 dashboard / 文件
		-- 触发场景：
		--   `nvim`        → alpha 自动显示，追加打开 nvim-tree
		--   `nvim .`      → cd 进目录，启动 alpha，删掉空的目录 buffer，再开 nvim-tree
		--   `nvim foo.rs` → 打开文件，并在左侧补一棵 nvim-tree
		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("johnlyon_startup_layout", { clear = true }),
			callback = function()
				local args = vim.fn.argv()

				local should_layout = false

				if #args == 0 then
					-- nvim 无参：alpha 已自动显示，仅需追加 tree
					should_layout = true
				elseif #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
					-- nvim <dir>：cd 进去，启动 alpha，清理掉那个空的目录 buffer
					vim.cmd("cd " .. vim.fn.fnameescape(args[1]))
					vim.cmd("enew")
					alpha.start(false)
					-- 把启动时为目录创建的 buffer 删掉，避免在 :ls 里残留
					for _, buf in ipairs(vim.api.nvim_list_bufs()) do
						if vim.api.nvim_buf_is_loaded(buf) then
							local name = vim.api.nvim_buf_get_name(buf)
							if name ~= "" and vim.fn.isdirectory(name) == 1 then
								pcall(vim.api.nvim_buf_delete, buf, { force = true })
							end
						end
					end
					should_layout = true
				else
					-- nvim <file> [file...]：文件已打开并聚焦，只在左侧补一棵 tree，
					-- focus=false 让光标留在文件上。
					should_layout = true
				end

				if should_layout then
					-- 用 schedule 确保 nvim-tree 已就绪；focus=false 让光标停在 dashboard 上
					vim.schedule(function()
						local ok, api = pcall(require, "nvim-tree.api")
						if ok then
							api.tree.open({ focus = false })
						end
					end)
				end
			end,
		})
	end,
}
