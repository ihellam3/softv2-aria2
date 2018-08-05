#!/bin/sh

. /koolshare/scripts/base.sh
. /koolshare/scripts/jshn.sh
. /koolshare/scripts/uci.sh

load_uci_env(){
    config_load aria2
    config_get aria2_mode main mode
    config_get aria2_default main acl
}

start_aria2(){
    /koolshare/aria2/aria2c --conf-path=/tmp/aria2.conf -D >/dev/null 2>&1 &
}

kill_aria2(){
    killall aria2c >/dev/null 2>&1
}

open_port(){
    iptables -I input_wan_rule -p tcp --dport $aria2_rpc_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p tcp --dport 8088 -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p tcp --dport 6881:6889 -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p tcp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p tcp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p udp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
}

close_port(){
    iptables -D input_wan_rule -p tcp --dport $aria2_rpc_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p tcp --dport 8088 -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p tcp --dport 6881:6889 -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p tcp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p tcp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p udp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
}

on_get(){
    lua -<<EOF
require "luci.cacheloader"
require "luci.sgi.cgi"
luci.dispatcher.indexcache = "/tmp/luci-indexcache"
local index = require "luci.controller.apps.aria2.index"
index.prepare_conf()

EOF

}

case $ACTION in
start)
    echo '{}'
    ;;
restart)
    echo '{}'
    ;;
post)
    echo '{}'
    ;;
get)
    on_get
    ;;
installed)
    app_init_cfg '{"aria2":[{"_id":"main","enabled":"0","dir":"/tmp/mnt/sda","dht_enabled":"0","rpc_enabled":"0","rpc_listen":"6800","rpc_token":" ","bt_listen":"6888","max_conn":"60","trackers":" ","useragent":"user-agent=uTorrent/2210(25130),peer-id-prefix=-UT2210-"}]}'
    ;;
stop)
    ;;
esac
