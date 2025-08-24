#!/bin/bash
set -e

# ========== 欢迎界面 ==========
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
echo " - 文档：https://support.brave.app/hc/zh-tw/articles/7816553516045"
echo " - 有问题可以发邮件：1224huangjin@gmail.com"
echo

read -p "准备好了吗？要继续安装 Brave 浏览器吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "好啦，那我们下次再见，祝你生活愉快！👋"
  exit 0
fi

echo
echo "开始安装流程啦！🚀"
echo

# ========== 语言选择 ==========
echo "请选择语言设置方式："
echo " 1) 修改整个 Linux 系统语言为 中文简体"
echo " 2) 仅 Brave 浏览器改中文（推荐）"
read -p "请输入 1 或 2 (默认 2): " lang_choice
lang_choice=${lang_choice:-2}

# ========== 第1步：安装依赖 ==========
echo "🌐 [1/6] 安装必要依赖..."
sudo apt update
sudo apt install -y curl gnupg ca-certificates apt-transport-https software-properties-common locales

if [[ "$lang_choice" == "1" ]]; then
  echo "⚙️ 正在配置系统语言为 中文简体..."
  if ! grep -q '^zh_CN.UTF-8 UTF-8' /etc/locale.gen; then
    echo "zh_CN.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen > /dev/null
  else
    sudo sed -i '/^#.*zh_CN.UTF-8 UTF-8/s/^#//' /etc/locale.gen
  fi
  sudo locale-gen
  sudo update-locale LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8
  echo "✅ 系统语言已改为中文简体。请注销或重启系统后生效。"
else
  echo "⚙️ 系统语言保持不变，仅 Brave 浏览器改中文。"
fi

# ========== 第2步：添加 GPG 和源 ==========
echo "🔐 [2/6] 添加 Brave 官方 GPG 密钥和软件源..."
arch=$(dpkg --print-architecture)

# GPG key
if [[ -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]]; then
  echo "✅ Brave GPG 密钥已存在，跳过下载。"
else
  echo "⬇️ 正在下载 Brave GPG 密钥..."
  sudo curl --retry 3 -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
fi

# sources.list
if [[ -f /etc/apt/sources.list.d/brave-browser-release.sources ]] && \
   grep -q "brave-browser-apt-release.s3.brave.com" /etc/apt/sources.list.d/brave-browser-release.sources; then
  echo "✅ Brave 软件源已存在，跳过添加。"
else
  echo "📝 写入 Brave 软件源..."
  if ! cat <<EOF | sudo tee /etc/apt/sources.list.d/brave-browser-release.sources > /dev/null
Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com/
Suites: stable
Components: main
Architectures: $arch
Signed-By: /usr/share/keyrings/brave-browser-archive-keyring.gpg
EOF
  then
    echo "⚠️ 写入失败，尝试直接下载官方 sources 文件..."
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
      https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  fi
fi

# ========== 第3步：安装 Brave ==========
echo "📦 [3/6] 安装 Brave 浏览器..."
sudo apt update
sudo apt install -y brave-browser

# ========== 第4步：自定义启动器名称 ==========
echo "🖥️ [4/6] 设置启动器名称（默认：Brave 浏览器）"
read -p "启动器名称：" launcher_name
launcher_name=${launcher_name:-"Brave 浏览器"}

# ========== 第5步：创建中文启动器 ==========
echo "🚀 [5/6] 创建自定义启动器：“$launcher_name”..."
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
Comment=使用中文语言启动 Brave 浏览器 (来自→ https://github.com/1224HuangJin/Linux/Brave-zh.sh )
Exec=$exec_line
Icon=brave-browser
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

# ========== 第6步：是否隐藏原版启动器 ==========
echo "😶‍🌫 [6/6] 要不要隐藏系统自带的英文启动器？[y/N]"
read -r hide_choice
if [[ "$hide_choice" =~ ^[Yy]$ ]]; then
  echo "🤭 正在隐藏原版启动器..."
  for f in /usr/share/applications/brave-browser.desktop /usr/share/applications/com.brave.Browser.desktop; do
    if [[ -f "$f" ]]; then
      sudo sed -i '/^NoDisplay=true/d' "$f"
      echo "NoDisplay=true" | sudo tee -a "$f" > /dev/null
    fi
  done
  echo "😋 隐藏成功！菜单里就只剩你的中文启动器啦~"
else
  echo "😔 保留了原版启动器，菜单里会显示两个 Brave 浏览器哦。"
fi

# ========== 完成 ==========
echo
echo "🎉 全部搞定！你可以在菜单找到 “$launcher_name”，开心地用中文启动啦！"
echo "🧑‍💻 命令行启动方式（备用）："
echo "  LANG=zh_CN.UTF-8 brave-browser --lang=zh-CN"

exit 0
