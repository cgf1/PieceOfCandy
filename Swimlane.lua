setfenv(1, POC)
local collectgarbage = collectgarbage
local CreateControlFromVirtual = CreateControlFromVirtual
local FormatTimeSeconds = FormatTimeSeconds
local GetAbilityDuration = GetAbilityDuration
local GetGroupSize = GetGroupSize
local GetTimeStamp = GetTimeStamp
local GetUnitDisplayName = GetUnitDisplayName
local GetUnitName = GetUnitName
local InitializeTooltip = InitializeTooltip
local IsUnitDead = IsUnitDead
local IsUnitGroupLeader = IsUnitGroupLeader
local IsUnitGrouped = IsUnitGrouped
local IsUnitInCombat = IsUnitInCombat
local IsUnitInGroupSupportRange = IsUnitInGroupSupportRange
local IsUnitOnline = IsUnitOnline
local PlaySound = PlaySound
local SCENE_MANAGER = SCENE_MANAGER
local SOUNDS = SOUNDS
local table = table
local WINDOW_MANAGER = WINDOW_MANAGER
local ZO_ObjectPool_CreateControl = ZO_ObjectPool_CreateControl
local ZO_DeepTableCopy = ZO_DeepTableCopy

local tt = POC_CharTooltip

local TIMEOUT = 10		-- GetTimeStamp() is in seconds
local INRANGETIME = 120		-- Reset ultpct if not inrange for at least this long
local REFRESH_IF_CHANGED = 1
local MAXPLAYSOUNDTIME = 60
local GARBAGECOLLECT = 60 * 3

local widget = nil
local mvc = nil
local cellpool = nil
local namelen = 12
local topleft = 25
local swimlanerow

local SWIMLANEULTMAX = 24
local SWIMLANEPCTADD = 100 + SWIMLANEULTMAX

local myults
local forcepct = nil
local sldebug = false

local maxping

local version
local dversion

local group_members

local ping_refresh = false

local tick = 0

local icon_size = {25, 25}

local max_x = 0
local max_y = 0

local Col = {
}
Col.__index = Col

local MIA = {}

local mias = 6
local miasper = 24 / mias

local ultn

local stats

local ultm_isactive

local play_sound = false
local last_played = 0
Player = {
    IsMe = false,
    Pos = 0,
    TimeStamp = 0,
    Ults = {},
}
Player.__index = Player

local me = setmetatable({
    DispName = {},
    InRangeTime = 0,
    IsDead = false,
    IsMe = true,
    Pos = 0,
    Tick = 0,
    TimeStamp = 0,
    UltMain = 0,
    Ults = {},
    Visited = false
}, Player)
Me = me

local myname = GetUnitName("player")
local ultix = myname

local Cols = {}
Cols.__index = Cols

local maxcols = 0
local maxrows = 0

local saved

local dumpme

-- Table Swimlanes
--
Swimlanes = {
    Name = "POC-Swimlanes",
}
Swimlanes.__index = Swimlanes

local swimlanes = Swimlanes

local need_to_fire = true

local msg = d
local d = nil

local function widget_should_be_visible()
    if not (Group.IsGrouped() and Comm.IsActive()) then
	return false
    else
	return (not saved.OnlyAva) or IsInCampaign()
    end
end

-- set_widget_movable sets the Movable and MouseEnabled flag in UI elements
--
local function set_widget_movable()
    local movable = saved.AllowMove
    if movable == nil then
	movable = true
    end
    widget:SetMovable(movable)
    widget:SetMouseEnabled(movable)
end

function ultn_save_pos()
    saved.UltNumberPos = {ultn:GetLeft(),ultn:GetTop()}
end

local function ultn_hide(x)
    if saved.UltNumberShow then
	if not x and me.IsDead or me.UltMain == 0 or me.Ults[me.UltMain] == nil or me.Ults[me.UltMain] < 100 then
	    x = true
	end
	ultn:SetHidden(x)
    end
end

local function ultn_show(n, ready)
    if not saved.UltNumberShow then
	ultn:SetHidden(true)
	return
    end
    local color
    if not ready then
	color = "6F6F6F"
    elseif n == 1 then
	color = "00ff00"
    else
	color = "ff0000"
    end
    ultn:SetText(string.format("|c%s#%s|r", color, tostring(n)))
    ultn:SetHidden(false)
    if not ready then
	return
    end
    local timenow = GetTimeStamp()
    if ((GetTimeStamp() - last_played) < MAXPLAYSOUNDTIME) then
	play_sound = false
	return
    end
    if n ~= 1 or not play_sound or not saved.WereNumberOne then
	return
    end
    PlaySound(SOUNDS.DUEL_START)
    last_played = GetTimeStamp()
    play_sound = false
    -- xxx("sound", play_sound)
    me.Because = "false because we played the sound"
end

-- Set hidden on control
--
local fragment
local function show_widget(showit)
    showit = showit and widget_should_be_visible()
    if scene_showing ~= showit then
	scene_showing = showit
	if not showit then
	    SCENE_MANAGER:GetScene("hud"):RemoveFragment(fragment)
	    SCENE_MANAGER:GetScene("hudui"):RemoveFragment(fragment)
	    SCENE_MANAGER:GetScene("siegeBar"):RemoveFragment(fragment)
	    -- SCENE_MANAGER:GetScene("worldMap"):RemoveFragment(fragment)
	    -- widget:SetHidden(true)
	else
	    SCENE_MANAGER:GetScene("hud"):AddFragment(fragment)
	    SCENE_MANAGER:GetScene("hudui"):AddFragment(fragment)
	    SCENE_MANAGER:GetScene("siegeBar"):AddFragment(fragment)
	    -- SCENE_MANAGER:GetScene("worldMap"):AddFragment(fragment)
	    -- widget:SetHidden(false)
	end
    end
end

-- restore_position sets widget position
--
local function restore_position()
    if saved.WinPos == nil then
	widget:GetNamedChild("MovableControl"):SetHidden(false)
    else
	widget:ClearAnchors()
	widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, saved.WinPos.X, saved.WinPos.Y)
    end
end

function swimlanes.Sched(clear_dispname)
    need_to_fire = true
    watch("need_to_fire", "swimlanes.Sched")
    if clear_dispname and group_members then
	for _, v in pairs(group_members) do
	    v.DispName[true] = nil
	    v.DispName[false] = nil
	end
    end
end

local function clear(verbose)
    saved.GroupMembers = {}
    group_members = saved.GroupMembers
    me.Ults = {}
    me.Pos = 0
    forcepct = nil
    ping_refresh = false
    sldebug = false
    RunClear(gc)
    local msg
    local n = collectgarbage("count")
    collectgarbage()
    n = n - collectgarbage("count")
    msg = string.format("memory cleared: freed %d Kbytes", n)
    if verbose then
	Info(msg)
    end
end

local function dump(name)
    local found = false
    local function time(t)
	local p
	if t == 0 then
	    p = 'never'
	else
	    local duration = GetTimeStamp() - t
	    p = FormatTimeSeconds(duration, TIME_FORMAT_STYLE_DURATION , TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_NONE)
	end
	return p
    end
    for n, v in pairs(group_members) do
	if string.find(n, name, 1) then
	    msg(string.format("== %s ==", n))
	    local a = {}
	    for n in pairs(v) do
		table.insert(a, n)
	    end
	    table.sort(a)
	    for _, x in ipairs(a) do
		local t = v[x]
		local p
		if x == 'InRangeTime' then
		    p = time(t)
		elseif x == 'TimeStamp' then
		    p = time(t)
		elseif x == 'Ults' then
		    x = "Ults"
		    p = ''
		    local comma = ''
		    for n, v in pairs(t) do
			local ult = Ult.ByPing(n)
			if not ult.IsMIA then
			    p = string.format("%s%s%s[%s%%]", p, comma, ult.Desc, v)
			    comma = ', '
			end
		    end
		else
		    p = tostring(t)
		end
		msg(string.format("%s: %s", x, p))
	    end
	    found = true
	end
    end
    if not found then
	msg("not found")
    end
end

local function showcols()
    local showall = ultm_isactive()
    return saved.ShowUnusedCols or showall, showall
end

-- Sets visibility of labels
--
local gc = GARBAGECOLLECT
local wasactive = false
local tickdown = 20
local scene_showing
local lastcolseen = 0
local MIAshowing = false
function Cols:Update(x)
    local refresh
    local displayed = false
    local oldmax_x, old_max_y = max_x, max_y
    if x == "left" then
	need_to_fire = true
	watch("need_to_fire", "left")
    elseif x == "joined" then
	need_to_fire = true
	watch("need_to_fire", "joined")
    end
    if x ~= 'off' and Group.IsGrouped() then
	refresh = Player.Update(true)
	displayed = not wasactive
    elseif not wasactive then
	refresh = false
    else
	if not Group.IsGrouped() then
	    msg("POC: No longer grouped")
	end
	clear(false)
	show_widget(false)
	wasactive = false
	Comm.Unload()
	return
    end

    tickdown = tickdown - 1
    if tickdown <= 0 then
	tickdown = 20
	refresh = true
    end
    watch("Cols:Update", x, 'refresh', refresh, 'wasactive', wasactive)
    local showunused, showall = showcols()
    if refresh or showall then
	watch("refresh")
	-- Check all swimlanes
	tick = tick + 1
	max_x = 0
	max_y = 60
	local col = 1
	local ncolseen = 0
	for _, v in ipairs(self) do
	    local didit, finished = v:Update(tick, col, showunused, showall, maxrows)
	    if didit then
		displayed = true
		if col <= maxcols then
		    ncolseen = col
		end
		col = col + 1
	    end
	    if not showall and col >= lastcolseen and (finished or col > maxcols) then
		break
	    end
	end
	if saved.MIA and (MIAshowing or not finished) then
	    MIAshowing = false
	    for i,v in ipairs(MIA) do
		if v:Update(tick, col, false, false, miasper) then
		    MIAshowing = true
		elseif col >= lastcolseen then
		    break
		end
		ncolseen = col
		col = col + 1
	    end
	end
	lastcolseen = ncolseen
    end

    if displayed then
	-- displayed should be false if not grouped
	if not wasactive then
	    msg("POC: now grouped")
	    Comm.Load()
	end
	wasactive = true
    end
    local show = widget_should_be_visible()
    if show ~= scene_showing then
	show_widget(show)
    end
    if max_x ~= oldmax_x or max_y ~= oldmax_y then
	local bigx = max_x + 16
	local bigy = max_y + 16
	widget:SetDimensions(bigx, bigy)
	mvc:SetDimensionConstraints(0, 0, bigx, bigy)
	mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, max_x, bigy)
    end
end

-- Return true if we timed out
--
function Player:TimedOut(timestamp)
    if timestamp == nil then
	timestamp = GetTimeStamp()
    end
    local timedout = (timestamp - self.TimeStamp) > TIMEOUT
    if timedout then
	self.HasTimedOut = true
    elseif self.HasTimedOut then
	Comm.SendVersion()
	self.HasTimedOut = false
    end
    return timedout
end

-- Return true if we need to back the heck off
--
function Player:HasBeenInRange()
    return (GetTimeStamp() - self.InRangeTime) < INRANGETIME
end

-- Return true if player is in range of rest of group
--
function Player:IsInRange()
    return self.InRange and (self.InRangeTime == nil or self.InRangeTime > 0)
end

function plunk_not_mia(self, apid, tick)
    if self.Ults[apid] == nil then
	return false
    else
	self.Tick = tick
	return true
    end
end

function plunk_mia(self, apid, tick)
    if self.Tick == tick then
	return false
    else
	self.Tick = tick
	return true
    end
end

local lane_apid
local function sortval_not_mia(key)
    local a
    local player = group_members[key]
    if player:TimedOut() then
	a = -2
    elseif player.IsDead then
	a = -1
    else
	a = player.Ults[lane_apid] or 0
    end
    return a, player
end

local function compare_mia(key1, key2)
    return key1 < key2
end

local function compare_not_mia(key1, key2)
    local a, player1 = sortval_not_mia(key1)
    local b, player2 = sortval_not_mia(key2)
    if a == b then
	return player1.PingTag < player2.PingTag
    else
	return a > b
   end
end

local function onmouse_cell(t)
    local tooltip
    local player, playername = unpack(t.PlayerInfo)
    local tooltip = {}
    if player and playername then
	local version = player.Version
	if not version then
	    version = "unknown"
	end
	local seconds
	if player.TimeStamp and player.TimeStamp ~= 0 then
	    seconds = string.format("%d seconds ago", GetTimeStamp() - player.TimeStamp, ' seconds')
	else
	    seconds = "hasn't pinged yet"
	end
	local inrange
	if player:IsInRange() then
	    inrange = 'yes'
	else
	    inrange = 'no'
	end
	local disp = {
	    'Name', playername,
	    'Display Name', GetUnitDisplayName(player.PingTag),
	    'Class', GetUnitClass(player.PingTag),
	    'Version', version,
	    'Last Seen', seconds,
	    'In Range', inrange,
	    'Zone', GetUnitZone(player.PingTag)
	}
	if player.FwCampTimer and player.FwCampTimer ~= 0 then
	    disp[#disp + 1] = 'Camp Avail'
	    disp[#disp + 1] = player.FwCampTimer .. ' seconds'
	end
	if player.Pos and player.Pos ~= 0 then
	    disp[#disp + 1] = 'Queue Position'
	    disp[#disp + 1] = player.Pos
	end
	local ultn = #disp + 1
	for n, v in pairs(player.Ults) do
	    local tag
	    local ix
	    if n == player.UltMain then
		ix = ultn
		tag = 'Ultimate #1'
	    else
		ix = ultn + 2
		tag = 'Ultimate #2'
	    end
	    disp[ix] = tag
	    if n == 0 or n == maxping or n == 'MIA' then
		disp[ix + 1] = 'not set'
	    else
		disp[ix + 1] = string.format("%s (%d%%)", Ult.ByPing(n).Desc, v)
	    end
	end
	if ultn > #disp then
	    disp[ultn] = 'Ultimate #1'
	    disp[ultn + 1] = 'not set'
	end

	local fmtlen = 0
	for i = 1, #disp, 2 do
	    disp[i] = disp[i] .. ':'
	    if disp[i]:len() > fmtlen then
		fmtlen = disp[i]:len()
	    end
	end
	local fmt = '%-' .. fmtlen .. 's %s'
	for i = 1, #disp, 2 do
	    tooltip[#tooltip + 1] = string.format(fmt, disp[i], disp[i + 1]);
	end
    end
    local control = t.Control
    if not control.data then
	control.data = {}
    end

    InitializeTooltip(tt, control, LEFT, -2, 0, RIGHT)
    tt:AddLine(table.concat(tooltip, "\n"), "EsoUI/Common/Fonts/consola.ttf|14|thin-outline", 1, 1, 1)
end

local function create_cell(pool)
    local control = ZO_ObjectPool_CreateControl('POC_Cell', pool, widget)
    control:SetMouseEnabled(true)
    local t = {
	Backdrop = control:GetNamedChild("Backdrop"),
	Control = control,
	Name = control:GetNamedChild("PlayerName"),
	PlayerInfo = {},
	UltPct = control:GetNamedChild("UltPct")
    }
    if saved.Tooltips then
	control:SetHandler("OnMouseEnter", function ()	onmouse_cell(t) end)
	control:SetHandler("OnMouseExit", function () ClearTooltip(tt) end)
    end
    return t
end

local function reset_cell(tbl)
    tbl.Control:SetHidden(true)
    tbl.Control:ClearAnchors()
end


function Col:Info(col, row)
    local sizex = icon_size[1]
    local sizey = icon_size[2]
    if saved.Style == 'Standard' and not self.Moused then
	sizex = sizex + 75	-- room for text
    else
	sizex = sizex + 27
    end
    local x = (col - 1) * (sizex + 2)
    local y = row * (sizey + 2)
    return x, y, sizex, sizey
end


-- Update swimlane
--
local keys = {}
function Col:Update(tick, col, showunused, showall, maxrow)
    local displayed = showunused
    local apid = self.Apid
    local isMIA = apid == maxping
    lane_apid = apid

    self.Moused = showall
    self.Col = col

    local plunk = self.Plunk
    local keys = keys
    local ticked = 0
    local grouped = 0
    for name, player in pairs(group_members) do
	local pingtag = player.PingTag
	if (not IsUnitGrouped(pingtag)) or GetUnitName(pingtag) ~= name then
	    group_members[name] = nil
	else
	    grouped = grouped + 1
	    if plunk(player, apid, tick) then
		keys[#keys + 1] = name
	    elseif player.Tick == tick then
		ticked = ticked + 1
	    end
	end
    end

    local finished = not showunused and grouped == ticked

    if #keys > 1 then
	table.sort(keys, self.Compare)
    end

    -- Update sorted swimlane
    local gt100 = SWIMLANEPCTADD
    local n = 1
    while true do
	local playername = table.remove(keys, 1)
	if playername == nil then
	    break
	end
	local player = group_members[playername]
	local priult = player.UltMain == apid
	displayed = true
	local y
	if not player.IsMe or not priult or isMIA then
	    y = self:UpdateCell(n, player, playername, isMIA or priult)
	    if not isMIA and player.Ults[apid] and player.Ults[apid] > 100 then
		gt100 = player.Ults[apid]
	    end
	else
	    local ready
	    if forcepct ~= nil then
		player.Ults[apid] = forcepct
	    end
	    if player.Ults[apid]  < 100 then
		play_sound = true
		me.Because = "ultpct < 100"
		ready = false
	    elseif priult and not player.IsDead and player:IsInRange() then
		player.Ults[apid] = gt100 - 1
		me.Because = "ultpct == 100"
		ready = true
	    else
		-- reset order since we can't contribute
		if player.Ults[apid] > 100 then
		    player.Ults[apid] = 100
		end
		play_sound = true
		me.Because = "out of range or dead"
		ready = false
	    end
	    y = self:UpdateCell(n, player, playername, priult)
	    ultn_show(n, ready)
	end
	if y > max_y then
	    max_y = y
	end
	n = n + 1
	if n > maxrow then
	    if not isMIA then
		while table.remove(keys, 1) ~= nil do end
	    end
	    -- log here?
	    break
	end
    end

    if displayed then
	local x, y, sizex, sizey = self:Info(col + 1, 0)
	max_x = x
    end

    -- Clear any abandonded cells
    while self[n] do
	cellpool:ReleaseObject(table.remove(self, n))
    end

    self:SetHeader(displayed and col)

    self.Moused = false
    return displayed, finished
end

local alivealpha = 1.0
local deadalpha = 0.8
local inprogressalpha = 0.8
local normal = {
    [true] = {		-- It's the primary
	[true] = {		-- >= 100
	    center = {0.51, 0.41, 0.65},
	    name = {1, 1, 1, 1},
	    ult = {0.01, 0.69, 0.02, alivealpha}
	},
	[false] = {		-- < 100
	    center = {0.51, 0.41, 0.65},
	    name = {1, 1, 1, 0.8},
	    ult = {0.03, 0.03, 0.7, inprogressalpha},
	},
    },
    [false] = {		-- secondary
	 [true] = {		-- >= 100
	    center = {0.51, 0.63, 0.90},
	    name = {1, 1, 1, 1},
	    ult = {0.18, 0.42, 0.96, alivealpha},
	 },
	 [false] = {	-- < 100
	    center = {0.51, 0.63, 0.90},
	    name = {1, 1, 1, 0.8},
	    ult = {0.18, 0.42, 0.96, alivealpha}
	}
    }
}
local timedout = {
    center = {0.15, 0.15, 0.15},
    name = {1, 1, 1, 1},
    ult = {0.80, 0.80, 0.80, 2}
}
local isdead = {
    center = normal[true][true].center,
    name = {0.8, 0.8, 0.8, 0.8},
    ult = {0.8, 0.03, 0.03, deadalpha}
}

local tmp_colors = {}
local function colors(inrange, tbl)
    local ret = tmp_colors
    for i, x in ipairs(tbl) do
	if inrange then
	    -- ok
	elseif i < 4 then
	    x = x * 0.55
	else
	    x = x * 0.85
	end
	ret[i] = x
    end
    if #ret > #tbl then
	ret[#tbl + 1] = nil
    end
    return unpack(ret)
end

-- Update a cell
--
function Col:UpdateCell(i, player, playername, priult)
    local col = self.Col
    rowtbl, key = cellpool:AcquireObject(self[i])
    local row = rowtbl.Control
    local bgcell = rowtbl.Backdrop
    local namecell = rowtbl.Name
    local ultcell = rowtbl.UltPct
    if rowtbl.PlayerInfo.playername ~= playername then
	rowtbl.PlayerInfo[1] = player
	rowtbl.PlayerInfo[2] = playername
    end

    local x, y, sizex, sizey = self:Info(col, i)
    if not self[ix] then
	row:SetAnchor(TOPLEFT, widget, TOPLEFT, x, y)
	row:SetWidth(sizex)
	bgcell:SetWidth(sizex)
	ultcell:SetWidth(sizex)
	namecell:SetWidth(sizex)
	self[i] = key
    elseif self.X ~= x then
	row:ClearAnchors()
	row:SetAnchor(TOPLEFT, widget, TOPLEFT, x, y)
    end
    if saved.AtNames and player.AtName then
	playername = string.sub(player.AtName, 2)
    end

    local prefix
    if not player.IsDead and player.InCombat then
	prefix = '|cff0000'
    else
	prefix = ''
    end

    local ultpct
    local apid
    if self.Apid == 'MIA' then
	apid = player.UltMain
    else
	apid = self.Apid
    end

    if player.Ults[apid] == nil then
	ultpct = 0
    elseif player.Ults[apid] > 100 then
	ultpct = 100
    else
	ultpct = player.Ults[apid]
    end

    local values
    if player:TimedOut() then
	values = timedout
	watch("Col:UpdateCell", playername, "timedout")
    elseif player.IsDead then
	values = isdead
	watch("Col:UpdateCell", playername, "isdead")
    else
	values = normal[priult][ultpct >= 100]
	watch("Col:UpdateCell", playername, "normal", ultpct >= 100)
    end

    ultcell:SetValue(ultpct)
    local inrange = player:IsInRange()
    bgcell:SetCenterColor(colors(inrange, values.center))
    local font
    local stealthed = player.StealthState ~= 0
    local lastfont = namecell.Font
    if not stealthed then
	namecell.Font = "$(MEDIUM_FONT)|16|soft-shadow-thin"
    else
	namecell.Font = "$(GAMEPAD_MEDIUM_FONT)|16|thick-outline"
    end
    if lastfont ~= namecell.Font then
	namecell:SetFont(namecell.Font)
    end
    if not player.DispName[stealthed] then
	local toobig = false
	while namecell:GetStringWidth(playername) > sizex do
	    toobig = true
	    playername = playername:sub(1, -2)
	end

	if toobig then
	    local c = '·'
	    playername = playername:sub(1, -2) .. '|cffff00' .. c .. '|r'
	end
	player.DispName[stealthed] = playername
    end
    playername = player.DispName[stealthed]
    namecell:SetText(prefix .. playername)
    namecell:SetColor(colors(inrange, values.name))
    ultcell:SetColor(colors(inrange, values.ult))

    row:SetHidden(false)
    return y + sizey
end

function Player.MakeLeader(pingtag)
    local name = GetUnitName(pingtag)
    local dname= GetUnitDisplayName(pingtag)
    local player = group_members[name]
    if player ~= nil and me.IsLeader and (player.HasBeenLeader or saved.AutoAccept[name] or saved.AutoAccept[dname]) then
	GroupPromote(pingtag)
    end
end

local newversion_alert = 5
function Player.SetVersion(pingtag, major, minor, beta)
    if beta == 0 then
	beta = ''
    else
	beta = string.format("b%d", beta)
    end
    local v = string.format("%d.%03d", major, minor)
    local dv = string.format("%d.%d%s", major, minor, beta)
    watch("Player.Version", pingtag, v)
    local name = GetUnitName(pingtag)
    if group_members[name] ~= nil then
	group_members[name].Version = dv
    end
    if beta == '' and tonumber(v) > version then
	if newversion_alert > 0 then
	    Info(string.format("new version v%s detected (%s). You have v%s", dv, name, dversion))
	end
	newversion_alert = newversion_alert - 1
    end
end

local lrecord = {}
function Player:Record(name, what, newval, oldval)
    if not saved.RecordStats then
	return
    end
    lrecord[name] = lrecord[name] or {}
    local rtmp = lrecord[name]
    stats[name] = stats[name] or {}
    local srecord = stats[name]
    local now = GetTimeStamp()
    if what == 'InRange' and (self.IsMe or me:IsInRange()) then
	local other
	if  newval then
	    other = 'OutOfRange'
	else
	    what = 'OutOfRange'
	    other = 'InRange'
	end
	srecord[other] = srecord[other] or {}
	local swhat = srecord[other]
	local start = rtmp[other]
	rtmp[other] = nil
	if start then
	    swhat[start] = now - start
	end
	rtmp[what] = rtmp[what] or now
	return
    end
    if what == 'IsDead' then
	srecord[what] = srecord[what] or {}
	local swhat = srecord[what]
	if self.IsDead == newval then
	    return -- shouldn't happen
	end
	if not self.IsDead then
	    rtmp['is-dead'] = now
	else
	    local start = rtmp['is-dead']
	    rtmp['is-dead'] = nil
	    if start ~= nil then
		swhat[start] = now - start
	    end
	end
	return
    end
    if what == 'Primary Ult' then
	srecord[what] = srecord[what] or {}
	local swhat = srecord[what]
	oldval = oldval or 0
	if not rtmp['ult-start'] then
	    rtmp['ult-start'] = now
	elseif oldval < 100 and newval >= 100 then
	    local start = rtmp['ult-start']
	    rtmp['ult-start'] = nil
	    if start ~= nil then
		swhat[start] = now - start
	    end
	end
	return
    end
end

local tmp_player = {}
function Player.New(pingtag, timestamp, fwctimer, apid1, pct1, pos, apid2, pct2)
    local name = GetUnitName(pingtag)
    local self = group_members[name]
    watch("Player.New", name, pingtag, timestamp, apid1, pct1, apid2, pct2, pos, self)
    if self == nil then
	if name == myname then
	    self = me
	else
	    self = {
		DispName = {},
		IsMe = false,
		Pos = 0,
		Tick = 0,
		TimeStamp = 0,
		UltMain = maxping,
		Ults = {
		    [maxping] = 0
		},
		Version = 'unknown',
		Visited = false
	    }
	end
	group_members[name] = setmetatable(self, Player)
    end

    if timestamp ~= nil then
	if apid1 == 0 then
	    return			-- hopefully an anomaly
	end
    elseif not self.Visited then
	-- coming from Player.Update - haven't seen yet
    else
	self.Visited = false
	return self
    end

    local player = tmp_player
    player.InCombat = IsUnitInCombat(pingtag)
    player.InRange = IsUnitInGroupSupportRange(pingtag)
    player.IsLeader = IsUnitGroupLeader(pingtag)
    player.StealthState = GetUnitStealthState(pingtag)
    if player.IsLeader then
	player.HasBeenLeader = true
    end
    player.IsDead = IsUnitDead(pingtag)
    player.IsOnline = IsUnitOnline(pingtag)
    player.PingTag = pingtag
    player.UltMain = apid1
    player.Pos = pos
    -- Consider changed if we have a timestamp and timeout is detected
    local was_timedout = self.TimedOut
    local changed = false
    if not timestamp then
	changed = false
    else
	local was_timedout = self.HasTimedOut
	changed = was_timedout ~= self:TimedOut(timestamp)
	if changed then
	    watch("need_to_fire", name, "changed timestamp", was_timedout)
	end
	self.TimeStamp = timestamp
    end
    if saved.AtNames and self.AtName == nil then
	player.AtName = GetUnitDisplayName(pingtag)
	self.DispName[true] = nil
	self.DispName[false] = nil
    end

    if fwctimer ~= nil then
	player.FwCampTimer = fwctimer
    end
    if apid1 ~= nil then
	-- Coming from on_map_ping
	if self.IsMe and pct1 >= 100 and me.Ults ~= nil and me.Ults[apid1] ~= nil and me.Ults[apid1] >= 100 then
	    pct1 = me.Ults[apid1]	-- don't mess with our calculated percent
	end
	-- Called from map ping
	-- If either is nil then player changed their ultimate
	if self.Ults[apid1] == nil or apid2 ~= nil and self.Ults[apid2] == nil then
	    changed = true
	    for n in pairs(self.Ults) do
		self.Ults[n] = nil
	    end
	end
	if self.Ults[apid1] ~= pct1 then
	    changed = true
	    watch("need_to_fire", name, "apid1 different", apid1, self.Ults[apid1], '~=', pct1)
	    self:Record(name, 'Primary Ult', pct1, self.Ults[apid1])
	    self.Ults[apid1] = pct1		-- Primary ult pct changed
	end
	if apid2 ~= nil and self.Ults[apid2] ~= pct2 then
	    changed = true
	    watch("need_to_fire", name, "apid2 different", self.Ults[apid2], '~=', pct2)
	    self.Ults[apid2] = pct2		-- secondary ult pct changed
	end
    end

    for n, v in pairs(player) do
	player[n] = nil
	if self[n] ~= v then
	    changed = true
	    watch("need_to_fire", name, 'player vs. self', n, self[n], '~=', v)
	    self:Record(name, n, v)
	    self[n] = v
	end
    end

    self.Visited = apid1 ~= nil			-- Saw this this time around

    if changed then
	need_to_fire = true
	watch("need_to_fire", "changed")
    end

    return self
end

local unitnames = {
    'group1', 'group2', 'group3', 'group4', 'group5', 'group6', 'group7', 'group8',
    'group9', 'group10', 'group11', 'group12', 'group13', 'group14', 'group15', 'group16',
    'group17', 'group18', 'group19', 'group20', 'group21', 'group22', 'group23', 'group24'
}

-- Updates player in-range info
--
function Player.Update(clear_need_to_fire)
    local nmembers = 0
    local inrange = 0

    for i = 1, GetGroupSize() do
	local unitid = unitnames[i]
	local unitname = GetUnitName(unitid)
	if unitname ~= nil and unitname:len() ~= 0 then
	    nmembers = nmembers + 1
	    player = Player.New(unitid)
	    if player:TimedOut() then
		nmembers = nmembers - 1
	    elseif player.InRange then
		inrange = inrange + 1
	    elseif player.IsLeader then
		inrange = inrange - 1
	    end
	end
    end

    if me.IsLeader then
	inrange = inrange + 2
    end

    if (inrange / nmembers) >= 0.5 then
	me.InRangeTime = GetTimeStamp()
    elseif me.InRangeTime ~= 0 and not me:HasBeenInRange() then
	watch("need_to_fire", "inrange", me.InrangeTime)
	me.InRangeTime = 0
	need_to_fire = true
    end
    if dumpme ~= nil then
	dump(dumpme)
	dumpme = nil
    end

    local changed = sldebug or ping_refresh or need_to_fire
    if clear_need_to_fire then
	need_to_fire = false
    end
    return changed
end

-- Saves current widget position to settings
--
function swimlanes:OnMove(stop)
    if not stop then
	mvc:SetHidden(false)
    else
	mvc:SetHidden(true)
	saved.WinPos = {
	    X = widget:GetLeft(),
	    Y = widget:GetTop()
	}
    end
end

function Col:SetHeader(what)
    local showunused = self.Moused
    local twhat = type(what)
    local hide
    if type(what) == 'table' then
	self.Apid = what.Ping
	self.Icon:SetTexture(what.Icon)
	self.Control.data.tooltipText = what.Desc
	self.Name = what.Name
	hide = true
    elseif twhat == 'number' then
	local x, y = self:Info(what, 0)
	if self.X ~= x then
	    local control = self.Control
	    control:ClearAnchors()
	    control:SetAnchor(TOPLEFT, widget, TOPLEFT, x, y)
	    self.X = x
	end
	hide = false
    else
	hide = true
    end
    local text
    if saved.Style == 'Standard' and not showunused then
	text = self.Name
    else
	text = ''
    end
    if text ~= self.LastText then
	self.Label:SetText(text)
    end
    self.Control:SetHidden(hide)
end

local warned_ult = false
function Player.SetUlt()
    if GetActiveWeaponPairInfo() ~= 1 then
	return
    end
    if not myults then
	myults = Settings.SavedVariables.MyUltId[ultix]
    end
    local aid = GetSlotBoundId(8)
    local ult = Ult.ByAid(aid)
    if ult == nil then
	if not warned_ult then
	    Error(string.format("Can't translate ultimate '%s' to base ultimate.  Please report to esoui.com", GetAbilityName(aid)))
	    warned_ult = true
	end
	return
    end
    local pid = ult.Ping
    if pid ~= myults[1] then
	for n in pairs(me.Ults) do
	    me.Ults[n] = nil
	end
	me.UltMain = pid
	myults[1] = pid
	swimlanes.Sched(true)
    end
end

-- Called when header clicked to change column identifier
--
function Cols:SetLaneUlt(id, apid)
    watch("Cols:SetLaneUlt", id, apid)
    local switchi, switchv
    if apid ~= maxping then
	for i,v in ipairs(self) do
	    if v.Apid == apid then
		watch("Cols:SetLaneUlt", _, v.Apid, '==', apid)
		local oapid = saved.LaneIds[id]
		saved.LaneIds[i] = oapid
		self[i]:SetHeader(Ult.ByPing(oapid))
		break
	    end
	end
    end
    saved.LaneIds[id] = apid		-- Remember what's here
    self[id]:SetHeader(Ult.ByPing(apid))
end

-- Col:Click called on header clicked
--
function Col:Click()
    UltMenu.Show(self.Button, self.Id, self.Apid)
end

local function mouse_handler(self, on, what)
    if not on then
	ZO_Options_OnMouseExit(self)
    else
	ZO_Options_OnMouseEnter(self)
    end
end

-- Create icon/label at top of column
--
function Col.New(apid, i)
    local self = setmetatable({Id = i}, Col)
    local ult = Ult.ByPing(apid)

    local control = self.Control
    local button
    if control then
	button = self.Button
    else
	control = CreateControlFromVirtual('POCheader' .. i, widget, 'POC_Header')
	self.Control = control
	self.Button = control:GetNamedChild("Button")
	self.Icon = control:GetNamedChild("Icon")
	self.Label = control:GetNamedChild("Label")
	button = self.Button
	local data = {}
	control.data = data
	button.data = data
	self.Icon.data = data
	self.Label.data = data
    end

    control:SetMouseEnabled(true)
    button:SetHandler("OnMouseEnter", function(self) mouse_handler(self, true, "button mouse on") end)
    control:SetHandler("OnMouseEnter", function(self) mouse_handler(self, true, "control mouse on") end)
    button:SetHandler("OnMouseExit", function(self) mouse_handler(self, false, "button mouse off") end)
    control:SetHandler("OnMouseExit", function(self) mouse_handler(self, false, "control mouse off") end)

    if apid == maxping then
	self.Compare = compare_mia
	self.Plunk = plunk_mia
	button:SetHandler("OnClicked", nil)
    else
	self.Compare = compare_not_mia
	self.Plunk = plunk_not_mia
	button:SetHandler("OnClicked", function() self:Click() end)
    end

    self:SetHeader(ult)

    return self
end

function Cols:Redo()
    for _, v in ipairs(self) do
	v:SetHeader()
	-- Start fresh with any existing cells
	while v[1] do
	    cellpool:ReleaseObject(table.remove(v, 1))
	end
    end
    lastcolseen = 0
    maxrows = saved.SwimlaneMax
    maxcols = saved.SwimlaneMaxCols
    need_to_fire = true
    watch("need_to_fire", "Cols:Redo")
    swimlanes.Sched(true)
end

function Cols:New()
    maxrows = saved.SwimlaneMax
    maxcols = saved.SwimlaneMaxCols
    for i, apid in ipairs(saved.LaneIds) do
	self[i] = Col.New(apid, i)
    end
    for i = 1, mias do
	MIA[i] = Col.New(maxping, maxping + i - 1)
    end
    return self
end

local function getstats()
    if not stats and saved.RecordStats then
	stats = ZO_SavedVars:NewAccountWide('POCstats', 1, nil, {Version = 1})
    end
end

-- Initialize Swimlanes
--
swimlanes.Update = function(x) Cols:Update(x) end
swimlanes.SetLaneUlt = function(apid, icon) Cols:SetLaneUlt(apid, icon) end
swimlanes.Redo = function() Cols:Redo() end
function swimlanes.Initialize(major, minor, _saved)
    saved = _saved
    widget = POC_Main
    mvc = widget:GetNamedChild("MovableControl")
    widget:SetHidden(true)
    fragment = ZO_SimpleSceneFragment:New(widget)
    group_members = saved.GroupMembers
    myults = saved.MyUltId[ultix]
    ultm_isactive = UltMenu.IsActive
    if myults[1] == nil then
	myults[1] = maxping
    end
    maxping = Ult.MaxPing
    for n, v in pairs(group_members) do
	if n == myname then
	    v =	 ZO_DeepTableCopy(v, me)
	end
	setmetatable(v, Player)
	if not v.UltMain or v.UltMain == 0 then
	    v.UltMain = maxping
	end
	if not v.Ults[v.UltMain] then
	    v.UltMain = 0
	end
	if v.Pos == nil then
	    v.Pos = 0
	end
	if not v.DispName or v.DispName ~= 'table' then
	    v.DispName = {}
	else
	    v.DispName[true] = nil
	    v.DispName[false] = nil
	end

	group_members[n] = v
    end
    me.UltMain = myults[1]
    for n in pairs(me.Ults) do
	if n == myults[1] or n == myults[2] then
	    me.Ults[n] = 0
	else
	    me.Ults[n] = nil
	end
    end
    local ultids = {}
    local maxult = maxping - 1
    local newlaneids = {}
    for i = 1, maxult  do
	if saved.LaneIds[i] == 'MIA' then
	    table.remove(saved.LaneIds, i)
	    i = i - 1
	elseif saved.LaneIds[i] ~= nil then
	    ultids[saved.LaneIds[i]] = true
	else
	    for apid = 1, maxult do
		if not ultids[apid] then
		    saved.LaneIds[i] = apid
		    ultids[apid] = true
		    break
		end
	    end
	end
    end

    cellpool = ZO_ObjectPool:New(create_cell, reset_cell)

    Cols:New()
    restore_position()

    ultn = WM:CreateControl(nil, widget, CT_LABEL)
    ultn:SetHandler('OnMoveStop', ultn_save_pos)
    ultn:SetFont('$(BOLD_FONT)|40|soft-shadow-thick')
    ultn:ClearAnchors()

    if saved.UltNumberPos == nil then
	ultn:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	ultn:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.UltNumberPos[1],
				saved.UltNumberPos[2])
    end
    ultn:SetMovable(true)
    ultn:SetMouseEnabled(true)
    ultn_hide(true)

    getstats()

    version = tonumber(string.format("%d.%03d", major, minor))
    dversion = string.format("%d.%d", major, minor)
    Slash("show", "debugging: show the widget", function()
	widget:SetHidden(false)
    end)

    Slash("clear", "clear POC memory, run game garbage collection", function()
	clear(true)
    end)
    Slash("pct", "debugging: set fake ultimate percentage", function(pct)
	if string.len(pct) == 0 then
	    forcepct = nil
	else
	    forcepct = tonumber(pct)
	    need_to_fire = true
	end
    end)
    Slash("sldebug", "debugging: display percentages next to names", function(pct)
	sldebug = not sldebug
	msg(sldebug)
    end)
    Slash("refresh", "debugging: force periodic update of display", function(pct)
	ping_refresh = not ping_refresh
	if ping_refresh then
	    msg("refresh on")
	else
	    msg("refresh off")
	end
    end)
    Slash("movable", "specify true/false to make ultimate display movable", function(x)
	local movable
	if x == "yes" or x == "true" or x == "on" then
	    movable = true
	elseif x == "no" or x == "false" or x == "off" then
	    movable = false
	elseif x ~= "" then
	    Error("Huh?")
	    return
	end
	if movable ~= nil then
	    saved.AllowMove = movable
	    set_widget_movable()
	end
	Info("movable state is:", saved.AllowMove)
    end)
    Slash("sendver", "debugging: send POC add-on version to others in your group", function(x)
	Comm.SendVersion()
    end)
    Slash("dump", "debugging: show collected information for specified player", function(x) dumpme = x end)
    Slash("leader", "make me group leader", function()
	Comm.Send(COMM_TYPE_MAKEMELEADER)
    end)
    Slash("record", "turn recording of interesting statistics on/off", function(x)
	if x == "no" or x == "false" or x == "off" then
	    saved.RecordStats = false
	elseif x == "yes" or x == "true" or x == "on" then
	    saved.RecordStats = true
	    getstats()
	elseif x == "clear" then
	    for k in pairs(stats) do
		stats[k] = nil
	    end
	    Info("records cleared")
	elseif x ~= "" then
	    Error("Huh?")
	    return
	end
	Info("record state is:", saved.RecordStats)
    end)
end
