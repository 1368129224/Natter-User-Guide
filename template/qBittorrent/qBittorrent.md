# 自动设置 qBittorrent 传输端口

BT / PT 下载时，Tracker 会向其他 Peer 通告 qBittorrent 配置的监听端口（`listen_port`）。为了让外部 Peer 顺利主动连入，需要通过 Hook 将 qBittorrent 的监听端口动态修改为 Natter 打洞获得的公网端口（`outer_port`），从而提升连通率。

## 配置步骤

### 1. 测试能否正常登录 Web API

在运行 Natter 的设备上执行以下命令（请将地址、账号及密码替换为实际值）：

```shell
qb_web_url="https://192.168.1.100:18080"
curl --insecure -s -i \
  --header "Referer: ${qb_web_url}" \
  --data-urlencode "username=admin" \
  --data-urlencode "password=adminadmin" \
  "${qb_web_url}/api/v2/auth/login" | grep -i '^set-cookie:' | grep -o 'SID=[^;[:space:]]*'
```

检查能否输出类似 `SID=6oavHb8b4MtL6PZvVqDpd9vb9eeedryh` 的凭据。若无输出则说明登录失败，请检查 Web UI 地址协议（`http`/`https`）、端口、账号密码或 IP 封禁状态。

### 2. 选择端口转发同步模式

由于 Natter 的 `-p` 参数在启动后目标端口固定，而 qBittorrent 的监听端口会随 `outer_port` 动态变化，建议在 [qBittorrent.template.sh](qBittorrent.template.sh) 中根据你的网络环境配置 `forward_mode`：

* **`forward_mode="openwrt"`（未开启 DMZ，搭配 OpenWrt 路由）**：
  先参考 [自动设置端口转发](../auto_forward/auto_forward.md) 配置好 SSH 免密与初始规则，脚本会自动将路由器 WAN 口的 `outer_port` 直接 DNAT 到本机的 `outer_port`。此时 Natter 仅负责维持打洞映射，不加 `-p` 参数（可加 `-q` 退出测试或保持运行）：
  ```shell
  python3 ./natter.py -e ./qBittorrent.sh
  ```
* **`forward_mode="iptables"`（路由器已开启 DMZ 指向本机）**：
  公网访问 `outer_port` 的流量经路由器 Full Cone NAT 后会到达本机的 `inner_port`。当 `inner_port` 与 `outer_port` 不一致时，脚本会自动在本机 `NATTER_QB` 链中将 `inner_port` 重定向至 `outer_port`（需使用 `sudo` 运行 Natter）：
  ```shell
  sudo python3 ./natter.py -e ./qBittorrent.sh
  ```
* **`forward_mode="none"`**：
  仅调用 API 更新 qBittorrent 监听端口（适合已在自定义脚本中自行处理转发规则的场景）。

### 3. 启用 Hook 脚本

```shell
cp qBittorrent.template.sh qBittorrent.sh
chmod +x qBittorrent.sh
```

按注释修改 `qb_web_url`、`qb_username`、`qb_password` 及 `forward_mode` 后，通过 Natter `-e ./qBittorrent.sh` 调用即可。
