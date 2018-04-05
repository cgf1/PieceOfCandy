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
	["Sorcerer"] = {
	    {
		Name = "NEGATE",
		Ping = 1,
		Aid = 29861
	    },
	    {
		Name = "ATRO",
		Ping = 2,
		Aid = 30553
	    },
	    {
		Name = "OVER",
		Ping = 3,
		Aid = 30366
	    },
	},
	["Templar"] = {
	    {
		Name = "SWEEP",
		Ping = 4,
		Aid = 23788
	    },
	    {
		Name = "NOVA",
		Ping = 5,
		Aid = 24301
	    },
	    {
		Name = "TPHEAL",
		Ping = 6,
		Aid = 27413
	    },
	},
	["Dragonknight"] = {
	    {
		Name = "STAND",
		Ping = 7,
		Aid = 34021
	    },
	    {
		Name = "LEAP",
		Ping = 8,
		Aid = 33668
	    },
	    {
		Name = "MAGMA",
		Ping = 9,
		Aid = 33841
	    },
	},
	["Nightblade"] = {
	    {
		Name = "STROKE",
		Ping = 10,
		Aid = 37545
	    },
	    {
		Name = "VEIL",
		Ping = 11,
		Aid = 37713
	    },
	    {
		Name = "NBSOUL",
		Ping = 12,
		Aid = 36207
	    },
	},
	["Warden"] = {
	    -- BEAR not useful, its always up
	    {
		Name = "FREEZE",
		Ping = 13,
		Aid = 86112
	    },
	    {
		Name = "WDHEAL",
		Ping = 14,
		Aid = 93971
	    },
	},
	["Destruction Staff"] = {
	    -- Destro
	    {
		Name = "ICE",
		Ping = 15,
		Aid = 86542
	    },
	    {
		Name = "FIRE",
		Ping = 16,
		Aid = 86536
	    },
	    {
		Name = "LIGHT",
		Ping = 17,
		Aid = 86550
	    },
	},
	["Restoration Staff"] = {
	    -- Resto
	    {
		Name = "STHEAL",
		Ping = 18,
		Aid = 86454
	    },
	},
	["Two Handed"] = {
	    -- 2H
	    {
		Name = "BERSERK",
		Ping = 19,
		Aid = 86284
	    },
	},
	["One Hand and Shield"] = {
	    -- SB
	    {
		Name = "SHIELD",
		Ping = 20,
		Aid = 83292
	    },
	},
	["Dual Wield"] = {
	    -- DW
	    {
		Name = "DUAL",
		Ping = 21,
		Aid = 86410
	    },
	},
	["Bow"] = {
	    -- BOW
	    {
		Name = "BOW",
		Ping = 22,
		Aid = 86620
	    },
	},
	["Soul Magic"] = {
	    -- Soul
	    {
		Name = "SOUL",
		Ping = 23,
		Aid = 43109
	    },
	},
	["Werewolf"] = {
	    -- Werewolf
	    {
		Name = "WERE",
		Ping = 24,
		Aid = 42379
	    },
	},
	["Vampire"] = {
	    -- Vamp
	    {
		Name = "VAMP",
		Ping = 25,
		Aid = 41937
	    },
	},
	["Mages Guild"] = {
	    -- Mageguild
	    {
		Name = "METEOR",
		Ping = 26,
		Aid = 42492
	    },
	},
	["Fighters Guild"] = {
	    -- Fighterguild
	    {
		Name = "DAWN",
		Ping = 27,
		Aid = 42598
	    }
	},
	["PVP"] = {
	    -- Support
	    {
		Name = "BARRIER",
		Ping = 28,
		Aid = 46622
	    },
	    -- Assault
	    {
		Name = "HORN",
		Ping = 29,
		Aid = 46537
	    }
	},
	["POC"] = {
	    {
		Name = "MIA",
		Desc = "Incommunicado Player",
		Icon = MIAicon,
		Ping = 30,  -- a contradiction?
		Aid = 'MIA'
	    }
	}

    }
    -- Add groups
    for class, x in pairs(ults) do
	for _, group in pairs(x) do
	    if group.Desc == nil then
		group.Desc = string.format("%s: %s", class, GetAbilityName(group.Aid))
	    end
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
    ids[7] = nil
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
    saved.LaneIds[7] = 'MIA'
    for n, v in pairs(saved.MyUltId) do
	if type(v) ~= 'table' then
	    if v > Ult.MaxPing then
		v = Ult.ByAid(v).Ping
	    end
	    saved.MyUltId[n] = {[1] = v, [2] = 'MIA'}
	end
    end
end
