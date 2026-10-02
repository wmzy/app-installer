#!/bin/bash
# 极简配置处理脚本 (Linux/dnf 版) - 直接字符串替换
# mihomo 由 dnf 安装, systemd 服务使用 -d /etc/mihomo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.yaml"
CONFIG_PROVIDERS_FILE="$SCRIPT_DIR/config.providers.yaml"
MIHOMO_CONF_DIR="/etc/mihomo"
CONFIG_OUTPUT="$MIHOMO_CONF_DIR/config.yaml"

# 如果没有 config.providers.yaml 文件，创建默认的
if [[ ! -f "$CONFIG_PROVIDERS_FILE" ]]; then
    cp "$SCRIPT_DIR/$CONFIG_PROVIDERS_FILE.example" "$CONFIG_PROVIDERS_FILE"
    echo "已创建默认 config.providers.yaml 文件，请编辑后重新运行"
    exit 0
fi

# /etc/mihomo 归 root 所有, 非 root 时借助 sudo
SUDO=""
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
fi

# 合并 config.providers.yaml 和 config.yaml 到临时文件, 避免半成品配置落盘
TMP_FILE="$(mktemp)"
cat "$CONFIG_PROVIDERS_FILE" "$CONFIG_TEMPLATE" > "$TMP_FILE"

# 动态注入 ppg 入口 hosts (数据源: /etc/mihomo/ppg-hosts.txt)
# ppg 节点域名只能由机场私有 DNS 解析, 用 hosts 绕过;
# IP 池由 ppg-dns-update.sh 定期刷新, 模板保持静态
PPG_HOSTS_FILE="$MIHOMO_CONF_DIR/ppg-hosts.txt"
if [[ -f "$PPG_HOSTS_FILE" ]]; then
    if ! python3 - "$TMP_FILE" "$PPG_HOSTS_FILE" <<'PYEOF'
import sys
path, hosts_file = sys.argv[1], sys.argv[2]
ips = [l.strip() for l in open(hosts_file) if l.strip()]
if not ips:
    sys.exit(0)
content = open(path, encoding='utf-8').read()
block = 'hosts:\n'
for d in ['ppg-hk', 'ppg-jp', 'ppg-us', 'ppg-sg', 'ppg-other']:
    block += f"  '{d}.kunlun05dns.com':\n"
    for ip in ips:
        block += f'    - {ip}\n'
if 'hosts:\n' not in content:
    content = content.replace('profile:', block + '\nprofile:', 1)
    open(path, 'w', encoding='utf-8').write(content)
    print(f'ppg hosts 已注入 ({len(ips)} IPs x 5 域名)')
PYEOF
then
    echo "警告: ppg hosts 注入失败, 配置将不含 ppg 入口 hosts" >&2
fi
fi

chmod 600 "$TMP_FILE"
# external-controller 访问密钥 (来自合并后的配置, API 热重载需要认证)
SECRET="$(sed -n 's/^secret:[[:space:]]*//p' "$TMP_FILE" | tr -d '"' | head -1)"
if ! $SUDO install -m 600 "$TMP_FILE" "$CONFIG_OUTPUT"; then
    rm -f "$TMP_FILE"
    echo "错误: 无法写入 $CONFIG_OUTPUT(sudo 密码错误或权限不足)" >&2
    exit 1
fi
rm -f "$TMP_FILE"

echo "配置文件已生成: $CONFIG_OUTPUT"

# 优先走 external-controller 热重载(不中断现有连接), API 不可达时退回重启服务
# 注意: PUT /configs 同步等待配置应用完成, 订阅 URL 变更时需现拉订阅, 可能耗时 1 分钟左右
AUTH_ARGS=()
if [[ -n "$SECRET" ]]; then
    AUTH_ARGS=(-H "Authorization: Bearer $SECRET")
fi
HTTP_CODE="$(curl --noproxy '*' -s -o /dev/null -w '%{http_code}' "${AUTH_ARGS[@]}" \
    'http://127.0.0.1:9090/configs?force=true' -X PUT --data-raw '{"path":"","payload":""}' --max-time 120 2>/dev/null)"

if [[ "$HTTP_CODE" =~ ^2 ]]; then
    echo "已通过 API 热重载配置"
else
    $SUDO systemctl restart mihomo
    echo "API 不可达(HTTP $HTTP_CODE), 已重启 mihomo 服务"
fi

echo "配置文件安装完成"
