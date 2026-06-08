return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec", "TermSelect", "BottomTermToggle" },
  keys = {
    { "<leader>t",  desc = "Toggle floating terminal" },
    { "<leader>th", desc = "Toggle bottom terminal" },
    { "<leader>tv", desc = "Toggle right terminal" },
    { "<leader>tn", desc = "Split current terminal into a new pane" },
    { "<leader>tr", desc = "Rename current terminal" },
    { "<leader>tl", desc = "List/select terminals" },
    { "<leader>tk", desc = "Kill current terminal" },
  },
  config = function()
    require("toggleterm").setup({
      -- 三种 direction 各自合理的尺寸：
      --   horizontal → 行数；vertical → 列数；float → 兜底
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
        return 20
      end,
      open_mapping = [[<leader>t]], -- 浮动终端入口（自带 count 支持：N<leader>t = 第 N 个浮动终端）
      insert_mappings = false,
      terminal_mappings = false,    -- 不在 terminal 模式注册 <leader>t，避免空格键延迟

      direction = "float",
      float_opts = { border = "curved" },
      persist_size = true,
      persist_mode = true,
    })

    -- 右侧垂直终端仍由 toggleterm 管（vertical 用 wincmd L 推到最右，
    -- 因为 tree 在最左，不会跨过它，所以行为可接受）
    local Terminal = require("toggleterm.terminal").Terminal
    local v_term = Terminal:new({ direction = "vertical", hidden = true, display_name = "right" })

    vim.keymap.set("n", "<leader>tv", function() v_term:toggle() end,
      { desc = "Toggle right terminal" })

    -- 底部水平终端「自管理」：toggleterm 的 horizontal 内部会跑 `wincmd J`
    -- 把窗口推到屏幕最底部全宽，会盖在 nvim-tree 列下面 —— 我们不要那样。
    -- 改成 `belowright split`：在当前窗口下方裂分，只占当前窗口的宽度。
    -- 配合先把焦点切到编辑器窗口，结果就是「终端只在编辑器列的下方」。
    local h_state = { buf = nil, win = nil }

    -- 找"编辑器区域"窗口：
    --   1) 优先：真文件 buffer (buftype == "")
    --   2) 次选：alpha 启动页 / 其它非 tree、非终端的特殊 buffer
    -- 否则会回退到当前窗口（如果当前焦点在 tree 上，终端就裂到 tree 下面了）
    local function find_editor_win()
      local fallback
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then
          local buf = vim.api.nvim_win_get_buf(win)
          local bt = vim.bo[buf].buftype
          local ft = vim.bo[buf].filetype
          if bt == "" then
            return win
          elseif bt ~= "terminal" and ft ~= "NvimTree" then
            fallback = fallback or win
          end
        end
      end
      return fallback
    end

    local function bottom_term_toggle()
      -- 已开 → 关窗口（buffer 保留，进程不杀，再开能复用）
      if h_state.win and vim.api.nvim_win_is_valid(h_state.win) then
        vim.api.nvim_win_close(h_state.win, true)
        h_state.win = nil
        return
      end

      -- 找编辑器窗口做锚点；找不到就在当前窗口裂分（兜底）
      local ed = find_editor_win()
      if ed then
        vim.api.nvim_set_current_win(ed)
      end

      vim.cmd("belowright 15split")
      h_state.win = vim.api.nvim_get_current_win()
      vim.wo[h_state.win].winfixheight = true

      if h_state.buf and vim.api.nvim_buf_is_valid(h_state.buf) then
        vim.api.nvim_set_current_buf(h_state.buf)
      else
        vim.cmd("terminal")
        h_state.buf = vim.api.nvim_get_current_buf()
        -- 给个好看的名字，<leader>tl 列表里直接显示 "bottom"
        pcall(vim.cmd, "file bottom")
      end

      vim.cmd("startinsert")
    end

    vim.keymap.set("n", "<leader>th", bottom_term_toggle,
      { desc = "Toggle bottom terminal (below editor only)" })

    -- 暴露成用户命令，方便外部 / 脚本调用
    vim.api.nvim_create_user_command("BottomTermToggle", bottom_term_toggle,
      { desc = "Toggle the managed bottom terminal" })

    -- <leader>tn：在终端窗口里追加一个"对垂直方向"的新 pane
    --   底部（horizontal）终端里按 → vsplit 出右边的新 pane（tmux 风）
    --   右侧（vertical）终端里按   → split  出下方的新 pane
    -- 这些追加的 pane 是裸 :terminal，不被 toggleterm 管理；
    -- 但下方的 TermOpen autocmd 会给它们加 <C-w>o 防护。
    vim.keymap.set("n", "<leader>tn", function()
      if vim.bo.buftype ~= "terminal" then
        vim.notify("Open <leader>th or <leader>tv first, then split inside it",
          vim.log.levels.WARN)
        return
      end
      local win = vim.api.nvim_get_current_win()
      local w = vim.api.nvim_win_get_width(win)
      -- 占据整个终端宽度大半（横向终端在底部）→ 沿垂直线劈开（vsplit）
      -- 否则视为纵向终端 → 沿水平线劈开（split）
      if w > vim.o.columns * 0.6 then
        vim.cmd("rightbelow vsplit | terminal")
      else
        vim.cmd("rightbelow split | terminal")
      end
    end, { desc = "Split current terminal into a new pane" })

    -- 列出所有 terminal buffer（含 toggleterm 主终端 + 裸 split 的 pane）
    -- 显示优先级：
    --   1) 用户用 <leader>tr 重命名过 → 直接显示自定义名
    --   2) toggleterm 主终端 → 显示 display_name (direction)
    --   3) 兜底 → 解析 term:// URL 取 shell 名
    vim.keymap.set("n", "<leader>tl", function()
      local tt_map = {}
      for _, t in ipairs(require("toggleterm.terminal").get_all()) do
        if t.bufnr then tt_map[t.bufnr] = t end
      end

      local terms = {}
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "terminal" then
          local bufname = vim.api.nvim_buf_get_name(buf)
          local tt = tt_map[buf]
          local label
          if not bufname:match("^term://") then
            label = bufname -- 用户已 :file 重命名
          elseif tt and tt.display_name and tt.display_name ~= "" then
            label = string.format("%s (%s)", tt.display_name, tt.direction)
          else
            local cmd = bufname:match(":([^:/]+)$") or "shell"
            label = "term: " .. cmd
          end
          table.insert(terms, {
            buf = buf,
            label = string.format("[%d] %s", buf, label),
          })
        end
      end

      if #terms == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
      end
      vim.ui.select(terms, {
        prompt = "Select terminal: ",
        format_item = function(t) return t.label end,
      }, function(choice)
        if not choice then return end
        -- 找一个已经显示该 buffer 的窗口；若没有就在当前窗口切过去
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == choice.buf then
            vim.api.nvim_set_current_win(win)
            return
          end
        end
        vim.api.nvim_set_current_buf(choice.buf)
      end)
    end, { desc = "List/select terminals" })

    -- 重命名当前终端 buffer（弹输入框，确认后用 :file 设置 buffer 名）
    -- 命名后，<leader>tl 列表里就能看到自定义名字（如 "cargo-watch" / "build"）
    vim.keymap.set("n", "<leader>tr", function()
      if vim.bo.buftype ~= "terminal" then
        vim.notify("Not in a terminal buffer", vim.log.levels.WARN)
        return
      end
      vim.ui.input({ prompt = "Rename terminal: " }, function(name)
        if name and name ~= "" then
          -- :file 会改变 buffer 名；fnameescape 处理特殊字符
          vim.cmd("file " .. vim.fn.fnameescape(name))
        end
      end)
    end, { desc = "Rename current terminal" })

    -- 杀掉当前终端 buffer
    vim.keymap.set("n", "<leader>tk", function()
      if vim.bo.buftype ~= "terminal" then
        vim.notify("Not in a terminal buffer", vim.log.levels.WARN)
        return
      end
      vim.cmd("bdelete!")
    end, { desc = "Kill current terminal" })

    -- 终端 normal 模式下按 <CR>：
    --   - 光标下能解析出有效文件路径 → 在「编辑器窗口」中打开（不替换终端）
    --   - 支持 "path:line:col" 后缀
    --   - 解析失败 notify 报错，不影响终端
    local function term_open_under_cursor()
      local cfile = vim.fn.expand("<cfile>")
      if cfile == "" then
        vim.notify("No file under cursor", vim.log.levels.WARN)
        return
      end

      -- 解析 cfile 后面可能跟着的 :line:col
      local cur_line = vim.api.nvim_get_current_line()
      local _, _, l, c = cur_line:find(vim.pesc(cfile) .. ":(%d+):?(%d*)")
      local lnum = tonumber(l)
      local cnum = tonumber(c)

      -- 解析路径：原样 → 项目根递归 findfile
      local path = cfile
      if vim.fn.filereadable(path) == 0 then
        local found = vim.fn.findfile(cfile, vim.fn.getcwd() .. ";")
        if found ~= "" then path = found end
      end
      if vim.fn.filereadable(path) == 0 then
        vim.notify("File not found: " .. cfile, vim.log.levels.WARN)
        return
      end

      -- 找当前 tab 第一个普通文件 buffer 的窗口（buftype == ""）
      -- 自动排除 terminal / nvim-tree(nofile) / quickfix / help / alpha
      local target_win
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype == "" then
            target_win = win
            break
          end
        end
      end

      if target_win then
        vim.api.nvim_set_current_win(target_win)
      else
        vim.cmd("aboveleft split")
      end

      vim.cmd("edit " .. vim.fn.fnameescape(path))
      if lnum then
        pcall(vim.api.nvim_win_set_cursor, 0, { lnum, math.max((cnum or 1) - 1, 0) })
      end
    end

    -- 给所有 :terminal 打开的 buffer（含裸 split 出的 pane）做几件事：
    --   1) 设为 unlisted，避免出现在 bufferline / :ls 列表（终端走 <leader>tl 管理）
    --   2) 禁止 <C-w>o / <C-w>O 把当前窗口设为唯一窗口（终端被"全屏化"的元凶）
    --   3) <CR> 在编辑器窗口打开光标下文件路径（不替换终端）
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("johnlyon_term_protect", { clear = true }),
      callback = function(args)
        vim.bo[args.buf].buflisted = false
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("t", "<C-w>o", "<Nop>", opts)
        vim.keymap.set("t", "<C-w>O", "<Nop>", opts)
        vim.keymap.set("n", "<C-w>o", "<Nop>", opts)
        vim.keymap.set("n", "<C-w>O", "<Nop>", opts)
        vim.keymap.set("n", "<CR>", term_open_under_cursor,
          vim.tbl_extend("force", opts, { desc = "Open file under cursor in editor window" }))
      end,
    })
  end,
}
