--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local ROWS = 24
local REFRESHRATE = 1000 -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 4 -- s; GetTimeStamp() is in seconds

local _logger = nil
local _control = nil

--[[
	Table CompactSwimlaneList
]]--
POC_CompactSwimlaneList = {}
POC_CompactSwimlaneList.__index = POC_CompactSwimlaneList

--[[
	Table Members
]]--
POC_CompactSwimlaneList.Name = "TGU-CompactSwimlaneList"
POC_CompactSwimlaneList.IsMocked = false
POC_CompactSwimlaneList.Swimlanes = {}

--[[
	Sets visibility of labels
]]--
function POC_CompactSwimlaneList.RefreshList()
	if (LOG_ACTIVE) then _logger:logTrace("POC_CompactSwimlaneList.RefreshList") end

    -- Check all swimlanes
    for i,swimlane in ipairs(POC_CompactSwimlaneList.Swimlanes) do
        POC_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlane)
	end
end

--[[
	Sorts swimlane
]]--
function POC_CompactSwimlaneList.SortSwimlane(swimlane)
	if (LOG_ACTIVE) then _logger:logTrace("POC_CompactSwimlaneList.SortSwimlane") end

    -- Comparer
    function compare(playerLeft, playerRight)
        if (playerLeft.RelativeUltimate == playerRight.RelativeUltimate) then
            return playerLeft.PingTag < playerRight.PingTag
        else
            return playerLeft.RelativeUltimate > playerRight.RelativeUltimate
        end
    end

    table.sort(swimlane.Players, compare)

    -- Sort by name

    -- Update sorted swimlane list
    for i,swimlanePlayer in ipairs(swimlane.Players) do
        POC_CompactSwimlaneList.UpdateListRow(swimlane.SwimlaneControl:GetNamedChild("Row" .. i), swimlanePlayer)
    end
end

--[[
	Updates list row
]]--
function POC_CompactSwimlaneList.UpdateListRow(row, player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.UpdateListRow")
    end

    local playerName = player.PlayerName
    local nameLength = string.len(playerName)

    if (nameLength > 6) then
        playerName = string.sub(playerName, 0, 5) .. ".."
    end

    row:GetNamedChild("SenderNameValueLabel"):SetText(playerName)
    row:GetNamedChild("RelativeUltimateStatusBar"):SetValue(player.RelativeUltimate)

	if (player.IsPlayerDead) then
        -- Dead Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, 0.8)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.8, 0.03, 0.03, 0.7)
    elseif (player.RelativeUltimate == 100) then
		-- Ready Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 1)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.03, 0.7, 0.03, 0.7)
	else
		-- Inprogress Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 0.8)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.03, 0.03, 0.7, 0.7)
	end

    row:SetHidden(false)
end

--[[
	Updates list row
]]--
function POC_CompactSwimlaneList.UpdatePlayer(player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.UpdatePlayer")
    end

	if (player) then
        local swimLane = POC_CompactSwimlaneList.GetSwimLane(player.UltimateGroup.GroupAbilityId)

        if (swimLane) then
            local row = POC_CompactSwimlaneList.GetSwimLaneRow(swimLane, player.PlayerName)

            -- Update timestamp
            if (row ~= nil) then
                for i,swimlanePlayer in ipairs(swimLane.Players) do
		            if (swimlanePlayer.PlayerName == player.PlayerName) then
                        swimlanePlayer.LastMapPingTimestamp = GetTimeStamp()
                        swimlanePlayer.IsPlayerDead = player.IsPlayerDead
                        swimlanePlayer.RelativeUltimate = player.RelativeUltimate
                        break
                    end
	            end
            else
                -- Add new player
                local nextFreeRow = 1

                for i,player in ipairs(swimLane.Players) do
		            nextFreeRow = nextFreeRow + 1
	            end

                if (nextFreeRow <= ROWS) then
                    if (LOG_ACTIVE) then 
                        _logger:logDebug("POC_CompactSwimlaneList.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                    end

                    player.LastMapPingTimestamp = GetTimeStamp()
                    swimLane.Players[nextFreeRow] = player
                    row = swimLane.SwimlaneControl:GetNamedChild("Row" .. nextFreeRow)
                else
                    if (LOG_ACTIVE) then _logger:logDebug("POC_CompactSwimlaneList.UpdatePlayer, too much players for one swimlane " .. tostring(nextFreeRow)) end
                end
            end
            
            -- Only update if player in a row
            if (row ~= nil) then
                if (POC_SettingsHandler.SavedVariables.IsSortingActive) then
                    -- Sort swimlane with all players
                    POC_CompactSwimlaneList.SortSwimlane(swimLane)
                else
                    -- Directly update row with player
                    POC_CompactSwimlaneList.UpdateListRow(row, player)
                end
            end
        else
            if (LOG_ACTIVE) then _logger:logDebug("POC_CompactSwimlaneList.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName)) end
        end
	end
end

--[[
	Get swimlane from current SwimLanes
]]--
function POC_CompactSwimlaneList.GetSwimLane(ultimateGroupId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.GetSwimLane")
        _logger:logDebug("ultimateGroupId", ultimateGroupId)
    end

    if (ultimateGroupId ~= 0) then
        for i,swimLane in ipairs(POC_CompactSwimlaneList.Swimlanes) do
		    if (swimLane.UltimateGroupId == ultimateGroupId) then
                return swimLane
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("POC_CompactSwimlaneList.GetSwimLane, swimLane not found " .. tostring(ultimateGroupId)) end
        return nil
    else
        _logger:logError("POC_CompactSwimlaneList.GetSwimLane, ultimateGroupId is 0")
        return nil
    end
end

--[[
	Get Player Row from current players in swimlane
]]--
function POC_CompactSwimlaneList.GetSwimLaneRow(swimLane, playerName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.GetSwimLaneRow")
        _logger:logDebug("swimLane ID", swimLane.Id)
    end

    if (swimLane) then
        for i,player in ipairs(swimLane.Players) do
            if (LOG_ACTIVE) then _logger:logDebug(player.PlayerName .. " == " .. playerName) end
		    if (player.PlayerName == playerName) then
                return swimLane.SwimlaneControl:GetNamedChild("Row" .. i)
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("POC_CompactSwimlaneList.GetSwimLane, player not found " .. tostring(playerName)) end
        return nil
    else
        _logger:logError("POC_CompactSwimlaneList.GetSwimLane, swimLane is nil")
        return nil
    end
end

--[[
	Clears all players in swimlane
]]--
function POC_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlane)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.ClearPlayersFromSwimlane")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    if (swimlane) then
        for i=1, ROWS, 1 do
            local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
            local swimlanePlayer = swimlane.Players[i]

            if (swimlanePlayer ~= nil) then
                local isPlayerNotGrouped = IsUnitGrouped(swimlanePlayer.PingTag) == false

                if (POC_CompactSwimlaneList.IsMocked) then
                    isPlayerNotGrouped = false
                end

                local isPlayerTimedOut = (GetTimeStamp() - swimlanePlayer.LastMapPingTimestamp) > TIMEOUT
                local isPlayerUltimateNotCorrect = swimlane.UltimateGroupId ~= swimlanePlayer.UltimateGroup.GroupAbilityId

                if (isPlayerNotGrouped or isPlayerTimedOut or isPlayerUltimateNotCorrect) then
                    if (LOG_ACTIVE) then _logger:logDebug("Player invalid, hide row: " .. tostring(i)) end

                    row:SetHidden(true)
                    table.remove(swimlane.Players, i)
                end
            else
                if (LOG_ACTIVE) then _logger:logDebug("Row empty, hide: " .. tostring(i)) end

                row:SetHidden(true)
            end
        end
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function POC_CompactSwimlaneList.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets POC_CompactSwimlaneList on settings position
]]--
function POC_CompactSwimlaneList.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnPOC_CompactSwimlaneListMoveStop saves current POC_CompactSwimlaneList position to settings
]]--
function POC_CompactSwimlaneList.OnCompactSwimlaneListMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("POC_CompactSwimlaneList.OnCompactSwimlaneListMoveStop") end

	local left = _control:GetLeft()
	local top = _control:GetTop()
	
    POC_SettingsHandler.SavedVariables.PosX = left
    POC_SettingsHandler.SavedVariables.PosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", POC_SettingsHandler.SavedVariables.PosX, POC_SettingsHandler.SavedVariables.PosY)
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function POC_CompactSwimlaneList.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (POC_GroupHandler.IsGrouped()) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function POC_CompactSwimlaneList.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.SetControlActive")
    end

    local isHidden = POC_SettingsHandler.IsCompactSwimlaneListVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end
    
    POC_CompactSwimlaneList.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
        -- Start timeout timer
	    EVENT_MANAGER:UnregisterForUpdate(POC_CompactSwimlaneList.Name)

        CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, POC_CompactSwimlaneList.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, POC_CompactSwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, POC_CompactSwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, POC_CompactSwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_CompactSwimlaneList.SetControlHidden)
    else
        POC_CompactSwimlaneList.SetControlMovable(POC_SettingsHandler.SavedVariables.Movable)
        POC_CompactSwimlaneList.RestorePosition(POC_SettingsHandler.SavedVariables.PosX, POC_SettingsHandler.SavedVariables.PosY)

        -- Start timeout timer
	    EVENT_MANAGER:RegisterForUpdate(POC_CompactSwimlaneList.Name, REFRESHRATE, POC_CompactSwimlaneList.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, POC_CompactSwimlaneList.RefreshList)
        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, POC_CompactSwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, POC_CompactSwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, POC_CompactSwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_CompactSwimlaneList.SetControlHidden)
    end
end

--[[
	OnSwimlaneHeaderClicked called on header clicked
]]--
function POC_CompactSwimlaneList.OnSwimlaneHeaderClicked(button, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.OnSwimlaneHeaderClicked")
        _logger:logDebug("swimlaneId", swimlaneId)
    end

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, POC_CompactSwimlaneList.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("POC_CompactSwimlaneList.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup called on header clicked
]]--
function POC_CompactSwimlaneList.OnSetUltimateGroup(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, POC_CompactSwimlaneList.OnSetUltimateGroup)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        POC_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlaneId, group)
    else
        _logger:logError("POC_UltimateGroupMenu.ShowUltimateGroupMenu, group nil or swimlaneId invalid")
    end
end

--[[
	SetSwimlaneUltimate sets the swimlane header icon in base of ultimateGroupId
]]--
function POC_CompactSwimlaneList.SetSwimlaneUltimate(swimlaneId, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CompactSwimlaneList.SetSwimlaneUltimate")
        _logger:logDebug("ultimateGroup.GroupName, swimlaneId", ultimateGroup.GroupName, swimlaneId)
    end

    local swimlaneObject = POC_CompactSwimlaneList.Swimlanes[swimlaneId]
    local iconControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")

    if (ultimateGroup ~= nil and iconControl ~= nil) then
        iconControl:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))

        swimlaneObject.UltimateGroupId = ultimateGroup.GroupAbilityId
        POC_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlaneObject)
    else
        _logger:logError("POC_CompactSwimlaneList.SetSwimlaneUltimateIcon, icon is " .. tostring(icon) .. ";" .. tostring(iconControl) .. ";" .. tostring(ultimateGroup))
    end
end

--[[
	CreateCompactSwimlaneListHeaders creates swimlane list headers
]]--
function POC_CompactSwimlaneList.CreateCompactSwimlaneListHeaders()
    if (LOG_ACTIVE) then _logger:logTrace("POC_CompactSwimlaneList.CreateCompactSwimlaneListHeaders") end

	for i=1, SWIMLANES, 1 do
        local ultimateGroupId = POC_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[i]
        local ultimateGroup = POC_UltimateGroupHandler.GetUltimateGroupByAbilityId(ultimateGroupId)

        local swimlaneControlName = "Swimlane" .. tostring(i)
        local swimlaneControl = _control:GetNamedChild(swimlaneControlName)
        
        -- Add button
        local button = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
        button:SetHandler("OnClicked", function() POC_CompactSwimlaneList.OnSwimlaneHeaderClicked(button, i) end)

        local swimLane = {}
        swimLane.Id = i
        swimLane.SwimlaneControl = swimlaneControl
        swimLane.Players = {}

        if (ultimateGroup ~= nil) then
            if (LOG_ACTIVE) then 
                _logger:logDebug("Create Swimlane", i)
                _logger:logDebug("ultimateGroup.GroupName", ultimateGroup.GroupName)
                _logger:logDebug("swimlaneControlName", swimlaneControlName)
            end

            local icon = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
            icon:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))

            swimLane.UltimateGroupId = ultimateGroup.GroupAbilityId
        else
            _logger:logError("POC_CompactSwimlaneList.CreateCompactSwimlaneListHeaders, ultimateGroup nil.")
        end

        POC_CompactSwimlaneList.CreateCompactSwimlaneListRows(swimlaneControl)
	    POC_CompactSwimlaneList.Swimlanes[i] = swimLane
	end
end

--[[
	CreateCompactSwimlaneListRows creates swimlane lsit rows
]]--
function POC_CompactSwimlaneList.CreateCompactSwimlaneListRows(swimlaneControl)
    if (LOG_ACTIVE) then _logger:logTrace("POC_CompactSwimlaneList.CreateCompactSwimlaneListRows") end

    if (swimlaneControl ~= nil) then
	    for i=1, ROWS, 1 do
		    local row = CreateControlFromVirtual("$(parent)Row", swimlaneControl, "CompactGroupUltimateSwimlaneRow", i)
            if (LOG_ACTIVE) then _logger:logDebug("Row created " .. row:GetName()) end

		    row:SetHidden(true) -- initial not visible

		    if (i == 1) then
                row:SetAnchor(TOPLEFT, swimlaneControl, TOPLEFT, 0, 50)
            elseif (i == 5) then -- Fix pixelbug, Why the hell ZOS?!
                row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, 0)
            else
				row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, -1)
			end

		    lastRow = row
	    end
    else
        _logger:logError("POC_CompactSwimlaneList.CreateCompactSwimlaneListRows, swimlaneControl nil.")
    end
end

--[[
	Initialize initializes POC_CompactSwimlaneList
]]--
function POC_CompactSwimlaneList.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_CompactSwimlaneList.Initialize")
    end

    _logger = logger
    _control = POC_CompactSwimlaneListControl

    POC_CompactSwimlaneList.IsMocked = isMocked

    POC_CompactSwimlaneList.CreateCompactSwimlaneListHeaders()

    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, POC_CompactSwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, POC_CompactSwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, POC_CompactSwimlaneList.SetControlActive)
end
