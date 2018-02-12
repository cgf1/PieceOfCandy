local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end

local _ultHandler = nil

local ABILITY_COEFFICIENT = 100
local ULTIMATE_COEFFICIENT = 1000

-- ping table
--
local ping = {
  Name = "ping"
}
ping.__index = ping

local xxx
local pingerr = function() end
local show_errors = false

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
    local ultpct = math.floor((offset * ULTIMATE_COEFFICIENT) + 0.5)

    if (ultpct >= 0 and ultpct <= 125) then
	return ultpct
    else
	pingerr("get_ult_pct: ultpct is incorrect: " .. tostring(ultpct) .. "; offset: " .. tostring(offset))
	return -1
    end
end

-- Called on map ping from LibMapPing
--
function ping.OnMapPing(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    if (pingType == MAP_PIN_TYPE_PING and LMP:IsPositionOnMap(offsetX, offsetY) and
	ping.IsPossiblePing(offsetX, offsetY)) then

	LMP:SuppressPing(pingType, pingtag)

	local type_ping, api = get_ult_ping(offsetX)
	local ultpct = get_ult_pct(offsetY)

	if (type_ping ~= -1 and ultpct ~= -1) then
	    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, pingtag, type_ping, ultpct, api)
	else
	    pingerr("OnMapPing: Ping invalid type_ping=" .. tostring(type_ping) .. "; ultpct=" .. tostring(ultpct) .. "; api=" .. tostring(api))
	    pingerr("OnMapPing: offsets " .. tostring(offsetX) .. "," .. tostring(offsetY))
	end
    end
end

-- Called on map ping from LibMapPing
--
function ping.OnMapPingFinished(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    offsetX, offsetY = LMP:GetMapPing(pingType, pingtag) -- load from LMP, because offsetX, offsetY from PING_EVENT_REMOVED are 0,0

    if pingType == MAP_PIN_TYPE_PING and
	LMP:IsPositionOnMap(offsetX, offsetY) and
	ping.IsPossiblePing(offsetX, offsetY) then
	LMP:UnsuppressPing(pingType, pingtag)
    end
end

-- Called on refresh of timer
--
function ping.SendData(ult)
    if (ult == nil) then
	pingerr("ping.SendData, ult is nil.")
	return
    end
    local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local ultCost = math.max(1, GetAbilityCost(ult.Gid))

    local ultpct = math.floor((current / ultCost) * 100)

    -- d("UltPct " .. tostring(POC_Swimlanes.UltPct))
    if (ultpct < 100) then
	-- nothing to do
    elseif (POC_Swimlanes.UltPct ~= nil) then
	ultpct = POC_Swimlanes.UltPct
    else
	ultpct = 100
    end

    -- Ultimate type + our API #
    local type_ping = (ult.Ping + (POC_Ult.MaxPing * POC_API_VERSION)) / ABILITY_COEFFICIENT

    if (ultpct > 0) then
	pct_ping = ultpct / ULTIMATE_COEFFICIENT
    else
	pct_ping = 0.0001 -- Zero, if you send "0", the map ping will be invalid
    end

    LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, type_ping, pct_ping)
end

-- Check if map ping is in possible range
--
function ping.IsPossiblePing(offsetX, offsetY)
    local isValidPing = (offsetX ~= 0 or offsetY ~= 0)
    local isCorrectOffsetX = (offsetX >= 0.009 and offsetX <= 2.69)
    local isCorrectOffsetY = (offsetY >= 0.000 and offsetY <= 0.60)

    return isValidPing and (isCorrectOffsetX and isCorrectOffsetY)
end

local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

POC_MapPing = {
    Name = "POC-MapPing",
    active = false
}
POC_MapPing.__index = POC_MapPing

local ultix = GetUnitName("player")
local notify_when_not_grouped = false

-- Called on new data from LibGroupSocket
--
local function rcv(pingTag, ultid, ultpct, apiver)
    local ult = POC_Ult.ByPing(ultid)

    if (ult ~= nil and ultpct ~= -1) then
	local player = {
	    PingTag = pingTag,
	    UltPct = ultpct,
	    ApiVer = apiver
	}

	if true or apiver == POC_API_VERSION then
	    player.UltGid = ult.Gid
	    player.InvalidClient = false
	else
	    player.UltGid = POC_Ult.MaxPing
	    player.InvalidClient = true
	end

	-- d(playerName .. " " .. tostring(ultpct))

	CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
    else
	POC_Error("POC_MapPing.OnMapPing, Ping invalid ult: " .. tostring(ult) .. "; ultpct: " .. tostring(ultpct))
    end
end

-- Called on refresh of timer
--
function POC_MapPing.Send(_)
    if not IsUnitGrouped("player") and not POC_MapPing.IsMocked then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_GROUP_CHANGED, "left")
	end
	return
    end

    -- only if player is in group and system is not mocked
    notify_when_not_grouped = true

    local myult = POC_Ult.ById(POC_Settings.SavedVariables.MyUltId[ultix])

    if (myult ~= nil) then
	ping.SendData(myult)
    else
	POC_Error("POC_MapPing.OnTimedUpdate, ultimate is nil. StaticID: " .. tostring(myult))
    end
end

-- Unload MapPing handling
--
function POC_MapPing.Unload()
    POC_MapPing.active = false
    CALLBACK_MANAGER:UnregisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:UnregisterCallback("BeforePingAdded", ping.OnMapPing)
    LMP:UnregisterCallback("AfterPingRemoved", ping.OnMapPingFinished)
end

-- Initialize initializes POC_MapPing
--
function POC_MapPing.Load()
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, rcv)
    LMP:RegisterCallback("BeforePingAdded", ping.OnMapPing)
    LMP:RegisterCallback("AfterPingRemoved", ping.OnMapPingFinished)

    POC_MapPing.active = true
    xxx = POC.xxx
end

SLASH_COMMANDS["/pocpingerr"] = function()
    show_errors = not show_errors
    if show_errors then
	pingerr = POC_Error
    else
	pingerr = function() return end
    end
    d("show_errors " .. tostring(show_errors))
end
