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
local notify_when_not_grouped = false

--[[
	Called on new data from LibGroupSocket
]]--
function POC_MapPingHandler.OnData(pingTag, abilityPing, ultpct)
    local ult = POC_Ult.ByPing(abilityPing)

    if (ult ~= nil and ultpct ~= -1) then
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
        player.Ult = ult
        player.UltimateName = GetAbilityName(ult.Gid)
        player.UltimateIcon = GetAbilityIcon(ult.Gid)
        player.UltPct = ultpct
        -- d(playerName .. " " .. tostring(ultpct))

        CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
    else
        POC_Error("POC_MapPingHandler.OnMapPing, Ping invalid ult: " .. tostring(ult) .. "; ultpct: " .. tostring(ultpct))
    end
end

-- Called on refresh of timer
--
function POC_MapPingHandler.OnTimedUpdate(eventCode)
    if not IsUnitGrouped("player") and not POC_MapPingHandler.IsMocked then
        if notify_when_not_grouped then
            notify_when_not_grouped = false
            CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_GROUP_CHANGED, "left")
        end
        return
    end

    -- only if player is in group and system is not mocked
    notify_when_not_grouped = true

    local abilityGroup = POC_Ult.ById(POC_Settings.SavedVariables.MyUltId[ultix])

    if (abilityGroup ~= nil) then
        POC_Communicator.SendData(abilityGroup)
    else
        POC_Error("POC_MapPingHandler.OnTimedUpdate, abilityGroup is nil, change ultimate. StaticID: " .. tostring(abilityGroup))
    end
end

--[[
	Initialize initializes POC_MapPingHandler
]]--
function POC_MapPingHandler.Initialize(isMocked)
    POC_MapPingHandler.IsMocked = isMocked

    -- Register callbacks
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, POC_MapPingHandler.OnData)

    -- Start timer
    EVENT_MANAGER:RegisterForUpdate(POC_MapPingHandler.Name, REFRESHRATE, POC_MapPingHandler.OnTimedUpdate)
end
