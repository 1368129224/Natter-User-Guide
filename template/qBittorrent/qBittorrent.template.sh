#!/usr/bin/env bash
set -eu

protocol="$1"
inner_ip="$2"
inner_port="$3"
outer_ip="$4"
outer_port="$5"

# 配置 qBittorrent Web UI 地址（注意区分 http 与 https）及账号密码
qb_web_url="https://192.168.1.100:18080"
qb_username="admin"
qb_password="adminadmin"

# 端口转发同步方式（qBittorrent 做种要求监听端口与公网端口 outer_port 一致）：
# - "none"    : 仅修改 qBittorrent 监听端口
# - "iptables": 本机处于 DMZ 时，用 iptables 将 Natter 的 inner_port 重定向至 outer_port（需 root 权限）
# - "openwrt" : 未开 DMZ 时，通过 SSH 调用 OpenWrt UCI 将 WAN outer_port 直接转发至本机 outer_port
forward_mode="none"
openwrt_rule_id="0"

echo "[Hook] ${protocol}://${inner_ip}:${inner_port} <-Natter-> ${outer_ip}:${outer_port}"
echo "Updating qBittorrent listen port to ${outer_port} ..."

qb_cookie=$(curl --insecure -s -i \
  --header "Referer: ${qb_web_url}" \
  --data-urlencode "username=${qb_username}" \
  --data-urlencode "password=${qb_password}" \
  "${qb_web_url}/api/v2/auth/login" | grep -i '^set-cookie:' | grep -o 'SID=[^;[:space:]]*' || true)

if [ -z "${qb_cookie}" ]; then
  echo "Error: Failed to login to qBittorrent Web UI (${qb_web_url})." >&2
  exit 1
fi

curl --insecure -sS -X POST \
  --header "Referer: ${qb_web_url}" \
  -b "${qb_cookie}" \
  --data-urlencode "json={\"listen_port\":${outer_port}}" \
  "${qb_web_url}/api/v2/app/setPreferences"

case "${forward_mode}" in
  iptables)
    if [ "${inner_port}" != "${outer_port}" ]; then
      iptables -t nat -N NATTER_QB 2>/dev/null || iptables -t nat -F NATTER_QB
      iptables -t nat -C PREROUTING -p tcp -j NATTER_QB 2>/dev/null || \
        iptables -t nat -A PREROUTING -p tcp -j NATTER_QB
      iptables -t nat -F NATTER_QB
      iptables -t nat -A NATTER_QB -p tcp --dport "${inner_port}" -j REDIRECT --to-ports "${outer_port}"
      echo "Updated local iptables REDIRECT: ${inner_port} -> ${outer_port}"
    fi
    ;;
  openwrt)
    ssh openwrt "uci set firewall.@redirect[${openwrt_rule_id}].src_dport='${outer_port}'; \
      uci set firewall.@redirect[${openwrt_rule_id}].dest_ip='${inner_ip}'; \
      uci set firewall.@redirect[${openwrt_rule_id}].dest_port='${outer_port}'; \
      uci commit firewall; \
      /etc/init.d/firewall reload"
    echo "Updated OpenWrt firewall redirect[${openwrt_rule_id}]: WAN ${outer_port} -> ${inner_ip}:${outer_port}"
    ;;
  none)
    ;;
  *)
    echo "Warning: Unknown forward_mode '${forward_mode}'" >&2
    ;;
esac

echo "Done."
