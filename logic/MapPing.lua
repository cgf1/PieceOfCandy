local REFRESHRATE = 2000 -- ms; RegisterForUpdate is in miliseconds

POC_MapPing = {
    Name = "POC-MapPing",
    IsMocked = false
}
POC_MapPing.__index = POC_MapPing


local ultix = GetUnitName("player")
local notify_when_not_grouped = false

-- Called on new data from LibGroupSocket
--
function POC_MapPing.OnData(pingTag, abilityPing, ultpct)
    local ult = POC_Ult.ByPing(abilityPing)

    if (ult ~= nil and ultpct ~= -1) then
	local player = {}
	local playerName = ""

	if (POC_MapPing.IsMocked == false) then
	    playerName = GetUnitName(pingTag)
	else
	    playerName = pingTag
	end

	player.PingTag = pingTag
	player.PlayerName = playerName
	player.UltGid = ult.Gid
	player.UltPct = ultpct
	-- d(playerName .. " " .. tostring(ultpct))

	CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
    else
	POC_Error("POC_MapPing.OnMapPing, Ping invalid ult: " .. tostring(ult) .. "; ultpct: " .. tostring(ultpct))
    end
end

-- Called on refresh of timer
--
function POC_MapPing.OnTimedUpdate(eventCode)
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
	POC_Communicator.SendData(myult)
    else
	POC_Error("POC_MapPing.OnTimedUpdate, ultimate is nil. StaticID: " .. tostring(myult))
    end
end

-- Initialize initializes POC_MapPing
--
function POC_MapPing.Initialize(isMocked)
    POC_MapPing.IsMocked = isMocked

    -- Register callbacks
    CALLBACK_MANAGER:RegisterCallback(POC_MAP_PING_CHANGED, POC_MapPing.OnData)

    -- Start timer
    EVENT_MANAGER:RegisterForUpdate(POC_MapPing.Name, REFRESHRATE, POC_MapPing.OnTimedUpdate)
end
