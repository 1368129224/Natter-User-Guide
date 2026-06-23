# Natter 使用指南

本项目旨在帮助大家应用 [Natter v2](https://github.com/MikeWang000000/Natter) ，在 **Full Cone NAT** 网络环境下打开 TCP 端口，获得在 IPv4 可连接的端口，并提供一些Hook的模板。

<p align="right">
Natter 官方交流群组：<a href="https://jq.qq.com/?_wv=1027&k=EYXohGpC">Q 657590400</a> | <a href="https://t.me/+VS5sjOWGgzsyYjY1">TG</a>
</p>

## Natter 基本使用

### 前提条件

1. 网络环境 NAT 为 **Full Cone NAT**，又称 NAT1。

    以下家庭网络环境很有可能是 NAT1 ，例如：

    * 使用光猫拨号，但拥有光猫控制权，能够设置DMZ。

    * 光猫为桥接模式，使用路由拨号，拥有路由控制权。

    处于以上环境时，使用 [natter-check](https://github.com/MikeWang000000/Natter/blob/master/natter-check/natter-check.py) 进行 NAT 检测，注意：如果在使用任何代理软件，关闭TUN后再进行Nat类型检测。

    ```bash
    python ./natter-check.py 
    > NatterCheck v2.2.1

    Checking TCP NAT...                  [   OK   ] ... NAT Type: 1
    Checking UDP NAT...                  [   OK   ] ... NAT Type: 1
    ```

2. 运营商没有配置防火墙

    一般我们无法感知，有条件的用户可以使用 `nmap` 在外部网络对出口IP进行 TCP 全端口扫描，期望结果是不为全部关闭。

### 使用教程

PS：由于我的路由限制，暂时只讲解在路由下挂设备上运行 Natter 。

#### 在路由下挂设备上运行

![网络拓扑](img/network.jpg)

本例讲解光猫桥接，且在 NAS 上运行 Natter 。

1. 在准备运行 Natter 的设备上下载 Natter

    按照系统架构下载对应的版本：https://github.com/MikeWang000000/Natter/releases

    我这里下载`natter.py`作为演示。

2. 为运行 Natter 的设备配置网络防火墙

    - 开启DMZ（推荐）
    
        进入路由器后台，找到 DMZ 设置，开启 DMZ 并将运行 Natter 的设备的 IP 地址设置为 DMZ 主机。

        > 注意：开启 DMZ 后，运行 Natter 的设备将会暴露在公网，将会有网络安全风险，请做好防范措施，例如：自托管服务监听地址从`0.0.0.0`改到内网地址`192.168.1.100`，开启防火墙，禁止不必要的端口访问等。

    - 开启端口转发

        进入路由器后台，找到端口转发设置，添加新的端口转发规则，将外部端口映射到运行 Natter 的设备的内部端口。

        > natter 由于家宽特性，外部端口会周期改变，手动更新很麻烦，建议使用 DMZ 方式，或者后续使用 Hook 自动设置端口转发。

3. 测试 natter 可用性

    首先直接运行natter.py，查看是否能够成功打洞。
    ```bash
    python ./natter.py
    2026-06-23 13:44:48 [I] Natter v2.1.1
    2026-06-23 13:44:48 [I] Tips: Use `--help` to see help messages
    2026-06-23 13:44:55 [I] 
    2026-06-23 13:44:55 [I] tcp://192.168.1.100:36741 <--Natter--> tcp://101.204.28.118:39206
    2026-06-23 13:44:55 [I] 
    2026-06-23 13:44:55 [I] Test mode in on.
    2026-06-23 13:44:55 [I] Please check [ http://101.204.28.118:39206 ]
    2026-06-23 13:44:55 [I] 
    2026-06-23 13:44:55 [I] LAN > 192.168.1.100:36741   [ OPEN ]
    2026-06-23 13:44:55 [I] LAN > 192.168.1.100:36741   [ OPEN ]
    2026-06-23 13:44:55 [I] LAN > 101.204.28.118:39206   [ OPEN ]
    2026-06-23 13:44:55 [I] WAN > 101.204.28.118:39206   [ OPEN ]
    2026-06-23 13:44:55 [I]
    ```
    访问`http://101.204.28.118:39206`查看是否能够正常访问测试页面

    ![测试](img/test01.png)

    如果能够访问，就说明当前网络可以正常使用natter进行打洞。

4. 为内网服务打洞

    接下来我们就要为内网服务打洞了，假设我们要打洞的内网服务是 `192.168.1.100:18888`，那么我们使用参数`-p 18888`来指定内网服务的端口（Natter 将会把数据转发到该端口），使用`-t 192.168.1.100`来指定转发目标的内网 IP 地址。

    如果运行 Natter 的设备有多张网卡或多个 IP，可以使用`-i`指定 Natter 绑定的网卡名或本机 IP 地址；如果不确定，一般可以先省略`-i`。

    ```bash
    python ./natter.py -t 192.168.1.100 -p 18888
    2026-06-23 14:09:07 [I] Natter v2.1.1
    2026-06-23 14:09:13 [I] 
    2026-06-23 14:09:13 [I] tcp://192.168.1.100:18888 <--socket--> tcp://192.168.1.100:40645 <--Natter--> tcp://101.204.28.118:38010
    2026-06-23 14:09:13 [I] 
    2026-06-23 14:09:13 [I] LAN > 192.168.1.100:18888   [ OPEN ]
    2026-06-23 14:09:13 [I] LAN > 192.168.1.100:40645   [ OPEN ]
    2026-06-23 14:09:13 [I] LAN > 101.204.28.118:38010   [ OPEN ]
    2026-06-23 14:09:14 [I] WAN > 101.204.28.118:38010   [ OPEN ]
    2026-06-23 14:09:14 [I]
    ```

    然后访问log中打印的WAN地址：`101.204.28.118:38010`，如果能够访问到内网服务，就说明打洞成功了。

    建议将目标指向到web服务，方便访问以检测打通是否成功，如：qBittorrent web等。

    > 详细参数：[Natter Usage](https://github.com/MikeWang000000/Natter/blob/master/docs/usage.md)

#### 在路由上运行

**待补充**

## 高级用法

如果你已经掌握了 Natter 的基本使用方法，想要进一步探索更多高级功能，可以参考以下内容。

### 转发模式

Natter 提供多种途径，将 Natter 端口流量转发至目标端口。

> 总的来说：
> 
> iptables 是最推荐的转发方法。
> 
> 如果您不是 Linux 用户，您可以选择 socat, gost 或者 socket 方法。
> 
> socket 方法，是 Natter 采用的默认转发方法。

| &nbsp;       | iptables | nftables | socat   | gost    | socket  |
| ------------ | -------- | -------- | ------- | ------- | ------- |
| 操作系统限制 | 仅 Linux | 仅 Linux | 跨平台  | 跨平台  | 跨平台  |
| 保留源 IP    | 可       | 可       | 不可    | 不可    | 不可    |
| 转发效率     | 高       | 高       | 中      | 中      | 中      |
| 转发类型     | 内核     | 内核     | 多进程  | 协程    | 多线程  |
| root 权限    | 需要     | 需要     | 无需    | 无需    | 无需    |
| 第三方依赖   | 是       | 是       | 是      | 是      | 否      |
| 依赖最低版本 | 1.4.1    | 0.9.0    | 1.7.2   | 2.3     | -       |
| 依赖最佳版本 | ≥ 1.4.20 | ≥ 1.0.6  | ≥ 1.7.2 | ≥ 2.3   | -       |

如果运行 Natter 的设备是 Linux 系统，建议使用 iptables 转发，需要使用`sudo`权限运行 Natter。

> 详细差异：[Forwarding Modes](https://github.com/MikeWang000000/Natter/blob/master/docs/forward.md)

### 后台保活 & 自动开机运行

- 使用screen或tmux等工具在后台运行Natter，避免关闭终端导致Natter退出。

- 把以下命令加入开机脚本：`echo "sudo-password" | sudo -S nohup /home/zooter/scripts/nas/nat/natter.py -m iptables -p 18888 -i 192.168.1.100 -e /home/zooter/scripts/nas/nat/vscode-hook.py &`

- 使用docker运行

    ```bash
    docker run -d \
        --net=host \
        --cap-add=NET_ADMIN \
        --cap-add=NET_RAW \
        --restart=always \
        --name natter \
        nattertool/natter -m iptables -p 18888 -i 192.168.1.100
    ```
    查看打洞信息
    ```bash
    docker logs natter
    2026-06-23 07:31:50 [I] Natter v2.2.1
    2026-06-23 07:31:57 [I] 
    2026-06-23 07:31:57 [I] tcp://192.168.1.100:18888 <--iptables--> tcp://192.168.1.100:41177 <--Natter--> tcp://101.204.28.118:40232
    2026-06-23 07:31:57 [I] 
    2026-06-23 07:31:57 [I] LAN > 192.168.1.100:18888   [ OPEN ]
    2026-06-23 07:31:57 [I] LAN > 192.168.1.100:41177   [ OPEN ]
    2026-06-23 07:31:57 [I] LAN > 101.204.28.118:40232   [ OPEN ]
    2026-06-23 07:32:13 [I] WAN > 101.204.28.118:40232   [ OPEN ]
    2026-06-23 07:32:13 [I]
    ```

### Hook调用

Natter 支持Hook调用，即在打洞成功后执行脚本。

利用这一点，我们可以在打洞成功后自动登录到路由器并设置端口转发，实现一些自动化功能，例如：自动设置端口转发、自动修改 qBittorrent 传输端口、配置消息推送等。

以下提供一些使用模板，仅建议愿意折腾的小伙伴使用，欢迎大家PR！

* [自动设置端口转发](https://github.com/1368129224/Natter-User-Guide/blob/main/template/auto_forward/auto_forward.md)

    适用于具有 [UCI](https://openwrt.org/zh/docs/guide-user/base-system/uci) 系统的 OpenWRT 路由器，自动设置端口转发。

* [自动设置 qBittorrent 传输端口](https://github.com/1368129224/Natter-User-Guide/blob/main/template/qBittorrent/qBittorrent.md)

    自动修改 qBittorrent 传输端口，提高连通性。

* [使用 message-pusher 进行推送消息](https://github.com/1368129224/Natter-User-Guide/blob/main/template/push/push.md)

    使用 [message-pusher](https://github.com/songquanpeng/message-pusher) 在网络环境改变时进行消息推送。

## Thanks

* [Natter](https://github.com/MikeWang000000/Natter)
