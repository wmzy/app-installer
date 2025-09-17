#!/bin/bash
# 极简配置处理脚本 - 直接字符串替换

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.yaml"
CONFIG_OUTPUT="$SCRIPT_DIR/config-processed.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

# 如果没有 .env 文件，创建默认的
if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << 'EOF'
PROXY_PROVIDER_NAME=MyProvider
PROXY_PROVIDER_URL=https://example.com/subscription
EOF
    echo "已创建默认 .env 文件，请编辑后重新运行"
    exit 0
fi

# 加载环境变量并进行字符串替换
source "$ENV_FILE"
sed "s/\${PROXY_PROVIDER_NAME}/$PROXY_PROVIDER_NAME/g; s|\${PROXY_PROVIDER_URL}|$PROXY_PROVIDER_URL|g" "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

echo "配置文件已生成: $CONFIG_OUTPUT"