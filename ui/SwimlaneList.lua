--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local REFRESHRATE = 1000 -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 10 -- s; GetTimeStamp() is in seconds

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

local forcepct = nil
local sldebug

--[[
	Table POC_Swimlane
]]--
POC_Swimlane = {
    IsMocked = false,
    Me = GetUnitName("player"),
    UltPct = nil,
    Name = "POC-SwimlaneList",
    Swimlanes = {},
    WasActive = false,
    __index = POC_Swimlane
}

local _this = POC_Swimlane

POC_UltNumber.ishidden = nil

--[[
	Sets visibility of labels
]]--
function _this.RefreshList()
    if LOG_ACTIVE then
        _logger:logTrace("POC_Swimlane.RefreshList")
    end

    if (not POC_GroupHandler.IsGrouped()) then
        if (_this.WasActive) then
            d("POC: No longer grouped")
            _this.SetControlActive()
            _this.WasActive = false
            -- d("SetControlActive: set WasActive = false")
        end
    else
        -- Check all swimlanes
        local displayed = false
        for i,swimlane in ipairs(_this.Swimlanes) do
            if _this.ClearPlayersFromSwimlane(swimlane) then
                displayed = true
            end
        end
        if (not (displayed and _this.WasActive)) then
            -- d({"displayed", displayed})
            -- d({"WasActive", _this.WasActive})
            _this.SetControlActive()
            if (not _this.WasActive) then
                d("POC: now grouped")
            end
            _this.WasActive = true
        end
    end
end

-- Sorts swimlane
--
function _this.SortSwimlane(swimlane)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Swimlane.SortSwimlane")
    end

    function sortval(x)
        local a
        if (x.IsPlayerDead) then
            a = x.UltPct - 100
        else
            a = x.UltPct
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

    -- Update sorted swimlane list
    for i,player in ipairs(swimlane.Players) do
        if not player.IsMe then
            _this.UpdateListRow(swimlane, i, player)
            -- d(player.PlayerName .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
        else
            local not100
            if forcepct ~= nil then
                player.UltPct = forcepct
                _this.UltPct = forcepct
                not100 = player.UltPct  < 100
            elseif player.UltPct  < 100 then
                _this.UltPct = nil
                not100 = true
            elseif player.IsPlayerDead then
                _this.UltPct = 100
            else
                _this.UltPct = 101 + POC_Settings.SavedVariables.SwimlaneMax - i
                player.UltPct = _this.UltPct
            end
            -- d(player.PlayerName .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
            _this.UpdateListRow(swimlane, i, player)
            if (not POC_Settings.SavedVariables.UltNumberShow or
                    not100 or
                    CurrentHudHiddenState() or
                    player.IsPlayerDead or
                    not POC_GroupHandler.IsGrouped() or
                    not POC_Settings.IsSwimlaneListVisible()) then
                POC_UltNumber.Hide(true)
                if not100 then
                    play_sound = true
                end
            else
                local color
                if i == 1 then
                    color = "00ff00"
                else
                    color = "ff0000"
                end
                POC_UltNumberLabel:SetText("|c" .. color .. " #" .. i .. "|r")
                POC_UltNumber.Hide(false)
                if (i ~= 1) then
                    play_sound = true
                elseif (play_sound and POC_Settings.SavedVariables.WereNumberOne) then
                    PlaySound(SOUNDS.DUEL_START)
                    play_sound = false
                end
            end
        end
    end
end

--[[
	Updates list row
]]--
function _this.UpdateListRow(swimlane, i, player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.UpdateListRow")
    end

    local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
    local playerName = player.PlayerName
    local nameLength = string.len(playerName)

    if (nameLength > namelen) then
        playerName = string.sub(playerName, 0, namelen) .. '..'
    end

    if (not player.IsPlayerDead and IsUnitInCombat(player.PingTag)) then
        playerName = "|cff0000" .. playerName .. "|r"
    end

    if (sldebug) then
        playerName = playerName .. "   " .. player.UltPct
    end

    local ultpct
    if player.UltPct > 100 then
        ultpct = 100
    else
        ultpct = player.UltPct
    end
    row:GetNamedChild("SenderNameValueLabel"):SetText(playerName)
    row:GetNamedChild("UltPctStatusBar"):SetValue(ultpct)

    if (player.IsPlayerDead) then
        -- Dead Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, 0.8)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.03, 0.03, 0.7)
    elseif (player.UltPct >= 100) then
		-- Ready Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 1)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.7, 0.03, 1)
    else
		-- Inprogress Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 0.8)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.03, 0.7, 0.7)
    end

    if (row:IsHidden()) then
        row:SetHidden(false)
    end
end

--[[
	Updates list player
]]--
function _this.UpdatePlayer(player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.UpdatePlayer")
    end

    if (player) then
        local swimlane = _this.GetSwimLane(player.UltimateGroup.GroupAbilityId)

        if (swimlane) then
            local row = _this.GetSwimLaneRow(swimlane, player.PlayerName)

            -- Update player
            if (row ~= nil) then
                for i,swimplayer in ipairs(swimlane.Players) do
                    if (swimplayer.PlayerName == player.PlayerName) then
                        swimplayer.IsMe = player.IsMe
                        swimplayer.PingTag = player.PingTag
                        swimplayer.LastMapPingTimestamp = GetTimeStamp()
                        swimplayer.IsPlayerDead = player.IsPlayerDead
                        swimplayer.UltPct = player.UltPct
                        break
                    end
                end
            else
                -- Add new player
                local nextFreeRow = 1

                for i,player in ipairs(swimlane.Players) do
                    nextFreeRow = nextFreeRow + 1
                end

                if (nextFreeRow > POC_Settings.SavedVariables.SwimlaneMax) then
                    if (LOG_ACTIVE) then
                        _logger:logDebug("POC_Swimlane.UpdatePlayer, too much players for one swimlane " .. tostring(nextFreeRow))
                    end
                else
                    if (LOG_ACTIVE) then 
                        _logger:logDebug("POC_Swimlane.UpdatePlayer, add player " .. tostring(player.PlayerName) .. " to row " .. tostring(nextFreeRow)) 
                    end

                    player.LastMapPingTimestamp = GetTimeStamp()
                    swimlane.Players[nextFreeRow] = player
                    row = swimlane.SwimlaneControl:GetNamedChild("Row" .. nextFreeRow)
                end
            end

            -- Only update if player in a row
            if (row ~= nil) then
                _this.SortSwimlane(swimlane)
            end
        else
            if LOG_ACTIVE then
                _logger:logDebug("POC_Swimlane.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName))
            end
        end
    end
end

--[[
	Get swimlane from current SwimLanes
]]--
function _this.GetSwimLane(gid)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.GetSwimLane")
        _logger:logDebug("gid", gid)
    end

    if (gid == 0) then
        _logger:logError("POC_Swimlane.GetSwimLane, gid is 0")
    else
        for i,swimlane in ipairs(_this.Swimlanes) do
            if (swimlane.UltimateGroupId == gid) then
                return swimlane
            end
        end

        if (LOG_ACTIVE) then
            _logger:logDebug("POC_Swimlane.GetSwimLane, swimlane not found " .. tostring(gid))
        end
    end
    return nil
end

--[[
	Get Player Row from current players in swimlane
]]--
function _this.GetSwimLaneRow(swimlane, playerName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.GetSwimLaneRow")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    if not swimlane then
        _logger:logError("POC_Swimlane.GetSwimLane, swimlane is nil")
        return nil
    end

    for i,player in ipairs(swimlane.Players) do
        if LOG_ACTIVE then
            _logger:logDebug(player.PlayerName .. " == " .. playerName)
        end
        if (player.PlayerName == playerName) then
            return swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
        end
    end

    if LOG_ACTIVE then
        _logger:logDebug("POC_Swimlane.GetSwimLane, player not found " .. tostring(playerName))
    end
    return nil
end

--[[
	Clears all players in swimlane
]]--
function _this.ClearPlayersFromSwimlane(swimlane)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.ClearPlayersFromSwimlane")
        _logger:logDebug("swimlane ID", swimlane.Id)
    end

    local updated = false
    if (swimlane) then
        for i=1, POC_Settings.SavedVariables.SwimlaneMax, 1 do
            local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
            local swimplayer = swimlane.Players[i]

            if (swimplayer ~= nil) then
                updated = true
                local isPlayerNotGrouped = IsUnitGrouped(swimplayer.PingTag) == false

                if (_this.IsMocked) then
                    isPlayerNotGrouped = false
                end

                local isPlayerTimedOut = (GetTimeStamp() - swimplayer.LastMapPingTimestamp) > TIMEOUT
                local isPlayerUltimateNotCorrect = swimlane.UltimateGroupId ~= swimplayer.UltimateGroup.GroupAbilityId

                if (isPlayerNotGrouped or isPlayerTimedOut or isPlayerUltimateNotCorrect) then
                    if LOG_ACTIVE then
                        _logger:logDebug("Player invalid, hide row: " .. tostring(i))
                    end

                    table.remove(swimlane.Players, i)
                    row:SetHidden(true)
                end
            else
                if LOG_ACTIVE then
                    _logger:logDebug("Row empty, hide: " .. tostring(i))
                end
                row:SetHidden(true)
            end
        end
    end
    return updated
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function _this.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
    _control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets _this on settings position
]]--
function _this.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnSwimlaneListMoveStop saves current _this position to settings
]]--
function _this.OnSwimlaneListMoveStop()
    if LOG_ACTIVE then
        _logger:logTrace("POC_Swimlane.OnSwimlaneListMoveStop")
    end

	local left = _control:GetLeft()
	local top = _control:GetTop()
	
    POC_Settings.SavedVariables.PosX = left
    POC_Settings.SavedVariables.PosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", POC_Settings.SavedVariables.PosX, POC_Settings.SavedVariables.PosY)
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function _this.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.SetControlHidden")
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
function _this.StyleChanged()
    local style = POC_Settings.SavedVariables.Style
    if (style ~= curstyle) then
        curstyle = style
        if (_control ~= nil) then
            _control:SetHidden(true)
        end
        if (style == "Compact") then
            _control = POC_CompactSwimlaneControl
            swimlanerow = "CompactGroupUltimateSwimlaneRow"
            namelen = 6
            topleft = 50
        else
            _control = POC_SwimlaneControl
            swimlanerow = "GroupUltimateSwimlaneRow"
            namelen = 12
            topleft = 25
        end
        if (style_swimlanes[style] ~= nil) then
            for i, v in pairs(style_swimlanes[style]) do
               _this.Swimlanes[i] = v 
            end
            -- d("Used saved swimlane")
        else
            _this.CreateSwimLaneListHeaders()
            _this.SetControlMovable(POC_Settings.SavedVariables.Movable)
            _this.RestorePosition(POC_Settings.SavedVariables.PosX, POC_Settings.SavedVariables.PosY)
            style_swimlanes[style] = {}
            for i, v in pairs(_this.Swimlanes) do
                style_swimlanes[style][i] = v
            end
            -- d("Saved new swimlane")
        end
        _this.SetControlActive()
    end
end

--[[
	SetControlActive sets hidden on control
]]--
function _this.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.SetControlActive")
    end

    local isVisible = POC_Settings.IsSwimlaneListVisible() and POC_GroupHandler.IsGrouped()
    if LOG_ACTIVE then
        _logger:logDebug("isVisible", isHidden)
    end
    
    local isHidden = not isVisible or CurrentHudHiddenState()
    _this.SetControlHidden(isHidden)
    POC_UltNumber.Hide(isHidden)
    POC_UltimateSelectorControl:SetHidden(isHidden)

    if (isVisible) then
        if (registered) then
            return
        end
        registered = true
        _this.SetControlMovable(POC_Settings.SavedVariables.Movable)
        _this.RestorePosition(POC_Settings.SavedVariables.PosX, POC_Settings.SavedVariables.PosY)

        EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, _this.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, _this.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, _this.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, _this.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, _this.SetControlHidden)
    elseif (registered) then
        registered = false
        -- Stop timeout timer
        EVENT_MANAGER:UnregisterForUpdate(_this.Name)

        -- CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, _this.RefreshList)
        CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, _this.UpdatePlayer)
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, _this.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, _this.SetSwimlaneUltimate)
        CALLBACK_MANAGER:UnregisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, _this.SetControlHidden)
    end
end

--[[
	OnSwimlaneHeaderClicked called on header clicked
]]--
function _this.OnSwimlaneHeaderClicked(button, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.OnSwimlaneHeaderClicked")
        _logger:logDebug("swimlaneId", swimlaneId)
    end

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("POC_Swimlane.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup called on header clicked
]]--
function _this.OnSetUltimateGroup(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltimateGroup)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        POC_Settings.SetSwimlaneUltimateGroupIdSettings(swimlaneId, group)
    else
        _logger:logError("POC_UltimateGroupMenu.ShowUltimateGroupMenu, group nil or swimlaneId invalid")
    end
end

--[[
	SetSwimlaneUltimate sets the swimlane header icon in base of gid
]]--
function _this.SetSwimlaneUltimate(swimlaneId, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.SetSwimlaneUltimate")
        _logger:logDebug("ultimateGroup.GroupName, swimlaneId", ultimateGroup.GroupName, swimlaneId)
    end

    local swimlaneObject = _this.Swimlanes[swimlaneId]
    local iconControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
    local labelControl = swimlaneObject.SwimlaneControl:GetNamedChild("Header"):GetNamedChild("UltimateLabel")

    if (ultimateGroup ~= nil and iconControl ~= nil and labelControl ~= nil) then
        iconControl:SetTexture(GetAbilityIcon(ultimateGroup.GroupAbilityId))
        labelControl:SetText(ultimateGroup.GroupName)

        swimlaneObject.UltimateGroupId = ultimateGroup.GroupAbilityId
        _this.ClearPlayersFromSwimlane(swimlaneObject)
    else
        _logger:logError("POC_Swimlane.SetSwimlaneUltimateIcon, icon is " .. tostring(icon) .. ";" .. tostring(iconControl) .. ";" .. tostring(ultimateGroup))
    end
end

-- CreateSwimLaneListHeaders creates swimlane list headers
--
function _this.CreateSwimLaneListHeaders()
    if LOG_ACTIVE then
        _logger:logTrace("POC_Swimlane.CreateSwimLaneListHeaders")
    end

	for i=1, SWIMLANES, 1 do
            local gid = POC_Settings.SavedVariables.SwimlaneUltimateGroupIds[i]
            local ultimateGroup = POC_UltimateGroupHandler.GetUltimateGroupByAbilityId(gid)

            local name = "Swimlane" .. tostring(i)
            local swimlaneControl = _control:GetNamedChild(name)

            -- Add button
            local button = swimlaneControl:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
            button:SetHandler("OnClicked", function() _this.OnSwimlaneHeaderClicked(button, i) end)
            
            local swimlane = {}
            swimlane.Id = i
            swimlane.SwimlaneControl = swimlaneControl
            swimlane.Players = {}

            if (ultimateGroup == nil) then
                _logger:logError("POC_Swimlane.CreateSwimLaneListHeaders, ultimateGroup nil.")
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

                swimlane.UltimateGroupId = ultimateGroup.GroupAbilityId
            end

            _this.CreateSwimlaneListRows(swimlaneControl)
            _this.Swimlanes[i] = swimlane
	end
end

--[[
	CreateSwimlaneListRows creates swimlane list rows
]]--
function _this.CreateSwimlaneListRows(swimlaneControl)
    if LOG_ACTIVE then
        _logger:logTrace("POC_Swimlane.CreateSwimlaneListRows")
    end

    if (swimlaneControl == nil) then
        _logger:logError("POC_Swimlane.CreateSwimlaneListRows, swimlaneControl nil.")
        return
    end

    for i=1, SWIMLANEULTMAX, 1 do
        local row = CreateControlFromVirtual("$(parent)Row", swimlaneControl, swimlanerow, i)
        if LOG_ACTIVE then
            _logger:logDebug("Row created " .. row:GetName())
        end

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
end

function _this.savePosNumber(self)
    POC_Settings.SavedVariables.UltNumberPos = {self:GetLeft(),self:GetTop()}
end

function POC_UltNumber.Hide(hide)
    if (POC_UltNumber.ishdiden == nil and POC_UltNumber.ishidden ~= hide) then
        POC_UltNumber:SetHidden(hide)
        POC_UltNumber.ishidden = hide
    end
end

-- Initialize initializes _this
--
function _this.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_Swimlane.Initialize")
    end

    _logger = logger
    _this.IsMocked = isMocked

    POC_UltNumber:ClearAnchors()
    if (POC_Settings.SavedVariables.UltNumberPos == nil) then
        POC_UltNumber:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
        POC_UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
                                POC_Settings.SavedVariables.UltNumberPos[1],
                                POC_Settings.SavedVariables.UltNumberPos[2])
    end
    POC_UltNumber:SetMovable(true)
    POC_UltNumber:SetMouseEnabled(true)
    POC_UltNumber.Hide(not POC_Settings.SavedVariables.UltNumber)


    _this.StyleChanged()
    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, _this.StyleChanged)
    CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, _this.RefreshList)
    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, _this.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, _this.SetControlActive)
    SLASH_COMMANDS["/pocpct"] = function(pct)
        if string.len(pct) == 0 then
            forcepct = nil
        else
            forcepct = tonumber(pct)
        end
    end
    SLASH_COMMANDS["/pocpingtag"] = function(pct)
        local p = tostring(GetGroupUnitTagByIndex(GetGroupIndexByUnitTag("player")))
        d(p)
    end
    SLASH_COMMANDS["/pocsldebug"] = function(pct)
        sldebug = not sldebug
        d(sldebug)
    end
end
