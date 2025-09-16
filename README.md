# App Installer

通用的应用程序安装脚本集合，支持从 GitHub Release 自动下载适配当前系统的软件包。

## 通用下载脚本

`download-github-release.sh` 是一个通用的 GitHub Release 下载脚本，能够：

- 自动检测当前系统的操作系统和架构
- 从指定的 GitHub 仓库获取最新或指定版本的 release
- 智能匹配适合当前系统的软件包
- 支持多种文件命名模式的模糊匹配

### 用法

```bash
# 基本用法
./download-github-release.sh [选项] <owner/repo> [version] [output_dir]

# 查看帮助
./download-github-release.sh --help

# 示例：交互模式（用户选择版本）
./download-github-release.sh MetaCubeX/mihomo

# 示例：自动模式（自动选择第一个匹配的文件）
./download-github-release.sh --auto MetaCubeX/mihomo

# 示例：下载指定版本到指定目录
./download-github-release.sh MetaCubeX/mihomo v1.18.0 ./downloads

# 示例：下载其他项目
./download-github-release.sh --auto prometheus/prometheus latest ./prometheus
```

### 选项说明

- `-a, --auto` - 自动选择第一个匹配的文件，不询问用户（适用于脚本自动化）
- `-h, --help` - 显示帮助信息

### 支持的系统

- **操作系统**: macOS (darwin), Linux, Windows
- **架构**: x86_64/amd64, ARM64/aarch64, ARMv7, ARMv6, i386

### 特性

- 🔍 智能系统检测
- 📦 自动匹配合适的软件包
- 👤 用户选择模式 - 当有多个匹配文件时支持用户选择
- 🤖 自动选择模式 - 适用于脚本自动化
- 🌈 彩色输出和进度显示
- 📋 详细的下载信息
- 🔄 支持 curl 和 wget
- 📂 自动创建输出目录

## 项目示例

### Mihomo 代理服务

在 `mihomo/` 目录下包含了完整的 Mihomo 代理服务安装脚本：

```bash
# 下载 Mihomo
cd mihomo
./download.sh

# 安装 Mihomo 服务
./install.sh
```

## 添加新项目

要为新项目添加下载脚本：

1. 创建项目目录
2. 创建项目特定的下载脚本，调用通用下载器
3. 添加安装和配置脚本

示例项目结构：
```
your-app/
├── download.sh      # 调用通用下载器
├── install.sh       # 安装脚本
└── config/          # 配置文件
```

## 系统要求

- Bash 4.0+
- curl 或 wget
- 标准 Unix 工具 (grep, sed, awk)
