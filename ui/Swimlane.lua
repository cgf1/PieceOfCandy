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
local sldebug = false

local ping_refresh

-- Table POC_Swimlane
--
POC_Swimlane = {
    IsMocked = false,
    Me = GetUnitName("player"),
    UltPct = nil,
    Name = "POC-SwimlaneList",
    Swimlanes = {},
    WasActive = false,
    __index = POC_Swimlane
}

local playerkeys = {'IsPlayerDead', 'PingTag', 'UltPct', 'UltGrp', 'InCombat'}

local _this = POC_Swimlane

POC_UltNumber.ishidden = nil

-- Sets visibility of labels
--
function _this.RefreshList(x, what)
    -- if x ~= nil and what ~= nil then
    --    d("RefreshList " .. tostring(what) .. " = '" .. x .. "'")
    -- end
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
            if _this.SortSwimlane(swimlane) then
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

function _this.PlayerTimedOut(player)
    return ((GetTimeStamp() - player.LastMapPingTimestamp) > TIMEOUT)
end

-- Sorts swimlane
--
function _this.SortSwimlane(swimlane)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Swimlane.SortSwimlane")
    end

    local players = swimlane.Players

    function sortval(player)
        local a
        if _this.PlayerTimedOut(player) then
            a = player.UltPct - 200
        elseif player.IsPlayerDead or _this.PlayerTimedOut(player) then
            a = player.UltPct - 100
        else
            a = player.UltPct
        end
        return a
    end
    -- Comparer
    function compare(key1, key2)
        player1 = players[key1]
        player2 = players[key2]
        a = sortval(player1)
        b = sortval(player2)
        -- d("A " .. a)
        -- d("B " .. b)
        if (a == b) then
            return player1.PingTag < player2.PingTag
        else
            return a > b
       end
    end

    local keys = {}
    for n in pairs(players) do
        table.insert(keys, n)
    end

    table.sort(keys, compare)

    -- Update sorted swimlane
    local i = 0
    local displayed = false
    for uneeded, playername in ipairs(keys) do
        local player = players[playername]
        local player_grouped =  IsUnitGrouped(player.PingTag)
        local player_ultimate_correct = swimlane.UltGrpId == player.UltGrp.GroupAbilityId
        if not player_grouped or not player_ultimate_correct then
            players[playername] = nil
        else
            i = i + 1
            if i > POC_Settings.SavedVariables.SwimlaneMax then
                -- log here?
                break
            end
            displayed = true
            if not player.IsMe then
                _this.UpdateCell(swimlane, i, player, playername)
                -- d(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
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
                -- d(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
                _this.UpdateCell(swimlane, i, playername)
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
    return displayed
end

-- Update a cell
--
function _this.UpdateCell(swimlane, i, player, playername)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.UpdateCell")
    end

    local row = swimlane.SwimlaneControl:GetNamedChild("Row" .. i)
    local nameLength = string.len(playername)

    if (nameLength > namelen) then
        playername = string.sub(playername, 0, namelen) .. '..'
    end

    if (not player.IsPlayerDead and IsUnitInCombat(player.PingTag)) then
        playername = "|cff0000" .. playername .. "|r"
    end

    if (sldebug) then
        playername = playername .. "   " .. player.UltPct
    end

    local ultpct
    if player.UltPct > 100 then
        ultpct = 100
    else
        ultpct = player.UltPct
    end

    row:GetNamedChild("SenderNameValueLabel"):SetText(playername)
    row:GetNamedChild("UltPctStatusBar"):SetValue(ultpct)

    if (player.IsPlayerDead) then
        -- Dead Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, 0.8)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.03, 0.03, 0.7)
    elseif _this.PlayerTimedOut(player) then
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.8, 0.8, 0.8, 0.7)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.8, 0.8, 0.7)
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

-- Updates player in the swimlane
--
function _this.UpdatePlayer(player)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.UpdatePlayer")
    end

    if (not player) then
        return
    end

    local swimlane = _this.GetSwimLane(player.UltGrp.GroupAbilityId)

    if (not swimlane) then
        if LOG_ACTIVE then
            _logger:logDebug("POC_Swimlane.UpdatePlayer, swimlane not found for ultimategroup " .. tostring(ultimateGroup.GroupName))
        end
        return
    end

    local playername = player.PlayerName
    player.PlayerName = nil

    swimplayer = swimlane.Players[playername]

    player.InCombat = IsUnitInCombat(player.PingTag)
    player.Online = IsUnitOnline(player.PingTag)
    -- Update player
    local orig_swimlane
    if (swimplayer ~= nil) then
        if (LOG_ACTIVE) then 
            _logger:logDebug("POC_Swimlane.UpdatePlayer, update player " .. tostring(playername)) 
        end
        if swimplayer.IsMe and _this.PlayerTimedOut(swimplayer) then
            _this.UltPct = nil
        end
        orig_swimlane = _this.GetSwimLane(swimplayer.UltGrp.GroupAbilityId)
    else
        swimlane.Players[playername] = {}
        swimplayer = swimlane.Players[playername]
        if (LOG_ACTIVE) then 
            _logger:logDebug("POC_Swimlane.UpdatePlayer, add player " .. tostring(playername)) 
        end
        swimplayer.IsMe = swimplayer == GetUnitName("player")
    end

    local changed = false
    for n,v in pairs(player) do
        if swimplayer[n] == nil or swimplayer[n] ~= v then
            d(tostring(n) .. " " .. tostring(v))
            changed = true
            swimplayer[n] = v
        end
    end

    swimplayer.LastMapPingTimestamp = GetTimeStamp()

    if (changed) then
        _this.SortSwimlane(swimlane)
    end
end

-- Get swimlane from current SwimLanes
--
function _this.GetSwimLane(gid)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.GetSwimLane")
        _logger:logDebug("gid", gid)
    end

    if (gid == 0) then
        _logger:logError("POC_Swimlane.GetSwimLane, gid is 0")
    else
        for i,swimlane in ipairs(_this.Swimlanes) do
            if (swimlane.UltGrpId == gid) then
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

        -- EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, _this.RefreshList)

        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, _this.UpdatePlayer)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, _this.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, _this.SetSwimlaneUltimate)
        CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, _this.SetControlHidden)
    elseif (registered) then
        registered = false
        -- Stop timeout timer
        -- EVENT_MANAGER:UnregisterForUpdate(_this.Name)

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
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltGrp)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button, swimlaneId)
    else
        _logger:logError("POC_Swimlane.OnSwimlaneHeaderClicked, button nil")
    end
end

--[[
	OnSetUltGrp called on header clicked
]]--
function _this.OnSetUltGrp(group, swimlaneId)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlane.OnSetUltGrp")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltGrp)

    if (group ~= nil and swimlaneId ~= nil and swimlaneId >= 1 and swimlaneId <= 6) then
        POC_Settings.SetSwimlaneUltGrpIdSettings(swimlaneId, group)
    else
        _logger:logError("POC_UltGrpMenu.ShowUltGrpMenu, group nil or swimlaneId invalid")
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

        swimlaneObject.UltGrpId = ultimateGroup.GroupAbilityId
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
        local gid = POC_Settings.SavedVariables.SwimlaneUltGrpIds[i]
        local ultimateGroup = POC_UltGrpHandler.GetUltGrpByAbilityId(gid)

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

            swimlane.UltGrpId = ultimateGroup.GroupAbilityId
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
    _this.RefreshList("init", "init")
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
    SLASH_COMMANDS["/pocrefresh"] = function(pct)
        ping_refresh = not ping_refresh
        if ping_refresh then
            EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, _this.RefreshList)
            d("refresh on")
        else
            EVENT_MANAGER:UnregisterForUpdate(_this.Name)
            d("refresh off")
        end
    end
end
