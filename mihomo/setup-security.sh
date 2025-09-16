#!/bin/bash
# 安全配置脚本

MIHOMO_USER="mihomo"
MIHOMO_HOME="/Users/mihomo"

echo "🔒 配置 Mihomo 安全环境..."

# 设置文件权限
chmod 700 "$MIHOMO_HOME"
chmod 600 "$MIHOMO_HOME/.config/mihomo/config.yaml"
chmod 755 "$MIHOMO_HOME/start-mihomo.sh"
chmod 644 "$MIHOMO_HOME/Library/LaunchAgents/com.mihomo.proxy.plist"

# 设置所有者
sudo chown -R "$MIHOMO_USER:staff" "$MIHOMO_HOME"

# 创建沙盒配置（可选）
cat > "$MIHOMO_HOME/mihomo.sb" << 'EOF'
(version 1)
(deny default)

; 允许基本系统访问
(allow file-read* (literal "/"))
(allow file-read-metadata (literal "/"))
(allow process-info-pidinfo (target self))
(allow process-info-pidinfo)

; 允许网络访问
(allow network*)

; 允许访问配置目录
(allow file-read* file-write* (regex #"^/Users/mihomo/"))

; 禁止访问其他用户目录
(deny file* (regex #"^/Users/(?!mihomo/)"))
EOF

echo "✅ 安全配置完成"