setfenv(1, POC)
local LMP = LibStub("LibMapPing")
local LGPS = LibStub("LibGPS2", true)
local GetAPIVersion = GetAPIVersion

local XY
local ROUND

local pingerr = function() end
local show_errors = false

MapComm = {
    Name = "POC-MapComm",
    active = false,
    lastmycomm = 0,
    lastmytime = 0
}
MapComm.__index = MapComm

local MapComm = MapComm

local max_ping

local myname = GetUnitName("player")

local saved
local signif
local fsignif

-- LIFO!
local function unpack_ultpct(cmd, data)
    local pct1 = data[1] % 124
    local apid1 = math.floor(data[1] / 124) + 1

    local pos, apid2, pct2
    if cmd ~= COMM_TYPE_PCTULT then
	pos = data[2]
	apid2 = 0
	pct2 = 0
    else
	pos = 0
	pct2 = data[2] % 124
	apid2 = math.floor(data[2] / 124) + 1
    end
    return apid1, pct1, pos, apid2, pct2
end

local function mapop(func, ...)
    local args = {...}
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(saved.MapIndex2)
    local x, y = func(unpack(args))
    if x ~= nil and y ~= nil and not LMP:IsPositionOnMap(x, y) then
	x = -1
	y = -1
    end
    LGPS:PopCurrentMap()
    return x, y
end

local function unpacker(x, y, data)
    local xy = x .. y
    cmd = tonumber(xy:sub(1, 2))
    local packing = Comm.Packing[cmd]
    if not packing then
	-- Error(string.format('unknown code: 0x%2x', cmd))
	return nil
    end
    local n = 3
    local s = Watching and tostring(cmd)
    for i, wid in ipairs(packing) do
	data[i] = tonumber(xy:sub(n, n + wid - 1))
	s = Watching and (s .. ' ' .. tostring(data[i]))
	n = n + wid
    end
    watch('unpacker', s)
    return cmd, data
end


-- Called on map ping from LibMapPing
--
local before = 0
local data = {}
local function on_map_ping(pingtype, pingtag)
    if pingtype ~= MAP_PIN_TYPE_PING then
	return
    end
    local x, y = mapop(LMP.GetMapPing, LMP, pingtype, pingtag)
    if x < 0 then
	return
    end
    local sx = string.format(fsignif, x + ROUND):sub(3)
    local sy = string.format(fsignif, y + ROUND):sub(3)

    local name
    local watchme = ''
    local cmd, data = unpacker(sx, sy, data)
    if cmd then
	local timenow = GetTimeStamp()
	if name == myname then
	    MapComm.lastmytime = timenow
	    MapComm.lastmycomm = cmd
	end
	local apid1, pct1, pos, apid2, pct2
	local fwctimer = 0
	if cmd == COMM_TYPE_COUNTDOWN then
	    Countdown.Start(data[1])
	    name = 'COUNTDOWN'
	elseif cmd == COMM_TYPE_NEEDQUEST then
	    Quest.Process(pingtag, data[1], data[2])
	    name = 'NEEDQUEST'
	elseif cmd == COMM_TYPE_MYVERSION then
	    Player.SetVersion(pingtag, data[1], data[2], data[3])
	    name = 'MYVERSION'
	elseif cmd == COMM_TYPE_KEEPALIVE then
	    Player.New(pingtag, timenow)
	    name = 'KEEPALIVE'
	elseif cmd == COMM_TYPE_MAKEMELEADER then
	    Player.MakeLeader(pingtag)
	    name = 'MAKEMELEADER'
	elseif cmd == COMM_TYPE_NEEDHELP then
	    Alert.NeedsHelp(pingtag)
	    name = 'NEEDSHELP'
	elseif cmd == COMM_TYPE_ULTFIRED then
	    Alert.UltFired(pingtag, data[1])
	    name = 'ULTFIRED'
	elseif cmd == COMM_TYPE_PCTULT or cmd == COMM_TYPE_PCTULTPOS then
	    apid1, pct1, pos, apid2, pct2 =	 unpack_ultpct(cmd, data)
	    if Watching then
		watchme = string.format(" ult info: apid1 %d, pct1 %d, pos %d, apid2 %d, pct2 %d", apid1, pct1, pos, apid2, pct2)
	    end
	    if cmd == COMM_TYPE_PCTULT then
		name = 'PCTULT'
	    else
		name = 'PCULTPOS'
	    end
	elseif cmd == COMM_TYPE_FWCAMPTIMER then
	    fwctimer = data
	    name = 'FWCAMPTIMER'
	else
	    name = 'UNKNOWN'
	end
	if apid1 or fwctimer then
	    Player.New(pingtag, timenow, fwctimer, apid1, pct1, pos, apid2, pct2)
	end
    end
    if not LMP:IsPingSuppressed(pingtype, pingtag) then
	LMP:SuppressPing(pingtype, pingtag)
    end
    if Watching and name then
	local now = GetGameTimeMilliseconds()
	watch('on_map_ping', string.format('%s %s delta %5.2f input %s %s%s', name, pingtag, (now - before) / 1000, sx, sy, watchme))
	before = now
    end
end

local fmt = {
    '%1d',
    '%02d',
    '%03d',
    '%04d',
    '%05d',
    '%06d',
    '%07d',
    '%08d',
    '%09d',
    '%010d'
}
function MapComm.Send(cmd, send)
    local s = string.format('%02d', cmd)
    local packing = Comm.Packing[cmd]
    for i, wid in ipairs(packing) do
	s = s .. string.format(fmt[wid], send[i])
    end

    local len = s:len()
    if len <= signif then
	x = 1 / (XY * 10)
    else
	x = tonumber('.' .. s:sub(0, signif))
    end
    y = tonumber('.' .. s:sub(0 - (len - signif)))

    if Watching then
	watch('MapComm.Send', string.format('%s ' .. fsignif .. ' ' .. fsignif, s, x, y))
    end

    -- local before = GetGameTimeMilliseconds()
    mapop(PingMap, MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, x, y)
    -- watch("MapComm.Send", GetGameTimeMilliseconds() - before)
end

-- Unload MapComm
--
function MapComm.Unload()
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    Slash("pingerr")
    MapComm.active = false
    for i = 1, 24 do
	LMP:UnsuppressPing(MAP_PIN_TYPE_PING, 'group' .. i)
    end
end

function signify(n)
    signif = n
    XY = 10 ^ signif
    ROUND = -.1 / XY
    fsignif = '%0.' .. signif .. 'f'
    fsignifs = '.%0' .. signif .. 's'
end

-- Initialize MapComm
--
function MapComm.Load()
    LMP:RegisterCallback("BeforePingAdded", on_map_ping)
    --[[
    EVENT_MANAGER:RegisterForEvent('POC-Comm', EVENT_MAP_PING, function (eventCode, pingEventType, pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
	HERE('PING!', eventCode, pingEventType, pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
    end)]]--

    saved = Settings.SavedVariables

    max_ping = Ult.MaxPing
    signify(5)

    Slash("pingerr", "debugging: show all map ping errors",function()
	show_errors = not show_errors
	if show_errors then
	    pingerr = Error
	else
	    pingerr = function() return end
	end
	Info(string.format("show_errors: %s", tostring(show_errors)))
    end)
    Slash('signify', 'whatever', function(n)
	n = tonumber(n)
	if n ~= nil then
	    signify(n)
	    Info('set to', n)
	end
    end)

    MapComm.active = true
end
