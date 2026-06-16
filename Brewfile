# ════════════════════════════════════════════════════════════════════
# Brewfile —— 这套 Neovim 配置在【新机器】上需要的外部命令行工具。
#
# 不用背包名!新机器上把这份 nvim 配置 clone 好后,一行装齐 ↓
#     brew bundle --file ~/.config/nvim/Brewfile
#
# 维护:以后新增 brew 依赖,就往下面加一行 brew "xxx" 即可。
# 想从当前机器反向导出(会含你所有已装的,慎用):
#     brew bundle dump --file ~/.config/nvim/Brewfile --force
# ════════════════════════════════════════════════════════════════════

# ── 编辑器本体 ──
brew "neovim"

# ── fzf-lua(文件查找 / 内容搜索)──
brew "fd"
brew "ripgrep"
brew "fzf"

# ── Lint / Format ──
brew "ruff" # Python lint + format(替代了 pylint)

# ── 看图 ──
brew "chafa"       # 终端里直接看图
brew "imagemagick" # image.nvim 在 nvim 里渲染图片(提供 magick 命令)

# ── 摸鱼:终端听网易云音乐(go-musicfox)──
# ⚠️ brew 装它要从源码编译,需要【较新的 Xcode 命令行工具】(CLT 旧会报 "too outdated")。
#    CLT 新的机器:  brew install go-musicfox/go-musicfox/go-musicfox
#    CLT 旧 / 想省事 → 下预编译二进制(版本号去 releases 页核对):
#      curl -fsSL -o /tmp/gmf.zip \
#        https://github.com/go-musicfox/go-musicfox/releases/download/v4.8.5/go-musicfox_4.8.5_darwin_arm64.zip
#      unzip -o /tmp/gmf.zip -d /tmp/gmf
#      mkdir -p ~/.local/bin && mv /tmp/gmf/musicfox ~/.local/bin/ && chmod +x ~/.local/bin/musicfox
#      xattr -dr com.apple.quarantine ~/.local/bin/musicfox   # 去隔离,免得 Gatekeeper 拦

# ════════════════════════════════════════════════════════════════════
# 下面这些不归 brew 管,新机器还要补 —— 也都不用背,照抄就行:
#
# 1) LSP 服务器 + 格式化器  → 用 mason 一行装齐(在 nvim 里执行):
#      :MasonInstall pyright lua-language-server stylua prettier eslint_d \
#                    isort black taplo zls typescript-language-server \
#                    json-lsp html-lsp css-lsp
#
# 2) Rust 工具链(rust_analyzer 由 rustaceanvim 自动调用):
#      brew install rustup && rustup-init -y
#      rustup component add rust-analyzer
#
# 3) Nerd Font(图标字体)→ 把 IoskeleyMono Nerd Font 的 ttf 拷进 ~/Library/Fonts/
#    (这是自定义字体,不在 brew cask 里;Ghostty 配置 font-family 引用它)
# ════════════════════════════════════════════════════════════════════
