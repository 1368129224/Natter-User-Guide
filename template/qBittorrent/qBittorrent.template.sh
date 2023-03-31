# 配置qBittorrent，注意是http还是https
qb_web_url="https://192.168.1.100:18080"
qb_username="admin"
qb_password="adminadmin"

# 这里搭配自动修改端口转发的Hook，qBittorrent传输需要内外端口一致
target_port=$outter_port

echo "Update qBittorrent listen port to $outter_port..."

qb_cookie=$(curl --insecure -s -i --header "Referer: $qb_web_url" --data "username=$qb_username&password=$qb_password" $qb_web_url/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
curl --insecure -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$outter_port'"}' "$qb_web_url/api/v2/app/setPreferences"