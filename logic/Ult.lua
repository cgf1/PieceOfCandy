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
	GetUltByAbilityPing gets the ultimate group from given ability ping
]]--
function POC_Ult.GetUltByAbilityPing(pid)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.GetUltByAbilityPing")
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
	GetUltByAbilityId gets the ultimate group from given ability ID
]]--
function POC_Ult.GetUltByAbilityId(aid)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.GetUltByAbilityId")
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
	GetUltByName gets the ultimate group from given group name
]]--
function POC_Ult.GetUltByName(gname)
    if (LOG_ACTIVE) then
        _logger:logTrace("POC_Ult.GetUltByName")
        _logger:logDebug("groupName", groupName)
    end

    if bynames[gname] ~= nil then
        return bynames[gname]
    end

    -- not found
    _logger:logError("GroupName not found " .. tostring(gname))

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
            table.insert(desclist, v.GroupDescription)
        end
    end
    return desclist
end

local function insert_group_table(to_table, from_table, from_key, i)
    for _, v in ipairs(POC_IdSort(from_table[from_key], 'Gid', 1)) do
        i = i + 1
        v.Id = i
        _, _, name, class = string.find(v.GroupDescription, "^(.*) ultimates from (.+)")
        if name ~= nil then
            class = string.gsub(class, " class$", "")
            class = string.gsub(class, " weapons?$", "")
            class = string.gsub(class, " lines?", "s")
            class = string.gsub(class, "Assoult", "Assault")
            v.GroupDescription = name .. " (" .. class .. ")"
        end
        to_table[v.GroupName] = v
    end
    from_table[from_key] = nil
    return i
end

-- CreateUlts Creates Ults array
--
function POC_Ult.CreateUlts()
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
                GroupDescription = GetString(POC_DESCRIPTIONS_NEGATE),
                GroupAbilityPing = 1,
                Gid = 29861
            },

	    ["ATRO"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_ATRO),
		GroupAbilityPing = 2,
		Gid = 30553
	    },
	    ["OVER"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_OVER),
		GroupAbilityPing = 3,
		Gid = 30366
	    },
        },
        ["Templar"] = {
	    ["SWEEP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SWEEP),
		GroupAbilityPing = 4,
		Gid = 23788
	    },
	    ["NOVA"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_NOVA),
		GroupAbilityPing = 5,
		Gid = 24301
	    },
	    ["TPHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_TPHEAL),
		GroupAbilityPing = 6,
		Gid = 27413
	    },
        },
        ["Dragonknight"] = {
	    ["STAND"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STAND),
		GroupAbilityPing = 7,
		Gid = 34021
	    },
	    ["LEAP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_LEAP),
		GroupAbilityPing = 8,
		Gid = 33668
	    },
	    ["MAGMA"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_MAGMA),
		GroupAbilityPing = 9,
		Gid = 33841
	    },
        },
        ["Nightblade"] = {
	    ["STROKE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STROKE),
		GroupAbilityPing = 10,
		Gid = 37545
	    },
	    ["VEIL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_VEIL),
		GroupAbilityPing = 11,
		Gid = 37713
	    },
	    ["NBSOUL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_NBSOUL),
		GroupAbilityPing = 12,
		Gid = 36207
	    },
        },
        ["Warden"] = {
            -- BEAR not useful, its always up
	    ["FREEZE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_FREEZE),
		GroupAbilityPing = 13,
		Gid = 86112
	    },
	    ["WDHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_WDHEAL),
		GroupAbilityPing = 14,
		Gid = 93971
	    },
        },
        ["WEAPON"] = {
            -- Destro
	    ["ICE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_ICE),
		GroupAbilityPing = 15,
		Gid = 86542
	    },
	    ["FIRE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_FIRE),
		GroupAbilityPing = 16,
		Gid = 86536
	    },
	    ["LIGHT"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_LIGHT),
		GroupAbilityPing = 17,
		Gid = 86550
	    },
            -- Resto
	    ["STHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STHEAL),
		GroupAbilityPing = 18,
		Gid = 86454
	    },
            -- 2H
	    ["BERSERK"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BERSERK),
		GroupAbilityPing = 19,
		Gid = 86284
	    },
            -- SB
	    ["SHIELD"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SHIELD),
		GroupAbilityPing = 20,
		Gid = 83292
	    },
            -- DW
	    ["DUAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_DUAL),
		GroupAbilityPing = 21,
		Gid = 86410
	    },
            -- BOW
	    ["BOW"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BOW),
		GroupAbilityPing = 22,
		Gid = 86620
	    },
        },
        ["WORLD"] = {
            -- Soul
	    ["SOUL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SOUL),
		GroupAbilityPing = 23,
		Gid = 43109
	    },
            -- Werewolf
	    ["WERE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_WERE),
		GroupAbilityPing = 24,
		Gid = 42379
	    },
            -- Vamp
	    ["VAMP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_VAMP),
		GroupAbilityPing = 25,
		Gid = 41937
	    },
        },
        ["GUILD"] = {
            -- Mageguild
	    ["METEOR"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_METEOR),
		GroupAbilityPing = 26,
		Gid = 42492
	    },
            -- Fighterguild
	    ["DAWN"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_DAWN),
		GroupAbilityPing = 27,
		Gid = 42598
	    },
            -- Support
	    ["BARRIER"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BARRIER),
		GroupAbilityPing = 28,
		Gid = 46622
	    },
            -- Assault
	    ["HORN"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_HORN),
		GroupAbilityPing = 29,
		Gid = 46537
	    }
        },
        ["POC"] = {
            ['MIA'] = {
                GroupDescription = "Incommunicado players",
                GroupAbilityPing = 30,  -- a contradiction?
                Gid = 'MIA'
            }
        }

    }
    -- Add groups
    for _, x in pairs(ults) do
        for name, group in pairs(x) do
            group.GroupName = name
            byids[group.Gid] = group
            bypings[group.GroupAbilityPing] = group
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

    POC_Ult.CreateUlts()
end
