local LGS

POC_Comm = {}
POC_Comm.__index = POC_Comm

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local show_errors = true

POC_Comm = {
    active = false
}
POC_Comm.__index = POC_Comm
local comerr = function() end
local ultix = GetUnitName("player")

local default_data = {
    version = 1,
    enabled = true
}

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
	player.UltGid = ult.Gid
	player.InvalidClient = false
    else
	player.UltGid = POC_Ult.MaxPing
	player.InvalidClient = true
    end

    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
end

function brute_force(x)
    SLASH_COMMANDS["/lgs"](tostring(x))
end

local function send()
    if not IsUnitGrouped("player") then
	return
    end
    local myult = POC_Ult.Me
    local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local cost = math.max(1, GetAbilityCost(myult.Gid))
    local pct = math.floor((current / cost) * 100)

    -- d("UltPct " .. tostring(POC_Swimlanes.UltPct))
    if (pct < 100) then
	-- nothing to do
    elseif (POC_Swimlanes.UltPct ~= nil) then
	pct = POC_Swimlanes.UltPct
    else
	pct = 100
    end
    -- Ultimate type + our API #
    local ultver = myult.Ping + POC_Ult.MaxPing * POC_API_VERSION

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

local function on_update()
    if POC_Comm.active and IsUnitGrouped("player") then
	send()
    end
end

local function Load()

function POC_Comm.Initialize()
    LGS = LibStub("LibGroupSocket")
    local version = 3
    LGS.MESSAGE_TYPE_ULTIMATE = lgs_type
    local handler, _ = LGS:RegisterHandler(lgs_type, version)
    if not handler then
	POC_Error("couldn't register with with LibGroupSocket")
    end
    handler.resources = {}
    handler.data = {}
    handler.dataHandler = rcv

    handler:Load = function()
	LGS.cm:RegisterCallback(lgs_type, self.dataHandler)
	EVENT_MANAGER:RegisterForUpdate('POC_UltPing', 1000, on_update)
    end
    handler:Unload = function()
	d("POC_Comm: Unloading")
	LGS:UnregisterCallback(lgs_type, self.dataHandler)
	EVENT_MANAGER:UnregisterForUpdate('POC_UltPing')
	POC_Comm.active = false
    end
    handler.Load()

    POC_Comm.active = true
    SLASH_COMMANDS["/poccomerr"] = function()
	show_errors = not show_errors
	if show_errors then
	    comerr = POC_Error
	else
	    comerr = function() return end
	end
	d("show_errors " .. tostring(show_errors))
    end
    SLASH_COMMANDS["/poclgs"] = function()
	lgs_on = not lgs_on
	if lgs_on then
	    brute_force(1)
	else
	    brute_force(0)
	end
    end
    SLASH_COMMANDS["/poctoggle"] = function()
	POC_Comm.active = not POC_Comm.active
	if POC_Comm.active then
	    d("POC is on")
	    handler:Load()
	else
	    d("POC is off")
	    handler:Unload()
	end
	CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
    end
end
