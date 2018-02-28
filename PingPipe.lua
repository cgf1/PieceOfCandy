local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end
local LGPS = LibStub("LibGPS2", true)

local TWOBYTES = 65536
local ROUND = .5 / TWOBYTES

local xxx
local pingerr = function() end
local show_errors = false

local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

POC_PingPipe = {
    Name = "POC_PingPipe",
    active = false
}
POC_PingPipe.__index = POC_PingPipe

local saved

local function unpack_ultpct(x)
    pct2 = x % 124
    x = math.floor(x / 124)
    apid2 = (x % POC_Ult.MaxPing) + 1
    x = math.floor(x / POC_Ult.MaxPing)
    pct1 = x % 124
    apid1 = math.floor(x / 124) + 1
    return apid1, pct1, apid2, pct2
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

    local bytes = POC_Comm.ToBytes(input)
    local ctype = bytes[1]
    if ctype == POC_COMM_TYPE_PCTULTOLD then
	POC_Player.Update(pingtag, bytes[2], bytes[3])
    elseif ctype == POC_COMM_TYPE_COUNTDOWN then
	POC_Countdown.Start(bytes[2])
    elseif ctype == POC_COMM_TYPE_PCTULT then
	input = math.floor(input / 256)
	local apid1, pct1, apid2, pct2 = unpack_ultpct(input)
-- if GetUnitName(pingtag) == GetUnitName("player") then POC.xxx("Receiving ", input, apid1, pct1, apid2, pct2) end
	POC_Player.Update(pingtag, apid1, pct1, apid2, pct2)
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

function POC_PingPipe.SendWord(word)
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

function POC_PingPipe.Send(...)
    local bytes = {...}
    local word = 0
    local mul = 1
    for i, v in ipairs(bytes) do
	word = word + (mul * v)
	mul = mul * 256
    end
    POC_PingPipe.SendWord(word)
end

-- Unload PingPipe
--
function POC_PingPipe.Unload()
    CALLBACK_MANAGER:UnregisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    LMP:UnregisterCallback("AfterPingRemoved", map_ping_finished)
    SLASH_COMMANDS["/pocpingerr"] = nil
    POC_PingPipe.active = false
end

-- Initialize POC_PingPipe
--
function POC_PingPipe.Load()
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:RegisterCallback("BeforePingAdded", on_map_ping)
    LMP:RegisterCallback("AfterPingRemoved", map_ping_finished)

    xxx = POC.xxx
    saved = POC_Settings.SavedVariables

    SLASH_COMMANDS["/pocpingerr"] = function()
	show_errors = not show_errors
	if show_errors then
	    pingerr = POC_Error
	else
	    pingerr = function() return end
	end
	d("show_errors " .. tostring(show_errors))
    end
    POC_PingPipe.active = true
end
