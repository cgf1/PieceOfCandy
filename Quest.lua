setfenv(1, POC)
Quest = {
    Name = "POC-Quest"
}
Quest.__index = Quest

local OLDKEEP_IX = 1
local OLDRESOURCE_IX = 2
local OLDKILL_IX = 3

local AcceptSharedQuest = AcceptSharedQuest
local GetJournalQuestName = GetJournalQuestName
local GetNumJournalQuests = GetNumJournalQuests
local GetUnitName = GetUnitName
local ShareQuest = ShareQuest

local ixtoname = {}
local nametocat = {}
local nametoix = {}

local have = {}
local saved	-- alias for Settings.SavedVariables
local want	-- alias for saved.Quests

local sharequests = false

local function ignore(cat)
    if not cat or not want[cat] then
	return true
    end
    local qname = ixtoname[want[cat]]
    return qname:sub(1, 2) == '--'
end

local function havequest(cat)
    if ignore(cat) then
	return true
    end
    for i = 1, GetNumJournalQuests() do
	local qname = GetJournalQuestName(i)
	if nametocat[qname] == cat then
	    return true
	end
    end
    return false
end

local function _init()
    saved = Settings.SavedVariables
    local ref = {
	en = {
	    {"keep", "Capture Chalman Keep"},
	    {"resource", "Capture Chalman Mine"},
	    {"kill", "Kill Enemy Players"},
	    {"keep", "-- don't share keep quest --"},
	    {"resource", "-- don't share resource quest --"},
	    {"kill", "-- don't share kill enemy quest --"},
	    {"conquest", "Capture All 3 Towns"},
	    {"conquest", "Capture Any Nine Resources"},
	    {"conquest", "Capture Any Three Keeps"},
	    {"conquest", "Kill 40 Enemy Players"},
	    {"keep", "Capture Arrius Keep"},
	    {"keep", "Capture Blue Road Keep"},
	    {"keep", "Capture Castle Alessia"},
	    {"keep", "Capture Castle Black Boot"},
	    {"keep", "Capture Castle Bloodmayne"},
	    {"keep", "Capture Castle Brindle"},
	    {"keep", "Capture Castle Faregyl"},
	    {"keep", "Capture Castle Roebeck"},
	    {"keep", "Capture Drakelowe Keep"},
	    {"keep", "Capture Farragut Keep"},
	    {"keep", "Capture Fort Aleswell"},
	    {"keep", "Capture Fort Ash"},
	    {"keep", "Capture Fort Balfiera"},
	    {"keep", "Capture Fort Dragonclaw"},
	    {"keep", "Capture Fort Glademist"},
	    {"keep", "Capture Fort Rayles"},
	    {"keep", "Capture Fort Warden"},
	    {"keep", "Capture Kingscrest Keep"},
	    {"kill", "Kill Enemy Dragonknights"},
	    {"kill", "Kill Enemy Nightblades"},
	    {"kill", "Kill Enemy Sorcerers"},
	    {"kill", "Kill Enemy Templars"},
	    {"kill", "Kill Enemy Wardens"},
	    {"resource", "Capture Alessia Farm"},
	    {"resource", "Capture Alessia Lumbermill"},
	    {"resource", "Capture Alessia Mine"},
	    {"resource", "Capture Aleswell Farm"},
	    {"resource", "Capture Aleswell Lumbermill"},
	    {"resource", "Capture Aleswell Mine"},
	    {"resource", "Capture Arrius Farm"},
	    {"resource", "Capture Arrius Lumbermill"},
	    {"resource", "Capture Arrius Mine"},
	    {"resource", "Capture Ash Farm"},
	    {"resource", "Capture Ash Lumbermill"},
	    {"resource", "Capture Ash Mine"},
	    {"resource", "Capture Balfiera Lumbermill"},
	    {"resource", "Capture BalfieraMine"},
	    {"resource", "Capture Black Boot Farm"},
	    {"resource", "Capture Black Boot Lumbermill"},
	    {"resource", "Capture Black Boot Mine"},
	    {"resource", "Capture Bloodmayne Farm"},
	    {"resource", "Capture Bloodmayne Lumbermill"},
	    {"resource", "Capture Bloodmayne Mine"},
	    {"resource", "Capture Blue Road Farm"},
	    {"resource", "Capture Blue Road Lumbermill"},
	    {"resource", "Capture Blue Road Mine"},
	    {"resource", "Capture Brindle Farm"},
	    {"resource", "Capture Brindle Lumbermill"},
	    {"resource", "Capture Brindle Mine"},
	    {"resource", "Capture Chalman Farm"},
	    {"resource", "Capture Chalman Lumbermill"},
	    {"resource", "Capture Dragonclaw Farm"},
	    {"resource", "Capture Dragonclaw Lumbermill"},
	    {"resource", "Capture Dragonclaw Mine"},
	    {"resource", "Capture Drakelowe Farm"},
	    {"resource", "Capture Drakelowe Lumbermill"},
	    {"resource", "Capture Drakelowe Mine"},
	    {"resource", "Capture Faregyl Farm"},
	    {"resource", "Capture Faregyl Lumbermill"},
	    {"resource", "Capture Faregyl Mine"},
	    {"resource", "Capture Farragut Farm"},
	    {"resource", "Capture Farragut Lumbermill"},
	    {"resource", "Capture Farragut Mine"},
	    {"resource", "Capture Glademist Farm"},
	    {"resource", "Capture Glademist Lumbermill"},
	    {"resource", "Capture Glademist Mine"},
	    {"resource", "Capture Kingscrest Farm"},
	    {"resource", "Capture Kingscrest Lumbermill"},
	    {"resource", "Capture Kingscrest Mine"},
	    {"resource", "Capture Rayles Farm"},
	    {"resource", "Capture Rayles Lumbermill"},
	    {"resource", "Capture Rayles Mine"},
	    {"resource", "Capture Roebeck Farm"},
	    {"resource", "Capture Roebeck Lumbermill"},
	    {"resource", "Capture Roebeck Mine"},
	    {"resource", "Capture Warden Farm"},
	    {"resource", "Capture Warden Lumbermill"},
	    {"resource", "Capture Warden Mine"},
	},
	fr = {
	    {"keep", "Capturez la bastille Chalman"},
	    {"resource", "Capturez la mine de Chalman"},
	    {"kill", "Tuez les joueurs adverses"},
	    {"keep", "-- ne partagez la quête du châteaui --"},
	    {"resource", "-- ne partagez la quête de ressources --"},
	    {"kill", "-- ne partagez la quête de tuer l'ennemi --"},
	    {"conquest", "Capturez les 3 villes"},
	    {"conquest", "Capturez neuf ressources différentes"},
	    {"conquest", "Capturez trois forts différents"},
	    {"conquest", "Tuez 40 joueurs adverses"},
	    {"keep", "Capture Fort Balfiera"},
	    {"keep", "Capturez fort Bayle"},
	    {"keep", "Capturez fort Brumeclaire"},
	    {"keep", "Capturez fort Cendre"},
	    {"keep", "Capturez fort Griffe-dragon"},
	    {"keep", "Capturez fort Houblon"},
	    {"keep", "Capturez fort Rayles"},
	    {"keep", "Capturez la bastille Arrius"},
	    {"keep", "Capturez la bastille Farragut"},
	    {"keep", "Capturez la bastille Malard"},
	    {"keep", "Capturez la bastille de Farragut"},
	    {"keep", "Capturez la bastille de Sente-azur"},
	    {"keep", "Capturez la bastille des Armoiries"},
	    {"keep", "Capturez le château Crin-de-Sang"},
	    {"keep", "Capturez le château Faregyl"},
	    {"keep", "Capturez le château Roebeck"},
	    {"keep", "Capturez le château d'Alessia"},
	    {"keep", "Capturez le château de Botte-Noire"},
	    {"keep", "Capturez le château de Bringée"},
	    {"kill", "Tuez des Chevaliers-dragons ennemis"},
	    {"kill", "Tuez des Lames noires ennemis"},
	    {"kill", "Tuez des Sorciers ennemis"},
	    {"kill", "Tuez les gardiens ennemis"},
	    {"kill", "Tuez les templiers ennemis"},
	    {"resource", "Capture Balfiera Lumbermill"},
	    {"resource", "Capture BalfieraMine"},
	    {"resource", "Capturez la ferme d'Alessia"},
	    {"resource", "Capturez la ferme d'Arrius"},
	    {"resource", "Capturez la ferme de Bayle"},
	    {"resource", "Capturez la ferme de Botte-Noire"},
	    {"resource", "Capturez la ferme de Bringée"},
	    {"resource", "Capturez la ferme de Brumeclaire"},
	    {"resource", "Capturez la ferme de Cendre"},
	    {"resource", "Capturez la ferme de Chalman"},
	    {"resource", "Capturez la ferme de Faregyl"},
	    {"resource", "Capturez la ferme de Farragut"},
	    {"resource", "Capturez la ferme de Griffe-dragon"},
	    {"resource", "Capturez la ferme de Houblon"},
	    {"resource", "Capturez la ferme de Malard"},
	    {"resource", "Capturez la ferme de Rayles"},
	    {"resource", "Capturez la ferme de Roebeck"},
	    {"resource", "Capturez la ferme de Sente-azur"},
	    {"resource", "Capturez la ferme des Armoiries"},
	    {"resource", "Capturez la ferme du Crin-de-Sang"},
	    {"resource", "Capturez la mine d'Alessia"},
	    {"resource", "Capturez la mine d'Arrius"},
	    {"resource", "Capturez la mine de Bayle"},
	    {"resource", "Capturez la mine de Botte-Noire"},
	    {"resource", "Capturez la mine de Bringée"},
	    {"resource", "Capturez la mine de Brumeclaire"},
	    {"resource", "Capturez la mine de Cendre"},
	    {"resource", "Capturez la mine de Faregyl"},
	    {"resource", "Capturez la mine de Farragut"},
	    {"resource", "Capturez la mine de Griffe-dragon"},
	    {"resource", "Capturez la mine de Houblon"},
	    {"resource", "Capturez la mine de Malard"},
	    {"resource", "Capturez la mine de Rayles"},
	    {"resource", "Capturez la mine de Roebeck"},
	    {"resource", "Capturez la mine de Sente-azur"},
	    {"resource", "Capturez la mine des Armoiries"},
	    {"resource", "Capturez la mine du Crin-de-Sang"},
	    {"resource", "Capturez la scierie d'Alessia"},
	    {"resource", "Capturez la scierie d'Arrius"},
	    {"resource", "Capturez la scierie de Bayle"},
	    {"resource", "Capturez la scierie de Botte-Noire"},
	    {"resource", "Capturez la scierie de Bringée"},
	    {"resource", "Capturez la scierie de Brumeclaire"},
	    {"resource", "Capturez la scierie de Cendre"},
	    {"resource", "Capturez la scierie de Chalman"},
	    {"resource", "Capturez la scierie de Faregyl"},
	    {"resource", "Capturez la scierie de Farragut"},
	    {"resource", "Capturez la scierie de Griffe-dragon"},
	    {"resource", "Capturez la scierie de Houblon"},
	    {"resource", "Capturez la scierie de Malard"},
	    {"resource", "Capturez la scierie de Rayles"},
	    {"resource", "Capturez la scierie de Roebeck"},
	    {"resource", "Capturez la scierie de Sente-azur"},
	    {"resource", "Capturez la scierie des Armoiries"},
	    {"resource", "Capturez la scierie du Crin-de-Sang"},
	},
	de = {
	    {"keep", "Erobert die Burg Chalman"},
	    {"resource", "Erobert die Chalman-Mine"},
	    {"kill", "Tötet feindliche Spieler"},
	    {"keep", "-- nicht Kasten Quest teilen --"},
	    {"resource", "-- nicht Ressource Quest teilen --"},
	    {"kill", "-- nicht töten Feind Quest teilen--"},
	    {"conquest", "Erobert drei beliebige Burgen"},
	    {"conquest", "Nehmt alle 3 Siedlungen ein"},
	    {"conquest", "Nehmt neun beliebige Betriebe ein"},
	    {"keep", "Capture Fort Balfiera"},
	    {"keep", "Erobert das Kastell Alessia"},
	    {"keep", "Erobert das Kastell Blutmähne"},
	    {"keep", "Erobert das Kastell Brindell"},
	    {"keep", "Erobert das Kastell Faregyl"},
	    {"keep", "Erobert das Kastell Roebeck"},
	    {"keep", "Erobert das Kastell Schwarzstiefel"},
	    {"keep", "Erobert die Burg Arrius"},
	    {"keep", "Erobert die Burg Blauweg"},
	    {"keep", "Erobert die Burg Drakenschein"},
	    {"keep", "Erobert die Burg Farragut"},
	    {"keep", "Erobert die Burg Königsbanner"},
	    {"keep", "Erobert die Feste Alebrunn"},
	    {"keep", "Erobert die Feste Asch"},
	    {"keep", "Erobert die Feste Aunebel"},
	    {"keep", "Erobert die Feste Drachenklaue"},
	    {"keep", "Erobert die Feste Obhut"},
	    {"keep", "Erobert die Feste Rayles"},
	    {"kill", "Tötet feindliche Drachenritter"},
	    {"kill", "Tötet feindliche Nachtklingen"},
	    {"kill", "Tötet feindliche Templer"},
	    {"kill", "Tötet feindliche Zauberer"},
	    {"kill", "Tötet gegnerische Hüter"},
	    {"resource", "Capture Balfiera Lumbermill"},
	    {"resource", "Capture BalfieraMine"},
	    {"resource", "Erobert das Alebrunn-Holzfällerlager"},
	    {"resource", "Erobert das Alessia-Holzfällerlager"},
	    {"resource", "Erobert das Arrius-Holzfällerlager"},
	    {"resource", "Erobert das Asch-Holzfällerlager"},
	    {"resource", "Erobert das Aunebel-Holzfällerlager"},
	    {"resource", "Erobert das Blauweg-Holzfällerlager"},
	    {"resource", "Erobert das Blutmähne-Holzfällerlager"},
	    {"resource", "Erobert das Brindell-Holzfällerlager"},
	    {"resource", "Erobert das Chalman-Holzfällerlager"},
	    {"resource", "Erobert das Drachenklaue-Holzfällerlager"},
	    {"resource", "Erobert das Drakenschein-Holzfällerlager"},
	    {"resource", "Erobert das Faregyl-Holzfällerlager"},
	    {"resource", "Erobert das Farragut-Holzfällerlager"},
	    {"resource", "Erobert das Königsbanner-Holzfällerlager"},
	    {"resource", "Erobert das Obhut-Holzfällerlager"},
	    {"resource", "Erobert das Rayles-Holzfällerlager"},
	    {"resource", "Erobert das Roebeck-Holzfällerlager"},
	    {"resource", "Erobert das Schwarzstiefel-Holzfällerlager"},
	    {"resource", "Erobert den Alebrunn-Bauernhof"},
	    {"resource", "Erobert den Alessia-Bauernhof"},
	    {"resource", "Erobert den Arrius-Bauernhof"},
	    {"resource", "Erobert den Asch-Bauernhof"},
	    {"resource", "Erobert den Aunebel-Bauernhof"},
	    {"resource", "Erobert den Blauweg-Bauernhof"},
	    {"resource", "Erobert den Blutmähne-Bauernhof"},
	    {"resource", "Erobert den Brindell-Bauernhof"},
	    {"resource", "Erobert den Chalman-Bauernhof"},
	    {"resource", "Erobert den Drachenklaue-Bauernhof"},
	    {"resource", "Erobert den Drakenschein-Bauernhof"},
	    {"resource", "Erobert den Faregyl-Bauernhof"},
	    {"resource", "Erobert den Farragut-Bauernhof"},
	    {"resource", "Erobert den Königsbanner-Bauernhof"},
	    {"resource", "Erobert den Obhut-Bauernhof"},
	    {"resource", "Erobert den Rayles-Bauernhof"},
	    {"resource", "Erobert den Roebeck-Bauernhof"},
	    {"resource", "Erobert den Schwarzstiefel-Bauernhof"},
	    {"resource", "Erobert die Alebrunn-Mine"},
	    {"resource", "Erobert die Alessia-Mine"},
	    {"resource", "Erobert die Arrius-Mine"},
	    {"resource", "Erobert die Asch-Mine"},
	    {"resource", "Erobert die Aunebel-Mine"},
	    {"resource", "Erobert die Blauweg-Mine"},
	    {"resource", "Erobert die Blutmähne-Mine"},
	    {"resource", "Erobert die Brindell-Mine"},
	    {"resource", "Erobert die Drachenklaue-Mine"},
	    {"resource", "Erobert die Drakenschein-Mine"},
	    {"resource", "Erobert die Faregyl-Mine"},
	    {"resource", "Erobert die Farragut-Mine"},
	    {"resource", "Erobert die Königsbanner-Mine"},
	    {"resource", "Erobert die Obhut-Mine"},
	    {"resource", "Erobert die Rayles-Mine"},
	    {"resource", "Erobert die Roebeck-Mine"},
	    {"resource", "Erobert die Schwarzstiefel-Mine"},
	}
    }
    sharequests = saved.ShareQuests

    local lang = GetCVar('Language.2')
    local quests = ref[lang]
    if quests == nil then
	Error(string.format("Sorry.  Can't handle language \"%s\".  Quest handling disabled.", lang))
	sharequests = false
	return
    end

    -- easy lookup for quest type, quest ix
    for i, t in ipairs(quests) do
	local cat, qname = unpack(t)
	nametocat[qname] = cat
	ixtoname[i] = qname
	nametoix[qname] = i
    end

    want = saved.Quests
    local default = next(want) == nil
    if default or want[OLDKEEP_IX] then
	want['keep'] = OLDKEEP_IX
	want[OLDKEEP_IX] = nil
    end
    if default or want[OLDKILL_IX] then
	want['kill'] = OLDKILL_IX
	want[OLDKILL_IX] = nil
    end
    if default or want[OLDRESOURCE_IX] then
	want['resource'] = OLDRESOURCE_IX
	want[OLDRESOURCE_IX] = nil
    end

    have = {}
    for cat, ix in pairs(want) do
	local qname = ixtoname[ix]
	have[cat] = havequest(cat)
    end
    _init = function() end
end

local function quest_shared(eventcode, qid)
    local qname = GetOfferedQuestShareInfo(qid)
    local cat = nametocat[qname]
    if cat ~= nil then
	watch('quest_shared', cat, qid, '=', qname)
	local ix = nametoix[qname]

	if sharequests and want[cat] == ix then
	    Info("Automatically accepted:", qname)
	    AcceptSharedQuest(qid)
	    have[cat] = true
	end
    end
end

local function quest_added(_, _, qname)
    local cat = nametocat[qname]
    if cat then
	watch("quest_added", cat, '=',	qname)
	have[cat] = true
    end
end

-- 131092 false 3 Capture Chalman Keep 37 294967291 3089
-- 131092 false 4 Capture Chalman Mine 37 294967291 3126
local function quest_gone(eventcode, completed, jix, qname, zix, poiIndex, qid)
    local cat = nametocat[qname]
    if cat and not ignore(cat) then
	watch("quest_gone", "tracked quest gone", qid, qname)
	have[cat] = false
    end
end

function Quest.Process(player, ix)
    watch("Quest.Process", player, ix)
    if ix <= 0 then
	watch("Quest.Process", "zero quest ix?	shouldn't happen")
	return
    end
    if player == COMM_ALL_PLAYERS then
	-- everyone plays
    else
	local groupn = "group" .. player
	if GetUnitName(groupn) ~= myname then
	    return
	end
    end
    local qname = ixtoname[ix]
    if qname:sub(1, 2) == '--' then
	watch("Quest.Process", "ignored quest?	shouldn't happen", qname)
	return
    end
    if sharequests and qname then
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
    for cat, gotit in pairs(have) do
	if gotit then
	    watch("Quest.Ping", "already have something in category", cat, ixtoname[want[cat]])
	else
	    local ix = want[cat]
	    watch("Quest.Ping", "need", cat, ix)
	    Comm.Send(COMM_TYPE_NEEDQUEST, COMM_ALL_PLAYERS, ix)
	end
    end
end

function Quest.ShareThem(x)
    if x ~= nil and x == true or x == 'on' then
	sharequests = true
    elseif x == false or x == "off" or x == "false" or x == "no" then
	sharequests = false
    end
    saved.ShareQuests = sharequests
end

function Quest.Choices(incat)
    _init()
    local t = {}
    local seen = {}
    for qname, cat in pairs(nametocat) do
	if cat == incat and not seen[qname] then
	    t[#t + 1] = qname
	    seen[qname] = true
	end
    end
    table.sort(t)
    return t
end

function Quest.Want(cat, qname)
    _init()

    if not qname then
	local name = ixtoname[want[cat]]
	return name
    else
	local ix = nametoix[qname]
	want[cat] = ix
	have[cat] = havequest(cat)
    end
end

function Quest.Initialize()
    _init()
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_REMOVED, quest_gone)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_SHARED, quest_shared)
    EVENT_MANAGER:RegisterForEvent(Quest.Name, EVENT_QUEST_ADDED, quest_added)
    saved.ChalKeep = nil
    saved.ChalMine = nil

    Slash("quest", "turn off quest sharing", function (x)
	if x ~= '' then
	    Quest.ShareThem(x)
	end
	Info("Quest sharing:", sharequests)
    end)
end
