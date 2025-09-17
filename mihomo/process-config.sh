#!/bin/bash
# 简化的配置文件处理脚本 - 只处理代理提供商配置

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.yaml"
CONFIG_OUTPUT="$SCRIPT_DIR/config-processed.yaml"
ENV_FILE="$SCRIPT_DIR/.env"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 创建默认 .env 文件
create_default_env() {
    cat > "$ENV_FILE" << 'EOF'
# Mihomo 代理提供商配置
# 请根据实际情况修改以下配置

# 代理提供商名称
PROXY_PROVIDER_NAME=MyProvider

# 代理订阅链接
PROXY_PROVIDER_URL=https://example.com/subscription
EOF
}

# 检查 .env 文件
if [[ ! -f "$ENV_FILE" ]]; then
    print_warning "未找到 .env 文件，创建默认配置..."
    create_default_env
    print_success "已创建默认 .env 文件: $ENV_FILE"
    print_info "请编辑 .env 文件填入实际配置值"
fi

# 加载环境变量
print_info "加载环境变量..."
set -a  # 自动导出所有变量
source "$ENV_FILE"
set +a

# 验证必需的环境变量
if [[ -z "${PROXY_PROVIDER_NAME:-}" ]]; then
    print_error "缺少必需的环境变量: PROXY_PROVIDER_NAME"
    exit 1
fi

if [[ -z "${PROXY_PROVIDER_URL:-}" ]]; then
    print_error "缺少必需的环境变量: PROXY_PROVIDER_URL"
    exit 1
fi

# 处理配置文件
print_info "处理配置文件..."
if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
    print_error "配置模板文件不存在: $CONFIG_TEMPLATE"
    exit 1
fi

# 使用 sed 进行简单的字符串替换
print_info "替换代理提供商配置..."
sed "s/\${PROXY_PROVIDER_NAME}/$PROXY_PROVIDER_NAME/g; s|\${PROXY_PROVIDER_URL}|$PROXY_PROVIDER_URL|g" "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

print_success "配置文件处理完成: $CONFIG_OUTPUT"

# 验证生成的配置文件
if [[ -f "$CONFIG_OUTPUT" ]]; then
    # 检查是否还有未替换的代理提供商变量
    if grep -q '\${PROXY_PROVIDER_' "$CONFIG_OUTPUT"; then
        print_warning "配置文件中仍有未替换的代理提供商变量:"
        grep '\${PROXY_PROVIDER_' "$CONFIG_OUTPUT" || true
    else
        print_success "代理提供商配置已成功替换"
    fi
    
    print_info "配置文件信息:"
    echo "  - 模板文件: $CONFIG_TEMPLATE"
    echo "  - 环境文件: $ENV_FILE"
    echo "  - 输出文件: $CONFIG_OUTPUT"
    echo "  - 提供商名称: $PROXY_PROVIDER_NAME"
    echo "  - 订阅链接: $PROXY_PROVIDER_URL"
    echo ""
    print_info "使用方法:"
    echo "  mihomo -f $CONFIG_OUTPUT"
else
    print_error "配置文件生成失败"
    exit 1
fi