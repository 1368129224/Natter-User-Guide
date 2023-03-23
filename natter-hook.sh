protocol=$1
inner_ip=$2
inner_port=$3
outter_ip=$4
outter_port=$5

echo "[Script] - Upload to server: ${protocol}: ${inner_ip}:${inner_port} -> ${outter_ip}:${outter_port}"

# Write your upload script below...

# 以下需要我们添加，并按你自己实际填写
qb_web_url="https://192.168.1.200:8080" // qb登录URL, 注意是http还是https
qb_username="admin" // qb用户名
qb_password="adminadmin" // qb密码
rule_id="0" // 端口转发规则ID

echo "Update qBittorrent listen port to $outter_port..."

qb_cookie=$(curl --insecure -s -i --header "Referer: $qb_web_url" --data "username=$qb_username&password=$qb_password" $qb_web_url/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
curl --insecure -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$outter_port'"}' "$qb_web_url/api/v2/app/setPreferences"

echo "Update openwrt firewall..."

ssh openwrt "uci set firewall.@redirect[$rule_id].dest_port=$outter_port;uci set firewall.@redirect[$rule_id].src_dport=$inner_port;uci commit firewall;/etc/init.d/firewall restart;exit"

echo "Done."
