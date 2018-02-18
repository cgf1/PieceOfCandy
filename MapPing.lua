local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end

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

-- Gets ult ID
--
local function get_ult_ping(offset)
    if (offset <= 0) then
	pingerr("offset is incorrect: " .. tostring(offset))
	return -1
    end

    local ping = math.floor((offset * ABILITY_COEFFICIENT) + 0.5)
    local apiver = math.floor(ping / POC_Ult.MaxPing)
    ping = ping % POC_Ult.MaxPing
    if (ping >= 1 and ping < POC_Ult.MaxPing) then
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
local function valid_ping(offsetX, offsetY)
    local isValidPing = (offsetX ~= 0 or offsetY ~= 0)
    local isCorrectOffsetX = (offsetX >= 0.009 and offsetX <= 2.69)
    local isCorrectOffsetY = (offsetY >= 0.000 and offsetY <= 0.60)

    return isValidPing and (isCorrectOffsetX and isCorrectOffsetY)
end

-- Called on map ping from LibMapPing
--
local function on_map_ping(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    if (pingType == MAP_PIN_TYPE_PING and LMP:IsPositionOnMap(offsetX, offsetY) and
	valid_ping(offsetX, offsetY)) then

	LMP:SuppressPing(pingType, pingtag)

	local type_ping, api = get_ult_ping(offsetX)
	local pct = get_ult_pct(offsetY)

	if (type_ping ~= -1 and pct ~= -1) then
	    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, pingtag, type_ping, pct, api)
	else
	    pingerr("on_map_ping: Ping invalid type_ping=" .. tostring(type_ping) .. "; pct=" .. tostring(pct) .. "; api=" .. tostring(api))
	    pingerr("on_map_ping: offsets " .. tostring(offsetX) .. "," .. tostring(offsetY))
	end
    end
end

-- Called on map ping from LibMapPing
--
local function map_ping_finished(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    offsetX, offsetY = LMP:GetMapPing(pingType, pingtag) -- load from LMP, because offsetX, offsetY from PING_EVENT_REMOVED are 0,0

    if pingType == MAP_PIN_TYPE_PING and
	LMP:IsPositionOnMap(offsetX, offsetY) and
	valid_ping(offsetX, offsetY) then
	LMP:UnsuppressPing(pingType, pingtag)
    end
end

-- Called on new data from LibGroupSocket
--
local function rcv(pingTag, ultid, pct, apiver)
    local ult = POC_Ult.ByPing(ultid)

    if (ult == nil or pct == -1) then
	POC_Error("rcv: invalid ult: " .. tostring(ult) .. "; pct: " .. tostring(pct))
    end

    local player = {
	PingTag = pingTag,
	UltPct = pct,
	ApiVer = apiver
    }

    if true or apiver == POC_API_VERSION then
	player.UltGid = ult.Gid
	player.InvalidClient = false
    else
	player.UltGid = POC_Ult.MaxPing
	player.InvalidClient = true
    end

    -- d(playerName .. " " .. tostring(pct))

    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
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

    LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, type_ping, pct_ping)
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
