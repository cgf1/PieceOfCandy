local LOG_ACTIVE = false
local _logger = nil

POC_Ult = {
    Name = "POC-Ult",
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
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.ByPing")
        _logger:logDebug("pid", pid)
    end

    if bypings[pid] ~= nil then
        return bypings[pid]
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(pid))

    return nil
end

--[[
	ById gets the ultimate group from given ability ID
]]--
function POC_Ult.ById(aid)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.ById")
        _logger:logDebug("aid", aid)
    end

    if byids[aid] ~= nil then
        return byids[aid]
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(aid))

    return nil
end

--[[
	ByName gets the ultimate group from given group name
]]--
function POC_Ult.ByName(gname)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.ByName")
        _logger:logDebug("groupName", groupName)
    end

    if bynames[gname] ~= nil then
        return bynames[gname]
    end

    -- not found
    _logger:logError("Name not found " .. tostring(gname))

    return nil
end

-- GetUlts gets all ultimate groups
--
function POC_Ult.GetUlts()
    if LOG_ACTIVE then
        _logger:logTrace("POC_Ult.GetUlts")
    end

    return POC_IdSort(bynames, "Id")
end

function POC_Ult.Icons()
    local iconlist = {}
    for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
        if v.Gid ~= 'MIA' then
            table.insert(iconlist, GetAbilityIcon(v.Gid))
        end
    end
    return iconlist
end

function POC_Ult.Descriptions()
    local desclist = {}
    for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
        if v.Gid ~= 'MIA' then
            table.insert(desclist, v.Desc)
        end
    end
    return desclist
end

local function insert_group_table(to_table, from_table, from_key, i)
    for _, v in ipairs(POC_IdSort(from_table[from_key], 'Gid', 1)) do
        i = i + 1
        v.Id = i
        _, _, name, class = string.find(v.Desc, "^(.*) ultimates from (.+)")
        if name ~= nil then
            class = string.gsub(class, " class$", "")
            class = string.gsub(class, " weapons?$", "")
            class = string.gsub(class, " lines?", "s")
            class = string.gsub(class, "Assoult", "Assault")
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
    if (LOG_ACTIVE) then _logger:logTrace("POC_Ult.CreateUlts") end

    local class = GetUnitClass("player")
    local classes = {
        [1] = "Sorceror",
        [2] = "Templar",
        [3] = "Dragonknight",
        [4] = "Nightblade",
        [5] = "Warden"
    }

    local ults = {
        ["Sorceror"] = {
            ["NEGATE"] = {
                Desc = GetString(POC_DESCRIPTIONS_NEGATE),
                Ping = 1,
                Gid = 29861
            },

	    ["ATRO"] = {
		Desc = GetString(POC_DESCRIPTIONS_ATRO),
		Ping = 2,
		Gid = 30553
	    },
	    ["OVER"] = {
		Desc = GetString(POC_DESCRIPTIONS_OVER),
		Ping = 3,
		Gid = 30366
	    },
        },
        ["Templar"] = {
	    ["SWEEP"] = {
		Desc = GetString(POC_DESCRIPTIONS_SWEEP),
		Ping = 4,
		Gid = 23788
	    },
	    ["NOVA"] = {
		Desc = GetString(POC_DESCRIPTIONS_NOVA),
		Ping = 5,
		Gid = 24301
	    },
	    ["TPHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_TPHEAL),
		Ping = 6,
		Gid = 27413
	    },
        },
        ["Dragonknight"] = {
	    ["STAND"] = {
		Desc = GetString(POC_DESCRIPTIONS_STAND),
		Ping = 7,
		Gid = 34021
	    },
	    ["LEAP"] = {
		Desc = GetString(POC_DESCRIPTIONS_LEAP),
		Ping = 8,
		Gid = 33668
	    },
	    ["MAGMA"] = {
		Desc = GetString(POC_DESCRIPTIONS_MAGMA),
		Ping = 9,
		Gid = 33841
	    },
        },
        ["Nightblade"] = {
	    ["STROKE"] = {
		Desc = GetString(POC_DESCRIPTIONS_STROKE),
		Ping = 10,
		Gid = 37545
	    },
	    ["VEIL"] = {
		Desc = GetString(POC_DESCRIPTIONS_VEIL),
		Ping = 11,
		Gid = 37713
	    },
	    ["NBSOUL"] = {
		Desc = GetString(POC_DESCRIPTIONS_NBSOUL),
		Ping = 12,
		Gid = 36207
	    },
        },
        ["Warden"] = {
            -- BEAR not useful, its always up
	    ["FREEZE"] = {
		Desc = GetString(POC_DESCRIPTIONS_FREEZE),
		Ping = 13,
		Gid = 86112
	    },
	    ["WDHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_WDHEAL),
		Ping = 14,
		Gid = 93971
	    },
        },
        ["WEAPON"] = {
            -- Destro
	    ["ICE"] = {
		Desc = GetString(POC_DESCRIPTIONS_ICE),
		Ping = 15,
		Gid = 86542
	    },
	    ["FIRE"] = {
		Desc = GetString(POC_DESCRIPTIONS_FIRE),
		Ping = 16,
		Gid = 86536
	    },
	    ["LIGHT"] = {
		Desc = GetString(POC_DESCRIPTIONS_LIGHT),
		Ping = 17,
		Gid = 86550
	    },
            -- Resto
	    ["STHEAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_STHEAL),
		Ping = 18,
		Gid = 86454
	    },
            -- 2H
	    ["BERSERK"] = {
		Desc = GetString(POC_DESCRIPTIONS_BERSERK),
		Ping = 19,
		Gid = 86284
	    },
            -- SB
	    ["SHIELD"] = {
		Desc = GetString(POC_DESCRIPTIONS_SHIELD),
		Ping = 20,
		Gid = 83292
	    },
            -- DW
	    ["DUAL"] = {
		Desc = GetString(POC_DESCRIPTIONS_DUAL),
		Ping = 21,
		Gid = 86410
	    },
            -- BOW
	    ["BOW"] = {
		Desc = GetString(POC_DESCRIPTIONS_BOW),
		Ping = 22,
		Gid = 86620
	    },
        },
        ["WORLD"] = {
            -- Soul
	    ["SOUL"] = {
		Desc = GetString(POC_DESCRIPTIONS_SOUL),
		Ping = 23,
		Gid = 43109
	    },
            -- Werewolf
	    ["WERE"] = {
		Desc = GetString(POC_DESCRIPTIONS_WERE),
		Ping = 24,
		Gid = 42379
	    },
            -- Vamp
	    ["VAMP"] = {
		Desc = GetString(POC_DESCRIPTIONS_VAMP),
		Ping = 25,
		Gid = 41937
	    },
        },
        ["GUILD"] = {
            -- Mageguild
	    ["METEOR"] = {
		Desc = GetString(POC_DESCRIPTIONS_METEOR),
		Ping = 26,
		Gid = 42492
	    },
            -- Fighterguild
	    ["DAWN"] = {
		Desc = GetString(POC_DESCRIPTIONS_DAWN),
		Ping = 27,
		Gid = 42598
	    },
            -- Support
	    ["BARRIER"] = {
		Desc = GetString(POC_DESCRIPTIONS_BARRIER),
		Ping = 28,
		Gid = 46622
	    },
            -- Assault
	    ["HORN"] = {
		Desc = GetString(POC_DESCRIPTIONS_HORN),
		Ping = 29,
		Gid = 46537
	    }
        },
        ["POC"] = {
            ['MIA'] = {
                Desc = "Incommunicado players",
                Ping = 30,  -- a contradiction?
                Gid = 'MIA'
            }
        }

    }
    -- Add groups
    for _, x in pairs(ults) do
        for name, group in pairs(x) do
            group.Name = name
            byids[group.Gid] = group
            bypings[group.Ping] = group
        end
    end
    local i = 0
    i = insert_group_table(bynames, ults, class, i)
    if POC_Settings.SavedVariables.MyUltId[ultix] == nil then
        for _, v in ipairs(POC_IdSort(bynames, 'Id')) do
            POC_Settings.SetStaticUltimateIDSettings(v.Gid)
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

function POC_Ult.SetSaved(icon)
    for id, _ in pairs(byids) do
        if id ~= 'MIA' and GetAbilityIcon(id) == icon then

            POC_Settings.SavedVariables.MyUltId[ultix] = id
            return
        end
    end
    d("POC_Ult.SetSaved: unknown icon " .. tostring(icon))
end

-- Initialize POC_Ult
--
function POC_Ult.Initialize(logger)
    if LOG_ACTIVE then
        logger:logTrace("POC_Ult.Initialize")
    end

    _logger = logger

    create_ults()
end
