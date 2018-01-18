--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local REFRESHRATE = 1000 -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 4 -- s; GetTimeStamp() is in seconds

local _logger = nil
local _control = nil
local play_sound = true

--[[
	Table TGU_SwimlaneList
]]--
TGU_SwimlaneList = {}
TGU_SwimlaneList.__index = TGU_SwimlaneList

--[[
	Table Members
]]--
TGU_SwimlaneList.Name = "TGU-SwimlaneList"
TGU_SwimlaneList.IsMocked = false
TGU_SwimlaneList.Swimlanes = {}
TGU_SwimlaneList.WasActive = false

--[[
	Sets visibility of labels
]]--
function TGU_SwimlaneList.RefreshList()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SwimlaneList.RefreshList") end

    if (not TGU_GroupHandler.IsGrouped()) then
        if (TGU_SwimlaneList.WasActive) then
            d("POC: No longer grouped")
            TGU_SwimlaneList.SetControlActive()
            TGU_SwimlaneList.WasActive = false
            -- d("SetControlActive: set WasActive = false")
        end
    else
        -- Check all swimlanes
        local displayed = false
        for i,swimlane in ipairs(TGU_SwimlaneList.Swimlanes) do
            if TGU_SwimlaneList.ClearPlayersFromSwimlane(swimlane) then
                displayed = true
            end
        end
        if (not (displayed and TGU_SwimlaneList.WasActive)) then
            -- d({"displayed", displayed})
            -- d({"WasActive", TGU_SwimlaneList.WasActive})
            TGU_SwimlaneList.SetControlActive()
            if (not TGU_SwimlaneList.WasActive) then
                d("POC: now grouped")
            end
            TGU_SwimlaneList.WasActive = true
        end
    end
end

--[[
	Sorts swimlane
]]--
function TGU_SwimlaneList.SortSwimlane(swimlane)
	if (LOG_ACTIVE) then _logger:logTrace("TGU_SwimlaneList.SortSwimlane") end

    function sortval(x)
        local a
        if (x.IsPlayerDead) then
            a = 0
        else
            a = x.RelativeUltimate
        end
        return a
    end
    -- Comparer
    function compare(playerLeft, playerRight)
        a = sortval(playerLeft)
        b = sortval(playerRight)
        -- d("A " .. a)
        -- d("B " .. b)
        if (a == b) then
            return playerLeft.PingTag < playerRight.PingTag
        else
            return a > b
       end
    end

    table.sort(swimlane.Players, compare)


    -- d("MAX " .. TGU_SettingsHandler.SavedVariables.SwimlaneMax)
    -- Update sorted swimlane list
    local me = GetGroupUnitTagByIndex(GetGroupIndexByUnitTag("player"))

    for i,swimlanePlayer in ipairs(swimlane.Players) do
        if (swimlanePlayer.RelativeUltimate  >= 100) then
            if (swimlanePlayer.IsPlayerDead) then
                swimlanePlayer.RelativeUltimate = 100
            else
                swimlanePlayer.RelativeUltimate = 100 + TGU_SettingsHandler.SavedVariables.SwimlaneMax - i
            end
        end
        if (swimlanePlayer.PingTag ~= me) then
            -- nothing to do
        elseif (not TGU_SettingsHandler.SavedVariables.UltNumberShow or
                (swimlanePlayer.RelativeUltimate < 100) or
                CurrentHudHiddenState() or
                swimlanePlayer.IsPlayerDead or
                not TGU_GroupHandler.IsGrouped() or
                not TGU_SettingsHandler.IsSwimlaneListVisible()) then
            TGU_UltNumber:SetHidden(true)
            play_sound = swimlanePlayer.RelativeUltimate < 100
        else
            TGU_UltNumberLabel:SetText("|c00ff00 #" .. i .. "|r")
            TGU_UltNumber:SetHidden(false)
            if (i ~= 1) then
                play_sound = true
            elseif (play_sound and TGU_SettingsHandler.SavedVariables.WereNumberOne) then
                PlaySound(SOUNDS.DUEL_START)
                play_sound = false
            end
        end
        TGU_SwimlaneList.UpdateListRow(swimlane.SwimlaneControl:GetNamedChild("Row" .. i), swimlanePlayer)
    end
end

--[[
	Updates list row
]]--
function TGU_SwimlaneList.UpdateListRow(row, player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.UpdateListRow")
    end

    local playerName = player.PlayerName
    local nameLength = string.len(playerName)

    if (nameLength > 12) then
        playerName = string.sub(playerName, 0, 12) .. '..'
    end

    if (not player.IsPlayerDead and IsUnitInCombat(player.PingTag)) then
        playerName = "|cFF0000" .. playerName .. "|r"
    end

    row:GetNamedChild("SenderNameValueLabel"):SetText(playerName)
    row:GetNamedChild("RelativeUltimateStatusBar"):SetValue(player.RelativeUltimate)

    if (player.IsPlayerDead) then
        -- Dead Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, 0.8)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.8, 0.03, 0.03, 0.7)
    elseif (player.RelativeUltimate >= 100) then
		-- Ready Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 1)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.03, 0.7, 0.03, 1)
    else
		-- Inprogress Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 0.8)
        row:GetNamedChild("RelativeUltimateStatusBar"):SetColor(0.03, 0.03, 0.7, 0.7)
    end

    if (row:IsHidden()) then
        row:SetHidden(false)
    end
end

--[[
	Updates list player
]]--
function TGU_SwimlaneList.UpdatePlayer(player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.UpdatePlayer")
    end

    if (player) then
        local swimLane = TGU_SwimlaneList.GetSwimLane(player.UltimateGroup.GroupAbilityId)

        if (swimLane) then
            local row = TGU_SwimlaneList.GetSwimLaneRow(swimLane, player.PlayerName)

            -- Update player
            if (row ~= nil) then
                for i,swimlanePlayer in ipairs(swimLane.Players) do
                        if (swimlanePlayer.PlayerName == player.PlayerName) then
                            swimlanePlayer.LastMapPingTimestamp = GetTimeStamp()
                            swimlanePlayer.IsPlayerDead = player.IsPlayerDead
                            if (player.PlayerName == "Sirech") then
                                player.RelativeUltimate = 60
                            end
                            if (player.RelativeUltimate < 100 or swimlanePlayer.RelativeUltimate < 100) then
                                swimlanePlayer.RelativeUltimate = player.RelativeUltimate
                            end
                            break
                        end
                end
            else
                -- Add new player
                local nextFreeRow = 1

                for i,player in ipairs(swimLane.Players) do
		            nextFreeRow = nextFreeRow + 1
	            end

                if (nextFreeRow <= TGU_SettingsHandler.SavedVariables.SwimlaneMax) then
                    if (LOG_ACTIVE) then 
                        _logger:logDebug("TGU_SwimlaneList.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                    end

                    player.LastMapPingTimestamp = GetTimeStamp()
                    swimLane.Players[nextFreeRow] = player
                    row = swimLane.SwimlaneControl:GetNamedChild("Row" .. nextFreeRow)
                else
                    if (LOG_ACTIVE) then _logger:logDebug("TGU_SwimlaneList.UpdatePlayer, too much players for one swimlane " .. tostring(nextFreeRow)) end
                end
            end

            -- Only update if player in a row
            if (row ~= nil) then
                TGU_SwimlaneList.SortSwimlane(swimLane)
            end
        else
            if (LOG_ACTIVE) then _logger:logDebug("TGU_SwimlaneList.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName)) end
        end
    end
end

--[[
	Get swimlane from current SwimLanes
]]--
function TGU_SwimlaneList.GetSwimLane(ultimateGroupId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.GetSwimLane")
        _logger:logDebug("ultimateGroupId", ultimateGroupId)
    end

    if (ultimateGroupId ~= 0) then
        for i,swimLane in ipairs(TGU_SwimlaneList.Swimlanes) do
		    if (swimLane.UltimateGroupId == ultimateGroupId) then
                return swimLane
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("TGU_SwimlaneList.GetSwimLane, swimLane not found " .. tostring(ultimateGroupId)) end
        return nil
    else
        _logger:logError("TGU_SwimlaneList.GetSwimLane, ultimateGroupId is 0")
        return nil
    end
end

--[[
	Get Player Row from current players in swimlane
]]--
function TGU_SwimlaneList.GetSwimLaneRow(swimLane, playerName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.GetSwimLaneRow")
        _logger:logDebug("swimLane ID", swimLane.Id)
    end

    if (swimLane) then
        for i,player in ipairs(swimLane.Players) do
            if (LOG_ACTIVE) then _logger:logDebug(player.PlayerName .. " == " .. playerName) end
		    if (player.PlayerName == playerName) then
                return swimLane.SwimlaneControl:GetNamedChild("Row" .. i)
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("TGU_SwimlaneList.GetSwimLane, player not found " .. tostring(playerName)) end
        return nil
    else
        _logger:logError("TGU_SwimlaneList.GetSwimLane, swimLane is nil")
        return nil
    end
end

--[[
	Clears all players in swimlane
]]--
function TGU_SwimlaneList.ClearPlayersFromSwimlane(swimlane)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.ClearPlayersFromSwimlane")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    local updated = false
    if (swimlane) then
        for i=1, TGU_SettingsHandler.SavedVariables.SwimlaneMax, 1 do
            local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
            local swimlanePlayer = swimlane.Players[i]

            if (swimlanePlayer ~= nil) then
                updated = true
                local isPlayerNotGrouped = IsUnitGrouped(swimlanePlayer.PingTag) == false

                if (TGU_SwimlaneList.IsMocked) then
                    isPlayerNotGrouped = false
                end

                local isPlayerTimedOut = (GetTimeStamp() - swimlanePlayer.LastMapPingTimestamp) > TIMEOUT
                local isPlayerUltimateNotCorrect = swimlane.UltimateGroupId ~= swimlanePlayer.UltimateGroup.GroupAbilityId

                if (isPlayerNotGrouped or isPlayerTimedOut or isPlayerUltimateNotCorrect) then
                    if (LOG_ACTIVE) then _logger:logDebug("Player invalid, hide row: " .. tostring(i)) end

                    table.remove(swimlane.Players, i)
                    row:SetHidden(true)
                end
            else
                if (LOG_ACTIVE) then _logger:logDebug("Row empty, hide: " .. tostring(i)) end
                row:SetHidden(true)
            end
        end
    end
    return updated
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function TGU_SwimlaneList.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
    _control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets TGU_SwimlaneList on settings position
]]--
function TGU_SwimlaneList.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnSwimlaneListMoveStop saves current TGU_SwimlaneList position to settings
]]--
function TGU_SwimlaneList.OnSwimlaneListMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SwimlaneList.OnSwimlaneListMoveStop") end

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
function TGU_SwimlaneList.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (TGU_GroupHandler.IsGrouped()) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function TGU_SwimlaneList.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.SetControlActive")
    end

    local isVisible = TGU_SettingsHandler.IsSwimlaneListVisible() and TGU_GroupHandler.IsGrouped()
    if (LOG_ACTIVE) then _logger:logDebug("isVisible", isHidden) end
    
    local isHidden = not isVisible or CurrentHudHiddenState()
    TGU_SwimlaneList.SetControlHidden(isHidden)
    TGU_UltNumber:SetHidden(isHidden)
    TGU_UltimateSelectorControl:SetHidden(isHidden)

    if (isVisible) then
        TGU_SwimlaneList.SetControlMovable(TGU_SettingsHandler.SavedVariables.Movable)
        TGU_SwimlaneList.RestorePosition(TGU_SettingsHandler.SavedVariables.PosX, TGU_SettingsHandler.SavedVariables.PosY)

        EVENT_MANAGER:RegisterForUpdate(TGU_SwimlaneList.Name, REFRESHRATE, TGU_SwimlaneList.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(TGU_PLAYER_DATA_CHANGED, TGU_SwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(TGU_MOVABLE_CHANGED, TGU_SwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, TGU_SwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_SwimlaneList.SetControlHidden)
    else
        -- Stop timeout timer
        EVENT_MANAGER:UnregisterForUpdate(TGU_SwimlaneList.Name)

        -- CALLBACK_MANAGER:UnregisterCallback(TGU_GROUP_CHANGED, TGU_SwimlaneList.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(TGU_PLAYER_DATA_CHANGED, TGU_SwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(TGU_MOVABLE_CHANGED, TGU_SwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, TGU_SwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_SwimlaneList.SetControlHidden)
    end
end

--[[
	OnSwimlaneHeaderClicked called on header clicked
]]--
function TGU_SwimlaneList.OnSwimlaneHeaderClicked(button, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.OnSwimlaneHeaderClicked")
        _logger:logDebug("swimlaneId", swimlaneId)
    end

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_SwimlaneList.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(TGU_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("TGU_SwimlaneList.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup called on header clicked
]]--
function TGU_SwimlaneList.OnSetUltimateGroup(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_SwimlaneList.OnSetUltimateGroup)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        TGU_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlaneId, group)
    else
        _logger:logError("TGU_UltimateGroupMenu.ShowUltimateGroupMenu, group nil or swimlaneId invalid")
    end
end

--[[
	SetSwimlaneUltimate sets the swimlane header icon in base of ultimateGroupId
]]--
function TGU_SwimlaneList.SetSwimlaneUltimate(swimlaneId, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SwimlaneList.SetSwimlaneUltimate")
        _logger:logDebug("ultimateGroup.GroupName, swimlaneId", ultimateGroup.GroupName, swimlaneId)
    end

    local swimlaneObject = TGU_SwimlaneList.Swimlanes[swimlaneId]
    local iconControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
    local labelControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("UltimateLabel")

    if (ultimateGroup ~= nil and iconControl ~= nil and labelControl ~= nil) then
        iconControl:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))
        labelControl:SetText(ultimateGroup.GroupName)

        swimlaneObject.UltimateGroupId = ultimateGroup.GroupAbilityId
        TGU_SwimlaneList.ClearPlayersFromSwimlane(swimlaneObject)
    else
        _logger:logError("TGU_SwimlaneList.SetSwimlaneUltimateIcon, icon is " .. tostring(icon) .. ";" .. tostring(iconControl) .. ";" .. tostring(ultimateGroup))
    end
end

--[[
	CreateSwimLaneListHeaders creates swimlane list headers
]]--
function TGU_SwimlaneList.CreateSwimLaneListHeaders()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SwimlaneList.CreateSwimLaneListHeaders") end

	for i=1, SWIMLANES, 1 do
        local ultimateGroupId = TGU_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[i]
        local ultimateGroup = TGU_UltimateGroupHandler.GetUltimateGroupByAbilityId(ultimateGroupId)

        local swimlaneControlName = "Swimlane" .. tostring(i)
        local swimlaneControl = _control:GetNamedChild(swimlaneControlName)

        -- Add button
        local button = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
        button:SetHandler("OnClicked", function() TGU_SwimlaneList.OnSwimlaneHeaderClicked(button, i) end)
        
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

            local label = swimlaneControl:GetNamedChild("Header"):GetNamedChild("UltimateLabel")
            label:SetText(ultimateGroup.GroupName)

            swimLane.UltimateGroupId = ultimateGroup.GroupAbilityId
        else
            _logger:logError("TGU_SwimlaneList.CreateSwimLaneListHeaders, ultimateGroup nil.")
        end

        TGU_SwimlaneList.CreateSwimlaneListRows(swimlaneControl)
        TGU_SwimlaneList.Swimlanes[i] = swimLane
	end
end

--[[
	CreateSwimlaneListRows creates swimlane list rows
]]--
function TGU_SwimlaneList.CreateSwimlaneListRows(swimlaneControl)
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SwimlaneList.CreateSwimlaneListRows") end

    if (swimlaneControl ~= nil) then
	    for i=1, TGU_SettingsHandler.SavedVariables.SwimlaneMax, 1 do
		    local row = CreateControlFromVirtual("$(parent)Row", swimlaneControl, "GroupUltimateSwimlaneRow", i)
                if (LOG_ACTIVE) then _logger:logDebug("Row created " .. row:GetName()) end

                        row:SetHidden(true) -- initial not visible

                        if (i == 1) then
                            row:SetAnchor(TOPLEFT, swimlaneControl, TOPLEFT, 0, 25)
                        elseif (i == 5) then -- Fix pixelbug, Why the hell ZOS?!
                            row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, 0)
                        else
                            row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, -1)
                        end
                        lastRow = row
                end
        else
            _logger:logError("TGU_SwimlaneList.CreateSwimlaneListRows, swimlaneControl nil.")
    end
end

--[[
	Initialize initializes TGU_SwimlaneList
]]--
function TGU_SwimlaneList.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_SwimlaneList.Initialize")
    end

    _logger = logger
    _control = TGU_SwimlaneListControl

    TGU_SwimlaneList.IsMocked = isMocked

    TGU_SwimlaneList.CreateSwimLaneListHeaders()

    TGU_UltNumber:ClearAnchors()
    TGU_UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
                            TGU_SettingsHandler.SavedVariables.UltNumberPos[1],
                            TGU_SettingsHandler.SavedVariables.UltNumberPos[2])
    TGU_UltNumber:SetMovable(true)
    TGU_UltNumber:SetMouseEnabled(true)
    TGU_UltNumber:SetHidden(not TGU_SettingsHandler.SavedVariables.UltNumber)


    CALLBACK_MANAGER:RegisterCallback(TGU_GROUP_CHANGED, TGU_SwimlaneList.RefreshList)
    CALLBACK_MANAGER:RegisterCallback(TGU_STYLE_CHANGED, TGU_SwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(TGU_IS_ZONE_CHANGED, TGU_SwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(TGU_UNIT_GROUPED_CHANGED, TGU_SwimlaneList.SetControlActive)
end

function TGU_SwimlaneList.savePosNumber(self)
    TGU_SettingsHandler.SavedVariables.UltNumberPos = {self:GetLeft(),self:GetTop()}
end
