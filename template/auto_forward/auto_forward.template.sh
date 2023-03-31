uci add firewall redirect
uci show firewall.@redirect[-1]

uci set firewall.@redirect[-1].dest='lan'
uci set firewall.@redirect[-1].target='DNAT'
uci set firewall.@redirect[-1].name='ttyd'
uci set firewall.@redirect[-1].src='wan'
uci set firewall.@redirect[-1].src_dport='51000'
uci set firewall.@redirect[-1].dest_ip='192.168.1.100'
uci set firewall.@redirect[-1].dest_port='7681'

uci commit firewall
/etc/init.d/firewall restart

echo "Update openwrt firewall..."

ssh openwrt "uci set firewall.@redirect[$rule_id].dest_port=$target_port;uci set firewall.@redirect[$rule_id].src_dport=$inner_port;uci commit firewall;uci show firewall.@redirect[$rule_id];/etc/init.d/firewall restart;exit"
