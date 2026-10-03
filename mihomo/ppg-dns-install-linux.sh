#!/bin/bash
# 安装 ppg 入口 IP 定时刷新 (systemd timer, 每 30 分钟以 root 运行刷新脚本)
# 需 root; 非 root 自动 sudo 重执行。

set -eu

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for f in ppg-dns-update-linux.sh ppg-dns-update.service ppg-dns-update.timer; do
    [[ -f "$SCRIPT_DIR/$f" ]] || { echo "错误: 缺少 $SCRIPT_DIR/$f" >&2; exit 1; }
done

install -m 644 "$SCRIPT_DIR/ppg-dns-update.service" "$SCRIPT_DIR/ppg-dns-update.timer" /etc/systemd/system/

# systemd 无法 exec /home 下的脚本 (SELinux: init_t 禁止 execute user_home_t,
# 报 203/EXEC)。把刷新脚本副本装到 /usr/local/sbin (bin_t) 作为 ExecStart 入口,
# 占位符替换为仓库 mihomo 目录, 服务进程在 unconfined_service_t 域运行。
install -D -m 755 <(sed "s|MIHOMO_DIR_PLACEHOLDER|$SCRIPT_DIR|g" \
    "$SCRIPT_DIR/ppg-dns-update-linux.sh") /usr/local/sbin/ppg-dns-update

systemctl daemon-reload
systemctl enable --now ppg-dns-update.timer

# 立即刷新一次 (解析 IP 池 -> 写 ppg-hosts.txt -> 注入 hosts -> 热重载)
systemctl start ppg-dns-update.service

echo "ppg 入口定时刷新已安装 (每 30 分钟, timer: ppg-dns-update.timer)"
