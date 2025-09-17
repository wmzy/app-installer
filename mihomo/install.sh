#!/bin/bash
# Mihomo 完整安装脚本
# 支持自动下载和安装

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIHOMO_USER="mihomo"
MIHOMO_HOME="/Users/$MIHOMO_USER"
CURRENT_USER=$(whoami)

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "🚀 开始部署 Mihomo 独立账户环境..."

# 0. 检查并下载 Mihomo 二进制文件
print_info "检查 Mihomo 二进制文件..."
if [[ ! -f "$SCRIPT_DIR/bin/mihomo" ]]; then
    print_warning "未找到 Mihomo 二进制文件，开始下载..."
    cd "$SCRIPT_DIR"
    ./download.sh
fi

# 1. 创建用户账户
print_info "创建用户账户..."
if ! id "$MIHOMO_USER" &>/dev/null; then
    sudo dscl . -create "/Users/$MIHOMO_USER"
    sudo dscl . -create "/Users/$MIHOMO_USER" UserShell /bin/bash
    sudo dscl . -create "/Users/$MIHOMO_USER" RealName "Mihomo Proxy Service"
    sudo dscl . -create "/Users/$MIHOMO_USER" UniqueID 1001
    sudo dscl . -create "/Users/$MIHOMO_USER" PrimaryGroupID 20
    sudo dscl . -create "/Users/$MIHOMO_USER" NFSHomeDirectory "$MIHOMO_HOME"
    
    sudo mkdir -p "$MIHOMO_HOME"
    sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME"
    print_success "用户账户创建完成"
else
    print_success "用户账户已存在"
fi

# 2. 创建目录结构
print_info "创建目录结构..."
sudo -u "$MIHOMO_USER" mkdir -p "$MIHOMO_HOME"/{bin,logs,.config/mihomo,Library/LaunchAgents}
print_success "目录结构创建完成"

# 3. 复制 Mihomo 二进制文件
print_info "复制 Mihomo 二进制文件..."
sudo cp "$SCRIPT_DIR/bin/mihomo" "$MIHOMO_HOME/bin/"
sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/bin/mihomo"
sudo chmod 755 "$MIHOMO_HOME/bin/mihomo"
print_success "二进制文件复制完成"

# 4. 处理配置文件
print_info "处理配置文件..."
cd "$SCRIPT_DIR"
./process-config.sh

sudo cp "$SCRIPT_DIR/config-processed.yaml" "$MIHOMO_HOME/.config/mihomo/config.yaml"
sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/.config/mihomo/config.yaml"
sudo chmod 600 "$MIHOMO_HOME/.config/mihomo/config.yaml"
print_success "配置文件安装完成"

# 5. 复制 LaunchAgent plist 文件
print_info "复制 LaunchAgent 配置..."
sudo cp "$SCRIPT_DIR/com.mihomo.proxy.plist" "$MIHOMO_HOME/Library/LaunchAgents/"
sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
sudo chmod 644 "$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
print_success "LaunchAgent 配置复制完成"

# 6. 设置权限
print_info "设置安全权限..."
sudo chown -R "$MIHOMO_USER:staff" "$MIHOMO_HOME"
sudo chmod 700 "$MIHOMO_HOME"
print_success "权限设置完成"

print_success "Mihomo 独立账户环境部署完成！"
echo ""
print_info "后续步骤:"
echo "1. 编辑配置文件: sudo nano $MIHOMO_HOME/.config/mihomo/config.yaml"
echo "2. 启动服务: sudo launchctl load $MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
echo "3. 检查状态: ps aux | grep mihomo"
echo "4. 查看日志: tail -f $MIHOMO_HOME/logs/mihomo.log"