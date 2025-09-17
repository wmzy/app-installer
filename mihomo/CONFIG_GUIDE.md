# Mihomo 配置指南

## 📋 概述

本项目使用简单的环境变量替换来管理 Mihomo 代理提供商配置，保护敏感的订阅链接信息。

## 🔧 配置流程

### 1. 生成默认配置

运行配置处理脚本会自动创建默认的 `.env` 文件：

```bash
cd mihomo
./process-config.sh
```

### 2. 编辑环境变量

编辑生成的 `.env` 文件，填入实际的代理提供商信息：

```bash
nano .env
```

### 3. 生成最终配置

再次运行配置处理脚本生成最终配置文件：

```bash
./process-config.sh
```

## 📝 环境变量说明

只需要配置两个代理提供商相关的环境变量：

### 代理提供商配置
```bash
# 代理提供商名称
PROXY_PROVIDER_NAME=MyProvider

# 代理订阅链接
PROXY_PROVIDER_URL=https://example.com/subscription
```

**说明：**
- `PROXY_PROVIDER_NAME` - 代理提供商的名称，会替换配置文件中的 `${PROXY_PROVIDER_NAME}`
- `PROXY_PROVIDER_URL` - 代理订阅链接，会替换配置文件中的 `${PROXY_PROVIDER_URL}`

其他网络配置（端口、DNS、TUN 等）都使用固定的默认值，无需通过环境变量配置。

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

### 修改网络配置

如需修改端口、DNS 等网络配置，直接编辑 `config.yaml` 模板文件中的固定值：

```yaml
mixed-port: 7890        # 修改混合端口
external-controller: 127.0.0.1:9090  # 修改控制器地址
allow-lan: true         # 修改局域网访问
```

### 修改默认代理提供商

编辑 `process-config.sh` 中的 `create_default_env()` 函数来修改默认的代理提供商信息。

## 🔍 故障排除

### 配置文件生成失败
- 检查 `.env` 文件是否包含 `PROXY_PROVIDER_NAME` 和 `PROXY_PROVIDER_URL`
- 确保代理订阅链接没有特殊字符冲突
- 查看脚本输出的错误信息

### 环境变量未替换
- 确保 `.env` 文件中的变量名拼写正确
- 检查代理订阅链接是否包含特殊字符（如 `|`），需要适当转义

### 权限问题
- 确保 `process-config.sh` 有执行权限：`chmod +x process-config.sh`
- 检查生成的配置文件是否可读

## 📚 相关文档

- [Mihomo 官方文档](https://wiki.metacubex.one/)
- [配置文件示例](https://wiki.metacubex.one/example/conf/)
- [项目 README](../README.md)
