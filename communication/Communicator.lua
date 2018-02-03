--[[
	Local variables
]]--
local LOG_ACTIVE = false

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
  IsLgsActive = false,
  IsMocked = false,
  Name = "POC-Communicator"
}
POC_Communicator.__index = POC_Communicator

-- Called on data from LGS
--
function POC_Communicator.OnUltRcv(unitTag, ultCurrent, ultCost, ultId, isSelf)
    local ultpct = math.floor((ultCurrent / ultCost) * 100)

    if (ultpct > 124) then
	ultpct = 124
    end

    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, unitTag, ultId, ultpct)
end

-- Called on map ping from LibMapPing
--
function POC_Communicator.OnMapPing(pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
    if (pingType == MAP_PIN_TYPE_PING and LMP:IsPositionOnMap(offsetX, offsetY) and
	POC_Communicator.IsPossiblePing(offsetX, offsetY)) then

	LMP:SuppressPing(pingType, pingTag)

	local abilityPing = POC_Communicator.GetAbilityPing(offsetX)
	local ultpct = POC_Communicator.GetUltPct(offsetY)

	if (abilityPing ~= -1 and ultpct ~= -1) then
	    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, pingTag, abilityPing, ultpct)
	else
	    POC_Error("POC_Communicator.OnMapPing, Ping invalid abilityPing: " .. tostring(abilityPing) .. "; ultpct: " .. tostring(ultpct))
	end
    end
end

--[[
	Called on map ping from LibMapPing
]]--
function POC_Communicator.OnMapPingFinished(pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
    offsetX, offsetY = LMP:GetMapPing(pingType, pingTag) -- load from LMP, because offsetX, offsetY from PING_EVENT_REMOVED are 0,0

    if pingType == MAP_PIN_TYPE_PING and
       LMP:IsPositionOnMap(offsetX, offsetY) and
       POC_Communicator.IsPossiblePing(offsetX, offsetY) then
	LMP:UnsuppressPing(pingType, pingTag)
    end
end

--[[
	Called on refresh of timer
]]--
function POC_Communicator.SendData(abilityGroup)
    if (abilityGroup ~= nil) then
	local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
	local abilityCost = math.max(1, GetAbilityCost(abilityGroup.Gid))

	-- Mocked
	if POC_Communicator.IsMocked then
	    POC_Communicator.SendFakePings()
	-- LGS communication
	elseif (POC_Communicator.IsLgsActive) then
	    if (_ultHandler ~= nil) then
		_ultHandler:SetUltCost(abilityCost)
		_ultHandler:SetUltId(abilityGroup.Ping)
				_ultHandler:Refresh()
	    else
		POC_Error("POC_Communicator.SendData, _ultHandler is nil")
	    end
	-- Standard communication
	else
	    local ultpct = math.floor((current / abilityCost) * 100)

	    -- d("UltPct " .. tostring(POC_Swimlanes.UltPct))
	    if (ultpct < 100) then
		-- nothing to do
	    elseif (POC_Swimlanes.UltPct ~= nil) then
		ultpct = POC_Swimlanes.UltPct
	    else
		ultpct = 100
	    end

	    local abilityPing = abilityGroup.Ping / ABILITY_COEFFICIENT

	    if (ultpct > 0) then
		ultPing = ultpct / ULTIMATE_COEFFICIENT
	    else
		ultPing = 0.0001 -- Zero, if you send "0", the map ping will be invalid
	    end

	    LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, abilityPing, ultPing)
	end
    else
	POC_Error("POC_Communicator.SendData, abilityGroup is nil.")
    end
end

--[[
	Check if map ping is in possible range
]]--
function POC_Communicator.IsPossiblePing(offsetX, offsetY)
    local isValidPing = (offsetX ~= 0 or offsetY ~= 0)
    local isCorrectOffsetX = (offsetX >= 0.009 and offsetX <= 0.30)
    local isCorrectOffsetY = (offsetY >= 0.000 and offsetY <= 0.60)

    return isValidPing and (isCorrectOffsetX and isCorrectOffsetY)
end

--[[
	Gets ability ID
]]--
function POC_Communicator.GetAbilityPing(offset)
    if (offset > 0) then
	local abilityPing = math.floor((offset * ABILITY_COEFFICIENT) + 0.5)
	if (abilityPing >= 1 and abilityPing <= 29) then
	    return abilityPing
	else
	    POC_Error("offset is incorrect: " .. tostring(abilityPing) .. "; offset: " .. tostring(offset))
	    return -1
	end
    else
	POC_Error("offset is incorrect: " .. tostring(offset))
	return -1
    end
end

-- Gets ultimate percentage
--
function POC_Communicator.GetUltPct(offset)
    if (offset >= 0) then
	local ultpct = math.floor((offset * ULTIMATE_COEFFICIENT) + 0.5)

	if (ultpct >= 0 and ultpct <= 125) then
	    return ultpct
	else
	    POC_Error("ultpct is incorrect: " .. tostring(ultpct) .. "; offset: " .. tostring(offset))
	    return -1
	end
    else
	POC_Error("offset is incorrect: " .. tostring(offset))
	return -1
    end
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

    if (POC_Communicator.IsLgsActive) then
	local LGS = LibStub:GetLibrary("LibGroupSocket")

	if (LGS ~= nil) then
	    if (_ultHandler == nil) then
		_ultHandler = LGS:GetHandler(LGS.MESSAGE_TYPE_ULTIMATE)
	    end

	    _ultHandler:RegisterForUltChanges(POC_Communicator.OnUltRcv)
	    _ultHandler:Refresh()
	else
	    POC_Error("LGS not found. Please install LibGroupSocket. Activate default communication as fallback.")
	    POC_Communicator.SetIsLgsActive(false)
	end
    else
	-- Register events
	LMP:RegisterCallback("BeforePingAdded", POC_Communicator.OnMapPing)
	LMP:RegisterCallback("AfterPingRemoved", POC_Communicator.OnMapPingFinished)
    end
end

--[[
	Initialize initializes POC_Communicator
]]--
function POC_Communicator.Initialize(isLgsActive, isMocked)
    POC_Communicator.IsMocked = isMocked

    POC_Communicator.IsLgsActive = isLgsActive
    POC_Communicator.UpdateCommunicationType()
end
