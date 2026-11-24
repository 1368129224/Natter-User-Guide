#!/bin/sh
set -eu

# 如果存在自定义 resolv.conf，覆盖容器内 /etc/resolv.conf
if [ -f /opt/natter-resolv.conf ]; then
  cp /opt/natter-resolv.conf /etc/resolv.conf || true
fi

exec /opt/natter.py "$@"
