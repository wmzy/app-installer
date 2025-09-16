#!/bin/bash

# GitHub Release 通用下载脚本
# 用法: ./download-github-release.sh <owner/repo> [version] [output_dir]
# 示例: ./download-github-release.sh MetaCubeX/mihomo latest ./downloads

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 解析命令行参数
AUTO_SELECT=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto|-a)
            AUTO_SELECT=true
            shift
            ;;
        --help|-h)
            echo "用法: $0 [选项] <owner/repo> [version] [output_dir]"
            echo ""
            echo "参数:"
            echo "  owner/repo    GitHub 仓库 (如: MetaCubeX/mihomo)"
            echo "  version       版本标签 (默认: latest)"
            echo "  output_dir    输出目录 (默认: ./downloads)"
            echo ""
            echo "选项:"
            echo "  -a, --auto    自动选择第一个匹配的文件，不询问用户"
            echo "  -h, --help    显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 MetaCubeX/mihomo latest ./downloads"
            echo "  $0 --auto prometheus/prometheus v2.45.0 ./bin"
            exit 0
            ;;
        -*)
            print_error "未知选项: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# 检查参数
if [[ $# -lt 1 ]]; then
    print_error "用法: $0 [选项] <owner/repo> [version] [output_dir]"
    print_info "使用 --help 查看详细帮助"
    exit 1
fi

REPO="$1"
VERSION="${2:-latest}"
OUTPUT_DIR="${3:-./downloads}"

# 检测系统信息
detect_system() {
    local os arch
    
    # 检测操作系统
    case "$(uname -s)" in
        Darwin*)    os="darwin" ;;
        Linux*)     os="linux" ;;
        MINGW*|CYGWIN*|MSYS*) os="windows" ;;
        *)          os="unknown" ;;
    esac
    
    # 检测架构
    case "$(uname -m)" in
        x86_64|amd64)   arch="amd64" ;;
        aarch64|arm64)  arch="arm64" ;;
        armv7l)         arch="armv7" ;;
        armv6l)         arch="armv6" ;;
        i386|i686)      arch="386" ;;
        *)              arch="unknown" ;;
    esac
    
    echo "${os}-${arch}"
}

# 获取 GitHub API 数据
get_github_api() {
    local url="$1"
    local response
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$url")
    elif command -v wget >/dev/null 2>&1; then
        response=$(wget -qO- --header="Accept: application/vnd.github.v3+json" "$url")
    else
        print_error "需要 curl 或 wget 命令"
        exit 1
    fi
    
    echo "$response"
}

# 从 JSON 中提取值（简单的 JSON 解析）
extract_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed "s/\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\"/\1/"
}

# 获取所有 assets 的下载链接
extract_assets() {
    local json="$1"
    echo "$json" | grep -o '"browser_download_url": "[^"]*"' | cut -d'"' -f4
}

# 匹配适合当前系统的文件
match_system_file() {
    local assets="$1"
    local system="$2"
    local matched_files=()
    
    # 解析系统信息
    local os=$(echo "$system" | cut -d'-' -f1)
    local arch=$(echo "$system" | cut -d'-' -f2)
    
    print_info "当前系统: $os-$arch" >&2
    print_info "可用文件:" >&2
    
    # 显示所有可用文件
    local count=0
    while IFS= read -r asset; do
        [[ -z "$asset" ]] && continue
        count=$((count + 1))
        local filename=$(basename "$asset")
        echo "  $count. $filename" >&2
        
        # 检查是否匹配当前系统
        if [[ "$filename" =~ $os ]] && [[ "$filename" =~ $arch ]]; then
            matched_files+=("$asset")
        fi
    done <<< "$assets"
    
    # 如果没有精确匹配，尝试模糊匹配
    if [[ ${#matched_files[@]} -eq 0 ]]; then
        print_warning "未找到精确匹配的文件，尝试模糊匹配..." >&2
        
        # 尝试不同的命名模式
        local patterns=()
        case "$os" in
            darwin) patterns+=("macos" "osx" "mac") ;;
            linux) patterns+=("linux") ;;
            windows) patterns+=("windows" "win") ;;
        esac
        
        case "$arch" in
            amd64) patterns+=("amd64" "x64" "x86_64") ;;
            arm64) patterns+=("arm64" "aarch64") ;;
            armv7) patterns+=("armv7" "arm7") ;;
            armv6) patterns+=("armv6" "arm6") ;;
            386) patterns+=("386" "i386" "x86") ;;
        esac
        
        while IFS= read -r asset; do
            [[ -z "$asset" ]] && continue
            local filename=$(basename "$asset")
            local match_score=0
            
            for pattern in "${patterns[@]}"; do
                if [[ "$filename" =~ $pattern ]]; then
                    match_score=$((match_score + 1))
                fi
            done
            
            if [[ $match_score -ge 2 ]]; then
                matched_files+=("$asset")
            fi
        done <<< "$assets"
    fi
    
    # 返回匹配的文件
    if [[ ${#matched_files[@]} -eq 0 ]]; then
        print_error "未找到适合 $system 的文件" >&2
        return 1
    elif [[ ${#matched_files[@]} -eq 1 ]]; then
        echo "${matched_files[0]}"
    else
        print_warning "找到多个可能的文件:" >&2
        for i in "${!matched_files[@]}"; do
            echo "  $((i+1)). $(basename "${matched_files[$i]}")" >&2
        done
        
        # 用户选择或自动选择
        if [[ "$AUTO_SELECT" == "true" ]]; then
            print_info "自动选择第一个匹配的文件" >&2
            choice=1
        else
            echo "" >&2
            echo -n "请选择要下载的文件 [1-${#matched_files[@]}，默认: 1]: " >&2
            read -r choice
            
            # 验证用户输入
            if [[ -z "$choice" ]]; then
                choice=1
            elif ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -gt ${#matched_files[@]} ]]; then
                print_warning "无效选择，使用默认选项 1" >&2
                choice=1
            fi
        fi
        
        echo "${matched_files[$((choice-1))]}"
    fi
}

# 下载文件
download_file() {
    local url="$1"
    local output_path="$2"
    local filename=$(basename "$url")
    
    print_info "下载 $filename 到 $output_path"
    print_info "下载链接: $url"
    
    # 创建输出目录
    mkdir -p "$(dirname "$output_path")"
    
    # 下载文件
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$output_path" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output_path" "$url"
    else
        print_error "需要 curl 或 wget 命令"
        return 1
    fi
    
    print_success "下载完成: $output_path"
}

# 主函数
main() {
    print_info "开始下载 $REPO 的 release..."
    
    # 检测系统
    local system=$(detect_system)
    if [[ "$system" == *"unknown"* ]]; then
        print_error "无法检测系统信息: $system"
        exit 1
    fi
    
    # 构建 API URL
    local api_url
    if [[ "$VERSION" == "latest" ]]; then
        api_url="https://api.github.com/repos/$REPO/releases/latest"
    else
        api_url="https://api.github.com/repos/$REPO/releases/tags/$VERSION"
    fi
    
    print_info "获取 release 信息: $api_url"
    
    # 获取 release 信息
    local release_data=$(get_github_api "$api_url")
    
    if [[ -z "$release_data" ]] || [[ "$release_data" =~ "Not Found" ]]; then
        print_error "无法获取 release 信息，请检查仓库名称和版本号"
        exit 1
    fi
    
    # 提取版本信息
    local tag_name=$(extract_json_value "$release_data" "tag_name")
    local release_name=$(extract_json_value "$release_data" "name")
    
    print_success "找到 release: $release_name ($tag_name)"
    
    # 获取所有 assets
    local assets=$(extract_assets "$release_data")
    
    if [[ -z "$assets" ]]; then
        print_error "该 release 没有可下载的文件"
        exit 1
    fi
    
    # 匹配适合当前系统的文件
    local download_url=$(match_system_file "$assets" "$system")
    
    if [[ -z "$download_url" ]]; then
        print_error "未找到适合的文件"
        exit 1
    fi
    
    # 确保 URL 是第一行（如果有多行输出）
    download_url=$(echo "$download_url" | head -1)
    
    local filename=$(basename "$download_url")
    print_success "选择文件: $filename"
    
    # 下载文件
    local output_path="$OUTPUT_DIR/$filename"
    download_file "$download_url" "$output_path"
    
    # 如果是压缩文件，询问是否解压
    if [[ "$filename" =~ \.(tar\.gz|tgz|zip|tar\.bz2|tar\.xz)$ ]]; then
        print_info "检测到压缩文件，可以手动解压:"
        case "$filename" in
            *.tar.gz|*.tgz)
                echo "  tar -xzf \"$output_path\" -C \"$OUTPUT_DIR\""
                ;;
            *.zip)
                echo "  unzip \"$output_path\" -d \"$OUTPUT_DIR\""
                ;;
            *.tar.bz2)
                echo "  tar -xjf \"$output_path\" -C \"$OUTPUT_DIR\""
                ;;
            *.tar.xz)
                echo "  tar -xJf \"$output_path\" -C \"$OUTPUT_DIR\""
                ;;
        esac
    fi
    
    print_success "下载完成！文件保存在: $output_path"
}

# 运行主函数
main "$@"
