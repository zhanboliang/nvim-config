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

		-- 启动布局：不再自动打开 nvim-tree（任何启动方式都不开）。
		-- 需要文件树时用 <leader>ee 手动开,或 dashboard 上的 "SPC ee" 按钮。
		-- 这里只负责让 `nvim .`(用目录启动)显示 dashboard:
		--   `nvim`        → alpha 自动显示(alpha 自带,无需在此处理)
		--   `nvim .`      → cd 进目录 + 显示 dashboard + 清掉空的目录 buffer
		--   `nvim foo.rs` → 正常打开文件
		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("johnlyon_startup_layout", { clear = true }),
			callback = function()
				local args = vim.fn.argv()
				if #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
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
				end
			end,
		})
	end,
}
