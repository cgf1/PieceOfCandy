setfenv(1, POC)
local LGS

POC_LGS = {}
POC_LGS.__index = POC_LGS

local lgs_type = 21 -- aka, the code for 'u'

local lgs_handler

POC_LGS = {
    Name = "POC-LGS",
    active = false,
}
POC_LGS.__index = POC_LGS
local saved

local function rcv(unitid, data, is_self)
    local index, pct, ultver
    pct, index = LGS:ReadUint8(data, 1)
    ultver, index = LGS:ReadUint8(data, index)
    local ultid = ultver % POC_Ult.MaxPing
    local apiver = math.floor(ultver / POC_Ult.MaxPing)

    local player = {
	PingTag = unitid,
	UltPct = pct,
	ApiVer = apiver
    }

    local ult = POC_Ult.ByPing(ultid)
    if apiver == POC_API_VERSION then
	player.UltAid = ult.Aid
	player.InvalidClient = false
    else
	player.UltAid = POC_Ult.MaxPing
	player.InvalidClient = true
    end

    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
end

function brute_force(x)
    SLASH_COMMANDS["/lgs"](tostring(x))
end

function POC_LGS.Send(ultver, pct)
    local data = {}
    local index = 1
    index = LGS:WriteUint8(data, index, pct)
    LGS:WriteUint8(data, index, ultver)
    for i=1, 5 do
	if LGS:Send(lgs_type, data) then
	    return
	end
	brute_force(1)
    end
    POC_Error("LGS:Send failed")
end

function POC_LGS.Load()
    if LGS ~= nil then
	LGS.Load()
    else
	LGS = LibStub("POC_LibGroupSocket")
	local version = 3
	LGS.MESSAGE_TYPE_ULTIMATE = lgs_type
	lgs_handler, _ = LGS:RegisterHandler(lgs_type, version)
	if not lgs_handler then
	    POC_Error("couldn't register with with LibGroupSocket")
	end
	lgs_handler.resources = {}
	lgs_handler.data = {}
	lgs_handler.dataHandler = rcv
	lgs_handler.Load = POC_LGS.Load
	lgs_handler.Unload = POC_LGS.Unload
    end
    LGS:RegisterCallback(lgs_type, lgs_handler.dataHandler)

    SLASH_COMMANDS["/poclgs"] = function()
	lgs_on = not lgs_on
	if lgs_on then
	    brute_force(1)
	else
	    brute_force(0)
	end
    end
    POC_LGS.active = true
end

function POC_LGS.Unload()
    if POC_LGS.active then
	LGS:UnregisterCallback(lgs_type, lgs_handler.dataHandler)
	LGS.Unload()
	POC_LGS.active = false
    end
    SLASH_COMMANDS["/poclgs"] = nil
end
