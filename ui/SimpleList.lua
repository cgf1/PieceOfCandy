--[[
	Local variables
]]--
local LOG_ACTIVE = false

local REFRESHRATE = 1000 -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 4 -- s; GetTimeStamp() is in seconds

local _logger = nil
local _control = nil
local _players = {}

--[[
	Table POC_SimpleList
]]--
POC_SimpleList = {}
POC_SimpleList.__index = POC_SimpleList

--[[
	Table Members
]]--
POC_SimpleList.IsMocked = false

--[[
	Sets visibility of labels
]]--
function POC_SimpleList.RefreshList()
	if (LOG_ACTIVE) then _logger:logTrace("POC_SimpleList.RefreshList") end

    for i=1, GROUP_SIZE_MAX, 1 do
        local row = POC_SimpleListControlContainerScrollChild:GetNamedChild("Row" .. i)
        local listPlayer = _players[i]

        if (listPlayer ~= nil) then
            local isPlayerNotGrouped = IsUnitGrouped(listPlayer.PingTag) == false

            if (POC_SimpleList.IsMocked) then
                isPlayerNotGrouped = false
            end

            local isPlayerTimedOut = (GetTimeStamp() - listPlayer.LastMapPingTimestamp) > TIMEOUT

            if (isPlayerNotGrouped or isPlayerTimedOut) then
                if (LOG_ACTIVE) then _logger:logDebug("Player invalid, hide row: " .. tostring(i)) end

                row:SetHidden(true)
                table.remove(_players, i)
            end
        else
            if (LOG_ACTIVE) then _logger:logDebug("Row empty, hide: " .. tostring(i)) end
            row:SetHidden(true)
        end
    end
	
	if (POC_SettingsHandler.SavedVariables.IsSortingActive) then
		-- Sort list with all players
		POC_SimpleList.SortList()
	end
end

--[[
	Sorts swimlane
]]--
function POC_SimpleList.SortList()
	if (LOG_ACTIVE) then _logger:logTrace("POC_SimpleList.SortList") end

    -- Comparer
    function compare(playerLeft, playerRight)
        if (playerLeft.RelativeUltimate == playerRight.RelativeUltimate) then
            return playerLeft.PingTag < playerRight.PingTag
        else
            return playerLeft.RelativeUltimate > playerRight.RelativeUltimate
        end
    end

    table.sort(_players, compare)

    -- Update sorted swimlane list
    for i,listPlayer in ipairs(_players) do
        POC_SimpleList.UpdateListRow(POC_SimpleListControlContainerScrollChild:GetNamedChild("Row" .. i), listPlayer)
    end
end

--[[
	Updates list row
]]--
function POC_SimpleList.UpdateListRow(row, player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.UpdateListRow")
    end

    local localizedUltimateName = zo_strformat(SI_ABILITY_TOOLTIP_NAME, player.UltimateName)
    local nameLength = string.len(localizedUltimateName)

    if (nameLength > 22) then
        localizedUltimateName = string.sub(localizedUltimateName, 0, 22) .. "..."
    end

    row:GetNamedChild("SenderNameValueLabel"):SetText(player.PlayerName)
	row:GetNamedChild("UltimateValueLabel"):SetText(localizedUltimateName)
	row:GetNamedChild("ReadyValueLabel"):SetText(player.RelativeUltimate)
			
	if (player.IsPlayerDead) then
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1.0, 0.0, 0.0, 1)
		row:GetNamedChild("UltimateValueLabel"):SetColor(1.0, 0.0, 0.0, 1)
		row:GetNamedChild("ReadyValueLabel"):SetColor(1.0, 0.0, 0.0, 1)
    elseif (player.RelativeUltimate == 100) then
		row:GetNamedChild("SenderNameValueLabel"):SetColor(0.0, 1.0, 0.0, 1)
		row:GetNamedChild("UltimateValueLabel"):SetColor(0.0, 1.0, 0.0, 1)
		row:GetNamedChild("ReadyValueLabel"):SetColor(0.0, 1.0, 0.0, 1)
	else
		row:GetNamedChild("SenderNameValueLabel"):SetColor(1.0, 1.0, 1.0, 1)
		row:GetNamedChild("UltimateValueLabel"):SetColor(1.0, 1.0, 1.0, 1)
		row:GetNamedChild("ReadyValueLabel"):SetColor(1.0, 1.0, 1.0, 1)
	end

    if (row:IsHidden()) then
		row:SetHidden(false)
	end
end

--[[
	Updates list row
]]--
function POC_SimpleList.UpdatePlayer(player)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.UpdatePlayer")
    end

	if (player) then
        local row = nil

        for i,listPlayer in ipairs(_players) do
            if (LOG_ACTIVE) then _logger:logDebug(listPlayer.PlayerName .. " == " .. player.PlayerName) end
		    if (listPlayer.PlayerName == player.PlayerName) then
                row = POC_SimpleListControlContainerScrollChild:GetNamedChild("Row" .. i)
            end
	    end

        -- Update timestamp
		if (row ~= nil) then
            for i,listPlayer in ipairs(_players) do
		        if (listPlayer.PlayerName == player.PlayerName) then
                    listPlayer.LastMapPingTimestamp = GetTimeStamp()
                    listPlayer.IsPlayerDead = player.IsPlayerDead
                    listPlayer.RelativeUltimate = player.RelativeUltimate
                    break
                end
	        end
        else
            -- Add new player
            local nextFreeRow = 1

            for i,player in ipairs(_players) do
		        nextFreeRow = nextFreeRow + 1
	        end

            if (nextFreeRow <= GROUP_SIZE_MAX) then
                if (LOG_ACTIVE) then 
                    _logger:logDebug("POC_SimpleList.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                end

                player.LastMapPingTimestamp = GetTimeStamp()
                _players[nextFreeRow] = player
                row = POC_SimpleListControlContainerScrollChild:GetNamedChild("Row" .. nextFreeRow)
            else
                if (LOG_ACTIVE) then _logger:logDebug("POC_SimpleList.UpdatePlayer, too much players for list" .. tostring(nextFreeRow)) end
            end
        end

        -- Only update if player in a row
        if (row ~= nil) then
            -- Directly update row with player, sorting will be triggered on RefreshList
			POC_SimpleList.UpdateListRow(row, player)
        end
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function POC_SimpleList.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets POC_SimpleList on settings position
]]--
function POC_SimpleList.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnSimpleListMoveStop saves current POC_SimpleList position to settings
]]--
function POC_SimpleList.OnSimpleListMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SimpleList.OnSimpleListMoveStop") end

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
function POC_SimpleList.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (POC_GroupHandler.IsGrouped) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function POC_SimpleList.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SimpleList.SetControlActive")
    end

    local isHidden = POC_SettingsHandler.IsSimpleListVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end
    
    POC_SimpleList.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
		-- Stop timeout timer
	    EVENT_MANAGER:UnregisterForUpdate(POC_SimpleList.Name)
		
        CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, POC_SimpleList.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, POC_SimpleList.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, POC_SimpleList.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_SimpleList.SetControlHidden)
    else
        POC_SimpleList.SetControlMovable(POC_SettingsHandler.SavedVariables.Movable)
        POC_SimpleList.RestorePosition(POC_SettingsHandler.SavedVariables.PosX, POC_SettingsHandler.SavedVariables.PosY)

		-- Start timeout timer
	    EVENT_MANAGER:RegisterForUpdate(POC_SimpleList.Name, REFRESHRATE, POC_SimpleList.RefreshList)
		
        CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, POC_SimpleList.RefreshList)
        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, POC_SimpleList.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, POC_SimpleList.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_SimpleList.SetControlHidden)
    end
end

--[[
	CreateSimpleListRows creates simple list rows
]]--
function POC_SimpleList.CreateSimpleListRows()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SimpleList.CreateSimpleListRows") end

	for i=1, GROUP_SIZE_MAX, 1 do
		local row = CreateControlFromVirtual("$(parent)Row", POC_SimpleListControlContainerScrollChild, "GroupUltimateSimpleListRow", i)
        if (LOG_ACTIVE) then _logger:logDebug("Row created " .. row:GetName()) end

		row:SetHidden(true) -- initial not visible
		
		if i == 1 then
            row:SetAnchor(TOPLEFT, POC_SimpleListControlContainerScrollChild, TOPLEFT, 0, 0)
        else
            row:SetAnchor(TOP, lastRow, BOTTOM, 0, 0)
        end
		
		lastRow = row
	end
end

--[[
	Initialize initializes POC_SimpleList
]]--
function POC_SimpleList.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_SimpleList.Initialize")
    end

    _logger = logger
    _control = POC_SimpleListControl
    
    POC_SimpleList.IsMocked = isMocked

    POC_SimpleList.CreateSimpleListRows()

    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, POC_SimpleList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, POC_SimpleList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, POC_SimpleList.SetControlActive)
end
