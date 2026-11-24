# Natter 与 Mihomo TUN 模式共存部署模板

本模板提供了在宿主机运行 **Mihomo (Clash.Meta) TUN 模式** 时，让 Natter 流量绕过透明代理直出物理网卡打洞的完整配套文件。

## 目录文件说明

- `natter-nft-bypass.sh`: 宿主机 nftables 脚本，用于给 `natter.slice` 的 socket 流量原子设置 `0x80000` 标记，优先直通物理网卡。
- `natter-direct-route.service`: systemd 服务单元文件，锚定 `natter.slice` 生命周期并确保开机在 Docker 之前自动应用 nftables 规则。
- `resolv.conf`: 覆盖容器内 DNS，指定宿主机回环口 `127.0.0.53`，避免未显式 bind 的 DNS 走 TUN 网卡导致源 IP 被篡改。
- `natter-entrypoint.sh`: Docker 容器入口脚本，负责启动时将 `resolv.conf` 复制到 `/etc/resolv.conf`。
- `Dockerfile`: 构建带有 `requests` 模块与自定义 entrypoint 的 Debian 版 Natter 镜像。
- `docker-compose.yml`: Docker Compose 启动定义，绑定 `cgroup_parent: natter.slice` 与宿主机网络。

## 前置检查

1. **确认宿主机启用了 cgroup v2 且 Docker 使用 `systemd` 驱动**：
   ```bash
   docker info | grep -i "cgroup"
   # 期望输出包含：
   #  Cgroup Driver: systemd
   #  Cgroup Version: 2
   ```
   > 若 `Cgroup Driver` 为 `cgroupfs`，可在 `/etc/docker/daemon.json` 中配置 `"exec-opts": ["native.cgroupdriver=systemd"]` 后重启 Docker。

2. **确认宿主机本地 DNS 监听情况**：
   本模板 `resolv.conf` 默认指向 `127.0.0.53`（`systemd-resolved`）。执行以下命令确认该地址处于监听状态：
   ```bash
   ss -ulpn | grep 127.0.0.53
   ```
   > 若你的系统（如部分原生 Debian 或定制 NAS 系统）未启用 `systemd-resolved`，可将 `resolv.conf` 中的 `nameserver` 改为你的物理路由器网关地址（如 `192.168.1.1`），因容器内进程已带有 `0x80000` 标记，DNS 请求同样会绕过 TUN 直达网关。

## 部署步骤

### 1. 宿主机部署 nftables 绕行规则

```bash
# 复制脚本到 /usr/local/bin 并赋予可执行权限
sudo cp natter-nft-bypass.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/natter-nft-bypass.sh

# 复制并启用 systemd 服务
sudo cp natter-direct-route.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now natter-direct-route.service
```

### 2. 配置 Mihomo Fake-IP 过滤名单

在宿主机的 `/etc/mihomo/config.yaml`（或其他对应路径）中，将以下域名加入 `dns.fake-ip-filter`：

```yaml
dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-filter:
    - "ifconfig.co"
    - "portcheck.transmissionbt.com"
    - "stun.nextcloud.com"
    - "stun.freeswitch.org"
    - "turn.cloudflare.com"
```
保存后重启 Mihomo：
```bash
sudo systemctl restart mihomo
```

### 3. 启动 Natter 容器

修改 `docker-compose.yml` 中的物理网卡 IP（`-i` 参数）以及目标内网端口（`-p` 参数），然后启动：

```bash
docker compose up -d --build
```

查看打洞状态：
```bash
docker compose logs -f
```

## 进阶：在 Hook 脚本中使用代理

如果需要使用 Hook 脚本（例如更新 Cloudflare DNS 或发送 Telegram 通知），可取消 `docker-compose.yml` 中 `./hooks:/opt/hooks` 的挂载注释，并在 `command` 末尾添加 `-e /opt/hooks/your-hook.py`。

由于容器整体处于直连路由，若 Hook 需要访问境外接口，在代码中显式指定宿主机的 Mihomo 混合端口即可：

```python
proxies = {
    "http": "http://127.0.0.1:7890",
    "https": "http://127.0.0.1:7890",
}
requests.post(api_url, json=payload, proxies=proxies, timeout=15)
```

## 验证与排查

1. **检查 nftables 规则计数**：
   ```bash
   sudo nft list table inet natter-bypass
   # 观察 counter packets 是否随打洞和保活持续增长
   ```
2. **对比策略路由走向**：
   ```bash
   # 带标记流量应走物理网卡网关（如 via 192.168.1.1 dev enp3s0）
   ip route get 1.1.1.1 mark 0x80000
   # 普通流量走 Mihomo TUN
   ip route get 1.1.1.1
   ```
