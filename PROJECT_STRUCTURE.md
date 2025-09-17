# 项目结构说明

## 📁 目录结构

```
app-installer/
├── .gitignore                      # Git 忽略文件配置
├── README.md                       # 项目说明文档
├── PROJECT_STRUCTURE.md           # 项目结构说明（本文件）
├── download-github-release.sh     # 通用 GitHub Release 下载脚本
│
└── mihomo/                        # Mihomo 代理服务安装包
    ├── bin/                       # 二进制文件目录（被 .gitignore 忽略）
    │   └── mihomo                 # Mihomo 可执行文件
    ├── downloads/                 # 下载文件目录（被 .gitignore 忽略）
    ├── com.mihomo.proxy.plist     # macOS LaunchAgent 配置文件
    ├── download.sh                # Mihomo 专用下载脚本
    ├── install.sh                 # Mihomo 安装脚本
    ├── setup-security.sh          # 安全配置脚本
    └── start-mihomo.sh           # 启动脚本
```

## 🔧 核心脚本说明

### 通用下载脚本
- **`download-github-release.sh`** - 通用的 GitHub Release 下载器
  - 支持智能系统检测和文件匹配
  - 支持交互模式和自动模式
  - 支持多种压缩格式自动解压

### Mihomo 专用脚本
- **`mihomo/download.sh`** - 调用通用下载器下载 Mihomo
- **`mihomo/install.sh`** - 完整安装脚本，包含自动下载功能
- **`mihomo/service-control.sh`** - 服务管理脚本（启动/停止/重启/状态/日志/代理）
- **`mihomo/proxy-settings.sh`** - 系统代理设置脚本（类似 ClashX 功能）
- **`mihomo/uninstall.sh`** - 完整卸载脚本，清理所有组件
- **`mihomo/com.mihomo.proxy.plist`** - macOS 系统服务配置

## 🚫 被忽略的文件和目录

以下文件和目录被 `.gitignore` 忽略，不会提交到版本控制：

### 下载和构建产物
- `downloads/` 和 `*/downloads/` - 所有下载目录
- `bin/` 和 `*/bin/` - 所有二进制文件目录
- 各种压缩文件格式（`.gz`, `.zip`, `.tar` 等）
- 编译产物（`.exe`, `.dll`, `.so` 等）

### 配置和敏感文件
- `config.yaml` - 可能包含敏感配置信息
- `.env*` - 环境变量文件
- 证书和密钥文件（`.pem`, `.key`, `.crt` 等）

### 系统和临时文件
- `.DS_Store` - macOS 系统文件
- `*.log` - 日志文件
- `logs/` - 日志目录
- IDE 配置目录（`.vscode/`, `.idea/` 等）

## 🔄 工作流程

### 开发和贡献
1. 克隆仓库后，运行相应的下载脚本获取二进制文件
2. 修改脚本时，只提交源代码，不提交下载的文件
3. 配置文件模板可以提交，但实际的配置文件不应提交

### 用户使用
1. 克隆或下载项目
2. 运行 `./download-github-release.sh` 或项目特定的下载脚本
3. 运行安装脚本完成部署

## 📋 版本控制策略

- ✅ **包含**: 源代码、脚本、配置模板、文档
- ❌ **排除**: 下载文件、编译产物、个人配置、敏感信息
- 🔒 **保护**: 配置文件、密钥、个人数据
