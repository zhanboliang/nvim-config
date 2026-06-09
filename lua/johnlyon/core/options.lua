local opt = vim.opt -- for conciseness

-- 禁用未使用的 provider —— 跳过启动时对这些解释器的 spawn 探测，省 30-80ms
-- 用到任意一个再注释掉对应行即可
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- 兼容 shim：nvim-lsp-file-operations 等老插件还在调 vim.lsp.get_active_clients(),
-- nvim 0.10+ 已 deprecate 并每次刷红色警告。直接转发到 get_clients,屏蔽警告。
-- 上游修了之后可以删。
if vim.lsp and vim.lsp.get_clients then
	vim.lsp.get_active_clients = vim.lsp.get_clients
end

-- PATH：把 Homebrew 和 mason 的 bin 目录前置进 nvim 的 PATH，让 LSP / 格式化 / lint
-- 工具能被找到。放这里(而不是 mason 的 config)是为了让 mason 本体纯按命令懒加载 ——
-- 平时不加载 mason，已装好的工具照样可用。
do
	local prepend = { "/opt/homebrew/bin", vim.fn.stdpath("data") .. "/mason/bin" }
	local seen, entries = {}, {}
	for _, p in ipairs(prepend) do
		if vim.fn.isdirectory(p) == 1 and not seen[p] then
			seen[p] = true
			table.insert(entries, p)
		end
	end
	for _, p in ipairs(vim.split(vim.env.PATH or "", ":", { plain = true, trimempty = true })) do
		if not seen[p] then
			seen[p] = true
			table.insert(entries, p)
		end
	end
	vim.env.PATH = table.concat(entries, ":")
end

-- line numbers
opt.relativenumber = true -- show relative line numbers
opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false -- disable line wrapping

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true -- highlight the current cursor line

-- appearance

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard (deferred to avoid macOS pbcopy detection cost at startup)
vim.schedule(function()
  opt.clipboard:append("unnamedplus")
end)

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false

-- 隐藏底部命令行区域（cmdline 由 noice.nvim 接管，浮动窗口显示）
opt.cmdheight = 0

-- 禁止鼠标拖拽 statusline / 窗口分隔条改变窗口大小
-- 保留点击与滚轮，仅屏蔽 LeftDrag（这是 Neovim 改窗口尺寸的内建行为）
-- 注意：双击/三击后再拖拽会触发 <2-LeftDrag>/<3-LeftDrag>，要一并拦住
-- 用 <Nop> 而非 <LeftMouse>：触控板按下基本都有微位移，把 drag 重发成
-- 带"漂移坐标"的点击反而会让光标乱跳，直接吞掉最干净。
for _, key in ipairs({ "<LeftDrag>", "<2-LeftDrag>", "<3-LeftDrag>", "<4-LeftDrag>" }) do
  vim.keymap.set({ "n", "i", "v", "c", "t" }, key, "<Nop>", { silent = true })
end

-- 兜底：若 cmdheight 被改（例如鼠标拖底部 statusline 漏过 LeftDrag 拦截），
-- 立刻复位回 0，保持 statusline 钉在最底部
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "cmdheight",
  callback = function()
    if vim.v.option_new ~= 0 then
      vim.schedule(function() vim.o.cmdheight = 0 end)
    end
  end,
})

-- 内置终端打开后立即进入 insert 模式，避免 normal 模式误吞按键
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("johnlyon_term", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- 切回已有终端 buffer 时:
--   - 上次光标停在底部(最后两行之内)→ 自动进 insert,继续打字流畅
--   - 上次光标在上方(说明在用 normal 模式滚 / 读历史)→ 保持 normal,
--     不强制跳底部
-- 修复:右侧/底部终端切焦点后被拽回最底部、丢失滚动位置的问题。
vim.api.nvim_create_autocmd("BufEnter", {
  group = "johnlyon_term",
  pattern = "term://*",
  callback = function(args)
    local cur_line = vim.api.nvim_win_get_cursor(0)[1]
    local last_line = vim.api.nvim_buf_line_count(args.buf)
    if last_line - cur_line <= 1 then
      vim.cmd("startinsert")
    end
  end,
})

-- ─────────────────────────────────────────────────────────────────────────────
-- nvim 0.12 LSP pull diagnostics 的竞态修补
-- ─────────────────────────────────────────────────────────────────────────────
-- 现象:打开 Rust 项目同时快速 <leader>t 唤出 toggleterm 浮动终端时,nvim 报红:
--
--   …/lsp/diagnostic.lua:296: attempt to index local 'bufstate' (a nil value)
--
-- 真正的根因(读 v0.12.2 实际源码定位):
--   - rust-analyzer 通过 client/registerCapability 动态注册
--     textDocument/diagnostic(handlers.lua:147-176)。注册后立即对
--     attached_buffers 调 _refresh 发请求。
--   - _refresh 不会自己初始化 bufstates[bufnr],该初始化由 _set_defaults →
--     diagnostic._enable(bufnr) 完成(lsp.lua:865-867)。
--   - 启动期快速打开 toggleterm float 时,autocmd 排序 / 当前 buf 切换之间
--     存在 race,偶发出现:_refresh 已发出请求 → 响应到达 → on_diagnostic 跑
--     → bufstates[bufnr] 仍是 nil → diagnostic.lua:292 取出 nil →
--     diagnostic.lua:296 索引崩。
--
-- 此前的"buffer 已 wipe"假设是错的:这一场景下 buffer 仍然有效,只是
-- 模块私有的 bufstates 表里没那个 entry。所以 nvim_buf_is_valid 守卫拦不住。
--
-- 修法:在 wrapper 里通过 debug.getupvalue 拿出 diagnostic.lua 模块私有的
-- bufstates 表;若 bufstates[bufnr] 缺失就替 _enable 把 entry 补上,再调原
-- 函数。upvalue 抓不到时 pcall 兜底,功能不挂。
--
-- 上游修复后可整段删除。参考源码:
--   /opt/homebrew/Cellar/neovim/0.12.2/share/nvim/runtime/lua/vim/lsp/diagnostic.lua:276-319
-- ─────────────────────────────────────────────────────────────────────────────

-- 层 1:覆写 on_diagnostic（处理 textDocument/diagnostic 响应,主战场）
do
  local diag = vim.lsp.diagnostic
  local original = diag.on_diagnostic

  -- 抓 diagnostic.lua 模块的私有 bufstates 表(原函数的 upvalue)
  local bufstates
  for i = 1, math.huge do
    local n, v = debug.getupvalue(original, i)
    if not n then break end
    if n == "bufstates" then
      bufstates = v
      break
    end
  end

  diag.on_diagnostic = function(err, result, ctx)
    if not ctx or not ctx.bufnr or not vim.api.nvim_buf_is_valid(ctx.bufnr) then
      return
    end

    -- 关键修复:_enable 没赶上时替它把 bufstate 占位补齐,
    -- 让原函数后续 bufstate.client_result_id[key] = … 不再崩。
    -- pull_kind 用 'document',与 _enable 默认值一致。
    if bufstates and not bufstates[ctx.bufnr] then
      bufstates[ctx.bufnr] = { pull_kind = "document", client_result_id = {} }
    end

    -- pcall 兜底:upvalue 抓不到 / 上游字段又改 / 其它意外都不再刷红。
    local ok, perr = pcall(original, err, result, ctx)
    if not ok then
      vim.schedule(function()
        vim.notify(
          "[lsp.diagnostic patch] on_diagnostic swallowed: " .. tostring(perr),
          vim.log.levels.DEBUG
        )
      end)
    end
  end
end

-- 层 2:覆写 on_refresh(处理 workspace/diagnostic/refresh,防止同类 race)
do
  local diag = vim.lsp.diagnostic
  local original = diag.on_refresh
  diag.on_refresh = function(err, result, ctx)
    if not ctx or not ctx.client_id then
      return vim.NIL
    end
    return original(err, result, ctx)
  end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 窗口可见性 —— 分清「哪个窗口活动 / 边界在哪」。三层叠加,全跟随主题、不用粗字符。
-- ─────────────────────────────────────────────────────────────────────────────

-- ① 分隔线:细单线 box-drawing 字符(fillchars 是全局选项,不被 :colorscheme 重置)
vim.opt.fillchars:append({
  vert = "│", horiz = "─", horizup = "┴", horizdown = "┬",
  vertleft = "┤", vertright = "├", verthoriz = "┼",
})
-- WinSeparator 默认近似窗口背景 → 看不见。link 到 Comment:每个主题都把 Comment 定义成
-- 「可见但克制」的灰,自动跟随明/暗主题,无需写死颜色。(:colorscheme 会重置高亮,见下方 autocmd)
local function fix_winsep()
  vim.api.nvim_set_hl(0, "WinSeparator", { link = "Comment" })
end
fix_winsep()

-- ② 光标行只在「活动窗口」亮 —— 标出焦点在哪个窗口。CursorLine 由主题自带,自动跟随。
local cl_group = vim.api.nvim_create_augroup("johnlyon_active_cursorline", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = cl_group,
  callback = function() vim.wo.cursorline = true end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = cl_group,
  callback = function() vim.wo.cursorline = false end,
})

-- ③ 非活动窗口背景轻微变暗 —— 只动【背景】、不动语法前景色,左右对比看代码仍清晰。
local dim_amount = 0.06 -- 背景压暗比例;想更明显调大(如 0.10),想更淡调小

local function apply_normalnc()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if not normal.bg then -- 透明主题:没有背景可压暗
    vim.api.nvim_set_hl(0, "NormalNC", { link = "Normal" })
    return
  end
  local bg = normal.bg
  local r = math.floor((math.floor(bg / 65536) % 256) * (1 - dim_amount))
  local g = math.floor((math.floor(bg / 256) % 256) * (1 - dim_amount))
  local b = math.floor((bg % 256) * (1 - dim_amount))
  vim.api.nvim_set_hl(0, "NormalNC", { bg = string.format("#%02x%02x%02x", r, g, b) })
end
apply_normalnc()

-- 切主题后高亮被重置 → 重新应用 ① 和 ③
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("johnlyon_win_visibility", { clear = true }),
  callback = function()
    fix_winsep()
    apply_normalnc()
  end,
})
