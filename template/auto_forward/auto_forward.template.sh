# 对应的规则ID
rule_id="0"
# 目标端口，内网设备提供服务的端口
target_port=""

echo "Update openwrt firewall..."

ssh openwrt "uci set firewall.@redirect[$rule_id].dest_port=$target_port;uci set firewall.@redirect[$rule_id].src_dport=$inner_port;uci commit firewall;uci show firewall.@redirect[$rule_id];/etc/init.d/firewall restart;exit"
