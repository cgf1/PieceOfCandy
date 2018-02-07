local LMP = LibStub("LibMapPing")
if not LMP then
    error("Cannot load without LibMapPing")
end

local _ultHandler = nil

local ABILITY_COEFFICIENT = 100
local ULTIMATE_COEFFICIENT = 1000

-- POC_Communicator table
--
POC_Communicator = {
  IsMocked = false,
  Name = "POC-Communicator"
}
POC_Communicator.__index = POC_Communicator

local xxx

-- Gets ult ID
--
local function get_ult_ping(offset)
    if (offset <= 0) then
	POC_Error("offset is incorrect: " .. tostring(offset))
	return -1
    end

    local ping = math.floor((offset * ABILITY_COEFFICIENT) + 0.5)
    local apiver = math.floor(ping / POC_Ult.MaxPing)
    ping = ping % POC_Ult.MaxPing
    if (ping >= 1 and ping < POC_Ult.MaxPing) then
	return ping, apiver
    else
	POC_Error("get_ult_ping: offset is incorrect: " .. tostring(ping) .. "; offset: " .. tostring(offset))
	return -1
    end
end

-- Gets ultimate percentage
--
local function get_ult_pct(offset)
    if (offset < 0) then
	POC_Error("get_ult_pct: offset is incorrect: " .. tostring(offset))
	return
    end
    local ultpct = math.floor((offset * ULTIMATE_COEFFICIENT) + 0.5)

    if (ultpct >= 0 and ultpct <= 125) then
	return ultpct
    else
	POC_Error("get_ult_pct: ultpct is incorrect: " .. tostring(ultpct) .. "; offset: " .. tostring(offset))
	return -1
    end
end

-- Called on map ping from LibMapPing
--
function POC_Communicator.OnMapPing(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    if (pingType == MAP_PIN_TYPE_PING and LMP:IsPositionOnMap(offsetX, offsetY) and
	POC_Communicator.IsPossiblePing(offsetX, offsetY)) then

	LMP:SuppressPing(pingType, pingtag)

	local ult_type_ping, api = get_ult_ping(offsetX)
	local ultpct = get_ult_pct(offsetY)

	if (ult_type_ping ~= -1 and ultpct ~= -1) then
	    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, pingtag, ult_type_ping, ultpct, api)
	else
	    POC_Error("OnMapPing: Ping invalid ult_type_ping=" .. tostring(ult_type_ping) .. "; ultpct=" .. tostring(ultpct) .. "; api=" .. tostring(api))
	    POC_Error("OnMapPing: offsets " .. tostring(offsetX) .. "," .. tostring(offsetY))
	end
    end
end

-- Called on map ping from LibMapPing
--
function POC_Communicator.OnMapPingFinished(pingType, pingtag, offsetX, offsetY, isLocalPlayerOwner)
    offsetX, offsetY = LMP:GetMapPing(pingType, pingtag) -- load from LMP, because offsetX, offsetY from PING_EVENT_REMOVED are 0,0

    if pingType == MAP_PIN_TYPE_PING and
	LMP:IsPositionOnMap(offsetX, offsetY) and
	POC_Communicator.IsPossiblePing(offsetX, offsetY) then
	LMP:UnsuppressPing(pingType, pingtag)
    end
end

-- Called on refresh of timer
--
function POC_Communicator.SendData(ult)
    if (ult == nil) then
	POC_Error("POC_Communicator.SendData, ult is nil.")
        return
    end
    local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local ultCost = math.max(1, GetAbilityCost(ult.Gid))

    -- Mocked
    if POC_Communicator.IsMocked then
	POC_Communicator.SendFakePings()
    else -- Standard communication
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
	local ult_type_ping = (ult.Ping + (POC_Ult.MaxPing * POC_API_VERSION)) / ABILITY_COEFFICIENT

	if (ultpct > 0) then
	    ult_pct_ping = ultpct / ULTIMATE_COEFFICIENT
	else
	    ult_pct_ping = 0.0001 -- Zero, if you send "0", the map ping will be invalid
	end

	LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, ult_type_ping, ult_pct_ping)
    end
end

--[[
	Check if map ping is in possible range
]]--
function POC_Communicator.IsPossiblePing(offsetX, offsetY)
    local isValidPing = (offsetX ~= 0 or offsetY ~= 0)
    local isCorrectOffsetX = (offsetX >= 0.009 and offsetX <= 2.69)
    local isCorrectOffsetY = (offsetY >= 0.000 and offsetY <= 0.60)

    return isValidPing and (isCorrectOffsetX and isCorrectOffsetY)
end

-- Sends fake pings for all group members
-- FIXME: This is currently broken
--
function POC_Communicator.SendFakePings()
    local ults = POC_Ult.GetUlts()

    -- Directly send to test only UI
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group1", ults[1].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group2", ults[1].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group3", ults[1].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group4", ults[1].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group5", ults[1].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group6", ults[6].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group7", ults[6].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group8", ults[6].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group9", ults[6].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group10", ults[6].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group11", ults[1].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group12", ults[6].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group13", ults[16].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group14", ults[16].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group15", ults[16].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group16", ults[16].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group17", ults[16].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group18", ults[16].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group19", ults[13].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group20", ults[13].Ping, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group21", ults[13].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group22", ults[13].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group23", ults[13].Ping, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group24", ults[13].Ping, math.random(90, 100))
end

--[[
	Updates communication type
]]--
function POC_Communicator.UpdateCommunicationType()
    -- Unregister events
    LMP:UnregisterCallback("BeforePingAdded", POC_Communicator.OnMapPing)
    LMP:UnregisterCallback("AfterPingRemoved", POC_Communicator.OnMapPingFinished)

    -- Register events
    LMP:RegisterCallback("BeforePingAdded", POC_Communicator.OnMapPing)
    LMP:RegisterCallback("AfterPingRemoved", POC_Communicator.OnMapPingFinished)
end

--[[
	Initialize initializes POC_Communicator
]]--
function POC_Communicator.Initialize(isMocked)
    xxx = POC.xxx
    POC_Communicator.IsMocked = isMocked

    POC_Communicator.UpdateCommunicationType()
end
