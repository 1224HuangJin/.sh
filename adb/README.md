# ADB 快捷方式
## 介绍：
一个给Chromebook ADB的快捷方式（仅自用）

## 使用教程：
首先下载：
``` sh
wget https://raw.githubusercontent.com/1224HuangJin/adb/refs/heads/main/adb.sh
```

随后运行：
``` sh
. adb.sh
```

### 它能做什么？(By AI)
- 🚀 **一键导航**：自动切换到 ChromeOS 共享文件夹下的 `MyFiles/Downloads/linux` 目录（方便存放 APK）。
- 🔌 **自动连接 ADB**：检测并执行 `adb connect arc`，免去手动输入。
- 📱 **显示设备信息**：输出 Android 版本、SDK 级别、型号等关键参数，便于调试或问题排查。
- 💡 **给出安装提示**：展示标准的 `adb install` 命令示例，让您直接粘贴使用。

### 适用场景 (By AI)
- 在 Chromebook 上开发或测试 Android 应用(或纯下载)。
- 需要频繁通过 ADB 安装 APK 到 ARC 环境。
- 想要一个简洁的命令行工具，省去重复的 `cd`、`adb connect` 和查看设备状态步骤。
