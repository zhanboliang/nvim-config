return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      python = { "ruff" },
    }

    -- 只跑「可执行文件已安装」的 linter —— 否则某个 linter 没装时,每次进 buffer / 保存
    -- 都会弹 "Error running pylint: ENOENT … Press ENTER"。缺就静默跳过。
    local function lint_if_available(notify_missing)
      local names = lint.linters_by_ft[vim.bo.filetype] or {}
      local runnable, missing = {}, {}
      for _, name in ipairs(names) do
        local ok, linter = pcall(function() return lint.linters[name] end)
        local cmd = ok and type(linter) == "table" and linter.cmd or nil
        if type(cmd) == "function" then cmd = cmd() end
        if cmd and vim.fn.executable(cmd) == 1 then
          table.insert(runnable, name)
        else
          table.insert(missing, name)
        end
      end
      if #runnable > 0 then lint.try_lint(runnable) end
      if notify_missing and #missing > 0 then
        vim.notify(
          "linter 未安装: " .. table.concat(missing, ", ") .. "（用 :MasonInstall 安装）",
          vim.log.levels.WARN
        )
      end
    end

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function() lint_if_available(false) end,
    })

    -- 手动触发:若该语言的 linter 没装,提示一下(自动触发时保持静默)
    vim.keymap.set("n", "<leader>l", function() lint_if_available(true) end,
      { desc = "Trigger linting for current file" })
  end,
}
