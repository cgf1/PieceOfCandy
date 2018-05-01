setfenv(1, POC)
local GetAbilityIcon = GetAbilityIcon
local GetAbilityName = GetAbilityName
local GetUnitClassId = GetUnitClassId
local GetUnitName = GetUnitName
local PlaySound = PlaySound
local SOUNDS = SOUNDS

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

local function mkulttbl()
    local tbl = {}
    for aid = 1, 99999 do
	if DoesAbilityExist(aid) then
	    local cost, mechanic = GetAbilityCost(aid)
	    if cost ~= 0 and mechanic == POWERTYPE_ULTIMATE then
		local _, _, _, morphChoice = GetSpecificSkillAbilityKeysByAbilityId(aid)
		if morphChoice == 0 then
		    tbl[GetAbilityIcon(aid)] = aid
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
		Ping = 1,
		Name = 'NEGATE',
		Icon = '/esoui/art/icons/ability_sorcerer_monsoon.dds'
	    },
	    {
		Ping = 2,
		Name = 'ATRO',
		Icon = '/esoui/art/icons/ability_sorcerer_storm_atronach.dds'
	    },
	    {
		Ping = 3,
		Name = 'OVER',
		Icon = '/esoui/art/icons/ability_sorcerer_overload.dds'
	    }
	},
	['Templar'] = {
	    {
		Ping = 4,
		Name = 'SWEEP',
		Icon = '/esoui/art/icons/ability_templar_radial_sweep.dds'
	    },
	    {
		Ping = 5,
		Name = 'NOVA',
		Icon = '/esoui/art/icons/ability_templar_nova.dds'
	    },
	    {
		Ping = 6,
		Name = 'TPHEAL',
		Icon = '/esoui/art/icons/ability_templar_rite_of_passage.dds'
	    }
	},
	['Dragonknight'] = {
	    {
		Ping = 7,
		Name = 'STAND',
		Icon = '/esoui/art/icons/ability_dragonknight_006.dds'
	    },
	    {
		Ping = 8,
		Name = 'LEAP',
		Icon = '/esoui/art/icons/ability_dragonknight_009.dds'
	    },
	    {
		Ping = 9,
		Name = 'MAGMA',
		Icon = '/esoui/art/icons/ability_dragonknight_018.dds'
	    }
	},
	['Nightblade'] = {
	    {
		Ping = 10,
		Name = 'STROKE',
		Icon = '/esoui/art/icons/ability_nightblade_007.dds'
	    },
	    {
		Ping = 11,
		Name = 'VEIL',
		Icon = '/esoui/art/icons/ability_nightblade_015.dds'
	    },
	    {
		Ping = 12,
		Name = 'NBSOUL',
		Icon = '/esoui/art/icons/ability_nightblade_018.dds'
	    }
	},
	['Warden'] = {
	    {
		Ping = 13,
		Name = 'FREEZE',
		Icon = '/esoui/art/icons/ability_warden_006.dds'
	    },
	    {
		Ping = 14,
		Name = 'WDHEAL',
		Icon = '/esoui/art/icons/ability_warden_012.dds'
	    }
	},
	['Destruction Staff'] = {
	    {
		Ping = 15,
		Name = 'ICE',
		Icon = '/esoui/art/icons/ability_destructionstaff_014_a.dds'
	    },
	    {
		Ping = 16,
		Name = 'FIRE',
		Icon = '/esoui/art/icons/ability_destructionstaff_013_a.dds'
	    },
	    {
		Ping = 17,
		Name = 'LIGHT',
		Icon = '/esoui/art/icons/ability_destructionstaff_015_a.dds'
	    }
	},
	['Restoration Staff'] = {
	    {
		Ping = 18,
		Name = 'STHEAL',
		Icon = '/esoui/art/icons/ability_restorationstaff_006.dds'
	    }
	},
	['Two Handed'] = {
	    {
		Ping = 19,
		Name = 'BERSERK',
		Icon = '/esoui/art/icons/ability_2handed_006.dds'
	    }
	},
	['One Hand and Shield'] = {
	    {
		Ping = 20,
		Name = 'SHIELD',
		Icon = '/esoui/art/icons/ability_1handed_006.dds'
	    }
	},
	['Dual Wield'] = {
	    {
		Ping = 21,
		Name = 'DUAL',
		Icon = '/esoui/art/icons/ability_dualwield_006.dds'
	    }
	},
	['Bow'] = {
	    {
		Ping = 22,
		Name = 'BOW',
		Icon = '/esoui/art/icons/ability_bow_006.dds'
	    }
	},
	['Soul Magic'] = {
	    {
		Ping = 23,
		Name = 'SOUL',
		Icon = '/esoui/art/icons/ability_otherclass_002.dds'
	    }
	},
	['Werewolf'] = {
	    {
		Ping = 24,
		Name = 'WERE',
		Icon = '/esoui/art/icons/ability_werewolf_001.dds'
	    }
	},
	['Vampire'] = {
	    {
		Ping = 25,
		Name = 'VAMP',
		Icon = '/esoui/art/icons/ability_vampire_001.dds'
	    }
	},
	['Mages Guild'] = {
	    {
		Ping = 26,
		Name = 'METEOR',
		Icon = '/esoui/art/icons/ability_mageguild_005.dds'
	    }
	},
	['Fighters Guild'] = {
	    {
		Ping = 27,
		Name = 'DAWN',
		Icon = '/esoui/art/icons/ability_fightersguild_005.dds'
	    }
	},
	['PVP'] = {
	    {
		Ping = 28,
		Name = 'BARRIER',
		Icon = '/esoui/art/icons/ability_ava_006.dds'
	    },
	    {
		Ping = 29,
		Name = 'HORN',
		Icon = '/esoui/art/icons/ability_ava_003.dds'
	    }
	},
	['POC'] = {
	    {
		Name = 'MIA',
		Desc = 'POC: Incommunicado Player',
		Ping = 30,
		Aid = 'MIA',
		Icon = MIAicon
	    }
	}
    }

    -- Create tables indexed by different things
    local xltults = mkulttbl()
    for class, x in pairs(ults) do
	for _, group in pairs(x) do
	    if not group.Aid then
		local aid = xltults[group.Icon]
		if not aid then
		    Error(string.format('no icon found for: %s', group.Name))
		else
		    group.Aid = aid
		    group.Desc = string.format('%s: %s', class, GetAbilityName(aid))
		end
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

local function ability_used(_, slotnum)
    if slotnum == 8 then
	if saved.UltNoise then
	    PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)
	end
	Comm.UltFired(GetSlotBoundId(slotnum))
    end
end

-- Initialize Ult
--
function Ult.Initialize()
    saved = Settings.SavedVariables
    create_ults()
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_ACTION_SLOT_ABILITY_USED, ability_used)

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
    Slash('sendult', 'debugging: pretend that an ultimate fired', function(x)
	x = tonumber(x)
	if not x or x <= 0 then
	    ability_used(_, 8)
	else
	    Comm.UltFired(x)
	end
    end)
end
