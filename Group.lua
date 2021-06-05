setfenv(1, POC)
local AcceptGroupInvite = AcceptGroupInvite
local IsUnitGrouped = IsUnitGrouped
local ZO_PreHook = ZO_PreHook

Group = {
    Name = "POC-Group"
}
Group.__index = Group

local saved
local JUMP1 = 'JUMP_TO_GROUP_LEADER_WORLD_PROMPT'
local JUMP2 = 'JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT'

local swimupdate
local swimsched

local function supdate(x)
    swimsched(false)
    swimupdate(x)
    Stats.Refresh = true
end

-- Called when group member joined group
--
local function on_joined(x, member)
    supdate("joined")
end

-- Called when group member left group
--
local function on_left(x, member)
    supdate("left")
end

-- Called when groupUnitTags updated
--
local function on_group_update(x, hmm)
    supdate("group update")
end

local function on_formed(x, hmm)
    supdate("formed")
end

local hooked = false
local suppress = false
local function nodialog(name, data)
    watch("nodialog", name, data)
    if (name == JUMP1 or name == JUMP2) and suppress then
	suppress = false
	return true
    end
end

local function on_invite(_, charname, displayname)
    watch("on_invite", charname, displayname)
    if saved.AutoAccept[charname] or saved.AutoAccept[displayname] then
	suppress = true
	if not hooked then
	    ZO_PreHook("ZO_Dialogs_ShowDialog", nodialog)
	    hooked = true
	end
	AcceptGroupInvite()
	Info(string.format("accepted invite from %s", charname))
    end
end

local function autoaccept(name)
    if name == 'clear' then
	Info("clearing all auto accept group invites")
	saved.AutoAccept = {}
    elseif name:len() > 0 then
	saved.AutoAccept[name] = true
	Info(string.format("automatically accept group invites from %s", name))
    else
	local keys = {}
	for n in pairs(saved.AutoAccept) do
	    keys[#keys + 1] = n
	end
	if #keys == 0 then
	    Info("not accepting group invites from anyone")
	else
	    Info("accepting group invites from:")
	    table.sort(keys)
	    for _, n in ipairs(keys) do
		d(n)
	    end
	end
    end
end

local function noautoaccept(name)
    if not saved.AutoAccept[name] then
	Error(string.format("'%s' was not found in group invite list", name))
    else
	saved.AutoAccept[name] = false
	Info(string.format("no longer automatically accept group invites from %s", name))
    end
end

function Group.IsGrouped()
    return IsUnitGrouped("player")
end

function Group.AutoAccept(val)
    if val ~= nil then
	local t = {}
	for line in val:gmatch("[^\r\n]+") do
	    t[line] = true
	end
	saved.AutoAccept = t
    else
	local t = {}
	for x in pairs(saved.AutoAccept) do
	    t[#t + 1] = x
	end
	table.sort(t)
	return table.concat(t, "\n")
    end
end

-- Initialize Group
--
function Group.Initialize(_saved)
    saved = _saved
    if not saved.AutoAccept then
	saved.AutoAccept = {}
    else
	for n in pairs(saved.AutoAccept) do
	    if n:len() == 0 then
		saved.AutoAccept[n] = nil
	    end
	end
    end

    swimupdate = Swimlanes.Update
    swimsched = Swimlanes.Sched
    -- Initial call
    on_group_update()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_JOINED, on_joined)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_LEFT, on_left)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_UPDATE, on_group_update)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, on_group_update)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_INVITE_RECEIVED, on_invite)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_UNIT_FRAME_UPDATE, on_formed)
    Slash("gaccept", "auto-accept group invite from given player", autoaccept)
    Slash("nogaccept", "remove auto-accept from given player", noautoaccept)
end
