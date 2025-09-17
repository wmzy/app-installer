# Mihomo 配置指南

## 📋 概述

本项目使用环境变量来管理 Mihomo 配置，支持灵活的配置管理和敏感信息保护。

## 🔧 配置流程

### 1. 生成默认配置

运行配置处理脚本会自动创建默认的 `.env` 文件：

```bash
cd mihomo
./process-config.sh
```

### 2. 编辑环境变量

编辑生成的 `.env` 文件，填入实际配置值：

```bash
nano .env
```

### 3. 生成最终配置

再次运行配置处理脚本生成最终配置文件：

```bash
./process-config.sh
```

## 📝 环境变量说明

### 代理提供商配置
```bash
# 代理提供商名称
PROXY_PROVIDER_NAME=MyProvider

# 代理订阅链接
PROXY_PROVIDER_URL=https://example.com/subscription
```

### 网络配置
```bash
# 混合端口（HTTP + SOCKS5）
MIXED_PORT=7890

# 外部控制器地址
EXTERNAL_CONTROLLER=127.0.0.1:9090

# 允许局域网访问
ALLOW_LAN=true

# IPv6 支持
IPV6=true
```

### TUN 模式配置
```bash
# 启用 TUN 模式
TUN_ENABLE=true
```

### DNS 配置
```bash
# 启用 DNS
DNS_ENABLE=true

# DNS IPv6 支持
DNS_IPV6=true
```

### 外部 UI 配置
```bash
# 外部 UI 目录名
EXTERNAL_UI=ui

# 外部 UI 下载链接
EXTERNAL_UI_URL=https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
```

## 📁 文件说明

- **`config.yaml`** - 配置模板文件（包含环境变量占位符）
- **`.env`** - 环境变量文件（包含实际配置值）
- **`config-processed.yaml`** - 生成的最终配置文件
- **`process-config.sh`** - 配置处理脚本

## 🔒 安全注意事项

1. **`.env` 文件包含敏感信息**，已被 `.gitignore` 忽略
2. **`config-processed.yaml`** 包含处理后的配置，也被忽略
3. 只有 **`config.yaml`** 模板文件会被提交到版本控制

## 🚀 使用方法

### 手动使用
```bash
# 生成配置
./process-config.sh

# 启动 Mihomo
mihomo -f config-processed.yaml
```

### 通过安装脚本
```bash
# 安装脚本会自动处理配置
./install.sh
```

## 🛠️ 自定义配置

### 添加新的环境变量

1. 在 `config.yaml` 中添加占位符：
   ```yaml
   new-option: ${NEW_OPTION}
   ```

2. 在 `process-config.sh` 中添加到 `required_vars` 数组：
   ```bash
   required_vars=(
       # ... 现有变量
       "NEW_OPTION"
   )
   ```

3. 在 `.env` 文件中添加实际值：
   ```bash
   NEW_OPTION=actual_value
   ```

### 修改默认值

编辑 `process-config.sh` 中的 `create_default_env()` 函数来修改默认值。

## 🔍 故障排除

### 配置文件生成失败
- 检查 `.env` 文件是否包含所有必需的变量
- 确保环境变量值没有特殊字符冲突
- 查看脚本输出的错误信息

### 环境变量未替换
- 确保变量名在 `config.yaml` 中使用 `${VARIABLE_NAME}` 格式
- 检查变量名是否在 `required_vars` 数组中
- 验证 `.env` 文件中的变量名拼写

### 权限问题
- 确保 `process-config.sh` 有执行权限
- 检查生成的配置文件是否可读

## 📚 相关文档

- [Mihomo 官方文档](https://wiki.metacubex.one/)
- [配置文件示例](https://wiki.metacubex.one/example/conf/)
- [项目 README](../README.md)
