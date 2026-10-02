#!/bin/bash
# ppg 机场入口域名刷新脚本
#
# 背景: ppg 节点 server 域名(*.kunlun05dns.com)只能由机场私有 DNS 解析,
# 公共 DNS 无记录; 作为 proxy-provider 加载时订阅内的 dns 段被丢弃,
# 因此用 hosts 直接指定入口 IP。机场用 DNS 轮询负载均衡(每次查询返回
# 不同 IP), 所以收集多次查询的 IP 池写入数据文件, 由 config.sh 注入
# 到运行时配置 (模板 config.yaml 保持静态, 动态 IP 不进 git)。
#
# 流程: 私有 DoH 多次查询收集 5 个入口域名的 IP 池 ->
#       写入 ~/.mihomo/config/ppg-hosts.txt -> 调 config.sh 注入并热重载。
# 任一域名解析失败则整体放弃, 保留旧数据, 不影响现有连接。
#
# 由 LaunchAgent (mihomo.ppg-dns) 每 30 分钟调用, 也可手动执行。

set -eu

# 安装时由 install.sh 替换为仓库实际路径
REPO_DIR="APP_INSTALLER_PLACEHOLDER"
PPG_HOSTS_FILE="$HOME/.mihomo/config/ppg-hosts.txt"

# ppg 全部 5 个入口域名 (漏一个对应地区就全挂)
DOMAINS=(ppg-hk ppg-jp ppg-us ppg-sg ppg-other)
# ppg 私有 DoH (订阅 proxy-server-nameserver 里的地址)
DOH_HOST=20.247.42.211
DOH_PORT=36290
DOH_PATH='/dns-query/clash?site=paopaogou'
# 每个域名查询次数 (收集 IP 池)
ROUNDS=10

# 用 ppg 私有 DoH 查询, 输出 IP 池 (每行一个)
resolve_pool() {
    python3 - "$1" "$ROUNDS" <<'PYEOF'
import ssl, socket, struct, random, base64, sys

name, rounds = sys.argv[1], int(sys.argv[2])

def query():
    qid = random.randint(0, 65535)
    q = struct.pack('>HHHHHH', qid, 0x0100, 1, 0, 0, 0)
    for part in name.split('.'):
        q += bytes([len(part)]) + part.encode()
    q += b'\x00' + struct.pack('>HH', 1, 1)
    b = base64.urlsafe_b64encode(q).decode().rstrip('=')
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    raw = socket.create_connection(('20.247.42.211', 36290), timeout=8)
    with ctx.wrap_socket(raw, server_hostname='20.247.42.211') as s:
        s.send(f'GET /dns-query/clash?site=paopaogou&dns={b} HTTP/1.1\r\nHost: 20.247.42.211:36290\r\nUser-Agent: clash\r\nAccept: application/dns-message\r\nConnection: close\r\n\r\n'.encode())
        data = b''
        while True:
            c = s.recv(4096)
            if not c:
                break
            data += c
    body = data.split(b'\r\n\r\n', 1)[1]
    ancount = struct.unpack('>H', body[6:8])[0]
    i = 12
    while body[i] != 0:
        i += body[i] + 1
    i += 5
    ips = []
    for _ in range(ancount):
        if body[i] & 0xC0 == 0xC0:
            i += 2
        else:
            while body[i] != 0:
                i += body[i] + 1
            i += 1
        rtype, _, _, rdlen = struct.unpack('>HHIH', body[i:i + 10])
        i += 10
        if rtype == 1:
            ips.append('.'.join(str(x) for x in body[i:i + rdlen]))
        i += rdlen
    return ips

pool = set()
for _ in range(rounds):
    try:
        pool.update(query())
    except Exception:
        pass

if pool:
    print('\n'.join(sorted(pool)))
else:
    sys.exit(1)
PYEOF
}

# 收集所有域名的 IP 池 (合并去重, 机场各域名共享 IP 池)
POOL_FILE=$(mktemp)
trap 'rm -f "$POOL_FILE"' EXIT
for d in "${DOMAINS[@]}"; do
    resolve_pool "$d.kunlun05dns.com" >> "$POOL_FILE" || {
        echo "[$(date '+%H:%M:%S')] 解析失败: $d, 保留旧 hosts"
        exit 1
    }
done
sort -u "$POOL_FILE" -o "$POOL_FILE"
echo "[$(date '+%H:%M:%S')] IP 池: $(wc -l < "$POOL_FILE") 个 IP"

# 写入数据文件 (config.sh 生成配置时注入)
cp "$POOL_FILE" "$PPG_HOSTS_FILE"
echo "[$(date '+%H:%M:%S')] 数据文件已更新: $PPG_HOSTS_FILE"

# 重新生成配置并热重载 (注入 hosts)
bash "$REPO_DIR/config.sh"

exit 0
