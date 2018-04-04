setfenv(1, POC)
local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end
local LGPS = LibStub("LibGPS2", true)

local TWOBYTES = 65536
local ROUND = .5 / TWOBYTES

local pingerr = function() end
local show_errors = false

PingPipe = {
    Name = "POC-PingPipe",
    active = false
}
PingPipe.__index = PingPipe

local max_ping

local saved
local sendword

-- LIFO!
local function unpack_ultpct(cmd, x)
    local orig_x = x
    local lower = x % COMM_ULTPCT_MUL1
    local upper = math.floor(x / COMM_ULTPCT_MUL1)
    pct1 = upper % 124
    apid1 = math.floor(upper / 124) + 1
    local apid2, pct2, pos
    if cmd == COMM_TYPE_PCTULT then
	pos = lower
    else
	pct2 = lower % 124
	apid2 = math.floor(lower / 124) + 1
    end
    return apid1, pct1, pos, apid2, pct2, pos
end

-- Called on map ping from LibMapPing
--
local unsuppress = false
local function on_map_ping(pingtype, pingtag, x, y, _)
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(saved.MapIndex)
    x, y = LMP:GetMapPing(pingtype, pingtag)
    local onmap = LMP:IsPositionOnMap(x, y)
    LGPS:PopCurrentMap()
    if pingtype ~= MAP_PIN_TYPE_PING or not onmap then
	unsuppress = false
	return
    end

    unsuppress = true

    LMP:SuppressPing(pingtype, pingtag)

    local input = math.floor((x + ROUND) * TWOBYTES) +
		  (TWOBYTES * math.floor((y + ROUND) * TWOBYTES))

    local bytes = Comm.ToBytes(input)
    local ctype = bytes[1]
    local timenow = GetTimeStamp()
    if ctype == COMM_TYPE_PCTULTOLD then
	Player.New(pingtag, timenow, bytes[2], bytes[3])
    elseif ctype == COMM_TYPE_COUNTDOWN then
	Countdown.Start(bytes[2])
    elseif ctype == COMM_TYPE_NEEDQUEST then
	Quest.Process(bytes[2], bytes[3])
    elseif ctype == COMM_TYPE_MYVERSION then
	Player.Version(pingtag, bytes[2], bytes[3], bytes[4] == 1)
    elseif ctype == COMM_TYPE_PCTULT or ctype == COMM_TYPE_PCTULTPOS then
	input = math.floor(input / 256)
	watch("on_map_ping", input)
	local apid1, pct1, pos, apid2, pct2 = unpack_ultpct(cmd, input)
	Player.New(pingtag, timenow, apid1, pct1, pos, apid2, pct2)
    end
end

-- Called on map ping from LibMapPing
--
local function map_ping_finished(pingtype, pingtag, x, y, isLocalPlayerOwner)
    if unsuppress then
	LMP:UnsuppressPing(pingtype, pingtag)
	unsuppress = false
    end
end

function PingPipe.SendWord(word)
    local x = (word % TWOBYTES) / TWOBYTES
    local y = math.floor(word / TWOBYTES) / TWOBYTES
    if y == 0 then
	y = .1 / TWOBYTES
    end

    LGPS:PushCurrentMap()
    SetMapToMapListIndex(saved.MapIndex)
    LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, x, y)
    LGPS:PopCurrentMap()
end

local sendword = PingPipe.SendWord
function PingPipe.Send(...)
    local bytes = {...}
    local word = 0
    local mul = 1
    for i, v in ipairs(bytes) do
	word = word + (mul * v)
	mul = mul * 256
    end

    sendword(word)
end

-- Unload PingPipe
--
function PingPipe.Unload()
    CALLBACK_MANAGER:UnregisterCallback(MAP_PING_CHANGED, rcv)
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    LMP:UnregisterCallback("AfterPingRemoved", map_ping_finished)
    Slash("pingerr")
    PingPipe.active = false
end

-- Initialize PingPipe
--
function PingPipe.Load()
    CALLBACK_MANAGER:RegisterCallback(MAP_PING_CHANGED, rcv)
    LMP:RegisterCallback("BeforePingAdded", on_map_ping)
    LMP:RegisterCallback("AfterPingRemoved", map_ping_finished)

    saved = Settings.SavedVariables

    max_ping = Ult.MaxPing

    Slash("pingerr", "debugging: show all map ping errors",function()
	show_errors = not show_errors
	if show_errors then
	    pingerr = Error
	else
	    pingerr = function() return end
	end
	Info(string.format("show_errors: %s", tostring(show_errors)))
    end)
    PingPipe.active = true
end
