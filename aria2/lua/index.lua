local nixio = require "nixio"
local ksutil = require "luci.ksutil"

module("luci.controller.apps.aria2.index", package.seeall)

function index()
    entry({"apps", "aria2"}, call("action_index"))
end

function action_index()
    ksutil.shell_action("aria2")
end

function prepare_conf()
    local template=[[
bt-max-peers=60
bt-tracker=udp://tracker1.wasabii.com.tw:6969/announce,udp://tracker2.wasabii.com.tw:6969/announce,http://mgtracker.org:6969/announce,http://tracker.mg64.net:6881/announce,http://share.camoe.cn:8080/announce,udp://tracker.opentrackr.org:1337/announce,udp://9.rarbg.com:2710/announce,udp://11.rarbg.me:80/announce,http://tracker.tfile.me/announce,http://tracker3.torrentino.com/announce
check-certificate=false
continue=true
enable-http-pipelining=false
enable-rpc=true
follow-torrent=true
input-file=/koolshare/aria2/aria2.session
listen-port=6888
max-concurrent-downloads=3
max-connection-per-server=10
max-overall-download-limit=0
max-overall-upload-limit=1K
min-split-size=10M
rpc-allow-origin-all=true
rpc-enable=1
rpc-listen-all=true
rpc-listen-port=%s
save-session=/koolshare/aria2/aria2.session
split=10
dir=/mnt/sdb1/downloads
rpc-secret=105b579f-b1ed-4623-a9c0-cb7cb2ba
enable-dht=true
user-agent=uTorrent/2210(25130)
peer-id-prefix=-UT2210-
]]
    print(string.format(template, "6800"))
end

