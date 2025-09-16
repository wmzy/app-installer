#!/bin/bash
# Mihomo 安全启动脚本

set -euo pipefail

# 配置变量
MIHOMO_HOME="/Users/mihomo"
MIHOMO_CONFIG_DIR="$MIHOMO_HOME/.config/mihomo"
MIHOMO_BIN="$MIHOMO_HOME/bin/mihomo"
LOG_FILE="$MIHOMO_HOME/logs/mihomo.log"

# 创建必要目录
mkdir -p "$MIHOMO_CONFIG_DIR"
mkdir -p "$MIHOMO_HOME/logs"
mkdir -p "$MIHOMO_HOME/bin"

# 检查配置文件
if [[ ! -f "$MIHOMO_CONFIG_DIR/config.yaml" ]]; then
    echo "❌ 配置文件不存在: $MIHOMO_CONFIG_DIR/config.yaml"
    exit 1
fi

# 检查可执行文件
if [[ ! -f "$MIHOMO_BIN" ]]; then
    echo "❌ Mihomo 可执行文件不存在: $MIHOMO_BIN"
    exit 1
fi

# 验证文件完整性（可选）
if command -v shasum >/dev/null; then
    echo "🔍 验证文件完整性..."
    # 这里可以添加 checksum 验证
fi

# 设置环境变量
export CLASH_HOME_DIR="$MIHOMO_CONFIG_DIR"
export CLASH_CONFIG_FILE="$MIHOMO_CONFIG_DIR/config.yaml"

# 启动 Mihomo
echo "🚀 启动 Mihomo..."
echo "   配置目录: $MIHOMO_CONFIG_DIR"
echo "   日志文件: $LOG_FILE"

cd "$MIHOMO_HOME"
exec "$MIHOMO_BIN" -d "$MIHOMO_CONFIG_DIR" >> "$LOG_FILE" 2>&1