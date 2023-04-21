# 自动设置端口转发

## 准备

登录路由后台，执行 `uci` 命令，有如下打印则具有 [UCI](https://openwrt.org/zh/docs/guide-user/base-system/uci) 系统。

```shell
root@ImmortalWrt:~# uci
Usage: uci [<options>] <command> [<arguments>]
```

## 配置

1. 配置私钥登录 openwrt 路由器

    在运行 Natter 的机器上生成密钥对
    ```shell
    user@ubuntu:~# ssh-keygen
    Generating public/private rsa key pair.
    Enter file in which to save the key (/home/user/.ssh/id_rsa): 
    Enter passphrase (empty for no passphrase):
    Enter same passphrase again:
    Your identification has been saved in /home/user/.ssh/id_rsa.
    Your public key has been saved in /home/user/.ssh/id_rsa.pub.
    The key fingerprint is:
    51:2d:88:4b:05:f2:80:76:30:25:68:24:d2:e0:75:2f user@ubuntu
    The key's randomart image is:
    +--[ RSA 2048]----+
    |==+=+..+....     |
    |=.=oo++ ... .    |
    |.o . E.o.  .     |
    |      o  .       |
    |        S        |
    |                 |
    |                 |
    |                 |
    |                 |
    +-----------------+
    root@ubuntu:~/.ssh$ ls
    authorized_keys  id_rsa  id_rsa.pub  known_hosts
    ```

    将公钥 `id_rsa.pub` 内容拷贝到 OpenWRT 的 `/etc/dropbear/authorized_keys` 。

    配置ssh，将以下内容添加到 `~/.ssh/config` 中，如果没有就新创建。
    ```
    Host openwrt
    HostName 192.168.1.1
    IdentityFile ~/.ssh/id_rsa
    User root
    ```

    保存后即可使用 `ssh openwrt` 免密登录 OpenWRT 后台。

2. 创建端口转发规则

    可以通过路由器Web后台创建规则，也可以通过登录到 OpenWRT 后台使用 UCI 系统创建规则。

    ```shell
    uci add firewall redirect
    uci set firewall.@redirect[-1].dest='lan'
    uci set firewall.@redirect[-1].target='DNAT'
    uci set firewall.@redirect[-1].name='ttyd' //按你的需求填写
    uci set firewall.@redirect[-1].src='wan'
    uci set firewall.@redirect[-1].src_dport='51000' //可任意填写
    uci set firewall.@redirect[-1].dest_ip='192.168.1.100' //可任意填写
    uci set firewall.@redirect[-1].dest_port='7681' //可任意填写
    uci commit firewall
    /etc/init.d/firewall restart
    ```

    PS: 经测试，`ImmortalWrt 21.02.5` 不需要执行 `/etc/init.d/firewall restart` 即可生效，建议初次配置时手动测试。

    **注意**：创建好规则后，请记住规则的ID，后面将会用到。

    可以通过 `uci show firewall.@redirect[id]` 确定规则ID，也可以通过Web后台查看，从上到下ID从0递增。

3. 编辑Hook

    参考 `auto_forward.template.sh` 修改你的Hook，规则ID即上一步中新创建的规则的ID。

    ```shell
    # 对应的规则ID
    rule_id="0"
    # 目标端口，内网设备提供服务的端口
    target_port=""

    echo "Update openwrt firewall..."

    ssh openwrt "uci set firewall.@redirect[$rule_id].dest_port=$target_port;uci set firewall.@redirect[$rule_id].src_dport=$inner_port;uci commit firewall;uci show firewall.@redirect[$rule_id];/etc/init.d/firewall restart;exit"
    ```

    PS: 经测试，`ImmortalWrt 21.02.5` 不需要执行 `/etc/init.d/firewall restart` 即可生效，填写Hook时根据实际情况增减restart步骤。
