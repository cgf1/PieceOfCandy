setfenv(1, POC)

Stats = {
    Name = "POC-Stats",
    Refresh = false
}
local Stats = Stats
Stats.__index = Stats

local saved
local group_members

local widget
local mvc
local back
local widgbot

local me

local pairs = pairs

local function emptyfunc()
end

local damage = {}
local heal = {}
local rowlen
local damagetrk = {}
local healtrk = {}

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
	val = WM:CreateControl(name .. 'val', label, CT_LABEL)
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
    fmt = '%' .. tostring(max):len() .. 'd'
    if saved.PctStats then
	fmt = fmt .. ' %2d%%'
    end

    while tbl[1] do
	local v = table.remove(tbl, 1)
	local label, val = dispcol(category, which, i)
	local dispval = string.format(fmt, v[2], 0.5 + (100 * (v[2] / tot)))
	local n = val:GetStringWidth(dispval)
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
    widget:SetDimensionConstraints(100, 16, 99999, 99999)
    local dimx, dimy = saved.StatWinPos.DimX, saved.StatWinPos.DimY
    back:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
    back:SetDimensions(dimx, dimy)
    mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
    mvc:SetDimensions(dimx, dimy)
    widget:SetHidden(false)
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

local function oncombat(_, result, iserror, aid_name, _, _, sname, stype, tname, ttype, hit, power_type, damage_type, log, suid, tuid, aid)
    if not aid_name or aid_name:len() == 0 then
	return
    end
    if sname then
	sname = sname:gsub('(.*)^.*', '%1')
    else
	return
    end
    if tname then
	tname = tname:gsub('(.*)^.*', '%1')
    else
	return
    end
    if POC_SAVESTATS then
	saved.StatMe = saved.StatMe or {}
	saved.StatMe[#saved.StatMe + 1] = {result, iserror, aid_name, sname, stype, tname, ttype, hit, power_type, damage_type, log, suid, tuid, aid}
    end
    if Watching then
	watch('oncombat', 'aid_name', aid_name, 'sname', sname, 'stype', stype, 'tname', tname, 'ttype', ttype)
	watch('oncombat', 'hit', hit, 'power_type', power_type, 'damage_type', damage_type, 'log', log, 'suid', suid, 'tuid', tuid, 'aid', aid)
	watch('oncombat', result, ACTION_RESULT_HEAL, ACTION_RESULT_CRITICAL_HEAL, ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE)
    end
    local player = group_members[sname]
    -- Add toggle to include self heals, self damage (?)
    if not player or not player.IsMe or (not saved.SelfStats and tuid == 'player') or (not saved.AllStats and ttype ~= COMBAT_UNIT_TYPE_OTHER) then
	return
    end
    if result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL then
	player.Heal = player.Heal + hit
	Stats.Refresh = true
    elseif result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_PRECISE_DAMAGE or result == ACTION_RESULT_WRECKING_DAMAGE then
	player.Damage = player.Damage + hit
	Stats.Refresh = true
    end
end

function Stats.ShareThem(x, doit)
    if x ~= nil and x == true or x == 'on' then
	sharestats = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharestats = false
    end
    if not doit and sharestats == saved.ShareStats then
	-- nothing to do
    elseif not sharestats then
	EVENT_MANAGER:UnregisterForEvent(Stats.name, EVENT_COMBAT_EVENT)
	widget:SetHidden(true)
	Stats.Update = emptyfunc
	for i = 1, #damage do
	    damage[i]:SetHidden(true)
	    damage[i]:GetChild(1):SetHidden(true)
	    damage[i]:SetText('')
	end
	for i = 1, #heal do
	    heal[i]:SetHidden(true)
	    heal[i]:GetChild(1):SetHidden(true)
	    heal[i]:SetText('')
	end
    else
	EVENT_MANAGER:RegisterForEvent(Stats.name, EVENT_COMBAT_EVENT, oncombat)
	EVENT_MANAGER:AddFilterForEvent(Stats.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_IS_ERROR, false, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	if #damage == 0 then
	    Stats.Update = initialize_update_func
	else
	    Stats.Update = update_func
	    widget:SetHidden(false)
	end
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
	player = me
    else
	for n, v in pairs(group_members) do
	    if string.find(n, name, 1) then
		player = v
		break
	    end
	end
	if not v then
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
    me = Me
    widget = POC_Stats
    local register_widget = Visibility.Export()
    register_widget(widget)
    mvc = widget:GetNamedChild("Movable")
    back = widget:GetNamedChild("Background")
    local x, y = widget:GetDimensions()
    saved.StatWinPos = saved.StatWinPos or {}
    -- Comm.Load will Call ShareThem as appropriate
    Slash({"dmg", 'damage'}, "debugging: Add a value to a player's healing total", function(x) debug('Damage', x) end)
    Slash("heal", "debugging: Add a value to a player's healing total", function(x) debug('Heal', x) end)
    Slash("clearstats", "debugging: clear stats window data", function () saved.StatWinPos = {} ReloadUI() end) 
end
