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
    
    # 运行下载脚本
    cd "$SCRIPT_DIR"
    ./download.sh
    
    # 再次检查是否下载成功
    if [[ ! -f "$SCRIPT_DIR/bin/mihomo" ]]; then
        echo "❌ 下载失败，请检查网络连接或手动下载"
        exit 1
    fi
else
    print_success "找到 Mihomo 二进制文件: $SCRIPT_DIR/bin/mihomo"
    
    # 显示当前版本信息
    print_info "当前版本:"
    "$SCRIPT_DIR/bin/mihomo" -v
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
if [[ -f "$SCRIPT_DIR/bin/mihomo" ]]; then
    sudo cp "$SCRIPT_DIR/bin/mihomo" "$MIHOMO_HOME/bin/"
    sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/bin/mihomo"
    sudo chmod 755 "$MIHOMO_HOME/bin/mihomo"
    print_success "二进制文件复制完成"
else
    print_warning "未找到二进制文件: $SCRIPT_DIR/bin/mihomo"
    echo "这不应该发生，因为我们已经在步骤 0 中检查过了"
    exit 1
fi

# 4. 处理配置文件
print_info "处理配置文件..."

# 检查是否有配置处理脚本
if [[ -f "$SCRIPT_DIR/process-config.sh" ]]; then
    print_info "运行配置处理脚本..."
    cd "$SCRIPT_DIR"
    ./process-config.sh
    
    # 检查是否生成了处理后的配置文件
    if [[ -f "$SCRIPT_DIR/config-processed.yaml" ]]; then
        sudo cp "$SCRIPT_DIR/config-processed.yaml" "$MIHOMO_HOME/.config/mihomo/config.yaml"
        sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/.config/mihomo/config.yaml"
        sudo chmod 600 "$MIHOMO_HOME/.config/mihomo/config.yaml"
        print_success "环境变量配置文件安装完成"
    elif [[ -f "$SCRIPT_DIR/.env" ]]; then
        print_warning "配置处理脚本运行完成，但未生成配置文件"
        print_info "请检查 .env 文件并重新运行配置处理脚本"
    else
        print_info "已创建默认 .env 文件，请编辑后重新运行安装脚本"
        exit 0
    fi
elif [[ -f "$SCRIPT_DIR/config.yaml" ]]; then
    # 如果有模板配置文件但没有处理脚本，直接复制
    print_warning "找到配置模板但没有处理脚本，直接复制配置文件"
    sudo cp "$SCRIPT_DIR/config.yaml" "$MIHOMO_HOME/.config/mihomo/"
    sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/.config/mihomo/config.yaml"
    sudo chmod 600 "$MIHOMO_HOME/.config/mihomo/config.yaml"
    print_success "配置文件复制完成"
else
    print_warning "未找到配置文件，将创建基础配置模板"
    # 创建基础配置文件
    sudo -u "$MIHOMO_USER" cat > "$MIHOMO_HOME/.config/mihomo/config.yaml" << 'EOF'
# Mihomo 基础配置
# 请根据需要修改此配置文件

mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

dns:
  enable: true
  enhanced-mode: fake-ip
  nameserver:
    - 114.114.114.114
    - 8.8.8.8

proxies:
  - name: "直连"
    type: direct

proxy-groups:
  - name: "默认"
    type: select
    proxies:
      - "直连"

rules:
  - MATCH,默认
EOF
    print_success "基础配置文件创建完成"
fi

# 5. 复制 LaunchAgent plist 文件
print_info "复制 LaunchAgent 配置..."
if [[ -f "$SCRIPT_DIR/com.mihomo.proxy.plist" ]]; then
    sudo cp "$SCRIPT_DIR/com.mihomo.proxy.plist" "$MIHOMO_HOME/Library/LaunchAgents/"
    sudo chown "$MIHOMO_USER:staff" "$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
    sudo chmod 644 "$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
    print_success "LaunchAgent 配置复制完成"
else
    print_warning "未找到 LaunchAgent 配置文件: com.mihomo.proxy.plist"
fi

# 6. 设置权限
print_info "设置安全权限..."
sudo chown -R "$MIHOMO_USER:staff" "$MIHOMO_HOME"
sudo chmod 700 "$MIHOMO_HOME"
print_success "权限设置完成"

print_success "Mihomo 独立账户环境部署完成！"
echo ""
print_info "后续步骤:"
echo "1. 编辑配置文件: sudo -u $MIHOMO_USER nano $MIHOMO_HOME/.config/mihomo/config.yaml"
echo "2. 启动服务: sudo -u $MIHOMO_USER launchctl load $MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"
echo "3. 检查状态: ps aux | grep mihomo"
echo "4. 查看日志: tail -f $MIHOMO_HOME/logs/mihomo.log"