# NAT-hole-punching

本项目旨在帮助大家应用 [Natter v0.9](https://github.com/MikeWang000000/Natter/tree/v0.9) ，在 **Full Cone NAT** 网络环境下进行 TCP 打洞，提高 [qBittorrent](https://www.qbittorrent.org/) 连通性，获得近似于公网 IPv4 的体验。

## 原理

[Natter v0.9](https://github.com/MikeWang000000/Natter/tree/v0.9) 支持了Hook调用，即在打洞成功后执行脚本。

利用这一点，我们可以在打洞成功后自动登录到路由器并设置端口转发，实现一些自动化功能。

PS：如果看到这里就懂了，那么大佬您就不用浪费时间看后续内容了，相信您能实现自己想要的功能。

## 条件

1. 网络环境 NAT 为 **Full Cone NAT**，又称 NAT1。
   
    使用 [NatTypeTester](https://github.com/HMBSbige/NatTypeTester) 进行 NAT 检测，结果为下图便可以继续后续步骤。

    TODO：补充图片

2. 路由器是 openwrt 系统，并且具备 [UCI](https://openwrt.org/zh/docs/guide-user/base-system/uci) 系统

    登录路由后台，执行 `uci` 命令，有如下打印则具备 UCI 系统。

    ```
    root@ImmortalWrt:~# uci
    Usage: uci [<options>] <command> [<arguments>]
    ```

    PS：后续视情况支持其他路由系统

3. Natter 需要运行在光猫下的任意设备上，装有 python 环境，并且能通过 ssh 连接到主路由，或运行在主路由上。

    TODO：补充网络拓扑图

## 步骤

1. 配置私钥登录 openwrt 路由器

    TODO：添加说明

2. 创建端口转发规则

    TODO：添加说明

3. 下载 Natter v0.9

    在准备运行 Natter 的设备上下载源码

    ```shell
    # 下载源码
    git clone https://github.com/MikeWang000000/Natter.git
    # 进入Natter目录
    cd Natter/
    # 切换到v0.9版本
    git checkout v0.9
    ```

4. 编辑 config

    复制 `natter-config.template.json` 并重命名为 `natter-config.json`，根据注释填写配置，参考 `config.template.json`。
    
    这里我们采用仅打洞方式，手动设置端口转发，转发交给路由来做。例如：在 "open_port" -> "tcp" 中添加 "0.0.0.0:50000"。
    ```
    {
        "logging": {
            "level": "info", // 日志等级：可选值："debug"、"info"、"warning"、"error"
            "log_file": "./natter.log" // 日志文件路径，不需要日志则置空：""
        },
        "status_report": {
            "hook": "bash ./natter-hook.sh '{protocol}' '{inner_ip} ' '{inner_port}' '{outer_ip}' '{outer_port}'", // Hook执行方式，一般无需改动
            "status_file": "./natter-status.json" // 实时端口映射状态储存至指定文件，不需要则置空：""
        },
        "open_port": {
            // 此处设置 Natter 打洞IP:端口。（仅打洞）
            // 此处地址为 Natter 绑定（监听）的地址，Natter 仅对这些地址打洞，您需要手动设置端口转发。
            // 注意：使用默认出口IP，请使用 0.0.0.0 ，而不是 127.0.0.1 。
            // 注意：这里尽量只保留一条规则，避免出现意想不到的错误
            "tcp": [
                "0.0.0.0:50000"
            ],
            "udp": [
            ]
        },
        "forward_port": {
            // 此处设置需要 Natter 开放至公网的 IP:端口。（打洞 + 内置转发）
            // Natter 会全自动打洞、转发，您无需做任何干预。
            // 注意：使用本机IP，请使用 127.0.0.1，而不是 0.0.0.0 。
            // 注意：我们采用仅打洞方式，不使用内置转发，清空所有规则
            "tcp": [
            ],
            "udp": [
            ]
        },
        "stun_server": {
            // 此处设置公共 STUN 服务器。
            // TCP 服务器请确保 TCP/3478 端口开放可用；
            // UDP 服务器请确保 UDP/3478 端口开放可用。
            // 一般无需改动
            "tcp": [
                "fwa.lifesizecloud.com",
                "stun.isp.net.au",
                "stun.freeswitch.org",
                "stun.voip.blackberry.com",
                "stun.nextcloud.com",
                "stun.stunprotocol.org",
                "stun.sipnet.com",
                "stun.radiojar.com",
                "stun.sonetel.com",
                "stun.voipgate.com"
            ],
            "udp": [
                "stun.miwifi.com",
                "stun.qq.com"
            ]
        },
        // 此处设置 HTTP Keep-Alive 服务器。请确保该服务器 80 端口开放，且支持 HTTP Keep-Alive。
        "keep_alive": "www.qq.com"
    }
    ```
    PS：json 不支持注释，请不要再配置文件中添加注释

5. 编辑 Hook 脚本

    ```
    protocol=$1
    inner_ip=$2
    inner_port=$3
    outter_ip=$4
    outter_port=$5

    echo "[Script] - Upload to server: ${protocol}: ${inner_ip}:${inner_port} -> ${outter_ip}:${outter_port}"

    # Write your upload script below...

    # 以下需要我们添加，并按你自己实际填写
    qb_web_url="https://192.168.1.200:8080" // qb登录URL，注意是http还是https
    qb_username="admin" // qb用户名
    qb_password="adminadmin" // qb密码
    rule_id="0" // 端口转发规则ID

    echo "Update qBittorrent listen port to $outter_port..."

    qb_cookie=$(curl --insecure -s -i --header "Referer: $qb_web_url" --data "username=$qb_username&password=$qb_password" $qb_web_url/api/v2/auth/login | grep -i set-cookie | cut -c13-48)
    curl --insecure -X POST -b "$qb_cookie" -d 'json={"listen_port":"'$outter_port'"}' "$qb_web_url/api/v2/app/setPreferences"

    echo "Update openwrt firewall..."

    # 这里通过SSH连接到 openwrt 路由器，并修改端口转发规则
    ssh openwrt "uci set firewall.@redirect[$rule_id].dest_port=$outter_port;uci set firewall.@redirect[$rule_id].src_dport=$inner_port;uci commit firewall;/etc/init.d/firewall    restart;exit"

    echo "Done."
    ```

6. 后台执行脚本

    由于运营商网络环境通常在2天左右会改变(公网IP地址)，我们需要将 Natter 常驻运行，自动进行打洞和设置端口转发。

    这里建议使用 `screen` 来运行 Natter：

    ```shell
    # 新建screen
    screen -S nat
    # 运行脚本
    python natter.py -c ./config.json
    # 离开screen
    # 按 Ctrl + A 再按 Ctrl + D
    # 回到screen
    # screen -r nat
    ```

7. 进行验证

    * 登录路由器后台查看端口转发是否正确
    * 使用[端口扫描工具](https://tool.chinaz.com/port)确认端口是否打开
    * 在 qBittorrent 页面查看连通性，或在PT站点查看连通性

8. Enjoy！

## Thanks

* [NatTypeTester](https://github.com/HMBSbige/NatTypeTester)
* [Natter](https://github.com/MikeWang000000/Natter)
