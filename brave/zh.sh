#!/bin/bash
# ==============================================
# Brave 浏览器一键安装脚本 (专为海外中文用户优化)
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

# ====== 防呆检查：禁止直接以 root/sudo 运行整个脚本 ======
# 如果以 sudo 运行，~/.local 目录会变成 /root/.local，导致普通用户桌面上看不到快捷方式
if [ "$EUID" -eq 0 ]; then
  log_error "❌ 请勿直接使用 root 用户或 sudo 运行本脚本！"
  log_error "   请作为普通用户运行（脚本内部会在需要时自动调用 sudo 申请权限）。"
  exit 1
fi

# ====== 系统兼容性检查（只支持 APT 系） ======
if ! command -v apt &> /dev/null; then
  log_error "❌ 本脚本仅支持基于 Debian/Ubuntu 的 Linux 发行版。"
  log_error "   当前系统未检测到 apt 命令，无法继续。"
  exit 1
fi

# ====== 架构支持检查 (新增优化：防止在不支持的设备上跑崩) ======
arch=$(dpkg --print-architecture)
if [[ ! "$arch" =~ ^(amd64|arm64)$ ]]; then
  log_error "❌ 当前系统架构 ($arch) 不受 Brave 官方源支持，无法继续安装！"
  exit 1
fi

# ====== 网络检测（针对海外用户：优先 ping Google，失败后尝试 curl） ======
log_info "🌐 检查网络连接..."
network_ok=false
if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
  network_ok=true
elif curl -s --connect-timeout 5 https://brave.com >/dev/null 2>&1; then
  network_ok=true
fi

if [ "$network_ok" = false ]; then
  log_error "❌ 没有网络，请检查连接后再试。"
  exit 1
fi
log_info "✅ 网络正常，继续..."

# ====== 检查 Brave 是否已安装 ======
if command -v brave-browser >/dev/null 2>&1; then
  log_warn "⚠️ 检测到 Brave 已安装，将跳过安装步骤，仅进行后续配置。"
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
echo "（2026.06.03 修正优化版）"
echo
read -p "准备好安装 Brave 浏览器吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  log_warn "好啦，下次再见！👋"
  exit 0
fi

# ====== 安装阶段（仅当 Brave 未安装时执行） ======
if [ "$skip_install" = false ]; then
  # ----- 安装必要依赖 -----
  log_info "📦 安装必要依赖（curl, gnupg, desktop-file-utils 等）..."
  sudo apt update
  sudo apt install -y curl gnupg ca-certificates apt-transport-https software-properties-common locales desktop-file-utils

  # ----- 添加 Brave 官方 GPG 密钥和软件源 -----
  log_info "🔐 添加 Brave 官方 GPG 密钥和软件源..."
  # 优化：取消文件存在判断，强制覆盖下载，防止旧密钥过期导致报错
  sudo curl --retry 3 -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

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

  # ----- 安装 Brave 浏览器 -----
  log_info "🌐 安装 Brave 浏览器..."
  sudo apt update
  sudo apt install -y brave-browser
fi

# ====== 交互选项 1：字体支持 (新增) ======
echo
read -p "是否需要安装开源中文字体(Noto CJK)以防止网页变成乱码豆腐块？(Y/n，推荐): " font_choice
font_choice=${font_choice:-Y}
if [[ "$font_choice" =~ ^[Yy]$ ]]; then
  log_info "🔤 正在安装中文字体..."
  sudo apt install -y fonts-noto-cjk
fi

# ====== 交互选项 2：语言选择 ======
echo
echo "请选择语言设置方式："
echo " 1) 修改整个系统语言为 中文简体（包括Brave浏览器）"
echo " 2) 仅 Brave 浏览器改中文"
read -p "请输入 1 或 2 (默认 2): " lang_choice
lang_choice=${lang_choice:-2}

if [[ "$lang_choice" == "1" ]]; then
  log_info "⚙️ 配置系统语言为中文简体..."
  # 检查 locale-gen 命令是否存在
  if ! command -v locale-gen &> /dev/null; then
    log_warn "⚠️ 未找到 locale-gen 命令，无法生成系统语言。请手动安装 locales 包。"
  else
    # 修复优化：屏蔽极简系统里的 grep 报错，加入 sed --follow-symlinks 防止软链破坏
    if grep -q '^# *zh_CN.UTF-8 UTF-8' /etc/locale.gen 2>/dev/null; then
      sudo sed -i --follow-symlinks '/^# *zh_CN.UTF-8 UTF-8/s/^# *//' /etc/locale.gen
    elif ! grep -q '^zh_CN.UTF-8 UTF-8' /etc/locale.gen 2>/dev/null; then
      echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
    fi
    sudo locale-gen
    if command -v update-locale &> /dev/null; then
      # 优化：取消破坏性极强的 LC_ALL，只设置安全的 LANG 和 LANGUAGE
      sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh
    else
      sudo localectl set-locale LANG=zh_CN.UTF-8 2>/dev/null || log_warn "⚠️ 未能自动设置系统 locale，请手动配置。"
    fi
    log_info "✅ 系统语言已改中文简体。请注销或重启后生效。"
  fi
fi

# ====== 交互选项 3：自定义启动器 ======
echo
read -p "设置启动器名称（默认：Brave 浏览器）: " launcher_name
launcher_name=${launcher_name:-"Brave 浏览器"}

mkdir -p ~/.local/share/applications
if [[ "$lang_choice" == "1" ]]; then
  exec_line="brave-browser %U"
else
  exec_line="env LANG=zh_CN.UTF-8 brave-browser --lang=zh-CN %U"
fi

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

# ====== 交互选项 4：隐藏原版启动器（优化：使用用户级无损覆盖策略） ======
echo
read -p "是否隐藏原版英文启动器？(y/N): " hide_choice
if [[ "$hide_choice" =~ ^[Yy]$ ]]; then
  # 修复：直接修改 /usr/share/ 会在 apt upgrade 时失效。在 ~/.local 中新建同名文件隐藏是 Linux 标准做法
  cat > ~/.local/share/applications/brave-browser.desktop <<EOF
[Desktop Entry]
Type=Application
NoDisplay=true
EOF
  cat > ~/.local/share/applications/com.brave.Browser.desktop <<EOF
[Desktop Entry]
Type=Application
NoDisplay=true
EOF
  log_info "😋 隐藏成功！应用菜单里只会留下你的中文启动器，且系统更新后也不会失效~"
else
  log_warn "保留原版启动器，菜单里会显示两个 Brave 浏览器。"
fi

# ====== 交互选项 5：设为默认浏览器 (新增) ======
echo
read -p "是否将 Brave 设置为系统默认浏览器？(y/N): " default_choice
if [[ "$default_choice" =~ ^[Yy]$ ]]; then
  if command -v xdg-settings &> /dev/null; then
    xdg-settings set default-web-browser brave-browser-cn.desktop 2>/dev/null || true
    log_info "✅ 已尝试将其设置为默认浏览器！"
  else
    log_warn "⚠️ 未找到 xdg-settings，无法自动设置默认浏览器。"
  fi
fi

# ====== 交互选项 6：清理缓存 (新增) ======
echo
read -p "是否清理底层的 APT 安装包缓存以释放磁盘空间？(Y/n，推荐): " clean_choice
clean_choice=${clean_choice:-Y}
if [[ "$clean_choice" =~ ^[Yy]$ ]]; then
  log_info "🧹 正在清理不再需要的依赖和缓存..."
  sudo apt autoremove -y >/dev/null 2>&1
  sudo apt clean >/dev/null 2>&1
  log_info "✅ 缓存清理完毕！"
fi

# ====== 更新桌面数据库 ======
if command -v update-desktop-database &> /dev/null; then
  update-desktop-database ~/.local/share/applications/ 2>/dev/null || log_warn "⚠️ 桌面数据库更新失败，可能需要重启桌面环境。"
else
  log_warn "⚠️ 未找到 update-desktop-database 命令，请手动刷新桌面缓存或重新登录。"
fi

# ====== 完成 ======
echo
log_info "🎉 完成！可以在应用菜单找到 “$launcher_name”，开心地用中文启动啦！"
log_info "🧑‍💻 命令行备用启动方式："
echo "   LANG=zh_CN.UTF-8 brave-browser --lang=zh-CN"

exit 0
