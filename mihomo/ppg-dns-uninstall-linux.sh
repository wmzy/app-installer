#!/bin/bash
# 卸载 ppg 入口 IP 定时刷新
# 需 root; 非 root 自动 sudo 重执行。

set -eu

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

systemctl disable --now ppg-dns-update.timer 2>/dev/null || true
systemctl stop ppg-dns-update.service 2>/dev/null || true
rm -f /etc/systemd/system/ppg-dns-update.service /etc/systemd/system/ppg-dns-update.timer
systemctl daemon-reload

# 删除数据文件并重新生成配置, 移除已注入的 hosts
rm -f /etc/mihomo/ppg-hosts.txt
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/config-linux.sh"

echo "ppg 入口定时刷新已卸载 (配置中的 hosts 已在下次生成时移除)"
