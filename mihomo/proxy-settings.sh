#!/bin/bash
# Mihomo 系统代理设置脚本
# 类似 ClashX 的【设置为系统代理】功能

set -e

# 颜色输出函数
print_info() { echo -e "\033[36m[INFO]\033[0m $1"; }
print_success() { echo -e "\033[32m[SUCCESS]\033[0m $1"; }
print_warning() { echo -e "\033[33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[31m[ERROR]\033[0m $1"; }

# 默认配置
DEFAULT_HTTP_PORT="7890"
DEFAULT_SOCKS_PORT="7890"
DEFAULT_SERVER="127.0.0.1"

# 忽略列表
BYPASS_DOMAINS=(
    "192.168.0.0/16"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "127.0.0.1"
    "localhost"
    "*.local"
    "timestamp.apple.com"
    "sequoia.apple.com"
    "seed-sequoia.siri.apple.com"
)

# 获取当前网络服务
get_network_services() {
    networksetup -listallnetworkservices | grep -v "^An asterisk" | grep -v "^$"
}

# 获取主要网络服务（Wi-Fi 优先）
get_primary_network_service() {
    local services
    services=$(get_network_services)
    
    # 优先查找 Wi-Fi
    if echo "$services" | grep -q "Wi-Fi"; then
        echo "Wi-Fi"
        return
    fi
    
    # 查找以太网相关
    if echo "$services" | grep -qi "ethernet"; then
        echo "$services" | grep -i "ethernet" | head -1
        return
    fi
    
    # 返回第一个服务
    echo "$services" | head -1
}

# 设置 HTTP 代理
set_http_proxy() {
    local service="$1"
    local server="$2"
    local port="$3"
    
    print_info "为 $service 设置 HTTP 代理: $server:$port"
    networksetup -setwebproxy "$service" "$server" "$port"
    networksetup -setwebproxystate "$service" on
    
    # 设置 HTTPS 代理（通常与 HTTP 代理相同）
    networksetup -setsecurewebproxy "$service" "$server" "$port"
    networksetup -setsecurewebproxystate "$service" on
}

# 设置 SOCKS 代理
set_socks_proxy() {
    local service="$1"
    local server="$2"
    local port="$3"
    
    print_info "为 $service 设置 SOCKS 代理: $server:$port"
    networksetup -setsocksfirewallproxy "$service" "$server" "$port"
    networksetup -setsocksfirewallproxystate "$service" on
}

# 设置代理忽略列表
set_proxy_bypass() {
    local service="$1"
    local bypass_list
    
    # 将数组转换为逗号分隔的字符串
    bypass_list=$(IFS=','; echo "${BYPASS_DOMAINS[*]}")
    
    print_info "为 $service 设置代理忽略列表"
    networksetup -setproxybypassdomains "$service" "${BYPASS_DOMAINS[@]}"
}

# 清除所有代理设置
clear_proxy() {
    local service="$1"
    
    print_info "清除 $service 的代理设置"
    
    # 清除 HTTP 代理
    networksetup -setwebproxystate "$service" off
    networksetup -setsecurewebproxystate "$service" off
    
    # 清除 SOCKS 代理
    networksetup -setsocksfirewallproxystate "$service" off
    
    # 清除 FTP 代理（如果有）
    networksetup -setftpproxystate "$service" off 2>/dev/null || true
    
    # 清除忽略列表
    networksetup -setproxybypassdomains "$service" "" 2>/dev/null || true
}

# 显示当前代理状态
show_proxy_status() {
    local service="$1"
    
    print_info "当前 $service 的代理设置:"
    echo ""
    
    # HTTP 代理状态
    local http_enabled=$(networksetup -getwebproxy "$service" | grep "Enabled: Yes" || echo "")
    if [[ -n "$http_enabled" ]]; then
        echo "🌐 HTTP 代理: 已启用"
        networksetup -getwebproxy "$service" | grep -E "(Server|Port):" | sed 's/^/   /'
    else
        echo "🌐 HTTP 代理: 未启用"
    fi
    
    # HTTPS 代理状态
    local https_enabled=$(networksetup -getsecurewebproxy "$service" | grep "Enabled: Yes" || echo "")
    if [[ -n "$https_enabled" ]]; then
        echo "🔒 HTTPS 代理: 已启用"
        networksetup -getsecurewebproxy "$service" | grep -E "(Server|Port):" | sed 's/^/   /'
    else
        echo "🔒 HTTPS 代理: 未启用"
    fi
    
    # SOCKS 代理状态
    local socks_enabled=$(networksetup -getsocksfirewallproxy "$service" | grep "Enabled: Yes" || echo "")
    if [[ -n "$socks_enabled" ]]; then
        echo "🧦 SOCKS 代理: 已启用"
        networksetup -getsocksfirewallproxy "$service" | grep -E "(Server|Port):" | sed 's/^/   /'
    else
        echo "🧦 SOCKS 代理: 未启用"
    fi
    
    # 忽略列表
    echo ""
    echo "🚫 代理忽略列表:"
    local bypass_domains=$(networksetup -getproxybypassdomains "$service" 2>/dev/null | grep -v "^There aren't any bypass domains" || echo "")
    if [[ -n "$bypass_domains" ]]; then
        echo "$bypass_domains" | sed 's/^/   /'
    else
        echo "   (无)"
    fi
}

# 启用系统代理
enable_system_proxy() {
    local service="${1:-$(get_primary_network_service)}"
    local http_port="${2:-$DEFAULT_HTTP_PORT}"
    local socks_port="${3:-$DEFAULT_SOCKS_PORT}"
    local server="${4:-$DEFAULT_SERVER}"
    
    print_info "正在为网络服务 '$service' 启用系统代理..."
    echo ""
    
    # 设置 HTTP/HTTPS 代理
    set_http_proxy "$service" "$server" "$http_port"
    
    # 设置 SOCKS 代理
    set_socks_proxy "$service" "$server" "$socks_port"
    
    # 设置忽略列表
    set_proxy_bypass "$service"
    
    echo ""
    print_success "系统代理已启用！"
    echo ""
    
    # 显示设置结果
    show_proxy_status "$service"
}

# 禁用系统代理
disable_system_proxy() {
    local service="${1:-$(get_primary_network_service)}"
    
    print_info "正在为网络服务 '$service' 禁用系统代理..."
    
    clear_proxy "$service"
    
    print_success "系统代理已禁用！"
    echo ""
    
    # 显示当前状态
    show_proxy_status "$service"
}

# 显示所有网络服务的代理状态
show_all_proxy_status() {
    print_info "所有网络服务的代理状态:"
    echo ""
    
    local services
    services=$(get_network_services)
    
    while IFS= read -r service; do
        if [[ -n "$service" ]]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            show_proxy_status "$service"
            echo ""
        fi
    done <<< "$services"
}

# 显示帮助信息
show_help() {
    echo "Mihomo 系统代理设置脚本"
    echo ""
    echo "用法: $0 {enable|disable|status|list|help} [选项]"
    echo ""
    echo "命令:"
    echo "  enable   - 启用系统代理"
    echo "  disable  - 禁用系统代理"
    echo "  status   - 显示主要网络服务的代理状态"
    echo "  list     - 显示所有网络服务的代理状态"
    echo "  help     - 显示此帮助信息"
    echo ""
    echo "启用代理选项:"
    echo "  $0 enable [网络服务] [HTTP端口] [SOCKS端口] [服务器]"
    echo ""
    echo "示例:"
    echo "  $0 enable                          # 使用默认设置启用代理"
    echo "  $0 enable Wi-Fi                    # 为 Wi-Fi 启用代理"
    echo "  $0 enable Wi-Fi 7890 7890          # 指定端口启用代理"
    echo "  $0 disable                         # 禁用主要网络服务的代理"
    echo "  $0 disable Wi-Fi                   # 禁用 Wi-Fi 的代理"
    echo "  $0 status                          # 查看代理状态"
    echo ""
    echo "默认设置:"
    echo "  服务器: $DEFAULT_SERVER"
    echo "  HTTP 端口: $DEFAULT_HTTP_PORT"
    echo "  SOCKS 端口: $DEFAULT_SOCKS_PORT"
    echo ""
    echo "忽略的域名和地址:"
    for domain in "${BYPASS_DOMAINS[@]}"; do
        echo "  • $domain"
    done
}

# 检查权限
check_permissions() {
    if ! networksetup -listallnetworkservices > /dev/null 2>&1; then
        print_error "需要管理员权限来修改网络设置"
        print_info "请使用 sudo 运行此脚本: sudo $0 $*"
        exit 1
    fi
}

# 主逻辑
case "${1:-}" in
    enable)
        check_permissions
        enable_system_proxy "$2" "$3" "$4" "$5"
        ;;
    disable)
        check_permissions
        disable_system_proxy "$2"
        ;;
    status)
        show_proxy_status "$(get_primary_network_service)"
        ;;
    list)
        show_all_proxy_status
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
