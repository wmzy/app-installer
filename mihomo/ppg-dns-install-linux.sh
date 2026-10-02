#!/bin/bash
# 安装 ppg 入口 IP 定时刷新 (systemd timer, 每 30 分钟以 root 运行 ppg-dns-update-linux.sh)
# 需 root; 非 root 自动 sudo 重执行。

set -eu

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

for f in ppg-dns-update-linux.sh ppg-dns-update.service ppg-dns-update.timer; do
    [[ -f "$SCRIPT_DIR/$f" ]] || { echo "错误: 缺少 $SCRIPT_DIR/$f" >&2; exit 1; }
done

install -m 644 "$SCRIPT_DIR/ppg-dns-update.service" "$SCRIPT_DIR/ppg-dns-update.timer" /etc/systemd/system/
# unit 里的 ExecStart 占位符替换为仓库实际路径
sed -i "s|REPO_DIR_PLACEHOLDER|$REPO_DIR|" /etc/systemd/system/ppg-dns-update.service

systemctl daemon-reload
systemctl enable --now ppg-dns-update.timer

# 立即刷新一次 (解析 IP 池 -> 写 ppg-hosts.txt -> 注入 hosts -> 热重载)
systemctl start ppg-dns-update.service

echo "ppg 入口定时刷新已安装 (每 30 分钟, timer: ppg-dns-update.timer)"
