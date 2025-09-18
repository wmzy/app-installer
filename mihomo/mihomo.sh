#!/bin/bash
# Mihomo 服务管理脚本

set -e

# 颜色输出函数
print_info() { echo -e "\033[36m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# 配置
MIHOMO_USER="mihomo"
MIHOMO_HOME="/Users/$MIHOMO_USER"
PLIST_PATH="$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"

# 检查服务状态
check_service_status() {
    if launchctl list | grep -q "com.mihomo.proxy"; then
        return 0  # 服务已加载
    else
        return 1  # 服务未加载
    fi
}

# 检查进程状态
check_process_status() {
    if pgrep -f "mihomo" > /dev/null; then
        return 0  # 进程运行中
    else
        return 1  # 进程未运行
    fi
}

# 显示服务状态
status() {
    print_info "检查 Mihomo 服务状态..."
    
    if check_service_status; then
        print_success "服务已加载到 launchctl"
    else
        print_warning "服务未加载到 launchctl"
    fi
    
    if check_process_status; then
        print_success "Mihomo 进程正在运行"
        echo "进程信息:"
        ps aux | grep mihomo | grep -v grep
    else
        print_warning "Mihomo 进程未运行"
    fi
    
    echo ""
    print_info "最近的日志:"
    if [[ -f "$MIHOMO_HOME/logs/mihomo.log" ]]; then
        tail -5 "$MIHOMO_HOME/logs/mihomo.log"
    else
        print_warning "日志文件不存在"
    fi
}

# 启动服务
start() {
    print_info "启动 Mihomo 服务..."
    
    if check_service_status; then
        print_warning "服务已经加载，尝试启动..."
        launchctl start com.mihomo.proxy
    else
        print_info "加载并启动服务..."
        launchctl load "$PLIST_PATH"
    fi
    
    # 等待一下让服务启动
    sleep 2
    
    if check_process_status; then
        print_success "Mihomo 服务启动成功"
    else
        print_error "Mihomo 服务启动失败，请检查日志"
        if [[ -f "$MIHOMO_HOME/logs/mihomo.log" ]]; then
            print_info "最近的错误日志:"
            tail -10 "$MIHOMO_HOME/logs/mihomo.log"
        fi
    fi
}

# 停止服务
stop() {
    print_info "停止 Mihomo 服务..."
    
    if check_service_status; then
        launchctl unload "$PLIST_PATH"
        print_success "服务已从 launchctl 卸载"
    else
        print_warning "服务未加载到 launchctl"
    fi
    
    # 检查进程是否还在运行
    if check_process_status; then
        print_warning "进程仍在运行，尝试强制终止..."
        pkill -f mihomo || true
        sleep 1
        
        if check_process_status; then
            print_warning "使用 SIGKILL 强制终止..."
            pkill -9 -f mihomo || true
        fi
    fi
    
    if ! check_process_status; then
        print_success "Mihomo 服务已停止"
    else
        print_error "无法停止 Mihomo 服务"
    fi
}

# 重启服务
restart() {
    print_info "重启 Mihomo 服务..."
    stop
    sleep 1
    start
}

# 重新加载配置
reload() {
    print_info "重新加载 Mihomo 配置..."
    
    if check_process_status; then
        # 发送 HUP 信号重新加载配置
        pkill -HUP -f mihomo || {
            print_warning "无法发送重载信号，尝试重启服务..."
            restart
            return
        }
        
        sleep 2
        if check_process_status; then
            print_success "配置重新加载成功"
        else
            print_error "配置重新加载失败，服务已停止"
        fi
    else
        print_warning "服务未运行，启动服务..."
        start
    fi
}

# 查看日志
logs() {
    local lines=${1:-20}
    
    if [[ -f "$MIHOMO_HOME/logs/mihomo.log" ]]; then
        print_info "显示最近 $lines 行日志:"
        tail -n "$lines" "$MIHOMO_HOME/logs/mihomo.log"
    else
        print_error "日志文件不存在: $MIHOMO_HOME/logs/mihomo.log"
    fi
}

# 实时查看日志
follow_logs() {
    if [[ -f "$MIHOMO_HOME/logs/mihomo.log" ]]; then
        print_info "实时查看日志 (Ctrl+C 退出):"
        tail -f "$MIHOMO_HOME/logs/mihomo.log"
    else
        print_error "日志文件不存在: $MIHOMO_HOME/logs/mihomo.log"
    fi
}

# 启用系统代理
enable_system_proxy() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local proxy_script="$script_dir/proxy-settings.sh"
    
    if [[ -f "$proxy_script" ]]; then
        print_info "启用系统代理..."
        sudo "$proxy_script" enable
    else
        print_error "代理设置脚本不存在: $proxy_script"
    fi
}

# 禁用系统代理
disable_system_proxy() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local proxy_script="$script_dir/proxy-settings.sh"
    
    if [[ -f "$proxy_script" ]]; then
        print_info "禁用系统代理..."
        sudo "$proxy_script" disable
    else
        print_error "代理设置脚本不存在: $proxy_script"
    fi
}

# 显示代理状态
show_proxy_status() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local proxy_script="$script_dir/proxy-settings.sh"
    
    if [[ -f "$proxy_script" ]]; then
        "$proxy_script" status
    else
        print_error "代理设置脚本不存在: $proxy_script"
    fi
}

# 显示帮助
show_help() {
    echo "Mihomo 服务管理脚本"
    echo ""
    echo "用法: $0 {start|stop|restart|status|reload|logs|follow|proxy-on|proxy-off|proxy-status|help}"
    echo ""
    echo "服务管理:"
    echo "  start       - 启动服务"
    echo "  stop        - 停止服务"
    echo "  restart     - 重启服务"
    echo "  status      - 查看服务状态"
    echo "  reload      - 重新加载配置 (无需重启)"
    echo ""
    echo "日志管理:"
    echo "  logs        - 查看日志 (默认最近20行)"
    echo "  logs N      - 查看日志 (最近N行)"
    echo "  follow      - 实时查看日志"
    echo ""
    echo "系统代理:"
    echo "  proxy-on    - 启用系统代理"
    echo "  proxy-off   - 禁用系统代理"
    echo "  proxy-status- 查看系统代理状态"
    echo ""
    echo "其他:"
    echo "  help        - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 status              # 查看服务状态"
    echo "  $0 restart             # 重启服务"
    echo "  $0 proxy-on            # 启动服务并启用系统代理"
    echo "  $0 logs 50             # 查看最近50行日志"
    echo "  $0 follow              # 实时查看日志"
}

# 主逻辑
case "${1:-}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    reload)
        reload
        ;;
    logs)
        logs "${2:-20}"
        ;;
    follow)
        follow_logs
        ;;
    proxy-on)
        enable_system_proxy
        ;;
    proxy-off)
        disable_system_proxy
        ;;
    proxy-status)
        show_proxy_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "未知命令: ${1:-}"
        echo ""
        show_help
        exit 1
        ;;
esac
