# Mihomo 配置指南

## 📋 概述

使用极简的字符串替换来管理 Mihomo 代理提供商配置。

## 🔧 配置流程

### 1. 生成默认 .env 文件

```bash
cd mihomo
./process-config.sh  # 会创建默认的 .env 文件
```

### 2. 编辑 .env 文件

```bash
nano .env  # 填入实际的代理信息
```

### 3. 生成配置文件

```bash
./process-config.sh  # 生成 config-processed.yaml
```

## 📝 .env 文件格式

```bash
PROXY_PROVIDER_NAME=你的提供商名称
PROXY_PROVIDER_URL=你的订阅链接
```

脚本会自动将 `config.yaml` 中的 `${PROXY_PROVIDER_NAME}` 和 `${PROXY_PROVIDER_URL}` 替换为实际值。

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

```bash
# 启动 Mihomo
mihomo -f config-processed.yaml
```

或通过安装脚本自动处理：
```bash
./install.sh
```

## 📚 相关文档

- [Mihomo 官方文档](https://wiki.metacubex.one/)
- [配置文件示例](https://wiki.metacubex.one/example/conf/)
- [项目 README](../README.md)
