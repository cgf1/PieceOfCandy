--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local REFRESHRATE = 1000 -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 4 -- s; GetTimeStamp() is in seconds

local _logger = nil
local _control = nil
local play_sound = false
local curstyle = ""
local registered = false
local namelen = 12
local topleft = 25
local style_swimlanes = {}
local swimlanerow

local SWIMLANEULTMAX = 24

--[[
	Table POC_SwimlaneList
]]--
POC_SwimlaneList = {}
POC_SwimlaneList.__index = POC_SwimlaneList

--[[
	Table Members
]]--
POC_SwimlaneList.Name = "POC-SwimlaneList"
POC_SwimlaneList.IsMocked = false
POC_SwimlaneList.Swimlanes = {}
POC_SwimlaneList.WasActive = false

--[[
	Sets visibility of labels
]]--
function POC_SwimlaneList.RefreshList()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SwimlaneList.RefreshList") end

    if (not POC_GroupHandler.IsGrouped()) then
        if (POC_SwimlaneList.WasActive) then
            d("POC: No longer grouped")
            POC_SwimlaneList.SetControlActive()
            POC_SwimlaneList.WasActive = false
            -- d("SetControlActive: set WasActive = false")
        end
    else
        -- Check all swimlanes
        local displayed = false
        for i,swimlane in ipairs(POC_SwimlaneList.Swimlanes) do
            if POC_SwimlaneList.ClearPlayersFromSwimlane(swimlane) then
                displayed = true
            end
        end
        if (not (displayed and POC_SwimlaneList.WasActive)) then
            -- d({"displayed", displayed})
            -- d({"WasActive", POC_SwimlaneList.WasActive})
            POC_SwimlaneList.SetControlActive()
            if (not POC_SwimlaneList.WasActive) then
                d("POC: now grouped")
            end
            POC_SwimlaneList.WasActive = true
        end
    end
end

--[[
	Sorts swimlane
]]--
function POC_SwimlaneList.SortSwimlane(swimlane)
	if (LOG_ACTIVE) then _logger:logTrace("POC_SwimlaneList.SortSwimlane") end

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


    -- d("MAX " .. POC_SettingsHandler.SavedVariables.SwimlaneMax)
    -- Update sorted swimlane list
    local me = GetGroupUnitTagByIndex(GetGroupIndexByUnitTag("player"))

    for i,swimlanePlayer in ipairs(swimlane.Players) do
        if (swimlanePlayer.RelativeUltimate  >= 100) then
            if (swimlanePlayer.IsPlayerDead) then
                swimlanePlayer.RelativeUltimate = 100
            else
                swimlanePlayer.RelativeUltimate = 100 + POC_SettingsHandler.SavedVariables.SwimlaneMax - i
            end
        end
        POC_SwimlaneList.UpdateListRow(swimlane.SwimlaneControl:GetNamedChild("Row" .. i), swimlanePlayer)
        if (swimlanePlayer.PingTag ~= me) then
            -- nothing to do
        elseif (not POC_SettingsHandler.SavedVariables.UltNumberShow or
                (swimlanePlayer.RelativeUltimate < 100) or
                CurrentHudHiddenState() or
                swimlanePlayer.IsPlayerDead or
                not POC_GroupHandler.IsGrouped() or
                not POC_SettingsHandler.IsSwimlaneListVisible()) then
            POC_UltNumber.Hide(true)
            play_sound = swimlanePlayer.RelativeUltimate < 100
        else
            local color
            if (i == 1) then
                color = "00ff00"
            else
                color = "ff0000"
            end
            POC_UltNumberLabel:SetText("|c" .. color .. " #" .. i .. "|r")
            POC_UltNumber.Hide(false)
            if (i ~= 1) then
                play_sound = true
            elseif (play_sound and POC_SettingsHandler.SavedVariables.WereNumberOne) then
                PlaySound(SOUNDS.DUEL_START)
                play_sound = false
            end
        end
    end
end

--[[
	Updates list row
]]--
function POC_SwimlaneList.UpdateListRow(row, player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.UpdateListRow")
    end

    local playerName = player.PlayerName
    local nameLength = string.len(playerName)

    if (nameLength > namelen) then
        playerName = string.sub(playerName, 0, namelen) .. '..'
    end

    if (not player.IsPlayerDead and IsUnitInCombat(player.PingTag)) then
        playerName = "|cff0000" .. playerName .. "|r"
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
function POC_SwimlaneList.UpdatePlayer(player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.UpdatePlayer")
    end

    if (player) then
        local swimLane = POC_SwimlaneList.GetSwimLane(player.UltimateGroup.GroupAbilityId)

        if (swimLane) then
            local row = POC_SwimlaneList.GetSwimLaneRow(swimLane, player.PlayerName)

            -- Update player
            if (row ~= nil) then
                for i,swimlanePlayer in ipairs(swimLane.Players) do
                        if (swimlanePlayer.PlayerName == player.PlayerName) then
                            swimlanePlayer.LastMapPingTimestamp = GetTimeStamp()
                            swimlanePlayer.IsPlayerDead = player.IsPlayerDead
                            swimlanePlayer.PingTag = player.PingTag
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

                if (nextFreeRow <= POC_SettingsHandler.SavedVariables.SwimlaneMax) then
                    if (LOG_ACTIVE) then 
                        _logger:logDebug("POC_SwimlaneList.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                    end

                    player.LastMapPingTimestamp = GetTimeStamp()
                    swimLane.Players[nextFreeRow] = player
                    row = swimLane.SwimlaneControl:GetNamedChild("Row" .. nextFreeRow)
                else
                    if (LOG_ACTIVE) then _logger:logDebug("POC_SwimlaneList.UpdatePlayer, too much players for one swimlane " .. tostring(nextFreeRow)) end
                end
            end

            -- Only update if player in a row
            if (row ~= nil) then
                POC_SwimlaneList.SortSwimlane(swimLane)
            end
        else
            if (LOG_ACTIVE) then _logger:logDebug("POC_SwimlaneList.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName)) end
        end
    end
end

--[[
	Get swimlane from current SwimLanes
]]--
function POC_SwimlaneList.GetSwimLane(gid)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.GetSwimLane")
        _logger:logDebug("gid", gid)
    end

    if (gid ~= 0) then
        for i,swimLane in ipairs(POC_SwimlaneList.Swimlanes) do
		    if (swimLane.UltimateGroupId == gid) then
                return swimLane
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("POC_SwimlaneList.GetSwimLane, swimLane not found " .. tostring(gid)) end
        return nil
    else
        _logger:logError("POC_SwimlaneList.GetSwimLane, gid is 0")
        return nil
    end
end

--[[
	Get Player Row from current players in swimlane
]]--
function POC_SwimlaneList.GetSwimLaneRow(swimLane, playerName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.GetSwimLaneRow")
        _logger:logDebug("swimLane ID", swimLane.Id)
    end

    if (swimLane) then
        for i,player in ipairs(swimLane.Players) do
            if (LOG_ACTIVE) then _logger:logDebug(player.PlayerName .. " == " .. playerName) end
		    if (player.PlayerName == playerName) then
                return swimLane.SwimlaneControl:GetNamedChild("Row" .. i)
            end
	    end

        if (LOG_ACTIVE) then _logger:logDebug("POC_SwimlaneList.GetSwimLane, player not found " .. tostring(playerName)) end
        return nil
    else
        _logger:logError("POC_SwimlaneList.GetSwimLane, swimLane is nil")
        return nil
    end
end

--[[
	Clears all players in swimlane
]]--
function POC_SwimlaneList.ClearPlayersFromSwimlane(swimlane)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.ClearPlayersFromSwimlane")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    local updated = false
    if (swimlane) then
        for i=1, POC_SettingsHandler.SavedVariables.SwimlaneMax, 1 do
            local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
            local swimlanePlayer = swimlane.Players[i]

            if (swimlanePlayer ~= nil) then
                updated = true
                local isPlayerNotGrouped = IsUnitGrouped(swimlanePlayer.PingTag) == false

                if (POC_SwimlaneList.IsMocked) then
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
function POC_SwimlaneList.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
    _control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets POC_SwimlaneList on settings position
]]--
function POC_SwimlaneList.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnSwimlaneListMoveStop saves current POC_SwimlaneList position to settings
]]--
function POC_SwimlaneList.OnSwimlaneListMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SwimlaneList.OnSwimlaneListMoveStop") end

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
function POC_SwimlaneList.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (POC_GroupHandler.IsGrouped()) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

-- Style changed
--
function POC_SwimlaneList.StyleChanged()
    local style = POC_SettingsHandler.SavedVariables.Style
    if (style ~= curstyle) then
        curstyle = style
        if (_control ~= nil) then
            _control:SetHidden(true)
        end
        if (style == "Compact") then
            _control = POC_CompactSwimlaneListControl
            swimlanerow = "CompactGroupUltimateSwimlaneRow"
            namelen = 6
            topleft = 50
        else
            _control = POC_SwimlaneListControl
            swimlanerow = "GroupUltimateSwimlaneRow"
            namelen = 12
            topleft = 25
        end
        if (style_swimlanes[style] ~= nil) then
            for i, v in pairs(style_swimlanes[style]) do
               POC_SwimlaneList.Swimlanes[i] = v 
            end
            d("Used saved swimlane")
        else
            POC_SwimlaneList.CreateSwimLaneListHeaders()
            POC_SwimlaneList.SetControlMovable(POC_SettingsHandler.SavedVariables.Movable)
            POC_SwimlaneList.RestorePosition(POC_SettingsHandler.SavedVariables.PosX, POC_SettingsHandler.SavedVariables.PosY)
            style_swimlanes[style] = {}
            for i, v in pairs(POC_SwimlaneList.Swimlanes) do
                style_swimlanes[style][i] = v
            end
            d("Saved new swimlane")
        end
        POC_SwimlaneList.SetControlActive()
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function POC_SwimlaneList.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.SetControlActive")
    end

    local isVisible = POC_SettingsHandler.IsSwimlaneListVisible() and POC_GroupHandler.IsGrouped()
    if (LOG_ACTIVE) then _logger:logDebug("isVisible", isHidden) end
    
    local isHidden = not isVisible or CurrentHudHiddenState()
    POC_SwimlaneList.SetControlHidden(isHidden)
    POC_UltNumber.Hide(isHidden)
    POC_UltimateSelectorControl:SetHidden(isHidden)

    if (isVisible) then
        if (registered) then
            return
        end
        registered = true
        POC_SwimlaneList.SetControlMovable(POC_SettingsHandler.SavedVariables.Movable)
        POC_SwimlaneList.RestorePosition(POC_SettingsHandler.SavedVariables.PosX, POC_SettingsHandler.SavedVariables.PosY)

        EVENT_MANAGER:RegisterForUpdate(POC_SwimlaneList.Name, REFRESHRATE, POC_SwimlaneList.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, POC_SwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, POC_SwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, POC_SwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_SwimlaneList.SetControlHidden)
    elseif (registered) then
        registered = false
        -- Stop timeout timer
        EVENT_MANAGER:UnregisterForUpdate(POC_SwimlaneList.Name)

        -- CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, POC_SwimlaneList.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, POC_SwimlaneList.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, POC_SwimlaneList.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, POC_SwimlaneList.SetSwimlaneUltimate)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, POC_SwimlaneList.SetControlHidden)
    end
end

--[[
	OnSwimlaneHeaderClicked called on header clicked
]]--
function POC_SwimlaneList.OnSwimlaneHeaderClicked(button, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.OnSwimlaneHeaderClicked")
        _logger:logDebug("swimlaneId", swimlaneId)
    end

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, POC_SwimlaneList.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("POC_SwimlaneList.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup called on header clicked
]]--
function POC_SwimlaneList.OnSetUltimateGroup(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, POC_SwimlaneList.OnSetUltimateGroup)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        POC_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlaneId, group)
    else
        _logger:logError("POC_UltimateGroupMenu.ShowUltimateGroupMenu, group nil or swimlaneId invalid")
    end
end

--[[
	SetSwimlaneUltimate sets the swimlane header icon in base of gid
]]--
function POC_SwimlaneList.SetSwimlaneUltimate(swimlaneId, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SwimlaneList.SetSwimlaneUltimate")
        _logger:logDebug("ultimateGroup.GroupName, swimlaneId", ultimateGroup.GroupName, swimlaneId)
    end

    local swimlaneObject = POC_SwimlaneList.Swimlanes[swimlaneId]
    local iconControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
    local labelControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("UltimateLabel")

    if (ultimateGroup ~= nil and iconControl ~= nil and labelControl ~= nil) then
        iconControl:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))
        labelControl:SetText(ultimateGroup.GroupName)

        swimlaneObject.UltimateGroupId = ultimateGroup.GroupAbilityId
        POC_SwimlaneList.ClearPlayersFromSwimlane(swimlaneObject)
    else
        _logger:logError("POC_SwimlaneList.SetSwimlaneUltimateIcon, icon is " .. tostring(icon) .. ";" .. tostring(iconControl) .. ";" .. tostring(ultimateGroup))
    end
end

--[[
	CreateSwimLaneListHeaders creates swimlane list headers
]]--
function POC_SwimlaneList.CreateSwimLaneListHeaders()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SwimlaneList.CreateSwimLaneListHeaders") end

	for i=1, SWIMLANES, 1 do
            local gid = POC_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[i]
            local ultimateGroup = POC_UltimateGroupHandler.GetUltimateGroupByAbilityId(gid)

            local name = "Swimlane" .. tostring(i)
            local swimlaneControl = _control:GetNamedChild(name)

            -- Add button
            local button = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
            button:SetHandler("OnClicked", function() POC_SwimlaneList.OnSwimlaneHeaderClicked(button, i) end)
            
            local swimLane = {}
            swimLane.Id = i
            swimLane.SwimlaneControl = swimlaneControl
            swimLane.Players = {}

            if (ultimateGroup == nil) then
                _logger:logError("POC_SwimlaneList.CreateSwimLaneListHeaders, ultimateGroup nil.")
            else
                if (LOG_ACTIVE) then 
                    _logger:logDebug("Create Swimlane", i)
                    _logger:logDebug("ultimateGroup.GroupName", ultimateGroup.GroupName)
                    _logger:logDebug("swimlaneControlName", swimlaneControlName)
                end

                local icon = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
                icon:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))

                local label = swimlaneControl:GetNamedChild("Header"):GetNamedChild("UltimateLabel")
                if (label ~= nil) then
                    label:SetText(ultimateGroup.GroupName)
                end

                swimLane.UltimateGroupId = ultimateGroup.GroupAbilityId
            end

            POC_SwimlaneList.CreateSwimlaneListRows(swimlaneControl)
            POC_SwimlaneList.Swimlanes[i] = swimLane
	end
end

--[[
	CreateSwimlaneListRows creates swimlane list rows
]]--
function POC_SwimlaneList.CreateSwimlaneListRows(swimlaneControl)
    if (LOG_ACTIVE) then _logger:logTrace("POC_SwimlaneList.CreateSwimlaneListRows") end

    if (swimlaneControl ~= nil) then
	    for i=1, SWIMLANEULTMAX, 1 do
                local row = CreateControlFromVirtual("$(parent)Row", swimlaneControl, swimlanerow, i)
                if (LOG_ACTIVE) then _logger:logDebug("Row created " .. row:GetName()) end

                        row:SetHidden(true) -- initial not visible

                        if (i == 1) then
                            row:SetAnchor(TOPLEFT, swimlaneControl, TOPLEFT, 0, topleft)
                        elseif (i == 5) then -- Fix pixelbug, Why the hell ZOS?!
                            row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, 0)
                        else
                            row:SetAnchor(TOPLEFT, lastRow, BOTTOMLEFT, 0, -1)
                        end
                        lastRow = row
                end
        else
            _logger:logError("POC_SwimlaneList.CreateSwimlaneListRows, swimlaneControl nil.")
    end
end

--[[
	Initialize initializes POC_SwimlaneList
]]--
function POC_SwimlaneList.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_SwimlaneList.Initialize")
    end

    _logger = logger
    POC_SwimlaneList.IsMocked = isMocked

    POC_UltNumber:ClearAnchors()
    POC_UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
                            POC_SettingsHandler.SavedVariables.UltNumberPos[1],
                            POC_SettingsHandler.SavedVariables.UltNumberPos[2])
    POC_UltNumber:SetMovable(true)
    POC_UltNumber:SetMouseEnabled(true)
    POC_UltNumber.Hide(not POC_SettingsHandler.SavedVariables.UltNumber)


    POC_SwimlaneList.StyleChanged()
    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, POC_SwimlaneList.StyleChanged)
    CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, POC_SwimlaneList.RefreshList)
    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, POC_SwimlaneList.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, POC_SwimlaneList.SetControlActive)
end

function POC_SwimlaneList.savePosNumber(self)
    POC_SettingsHandler.SavedVariables.UltNumberPos = {self:GetLeft(),self:GetTop()}
end

function POC_UltNumber.Hide(hide)
    if (POC_UltNumber.ishidden ~= hide) then
        POC_UltNumber:SetHidden(hide)
        POC_UltNumber.ishidden = hide
    end
end
