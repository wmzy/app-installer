# Mihomo 配置与维护指南

## 📋 概述

订阅与主配置分离管理：`config.providers.yaml`（gitignore，含订阅链接）与 `config.yaml`（模板，进版本控制）由 `config.sh` 拼接生成运行配置并热重载。所有运行文件隔离在 `~/.mihomo`。

## 📁 文件说明

**项目目录（本仓库 `mihomo/`）**

| 文件 | 作用 |
|---|---|
| `config.providers.yaml` | 订阅源定义（敏感，已 gitignore；首次从 `.example` 复制） |
| `config.yaml` | 主配置模板：代理组、规则、DNS 等 |
| `config.sh` | 拼接上面两者 → `~/.mihomo/config/config.yaml`，并调 API 热重载 |
| `install.sh` / `uninstall.sh` | 部署 / 卸载（bin、配置、LaunchAgent、日志轮转、升级脚本） |
| `upgrade.sh` | 二进制升级脚本（见下文） |
| `mihomo.sh` | 服务管理脚本，安装到 `/usr/local/bin/mihomo` |
| `clean-log.sh` + `clean-log.plist` | 日志轮转（copytruncate 式） |
| `download.sh` | 交互式下载 release 到项目 `bin/`（一次性安装用） |
| `mihomo.plist` | 服务 LaunchAgent 模板（`MIHOMO_HOME_PLACEHOLDER` 占位） |

**运行目录（`~/.mihomo`）**

```
~/.mihomo/
├── bin/        mihomo, clean-log.sh, upgrade.sh, mihomo.bak(升级备份)
├── config/     config.yaml(生成), providers/(订阅缓存), Geo*.dat
├── logs/       mihomo.log + 轮转归档 .gz
├── cache/      fake-ip 等缓存
└── tmp/
```

## 🔧 修改配置

1. 编辑 `config.providers.yaml`（订阅）或 `config.yaml`（组/规则）
2. 生成并热重载（无需重启服务）：

```bash
cd mihomo
./config.sh
```

注意：Geo 数据库、二进制等文件的变更需要重启服务才生效：`mihomo restart`。

## 🚀 日常命令

```bash
mihomo status        # 服务/进程/代理状态
mihomo start|stop|restart
mihomo reload        # 热重载配置(等同 ./config.sh 的重载)
mihomo logs [N]      # 最近 N 行日志
mihomo follow        # 实时日志
mihomo proxy-on|proxy-off|proxy-status   # 系统代理
mihomo upgrade       # 升级二进制到最新 release
```

## ⬆️ 升级 mihomo

```bash
mihomo upgrade             # 常规: 已是最新则跳过
mihomo upgrade --force     # 强制重装当前最新版
```

流程：`releases/latest` 重定向取版本号（**不走 GitHub API，不受限频影响**）→ 下载对应平台二进制 → 本地 `-v` 冒烟 → 替换（旧版备份为 `mihomo.bak`）→ launchd 重启 → 轮询 `/version` 校验，失败自动回滚 → 从仓库运行时同步 `bin/mihomo` 项目副本。

## 🧹 日志轮转

LaunchAgent `mihomo.clean-log` 每天 04:30 检查 `~/.mihomo/logs/mihomo.log`：超过 **100MB** 才 gzip 归档并原地清空，保留最近 **3 份**。轮转动作记录在 `mihomo.log.clean.log`。

## 📝 配置要点备忘

- **Github 组探测用 `github.com/robots.txt`**，不要用 `api.github.com`：后者消耗出口 IP 的未认证 API 配额（60 次/时），节点健康检查会把自己打到 403
- url-test 组 `tolerance: 150`（过小会导致节点频繁切换）、`interval` 不宜低于 60s
- Geo 数据库已开启自动更新：`geo-auto-update: true`，每 24h
- Apple 域名走"国内"组（国内有 CDN，直连更快）；临时代理在 UI 切组即可
- fake-ip DNS 段当前实际未启用（tun 关闭、无 dns-hijack）；开启 tun 时需重新审查

## 🔒 安全说明

- `config.providers.yaml` 含订阅链接，已 gitignore，权限 600
- `~/.mihomo` 根目录 700，仅当前用户可访问
- ⚠️ `external-controller: 127.0.0.1:9090` 无 secret 且 `allow-lan: true`：局域网内其他设备可使用代理并访问控制 API。家用网络可接受，公共网络环境务必加 `secret:` 或关 `allow-lan`

## 📚 相关文档

- [Mihomo 官方文档](https://wiki.metacubex.one/)
- [配置文件示例](https://wiki.metacubex.one/example/conf/)
- [项目 README](../README.md)
