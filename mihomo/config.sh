#!/bin/bash
# 极简配置处理脚本 - 直接字符串替换

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.yaml"
CONFIG_PROVIDERS_FILE="$SCRIPT_DIR/config.providers.yaml"
MIHOMO_HOME="$HOME/.mihomo"
CONFIG_OUTPUT="$MIHOMO_HOME/config/config.yaml"

# 如果没有 config.providers.yaml 文件，创建默认的
if [[ ! -f "$CONFIG_PROVIDERS_FILE" ]]; then
    cp "$SCRIPT_DIR/$CONFIG_PROVIDERS_FILE.example" "$CONFIG_PROVIDERS_FILE"
    echo "已创建默认 config.providers.yaml 文件，请编辑后重新运行"
    exit 0
fi

# 合并 config.providers.yaml 和 config.yaml
cat "$CONFIG_PROVIDERS_FILE" "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

echo "配置文件已生成: $CONFIG_OUTPUT"

chmod 600 "$CONFIG_OUTPUT"

curl 'http://127.0.0.1:9090/configs?force=true' -X 'PUT' --data-raw '{"path":"","payload":""}' 2>/dev/null

echo "配置文件安装完成"
