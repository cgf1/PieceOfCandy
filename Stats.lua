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

local function emptyfunc()
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
    end
end

local first = false
local damage, heal
local function update_func(first)
    if not Stats.Refresh then
	return
    end
    Stats.Refresh = false
    HERE("Would have updated")
end

local function initialize_update_func(x)
    if not saved.StatWinPos.DimX then
	saved.StatWinPos.DimX, saved.StatWinPos.DimY = widget:GetDimensions()
    else
	widget:SetDimensions(saved.StatWinPos.DimX, saved.StatWinPos.DimY)
    end
    local dimx, dimy = saved.StatWinPos.DimX, saved.StatWinPos.DimY
    mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
    mvc:SetDimensionConstraints(dimx, dimy)
    widget:SetHidden(false)

    damage = WM:CreateControl(nil, widget, CT_LABEL)
    damage:ClearAnchors()
    damage:SetAnchor(TOPLEFT, widget, TOPLEFT, 0, 0)
    damage:SetFont('$(BOLD_FONT)|18|soft-shadow-thick')
    damage:SetText("|cffff00Damage Done|r")
    damage:SetHidden(false)

    local dimx, dimy = widget:GetDimensions()
    heal = WM:CreateControl(nil, widget, CT_LABEL)
    heal:ClearAnchors()
    heal:SetAnchor(TOPLEFT, widget, TOPLEFT, dimx / 2, 0)
    heal:SetFont('$(BOLD_FONT)|18|soft-shadow-thick')
    heal:SetText("|cffff00Healing Done|r")
    heal:SetHidden(false)

    widget:ClearAnchors()
    if saved.StatWinPos == nil then
	widget:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, saved.StatWinPos.X, saved.StatWinPos.Y)
    end
    widget:SetMovable(true)
    widget:SetMouseEnabled(true)
    widget:SetHandler("OnResizeStop", function(doit)
	local dimx, dimy = widget:GetDimensions()
	saved.StatWinPos.DimX, saved.StatWinPos.DimY = dimx, dimy
	heal:ClearAnchors()
	heal:SetAnchor(TOPLEFT, widget, TOPLEFT, dimx / 2, 0)
	mvc:SetAnchor(BOTTOMRIGHT, nil, TOPLEFT, dimx, dimy)
	mvc:SetDimensionConstraints(dimx, dimy)
    end)

    Stats.Update = update_func
    update_func(x)
end 

function Foo(x)
    if x == 'hide' then
	widget:SetHidden(true)
	mvc:SetHidden(true)
    else
	widget:SetHidden(false)
	mvc:SetHidden(false)
    end
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
    watch('oncombat', 'aid_name', aid_name, 'sname', sname, 'stype', stype, 'tname', tname, 'ttype', ttype)
    watch('oncombat', 'hit', hit, 'power_type', power_type, 'damage_type', damage_type, 'log', log, 'suid', suid, 'tuid', tuid, 'aid', aid)
    watch('oncombat', result, ACTION_RESULT_HEAL, ACTION_RESULT_CRITICAL_HEAL, ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE)
    local player = group_members[sname]
    -- Add toggle to include self heals, self damage (?)
    if not player or not player.IsMe or tuid == 'player' or ttype ~= COMBAT_UNIT_TYPE_OTHER then
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
    else
	EVENT_MANAGER:RegisterForEvent(Stats.name, EVENT_COMBAT_EVENT, oncombat)
	EVENT_MANAGER:AddFilterForEvent(Stats.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_IS_ERROR, false, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
	if not damage then
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

function Stats.Initialize(_saved)
    saved = _saved
    group_members = saved.GroupMembers
    widget = POC_Stats
    mvc = widget:GetNamedChild("Movable")
    local x, y = widget:GetDimensions()
    saved.StatWinPos = saved.StatWinPos or {}
    -- Comm.Load will Call ShareThem as appropriate
    Slash("/mmm", "Make stats movable again", function () Foo(1) end)
end
