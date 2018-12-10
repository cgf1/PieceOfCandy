setfenv(1, POC)
Test = {
    Name = 'POC_Test'
}
Test.__index = Test

local saved

local testgroup = {
    ["Sirech"] = {
	["IsMe"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["InCombat"] = false,
	["IsLeader"] = false,
	["PingTag"] = "group2",
	["Pos"] = 0,
	["Online"] = true,
	["UltMain"] = 13,
	["Version"] = "3.22",
	["Visited"] = true,
	["InRange"] = false,
	["Ults"] = {
	    [30] = 0,
	    [13] = 100,
	},
	["TimeStamp"] = 1530381942,
    },
    ["Stomp Man"] = {
	["IsLeader"] = false,
	["PingTag"] = "group3",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["-Volkanos"] = {
	["UltMain"] = 16,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [16] = 42,
	    [30] = 0,
	},
	["InRange"] = false,
	["Visited"] = false,
	["PingTag"] = "group6",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725744,
    },
    ["Ulmron Madrtis"] = {
	["UltMain"] = 16,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [16] = 57,
	    [30] = 0,
	},
	["InRange"] = false,
	["Visited"] = false,
	["PingTag"] = "group2",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725740,
    },
    ["Valandil Tiwel"] = {
	["UltMain"] = 13,
	["HasTimedOut"] = false,
	["StealthState"] = 0,
	["IsLeader"] = true,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [30] = 0,
	    [13] = 122,
	},
	["InRange"] = true,
	["Visited"] = true,
	["InRangeTime"] = 1543725745,
	["PingTag"] = "group9",
	["InCombat"] = false,
	["HasBeenLeader"] = true,
	["IsDead"] = false,
	["IsMe"] = true,
	["Version"] = "3.30",
	["FwCampTimer"] = 0,
	["Because"] = "ultpct == 100",
	["TimeStamp"] = 1543725745,
    },
    ["Iri Copperwing"] = {
	["IsMe"] = false,
	["HasTimedOut"] = false,
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [6] = 123,
	    [30] = 0,
	},
	["InRange"] = false,
	["Visited"] = false,
	["PingTag"] = "group8",
	["InCombat"] = false,
	["IsDead"] = false,
	["UltMain"] = 6,
	["FwCampTimer"] = 0,
	["Version"] = "3.30",
	["TimeStamp"] = 1543725740,
    },
    ["Volcifar"] = {
	["UltMain"] = 16,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = 
	{
	    [16] = 58,
	    [30] = 0,
	},
	["InRange"] = false,
	{
	    [false] = "Volcifar",
	    [true] = "Volcifar",
	},
	["Visited"] = true,
	["PingTag"] = "group4",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725745,
    },
    ["Anaya Serenddulas"] = {
	["UltMain"] = 13,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [14] = 100,
	    [13] = 48,
	},
	["InRange"] = true,
	["Visited"] = false,
	["PingTag"] = "group3",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725743,
    },
    ["Bitting"] = {
	["UltMain"] = 1,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [1] = 71,
	    [30] = 0,
	},
	["InRange"] = true,
	["Visited"] = false,
	["PingTag"] = "group5",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725743,
    },
    ["Morgan the Streaker"] = {
	["UltMain"] = 1,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [1] = 57,
	    [30] = 0,
	},
	["InRange"] = false,
	["Visited"] = false,
	["PingTag"] = "group1",
	["InCombat"] = false,
	["HasBeenLeader"] = true,
	["IsDead"] = false,
	["HasTimedOut"] = true,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725700,
    },
    ["War-DÃ©jÃ "] = {
	["UltMain"] = 13,
	["Version"] = "3.30",
	["StealthState"] = 0,
	["IsLeader"] = false,
	["Pos"] = 0,
	["Online"] = true,
	["Ults"] = {
	    [30] = 0,
	    [13] = 123,
	},
	["InRange"] = true,
	["Visited"] = false,
	["PingTag"] = "group7",
	["InCombat"] = false,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["FwCampTimer"] = 0,
	["IsMe"] = false,
	["TimeStamp"] = 1543725745,
    }
}

local extra = {
    ["Arachnaid"] = {
	["IsLeader"] = false,
	["PingTag"] = "group4",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Clandestine Squirrel"] = {
	["IsLeader"] = false,
	["PingTag"] = "group5",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Lando Calrissian"] = {
	["IsLeader"] = false,
	["PingTag"] = "group6",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Clark Kent"] = {
	["IsLeader"] = false,
	["PingTag"] = "group7",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Lois Lane"] = {
	["IsLeader"] = false,
	["PingTag"] = "group8",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Jimmy Olsen"] = {
	["IsLeader"] = false,
	["PingTag"] = "group9",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Perry White"] = {
	["IsLeader"] = false,
	["PingTag"] = "group10",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Cat Grant"] = {
	["IsLeader"] = false,
	["PingTag"] = "group11",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Lori Lemaris"] = {
	["IsLeader"] = false,
	["PingTag"] = "group12",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Linda Lee Danvers"] = {
	["IsLeader"] = false,
	["PingTag"] = "group13",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Dick Malvern"] = {
	["IsLeader"] = false,
	["PingTag"] = "group14",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Lucy Lane"] = {
	["IsLeader"] = false,
	["PingTag"] = "group15",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Steve Lombard"] = {
	["IsLeader"] = false,
	["PingTag"] = "group16",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Morgan Edge"] = {
	["IsLeader"] = false,
	["PingTag"] = "group17",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Dan Turpin"] = {
	["IsLeader"] = false,
	["PingTag"] = "group18",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    },
    ["Maggie Sawyer"] = {
	["IsLeader"] = false,
	["PingTag"] = "group19",
	["UltMain"] = 27,
	["IsDead"] = false,
	["HasTimedOut"] = false,
	["IsMe"] = true,
	["InCombat"] = false,
	["Ults"] = {
	    [27] = 56,
	},
	["Online"] = true,
	["InRange"] = true,
	["Version"] = "3.22",
	["Visited"] = true,
	["Pos"] = 0,
	["HasBeenLeader"] = true,
	["TimeStamp"] = 1530381942,
	["Because"] = "ultpct < 100",
	["InRangeTime"] = 1530381942,
    }
}

local groupids = {}

function Test.DoesUnitExist(x)
    if x == 'player' or groupids[x] then
	return true
    else
	return _G['DoesUnitExist'](x)
    end
end

function Test.GetUnitClass(x)
    if x == 'player' or groupids[x] then
	return groupids[x].Class
    else
	return _G['GetUnitClass'](x)
    end

end

local classes = {
    Dragonknight = 1,
    Sorcerer = 2,
    Nightblade = 3,
    Warden = 4,
    Templar = 6
}

function Test.GetUnitClassId(x)
    if x == 'player' or groupids[x] then
	return classes[groupids[x].Class]
    else
	return _G['GetUnitClass'](x)
    end
end

function Test.GetUnitDisplayName(x)
    if x == 'player' or groupids[x] then
	return groupids[x].DisplayName
    else
	return _G['GetUnitClass'](x)
    end
end

function Test.GetUnitName(x)
    if x == 'player' or groupids[x] then
	return groupids[x].Name
    else
	return _G.GetUnitName(x)
    end
end

function Test.GetUnitPower(unitid, power_type)
    if unitid == 'player' and power_type == POWERTYPE_ULTIMATE then
	return tonumber(groupids[x].Power) or 97
    else
	return _G.GetUnitPower(unitid, power_type)
    end
end

function Test.GetUnitZone(x)
    if x == 'player' or groupids[x] then
	return groupids[x].Zone or 'Cyrodiil'
    else
	return _G.GetUnitZone(x)
    end
end

function Test.IsUnitDead(x)
    if x == 'player' or groupids[x] then
	return groupids[x].IsDead or false
    else
	return _G.IsUnitDead(x)
    end
end

function Test.IsUnitGrouped(x)
    if x == 'player' or groupids[x] then
	return true
    else
	return _G.IsUnitGrouped(x)
    end
end

function Test.IsUnitGroupLeader(x)
    if x == 'player' or groupids[x] then
	return group[x].IsLeader or false
    else
	return IsUnitGroupLeader(x)
    end
end

function Test.IsUnitInCombat(x)
    if x == 'player' or groupids[x] then
	return group[x].InCombat or false
    else
	return IsUnitInCombat(x)
    end
end

function Test.IsUnitInGroupSupportRange(x)
    if x == 'player' or groupids[x] then
	return group[x].InRange or true
    else
	return IsUnitInRange(x)
    end
end

function Test.IsUnitOnline(x)
    if x == 'player' or groupids[x] then
	return group[x].IsOnline or true
    else
	return IsUnitOnline(x)
    end
end

local function on_update()
    
end

function Test.Initialize(_saved)
    local saved = saved
    Slash('testadd', 'debugging: add <n> characters to group table', function (howmany)
	if tonumber(howmany) == nil then
	    Err("Nope")
	    return
	end
	local maxgid = 0
	local group = saved.GroupMembers
	for n, v in pairs(group) do
	    if v.Test then
		group[n] = nil
		groupids[v.PingTag] = nil
	    else
		if gid > maxgid then
		    maxgid = gid
		end
	    end
	end
	if howmany == 0 then
	    EVENT_MANAGER:UnregisterForUpdate(Test.Name)
	    return
	end
	for n, v in pairs(testgroup) do
	    local newv
	    ZO_DeepTableCopy(v, newv)
	    newv.Name = n
	    newv.DisplayName = newv.DisplayName or '@' .. n
	    maxgid = maxgid + 1
	    newv.PingTag = string.format("group%d", maxgid)
	    newv.Test = true
	    newv.KeepInRange = true
	    groupids[newv.Pingtag] = newv
	end
	EVENT_MANAGER:RegisterForUpdate(Test.Name, 2, on_update)
    end)
end
