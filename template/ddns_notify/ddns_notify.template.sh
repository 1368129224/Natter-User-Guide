#!/usr/bin/env bash
set -eu

protocol="$1"
inner_ip="$2"
inner_port="$3"
outer_ip="$4"
outer_port="$5"

# ==================== 可选代理配置 ====================
# 若宿主机开启了 Mihomo TUN 绕行但需访问 Cloudflare / Telegram 等境外接口，可取消注释：
# export HTTPS_PROXY="http://127.0.0.1:7890"
# export HTTP_PROXY="http://127.0.0.1:7890"

# ==================== 1. Cloudflare DNS 配置 ====================
cf_enable="false"                  # 设为 "true" 启用 Cloudflare 更新
cf_api_token=""                    # Cloudflare API Token（需具备对应域名的 Zone.DNS 编辑权限）
cf_zone_id=""                      # 域名的 Zone ID
cf_a_record_name="nas.example.com" # 用于绑定公网 IP 的 A 记录完整域名
cf_https_record_name=""            # 可选：填写如 "web.example.com" 自动维护 HTTPS 记录以实现浏览器免端口访问

# ==================== 2. 消息通知配置 ====================
# Telegram Bot 推送
tg_enable="false"
tg_bot_token=""
tg_chat_id=""

# 通用 JSON Webhook 推送（兼容企业微信 / 飞书 / 钉钉群机器人等）
webhook_enable="false"
webhook_url=""

# Bark 推送（iOS）
bark_enable="false"
bark_server="https://api.day.app"
bark_key=""

msg_title="Natter 端口映射更新"
msg_body="${protocol}://${outer_ip}:${outer_port} -> ${inner_ip}:${inner_port}"
echo "[Hook] ${msg_title}: ${msg_body}"

# -------------------- Cloudflare API 辅助函数 --------------------
cf_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  if [ -n "${data}" ]; then
    curl -fsSL -X "${method}" "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}${endpoint}" \
      -H "Authorization: Bearer ${cf_api_token}" \
      -H "Content-Type: application/json" \
      --data "${data}"
  else
    curl -fsSL -X "${method}" "https://api.cloudflare.com/client/v4/zones/${cf_zone_id}${endpoint}" \
      -H "Authorization: Bearer ${cf_api_token}" \
      -H "Content-Type: application/json"
  fi
}

if [ "${cf_enable}" = "true" ]; then
  echo "Updating Cloudflare A record (${cf_a_record_name} -> ${outer_ip}) ..."
  a_resp=$(cf_api GET "/dns_records?type=A&name=${cf_a_record_name}")
  a_id=$(printf '%s' "${a_resp}" | grep -o '"id":"[^"]*"' | head -n1 | cut -d'"' -f4 || true)
  a_payload="{\"type\":\"A\",\"name\":\"${cf_a_record_name}\",\"content\":\"${outer_ip}\",\"ttl\":60,\"proxied\":false}"

  if [ -n "${a_id}" ]; then
    cf_api PUT "/dns_records/${a_id}" "${a_payload}" >/dev/null
  else
    cf_api POST "/dns_records" "${a_payload}" >/dev/null
  fi

  if [ -n "${cf_https_record_name}" ]; then
    echo "Updating Cloudflare HTTPS record (${cf_https_record_name} -> ${cf_a_record_name}:${outer_port}) ..."
    h_resp=$(cf_api GET "/dns_records?type=HTTPS&name=${cf_https_record_name}")
    h_id=$(printf '%s' "${h_resp}" | grep -o '"id":"[^"]*"' | head -n1 | cut -d'"' -f4 || true)
    h_payload="{\"type\":\"HTTPS\",\"name\":\"${cf_https_record_name}\",\"ttl\":60,\"data\":{\"priority\":1,\"target\":\"${cf_a_record_name}\",\"value\":\"port=${outer_port}\"}}"

    if [ -n "${h_id}" ]; then
      cf_api PUT "/dns_records/${h_id}" "${h_payload}" >/dev/null
    else
      cf_api POST "/dns_records" "${h_payload}" >/dev/null
    fi
  fi
fi

# -------------------- 消息推送 --------------------
if [ "${tg_enable}" = "true" ]; then
  echo "Sending Telegram notification ..."
  curl -fsSL -X POST "https://api.telegram.org/bot${tg_bot_token}/sendMessage" \
    --data-urlencode "chat_id=${tg_chat_id}" \
    --data-urlencode "text=${msg_title}
${msg_body}" >/dev/null
fi

if [ "${webhook_enable}" = "true" ]; then
  echo "Sending Webhook notification ..."
  # 默认采用通用文本格式（兼容飞书/企微可按平台调整字段）
  curl -fsSL -X POST "${webhook_url}" \
    -H "Content-Type: application/json" \
    --data "{\"msgtype\":\"text\",\"msg_type\":\"text\",\"text\":{\"content\":\"${msg_title}: ${msg_body}\"},\"content\":{\"text\":\"${msg_title}: ${msg_body}\"}}" >/dev/null
fi

if [ "${bark_enable}" = "true" ]; then
  echo "Sending Bark notification ..."
  curl -fsSL -X POST "${bark_server}/${bark_key}" \
    --data-urlencode "title=${msg_title}" \
    --data-urlencode "body=${msg_body}" >/dev/null
fi

echo "Done."
