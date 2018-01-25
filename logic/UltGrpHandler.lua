local LOG_ACTIVE = false
local _logger = nil

POC_UltGrpHandler = {
    Name = "POC-UltGrpHandler",
    UltGrpByIds = {},
    UltGrpByNames = {},
    UltGrpByPings = {}
}
POC_UltGrpHandler.__index = POC_UltGrpHandler

local ultix = GetUnitName("player")

--[[
	GetUltGrpByAbilityPing gets the ultimate group from given ability ping
]]--
function POC_UltGrpHandler.GetUltGrpByAbilityPing(pid)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltGrpHandler.GetUltGrpByAbilityPing")
        _logger:logDebug("pid", pid)
    end

    if POC_UltGrpHandler.UltGrpByPings[pid] ~= nil then
        return POC_UltGrpHandler.UltGrpByPings[pid]
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(pid))

    return nil
end

--[[
	GetUltGrpByAbilityId gets the ultimate group from given ability ID
]]--
function POC_UltGrpHandler.GetUltGrpByAbilityId(aid)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltGrpHandler.GetUltGrpByAbilityId")
        _logger:logDebug("aid", aid)
    end

    if POC_UltGrpHandler.UltGrpByIds[aid] ~= nil then
        return POC_UltGrpHandler.UltGrpByIds[aid]
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(aid))

    return nil
end

--[[
	GetUltGrpByGroupName gets the ultimate group from given group name
]]--
function POC_UltGrpHandler.GetUltGrpByGroupName(gname)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltGrpHandler.GetUltGrpByGroupName")
        _logger:logDebug("groupName", groupName)
    end

    if POC_UltGrpHandler.UltGrpByNames[gname] ~= nil then
        return POC_UltGrpHandler.UltGrpByNames[gname]
    end

    -- not found
    _logger:logError("GroupName not found " .. tostring(gname))

    return nil
end

-- GetUltGrps gets all ultimate groups
--
function POC_UltGrpHandler.GetUltGrps()
    if LOG_ACTIVE then
        _logger:logTrace("POC_UltGrpHandler.GetUltGrps")
    end

    return POC_IdSort(POC_UltGrpHandler.UltGrpByNames, "Id")
end

local function insert_group_table(to_table, from_table, from_key, i)
    for k, v in pairs(from_table[from_key]) do
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
        to_table[k] = v
    end
    from_table[from_key] = nil
    return i
end

-- CreateUltGrps Creates UltGrps array
--
function POC_UltGrpHandler.CreateUltGrps()
    if (LOG_ACTIVE) then _logger:logTrace("POC_UltGrpHandler.CreateUltGrps") end

    local class = GetUnitClass("player")
    local ults = {
        ["Sorceror"] = {
            ["NEGATE"] = {
                GroupDescription = GetString(POC_DESCRIPTIONS_NEGATE),
                GroupAbilityPing = 1,
                GroupAbilityId = 29861
            },

	    ["ATRO"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_ATRO),
		GroupAbilityPing = 2,
		GroupAbilityId = 30553
	    },
	    ["OVER"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_OVER),
		GroupAbilityPing = 3,
		GroupAbilityId = 30366
	    },
        },
        ["Templar"] = {
	    ["SWEEP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SWEEP),
		GroupAbilityPing = 4,
		GroupAbilityId = 23788
	    },    
	    ["NOVA"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_NOVA),
		GroupAbilityPing = 5,
		GroupAbilityId = 24301
	    },
	    ["TPHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_TPHEAL),
		GroupAbilityPing = 6,
		GroupAbilityId = 27413
	    },
        },
        ["Dragonknight"] = {
	    ["STAND"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STAND),
		GroupAbilityPing = 7,
		GroupAbilityId = 34021
	    },
	    ["LEAP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_LEAP),
		GroupAbilityPing = 8,
		GroupAbilityId = 33668
	    },
	    ["MAGMA"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_MAGMA),
		GroupAbilityPing = 9,
		GroupAbilityId = 33841
	    },
        },
        ["Nightblade"] = {
	    ["STROKE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STROKE),
		GroupAbilityPing = 10,
		GroupAbilityId = 37545
	    },
	    ["VEIL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_VEIL),
		GroupAbilityPing = 11,
		GroupAbilityId = 37713
	    },
	    ["NBSOUL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_NBSOUL),
		GroupAbilityPing = 12,
		GroupAbilityId = 36207
	    },
        },
        ["Warden"] = {
            -- BEAR not useful, its always up
	    ["FREEZE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_FREEZE),
		GroupAbilityPing = 13,
		GroupAbilityId = 86112
	    },
	    ["WDHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_WDHEAL),
		GroupAbilityPing = 14,
		GroupAbilityId = 93971
	    },
        },
        ["WEAPON"] = {
            -- Destro
	    ["ICE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_ICE),
		GroupAbilityPing = 15,
		GroupAbilityId = 86542
	    },
	    ["FIRE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_FIRE),
		GroupAbilityPing = 16,
		GroupAbilityId = 86536
	    },
	    ["LIGHT"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_LIGHT),
		GroupAbilityPing = 17,
		GroupAbilityId = 86550
	    },
            -- Resto
	    ["STHEAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_STHEAL),
		GroupAbilityPing = 18,
		GroupAbilityId = 86454
	    },
            -- 2H
	    ["BERSERK"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BERSERK),
		GroupAbilityPing = 19,
		GroupAbilityId = 86284
	    },
            -- SB
	    ["SHIELD"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SHIELD),
		GroupAbilityPing = 20,
		GroupAbilityId = 83292
	    },
            -- DW
	    ["DUAL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_DUAL),
		GroupAbilityPing = 21,
		GroupAbilityId = 86410
	    },
            -- BOW
	    ["BOW"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BOW),
		GroupAbilityPing = 22,
		GroupAbilityId = 86620
	    },
        },
        ["WORLD"] = {
            -- Soul
	    ["SOUL"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_SOUL),
		GroupAbilityPing = 23,
		GroupAbilityId = 43109
	    },
            -- Werewolf
	    ["WERE"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_WERE),
		GroupAbilityPing = 24,
		GroupAbilityId = 42379
	    },
            -- Vamp
	    ["VAMP"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_VAMP),
		GroupAbilityPing = 25,
		GroupAbilityId = 41937
	    },
        },
        ["GUILD"] = {
            -- Mageguild
	    ["METEOR"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_METEOR),
		GroupAbilityPing = 26,
		GroupAbilityId = 42492
	    },
            -- Fighterguild
	    ["DAWN"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_DAWN),
		GroupAbilityPing = 27,
		GroupAbilityId = 42598
	    },
            -- Support
	    ["BARRIER"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_BARRIER),
		GroupAbilityPing = 28,
		GroupAbilityId = 46622
	    },
            -- Assault
	    ["HORN"] = {
		GroupDescription = GetString(POC_DESCRIPTIONS_HORN),
		GroupAbilityPing = 29,
		GroupAbilityId = 46537
	    }
        },
        ["POC"] = {
            ['MIA'] = {
                GroupDescription = "Incommunicado players",
                GroupAbilityPing = 30,  -- a contradiction?
                GroupAbilityId = 'MIA' 
            }
        }

    }
    -- Add groups
    for _, x in pairs(ults) do
        for name, group in pairs(x) do
            group.GroupName = name
            POC_UltGrpHandler.UltGrpByIds[group.GroupAbilityId] = group
            POC_UltGrpHandler.UltGrpByPings[group.GroupAbilityPing] = group
        end
    end
    local i = 0
    i = insert_group_table(POC_UltGrpHandler.UltGrpByNames, ults, class, i)
    if POC_Settings.SavedVariables.MyUltId[ultix] == nil then
        for _, v in ipairs(POC_IdSort(POC_UltGrpHandler.UltGrpByNames, 'Id')) do
            POC_Settings.SetStaticUltimateIDSettings(v.GroupAbilityId)
            break
        end
    end
    i = insert_group_table(POC_UltGrpHandler.UltGrpByNames, ults, "WEAPON", i)
    i = insert_group_table(POC_UltGrpHandler.UltGrpByNames, ults, "GUILD", i)
    i = insert_group_table(POC_UltGrpHandler.UltGrpByNames, ults, "WORLD", i)
    for notmyclass, _ in pairs(ults) do
        i = insert_group_table(POC_UltGrpHandler.UltGrpByNames, ults, notmyclass, i)
    end
end

-- Initialize POC_UltGrpHandler
--
function POC_UltGrpHandler.Initialize(logger)
    if LOG_ACTIVE then
        logger:logTrace("POC_UltGrpHandler.Initialize")
    end

    _logger = logger

    POC_UltGrpHandler.CreateUltGrps()
end
