--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

--[[
	Table POC_MapPingHandler
]]--
POC_MapPingHandler = {}
POC_MapPingHandler.__index = POC_MapPingHandler

--[[
	Table Members
]]--
POC_MapPingHandler.Name = "POC-MapPingHandler"
POC_MapPingHandler.IsMocked = false

local ultix = GetUnitName("player")

--[[
	Called on new data from LibGroupSocket
]]--
function POC_MapPingHandler.OnData(pingTag, abilityPing, ultpct)
    if (LOG_ACTIVE) then _logger:logTrace("POC_MapPingHandler.OnData") end

    local ultimateGroup = POC_Ult.GetUltByAbilityPing(abilityPing)

    if (ultimateGroup ~= nil and ultpct ~= -1) then
        local player = {}
        local playerName = ""
        local isPlayerDead = false

        if (POC_MapPingHandler.IsMocked == false) then
            playerName = GetUnitName(pingTag)
            isPlayerDead = IsUnitDead(pingTag)
        else
            playerName = pingTag
            isPlayerDead = math.random() > 0.8
        end

        player.PingTag = pingTag
        player.PlayerName = playerName
        player.IsPlayerDead = isPlayerDead
        player.Ult = ultimateGroup
        player.UltimateName = GetAbilityName(ultimateGroup.GroupAbilityId)
        player.UltimateIcon = GetAbilityIcon(ultimateGroup.GroupAbilityId)
        player.UltPct = ultpct
        -- d(playerName .. " " .. tostring(ultpct))

        if (LOG_ACTIVE) then 
            _logger:logDebug("player.PingTag", player.PingTag)
            _logger:logDebug("player.PlayerName", player.PlayerName)
            _logger:logDebug("player.IsPlayerDead", player.IsPlayerDead)
            _logger:logDebug("player.Ult.GroupName", player.Ult.GroupName)
            _logger:logDebug("player.UltPct", player.UltPct)
        end

        CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
    else
        _logger:logError("POC_MapPingHandler.OnMapPing, Ping invalid ultimateGroup: " .. tostring(ultimateGroup) .. "; ultpct: " .. tostring(ultpct))
    end
end

--[[
	Called on refresh of timer
]]--
function POC_MapPingHandler.OnTimedUpdate(eventCode)
    if (LOG_ACTIVE) then _logger:logTrace("POC_MapPingHandler.OnTimedUpdate") end

    if (not IsUnitGrouped("player") and not POC_MapPingHandler.IsMocked) then
        return
    end -- only if player is in group and system is not mocked

    local abilityGroup = POC_Ult.GetUltByAbilityId(POC_Settings.SavedVariables.MyUltId[ultix])

    if (abilityGroup ~= nil) then
        POC_Communicator.SendData(abilityGroup)
    else
        _logger:logError("POC_MapPingHandler.OnTimedUpdate, abilityGroup is nil, change ultimate. StaticID: " .. tostring(abilityGroup))
    end
end

--[[
	Initialize initializes POC_MapPingHandler
]]--
function POC_MapPingHandler.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_MapPingHandler.Initialize")
        logger:logDebug("isMocked", isMocked)
    end

    _logger = logger

    POC_MapPingHandler.IsMocked = isMocked

    -- Register callbacks
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, POC_MapPingHandler.OnData)

    -- Start timer
    EVENT_MANAGER:RegisterForUpdate(POC_MapPingHandler.Name, REFRESHRATE, POC_MapPingHandler.OnTimedUpdate)
end
