#!/bin/bash
# mihomo 日志轮转脚本 (copytruncate 方式: 归档后原地清空, 不依赖 mihomo 重开文件)
# 由 LaunchAgent (mihomo.clean-log) 每天 04:30 调用, 也可手动执行: clean-log.sh [日志路径]
# 规则: 超过 100MB 才轮转, gzip 归档, 保留最近 3 份, 轮转动作记录在 <日志>.clean.log

set -eu

LOG="${1:-$HOME/.mihomo/logs/mihomo.log}"
KEEP=3
THRESHOLD=$((100 * 1024 * 1024))  # 100MB

[ -f "$LOG" ] || exit 0

size=$(stat -f%z "$LOG" 2>/dev/null || echo 0)
if [ "$size" -lt "$THRESHOLD" ]; then
    exit 0
fi

archive="$LOG.$(date +%Y%m%d-%H%M%S).gz"
while [ -e "$archive" ]; do
    archive="$LOG.$(date +%Y%m%d-%H%M%S)-$RANDOM.gz"
done
gzip -c "$LOG" > "$archive"
: > "$LOG"
echo "$(date '+%Y-%m-%d %H:%M:%S') rotated ${size} bytes -> $(basename "$archive")" >> "$LOG.clean.log"

# 只保留最近 KEEP 份归档
ls -t "$LOG".*.gz 2>/dev/null | tail -n +"$((KEEP + 1))" | while IFS= read -r old; do
    rm -f "$old"
done

exit 0
