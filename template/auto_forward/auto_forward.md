# 自动设置端口转发（OpenWrt）

适用于路由器开启了 Full Cone NAT 但不想开启全局 DMZ 的场景：每次 Natter 打洞端口变化时，通过 SSH 调用 OpenWrt 的 [UCI](https://openwrt.org/zh/docs/guide-user/base-system/uci) 系统自动更新端口转发规则。

## 准备

登录路由器 SSH 后台，执行 `uci` 命令，有如下输出即具备 UCI 系统：

```shell
root@ImmortalWrt:~# uci
Usage: uci [<options>] <command> [<arguments>]
```

## 配置步骤

### 1. 配置 SSH 免密登录 OpenWrt 路由器

> **注意**：请确保在**实际运行 Natter 的系统用户**下配置密钥（例如使用 `sudo` 或 `-m iptables` 运行 Natter 时，需在 `root` 用户下配置 `/root/.ssh/`）。

1. 在运行 Natter 的机器上生成 `ed25519` 密钥对（一路回车留空密码）：
    ```shell
    ssh-keygen -t ed25519
    ```

2. 将生成的公钥 `~/.ssh/id_ed25519.pub` 内容追加到 OpenWrt 的 `/etc/dropbear/authorized_keys`（若使用 OpenSSH 则为 `~/.ssh/authorized_keys`）。

3. 编辑 `~/.ssh/config`（不存在则新建，权限设为 `600`）：
    ```text
    Host openwrt
        HostName 192.168.1.1
        User root
        IdentityFile ~/.ssh/id_ed25519
    ```

4. **手动执行一次 `ssh openwrt`**，输入 `yes` 确认主机指纹写入 `known_hosts`，验证无需密码即可直接登录 OpenWrt 后台（否则后台触发 Hook 时会卡在首次指纹确认）。

### 2. 创建初始端口转发规则

可以通过路由器 Web 后台（网络 -> 防火墙 -> 端口转发）创建一条占位规则，也可以登录 OpenWrt 后台通过 UCI 命令创建：

```shell
uci add firewall redirect
uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].target='DNAT'
# 规则名称，按需修改
uci set firewall.@redirect[-1].name='natter-forward'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].proto='tcp'
# 以下初始端口与 IP 可先任意填写，后续由 Hook 自动覆盖
uci set firewall.@redirect[-1].src_dport='51000'
uci set firewall.@redirect[-1].dest_ip='192.168.1.100'
uci set firewall.@redirect[-1].dest_port='7681'
uci commit firewall
/etc/init.d/firewall reload
```

**记住规则 ID**：创建好规则后，可通过 `uci show firewall | grep "\.name='natter-forward'"` 查看对应的 `@redirect[id]` 索引（Web 后台列表中从上到下 ID 从 `0` 递增）。

### 3. 配置并启用 Hook 脚本

复制 [auto_forward.template.sh](auto_forward.template.sh) 为 `auto_forward.sh`，按实际情况修改 `rule_id`，并赋予执行权限：

```shell
cp auto_forward.template.sh auto_forward.sh
chmod +x auto_forward.sh
```

脚本核心逻辑如下：

```bash
#!/usr/bin/env bash
set -eu

protocol="$1"
inner_ip="$2"
inner_port="$3"
outer_ip="$4"
outer_port="$5"

rule_id="0"
# 留空时默认转发到 Natter 自身的 inner_port，由 Natter (-p) 继续转发给目标服务
target_port=""

dest_port="${target_port:-$inner_port}"

ssh openwrt "uci set firewall.@redirect[${rule_id}].src_dport='${outer_port}'; \
uci set firewall.@redirect[${rule_id}].dest_ip='${inner_ip}'; \
uci set firewall.@redirect[${rule_id}].dest_port='${dest_port}'; \
uci commit firewall; \
uci show firewall.@redirect[${rule_id}]; \
/etc/init.d/firewall reload"
```

启动 Natter 时通过 `-e` 指定该脚本即可：

```shell
sudo python3 ./natter.py -m iptables -p 7681 -e ./auto_forward.sh
```

> **提示**：部分固件（如 `ImmortalWrt 21.02.5`）在 `uci commit firewall` 后无需执行 `firewall reload` 即可生效，可根据实际固件测试情况增减最后一步。
