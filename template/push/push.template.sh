MESSAGE_PUSHER_SERVER="https://msgpusher.com"
MESSAGE_PUSHER_USERNAME="your username"
MESSAGE_PUSHER_TOKEN="your token"

function send_message {
  # 向默认频道发送消息
  curl -s -X POST "$MESSAGE_PUSHER_SERVER/push/$MESSAGE_PUSHER_USERNAME" \
    -d "title=$1&description=$2&content=$3&token=$MESSAGE_PUSHER_TOKEN" \
    >/dev/null
}

function send_message_email {
  # 向邮箱发送消息
  curl -s -X POST "$MESSAGE_PUSHER_SERVER/push/$MESSAGE_PUSHER_USERNAME" \
    -d "title=$1&description=$2&content=$3&token=$MESSAGE_PUSHER_TOKEN&channel=email" \
    >/dev/null
}

function send_message_with_json {
  # 发送JSON格式的消息
  curl -s -X POST "$MESSAGE_PUSHER_SERVER/push/$MESSAGE_PUSHER_USERNAME" \
    -H 'Content-Type: application/json' \
    -d '{"title":"'"$1"'","desp":"'"$2"'", "content":"'"$3"'", "token":"'"$MESSAGE_PUSHER_TOKEN"'"}' \
    >/dev/null
}

send_message 'title' 'description' 'content'
