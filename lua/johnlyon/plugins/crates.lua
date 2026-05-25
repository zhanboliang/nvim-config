return {
	"saecki/crates.nvim",
	tag = "stable",
	event = { "BufRead Cargo.toml" },
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local crates = require("crates")
		crates.setup({
			-- 走 LSP 模式：补全/hover/code action 通过 cmp-nvim-lsp 自动接入,
			-- 不需要单独注册 cmp source。
			lsp = {
				enabled = true,
				name = "crates.nvim",
				actions = true,
				completion = true,
				hover = true,
				on_attach = function(_, bufnr)
					local opts = { buffer = bufnr, silent = true }
					local keymap = vim.keymap

					opts.desc = "Show crate popup"
					keymap.set("n", "<leader>cp", crates.show_popup, opts)

					opts.desc = "Show crate versions"
					keymap.set("n", "<leader>cv", crates.show_versions_popup, opts)

					opts.desc = "Show crate features"
					keymap.set("n", "<leader>cf", crates.show_features_popup, opts)

					opts.desc = "Show crate dependencies"
					keymap.set("n", "<leader>cd", crates.show_dependencies_popup, opts)

					opts.desc = "Update crate to latest"
					keymap.set("n", "<leader>cu", crates.update_crate, opts)

					opts.desc = "Upgrade crate (breaking)"
					keymap.set("n", "<leader>cU", crates.upgrade_crate, opts)

					opts.desc = "Open crate on crates.io"
					keymap.set("n", "<leader>co", crates.open_homepage, opts)
				end,
			},
		})
	end,
}
