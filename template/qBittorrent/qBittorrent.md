# 自动设置qBittorrent传输端口

## 使用步骤

1. 测试能否或正常登录

    在运行 Natter 的设备上执行 `curl --insecure -s -i --header "Referer: https://localhost:8080" --data "username=admin&password=adminadmin" https://localhost:8080/api/v2/auth/login | grep -i set-cookie | cut -c13-48` 检查能否打印 `SID=6oavHb8b4MtL6PZvVqDpd9vb9eeedryh` 类似的token，如果不行则登陆失败，请自行排除问题。

2. 编辑Hook

    参考 `qBittorrent.template.sh` 修改你的Hook，这里搭配自动修改端口转发使用，**注意**：qBittorrent传输需要内外端口一致 `target_port=$outter_port`。

    ```shell
    # 配置qBittorrent，注意是http还是https
    qb_web_url="https://192.168.1.100:18080"
    qb_username="admin"
    qb_password="adminadmin"

    # 这里搭配自动修改端口转发的Hook，qBittorrent传输需要内外端口一致
    target_port=$outter_port

    echo "Update qBittorrent listen port to $outter_port..."

    qb_cookie=$(curl --insecure -s -i --header "Referer: $qb_web_url" --data "username=$qb_username&password=$qb_password" $qb_web_url/api/v2/  auth/login | grep -i set-cookie | cut -c13-48)
    curl --insecure -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$outter_port'"}' "$qb_web_url/api/v2/app/setPreferences"
    ```
