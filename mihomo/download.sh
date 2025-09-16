#!/bin/bash

# Mihomo 下载脚本
# 使用通用的 GitHub Release 下载器

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }

# 检查通用下载脚本是否存在
DOWNLOAD_SCRIPT="$PROJECT_ROOT/download-github-release.sh"
if [[ ! -f "$DOWNLOAD_SCRIPT" ]]; then
    echo "❌ 找不到通用下载脚本: $DOWNLOAD_SCRIPT"
    exit 1
fi

# 确保下载脚本可执行
chmod +x "$DOWNLOAD_SCRIPT"

print_info "开始下载 Mihomo..."

# 使用通用脚本下载 mihomo (交互模式，支持用户选择)
"$DOWNLOAD_SCRIPT" "MetaCubeX/mihomo" "latest" "$SCRIPT_DIR/downloads"

# 检查下载结果
DOWNLOAD_DIR="$SCRIPT_DIR/downloads"
if [[ -d "$DOWNLOAD_DIR" ]]; then
    print_success "下载完成，文件保存在: $DOWNLOAD_DIR"
    
    # 列出下载的文件
    echo ""
    print_info "下载的文件:"
    ls -la "$DOWNLOAD_DIR"
    
    # 解压和处理下载的文件
    for file in "$DOWNLOAD_DIR"/*; do
        if [[ -f "$file" ]]; then
            case "$file" in
                *.gz)
                    print_info "解压 $(basename "$file")..."
                    gunzip "$file"
                    ;;
                *.zip)
                    print_info "解压 $(basename "$file")..."
                    unzip -q "$file" -d "$DOWNLOAD_DIR"
                    rm "$file"
                    ;;
            esac
        fi
    done
    
    # 如果找到可执行文件，创建 bin 目录并复制
    EXECUTABLE=$(find "$DOWNLOAD_DIR" -name "mihomo*" -type f -perm +111 2>/dev/null | head -1)
    if [[ -z "$EXECUTABLE" ]]; then
        # 如果没有找到有执行权限的文件，尝试找到 mihomo 文件并添加执行权限
        EXECUTABLE=$(find "$DOWNLOAD_DIR" -name "mihomo*" -type f 2>/dev/null | head -1)
        if [[ -n "$EXECUTABLE" ]]; then
            chmod +x "$EXECUTABLE"
        fi
    fi
    
    if [[ -n "$EXECUTABLE" ]]; then
        mkdir -p "$SCRIPT_DIR/bin"
        cp "$EXECUTABLE" "$SCRIPT_DIR/bin/mihomo"
        chmod +x "$SCRIPT_DIR/bin/mihomo"
        print_success "可执行文件已复制到: $SCRIPT_DIR/bin/mihomo"
        
        # 显示版本信息
        print_info "版本信息:"
        "$SCRIPT_DIR/bin/mihomo" -v
    fi
else
    echo "❌ 下载失败"
    exit 1
fi
