local BOTTOMLEFT = BOTTOMLEFT
local BOTTOMRIGHT = BOTTOMRIGHT
local CENTER = CENTER
local COMBAT_UNIT_TYPE_GROUP = COMBAT_UNIT_TYPE_GROUP
local COMBAT_UNIT_TYPE_OTHER = COMBAT_UNIT_TYPE_OTHER
local CT_LABEL = CT_LABEL
local DL_BACKGROUND = DL_BACKGROUND
local DT_LOW = DT_LOW
local GetUIGlobalScale = GetUIGlobalScale
local GuiRoot = GuiRoot
local LC = LibCombat
local LIBCOMBAT_EVENT_DAMAGE_OUT = LIBCOMBAT_EVENT_DAMAGE_OUT
local LIBCOMBAT_EVENT_FIGHTRECAP = LIBCOMBAT_EVENT_FIGHTRECAP
local LIBCOMBAT_EVENT_HEAL_OUT = LIBCOMBAT_EVENT_HEAL_OUT
local POC_Stats = POC_Stats
local TEXT_WRAP_MODE_TRUNCATE = TEXT_WRAP_MODE_TRUNCATE
local TOPLEFT = TOPLEFT
local TOPRIGHT = TOPRIGHT
local widget = POC_Stats
local WM = WINDOW_MANAGER

Stats = {
    Name = "POC-Stats",
    Refresh = false
}
local Stats = Stats
Stats.__index = Stats

local saved
local group_members

local mvc = widget:GetNamedChild("Movable")
local back = widget:GetNamedChild("Background")
local widgbot

local pairs = pairs

local function emptyfunc()
end

local damage = {}
local heal = {}
local rowlen
local damagetrk = {}
local healtrk = {}
setfenv(1, POC)
local Error, Info, Me, mysplit, namefit, ReloadUI, Slash, Visibility, watch

_ = ''	-- start parsing

local function sorter(a, b)
    local aname, aval = unpack(a)
    local bname, bval = unpack(b)
    if aval == bval then
	return aname < bname
    else
	return aval > bval
    end
end

local function dispcol(category, which, i)
    local label = which[i]
    if not label then
	local name = string.format("%s%02d", category, i)
	label = WM:CreateControl(name, widget, CT_LABEL)
	label:SetFont("$(MEDIUM_FONT)|16|soft-shadow-thin")
	label:SetAnchor(TOPLEFT, which[i - 1], BOTTOMLEFT, 0, 0)
	label:SetWrapMode(TEXT_WRAP_MODE_TRUNCATE)
	label:SetDrawLayer(DL_BACKGROUND)
	label:SetDrawTier(DT_LOW)
	local val = WM:CreateControl(name .. 'val', label, CT_LABEL)
	val:SetFont("EsoUI/Common/Fonts/consola.ttf|16|soft-shadow-thin")
	val:SetAnchor(TOPLEFT, label, TOPRIGHT, 0, 0)
	val:SetWrapMode(TEXT_WRAP_MODE_TRUNCATE)
	val:SetDrawLayer(DL_BACKGROUND)
	val:SetDrawTier(DT_LOW)
	which[i] = label
    end
    return label, label:GetChild(1)
end

local function dispall(category, which, tbl, tot, max)
    table.sort(tbl, sorter)
    local i = 1
    local fmt = '%' .. tostring(max):len() .. 'd'
    if saved.PctStats then
	fmt = fmt .. ' %2d%%'
    end

    while tbl[1] do
	local v = table.remove(tbl, 1)
	local label, val = dispcol(category, which, i)
	local dispval = string.format(fmt, v[2], 0.5 + (100 * (v[2] / tot)))
	local n = val:GetStringWidth(dispval) / GetUIGlobalScale();
	val:SetWidth(n)
	local namelen = rowlen - n
	label:SetWidth(namelen)
	local dispname = namefit(label, v[1], namelen)
	label:SetText(dispname)
	val:SetText(dispval)
	if label:GetBottom() > widgbot then
	    break
	end
	label:SetHidden(false)
	val:SetHidden(false)
	i = i + 1
    end
    while which[i] and not which[i]:IsHidden() do
	local label, val = which[i], which[i]:GetChild(1)
	label:SetHidden(true)
	val:SetHidden(true)
	label:SetText('')
	val:SetText('')
	i = i + 1
    end
end

local function update_func()
    if not Stats.Refresh  then
	return
    end
    Stats.Refresh = false
    local totdamage = 0
    local totheal = 0
    local maxdamage = 0
    local maxheal = 0
    for name, player in pairs(group_members) do
	local damage = player.Damage
	if damage ~= 0 then
	    damagetrk[#damagetrk + 1] = {name, damage}
	    totdamage = totdamage + damage
	    if damage > maxdamage then
		maxdamage = damage
	    end
	end
	local heal = player.Heal
	if heal ~= 0 then
	    healtrk[#healtrk + 1] = {name, heal}
	    totheal = totheal + heal
	    if heal > maxheal then
		maxheal = heal
	    end
	end
    end
    dispall('damage', damage, damagetrk, totdamage, maxdamage)
    dispall('heal', heal, healtrk, totheal, maxheal)
end

local function update_maybe()
    if Stats.Update == update_func then
	Stats.Refresh = true
	update_func()
    end
end

-- Saves current widget position to settings
--
function Stats:OnMove(stop)
    if not stop then
	mvc:SetHidden(false)
    else
	mvc:SetHidden(true)
	saved.StatWinPos.X = widget:GetLeft()
	saved.StatWinPos.Y = widget:GetTop()
	widgbot = widget:GetBottom()
	update_maybe()
    end
end

local function resize(start)
    if start then
	-- mvc:SetHidden(false)
    else
	-- mvc:SetHidden(true)
	local dimx, dimy = widget:GetDimensions()
	widgbot = widget:GetBottom()
	saved.StatWinPos.DimX, saved.StatWinPos.DimY = dimx, dimy
	rowlen = (dimx / 2) - 4
	heal[0]:ClearAnchors()
	heal[0]:SetAnchor(TOPLEFT, widget, TOPLEFT, dimx / 2, 0)
	back:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
	back:SetDimensions(dimx, dimy)
	mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
	mvc:SetDimensions(dimx, dimy)
	mvc:SetDimensionConstraints(0, 0, dimx, dimy)
	update_maybe()
    end
end

local function initialize_update_func(x)
    local firsttime
    if not saved.StatWinPos.DimX or saved.StatWinPos.DimX == 0 then
	saved.StatWinPos.DimX, saved.StatWinPos.DimY = widget:GetDimensions()
	firsttime = true
    else
	widget:SetDimensions(saved.StatWinPos.DimX, saved.StatWinPos.DimY)
	firsttime = false
    end
    -- widget:SetDimensionConstraints(100, 16, 99999, 99999)
    local dimx, dimy = saved.StatWinPos.DimX, saved.StatWinPos.DimY
    back:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
    back:SetDimensions(dimx, dimy)
    mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
    mvc:SetDimensions(dimx, dimy)
    rowlen = (dimx / 2) - 4
    damage[0] = WM:CreateControl(nil, widget, CT_LABEL)
    damage[0]:ClearAnchors()
    damage[0]:SetAnchor(TOPLEFT, widget, TOPLEFT, 0, 0)
    damage[0]:SetFont('$(BOLD_FONT)|18|soft-shadow-thick')
    damage[0]:SetText("|cffff00Damage Done|r")
    damage[0]:SetDrawLayer(DL_BACKGROUND)
    damage[0]:SetDrawTier(DT_LOW)
    damage[0]:SetHidden(false)

    heal[0] = WM:CreateControl(nil, widget, CT_LABEL)
    heal[0]:ClearAnchors()
    heal[0]:SetAnchor(TOPLEFT, widget, TOPLEFT, dimx / 2, 0)
    heal[0]:SetFont('$(BOLD_FONT)|18|soft-shadow-thick')
    heal[0]:SetText("|cffff00Healing Done|r")
    heal[0]:SetDrawLayer(DL_BACKGROUND)
    heal[0]:SetDrawTier(DT_LOW)
    heal[0]:SetHidden(false)

    widget:ClearAnchors()
    if firsttime then
	widget:SetAnchor(CENTER, GuiRoot, CENTER, 0, -dimy - 40)
    else
	widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, saved.StatWinPos.X, saved.StatWinPos.Y)
    end
    widget:SetMovable(true)
    widget:SetMouseEnabled(true)
    mvc:SetHidden(not firsttime)
    widgbot = widget:GetBottom()
    widget:SetHandler("OnResizeStart", function() resize(true) end)
    widget:SetHandler("OnResizeStop", function() resize(false) end)

    Stats.Update = update_func
    update_func(x)
end

local unitcache = {}
local function record(ev, timems, result, sid, tid, aid, hit, damage_type, overflow)
    if not unitcache[tid] then
	local fight = LC.GetCurrentFight()
	if not fight or not fight.units[tid] then
	    watch('record', string.format("*** couldn't find unit %d", tid))
	    return
	end
	local this = fight.units[tid]
	unitcache[tid] = {this.unitType, this.name}
	watch('damage', ev, tid, this.unitType, this.name)
    end

    local ix
    local dtype = unitcache[tid][1]

    if ev == LIBCOMBAT_EVENT_DAMAGE_OUT then
	if dtype ~= COMBAT_UNIT_TYPE_OTHER then
	    watch('stats', 'returning combat')
	    return
	end
	ix = 'Damage'
    else
	if dtype ~= COMBAT_UNIT_TYPE_OTHER and dtype ~= COMBAT_UNIT_TYPE_GROUP then
	    watch('stats', 'returning heal')
	    return
	end
	ix = 'Heal'
    end

    watch('stats', ix, hit, unitcache[tid][2])
    Me[ix] = Me[ix] + hit
    Stats.Refresh = true
end

function clearcache()
    for x in pairs(unitcache) do
	unitcache[x] = nil
    end
end

function Stats.ShareThem(x, doit)
    local sharestats
    if x ~= nil and x == true or x == 'on' or x == 'true' then
	sharestats = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharestats = false
    end
    local register_widget = Visibility.Export()
    if not doit and sharestats == saved.ShareStats then
	-- nothing to do
    elseif sharestats then
	register_widget(widget, 'stats', true)
	LC:RegisterCallbackType(LIBCOMBAT_EVENT_DAMAGE_OUT, record, "POC")
	LC:RegisterCallbackType(LIBCOMBAT_EVENT_HEAL_OUT, record, "POC")
	LC:RegisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, clearcache, "POC")
	if #damage == 0 then
	    Stats.Update = initialize_update_func
	else
	    Stats.Update = update_func
	end
	if not Me.Heal then
	    Me.Heal = 0
	end
	if not Me.Damage then
	    Me.Damage = 0
	end
    else
	register_widget(widget, 'stats', false)
	LC:UnregisterCallbackType(LIBCOMBAT_EVENT_DAMAGE_OUT, record, "POC")
	LC:UnregisterCallbackType(LIBCOMBAT_EVENT_HEAL_OUT, record, "POC")
	LC:UnregisterCallbackType(LIBCOMBAT_EVENT_FIGHTRECAP, clearcache, "POC")
	Stats.Update = emptyfunc
    end
    if not doit then
	saved.ShareStats = sharestats
    end
end

function debug(what, x)
    local val, name = mysplit(x)
    local ival = tonumber(val)
    if not ival then
	Error(string.format('"%s" is not a number', val))
	return
    end
    local player
    if name == nil then
	player = Me
    else
	for n, v in pairs(group_members) do
	    if string.find(n, name, 1) then
		player = v
		break
	    end
	end
	if not player then
	    Error(string.format('no group member named "%s"', name))
	    return
	end
    end
    if ival ~= 0 then
	player[what] = player[what] + ival
	Stats.Refresh = true
    end
    Info(string.format("%s is now %d", what, player[what]))
end

function Stats.Initialize(_saved)
    saved = _saved
    group_members = saved.GroupMembers

    Error = POC.Error
    Info = POC.Info
    Me = POC.Me
    mysplit = POC.mysplit
    namefit = POC.namefit
    ReloadUI = POC.ReloadUI
    Slash = POC.Slash
    Visibility = POC.Visibility
    watch = POC.watch

    saved.StatWinPos = saved.StatWinPos or {}
    -- Comm.Load will Call ShareThem as appropriate
    Slash({"dmg", 'damage'}, "debugging: Add a value to a player's damage total", function(x) debug('Damage', x) end)
    Slash("heal", "debugging: Add a value to a player's healing total", function(x) debug('Heal', x) end)
    Slash("clearstats", "debugging: clear stats window data", function () saved.StatWinPos = {} ReloadUI() end)
    Slash("stats", "turn stat sharing on/off", Stats.ShareThem)
end
