setfenv(1, POC)
Quest = {
    Name = "POC-Quest"
}
Quest.__index = Quest

KEEP_INDEX = 1
RESOURCE_INDEX = 2
local qidtonum = {
    [3089] = KEEP_INDEX,
    [3126] = RESOURCE_INDEX
}

local numtoqname = {
    [KEEP_INDEX] = 'Capture Chalman Keep',
    [RESOURCE_INDEX] = 'Capture Chalman Mine'
}

local need = {
    [KEEP_INDEX] = true,
    [RESOURCE_INDEX] = true
}

local tracked = {}

local want

local myname = GetUnitName("player")

local getquest = true

local function question(id)
    if not getquest then
	return false
    else
	return want[id]
    end
end

local doit = false
local function ourquest(jix)
    local qname = GetJournalQuestName(jix)
    local qtype = GetJournalQuestType(jix)
    if qtype ~= QUEST_TYPE_AVA or qname:sub(1, 7) ~= 'Capture' then
	return 0
    end
    if qname:find(' Farm') ~= nil or qname:find(' Lumbermill') ~= nil or qname:find(' Mine') ~= nil then
	return RESOURCE_INDEX
    else
	return KEEP_INDEX
    end
end

local function quest_track(qname, id)
    local val
    if id ~= nil then
	tracked[qname] = id
	watch("quest_track", "tracking", qname, id)
	val = false
    elseif tracked[qname] == nil then
	watch("quest_track", "not tracked", qname)
	return false
    else
	id = tracked[qname]
	watch("quest_track", "clearing qname", id)
	tracked[qname] = nil
	val = true
    end
    need[id] = val
    return true
end

local function shared(eventcode, qid)
    local id = qidtonum[qid]
    if id ~= nil then
	AcceptSharedQuest(qid)
	Info("Automatically accepted:", numtoqname[id])
    end
end

local function quest_added(_, jix, qname)
    local id = ourquest(jix)
    watch("quest_added", qname, i)
    if id > 0 then
	quest_track(qname, id)
	watch("quest_added", "recognized")
    end
end

-- 131092 false 3 Capture Chalman Keep 37 294967291 3089
-- 131092 false 4 Capture Chalman Mine 37 294967291 3126
local function quest_gone(eventcode, completed, jix, qname,
			  zix, poiIndex, qid)
    if false and not completed then
	return
    end
    
    if quest_track(qname) then
	watch("quest_gone", "found quest", id)
    else
	watch("quest_gone", "unknown quest", qid)
    end
end

function Quest.Process(player, numquest)
    watch("Quest.Process", player, numquest)
    local myunit = GetUnitName
    if player == COMM_ALL_PLAYERS then
	-- everyone plays
    else
	local groupn = "group" .. player
	if GetUnitName(groupn) ~= myname then
	    return
	end
    end
    local qname = numtoqname[numquest]
    if qname ~= nil then
	for i = 1, GetNumJournalQuests() do
	    if GetJournalQuestName(i) == qname then
		Info("Sharing quest #" .. GetJournalQuestName(i) .. ' (' .. i .. ')')
		ShareQuest(i)
		return
	    end
	end
    end
end

function Quest.Ping()
    for id, need in pairs(need) do
	if not question(id) then
	    watch("Quest.Ping", "skipping", id)
	elseif not need then
	    watch("Quest.Ping", "don't need", id)
	else
	    watch("Quest.Ping", "need", id)
	    Comm.Send(COMM_TYPE_NEEDQUEST, COMM_ALL_PLAYERS, id)
	end
    end
end

function Quest.Want(id, set)
    if set == nil then
	return want[id]
    else
	want[id] = set
    end
end

function Quest.Initialize()
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_REMOVED, quest_gone)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_SHARED, shared)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_ADDED, quest_added)
    saved.ChalKeep = nil
    saved.ChalMine = nil
    if saved.Quests == nil then
	saved.Quests = {
	    [KEEP_INDEX] = true,
	    [RESOURCE_INDEX] = true
	}
    end
    want = saved.Quests
    for i = 1, GetNumJournalQuests() do
	local id = ourquest(i)
	if id > 0 then
	    quest_track(GetJournalQuestName(i), id)
	    need[id] = false
	end
    end
    SLASH_COMMANDS["/pocquest"] = function (x)
	if x == "off" or x == "false" or x == "no" then
	    getquest = false
	elseif x == "on" then
	    getquest = true
	end
	Info("Quest retrieval:", getquest)
    end
end
