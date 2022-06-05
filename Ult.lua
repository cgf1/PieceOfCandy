local Comm = POC.Comm
local DoesAbilityExist = DoesAbilityExist
local Error = POC.Error
local GetAbilityCost = GetAbilityCost
local GetAbilityIcon = GetAbilityIcon
local GetAbilityIdByIndex = GetAbilityIdByIndex
local GetAbilityName = GetAbilityName
local GetAbilityProgressionAbilityId = GetAbilityProgressionAbilityId
local GetAbilityProgressionInfo = GetAbilityProgressionInfo
local GetAbilityProgressionXPInfoFromAbilityId = GetAbilityProgressionXPInfoFromAbilityId
local GetActiveWeaponPairInfo = GetActiveWeaponPairInfo
local GetAPIVersion = GetAPIVersion
local GetNumAbilities = GetNumAbilities
local GetNumSkillAbilities = GetNumSkillAbilities
local GetNumSkillLines = GetNumSkillLines
local GetNumSkillTypes = GetNumSkillTypes
local GetSkillAbilityId = GetSkillAbilityId
local GetSlotBoundId = GetSlotBoundId
local GetSpecificSkillAbilityInfo = GetSpecificSkillAbilityInfo
local GetSpecificSkillAbilityKeysByAbilityId = GetSpecificSkillAbilityKeysByAbilityId
local GetUnitClassId = GetUnitClassId
local GetUnitName = GetUnitName
local GetUnitPower = GetUnitPower
local Group = POC.Group
local HERE = POC.HERE
local idpairs = POC.idpairs
local Player = POC.Player
local PlaySound = PlaySound
local POWERTYPE_ULTIMATE = POWERTYPE_ULTIMATE
local SetCrownCrateNPCVisible = SetCrownCrateNPCVisible
local Slash = POC.Slash
local SOUNDS = SOUNDS
local watch = POC.watch

setfenv(1, POC)

Ult = {
    Name = "POC-Ult",
    MaxPing = 0,
    Me = 0
}
local Ult = Ult
Ult.__index = Ult
setmetatable(Ult, Ult)

local ultix = GetUnitName("player")
local bynames = {}
local byids = {}
local bypings = {}
local tmp = {}

local saved
local mia
local MIAicon = "POC/icons/mia.dds"

local myults

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
    if byids[aid] then
	return byids[aid]
    end
    local skillType, skillLineIndex, skillIndex, _, rankIndex = GetSpecificSkillAbilityKeysByAbilityId(aid)
    local baid = GetSpecificSkillAbilityInfo(skillType, skillLineIndex, skillIndex, 0, rankIndex)
    if byids[baid] then
	return byids[baid]
    end

    -- not found
    -- Error(string.format("AbilityId not found %d/%d %s", aid, baid, GetAbilityIcon(baid)))

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
	if not v.IsMia then
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

local function baseaid(aid)
    local hasp, pindex = GetAbilityProgressionXPInfoFromAbilityId(aid)
    local baid
    if not hasp then
	baid = aid
    else
	local name, morph, rank = GetAbilityProgressionInfo(pindex)
	baid = GetAbilityProgressionAbilityId(pindex, 0, rank)
    end

    return baid
end

local function mkulttbl()
    local nskt = GetNumSkillTypes()
    local iconlist = {}
    for i = 1, nskt do
	local nskl = GetNumSkillLines(i)
	for j=1,nskl do
	    local nska =GetNumSkillAbilities(i, j)
	    for k = 1, nska do
		local aid = GetSkillAbilityId(i, j, k)
		local _, ptype = GetAbilityCost(aid)
		if true or ptype == POWERTYPE_ULTIMATE then
		    local baid = baseaid(aid)
		    iconlist[GetAbilityIcon(baid)] = aid
		end
	    end
	end
    end
    return iconlist
end

local function insert_group_table(to_table, from_table, from_key, i)
    local t = from_table[from_key]
    from_table[from_key] = nil
    for _, v in ipairs(t) do
	if v.Ping ~= 0 then
	    to_table[v.Name] = v
	    i = i + 1
	    v.Id = i
	end
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
	[5] = "Necromancer",
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
	    },
	    {
		Ping = 31,
		Name = 'GUARDIAN',
		Icon = '/esoui/art/icons/ability_warden_018.dds'
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
		Icon = '/esoui/art/icons/ability_u26_vampire_06.dds'
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
	['Psijic'] = {
	    {
		Ping = 30,
		Name = 'UNDO',
		Icon = '/esoui/art/icons/ability_psijic_001.dds'
	    }
	},
	['Necromancer'] = {
	    {
		Ping = 32,
		Name = 'COLOSSUS',
		Icon = '/esoui/art/icons/ability_necromancer_006.dds'
	    },
	    {
		Ping = 33,
		Name = 'GOLIATH',
		Icon = '/esoui/art/icons/ability_necromancer_012.dds'
	    },
	    {
		Name = 'REANIMATE',
		Ping = 34,
		Icon = '/esoui/art/icons/ability_necromancer_018.dds'
	    }
	},
	['POC'] = {
	    {
		Name = 'MIA',
		Ping = 0,
		Desc = 'POC: Incommunicado Player',
		Aid = 'MIA',
		Icon = MIAicon
	    }
	}
    }

    -- Create tables indexed by different things
    local iconlist = mkulttbl(ults)
    local maxping = 0
    for class, x in pairs(ults) do
	for _, group in ipairs(x) do
	    local ping
	    if group.Aid then
		byids[group.Aid] = group
	    else
		local icon = group.Icon
		if not iconlist[icon]  then
		    Error(string.format('no icon found for: %s', group.Name))
		else
		    local aid = iconlist[icon]
		    group.Aid = aid
		    group.Desc = string.format('%s: %s', class, GetAbilityName(aid))
		    byids[aid] = group
		end
	    end
	    if group.Ping > 0 then
		bypings[group.Ping] = group
	    end
	    if group.Ping > maxping then
		maxping = group.Ping
	    end
	end
    end

    maxping = maxping + 1
    mia = byids['MIA']
    mia.IsMIA = true
    mia.Ping = maxping
    Ult.MaxPing = maxping
    bypings[maxping] = mia

    local i = 0
    i = insert_group_table(bynames, ults, class, i)
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
    i = insert_group_table(bynames, ults, "Psijic", i)
    for _, class in pairs(classes) do
	if ults[class] ~= nil then
	    i = insert_group_table(bynames, ults, class, i)
	end
    end
end

function Ult.GetSaved(n)
    if myults[n] ~= nil then
	-- should never be non-nil, but...
	local ult = Ult.ByPing(myults[n])
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
    saved.AutUlt = false;
    if apid == nil then
	local one = myults[1]
	myults[1] = myults[2]
	myults[2] = one
    else
	if myults == nil then
	    myults = saved.MyUltId[ultix] or {}
	    saved.MyUltId[ultix] = saved.MyUltId[ultix] or myults
	end
	myults[n] = apid
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

local function ability_used(slotnum, power)
    if slotnum == 8 then
	Comm.UltFired(GetSlotBoundId(8), power or GetUnitPower("player", POWERTYPE_ULTIMATE))
    end
end

local function ability_updated(n)
    watch("ability_updated", n)
    if saved.AutUlt and GetActiveWeaponPairInfo() == 1 then
	Player.SetUlt()
    end
end

-- Initialize Ult
--
function Ult.Initialize(_saved)
    saved = _saved
    myults = saved.MyUltId[ultix]
    saved.UltAbilities = nil
    create_ults()
    if saved.AutUlt then
	Player.SetUlt()
    end
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_ACTION_SLOT_ABILITY_USED, function (_, n) ability_used(n) end)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_SKILL_RESPEC_RESULT, function () ability_updated('respec') end)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_ABILITY_LIST_CHANGED, function () ability_updated('ability list changed') end)

    for n, v in pairs(saved.MyUltId) do
	if type(v) ~= 'table' then
	    if v > Ult.MaxPing then
		local x = Ult.ByAid(v)
		if x then
		    v = x.Ping
		else
		    v = nil
		end
	    end
	    saved.MyUltId[n] = {[1] = v, [2] = 'MIA'}
	end
    end
    Slash('sendult', 'debugging: pretend that an ultimate fired', function(x)
	x = tonumber(x)
	if not x or x <= 0 then
	    ability_used(8, GetUnitPower("player", POWERTYPE_ULTIMATE) + 10)
	else
	    Comm.UltFired(x, 9999)
	end
    end)
    Slash('npc', 'set NPC on/off', function(x)
	local onoff
	if x ==	 'on' then
	    onoff = true
	else
	    onoff = false
	end
	SetCrownCrateNPCVisible(onoff)
    end)
end
