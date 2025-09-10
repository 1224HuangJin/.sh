#!/bin/bash
# ==============================================
# Brave 浏览器一键安装脚本 (Chromebook 优化版)
# 备用连接: https://raw.githubusercontent.com/1224HuangJin/.sh/main/brave/zh.sh
# 快速运行方法：
# bash <(wget -qO- https://is.gd/zhbrave)
# 或下载后执行：
# wget -O brave-zh.sh https://is.gd/zhbrave
# bash brave-zh.sh
# ==============================================
set -e

# ====== 彩色输出函数 ======
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"

log_info() { echo -e "${GREEN}$1${RESET}"; }
log_warn() { echo -e "${YELLOW}$1${RESET}"; }
log_error() { echo -e "${RED}$1${RESET}"; }

# ====== 网络检测 ======
log_info "🌐 检查网络连接..."
if ! ping -c 1 google.com >/dev/null 2>&1; then
  log_error "❌ 没有网络，请检查连接后再试。"
  exit 1
fi
log_info "✅ 网络正常，继续..."

# ====== 检查 Brave 是否已安装 ======
if command -v brave-browser >/dev/null 2>&1; then
  log_warn "⚠️ 检测到 Brave 已安装，将跳过安装步骤，仅设置中文启动器。"
  skip_install=true
else
  skip_install=false
fi

# ====== 欢迎界面 ======
echo "👋 嘿！欢迎使用 Brave 浏览器安装脚本，准备开启安全快跑模式了吗？^_^"
echo
echo "先跟你聊聊 Brave 浏览器的小秘密："
echo "🦁 优点："
echo " - 自带广告拦截，隐私保护很强"
echo " - 基于 Chromium，兼容扩展和网页"
echo " - 比 Chrome 更省内存"
echo " - 后台进程更少，看着更清爽"
echo
echo "⚠️ 小瑕疵："
echo " - 有些网站/扩展偶尔卡顿"
echo " - 隐私设置严格，得手动调权限"
echo " - 玩 GeforceNow 时 ESC 会直接退出全屏"
echo " - 玩 CrazyGames 时可能卡顿"
echo
echo "🔒 特别功能：内置 Tor VPN"
echo " - 可以访问被限制的网站"
echo " - 支持暗网（⚠️ 不建议乱尝试）"
echo " - 用法：≡ → 新建 Tor 隐私窗口 (Shift+Alt+N)"
echo " - 缺点：速度慢，不稳定"
echo " - 想要更安全的，还是 Tor 官方浏览器更靠谱"
echo " - 关于Tor的文档：https://support.brave.app/hc/zh-tw/articles/7816553516045"
echo "如有问题请联系: 1224huangjin@gmail.com 或在 https://github.com/1224HuangJin/.sh/ 发送一个Issues"
echo "（2025.09.07）"
echo
read -p "准备好安装 Brave 浏览器吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  log_warn "好啦，下次再见！👋"
  exit 0
fi

# ====== 安装必要依赖 ======
if [ "$skip_install" = false ]; then
  log_info "🌐 安装必要依赖..."
  sudo apt update
  sudo apt install -y curl gnupg ca-certificates apt-transport-https software-properties-common locales
fi

# ====== 添加 Brave 官方 GPG 密钥和软件源 ======
log_info "🔐 添加 Brave 官方 GPG 密钥和软件源..."
arch=$(dpkg --print-architecture)

if [[ ! -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]]; then
  sudo curl --retry 3 -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
fi

if [[ ! -f /etc/apt/sources.list.d/brave-browser-release.sources ]] || \
   ! grep -q "brave-browser-apt-release.s3.brave.com" /etc/apt/sources.list.d/brave-browser-release.sources; then
  sudo tee /etc/apt/sources.list.d/brave-browser-release.sources > /dev/null <<EOF
Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com/
Suites: stable
Components: main
Architectures: $arch
Signed-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg
EOF
fi

# ====== 安装 Brave 浏览器 ======
if [ "$skip_install" = false ]; then
  log_info "🌐 安装 Brave 浏览器..."
  sudo apt update
  sudo apt install -y brave-browser
fi

# ====== 语言选择 ======
echo "请选择语言设置方式："
echo " 1) 修改整个系统语言为 中文简体（包括Brave浏览器）"
echo " 2) 仅 Brave 浏览器改中文"
read -p "请输入 1 或 2 (默认 2): " lang_choice
lang_choice=${lang_choice:-2}

if [[ "$lang_choice" == "1" ]]; then
  log_info "⚙️ 配置系统语言为中文简体..."
  if ! grep -q '^zh_CN.UTF-8 UTF-8' /etc/locale.gen; then
    echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
  else
    sudo sed -i '/^#.*zh_CN.UTF-8 UTF-8/s/^#//' /etc/locale.gen
  fi
  sudo locale-gen
  sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8
  log_info "✅ 系统语言已改中文简体。请注销或重启后生效。"
fi

# ====== 自定义启动器 ======
read -p "设置启动器名称（默认：Brave 浏览器）: " launcher_name
launcher_name=${launcher_name:-"Brave 浏览器"}

mkdir -p ~/.local/share/applications
# 无论选择哪种语言设置，都强制使用中文启动
exec_line="env LANG=zh_CN.UTF-8 brave-browser --lang=zh-CN %U"

cat > ~/.local/share/applications/brave-browser-cn.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=$launcher_name
Name[zh_CN]=$launcher_name
Comment=使用中文语言启动 Brave 浏览器 (来自→ https://github.com/1224HuangJin/.sh/blob/main/brave/zh.sh )
Exec=$exec_line
Icon=brave-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

# ====== 更新桌面数据库 ======
update-desktop-database ~/.local/share/applications/

# ====== 隐藏原版启动器 ======
read -p "是否隐藏原版英文启动器？(y/N): " hide_choice
if [[ "$hide_choice" =~ ^[Yy]$ ]]; then
  log_info "🔍 正在查找并隐藏所有原版Brave启动器..."
  
  # 查找所有可能的Brave启动器位置
  declare -a brave_dirs=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
    "/var/lib/snapd/desktop/applications"
    "$HOME/.local/share/applications"
  )
  
  # 查找并隐藏所有Brave启动器（除了我们创建的）
  hidden_count=0
  for dir in "${brave_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      while IFS= read -r -d '' f; do
        # 跳过我们创建的中文启动器
        if [[ "$f" != *"brave-browser-cn.desktop" ]]; then
          # 尝试使用sudo修改，如果失败则使用当前用户权限
          if sudo test -w "$f"; then
            sudo sed -i '/^NoDisplay=/d' "$f" 2>/dev/null || true
            echo "NoDisplay=true" | sudo tee -a "$f" >/dev/null 2>/dev/null
          else
            sed -i '/^NoDisplay=/d' "$f" 2>/dev/null || true
            echo "NoDisplay=true" | tee -a "$f" >/dev/null 2>/dev/null
          fi
          log_info "已隐藏: $f"
          ((hidden_count++))
        fi
      done < <(find "$dir" -name "*brave*.desktop" -o -name "*Brave*.desktop" -print0 2>/dev/null)
    fi
  done
  
  # 额外处理可能的Snap版本
  if command -v snap >/dev/null 2>&1; then
    if snap list | grep -q brave; then
      while IFS= read -r -d '' f; do
        if [[ -f "$f" ]]; then
          sed -i '/^NoDisplay=/d' "$f" 2>/dev/null
          echo "NoDisplay=true" | tee -a "$f" >/dev/null 2>/dev/null
          log_info "已隐藏Snap版: $f"
          ((hidden_count++))
        fi
      done < <(find "$HOME/.local/share/applications" -name "snap*brave*.desktop" -print0 2>/dev/null)
    fi
  fi
  
  if [ $hidden_count -gt 0 ]; then
    log_info "😋 成功隐藏了 $hidden_count 个原版启动器！菜单里应该只剩你的中文启动器~"
  else
    log_warn "⚠️ 没有找到需要隐藏的原版启动器。"
  fi
else
  log_warn "保留原版启动器，菜单里会显示多个 Brave 浏览器。"
fi

# ====== 强制刷新桌面菜单 (Chromebook 专用) ======
log_info "🔄 强制刷新桌面菜单..."
if command -v xdg-desktop-menu >/dev/null 2>&1; then
  xdg-desktop-menu forceupdate 2>/dev/null || true
fi

# Chromebook 专用桌面刷新方法
log_info "📱 Chromebook 专用提示:"
echo "  如果您使用的是 Chromebook Linux 容器，可能需要以下操作:"
echo "  1. 点击屏幕右下角的时间区域"
echo "  2. 点击设置图标(齿轮形状)"
echo "  3. 在左侧菜单中找到 '应用'"
echo "  4. 点击右上角的『刷新』按钮"
echo "  5. 或者完全退出 Linux 容器并重新启动"

# ====== 完成 ======
log_info "🎉 完成！可以在菜单找到 \"$launcher_name\"，开心地用中文启动啦！"
log_info "🧑‍💻 命令行备用启动："
echo "  env LANG=zh_CN.UTF-8 brave-browser --lang=zh-CN"

log_info "💡 如果菜单中仍有多个Brave图标，请尝试："
echo "  1. 完全注销并重新登录"
echo "  2. 在 Chromebook 上: 完全退出 Linux 容器并重新启动"
echo "  3. 运行: killall gnome-panel 2>/dev/null || killall plasmashell 2>/dev/null"
echo "  4. 或者重启计算机"

# 添加重置桌面的具体指导
echo
log_info "🔄 重置 Linux 桌面环境的方法:"
echo "  对于 Chromebook 的 Linux 容器:"
echo "  1. 右键点击终端图标"
echo "  2. 选择『关闭 Linux』"
echo "  3. 等待几秒钟后重新启用 Linux"
echo "  4. 或者重启整个 Chromebook"

exit 0
