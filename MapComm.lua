setfenv(1, POC)
local LMP = LibMapPing
local LGPS = LibGPS2

local getmapping = LMP.GetMapPing

local GetMapNameByIndex = GetMapNameByIndex
local GetNumMaps = GetNumMaps
local GetGameTimeMilliseconds = GetGameTimeMilliseconds
local GetTimeStamp = GetTimeStamp

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
local mapindex
local dispatch
local packing

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

local function mapop(func, mapindex, ...)
    local args = {...}
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(mapindex)
    local x, y = func(unpack(args))
    if x ~= nil and y ~= nil and not LMP:IsPositionOnMap(x, y) then
	x = -1
	y = -1
    end
    LGPS:PopCurrentMap()
    return x, y
end

local function unpacker(x, y, data)
    local xy = string.format(fsignif, x + ROUND):sub(3) .. string.format(fsignif, y + ROUND):sub(3)
    cmd = tonumber(xy:sub(1, 2))
    local packing = packing[cmd]
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

local OCOMM_ULTPCT_MUL1 = 30 * 124
local function ounpack_ultpct(cmd, data)
    local x = 0
    for i = #data, 1, -1 do
	x = (x * 256) + data[i]
    end
    local lower = x % OCOMM_ULTPCT_MUL1
    local upper = math.floor(x / OCOMM_ULTPCT_MUL1)
    local pct1 = upper % 124
    local apid1 = math.floor(upper / 124) + 1
    local apid2, pct2, pos
    if cmd ~= COMM_TYPE_PCTULT then
	pos = lower
    else
	pct2 = lower % 124
	apid2 = math.floor(lower / 124) + 1
	pos = 0
    end
    if apid2 == 30 then
	apid2 = max_ping
    end
    return apid1, pct1, pos, apid2, pct2
end

-- Called on map ping from LibMapPing
--
local before = 0
local data = {}
local function on_map_ping(pingtype, pingtag)
    if pingtype ~= MAP_PIN_TYPE_PING then
	return
    end
    local x, y = mapop(getmapping, mapindex, LMP, pingtype, pingtag)
    if x < 0 then
	return
    end
    if not LMP:IsPingSuppressed(pingtype, pingtag) then
	LMP:SuppressPing(pingtype, pingtag)
    end

    local unpdata, unppct = unpacker, unpack_ultpct
    unpdata = unpacker
    unppct = unpack_ultpct
    local now = GetTimeStamp()
    local cmd, data = unpdata(x, y, data)
    if cmd then
	local before, name, watchme = dispatch(pingtag, cmd, data, unppct)
	if Watching and name then
	    local now = GetGameTimeMilliseconds()
	    watch('on_map_ping', string.format('%s %s delta %5.2f input %f %f%s', name, pingtag, (now - before) / 1000, x, y, watchme))
	    before = now
	end
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
    local packing = packing[cmd]
    for i, wid in ipairs(packing) do
	s = s .. string.format(fmt[wid], send[i])
    end

    local len = s:len()
    if len <= signif then
	x = tonumber('.' .. s)
	y = 1 / (XY * 10)
    else
	x = tonumber('.' .. s:sub(0, signif))
	y = tonumber('.' .. s:sub(0 - (len - signif)))
    end

    if Watching then
	watch('MapComm.Send', string.format('%s ' .. fsignif .. ' ' .. fsignif, s, x, y))
    end

    -- local before = GetGameTimeMilliseconds()
    mapop(PingMap, mapindex, MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, x, y)
    -- watch("MapComm.Send", GetGameTimeMilliseconds() - before)
end

function MapComm.MapIndex(name)
    if name:len() == 0 then
	Info("Reference map is " ..  GetMapNameByIndex(saved.MapIndex2) .. " (" .. tostring(saved.MapIndex2) .. ")")
	Info("Old reference map is " ..	 GetMapNameByIndex(saved.MapIndex) .. " (" .. tostring(saved.MapIndex) .. ")")
	return
    end
    local lname = name:lower()
    local n
    if tonumber(name) then
	n = tonumber(name)
    else
	for i = 1, GetNumMaps() do
	    if GetMapNameByIndex(i):lower() == lname then
		n = i
		break
	    end
	end
    end
    if n and n <= GetNumMaps() and GetMapNameByIndex(n) then
	mapindex = n
	saved.MapIndex2 = n
	Info(string.format("Setting reference map to %s(%d)", GetMapNameByIndex(n), n))
	return
    end
    Error(string.format("unknown map - %s", name))
end

-- Unload MapComm
--
function MapComm.Unload()
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    Slash("pingerr")
    Slash("signify")
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
    packing = Comm.Packing

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
    mapindex = saved.MapIndex2
    dispatch = Comm.Dispatch
    Slash('signify', 'whatever', function(n)
	n = tonumber(n)
	if n ~= nil then
	    signify(n)
	    Info('set to', n)
	end
    end)

    MapComm.active = true
end
