setfenv(1, POC)
Quest = {
    Name = "POC-Quest"
}
Quest.__index = Quest

KEEP_INDEX = 1
RESOURCE_INDEX = 2
KILL_INDEX = 3

-- 3157 == Kill enemy players
-- 5222 == Templars
-- 5231 == Nightblades
--
local qidtonum = {
    [3089] = KEEP_INDEX,
    [3126] = RESOURCE_INDEX,
    [3157] = KILL_INDEX
}

local numtoqname_lang = {
    en = {
	[KEEP_INDEX] = 'Capture Chalman Keep',
	[RESOURCE_INDEX] = 'Capture Chalman Mine',
	[KILL_INDEX] = 'Kill Enemy Players'
    },
    fr = {
	[KEEP_INDEX] = 'Capturez la bastille Chalman',
	[RESOURCE_INDEX] = 'Capturez la mine de Chalman',
	[KILL_INDEX] = 'Tuez les joueurs adverses'
    },
    de = {
	[KEEP_INDEX] = 'Erobert die Burg Chalman',
	[RESOURCE_INDEX] = 'Erobert die Chalman-Mine',
	[KILL_INDEX] = 'Töte feindliche Spieler'
    }
}

local numtoqname

local need = {
    [KEEP_INDEX] = true,
    [RESOURCE_INDEX] = true,
    [KILL_INDEX] = false
}

local tracked = {}

local want = {}

local myname = GetUnitName("player")

local sharequests = true

local function question(id)
    if not sharequests then
	return false
    else
	return want[id]
    end
end

local doit = false
local function ourquest(jix)
    local qname = GetJournalQuestName(jix)
    local qtype = GetJournalQuestType(jix)
    local sub = qname:sub(1, 7)
    if qtype ~= QUEST_TYPE_AVA then
	return 0
    elseif sub == 'Kill En' then
	return KILL_INDEX
    elseif sub == 'Capture' then
	if qname:find(' Farm') ~= nil or qname:find(' Lumbermill') ~= nil or qname:find(' Mine') ~= nil then
	    return RESOURCE_INDEX
	else
	    return KEEP_INDEX
	end
    end
    return 0
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
    if not id then
	return
    end
    if question(id) then
	AcceptSharedQuest(qid)
	Info("Automatically accepted:", numtoqname[id])
    else
	DeclineSharedQuest(qid)
	watch("Quest.shared", "Automatically declined:", numtoqname[id])
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
    if sharequests and qname ~= nil then
	for i = 1, GetNumJournalQuests() do
	    if GetJournalQuestName(i) == qname then
		-- Info(zo_strformat("Sharing quest <<1>>", GetJournalQuestName(i)))
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

function Quest.Share(x)
    if x ~= '' and x == "on" then
	sharequests = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharequests = false
    end
    saved.ShareQuests = sharequests
end

function Quest.Want(id, set)
    if set == nil then
	return want[id]
    else
	want[id] = set
    end
end

function Quest.Initialize()
    local lang = GetCVar('Language.2')
    numtoqname = numtoqname_lang[lang]
    if numtoqname == nil then
	Error(string.format("Sorry.  Can't handle language '%s'.  Quest handling disabled.", lang))
	return
    end

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

    sharequests = saved.ShareQuests

    want = saved.Quests
    if want[KILL_INDEX] == nil then
	want[KILL_INDEX] = true
    end
    for i = 1, GetNumJournalQuests() do
	local id = ourquest(i)
	if id > 0 then
	    quest_track(GetJournalQuestName(i), id)
	    need[id] = false
	end
    end
    Slash("quest", "turn off quest sharing", function (x)
	if x ~= '' then
	    Quest.Share(x)
	end
	Info("Quest sharing:", sharequests)
    end)
end
