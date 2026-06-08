return {
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				-- 三个主题：
				--   "wave"   → 默认，深蓝紫，灵感来自葛饰北斋《神奈川冲浪里》
				--   "dragon" → 更深更暗，对比度更高，OLED 友好
				--   "lotus"  → 亮色主题，配 background=light 用
				theme = "dragon",
				-- 如果想根据 vim.opt.background 自动切换 dark/light：
				background = {
					dark = "dragon",
					light = "lotus",
				},
				compile = false,           -- 启用 :KanagawaCompile 后改 true 加速
				undercurl = true,
				commentStyle = { italic = true },
				functionStyle = {},
				keywordStyle = { italic = true },
				statementStyle = { bold = true },
				typeStyle = {},
				transparent = false,
				dimInactive = false,       -- 非活动窗口变暗
				terminalColors = true,
			})
			-- 不再在这里兜底 :colorscheme —— root init.lua 末尾的 core.colorscheme.apply()
			-- 会从存档恢复,或在缺失时回落到 fallback "kanagawa"。
			-- 在这里再调一次只会让启动多 source 一次 colors/kanagawa.vim,白白浪费 ~3ms。
		end,
	},
	-- 旧主题保留（不会自动加载，priority 默认 50；想用就改 priority=1000 并注释掉上面）
	{
		"nyoom-engineering/oxocarbon.nvim",
		lazy = true,
	},
	-- tokyonight —— folke 出品的顶流主题。lazy=true：不在启动时加载，
	-- 只有 <leader>uc 选中它 / 存档里存的就是它时，才由 lazy 按需载入。
	-- 切换走 colorscheme 命令，会被 core/colorscheme.lua 的存档逻辑记住。
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {
			style = "night", -- 可选风格：night(最深) / storm(深) / moon(柔) / day(亮)
			-- 对应主题名分别是：tokyonight / tokyonight-storm / tokyonight-moon / tokyonight-day
		},
	},
}
