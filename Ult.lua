POC_Ult = {
    Name = "POC_Ult",
    MaxPing = 0,
    Me = 0
}
POC_Ult.__index = POC_Ult

local ultix = GetUnitName("player")
local bynames = {}
local byids = {}
local bypings = {}

local saved
local xxx
local myults

-- ByPing gets the ultimate group from given ability ping
--
function POC_Ult.ByPing(pid)
    if bypings[pid] ~= nil then
	return bypings[pid]
    end

    -- not found
    -- POC_Error("AbilityId not found " .. tostring(pid))

    return nil
end

-- ByAid gets the ultimate group from given ability ID
--
function POC_Ult.ByAid(aid)
    if byids[aid] ~= nil then
	return byids[aid]
    end

    -- not found
    POC_Error("AbilityId not found " .. tostring(aid))

    return nil
end

-- ByName gets the ultimate group from given group name
--
function POC_Ult.ByName(gname)
    if bynames[gname] ~= nil then
	return bynames[gname]
    end

    -- not found
    POC_Error("Name not found " .. tostring(gname))

    return nil
end

-- GetUlts gets all ultimate groups
--
function POC_Ult.GetUlts()
    return POC_IdSort(bynames, "Id")
end

function POC_Ult.Icons()
    local icons = {}
    for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
	if v.Aid ~= 'MIA' then
	    table.insert(icons, GetAbilityIcon(v.Aid))
	end
    end
    return icons
end

function POC_Ult.Descriptions()
    local desclist = {}
    for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
	if v.Aid ~= 'MIA' then
	    table.insert(desclist, v.Desc)
	end
    end
    return desclist
end

local function insert_group_table(to_table, from_table, from_key, i)
    for _, v in ipairs(POC_IdSort(from_table[from_key], 'Aid', 1)) do
	i = i + 1
	v.Id = i
	to_table[v.Name] = v
    end
    from_table[from_key] = nil
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
	    ["NEGATE"] = {
		Ping = 1,
		Aid = 29861
	    },

	    ["ATRO"] = {
		Ping = 2,
		Aid = 30553
	    },
	    ["OVER"] = {
		Ping = 3,
		Aid = 30366
	    },
	},
	["Templar"] = {
	    ["SWEEP"] = {
		Ping = 4,
		Aid = 23788
	    },
	    ["NOVA"] = {
		Ping = 5,
		Aid = 24301
	    },
	    ["TPHEAL"] = {
		Ping = 6,
		Aid = 27413
	    },
	},
	["Dragonknight"] = {
	    ["STAND"] = {
		Ping = 7,
		Aid = 34021
	    },
	    ["LEAP"] = {
		Ping = 8,
		Aid = 33668
	    },
	    ["MAGMA"] = {
		Ping = 9,
		Aid = 33841
	    },
	},
	["Nightblade"] = {
	    ["STROKE"] = {
		Ping = 10,
		Aid = 37545
	    },
	    ["VEIL"] = {
		Ping = 11,
		Aid = 37713
	    },
	    ["NBSOUL"] = {
		Ping = 12,
		Aid = 36207
	    },
	},
	["Warden"] = {
	    -- BEAR not useful, its always up
	    ["FREEZE"] = {
		Ping = 13,
		Aid = 86112
	    },
	    ["WDHEAL"] = {
		Ping = 14,
		Aid = 93971
	    },
	},
	["Destruction Staff"] = {
	    -- Destro
	    ["ICE"] = {
		Ping = 15,
		Aid = 86542
	    },
	    ["FIRE"] = {
		Ping = 16,
		Aid = 86536
	    },
	    ["LIGHT"] = {
		Ping = 17,
		Aid = 86550
	    },
	},
	["Restoration Staff"] = {
	    -- Resto
	    ["STHEAL"] = {
		Ping = 18,
		Aid = 86454
	    },
	},
	["Two Handed"] = {
	    -- 2H
	    ["BERSERK"] = {
		Ping = 19,
		Aid = 86284
	    },
	},
	["One Hand and Shield"] = {
	    -- SB
	    ["SHIELD"] = {
		Ping = 20,
		Aid = 83292
	    },
	},
	["Dual Wield"] = {
	    -- DW
	    ["DUAL"] = {
		Ping = 21,
		Aid = 86410
	    },
	},
	["Bow"] = {
	    -- BOW
	    ["BOW"] = {
		Ping = 22,
		Aid = 86620
	    },
	},
	["Soul Magic"] = {
	    -- Soul
	    ["SOUL"] = {
		Ping = 23,
		Aid = 43109
	    },
	},
	["Werewolf"] = {
	    -- Werewolf
	    ["WERE"] = {
		Ping = 24,
		Aid = 42379
	    },
	},
	["Vampire"] = {
	    -- Vamp
	    ["VAMP"] = {
		Ping = 25,
		Aid = 41937
	    },
	},
	["Mages Guild"] = {
	    -- Mageguild
	    ["METEOR"] = {
		Ping = 26,
		Aid = 42492
	    },
	},
	["Fighters Guild"] = {
	    -- Fighterguild
	    ["DAWN"] = {
		Ping = 27,
		Aid = 42598
	    }
	},
	["PVP"] = {
	    -- Support
	    ["BARRIER"] = {
		Ping = 28,
		Aid = 46622
	    },
	    -- Assault
	    ["HORN"] = {
		Ping = 29,
		Aid = 46537
	    }
	},
	["POC"] = {
	    ['MIA'] = {
		Desc = "Incommunicado Player",
		Ping = 30,  -- a contradiction?
		Aid = 'MIA'
	    }
	}

    }
    -- Add groups
    for class, x in pairs(ults) do
	for name, group in pairs(x) do
	    group.Name = name
	    if group.Desc == nil then
		group.Desc = class .. ': ' .. GetAbilityName(group.Aid)
	    end
	    byids[group.Aid] = group
	    bypings[group.Ping] = group
	    if group.Ping > POC_Ult.MaxPing then
		POC_Ult.MaxPing = group.Ping
	    end
	end
    end
    local i = 0
    i = insert_group_table(bynames, ults, class, i)
    if saved.MyUltId[ultix] == nil then
	for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
	    POC_Ult.SetSavedId(v.Aid, 1)
	    POC_Ult.SetSavedId('MIA', 2)
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
	if ults[class] ~= null then
	    i = insert_group_table(bynames, ults, class, i)
	end
    end
end

function POC_Ult.GetSaved(n)
    local ret
    if saved.MyUltId[ultix][n] == nil then
	-- should never happen
    else
	local ult = POC_Ult.ByPing(saved.MyUltId[ultix][n])
	if ult == nil or ult.Aid == 'MIA' then
	    ret = "/POC/icons/lollipop.dds"
	else
	    ret = GetAbilityIcon(ult.Aid)
	end
    end
    return ret
end

function POC_Ult.UltApidFromIcon(icon)
    for id, v in pairs(byids) do
	if id ~= 'MIA' and GetAbilityIcon(id) == icon then
	    return v.Ping
	end
    end
    return nil
end

function POC_Ult.SetSavedId(apid, n)
    if saved.MyUltId[ultix] == nil then
	saved.MyUltId[ultix] = {}
    end
xxx("Setting ", n, "to", apid)
    saved.MyUltId[ultix][n] = apid
end

function POC_Ult.SetSavedFromIcon(icon, n)
    local apid = POC_Ult.UltApidFromIcon(icon)
    if apid ~= nil then
	POC_Ult.SetSavedId(apid, n)
	return
    end
    d("POC_Ult.SetSaved: unknown icon " .. tostring(icon))
end

-- Initialize POC_Ult
--
function POC_Ult.Initialize()
    saved = POC_Settings.SavedVariables
    create_ults()
    xxx = POC.xxx

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
    for i, v in ipairs(ids) do
	if v > POC_Ult.MaxPing then
	    newultids[i] = POC_Ult.ByAid(v).Ping
	    changed = true
	end
    end
    if changed then
	saved.LaneIds = newultids
    end
    saved.LaneIds[7] = 'MIA'
    for n, v in pairs(saved.MyUltId) do
	if type(v) ~= 'table' then
	    if v > POC_Ult.MaxPing then
		v = POC_Ult.ByAid(v).Ping
	    end
	    saved.MyUltId[n] = {[1] = v, [2] = 'MIA'}
	end
    end
end
