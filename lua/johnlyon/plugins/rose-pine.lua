return {
	-- ⚠️ 仓库是 rose-pine/neovim，必须显式 name = "rose-pine"，
	--    否则 lazy 会把插件目录命名为 "neovim"，:colorscheme rose-pine 找不到。
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = true,
	opts = {
		variant = "auto",      -- auto：跟随 background（dark→main，light→dawn）
		dark_variant = "main", -- 深色档：main(深) / moon(中)；可改 moon 试试
		styles = {
			bold = true,
			italic = true,
			transparency = false,
		},
	},
	-- 三个主题名都可用：rose-pine / rose-pine-moon / rose-pine-dawn
}
