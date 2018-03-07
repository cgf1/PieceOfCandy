setfenv(1, POC)
Quest = {
    Name = "POC-Quest"
}
Quest.__index = Quest

local qidtonum = {
    [3089] = 1,
    [3126] = 2
}

local numtoqname = {
    [1] = 'Capture Chalman Keep',
    [2] = 'Capture Chalman Mine'
}

local need = {
    [1] = true,
    [2] = true
}

local myname = GetUnitName("player")

local getquest = true

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
    if not getquest then
        return
    end
    for id, need in pairs(need) do
	watch("Quest.Ping", id, need)
	if need then
	    Comm.Send(COMM_TYPE_NEEDQUEST, COMM_ALL_PLAYERS, id)
	end
    end
end

local function shared(eventcode, qid)
    local id = qidtonum[qid]
    if id ~= nil then
	need[id] = false
	AcceptSharedQuest(qid)
	Info("Automatically accepted:", numtoqname[id])
    end
end

-- 131092 false 3 Capture Chalman Keep 37 294967291 3089
-- 131092 false 4 Capture Chalman Mine 37 294967291 3126
local function quest_gone(eventcode, isCompleted, journalIndex, qname,
			  zoneIndex, poiIndex, qid)
    if false and not isCompleted then
	return
    end
    local id = qidtonum[qid]
    if not id then
	watch("quest_gone", "unknown quest", qid)
    else
	need[id] = true
	watch("quest_gone", "found quest", id)
    end
end

function Quest.Initialize()
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_REMOVED, quest_gone)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_SHARED, shared)
    for i = 1, GetNumJournalQuests() do
	local qname = GetJournalQuestName(i)
	for id, _ in pairs(need) do
	    if qname == numtoqname[id] then
		need[id] = false
	    end
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
