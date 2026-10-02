#!/bin/bash
# Mihomo 安装脚本
# 以当前用户运行，文件隔离在 ~/.mihomo 目录

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER=$(whoami)
MIHOMO_HOME="$HOME/.mihomo"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "🚀 开始部署 Mihomo 环境..."

# 0. 检查并下载 Mihomo 二进制文件
print_info "检查 Mihomo 二进制文件..."
if [[ ! -f "$SCRIPT_DIR/bin/mihomo" ]]; then
    print_warning "未找到 Mihomo 二进制文件，开始下载..."
    cd "$SCRIPT_DIR"
    ./download.sh
fi

# 1. 创建目录结构
print_info "创建目录结构..."
mkdir -p "$MIHOMO_HOME"/{bin,config,logs,cache,tmp}
mkdir -p "$HOME/Library/LaunchAgents"
print_success "目录结构创建完成"

# 2. 复制 Mihomo 二进制文件
print_info "复制 Mihomo 二进制文件..."
cp "$SCRIPT_DIR/bin/mihomo" "$MIHOMO_HOME/bin/"
chmod 755 "$MIHOMO_HOME/bin/mihomo"
print_success "二进制文件复制完成"

# 3. 处理配置文件
print_info "处理配置文件..."
cd "$SCRIPT_DIR"
./config.sh

# 4. 创建 LaunchAgent plist 文件
print_info "创建 LaunchAgent 配置..."
# 复制模板并替换路径占位符
sed "s|MIHOMO_HOME_PLACEHOLDER|$MIHOMO_HOME|g" \
    "$SCRIPT_DIR/mihomo.plist" > "$HOME/Library/LaunchAgents/mihomo.plist"
chmod 644 "$HOME/Library/LaunchAgents/mihomo.plist"
print_success "LaunchAgent 配置创建完成"

# 4.1 安装日志轮转脚本和 LaunchAgent (每天 04:30 检查, 超 100MB 归档清空, 保留 3 份)
print_info "创建日志轮转配置..."
cp "$SCRIPT_DIR/clean-log.sh" "$MIHOMO_HOME/bin/"
chmod 755 "$MIHOMO_HOME/bin/clean-log.sh"
sed "s|MIHOMO_HOME_PLACEHOLDER|$MIHOMO_HOME|g" \
    "$SCRIPT_DIR/clean-log.plist" > "$HOME/Library/LaunchAgents/mihomo.clean-log.plist"
chmod 644 "$HOME/Library/LaunchAgents/mihomo.clean-log.plist"
print_success "日志轮转配置创建完成"

# 4.2 安装升级脚本 (mihomo upgrade 子命令调用; 也可手动 ~/.mihomo/bin/upgrade.sh)
cp "$SCRIPT_DIR/upgrade.sh" "$MIHOMO_HOME/bin/"
chmod 755 "$MIHOMO_HOME/bin/upgrade.sh"

# 4.3 安装 ppg 入口刷新脚本 + LaunchAgent (每 30 分钟更新 hosts)
# ppg 节点域名只能由机场私有 DNS 解析, 用 hosts 指定 IP 池绕过
sed "s|APP_INSTALLER_PLACEHOLDER|$SCRIPT_DIR|g" \
    "$SCRIPT_DIR/ppg-dns-update.sh" > "$MIHOMO_HOME/bin/ppg-dns-update.sh"
chmod 755 "$MIHOMO_HOME/bin/ppg-dns-update.sh"
sed "s|MIHOMO_HOME_PLACEHOLDER|$MIHOMO_HOME|g" \
    "$SCRIPT_DIR/ppg-dns.plist" > "$HOME/Library/LaunchAgents/mihomo.ppg-dns.plist"
chmod 644 "$HOME/Library/LaunchAgents/mihomo.ppg-dns.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/mihomo.ppg-dns.plist" 2>/dev/null || \
    launchctl kickstart -k "gui/$(id -u)/mihomo.ppg-dns" 2>/dev/null || true
# 首次刷新 (生成 ppg-hosts.txt 并注入 hosts)
bash "$MIHOMO_HOME/bin/ppg-dns-update.sh" || print_warning "ppg 入口首次刷新失败, 将由定时任务重试"
print_success "ppg 入口刷新配置安装完成"

# 5. 设置目录权限
print_info "设置目录权限..."
chmod 700 "$MIHOMO_HOME"           # 根目录仅当前用户访问
chmod 755 "$MIHOMO_HOME/bin"       # 二进制文件目录
chmod 700 "$MIHOMO_HOME/config"    # 配置目录严格权限
chmod 755 "$MIHOMO_HOME/logs"      # 日志目录
chmod 755 "$MIHOMO_HOME/cache"     # 缓存目录
chmod 755 "$MIHOMO_HOME/tmp"       # 临时文件目录
print_success "权限设置完成"

# 6. 安装 mihomo 命令到系统路径
print_info "安装 mihomo 命令到 /usr/local/bin..."
sudo cp "$SCRIPT_DIR/mihomo.sh" "/usr/local/bin/mihomo"
sudo chmod 755 "/usr/local/bin/mihomo"
print_success "mihomo 命令安装完成"

print_success "Mihomo 环境部署完成！"
echo ""
print_info "环境特性:"
echo "• 以当前用户 ($CURRENT_USER) 身份运行"
echo "• 所有文件隔离在 $MIHOMO_HOME 目录"
echo "• 不需要 sudo 权限管理服务"
echo "• 通过目录权限提供基本安全保护"
echo ""
print_info "后续步骤:"
echo "1. 编辑配置文件: nano $MIHOMO_HOME/config/config.yaml"
echo "2. 启动服务: mihomo start"
echo "3. 查看状态: mihomo status"
echo "4. 查看日志: mihomo logs"
echo ""
print_info "服务管理命令 (可在任何位置使用):"
echo "• 启动服务: mihomo start"
echo "• 停止服务: mihomo stop"
echo "• 重启服务: mihomo restart"
echo "• 重载配置: mihomo reload"
echo "• 实时日志: mihomo follow"
echo ""
print_info "系统代理管理:"
echo "• 启用系统代理: mihomo proxy-on"
echo "• 禁用系统代理: mihomo proxy-off"
echo "• 查看代理状态: mihomo proxy-status"
echo ""
print_info "安全说明:"
echo "• Mihomo 文件隔离在 $MIHOMO_HOME 目录"
echo "• 配置文件权限设为 600（仅当前用户可读写）"
echo "• 根目录权限设为 700（仅当前用户可访问）"