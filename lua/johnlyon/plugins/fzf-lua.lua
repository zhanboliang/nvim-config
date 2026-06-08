return {
	"ibhagwan/fzf-lua",
	cmd = "FzfLua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	keys = {
		-- ff: 项目文件 —— fd 默认会读 .gitignore + 我们额外 exclude target/node_modules 等.
		--     比 git_files 更宽松一点:未 commit 的新文件也能搜到 (git_files 只列追踪过的).
		{ "<leader>ff", "<cmd>FzfLua files<cr>",            desc = "Find project files" },
		-- fa: 真·全部文件 —— 不读 .gitignore, 显示 hidden, 啥都给你看
		{
			"<leader>fa",
			function()
				require("fzf-lua").files({
					cmd = "fd --color=never --type f --hidden --no-ignore --follow --exclude .git",
				})
			end,
			desc = "Find ALL files (no filters)",
		},
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>",         desc = "Recent files (fzf-lua)" },
		{ "<leader>fs", "<cmd>FzfLua live_grep_native<cr>", desc = "Live grep (fzf-lua, fastest)" },
		-- fc: 搜光标下的单词 —— 用普通字符串模式,不加 \b 边界,UI 干净;
		--     可以在搜索框继续往后输入字符细化过滤.
		{
			"<leader>fc",
			function()
				local cword = vim.fn.expand("<cword>")
				if cword == "" then
					vim.notify("No word under cursor", vim.log.levels.WARN)
					return
				end
				require("fzf-lua").grep({
					search = cword,
					no_esc = false, -- 把特殊符号转义掉, 当字面量搜
					prompt = "  Grep word> ",
				})
			end,
			desc = "Grep word under cursor",
		},
		{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Switch buffer (fzf-lua)" },
	},
	opts = {
		winopts = {
			height = 0.85,
			width = 0.85,
			preview = {
				layout = "flex",
				flip_columns = 130,
			},
		},
		-- Ctrl+n / Ctrl+p 强制绑成上下移动.
		-- fzf 里上下默认是 Ctrl+j / Ctrl+k; n/p 在开了 --history 时会被抢去翻历史,
		-- 这里覆盖回 down/up (deep-merge, 不影响 fzf-lua 其它默认键).
		keymap = {
			fzf = {
				["ctrl-n"] = "down",
				["ctrl-p"] = "up",
			},
		},
		-- buffers 选择器: 关掉 fzf-lua 默认给当前 buffer 钉的表头 (--header-lines=1).
		-- 默认 sort_lastused=true + ignore_current_buffer=false 时,当前 buffer 会被
		-- 冻结成一行不可选的表头; 只开 2 个 buffer 时就只剩 1 个可选条目, 计数器 1/1、
		-- 上下/Ctrl-n/Ctrl-p 都"动不了"(无处可移). 设为 false 让当前 buffer 也变成
		-- 普通可选行, 同时保留 MRU(最近使用)排序、不丢任何 buffer.
		buffers = {
			fzf_opts = { ["--header-lines"] = false },
		},
		-- 装了 fd, fzf-lua 自动用 fd. 这里只覆盖 fd_opts 加自定义排除.
		files = {
			fd_opts = "--color=never --type f --hidden --follow "
				.. "--exclude .git --exclude target --exclude node_modules "
				.. "--exclude dist --exclude build --exclude .next --exclude .venv "
				.. "--exclude .DS_Store",
		},
		grep = {
			-- 更激进的排除: 除了常见构建/依赖目录,还排掉:
			-- - *.lock (Cargo.lock / package-lock.json / yarn.lock 等)
			-- - *.log
			-- - .fingerprint / incremental / deps —— cargo 在 target 外也可能留, 这些里全是 ANSI 转义文本
			-- - *.min.js / *.map —— 压缩产物
			-- - .DS_Store / .idea / .vscode —— 编辑器/系统垃圾
			rg_opts = "--column --line-number --no-heading --color=always --smart-case "
				.. "-g '!.git' -g '!target' -g '!node_modules' "
				.. "-g '!dist' -g '!build' -g '!.next' -g '!.venv' "
				.. "-g '!*.lock' -g '!*.log' "
				.. "-g '!.fingerprint' -g '!incremental' -g '!deps' "
				.. "-g '!*.min.js' -g '!*.map' "
				.. "-g '!.DS_Store' -g '!.idea' -g '!.vscode'",
		},
	},
}
