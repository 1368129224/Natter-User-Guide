# Natter 与 Mihomo TUN 模式共存部署模板

本模板提供了在宿主机运行 **Mihomo (Clash.Meta) TUN 模式** 时，让 Natter 流量绕过透明代理直出物理网卡打洞的完整配套文件。

## 目录文件说明

- `natter-nft-bypass.sh`: 宿主机 nftables 脚本，用于给 `natter.slice` 的 socket 流量设置 `0x80000` 标记，优先直通物理网卡。
- `natter-direct-route.service`: systemd 服务单元文件，确保开机在 Docker 之前自动应用 nftables 规则。
- `resolv.conf`: 覆盖容器内 DNS，指定宿主机回环口 `127.0.0.53`，避免未显式 bind 的 DNS 走 TUN 网卡导致源 IP 被篡改。
- `natter-entrypoint.sh`: Docker 容器入口脚本，负责启动时将 `resolv.conf` 复制到 `/etc/resolv.conf`。
- `Dockerfile`: 构建带有 `requests` 模块与自定义 entrypoint 的 Debian 版 Natter 镜像。
- `docker-compose.yml`: Docker Compose 启动定义，绑定 `cgroup_parent: natter.slice` 与宿主机网络。

## 部署步骤

### 1. 宿主机部署 nftables 绕行规则

```bash
# 复制脚本到 /usr/local/bin 并赋予可执行权限
sudo cp natter-nft-bypass.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/natter-nft-bypass.sh

# 复制 systemd 服务
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
