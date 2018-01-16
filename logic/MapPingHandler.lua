--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

--[[
	Table TGU_MapPingHandler
]]--
TGU_MapPingHandler = {}
TGU_MapPingHandler.__index = TGU_MapPingHandler

--[[
	Table Members
]]--
TGU_MapPingHandler.Name = "TGU-MapPingHandler"
TGU_MapPingHandler.IsMocked = false

--[[
	Called on new data from LibGroupSocket
]]--
function TGU_MapPingHandler.OnData(pingTag, abilityPing, relativeUltimate)
    if (LOG_ACTIVE) then _logger:logTrace("TGU_MapPingHandler.OnData") end

    local ultimateGroup = TGU_UltimateGroupHandler.GetUltimateGroupByAbilityPing(abilityPing)

    if (ultimateGroup ~= nil and relativeUltimate ~= -1) then
        local player = {}
        local playerName = ""
        local isPlayerDead = false

        if (TGU_MapPingHandler.IsMocked == false) then
            playerName = GetUnitName(pingTag)
            isPlayerDead = IsUnitDead(pingTag)
        else
            playerName = pingTag
            isPlayerDead = math.random() > 0.8
        end

        player.PingTag = pingTag
        player.PlayerName = playerName
        player.IsPlayerDead = isPlayerDead
        player.UltimateGroup = ultimateGroup
        player.UltimateName = GetAbilityName(ultimateGroup.GroupAbilityId)
        player.UltimateIcon = GetAbilityIcon(ultimateGroup.GroupAbilityId)
        player.RelativeUltimate = relativeUltimate

        if (LOG_ACTIVE) then 
            _logger:logDebug("player.PingTag", player.PingTag)
            _logger:logDebug("player.PlayerName", player.PlayerName)
            _logger:logDebug("player.IsPlayerDead", player.IsPlayerDead)
            _logger:logDebug("player.UltimateGroup.GroupName", player.UltimateGroup.GroupName)
            _logger:logDebug("player.RelativeUltimate", player.RelativeUltimate)
        end

        CALLBACK_MANAGER:FireCallbacks(TGU_PLAYER_DATA_CHANGED, player)
    else
        _logger:logError("TGU_MapPingHandler.OnMapPing, Ping invalid ultimateGroup: " .. tostring(ultimateGroup) .. "; relativeUltimate: " .. tostring(relativeUltimate))
    end
end

--[[
	Called on refresh of timer
]]--
function TGU_MapPingHandler.OnTimedUpdate(eventCode)
    if (LOG_ACTIVE) then _logger:logTrace("TGU_MapPingHandler.OnTimedUpdate") end

	if (IsUnitGrouped("player") == false and TGU_MapPingHandler.IsMocked == false) then return end -- only if player is in group and system is not mocked

    local abilityGroup = TGU_UltimateGroupHandler.GetUltimateGroupByAbilityId(TGU_SettingsHandler.SavedVariables.StaticUltimateID)

    if (abilityGroup ~= nil) then
	    TGU_Communicator.SendData(abilityGroup)
    else
        _logger:logError("TGU_MapPingHandler.OnTimedUpdate, abilityGroup is nil, change ultimate. StaticID: " .. tostring(TGU_SettingsHandler.SavedVariables.StaticUltimateID))
    end
end

--[[
	Initialize initializes TGU_MapPingHandler
]]--
function TGU_MapPingHandler.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_MapPingHandler.Initialize")
        logger:logDebug("isMocked", isMocked)
    end

    _logger = logger

    TGU_MapPingHandler.IsMocked = isMocked

    -- Register callbacks
    CALLBACK_MANAGER:RegisterCallback(TGU_MAP_PING_CHANGED, TGU_MapPingHandler.OnData)

    -- Start timer
    EVENT_MANAGER:RegisterForUpdate(TGU_MapPingHandler.Name, REFRESHRATE, TGU_MapPingHandler.OnTimedUpdate)
end
