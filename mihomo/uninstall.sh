#!/bin/bash
# Mihomo 完整卸载脚本

set -e

# 颜色输出函数
print_info() { echo -e "\033[36m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# 配置
CURRENT_USER=$(whoami)
MIHOMO_HOME="$HOME/.mihomo"
PLIST_PATH="$HOME/Library/LaunchAgents/mihomo.plist"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_warning "⚠️  即将完全卸载 Mihomo 代理服务"
echo ""
print_info "将执行以下操作："
echo "1. 停止并卸载 LaunchAgent 服务"
echo "2. 删除 ~/.mihomo 目录和所有文件"
echo "3. 清理 LaunchAgent 配置文件"
echo ""

# 确认操作
read -p "确定要继续吗？这个操作不可逆转 [y/N]: " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "操作已取消"
    exit 0
fi

echo ""
print_info "开始卸载 Mihomo..."

# 1. 停止并卸载服务
print_info "停止 Mihomo 服务..."

# 检查服务是否存在并停止
if launchctl list | grep -q "mihomo" 2>/dev/null; then
    print_info "发现运行中的服务，正在停止..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    print_success "服务已停止"
else
    print_info "服务未运行"
fi

# 强制终止可能残留的进程
if pgrep -f "mihomo" > /dev/null 2>&1; then
    print_info "终止残留的 mihomo 进程..."
    pkill -f mihomo || true
    sleep 2
    
    # 如果还有进程，强制终止
    if pgrep -f "mihomo" > /dev/null 2>&1; then
        print_warning "强制终止顽固进程..."
        pkill -9 -f mihomo || true
    fi
    print_success "进程已清理"
fi

# 2. 删除 Mihomo 目录和所有文件
print_info "删除 Mihomo 目录和所有相关文件..."

if [[ -d "$MIHOMO_HOME" ]]; then
    print_info "删除目录: $MIHOMO_HOME"
    rm -rf "$MIHOMO_HOME"
    print_success "Mihomo 目录已删除"
else
    print_info "Mihomo 目录不存在，跳过"
fi

# 3. 删除 LaunchAgent plist 文件
print_info "删除 LaunchAgent 配置文件..."

if [[ -f "$PLIST_PATH" ]]; then
    print_info "删除文件: $PLIST_PATH"
    rm -f "$PLIST_PATH"
    print_success "LaunchAgent 配置文件已删除"
else
    print_info "LaunchAgent 配置文件不存在，跳过"
fi

# 4. 验证清理结果
print_info "验证卸载结果..."

# 检查进程是否还在运行
if pgrep -f "mihomo" > /dev/null 2>&1; then
    print_warning "发现残留的 mihomo 进程"
    ps aux | grep mihomo | grep -v grep
else
    print_success "✅ 没有残留进程"
fi

# 检查目录是否还存在
if [[ -d "$MIHOMO_HOME" ]]; then
    print_warning "Mihomo 目录仍然存在: $MIHOMO_HOME"
else
    print_success "✅ Mihomo 目录已完全删除"
fi

# 检查 plist 文件是否还存在
if [[ -f "$PLIST_PATH" ]]; then
    print_warning "LaunchAgent 配置文件仍然存在: $PLIST_PATH"
else
    print_success "✅ LaunchAgent 配置文件已删除"
fi

# 检查服务是否还在
if launchctl list | grep -q "mihomo" 2>/dev/null; then
    print_warning "LaunchAgent 服务仍在列表中"
else
    print_success "✅ LaunchAgent 服务已清理"
fi

echo ""
print_success "🎉 Mihomo 卸载完成！"
echo ""
print_info "已清理的内容："
echo "• Mihomo 目录 ($MIHOMO_HOME)"
echo "• LaunchAgent 服务配置"
echo "• LaunchAgent plist 文件"
echo "• 所有相关进程"
echo "• 本地下载的二进制文件"
echo "• 临时和缓存文件"
echo ""

# 检查是否有其他相关文件
print_info "检查系统中是否还有其他 mihomo 相关文件..."

# 搜索可能的残留文件（仅显示，不删除）
POTENTIAL_FILES=(
    "/usr/local/bin/mihomo"
    "/opt/mihomo"
    "/etc/mihomo"
    "/var/log/mihomo"
    "/tmp/mihomo*"
)

FOUND_FILES=()
for file_pattern in "${POTENTIAL_FILES[@]}"; do
    if ls $file_pattern > /dev/null 2>&1; then
        FOUND_FILES+=("$file_pattern")
    fi
done

if [[ ${#FOUND_FILES[@]} -gt 0 ]]; then
    print_warning "发现可能的残留文件："
    for file in "${FOUND_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    print_info "如需删除这些文件，请手动检查并删除"
else
    print_success "✅ 未发现其他残留文件"
fi

echo ""
print_info "如果需要重新安装 Mihomo，请运行:"
echo "  $SCRIPT_DIR/install.sh"
