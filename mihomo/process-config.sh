#!/bin/bash
# 配置文件环境变量处理脚本

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
# Mihomo 配置环境变量
# 请根据实际情况修改以下配置

# 代理提供商配置
PROXY_PROVIDER_NAME=MyProvider
PROXY_PROVIDER_URL=https://example.com/subscription

# 网络配置
MIXED_PORT=7890
EXTERNAL_CONTROLLER=127.0.0.1:9090

# TUN 模式配置 (true/false)
TUN_ENABLE=true

# DNS 配置
DNS_ENABLE=true
DNS_IPV6=true

# 允许局域网访问 (true/false)
ALLOW_LAN=true

# IPv6 支持 (true/false)
IPV6=true

# 外部 UI 配置
EXTERNAL_UI=ui
EXTERNAL_UI_URL=https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip
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
required_vars=(
    "PROXY_PROVIDER_NAME"
    "PROXY_PROVIDER_URL"
    "MIXED_PORT"
    "EXTERNAL_CONTROLLER"
    "TUN_ENABLE"
    "DNS_ENABLE"
    "DNS_IPV6"
    "ALLOW_LAN"
    "IPV6"
    "EXTERNAL_UI"
    "EXTERNAL_UI_URL"
)

missing_vars=()
for var in "${required_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
        missing_vars+=("$var")
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    print_error "缺少必需的环境变量:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

# 处理配置文件
print_info "处理配置文件..."
if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
    print_error "配置模板文件不存在: $CONFIG_TEMPLATE"
    exit 1
fi

# 使用 envsubst 替换环境变量
if command -v envsubst >/dev/null 2>&1; then
    envsubst < "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"
else
    # 如果没有 envsubst，使用 sed 进行简单替换
    print_warning "未找到 envsubst，使用 sed 进行替换..."
    cp "$CONFIG_TEMPLATE" "$CONFIG_OUTPUT"
    
    for var in "${required_vars[@]}"; do
        sed -i.bak "s/\${$var}/${!var}/g" "$CONFIG_OUTPUT"
    done
    rm -f "$CONFIG_OUTPUT.bak"
fi

print_success "配置文件处理完成: $CONFIG_OUTPUT"

# 验证生成的配置文件
if [[ -f "$CONFIG_OUTPUT" ]]; then
    # 检查是否还有未替换的变量
    if grep -q '\${' "$CONFIG_OUTPUT"; then
        print_warning "配置文件中仍有未替换的变量:"
        grep '\${' "$CONFIG_OUTPUT" || true
    else
        print_success "所有环境变量已成功替换"
    fi
    
    print_info "配置文件信息:"
    echo "  - 模板文件: $CONFIG_TEMPLATE"
    echo "  - 环境文件: $ENV_FILE"
    echo "  - 输出文件: $CONFIG_OUTPUT"
    echo ""
    print_info "使用方法:"
    echo "  mihomo -f $CONFIG_OUTPUT"
else
    print_error "配置文件生成失败"
    exit 1
fi
