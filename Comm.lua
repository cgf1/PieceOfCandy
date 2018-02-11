local LGS

POC_Comm = {}
POC_Comm.__index = POC_Comm

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local lgs_handler

POC_Comm = {
    Name = "POC_Comm",
    active = false,
}
POC_Comm.__index = POC_Comm
local ultix = GetUnitName("player")
local comm = {}

local sender

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

function POC_Comm.IsActive()
    return comm.active
end

function POC_Comm.Send()
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
    if comm.active and IsUnitGrouped("player") then
	comm.Send()
    end
end

function POC_Comm.Load()
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
	lgs_handler.Load = POC_Comm.Load
	lgs_handler.Unload = POC_Comm.Unload
    end
    LGS:RegisterCallback(lgs_type, lgs_handler.dataHandler)
    POC_Comm.active = true
end

function POC_Comm.Unload()
    if POC_Comm.active then
	POC_Comm.active = false
	LGS:UnregisterCallback(lgs_type, lgs_handler.dataHandler)
	LGS.Unload()
    end
end

local function toggle(verbose)
    comm.active = not comm.active
    if verbose then
	msg = d
    else
	msg = function() end
    end
    if comm.active then
	msg("POC: on")
	comm.Load()
	EVENT_MANAGER:RegisterForUpdate('POC_UltPing', 1000, on_update)
    else
	msg("POC: off")
	comm.Unload()
	EVENT_MANAGER:UnregisterForUpdate('POC_UltPing')
    end
    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
end

function POC_Comm.Initialize()
    saved = POC_Settings.SavedVariables
    if not saved.MapPing then
	comm = POC_Comm
    else
	comm = POC_MapPing
    end
    if not comm.active then
	toggle(false)
    end

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
    SLASH_COMMANDS["/poctoggle"] = function () toggle(true) end
    SLASH_COMMANDS["/pocping"] = function(x)
	if string.len(x) ~= 0 then
	    local istrue = x == '1' or x == 'true' or x == 'yes'
	    if istrue == saved.MapPing then
		return
	    end
	    saved.MapPing = istrue
	    if istrue then
		POC_Comm.Unload()
		POC_MapPing.Load()
		comm = POC_MapPing
	    else
		POC_MapPing.Unload()
		POC_Comm.Load()
		comm = POC_Comm
	    end
	    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
	end
	if saved.MapPing then
	    d("POC: Using MapPing")
	else
	    d("POC: Using LibGroupSocket")
	end
    end
end
