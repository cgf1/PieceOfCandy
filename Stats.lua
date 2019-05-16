setfenv(1, POC)

Stats = {
    Name = "POC-Stats",
}
local Stats = Stats
Stats.__index = Stats

local saved
local group_members

local function oncombat(_, result, iserror, aid_name, _, _, sname, stype, tname, ttype, hit, power_type, damage_type, log, suid, tuid, aid)
    if sname then
	sname = sname:gsub('(.*)^.*', '%1')
    else
	return
    end
    watch('oncombat', 'aid_name', aid_name, 'sname', sname, 'stype', stype, 'tname', tname, 'ttype', ttype, 'hit', hit, 'power_type', power_type, 'damage_type', damage_type, 'log', log, 'suid', suid, 'tuid', tuid, 'aid', aid)
    watch('oncombat', result, ACTION_RESULT_HEAL, ACTION_RESULT_CRITICAL_HEAL, ACTION_RESULT_DAMAGE, ACTION_RESULT_CRITICAL_DAMAGE)
    local player = group_members[sname]
    -- Add toggle to include self heals, self damage (?)
    if not player or not player.IsMe or tuid == 'player' then
	return
    end
    if result == ACTION_RESULT_HEAL or result == ACTION_RESULT_CRITICAL_HEAL then
	player.Heal = player.Heal + hit
    elseif result == ACTION_RESULT_DAMAGE or result == ACTION_RESULT_CRITICAL_DAMAGE then
	player.Damage = player.Damage + hit
    end
end

function Stats.Initialize(_saved)
    saved = _saved
    group_members = saved.GroupMembers
    EVENT_MANAGER:RegisterForEvent(Stats.name, EVENT_COMBAT_EVENT, oncombat)
    EVENT_MANAGER:AddFilterForEvent(Stats.name, EVENT_COMBAT_EVENT, REGISTER_FILTER_IS_ERROR, false, REGISTER_FILTER_UNIT_TAG, "player")
end
