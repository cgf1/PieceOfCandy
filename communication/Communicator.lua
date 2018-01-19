--[[
	Local variables
]]--
local LOG_ACTIVE = false

local LMP = LibStub("LibMapPing")
if(not LMP) then
	error("Cannot load without LibMapPing")
end

local _logger = nil
local _ultimateHandler = nil

local ABILITY_COEFFICIENT = 100
local ULTIMATE_COEFFICIENT = 1000

--[[
	Table POC_Communicator
]]--
POC_Communicator = {}
POC_Communicator.__index = POC_Communicator

--[[
	Table Members
]]--
POC_Communicator.Name = "POC-Communicator"
POC_Communicator.IsMocked = false
POC_Communicator.IsLgsActive = false

--[[
	Called on data from LGS
]]--
function POC_Communicator.OnUltimateReceived(unitTag, ultimateCurrent, ultimateCost, ultimateGroupId, isSelf)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Communicator.OnUltimateReceived")
        _logger:logDebug("unitTag; ultimateCurrent; ultimateCost; ultimateGroupId", unitTag, ultimateCurrent, ultimateCost, ultimateGroupId)
    end

	local relativeUltimate = math.floor((ultimateCurrent / ultimateCost) * 100)

	if (relativeUltimate > 100) then
		relativeUltimate = 100
	end

    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, unitTag, ultimateGroupId, relativeUltimate)
end

--[[
	Called on map ping from LibMapPing
]]--
function POC_Communicator.OnMapPing(pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Communicator.OnMapPing")
        --_logger:logDebug("pingTag; offsetX; offsetY", pingTag, offsetX, offsetY)
    end

	if (pingType == MAP_PIN_TYPE_PING and
        LMP:IsPositionOnMap(offsetX, offsetY) and
		POC_Communicator.IsPossiblePing(offsetX, offsetY)) then
        
        if (LOG_ACTIVE) then
            _logger:logDebug("SuppressPing ->", pingType, pingTag)
        end

        LMP:SuppressPing(pingType, pingTag)

        local abilityPing = POC_Communicator.GetAbilityPing(offsetX)
		local relativeUltimate = POC_Communicator.GetRelativeUltimate(offsetY)

        if (LOG_ACTIVE) then
            _logger:logDebug("pingTag; abilityPing; relativeUltimate", pingTag, abilityPing, relativeUltimate)
        end

        if (abilityPing ~= -1 and relativeUltimate ~= -1) then
            CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, pingTag, abilityPing, relativeUltimate)
        else
            _logger:logError("POC_Communicator.OnMapPing, Ping invalid abilityPing: " .. tostring(abilityPing) .. "; relativeUltimate: " .. tostring(relativeUltimate))
        end
    end
end

--[[
	Called on map ping from LibMapPing
]]--
function POC_Communicator.OnMapPingFinished(pingType, pingTag, offsetX, offsetY, isLocalPlayerOwner)
    offsetX, offsetY = LMP:GetMapPing(pingType, pingTag) -- load from LMP, because offsetX, offsetY from PING_EVENT_REMOVED are 0,0
	
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Communicator.OnMapPingFinished")
		--_logger:logDebug("pingType; pingTag; offsetX; offsetY", pingType, pingTag, offsetX, offsetY)
    end
	
    if (pingType == MAP_PIN_TYPE_PING and
        LMP:IsPositionOnMap(offsetX, offsetY) and
		POC_Communicator.IsPossiblePing(offsetX, offsetY)) then

        if (LOG_ACTIVE) then
            _logger:logDebug("UnsuppressPing ->", pingType, pingTag)
        end

        LMP:UnsuppressPing(pingType, pingTag)
    end
end

--[[
	Called on refresh of timer
]]--
function POC_Communicator.SendData(abilityGroup)
    if (LOG_ACTIVE) then 
		_logger:logTrace("POC_Communicator.SendData")
		--_logger:logDebug("abilityGroup", abilityGroup)
	end

    if (abilityGroup ~= nil) then
        local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
        local abilityCost = math.max(1, GetAbilityCost(abilityGroup.GroupAbilityId))

        -- Mocked
        if (POC_Communicator.IsMocked) then
            POC_Communicator.SendFakePings()
        -- LGS communication
        elseif (POC_Communicator.IsLgsActive) then
            if (_ultimateHandler ~= nil) then
                _ultimateHandler:SetUltimateCost(abilityCost)
                _ultimateHandler:SetUltimateGroupId(abilityGroup.GroupAbilityPing)
				_ultimateHandler:Refresh()
            else
                _logger:logError("POC_Communicator.SendData, _ultimateHandler is nil")
            end
        -- Standard communication
        else
            local relativeUltimate = math.floor((current / abilityCost) * 100)

	        if (relativeUltimate > 100) then
		        relativeUltimate = 100
	        end

	        local abilityPing = abilityGroup.GroupAbilityPing / ABILITY_COEFFICIENT
            local ultimatePing = 0.0001 -- Zero, if you send "0", the map ping will be invalid

            if (relativeUltimate > 0) then
	            ultimatePing = relativeUltimate / ULTIMATE_COEFFICIENT
            end

            if (LOG_ACTIVE) then 
		        --_logger:logDebug("abilityGroup.GroupName", abilityGroup.GroupName)
                --_logger:logDebug("relativeUltimate", relativeUltimate)
                --_logger:logDebug("abilityPing", abilityPing)
                --_logger:logDebug("ultimatePing", ultimatePing)
            end

            LMP:SetMapPing(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, abilityPing, ultimatePing)
        end
    else
        _logger:logError("POC_Communicator.SendData, abilityGroup is nil.")
    end
end

--[[
	Check if map ping is in possible range
]]--
function POC_Communicator.IsPossiblePing(offsetX, offsetY)
    if (LOG_ACTIVE) then 
        --_logger:logTrace("POC_Communicator.IsPossiblePing")
        --_logger:logDebug("offsetX; offsetY", offsetX, offsetY)
    end

	local isValidPing = (offsetX ~= 0 or offsetY ~= 0)
	local isCorrectOffsetX = (offsetX >= 0.009 and offsetX <= 0.30)
	local isCorrectOffsetY = (offsetY >= 0.000 and offsetY <= 0.11)

    if (LOG_ACTIVE) then 
        --_logger:logDebug("isValidPing; isCorrectOffsetX; isCorrectOffsetY", isValidPing, isCorrectOffsetX, isCorrectOffsetY)
    end

	return isValidPing and (isCorrectOffsetX and isCorrectOffsetY)
end

--[[
	Gets ability ID
]]--
function POC_Communicator.GetAbilityPing(offset)
    if (LOG_ACTIVE) then 
        --_logger:logTrace("POC_Communicator.GetAbilityPing")
        --_logger:logDebug("offset", offset)
    end

    if (offset > 0) then
        local abilityPing = math.floor((offset * ABILITY_COEFFICIENT) + 0.5)
        if (abilityPing >= 1 and abilityPing <= 29) then
            return abilityPing
        else
            _logger:logError("offset is incorrect: " .. tostring(abilityPing) .. "; offset: " .. tostring(offset))
            return -1
        end
    else
        _logger:logError("offset is incorrect: " .. tostring(offset))
        return -1
    end
end

--[[
	Gets relative ultimate
]]--
function POC_Communicator.GetRelativeUltimate(offset)
    if (LOG_ACTIVE) then 
        --_logger:logTrace("POC_Communicator.GetRelativeUltimate")
        --_logger:logDebug("offset", offset)
    end

    if (offset >= 0) then
        local relativeUltimate = math.floor((offset * ULTIMATE_COEFFICIENT) + 0.5)
        if (relativeUltimate >= 0 and relativeUltimate <= 100) then
            return relativeUltimate
        elseif (relativeUltimate >= 100 and relativeUltimate <= 110) then
            if (LOG_ACTIVE) then _logger:logDebug("offset; relativeUltimate", offset, relativeUltimate) end
            return 100
        else
            _logger:logError("relativeUltimate is incorrect: " .. tostring(relativeUltimate) .. "; offset: " .. tostring(offset))
            return -1
        end
    else
        _logger:logError("offset is incorrect: " .. tostring(offset))
        return -1
    end
end

--[[
	Sends fake pings for all group members
]]--
function POC_Communicator.SendFakePings()
    if (LOG_ACTIVE) then  _logger:logTrace("POC_Communicator.SendFakePings") end

    local ultimateGroups = POC_UltimateGroupHandler.GetUltimateGroups()

    -- Directly send to test only UI
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group1", ultimateGroups[1].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group2", ultimateGroups[1].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group3", ultimateGroups[1].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group4", ultimateGroups[1].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group5", ultimateGroups[1].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group6", ultimateGroups[6].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group7", ultimateGroups[6].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group8", ultimateGroups[6].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group9", ultimateGroups[6].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group10", ultimateGroups[6].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group11", ultimateGroups[1].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group12", ultimateGroups[6].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group13", ultimateGroups[16].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group14", ultimateGroups[16].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group15", ultimateGroups[16].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group16", ultimateGroups[16].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group17", ultimateGroups[16].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group18", ultimateGroups[16].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group19", ultimateGroups[13].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group20", ultimateGroups[13].GroupAbilityPing, 100)
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group21", ultimateGroups[13].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group22", ultimateGroups[13].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group23", ultimateGroups[13].GroupAbilityPing, math.random(90, 100))
    CALLBACK_MANAGER:FireCallbacks(POC_MAP_PING_CHANGED, "group24", ultimateGroups[13].GroupAbilityPing, math.random(90, 100))
end

--[[
	Updates communication type
]]--
function POC_Communicator.UpdateCommunicationType()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Communicator.UpdateCommunicationType")
    end

    -- Unregister events
    LMP:UnregisterCallback("BeforePingAdded", POC_Communicator.OnMapPing)
    LMP:UnregisterCallback("AfterPingRemoved", POC_Communicator.OnMapPingFinished)

    if (POC_Communicator.IsLgsActive) then
        local LGS = LibStub:GetLibrary("LibGroupSocket")

        if (LGS ~= nil) then
            if (_ultimateHandler == nil) then
                _ultimateHandler = LGS:GetHandler(LGS.MESSAGE_TYPE_ULTIMATE)
            end

            _ultimateHandler:RegisterForUltimateChanges(POC_Communicator.OnUltimateReceived)
            _ultimateHandler:Refresh()
        else
            _logger:logError("LGS not found. Please install LibGroupSocket. Activate default communication as fallback.")
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
function POC_Communicator.Initialize(logger, isLgsActive, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_Communicator.Initialize")
        logger:logDebug("isLgsActive", isLgsActive)
        logger:logDebug("isMocked", isMocked)
    end

    _logger = logger

    POC_Communicator.IsMocked = isMocked

    POC_Communicator.IsLgsActive = isLgsActive
    POC_Communicator.UpdateCommunicationType()
end
