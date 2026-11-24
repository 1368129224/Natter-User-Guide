#!/bin/bash
# Natter mihomo-TUN bypass via nftables (cgroup v2)
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root." >&2
  exit 1
fi

# 确保 cgroup 目录存在，避免容器未启动前 nftables 解析路径失败
mkdir -p /sys/fs/cgroup/natter.slice

nft -f - << 'EOF'
table inet natter-bypass
delete table inet natter-bypass
table inet natter-bypass {
  chain out {
    # 优先级设置为 mangle - 5，早于 mihomo 的重定向链
    type route hook output priority mangle - 5; policy accept;
    # 匹配 natter.slice 下所有进程 socket，打标 0x80000 直连物理网卡
    socket cgroupv2 level 1 "natter.slice" mark set 0x80000 counter comment "natter direct egress"
  }
}
EOF

echo "natter-bypass installed successfully."
