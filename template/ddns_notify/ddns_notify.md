# Cloudflare DDNS（免端口访问）与消息推送通知

家宽打洞获得的公网 IP 和公网端口（`outer_port`）都会周期性变化。本模板集成了两个最常用的后置自动化能力：
1. **Cloudflare 动态域名解析（A 记录 + HTTPS 记录）**：除了自动更新公网 IP，还支持配置 `HTTPS`（SVCB）记录携带动态端口，现代浏览器访问 `https://web.example.com` 时会自动连接对应的非标打洞端口，实现**免输入端口号访问**。
2. **多渠道消息通知**：支持在打洞成功或端口变动时，通过 **Telegram Bot**、**企业微信 / 飞书 / 钉钉 Webhook** 或 **Bark** 第一时间推送最新公网地址。

## 配置说明

### 1. 复制并授权脚本

```shell
cp ddns_notify.template.sh ddns_notify.sh
chmod +x ddns_notify.sh
```

### 2. 按需开启功能模块

编辑 `ddns_notify.sh` 顶部的配置区：

#### A. Cloudflare DDNS 与 HTTPS 免端口记录（可选）
1. 在 Cloudflare 控制台 **My Profile -> API Tokens** 创建令牌，授予目标域名的 **Zone -> DNS -> Edit** 权限，填入 `cf_api_token`。
2. 在域名概览页右下角复制 **Zone ID** 填入 `cf_zone_id`。
3. 设置 `cf_enable="true"` 并填写 `cf_a_record_name`（如 `nas.example.com`）。
4. **如需浏览器免端口访问 HTTPS 服务**：
   - 确保内网反向代理（如 Nginx / Lucky / Caddy）已配置对应域名的有效 TLS 证书；
   - 填写 `cf_https_record_name`（如 `web.example.com`，建议与 `cf_a_record_name` 区分开），现代浏览器（Chrome / Edge / Safari / Firefox）通过 DoH 查询 `HTTPS` 记录后即可直接无端口访问 `https://web.example.com`。

#### B. 消息通知（可选）
- **Telegram**：将 `tg_enable` 设为 `"true"`，填入 `tg_bot_token` 与 `tg_chat_id`。
- **企业微信 / 飞书 / 钉钉群机器人**：将 `webhook_enable` 设为 `"true"`，填入群机器人的 `webhook_url`（若开启了关键词安全设置，可将关键词设为 `Natter`）。
- **Bark (iOS)**：将 `bark_enable` 设为 `"true"`，填入 `bark_key`（如有自建服务端可修改 `bark_server`）。

> **提示**：如果你使用了 [Mihomo TUN 模式共存方案](../mihomo_bypass/README.md)，Natter 容器默认直连国内网络；访问 Cloudflare 或 Telegram API 时，只需取消脚本顶部 `HTTPS_PROXY` / `HTTP_PROXY` 的注释并指向本机代理端口即可。

### 3. 启动 Natter

```shell
python3 ./natter.py -p 18888 -e ./ddns_notify.sh
```
