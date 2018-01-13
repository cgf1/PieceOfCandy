--[[
	Addon: Taos Group Ultimate
	Author: TProg Taonnor
	Created by @Taonnor
]]--

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
TGU_CompactSwimlaneList = {}
TGU_CompactSwimlaneList.__index = TGU_CompactSwimlaneList

--[[
	Table Members
]]--
TGU_CompactSwimlaneList.Name = "TGU-CompactSwimlaneList"
TGU_CompactSwimlaneList.IsMocked = false
TGU_CompactSwimlaneList.Swimlanes = {}

--[[
	Sets visibility of labels
]]--
function TGU_CompactSwimlaneList.RefreshList()
	if (LOG_ACTIVE) then _logger:logTrace("TGU_CompactSwimlaneList.RefreshList") end

    -- Check all swimlanes
    for i,swimlane in ipairs(TGU_CompactSwimlaneList.Swimlanes) do
        TGU_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlane)
	end
end

--[[
	Sorts swimlane
]]--
function TGU_CompactSwimlaneList.SortSwimlane(swimlane)
	if (LOG_ACTIVE) then _logger:logTrace("TGU_CompactSwimlaneList.SortSwimlane") end

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
        TGU_CompactSwimlaneList.UpdateListRow(swimlane.SwimlaneControl:GetNamedChild("Row" .. i), swimlanePlayer)
    end
end

--[[
	Updates list row
]]--
function TGU_CompactSwimlaneList.UpdateListRow(row, player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.UpdateListRow")
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
function TGU_CompactSwimlaneList.UpdatePlayer(player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.UpdatePlayer")
    end

	if (player) then
        local swimLane = TGU_CompactSwimlaneList.GetSwimLane(player.UltimateGroup.GroupAbilityId)

        if (swimLane) then
            local row = TGU_CompactSwimlaneList.GetSwimLaneRow(swimLane, player.PlayerName)

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
                        _logger:logDebug("TGU_CompactSwimlaneList.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                    end

                    player.LastMapPingTimestamp = GetTimeStamp()
                    swimLane.Players[nextFreeRow] = player
                    row = swimLane.SwimlaneControl:GetNamedChild("Row" .. nextFreeRow)
                else
                    if (LOG_ACTIVE) then _logger:logDebug("TGU_CompactSwimlaneList.UpdatePlayer, too much players for one swimlane " .. tostring(nextFreeRow)) end
                end
            end
            
            -- Only update if player in a row
            if (row ~= nil) then
                if (TGU_SettingsHandler.SavedVariables.IsSortingActive) then
                    -- Sort swimlane with all players
                    TGU_CompactSwimlaneList.SortSwimlane(swimLane)
                else
                    -- Directly update row with player
                    TGU_CompactSwimlaneList.UpdateListRow(row, player)
                end
            end
        else
            if (LOG_ACTIVE) then _logger:logDebug("TGU_CompactSwimlaneList.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName)) end
        end
	end
end

--[[
	Get swimlane from current SwimLanes
]]--
function TGU_CompactSwimlaneList.GetSwimLane(ultimateGroupId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.GetSwimLane")
        _logger:logDebug("ultimateGroupId", ultimateGroupId)
    end

    if (ultimateGroupId ~= 0) then
        for i,swimLane in ipairs(TGU_CompactSwimlaneList.Swimlanes) do
		    if (swimLane.UltimateGroupId == ultimateGroupId) then
                return swimLane
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("TGU_CompactSwimlaneList.GetSwimLane, swimLane not found " .. tostring(ultimateGroupId)) end
        return nil
    else
        _logger:logError("TGU_CompactSwimlaneList.GetSwimLane, ultimateGroupId is 0")
        return nil
    end
end

--[[
	Get Player Row from current players in swimlane
]]--
function TGU_CompactSwimlaneList.GetSwimLaneRow(swimLane, playerName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.GetSwimLaneRow")
        _logger:logDebug("swimLane ID", swimLane.Id)
    end

    if (swimLane) then
        for i,player in ipairs(swimLane.Players) do
            if (LOG_ACTIVE) then _logger:logDebug(player.PlayerName .. " == " .. playerName) end
		    if (player.PlayerName == playerName) then
                return swimLane.SwimlaneControl:GetNamedChild("Row" .. i)
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("TGU_CompactSwimlaneList.GetSwimLane, player not found " .. tostring(playerName)) end
        return nil
    else
        _logger:logError("TGU_CompactSwimlaneList.GetSwimLane, swimLane is nil")
        return nil
    end
end

--[[
	Clears all players in swimlane
]]--
function TGU_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlane)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.ClearPlayersFromSwimlane")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    if (swimlane) then
        for i=1, ROWS, 1 do
            local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
            local swimlanePlayer = swimlane.Players[i]

            if (swimlanePlayer ~= nil) then
                local isPlayerNotGrouped = IsUnitGrouped(swimlanePlayer.PingTag) == false

                if (TGU_CompactSwimlaneList.IsMocked) then
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
function TGU_CompactSwimlaneList.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets TGU_CompactSwimlaneList on settings position
]]--
function TGU_CompactSwimlaneList.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnTGU_CompactSwimlaneListMoveStop saves current TGU_CompactSwimlaneList position to settings
]]--
function TGU_CompactSwimlaneList.OnCompactSwimlaneListMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_CompactSwimlaneList.OnCompactSwimlaneListMoveStop") end

	local left = _control:GetLeft()
	local top = _control:GetTop()
	
    TGU_SettingsHandler.SavedVariables.PosX = left
    TGU_SettingsHandler.SavedVariables.PosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", TGU_SettingsHandler.SavedVariables.PosX, TGU_SettingsHandler.SavedVariables.PosY)
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function TGU_CompactSwimlaneList.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (TGU_GroupHandler.IsGrouped) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function TGU_CompactSwimlaneList.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.SetControlActive")
    end

    local isHidden = TGU_SettingsHandler.IsCompactSwimlaneListVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end
    
    TGU_CompactSwimlaneList.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
        -- Start timeout timer
	    EVENT_MANAGER:UnregisterForUpdate(TGU_CompactSwimlaneList.Name)

        CALLBACK_MANAGER:UnregisterCallback(TGU_GROUP_CHANGED, TGU_CompactSwimlaneList.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(TGU_PLAYER_DATA_CHANGED, TGU_CompactSwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(TGU_MOVABLE_CHANGED, TGU_CompactSwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, TGU_CompactSwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_CompactSwimlaneList.SetControlHidden)
    else
        TGU_CompactSwimlaneList.SetControlMovable(TGU_SettingsHandler.SavedVariables.Movable)
        TGU_CompactSwimlaneList.RestorePosition(TGU_SettingsHandler.SavedVariables.PosX, TGU_SettingsHandler.SavedVariables.PosY)

        -- Start timeout timer
	    EVENT_MANAGER:RegisterForUpdate(TGU_CompactSwimlaneList.Name, REFRESHRATE, TGU_CompactSwimlaneList.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(TGU_GROUP_CHANGED, TGU_CompactSwimlaneList.RefreshList)
        CALLBACK_MANAGER:RegisterCallback(TGU_PLAYER_DATA_CHANGED, TGU_CompactSwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(TGU_MOVABLE_CHANGED, TGU_CompactSwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, TGU_CompactSwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_CompactSwimlaneList.SetControlHidden)
    end
end

--[[
	OnSwimlaneHeaderClicked called on header clicked
]]--
function TGU_CompactSwimlaneList.OnSwimlaneHeaderClicked(button, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.OnSwimlaneHeaderClicked")
        _logger:logDebug("swimlaneId", swimlaneId)
    end

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_CompactSwimlaneList.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(TGU_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("TGU_CompactSwimlaneList.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup called on header clicked
]]--
function TGU_CompactSwimlaneList.OnSetUltimateGroup(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_CompactSwimlaneList.OnSetUltimateGroup)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        TGU_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlaneId, group)
    else
        _logger:logError("TGU_UltimateGroupMenu.ShowUltimateGroupMenu, group nil or swimlaneId invalid")
    end
end

--[[
	SetSwimlaneUltimate sets the swimlane header icon in base of ultimateGroupId
]]--
function TGU_CompactSwimlaneList.SetSwimlaneUltimate(swimlaneId, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CompactSwimlaneList.SetSwimlaneUltimate")
        _logger:logDebug("ultimateGroup.GroupName, swimlaneId", ultimateGroup.GroupName, swimlaneId)
    end

    local swimlaneObject = TGU_CompactSwimlaneList.Swimlanes[swimlaneId]
    local iconControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")

    if (ultimateGroup ~= nil and iconControl ~= nil) then
        iconControl:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))

        swimlaneObject.UltimateGroupId = ultimateGroup.GroupAbilityId
        TGU_CompactSwimlaneList.ClearPlayersFromSwimlane(swimlaneObject)
    else
        _logger:logError("TGU_CompactSwimlaneList.SetSwimlaneUltimateIcon, icon is " .. tostring(icon) .. ";" .. tostring(iconControl) .. ";" .. tostring(ultimateGroup))
    end
end

--[[
	CreateCompactSwimlaneListHeaders creates swimlane list headers
]]--
function TGU_CompactSwimlaneList.CreateCompactSwimlaneListHeaders()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_CompactSwimlaneList.CreateCompactSwimlaneListHeaders") end

	for i=1, SWIMLANES, 1 do
        local ultimateGroupId = TGU_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[i]
        local ultimateGroup = TGU_UltimateGroupHandler.GetUltimateGroupByAbilityId(ultimateGroupId)

        local swimlaneControlName = "Swimlane" .. tostring(i)
        local swimlaneControl = _control:GetNamedChild(swimlaneControlName)
        
        -- Add button
        local button = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
        button:SetHandler("OnClicked", function() TGU_CompactSwimlaneList.OnSwimlaneHeaderClicked(button, i) end)

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
            _logger:logError("TGU_CompactSwimlaneList.CreateCompactSwimlaneListHeaders, ultimateGroup nil.")
        end

        TGU_CompactSwimlaneList.CreateCompactSwimlaneListRows(swimlaneControl)
	    TGU_CompactSwimlaneList.Swimlanes[i] = swimLane
	end
end

--[[
	CreateCompactSwimlaneListRows creates swimlane lsit rows
]]--
function TGU_CompactSwimlaneList.CreateCompactSwimlaneListRows(swimlaneControl)
    if (LOG_ACTIVE) then _logger:logTrace("TGU_CompactSwimlaneList.CreateCompactSwimlaneListRows") end

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
        _logger:logError("TGU_CompactSwimlaneList.CreateCompactSwimlaneListRows, swimlaneControl nil.")
    end
end

--[[
	Initialize initializes TGU_CompactSwimlaneList
]]--
function TGU_CompactSwimlaneList.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_CompactSwimlaneList.Initialize")
    end

    _logger = logger
    _control = TGU_CompactSwimlaneListControl

    TGU_CompactSwimlaneList.IsMocked = isMocked

    TGU_CompactSwimlaneList.CreateCompactSwimlaneListHeaders()

    CALLBACK_MANAGER:RegisterCallback(TGU_STYLE_CHANGED, TGU_CompactSwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(TGU_IS_ZONE_CHANGED, TGU_CompactSwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(TGU_UNIT_GROUPED_CHANGED, TGU_CompactSwimlaneList.SetControlActive)
end
