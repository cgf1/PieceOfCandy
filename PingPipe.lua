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
local function handle_pctult(pingtag, apid, pct)
    local ult = POC_Ult.ByPing(apid)

    if (ult == nil or pct == -1) then
	pingerr("handle_pctult: error: ult: " .. tostring(ult) .. "; pct: " .. tostring(pct))
	return
    end

    local player = {
	PingTag = pingtag,
	UltPct = pct,
	ApiVer = apiver
    }

    if true or apiver == POC_API_VERSION then
	player.UltAid = ult.Aid
	player.InvalidClient = false
    else
	player.UltAid = POC_Ult.MaxPing
	player.InvalidClient = true
    end

    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
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

    local bytes = {}
    for i = 1, 4 do
	bytes[i] = input % 256
	input = math.floor(input / 256)
    end
    local ctype = bytes[1]
    if ctype == POC_COMM_TYPE_PCTULT then
	handle_pctult(pingtag, bytes[2], bytes[3])
    elseif ctype == POC_COMM_TYPE_COUNTDOWN then
	POC_Countdown.Start(bytes[2])
    end
end

-- Called on map ping from LibMapPing
--
local function map_ping_finished(pingtype, pingtag, x, y, isLocalPlayerOwner)
    if unsuppress then
	LMP:UnsuppressPing(pingtype, pingtag)
    end
    unsuppress = false
end

-- Called on refresh of timer
--
function POC_PingPipe.Send(...)
    local bytes = {...}
    local word = 0
    local mul = 1
    for i, v in ipairs(bytes) do
	word = word + (mul * v)
	mul = mul * 256
    end

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
