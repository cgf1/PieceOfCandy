setfenv(1, POC)
local GetAbilityIcon = GetAbilityIcon
local GetAbilityName = GetAbilityName
local GetUnitClassId = GetUnitClassId
local GetUnitName = GetUnitName

Ult = {
    Name = "POC-Ult",
    MaxPing = 0,
    Me = 0
}
Ult.__index = Ult

local ultix = GetUnitName("player")
local bynames = {}
local byids = {}
local bypings = {}
local tmp = {}

local saved
local mia
local MIAicon = "/POC/icons/mia.dds"

-- ByPing gets the ultimate group from given ability ping
--
function Ult.ByPing(pid)
    if pid ~= nil and bypings[pid] ~= nil then
	return bypings[pid]
    end
    return mia
end

-- ByAid gets the ultimate group from given ability ID
--
function Ult.ByAid(aid)
    if byids[aid] ~= nil then
	return byids[aid]
    end

    -- not found
    Error(string.format("AbilityId not found %s", tostring(aid)))

    return nil
end

-- ByName gets the ultimate group from given group name
--
function Ult.ByName(gname)
    if bynames[gname] ~= nil then
	return bynames[gname]
    end

    -- not found
    Error(string.format("Name not found %s", tostring(gname)))

    return nil
end

function Ult.Icons()
    local icons = {}
    for v in idpairs(bynames, 'Id', tmp) do
	if v.Aid ~= 'MIA' then
	    table.insert(icons, v.Icon)
	end
    end
    return icons
end

function Ult.Descriptions()
    local desclist = {}
    for v in idpairs(bynames, 'Id', tmp) do
	if v.Aid ~= 'MIA' then
	    table.insert(desclist, v.Desc)
	end
    end
    return desclist
end

local function addtbl(tbl, name, id, morphchoice, morphs)
    tbl[name] = tbl[name] or {}
    tbl[name].Morphs = morphs
    tbl[name].Aid = id
    tbl[name].MorphChoice = morphchoice
    if not morphs then
	tbl[name].Base = name
    else
	for _, morph in pairs(morphs) do
	    tbl[morph] = tbl[morph] or {}
	    tbl[morph].Base = name
	end
    end
end

local function mkulttbl()
    local tbl = {}
    for i = 1, 99999 do
	if DoesAbilityExist(i) then
	    local cost, mechanic = GetAbilityCost(i)
	    if cost ~= 0 and mechanic == POWERTYPE_ULTIMATE then
		local name = GetAbilityName(i)
		local aid
		local skillType, skillIndex, abilityIndex, morphChoice, rankIndex = GetSpecificSkillAbilityKeysByAbilityId(i)
		local doit
		if morphChoice ~= 0 then
		    doit = true
		else
		    aid = {}
		    aid[1] = GetSpecificSkillAbilityInfo(skillType, skillIndex, abilityIndex, 1, rankIndex)
		    aid[2] = GetSpecificSkillAbilityInfo(skillType, skillIndex, abilityIndex, 2, rankIndex)
		    if aid[1] == 0 or aid[2] == 0 then
			doit = name:lower():sub(1, 7) == 'eye of '
		    else
			for i, x in pairs(aid) do
			    aid[i] = GetAbilityName(x)
			end
			doit = true
		    end
		end
		if doit then
		    addtbl(tbl, name, i, morphChoice, aid)
		end
	    end
	end
    end
    return tbl
end

local function insert_group_table(to_table, from_table, from_key, i)
    local t = from_table[from_key]
    from_table[from_key] = nil
    for _, v in ipairs(t) do
	to_table[v.Name] = v
	i = i + 1
	v.Id = i
    end
    return i
end

-- Create Ults array
--
local function create_ults()
    local classes = {
	[1] = "Dragonknight",
	[2] = "Sorcerer",
	[3] = "Nightblade",
	[4] = "Warden",
	[6] = "Templar"
    }

    local classid = GetUnitClassId("player")
    local class = classes[classid]

    local ults = {
	['Sorcerer'] = {
	    {
		['Ping'] = 1,
		['Name'] = 'NEGATE',
		['Desc'] = 'Negate Magic'
	    },
	    {
		['Ping'] = 2,
		['Name'] = 'ATRO',
		['Desc'] = 'Summon Storm Atronach'
	    },
	    {
		['Ping'] = 3,
		['Name'] = 'OVER',
		['Desc'] = 'Overload'
	    }
	},
	['Templar'] = {
	    {
		['Ping'] = 4,
		['Name'] = 'SWEEP',
		['Desc'] = 'Radial Sweep'
	    },
	    {
		['Ping'] = 5,
		['Name'] = 'NOVA',
		['Desc'] = 'Nova'
	    },
	    {
		['Ping'] = 6,
		['Name'] = 'TPHEAL',
		['Desc'] = 'Rite of Passage'
	    }
	},
	['Dragonknight'] = {
	    {
		['Ping'] = 7,
		['Name'] = 'STAND',
		['Desc'] = 'Dragonknight Standard'
	    },
	    {
		['Ping'] = 8,
		['Name'] = 'LEAP',
		['Desc'] = 'Dragon Leap'
	    },
	    {
		['Ping'] = 9,
		['Name'] = 'MAGMA',
		['Desc'] = 'Magma Armor'
	    }
	},
	['Nightblade'] = {
	    {
		['Ping'] = 10,
		['Name'] = 'STROKE',
		['Desc'] = 'Death Stroke'
	    },
	    {
		['Ping'] = 11,
		['Name'] = 'VEIL',
		['Desc'] = 'Consuming Darkness'
	    },
	    {
		['Ping'] = 12,
		['Name'] = 'NBSOUL',
		['Desc'] = 'Soul Shred'
	    }
	},
	['Warden'] = {
	    {
		['Ping'] = 13,
		['Name'] = 'FREEZE',
		['Desc'] = 'Sleet Storm'
	    },
	    {
		['Ping'] = 14,
		['Name'] = 'WDHEAL',
		['Desc'] = 'Secluded Grove'
	    }
	},
	['Destruction Staff'] = {
	    {
		['Ping'] = 15,
		['Name'] = 'ICE',
		['Desc'] = 'Eye of Frost'
	    },
	    {
		['Ping'] = 16,
		['Name'] = 'FIRE',
		['Desc'] = 'Eye of Flame'
	    },
	    {
		['Ping'] = 17,
		['Name'] = 'LIGHT',
		['Desc'] = 'Eye of Lightning'
	    }
	},
	['Restoration Staff'] = {
	    {
		['Ping'] = 18,
		['Name'] = 'STHEAL',
		['Desc'] = 'Panacea'
	    }
	},
	['Two Handed'] = {
	    {
		['Ping'] = 19,
		['Name'] = 'BERSERK',
		['Desc'] = 'Berserker Strike'
	    }
	},
	['One Hand and Shield'] = {
	    {
		['Ping'] = 20,
		['Name'] = 'SHIELD',
		['Desc'] = 'Shield Wall'
	    }
	},
	['Dual Wield'] = {
	    {
		['Ping'] = 21,
		['Name'] = 'DUAL',
		['Desc'] = 'Lacerate'
	    }
	},
	['Bow'] = {
	    {
		['Ping'] = 22,
		['Name'] = 'BOW',
		['Desc'] = 'Rapid Fire'
	    }
	},
	['Soul Magic'] = {
	    {
		['Ping'] = 23,
		['Name'] = 'SOUL',
		['Desc'] = 'Soul Strike'
	    }
	},
	['Werewolf'] = {
	    {
		['Ping'] = 24,
		['Name'] = 'WERE',
		['Desc'] = 'Werewolf Transformation'
	    }
	},
	['Vampire'] = {
	    {
		['Ping'] = 25,
		['Name'] = 'VAMP',
		['Desc'] = 'Bat Swarm'
	    }
	},
	['Mages Guild'] = {
	    {
		['Ping'] = 26,
		['Name'] = 'METEOR',
		['Desc'] = 'Meteor'
	    }
	},
	['Fighters Guild'] = {
	    {
		['Ping'] = 27,
		['Name'] = 'DAWN',
		['Desc'] = 'Dawnbreaker'
	    }
	},
	['PVP'] = {
	    {
		['Ping'] = 28,
		['Name'] = 'BARRIER',
		['Desc'] = 'Barrier'
	    },
	    {
		['Ping'] = 29,
		['Name'] = 'HORN',
		['Desc'] = 'War Horn'
	    }
	},
	['POC'] = {
	    {
		Name = 'MIA',
		Desc = 'Incommunicado Player',
		Icon = MIAicon,
		Ping = 30,
		Aid = 'MIA'
	    }
	}
    }

    -- Create tables indexed by different things
    local xltults = mkulttbl()
    for class, x in pairs(ults) do
	for _, group in pairs(x) do
	    if not group.Aid then
		group.Aid = xltults[group.Desc].Aid
	    end
	    group.Desc = string.format('%s: %s', class, group.Desc)
	    if group.Icon == nil then
		group.Icon = GetAbilityIcon(group.Aid)
	    end
	    byids[group.Aid] = group
	    bypings[group.Ping] = group
	    if group.Ping > Ult.MaxPing then
		Ult.MaxPing = group.Ping
	    end
	end
    end
    mia = bypings[Ult.MaxPing]
    mia.IsMIA = true
    local i = 0
    i = insert_group_table(bynames, ults, class, i)
    if saved.MyUltId[ultix] == nil then
	for v in idpairs(bynames, 'Id', tmp) do
	    Ult.SetSavedId(v.Aid, 1)
	    Ult.SetSavedId('MIA', 2)
	    break
	end
    end
    i = insert_group_table(bynames, ults, "Destruction Staff", i)
    i = insert_group_table(bynames, ults, "Restoration Staff", i)
    i = insert_group_table(bynames, ults, "Two Handed", i)
    i = insert_group_table(bynames, ults, "One Hand and Shield", i)
    i = insert_group_table(bynames, ults, "Dual Wield", i)
    i = insert_group_table(bynames, ults, "Bow", i)
    i = insert_group_table(bynames, ults, "PVP", i)
    i = insert_group_table(bynames, ults, "Mages Guild", i)
    i = insert_group_table(bynames, ults, "Fighters Guild", i)
    i = insert_group_table(bynames, ults, "Vampire", i)
    i = insert_group_table(bynames, ults, "Werewolf", i)
    i = insert_group_table(bynames, ults, "Soul Magic", i)
    for _, class in pairs(classes) do
	if ults[class] ~= nil then
	    i = insert_group_table(bynames, ults, class, i)
	end
    end
end

function Ult.GetSaved(n)
    if saved.MyUltId[ultix][n] ~= nil then
	-- should never be non-nil, but...
	local ult = Ult.ByPing(saved.MyUltId[ultix][n])
	return ult.Icon
    end
end

function Ult.UltApidFromIcon(icon)
    for id, v in pairs(byids) do
	if id ~= 'MIA' and v.Icon == icon then
	    return v.Ping
	end
    end
    return nil
end

function Ult.SetSavedId(apid, n)
    if apid == nil then
	local one = saved.MyUltId[ultix][1]
	saved.MyUltId[ultix][1] = saved.MyUltId[ultix][2]
	saved.MyUltId[ultix][2] = one
    else
	if saved.MyUltId[ultix] == nil then
	    saved.MyUltId[ultix] = {}
	end
	saved.MyUltId[ultix][n] = apid
    end
end

function Ult.SetSavedFromIcon(icon, n)
    local apid = Ult.UltApidFromIcon(icon)
    if apid ~= nil then
	Ult.SetSavedId(apid, n)
	return
    end
    Error(string.format("Ult.SetSaved: unknown icon %s", tostring(icon)))
end

-- Initialize Ult
--
function Ult.Initialize()
    saved = Settings.SavedVariables
    create_ults()

    local ids
    if saved.SwimlaneUltIds == nil then
	ids = saved.LaneIds
    else
	ids = saved.SwimlaneUltIds
	saved.SwimlaneUltIds = nil
    end

    -- Convert array of ultimate ability ids to shorter ultimate ping ids
    local newultids = {}
    local changed = false
    for i = 1, saved.SwimlaneMaxCols do
	v = ids[i]
	if v == nil or v == 'MIA' then
	    v = Ult.MaxPing
	elseif v > Ult.MaxPing then
	    v = Ult.ByAid(v).Ping
	    changed = true
	end
	newultids[i] = v
    end
    if changed then
	saved.LaneIds = newultids
    end
    for n, v in pairs(saved.MyUltId) do
	if type(v) ~= 'table' then
	    if v > Ult.MaxPing then
		v = Ult.ByAid(v).Ping
	    end
	    saved.MyUltId[n] = {[1] = v, [2] = 'MIA'}
	end
    end
end
