--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local REFRESHRATE = 1000        -- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 10              -- s; GetTimeStamp() is in seconds
local BACKOFF = 10              -- BACKOFF time after timed out for setting ultimate percent ordering

local _logger = nil
local widget = nil
local play_sound = false
local curstyle = ""
local registered = false
local namelen = 12
local topleft = 25
local swimlanerow

local SWIMLANEULTMAX = 24

local forcepct = nil
local sldebug = false

local group_members = {}

local ping_refresh

local POC_Lane = {}
POC_Lane.__index = POC_Lane

local POC_Player = {
    Lane = nil
}
POC_Player.__index = POC_Player

local POC_Lanes = {
    Players = nil
}
POC_Lanes.__index = POC_Lanes

-- Table POC_Swimlanes
--
POC_Swimlanes = {
    IsMocked = false,
    Name = "POC-Swimlanes",
    Lanes = nil,
    SavedLanes = {},
    UltPct = nil,
    WasActive = false,
}
POC_Swimlanes.__index = POC_Swimlanes

local _this = POC_Swimlanes

if POC_UltNumber == nil then
    POC_UltNumber = {}  -- Just for linux
end
POC_UltNumber.ishidden = nil

local function _noop()
end

local xxx = d

-- Sets visibility of labels
--
function POC_Lanes:Refresh()
    -- if x ~= nil and what ~= nil then
    --    xxx("POC_Lanes:Refresh " .. tostring(what) .. " = '" .. x .. "'")
    -- end
    local refresh
    if (POC_GroupHandler.IsGrouped()) then
        refresh = true
        self.MIA:CheckGroup()
    elseif (not _this.WasActive) then
        refresh = false
    else
        refresh = true  -- just get rid of everything
        d("POC: No longer grouped")
        _this.SetControlActive()
        _this.WasActive = false
    end

    if refresh then
        -- Check all swimlanes
        local displayed = false
        for _,lane in ipairs(POC_IdSort(self, "Id")) do
            if lane:Refresh(_) then
                displayed = true
            else
                -- xxx("Didn't refresh " .. tostring(gid))
            end
        end
    end

    if displayed then
        -- displayed should be false if not grouped
        _this.SetControlActive()
        if (not _this.WasActive) then
            d("POC: now grouped")
        end
        _this.WasActive = true
    end
end

-- Return true if we timed out
--
function POC_Player:TimedOut()
    return (GetTimeStamp() - self.LastTimeStamp) > TIMEOUT
end

-- Check for absent group members
--
function POC_Lane:CheckGroup()
    for i = 1, 24, 1 do
        local unitid = "group" .. tostring(i)
        local unitname = GetUnitName(unitid)
        if unitname == nil or unitname:len() == 0 then
            break
        end
        if group_members[unitname] == nil then
            local player = {}
            player.PlayerName = unitname
            player.Lane = self
            player.UltGrp = {GroupAbilityId = 'MIA'}
            player.PingTag = unitid
            player.UltPct = 100
            POC_Player.new(player)
        end
    end
end

-- Refresh unpinged group members
--
function POC_Player:Refresh(name)
    for i = 1, 24, 1 do
        local unitid = "group" .. tostring(i)
        local unitname = GetUnitName(unitid)
        if unitname == nil or unitname:len() == 0 then
            break
        end
        if unitname == name then
            self.PingTag = unitid
            self.IsPlayerDead = IsUnitDead(unitid)
            self.UltPct = 100   -- who knows?
            break
        end
    end
end

-- Refresh swimlane
--
function POC_Lane:Refresh(n)
    local players = self.Players

    function sortval(player)
        local a
        if player:TimedOut() or IsGroupMemberInRemoteRegion(player.PingTag) then
            a = player.UltPct - 200
        elseif player.IsPlayerDead or player:TimedOut() then
            a = player.UltPct - 100
        else
            a = player.UltPct
        end
        return a
    end

    function compare(key1, key2)
        player1 = players[key1]
        player2 = players[key2]
        a = sortval(player1)
        b = sortval(player2)
        -- xxx("A " .. a)
        -- xxx("B " .. b)
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
    local i = 1
    local displayed = false
    for _, playername in ipairs(keys) do
        local player = players[playername]
        if player:TimedOut() then
            player:Refresh(playername)
        end
        local player_grouped =  IsUnitGrouped(player.PingTag)
        if not player_grouped or player.Lane ~= self then
            self.Players[playername] = nil
            if not player_grouped then
                group_members[playername] = nil
            end
        else
            if i > POC_Settings.SavedVariables.SwimlaneMax then
                -- log here?
                break
            end
            displayed = true
            if not player.IsMe then
                self:UpdateCell(i, player, playername)
                -- xxx(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
            else
                local not100
                if forcepct ~= nil then
                    player.UltPct = forcepct
                    _this.UltPct = forcepct
                    not100 = player.UltPct  < 100
                elseif player.UltPct  < 100 or (player.Backoff ~= nil and GetTimeStamp() < player.Backoff) then
                    _this.UltPct = nil
                    if player.UltPct > 100 then
                        player.UltPct = 100
                    end
                    not100 = true
                elseif player.IsPlayerDead then
                    _this.UltPct = 100
                else
                    _this.UltPct = 101 + POC_Settings.SavedVariables.SwimlaneMax - i
                    player.UltPct = _this.UltPct
                    player.Backoff = nil
                end
                -- xxx(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
                self:UpdateCell(i, player, playername)
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
            i = i + 1
        end
    end

    -- Clear any abandonded cells
    for i = i, POC_Settings.SavedVariables.SwimlaneMax, 1 do
        local row = self.Control:GetNamedChild("Row" .. i)
        if (not row:IsHidden()) then
            row:SetHidden(true)
        end
    end

    if (n == 7) then
        local hide = not displayed
        self.Button:SetHidden(hide)
        self.Icon:SetHidden(hide)
        self.Label:SetHidden(hide)
    end

    return displayed
end

-- Update a cell
--
function POC_Lane:UpdateCell(i, player, playername)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Lane:UpdateCell")
    end

    local row = self.Control:GetNamedChild("Row" .. i)
    local nameLength = string.len(playername)

    if (nameLength > namelen) then
        playername = string.sub(playername, 0, namelen) .. '..'
    end

    if (not player.IsPlayerDead and IsUnitInCombat(player.PingTag)) then
        playername = "|cff0000" .. playername .. "|r"
    end

    if (sldebug) then
        playername = playername .. "   " .. player.UltPct .. "%"
    end

    local ultpct
    if player.UltPct > 100 then
        ultpct = 100
    else
        ultpct = player.UltPct
    end

    local alivealpha
    local deadalpha
    local inprogressalpha
    if not IsUnitInGroupSupportRange(player.PingTag) then
        alivealpha = .5
        deadalpha = .4
        inprogressalpha = .4
    else
        alivealpha = 1
        deadalpha = .8
        inprogressalpha = .7
    end

    row:GetNamedChild("SenderNameValueLabel"):SetText(playername)
    row:GetNamedChild("UltPctStatusBar"):SetValue(ultpct)

    if (player.IsPlayerDead) then
        -- Dead Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, .8)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.03, 0.03, deadalpha)
    elseif player:TimedOut(player) then
        row:GetNamedChild("SenderNameValueLabel"):SetColor(0.8, 0.8, 0.8, 0.7)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.8, 0.8, 0.7)
    elseif (player.UltPct >= 100) then
		-- Ready Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 1)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.7, 0.03, alivealpha)
    else
		-- In-progress Color
        row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 0.8)
        row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.03, 0.7, inprogressalpha)
    end

    if (row:IsHidden()) then
        row:SetHidden(false)
    end
end

-- Updates player (potentially) in the swimlane
--
function POC_Player.new(inplayer)
    if _this.Lanes == nil then
        return
    end
    local name = inplayer.PlayerName
    local self = group_members[name]
    if self == nil then 
        self = setmetatable({}, POC_Player)
        group_members[name] = self
        self.LastTimeStamp = 0
        self.IsMe = name == GetUnitName("player")
    end
    self.InCombat = IsUnitInCombat(inplayer.PingTag)
    self.Online = IsUnitOnline(inplayer.PingTag)

    local changed = false
    local orig_swimlane = self.Lane
    local skip_refresh
    if inplayer.Lane ~= nil then
        skip_refresh = true
    else
        inplayer.Lane = _this.Lanes[inplayer.UltGrp.GroupAbilityId]
        if inplayer.Lane == nil then
            inplayer.Lane = 'MIA'
        end
    end

    -- Don't need these
    inplayer.PlayerName = nil
    inplayer.UltGrp = nil
    for n,v in pairs(inplayer) do
        if self[n] == nil or self[n] ~= v then
            -- xxx(tostring(n) .. "=" .. tostring(v))
            changed = true
            self[n] = v
        end
    end

    self.LastTimeStamp = GetTimeStamp()

    if not self.IsMe or not self:TimedOut() then
        self.Backoff = 0
    else
        self.Backoff = GetTimeStamp() + BACKOFF
    end

    if self.Lane.Players[name] == nil then
        self.Lane.Players[name] = self
    end

    if not skip_refresh then
        _this.Lanes:Refresh()
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function _this.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlanes.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    widget:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    widget:SetMovable(isMovable)
    widget:SetMouseEnabled(isMovable)
end

-- RestorePosition sets widget position
--
function _this.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlanes.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

    widget:ClearAnchors()
    widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

-- Saves current widget position to settings
--
function _this.OnSwimlaneListMoveStop()
    if LOG_ACTIVE then
        _logger:logTrace("POC_Swimlanes.OnSwimlaneListMoveStop")
    end

    local left = widget:GetLeft()
    local top = widget:GetTop()
	
    POC_Settings.SavedVariables.PosX = left
    POC_Settings.SavedVariables.PosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", POC_Settings.SavedVariables.PosX, POC_Settings.SavedVariables.PosY)
    end
end

-- Set hidden on control
--
function _this.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlanes.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (POC_GroupHandler.IsGrouped()) then
        widget:SetHidden(isHidden)
    else
        widget:SetHidden(true)
    end
end

-- Style changed
--
function _this.StyleChanged()
    local style = POC_Settings.SavedVariables.Style
    if (style ~= curstyle) then
        if curstyle ~= "" then
            _this.SetControlHidden(true)
        end
        curstyle = style
        if (widget ~= nil) then
            widget:SetHidden(true)
        end
        if (style == "Compact") then
            widget = POC_CompactSwimlaneControl
            swimlanerow = "CompactGroupUltimateSwimlaneRow"
            namelen = 6
            topleft = 50
        else
            widget = POC_SwimlaneControl
            swimlanerow = "GroupUltimateSwimlaneRow"
            namelen = 12
            topleft = 25
        end
        if (_this.SavedLanes[style] ~= nil) then
            _this.Lanes = _this.SavedLanes[style]
        else
            _this.SavedLanes[style] = POC_Lanes.new()
            _this.Lanes = _this.SavedLanes[style]
            _this.SetControlMovable(POC_Settings.SavedVariables.Movable)
            _this.RestorePosition(POC_Settings.SavedVariables.PosX, POC_Settings.SavedVariables.PosY)
            -- xxx("Saved new swimlane")
        end
        _this.SetControlActive()
    end
end

-- SetControlActive sets hidden on control
--
function _this.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlanes.SetControlActive")
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

        -- EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, _this.RefreshAll)

        CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, POC_Player.new)
        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, _this.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
        CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, _this.SetControlHidden)
    elseif (registered) then
        registered = false
        -- Stop timeout timer
        -- EVENT_MANAGER:UnregisterForUpdate(_this.Name)

        -- CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, _this.RefreshAll)
        CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, POC_Player.new)
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, _this.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
        CALLBACK_MANAGER:UnregisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, _this.SetControlHidden)
    end
end

-- OnSetUltGrp called on header clicked
--
function _this.OnSetUltGrp(ult, id)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Swimlanes.OnSetUltGrp")
        _logger:logDebug("group.GroupName, swimlaneId", group.GroupName, swimlaneId)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltGrp)


    if ult ~= nil and id ~= nil then
        POC_Settings.SetSwimlaneUltGrpIdSettings(id, ult)
    else
        _logger:logError("POC_Swimlanes.OnSetUltGrp: error ult " .. tostring(ult) .. " id " .. tostring(id))
    end
end

-- SetSwimlaneUltimate sets the swimlane header icon in base of gid
--
function POC_Lanes:SetUlt(id, newult)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Lanes.SetUlt")
        _logger:logDebug("ult.GroupName, swimlaneId", newult.GroupName, id)
    end

    local newgid = newult.GroupAbilityId
    for gid, lane in pairs(self) do
        if lane.Id == id then
            self[newgid] = lane -- New row
            local icon
            lane.Icon:SetTexture(GetAbilityIcon(newgid))
            lane.Label:SetText(newult.GroupName)
            self[gid] = nil     -- Delete old row
            break
        end
    end
end

-- POC_Lane:Click called on header clicked
--
function POC_Lane:Click()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Lane:Click")
        _logger:logDebug("Id", self.Id)
    end

    if (self.Button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, _this.OnSetUltGrp)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, self.Button, self.Id)
    else
        _logger:logError("POC_Lane:Click, button nil")
    end
end

-- Create a swimlane list headers
--
function POC_Lane.new(lanes, i)
    local self = setmetatable({}, POC_Lane)

    self.Id = i

    local gid = POC_Settings.SavedVariables.SwimlaneUltGrpIds[i]
    local ult = POC_UltGrpHandler.GetUltGrpByAbilityId(gid)

    self.Control = widget:GetNamedChild("Swimlane" .. i)

    if (ult == nil) then
        -- Pretty screwed up if this is true
        _logger:logError("POC_Lane.new, ult nil.")
        return
    end
    -- Add button
    self.Button = self.Control:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
    if i ~= 'MIA' then
        self.Button:SetHandler("OnClicked", function() self:Click() end)
    end
    self.Icon = self.Control:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
    local icon
    if ult.GroupAbilityId == 'MIA' then
        icon = "/POC/icons/lollipop.dds"
    else
        icon = GetAbilityIcon(ult.GroupAbilityId)
    end
    self.Icon:SetTexture(icon)

    self.Label = self.Control:GetNamedChild("Header"):GetNamedChild("UltimateLabel")
    if (self.Label ~= nil) then
        self.Label:SetText(ult.GroupName)
    end

    lanes[ult.GroupAbilityId] = self

    local last_row = self.Control
    for i = 1, SWIMLANEULTMAX, 1 do
        local row = CreateControlFromVirtual("$(parent)Row", self.Control, swimlanerow, i)
        if LOG_ACTIVE then
            _logger:logDebug("Row created " .. row:GetName())
        end

        row:SetHidden(true) -- not visible initially

        if (i == 1) then
            row:SetAnchor(TOPLEFT, last_row, TOPLEFT, 0, topleft)
        elseif (i == 5) then -- Fix pixelbug, Why the hell ZOS?!
            row:SetAnchor(TOPLEFT, last_row, BOTTOMLEFT, 0, 0)
        else
            row:SetAnchor(TOPLEFT, last_row, BOTTOMLEFT, 0, -1)
        end
        last_row = row
    end
    self.Players = {}
end

function POC_Lanes.new()
    local self = setmetatable({}, POC_Lanes)
    for i = 1, SWIMLANES, 1 do
        POC_Lane.new(self, i)
    end
    POC_Lane.new(self, 'MIA')
    return self
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
        logger:logTrace("POC_Swimlanes.Initialize")
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
    local x= getmetatable(_this.Lanes)
    _this.Lanes:Refresh()

    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, _this.StyleChanged)
    CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, function () _this.Lanes:Refresh() end)
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
            EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, function () _this.Lanes:Refresh() end)
            d("refresh on")
        else
            EVENT_MANAGER:UnregisterForUpdate(_this.Name)
            d("refresh off")
        end
    end
 end
