local http = require "luci.http"
local nixio = require "nixio"
local ksutil = require "luci.ksutil"
local fs = require "nixio.fs"
local uci  = require "luci.model.uci"
local util = require "luci.util"

module("luci.controller.apps.aria2.index", package.seeall)

function index()
    entry({"apps", "aria2"}, call("action_index"))
    entry({"apps", "aria2", "mounts"}, call("action_mounts"))
end

function action_index()
    local http_method = http.getenv("REQUEST_METHOD")
    local cur = uci.cursor()
    if http_method == "GET" then
        local status = util.exec("pidof aria2c")
        local luci_token = cur:get("luci", "main", "token")
        local aria2_conf = cur:get_all("aria2", "main")
        local dev = util.exec("/koolshare/bin/ddnsto -w")
        local devs = util.split(dev, " ")
        aria2_conf[".anonymous"] = nil
        aria2_conf[".name"] = nil
        aria2_conf[".type"] = nil
        aria2_conf["status"] = status
        aria2_conf["rpc_token"] = luci_token .. "-" .. devs[2]
        local js = ksutil.stringify(aria2_conf)
        http.write(js)
    elseif http_method == "POST" then
        local content = http.content()
        local input = ksutil.parsejson(content)
        cur:set("aria2", "main", "enabled", input["enabled"])
        cur:set("aria2", "main", "download", input["download"])
        cur:commit("aria2")
        if input["enabled"] == "1" then
            prepare_conf(cur)
        end
        local script = ksutil.kspath().."/scripts/aria2-config.sh post"
        local reader = ksutil.popen(script, nil, "aria2")
        luci.ltn12.pump.all(reader, luci.http.write)
    end
end

function prepare_conf(cursor)
    local cur = cursor or uci.cursor()
    local luci_token = cur:get("luci", "main", "token")
    local aria2_conf = cur:get_all("aria2", "main")
    local dev = util.exec("/koolshare/bin/ddnsto -w")
    local devs = util.split(dev, " ")
    local template=[[
bt-max-peers=60
bt-tracker=udp://tracker1.wasabii.com.tw:6969/announce,udp://tracker2.wasabii.com.tw:6969/announce,http://mgtracker.org:6969/announce,http://tracker.mg64.net:6881/announce,http://share.camoe.cn:8080/announce,udp://tracker.opentrackr.org:1337/announce,udp://9.rarbg.com:2710/announce,udp://11.rarbg.me:80/announce,http://tracker.tfile.me/announce,http://tracker3.torrentino.com/announce
check-certificate=false
continue=true
enable-http-pipelining=false
enable-rpc=true
follow-torrent=true
input-file=/koolshare/apps/aria2/aria2.session
listen-port=%s
max-concurrent-downloads=3
max-connection-per-server=10
max-overall-download-limit=0
max-overall-upload-limit=1K
min-split-size=10M
rpc-allow-origin-all=true
rpc-enable=1
rpc-listen-all=true
rpc-listen-port=%s
save-session=/koolshare/apps/aria2/aria2.session
split=10
dir=%s
rpc-secret=%s
enable-dht=true
user-agent=uTorrent/2210(25130)
peer-id-prefix=-UT2210-
]]
   fs.writefile("/tmp/aria2.conf", string.format(template, aria2_conf["bt_listen"], aria2_conf["rpc_listen"], aria2_conf["download"], luci_token .. "-" .. devs[2]))
end

local function mounts()
    local data = {}
    local k = {"fs", "blocks", "used", "available", "percent", "mountpoint"}
    local ps = luci.util.execi("df")

    if not ps then
        return
    else
        ps()
    end

    for line in ps do
        local row = {}

        local j = 1
        for value in line:gmatch("[^%s]+") do
            row[k[j]] = value
            j = j + 1
        end

        if row[k[1]] then

            -- this is a rather ugly workaround to cope with wrapped lines in
            -- the df output:
            --
            --  /dev/scsi/host0/bus0/target0/lun0/part3
            --                   114382024  93566472  15005244  86% /mnt/usb
            --

            if not row[k[2]] then
                j = 2
                line = ps()
                for value in line:gmatch("[^%s]+") do
                    row[k[j]] = value
                    j = j + 1
                end
            end

            table.insert(data, row)
        end
    end

    return data
end

function action_mounts()
    http.prepare_content("application/json; charset=UTF-8")
    local mount_points = mounts()
    local js = ksutil.stringify(mount_points)
    http.write(js)
end
