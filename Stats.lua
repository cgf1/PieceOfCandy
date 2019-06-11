setfenv(1, POC)

Stats = {
    Name = "POC-Stats",
}
local Stats = Stats
Stats.__index = Stats
local Stats = Stats

local saved
local group_members

local widget
local mvc

function Stats.ShareThem(x)
    if x ~= nil and x == true or x == 'on' then
	sharestats = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharestats = false
    end
    saved.ShareStats = sharestats
end

-- Saves current widget position to settings
--
function Stats:OnMove(stop)
    if not stop then
	mvc:SetHidden(false)
    else
	-- mvc:SetHidden(true)
	saved.StatWinPos = {
	    X = widget:GetLeft(),
	    Y = widget:GetTop()
	}
    end
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
    elseif result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE or result == ACTION_RESULT_PRECISE_DAMAGE or result == ACTION_RESULT_WRECKING_DAMAGE then
	player.Damage = player.Damage + hit
    end
end

function Stats.Initialize(_saved)
    saved = _saved
    group_members = saved.GroupMembers
    widget = POC_Stats
HERE('widget', widget)
    mvc = widget:GetNamedChild("MovableControl")
    EVENT_MANAGER:RegisterForEvent(Stats.name, EVENT_COMBAT_EVENT, oncombat)
    EVENT_MANAGER:AddFilterForEvent(Stats.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_IS_ERROR, false, REGISTER_FILTER_UNIT_TAG, "player")
end
