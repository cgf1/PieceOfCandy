setfenv(1, POC)
local LMP = LibStub("LibMapPing")
local LGPS = LibStub("LibGPS2", true)

local TWOBYTES = 65536
local ROUND = .5 / TWOBYTES

local pingerr = function() end
local show_errors = false

PingPipe = {
    Name = "POC-PingPipe",
    active = false,
    lastmycomm = 0,
    lastmytime = 0
}
PingPipe.__index = PingPipe

local PingPipe = PingPipe

local max_ping

local myname = GetUnitName("player")

local saved
local sendword

-- LIFO!
local function unpack_ultpct(ctype, x)
    local lower = x % COMM_ULTPCT_MUL1
    local upper = math.floor(x / COMM_ULTPCT_MUL1)
    local pct1 = upper % 124
    local apid1 = math.floor(upper / 124) + 1
    local apid2, pct2, pos
    if ctype ~= COMM_TYPE_PCTULT then
	pos = lower
    else
	pct2 = lower % 124
	apid2 = math.floor(lower / 124) + 1
    end
    return apid1, pct1, pos, apid2, pct2
end

local function mapop(func, ...)
    local args = {...}
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(saved.MapIndex)
    local x, y = func(unpack(args))
    LGPS:PopCurrentMap()
    return x, y
end

-- Called on map ping from LibMapPing
--
local function on_map_ping(pingtype, pingtag)
    -- local before = GetGameTimeMilliseconds()
    if pingtype ~= MAP_PIN_TYPE_PING then
	return
    end
    x, y = mapop(LMP.GetMapPing, LMP, pingtype, pingtag)

    local input = math.floor((x + ROUND) * TWOBYTES) +
		  (TWOBYTES * math.floor((y + ROUND) * TWOBYTES))

    local bytes = Comm.ToBytes(input)
    local ctype = bytes[1]
    local timenow = GetTimeStamp()
    local name = GetUnitName(pingtag)
    if name == myname then
	PingPipe.lastmytime = timenow
	PingPipe.lastmycomm = ctype
    end
    local data = math.floor(input / 256)
    watch('on_map_ping', string.format("0x%2x", ctype))
    local apid1, pct1, pos, apid2, pct2
    if ctype == COMM_TYPE_COUNTDOWN then
	Countdown.Start(bytes[2])
    elseif ctype == COMM_TYPE_NEEDQUEST then
	Quest.Process(bytes[2], bytes[3])
    elseif ctype == COMM_TYPE_MYVERSION then
	Player.Version(pingtag, bytes[2], bytes[3], bytes[4])
    elseif ctype == COMM_TYPE_KEEPALIVE then
	Player.New(pingtag, timenow)
    elseif ctype == COMM_TYPE_MAKEMELEADER then
	Player.MakeLeader(pingtag)
    elseif ctype == COMM_TYPE_NEEDHELP then
	Alert.NeedsHelp(pingtag)
    elseif ctype == COMM_TYPE_ULTFIRED then
	Alert.UltFired(pingtag, data)
    elseif ctype == COMM_TYPE_PCTULT or ctype == COMM_TYPE_PCTULTPOS then
	apid1, pct1, pos, apid2, pct2 =	 unpack_ultpct(ctype, data)
    end
    Player.New(pingtag, timenow, apid1, pct1, pos, apid2, pct2)
    if not LMP:IsPingSuppressed(pingtype, pingtag) then
	LMP:SuppressPing(pingtype, pingtag)
    end
    -- watch('on_map_ping', pingtag, GetGameTimeMilliseconds() - before)
end

function PingPipe.SendWord(word)
    local x = (word % TWOBYTES) / TWOBYTES
    local y = math.floor(word / TWOBYTES) / TWOBYTES
    if y == 0 then
	y = .1 / TWOBYTES
    end

    -- local before = GetGameTimeMilliseconds()
    mapop(PingMap, MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, x, y)
    -- watch("PingPipe.SendWord", GetGameTimeMilliseconds() - before)
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
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    Slash("pingerr")
    PingPipe.active = false
    for i = 1, 24 do
	LMP:UnsuppressPing(MAP_PIN_TYPE_PING, 'group' .. i)
    end
end

-- Initialize PingPipe
--
function PingPipe.Load()
    LMP:RegisterCallback("BeforePingAdded", on_map_ping)

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
