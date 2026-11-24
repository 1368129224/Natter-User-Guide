#!/usr/bin/env bash
set -eu

protocol="$1"
inner_ip="$2"
inner_port="$3"
outer_ip="$4"
outer_port="$5"

# OpenWrt 对应的端口转发规则 ID（从 0 开始递增）
rule_id="0"

# 转发目标端口：
# - 留空（推荐）：转发至 Natter 监听的 inner_port，由 Natter (-p) 继续转发到内网服务端口
# - 手动填写：由路由器直接 DNAT 到内网服务的实际端口（例如搭配 qBittorrent 时可填 "$outer_port"）
target_port=""

dest_port="${target_port:-$inner_port}"

echo "[Hook] ${protocol}://${inner_ip}:${inner_port} <-Natter-> ${outer_ip}:${outer_port}"
echo "Updating OpenWrt firewall redirect[${rule_id}]: WAN ${outer_port} -> ${inner_ip}:${dest_port} ..."

ssh openwrt "uci set firewall.@redirect[${rule_id}].src_dport='${outer_port}'; \
uci set firewall.@redirect[${rule_id}].dest_ip='${inner_ip}'; \
uci set firewall.@redirect[${rule_id}].dest_port='${dest_port}'; \
uci commit firewall; \
uci show firewall.@redirect[${rule_id}]; \
/etc/init.d/firewall reload"
