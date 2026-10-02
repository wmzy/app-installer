#!/bin/bash
# 极简配置处理脚本 - 直接字符串替换

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_TEMPLATE="$SCRIPT_DIR/config.yaml"
CONFIG_PROVIDERS_FILE="$SCRIPT_DIR/config.providers.yaml"
MIHOMO_HOME="$HOME/.mihomo"
CONFIG_OUTPUT="$MIHOMO_HOME/config/config.yaml"

# 如果没有 config.providers.yaml 文件，创建默认的
if [[ ! -f "$CONFIG_PROVIDERS_FILE" ]]; then
    cp "$SCRIPT_DIR/$CONFIG_PROVIDERS_FILE.example" "$CONFIG_PROVIDERS_FILE"
    echo "已创建默认 config.providers.yaml 文件，请编辑后重新运行"
    exit 0
fi

# 合并 config.providers.yaml 和 config.yaml
cat "$CONFIG_PROVIDERS_FILE" "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"

# 动态注入 ppg 入口 hosts (数据源: ~/.mihomo/config/ppg-hosts.txt)
# ppg 节点域名只能由机场私有 DNS 解析, 用 hosts 绕过;
# IP 池由 ppg-dns-update.sh 定期刷新, 模板保持静态
PPG_HOSTS_FILE="$MIHOMO_HOME/config/ppg-hosts.txt"
if [[ -f "$PPG_HOSTS_FILE" ]]; then
    python3 - "$CONFIG_OUTPUT" "$PPG_HOSTS_FILE" <<'PYEOF'
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
fi

echo "配置文件已生成: $CONFIG_OUTPUT"

chmod 600 "$CONFIG_OUTPUT"

curl 'http://127.0.0.1:9090/configs?force=true' -X 'PUT' --data-raw '{"path":"","payload":""}' 2>/dev/null

echo "配置文件安装完成"
