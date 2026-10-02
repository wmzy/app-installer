#!/bin/bash
# mihomo 二进制升级脚本
# 用法: upgrade.sh [--force]   (--force: 已是最新也重新下载安装)
#
# 流程: releases/latest 重定向取最新版本(不消耗 GitHub API 配额) ->
#       下载对应平台 .gz -> 本地冒烟 -> 原子替换 -> launchd 重启 ->
#       轮询 /version 校验, 失败自动回滚 -> 同步项目 bin/ 副本

set -euo pipefail

GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }

MIHOMO_HOME="$HOME/.mihomo"
BIN="$MIHOMO_HOME/bin/mihomo"
BACKUP="$BIN.bak"
API="http://127.0.0.1:9090"
REPO="MetaCubeX/mihomo"
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# 本地代理活着就走代理下载(GitHub 直连不稳定), 否则直连
CURL_OPTS=(--silent --show-error --location --max-time 120 --fail)
if nc -z 127.0.0.1 7890 2>/dev/null; then
    CURL_OPTS+=(--proxy http://127.0.0.1:7890)
fi

[ -x "$BIN" ] || { print_error "未找到 mihomo 二进制: $BIN (先运行 install.sh)"; exit 1; }

# 1. 版本比较
current=$("$BIN" -v | head -1 | awk '{print $3}')
latest=$(curl "${CURL_OPTS[@]}" -I "https://github.com/$REPO/releases/latest" \
    | tr -d '\r' | awk 'tolower($1)=="location:"{print $2}' \
    | sed 's|.*/tag/||')
[ -n "$latest" ] || { print_error "无法获取最新版本号 (网络问题?)"; exit 1; }

print_info "当前版本: $current | 最新版本: $latest"
if [ "$current" = "$latest" ] && [ "$FORCE" -eq 0 ]; then
    print_success "已是最新版本"
    exit 0
fi

# 2. 下载对应平台二进制
case "$(uname -s)/$(uname -m)" in
    Darwin/arm64)  PLATFORM="darwin-arm64" ;;
    Darwin/x86_64) PLATFORM="darwin-amd64" ;;
    *) print_error "不支持的平台: $(uname -s)/$(uname -m)"; exit 1 ;;
esac
ASSET="mihomo-$PLATFORM-$latest.gz"
print_info "下载 $ASSET ..."
curl "${CURL_OPTS[@]}" -o "$TMP_DIR/$ASSET" "https://github.com/$REPO/releases/download/$latest/$ASSET" \
    || { print_error "下载失败"; exit 1; }

# 3. 解压 + 冒烟测试
gunzip -c "$TMP_DIR/$ASSET" > "$TMP_DIR/mihomo"
chmod 755 "$TMP_DIR/mihomo"
NEW_VER=$("$TMP_DIR/mihomo" -v | head -1 | awk '{print $3}')
[ "$NEW_VER" = "$latest" ] || { print_error "新二进制版本异常: $NEW_VER != $latest, 放弃"; exit 1; }

# 4. 备份并替换
cp "$BIN" "$BACKUP"
mv "$TMP_DIR/mihomo" "$BIN"
print_info "已替换二进制 (备份: $BACKUP), 重启服务..."

# 5. 重启并校验, 失败回滚
LABEL="mihomo"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
ok=""
for i in $(seq 1 15); do
    sleep 1
    running=$(curl -s --max-time 2 "$API/version" 2>/dev/null \
        | tr -d '\r' | sed -n 's/.*"version":"\([^"]*\)".*/\1/p' || true)
    if [ "$running" = "$latest" ]; then ok=1; break; fi
done
if [ -z "$ok" ]; then
    print_error "重启后 /version 校验失败 (当前: ${running:-无响应}), 回滚到 $current"
    cp "$BACKUP" "$BIN"
    launchctl kickstart -k "gui/$(id -u)/$LABEL"
    sleep 2
    exit 1
fi

# 6. 同步项目 bin/ 副本, 避免重装 install.sh 时降级
PROJECT_BIN="$SCRIPT_DIR/bin/mihomo"
if [ -f "$PROJECT_BIN" ] && [ ! "$PROJECT_BIN" -ef "$BIN" ]; then
    cp "$BIN" "$PROJECT_BIN"
    print_info "已同步项目副本: $PROJECT_BIN"
fi

print_success "升级完成: $current -> $latest (运行中版本已确认)"
