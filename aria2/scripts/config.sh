#!/bin/sh

. /koolshare/scripts/base.sh
. /koolshare/scripts/jshn.sh
. /koolshare/scripts/uci.sh

load_uci_env(){
    config_load aria2
    config_get aria2_enabled main enabled
    config_get aria2_rpc_listen_port main rpc_listen
    config_get aria2_listen_port main bt_listen
}

start_aria2(){
    $APP_ROOT/bin/aria2c --conf-path=/tmp/aria2.conf -D >/dev/null 2>&1 &
}

kill_aria2(){
    killall aria2c >/dev/null 2>&1
}

open_port(){
    iptables -I input_wan_rule -p tcp --dport 6881:6889 -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p tcp --dport $aria2_rpc_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -I input_wan_rule -p udp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
}

close_port(){
    iptables -D input_wan_rule -p tcp --dport 6881:6889 -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p tcp --dport $aria2_rpc_listen_port -j ACCEPT >/dev/null 2>&1
    iptables -D input_wan_rule -p udp --dport $aria2_listen_port -j ACCEPT >/dev/null 2>&1
}

prepare_conf(){
    lua -<<EOF
require "luci.cacheloader"
require "luci.sgi.cgi"
luci.dispatcher.indexcache = "/tmp/luci-indexcache"
local index = require "luci.controller.apps.aria2.index"
index.prepare_conf(nil)

EOF

}

on_post(){
    load_uci_env
    if [ "$aria2_enabled" = "1" ]; then
        kill_aria2
        close_port
        start_aria2
        open_port
    else
        kill_aria2
        close_port
    fi
    status=`pidof aria2c`
    echo '{"status":"'$status'"}'
}

case $ACTION in
start)
    load_uci_env
    prepare_conf
    start_aria2
    open_port
    ;;
restart)
    load_uci_env
    kill_aria2
    close_port
    prepare_conf
    start_aria2
    open_port
    ;;
post)
    on_post
    ;;
installed)
    app_init_cfg '{"aria2":[{"_id":"main","enabled":"0","dir":"/tmp/mnt/sda","dht_enabled":"0","rpc_enabled":"0","rpc_listen":"6800","rpc_token":" ","bt_listen":"6888","max_conn":"60","trackers":" ","useragent":"user-agent=uTorrent/2210(25130),peer-id-prefix=-UT2210-"}]}'
    touch /koolshare/apps/aria2/aria2.session
    ;;
stop)
    load_uci_env
    kill_aria2
    close_port
    ;;
esac
