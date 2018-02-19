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

--[[
	ByPing gets the ultimate group from given ability ping
]]--
function POC_Ult.ByPing(pid)
    if bypings[pid] ~= nil then
	return bypings[pid]
    end

    -- not found
    -- POC_Error("AbilityId not found " .. tostring(pid))

    return nil
end

--[[
	ById gets the ultimate group from given ability ID
]]--
function POC_Ult.ById(aid)
    if byids[aid] ~= nil then
	return byids[aid]
    end

    -- not found
    POC_Error("AbilityId not found " .. tostring(aid))

    return nil
end

--[[
	ByName gets the ultimate group from given group name
]]--
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
    local iconlist = {}
    for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
	if v.Aid ~= 'MIA' then
	    table.insert(iconlist, GetAbilityIcon(v.Aid))
	end
    end
    return iconlist
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
	local name, class
	_, _, name, class = string.find(v.Desc, "^(.*) ultimates from (.+)")
	if name ~= nil then
	    class = string.gsub(class, " class$", "")
	    class = string.gsub(class, " weapons?$", "")
	    class = string.gsub(class, " lines?", "s")
	    v.Desc = name .. " (" .. class .. ")"
	end
	to_table[v.Name] = v
    end
    from_table[from_key] = nil
    return i
end

-- Create Ults array
--
local function create_ults()
    local class = GetUnitClass("player")
    local classes = {
	[1] = "Sorcerer",
	[2] = "Templar",
	[3] = "Dragonknight",
	[4] = "Nightblade",
	[5] = "Warden"
    }

    local ults = {
	["Sorcerer"] = {
	    ["NEGATE"] = {
		Desc = GetString(POC_DESCRIPTIONS_NEGATE),
		Ping = 1,
		Aid = 29861
	    },

	    ["ATRO"] = {
		Desc = GetString(POC_DESCRIPTIONS_ATRO),
		Ping = 2,
		Aid = 30553
	    },
	    ["OVER"] = {
		Desc = GetString(POC_DESCRIPTIONS_OVER),
		Ping = 3,
		Aid = 30366
	    },
	},
	["Templar"] = {
	    ["SWEEP"] = {
		Desc = GetString(POC_DESCRIPTIONS_SWEEP),
		Ping = 4,
		Aid = 23788
	    },
	    ["NOVA"] = {
		Desc = GetString(POC_DESCRIPTIONS_NOVA),
		Ping = 5,
		Aid = 24301
	    },
	    ["TPHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_TPHEAL),
		Ping = 6,
		Aid = 27413
	    },
	},
	["Dragonknight"] = {
	    ["STAND"] = {
		Desc = GetString(POC_DESCRIPTIONS_STAND),
		Ping = 7,
		Aid = 34021
	    },
	    ["LEAP"] = {
		Desc = GetString(POC_DESCRIPTIONS_LEAP),
		Ping = 8,
		Aid = 33668
	    },
	    ["MAGMA"] = {
		Desc = GetString(POC_DESCRIPTIONS_MAGMA),
		Ping = 9,
		Aid = 33841
	    },
	},
	["Nightblade"] = {
	    ["STROKE"] = {
		Desc = GetString(POC_DESCRIPTIONS_STROKE),
		Ping = 10,
		Aid = 37545
	    },
	    ["VEIL"] = {
		Desc = GetString(POC_DESCRIPTIONS_VEIL),
		Ping = 11,
		Aid = 37713
	    },
	    ["NBSOUL"] = {
		Desc = GetString(POC_DESCRIPTIONS_NBSOUL),
		Ping = 12,
		Aid = 36207
	    },
	},
	["Warden"] = {
	    -- BEAR not useful, its always up
	    ["FREEZE"] = {
		Desc = GetString(POC_DESCRIPTIONS_FREEZE),
		Ping = 13,
		Aid = 86112
	    },
	    ["WDHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_WDHEAL),
		Ping = 14,
		Aid = 93971
	    },
	},
	["WEAPON"] = {
	    -- Destro
	    ["ICE"] = {
		Desc = GetString(POC_DESCRIPTIONS_ICE),
		Ping = 15,
		Aid = 86542
	    },
	    ["FIRE"] = {
		Desc = GetString(POC_DESCRIPTIONS_FIRE),
		Ping = 16,
		Aid = 86536
	    },
	    ["LIGHT"] = {
		Desc = GetString(POC_DESCRIPTIONS_LIGHT),
		Ping = 17,
		Aid = 86550
	    },
	    -- Resto
	    ["STHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_STHEAL),
		Ping = 18,
		Aid = 86454
	    },
	    -- 2H
	    ["BERSERK"] = {
		Desc = GetString(POC_DESCRIPTIONS_BERSERK),
		Ping = 19,
		Aid = 86284
	    },
	    -- SB
	    ["SHIELD"] = {
		Desc = GetString(POC_DESCRIPTIONS_SHIELD),
		Ping = 20,
		Aid = 83292
	    },
	    -- DW
	    ["DUAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_DUAL),
		Ping = 21,
		Aid = 86410
	    },
	    -- BOW
	    ["BOW"] = {
		Desc = GetString(POC_DESCRIPTIONS_BOW),
		Ping = 22,
		Aid = 86620
	    },
	},
	["WORLD"] = {
	    -- Soul
	    ["SOUL"] = {
		Desc = GetString(POC_DESCRIPTIONS_SOUL),
		Ping = 23,
		Aid = 43109
	    },
	    -- Werewolf
	    ["WERE"] = {
		Desc = GetString(POC_DESCRIPTIONS_WERE),
		Ping = 24,
		Aid = 42379
	    },
	    -- Vamp
	    ["VAMP"] = {
		Desc = GetString(POC_DESCRIPTIONS_VAMP),
		Ping = 25,
		Aid = 41937
	    },
	},
	["GUILD"] = {
	    -- Mageguild
	    ["METEOR"] = {
		Desc = GetString(POC_DESCRIPTIONS_METEOR),
		Ping = 26,
		Aid = 42492
	    },
	    -- Fighterguild
	    ["DAWN"] = {
		Desc = GetString(POC_DESCRIPTIONS_DAWN),
		Ping = 27,
		Aid = 42598
	    },
	    -- Support
	    ["BARRIER"] = {
		Desc = GetString(POC_DESCRIPTIONS_BARRIER),
		Ping = 28,
		Aid = 46622
	    },
	    -- Assault
	    ["HORN"] = {
		Desc = GetString(POC_DESCRIPTIONS_HORN),
		Ping = 29,
		Aid = 46537
	    }
	},
	["POC"] = {
	    ['MIA'] = {
		Desc = "Incommunicado player",
		Ping = 30,  -- a contradiction?
		Aid = 'MIA'
	    }
	}

    }
    -- Add groups
    for _, x in pairs(ults) do
	for name, group in pairs(x) do
	    group.Name = name
	    byids[group.Aid] = group
	    bypings[group.Ping] = group
	    if group.Ping > POC_Ult.MaxPing then
		POC_Ult.MaxPing = group.Ping
	    end
	end
    end
    local i = 0
    i = insert_group_table(bynames, ults, class, i)
    if POC_Settings.SavedVariables.MyUltId[ultix] == nil then
	for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
	    POC_Settings.SetStaticUltimateIDSettings(v.Aid)
	    break
	end
    end
    i = insert_group_table(bynames, ults, "WEAPON", i)
    i = insert_group_table(bynames, ults, "GUILD", i)
    i = insert_group_table(bynames, ults, "WORLD", i)
    for _, class in pairs(classes) do
	if ults[class] ~= null then
	    i = insert_group_table(bynames, ults, class, i)
	end
    end
end

function POC_Ult.GetSaved()
    if POC_Settings.SavedVariables.MyUltId[ultix] == nil then
	-- should never happen
    else
	return GetAbilityIcon(POC_Settings.SavedVariables.MyUltId[ultix])
    end
end

function POC_Ult.UltFromIcon(icon)
    for id, _ in pairs(byids) do
	if id ~= 'MIA' and GetAbilityIcon(id) == icon then
	    return id
	end
    end
    return nil
end

function POC_Ult.SetSavedId(id)
    POC_Settings.SavedVariables.MyUltId[ultix] = id
    POC_Ult.Me = POC_Ult.ById(id)
end

function POC_Ult.SetSaved(icon)
    local id = POC_Ult.UltFromIcon(icon)
    if id ~= nil then
	POC_Ult.SetSavedId(id)
	return
    end
    d("POC_Ult.SetSaved: unknown icon " .. tostring(icon))
end

-- Initialize POC_Ult
--
function POC_Ult.Initialize()
    create_ults()
    POC_Ult.Me = POC_Ult.ById(POC_Settings.SavedVariables.MyUltId[ultix])
end
