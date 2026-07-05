#!/bin/sh

echo""
echo -e "正在导航到(cd)："
echo -e "\e[32m/mnt/chromeos/shared/MyFiles/Downloads/linux\e[0m..."
echo ""

TARGET="/mnt/chromeos/shared/MyFiles/Downloads/linux"
if [ ! -d "$TARGET" ]; then
    echo "错误：目标目录不存在，请检查路径。" >&2
    exit 1
fi
cd "$TARGET" || {
    echo "错误：无法切换到目录 $TARGET" >&2
    exit 1
}

echo "当前目录(pwd):"
echo -e "\e[32m$(pwd 2>/dev/null || echo '无法获取') \e[0m" 

echo""
echo "当前目录下文件(ls)："
ls

echo ""
echo "连接ADB中(adb connect arc).."
if ! command -v adb >/dev/null 2>&1; then
    echo "错误：未找到 adb 命令，请安装 Android SDK Platform-Tools。" >&2
    exit 1
fi

adb connect arc
if ! adb devices | grep -q "arc.*device"; then
    echo "警告：ADB 连接 arc 可能未成功，请检查 ARC 是否运行。" >&2
fi
echo ""

{
echo ""
echo "--------- 设备信息（若安装失败可给AI附上） ---------"
echo -e "  \033[0;34mAndroid 版本(adb shell getprop)  : \033[0m$(adb shell getprop ro.build.version.release 2>/dev/null || echo '无法获取')"
echo -e  "  \033[0;34mSDK 版本(adb shell getprop)      : \033[0m$(adb shell getprop ro.build.version.sdk 2>/dev/null || echo '无法获取')"
echo -e "  \033[0;34m设备型号(adb shell getprop)      : \033[0m$(adb shell getprop ro.product.model 2>/dev/null || echo '无法获取')"
echo -e "  \033[0;34m制造商(adb shell getprop)        : \033[0m$(adb shell getprop ro.product.manufacturer 2>/dev/null || echo '无法获取')"
echo -e "  \033[0;34m设备支持的AB(adb shell getprop)I : \033[0m$(adb shell getprop ro.product.cpu.abilist 2>/dev/null || echo '无法获取')"
echo -e "  \033[0;34m已连接设备列表(adb shell getprop):\033[0m"
adb devices | grep -v "List" | grep -v "^$" | sed 's/^/      /'
echo "------------------------------------------------------"
} | while read line; do echo "$line"; done


echo ""


echo -e "请使用以下命令以安装 APK："
echo -e "  \033[0;35madb install\033[0m \033[0;32m<包名>.apk\033[0m"
echo -e " 例如：\033[0;36madb install \"MyApp.apk\"\033[0m"
echo""
echo "您可以安装(ls)："
ls
