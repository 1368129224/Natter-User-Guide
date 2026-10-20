#!/bin/bash
# Natter mihomo-TUN bypass via nftables (cgroup v2)
set -eu

TABLE="inet natter-bypass"
if sudo nft list table $TABLE >/dev/null 2>&1; then
  sudo nft flush table $TABLE
else
  sudo nft add table $TABLE
fi

sudo nft -f - << 'EOF'
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
