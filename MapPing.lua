local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end
local LGPS = LibStub("LibGPS2", true)

local ABILITY_COEFFICIENT = 100
local ULTIMATE_COEFFICIENT = 1000

local xxx
local pingerr = function() end
local show_errors = false

local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

POC_MapPing = {
    Name = "POC_MapPing",
    active = false
}
POC_MapPing.__index = POC_MapPing
local WROTHGAR = 27

-- Gets ult ID
--
local function get_ult_ping(offset)
    if offset <= 0 then
	pingerr("offset is incorrect: " .. tostring(offset))
	return -1
    end

    local ping = math.floor((offset * ABILITY_COEFFICIENT) + 0.5)
    local apiver = math.floor(ping / POC_Ult.MaxPing)
    ping = ping % POC_Ult.MaxPing
    if ping >= 1 and ping < POC_Ult.MaxPing then
	return ping, apiver
    else
	pingerr("get_ult_ping: offset is incorrect: " .. tostring(ping) .. "; offset: " .. tostring(offset))
	return -1
    end
end

-- Gets ultimate percentage
--
local function get_ult_pct(offset)
    if (offset < 0) then
	pingerr("get_ult_pct: offset is incorrect: " .. tostring(offset))
	return
    end

    local pct = math.floor((offset * ULTIMATE_COEFFICIENT) + 0.5)

    if (pct >= 0 and pct <= 125) then
	return pct
    else
	pingerr("get_ult_pct: pct is incorrect: " .. tostring(pct) .. "; offset: " .. tostring(offset))
	return -1
    end
end

-- Check if map ping is in possible range
--
local function valid_ping(x, y)
    local ok_x = (x >= 0.009 and x <= 2.69)
    local ok_y = (y >= 0.000 and y <= 0.60)

    return ok_x and ok_y
end

-- Called on map ping from LibMapPing
--
local unsuppress = false
local function on_map_ping(pingtype, pingtag, x, y, _)
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(WROTHGAR)
    x, y = LMP:GetMapPing(pingtype, pingtag)
    local onmap = LMP:IsPositionOnMap(x, y)
    LGPS:PopCurrentMap()
    if pingtype ~= MAP_PIN_TYPE_PING or not onmap or not valid_ping(x, y) then
	unsuppress = false
	return
    end

    unsuppress = true

    LMP:SuppressPing(pingtype, pingtag)

    local apid, api = get_ult_ping(x)
    local pct = get_ult_pct(y)
    local ult = POC_Ult.ByPing(apid)

    if (ult == nil or pct == -1) then
	POC_Error("on_map_ping: invalid ult: " .. tostring(ult) .. "; pct: " .. tostring(pct))
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
local function map_ping_finished(pingtype, pingtag, x, y, isLocalPlayerOwner)
    if unsuppress then
	LMP:UnsuppressPing(pingtype, pingtag)
    end
    unsuppress = false
end

-- Called on refresh of timer
--
function POC_MapPing.Send(ultver, pct)
    local type_ping = ultver / ABILITY_COEFFICIENT

    local pct_ping
    if (pct > 0) then
	pct_ping = pct / ULTIMATE_COEFFICIENT
    else
	pct_ping = 0.0001 -- Zero, if you send "0", the map ping will be invalid
    end

    LGPS:PushCurrentMap()
    SetMapToMapListIndex(WROTHGAR)
    LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, type_ping, pct_ping)
    LGPS:PopCurrentMap()
end

-- Unload MapPing
--
function POC_MapPing.Unload()
    CALLBACK_MANAGER:UnregisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:UnregisterCallback("BeforePingAdded", on_map_ping)
    LMP:UnregisterCallback("AfterPingRemoved", map_ping_finished)
    SLASH_COMMANDS["/pocpingerr"] = nil
    POC_MapPing.active = false
end

-- Initialize POC_MapPing
--
function POC_MapPing.Load()
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:RegisterCallback("BeforePingAdded", on_map_ping)
    LMP:RegisterCallback("AfterPingRemoved", map_ping_finished)

    xxx = POC.xxx

    SLASH_COMMANDS["/pocpingerr"] = function()
	show_errors = not show_errors
	if show_errors then
	    pingerr = POC_Error
	else
	    pingerr = function() return end
	end
	d("show_errors " .. tostring(show_errors))
    end
    POC_MapPing.active = true
end
