local Comm

POC_Comm = {}
POC_Comm.__index = POC_Comm

POC_COMM_MAGIC          = 0x0c
POC_COMM_TYPE_PCTULTOLD = 0x01 + (POC_COMM_MAGIC * 16)
POC_COMM_TYPE_COUNTDOWN = 0x02 + (POC_COMM_MAGIC * 16)
POC_COMM_TYPE_PCTULT    = 0x03 + (POC_COMM_MAGIC * 16)
POC_COMM_TYPE_MAX       = 0x03

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local lgs_handler

POC_Comm = {
    active = false,
    Name = "POC_Comm",
    SawPCTULTOLD = true
}
POC_Comm.__index = POC_Comm
local ultix = GetUnitName("player")
local comm
local notify_when_not_grouped = false

local myults

local xxx

function POC_Comm.Send(...)
    comm.Send(...)
end

function POC_Comm.ToBytes(n)
    local bytes = {}
    for i = 1, 4 do
	bytes[i] = n % 256
	n = math.floor(n / 256)
    end
    return bytes
end

local function ultpct(apid, i)
    local pct
    if apid ~= nil and apid ~= 0 then
	local curpct = POC_Me.Ults[apid]
	local ult = POC_Ult.ByPing(apid)
	local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
	local cost = math.max(1, GetAbilityCost(ult.Aid))
	pct = math.min(100, math.floor((current / cost) * 100))
	if i == 1 and pct >= 100 and curpct and curpct >= 100 then
	    pct = curpct
	end
    end
    return pct
end

local OLDCOUNT = 5
local counter = 0
local function on_update()
    if not comm.active then
	return
    end
    if not IsUnitGrouped("player") then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_GROUP_CHANGED, "left")
	end
	return
    end
    local notify_when_not_grouped = true

    local mainult = myults[1]
    local pct = ultpct(myults[1])

    counter = counter + 1
    if counter == OLDCOUNT and POC_Comm.SawPCTULTOLD then
	comm.Send(POC_COMM_TYPE_PCTULTOLD, mainult,  pct)
	counter = 0
    else
	local send = 0
	for i, aid in ipairs(myults) do
	    local p = ultpct(aid, i)
	    send = (send * 30) + (aid - 1)
	    send = (send * 124) + p
	end
	local bytes = POC_Comm.ToBytes(send)
-- d("Sending " .. tostring(send))
	comm.Send(POC_COMM_TYPE_PCTULT, bytes[1], bytes[2], bytes[3])
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

function POC_Comm.IsActive()
    return comm ~= nil and comm.active
end

local function commtype(s)
    local toset
    if s == 'ping' or s == 'mapping' or s == 'POC_MapPing' then
	toset = POC_MapPing
    elseif s == 'lgs' or s == 'libgroupsocket' or s == 'POC_LGS' then
	toset = POC_LGS
    elseif s == 'pipe' or s == 'pingpipe' or s == 'POC_PingPipe' then
	toset = POC_PingPipe
    else
	return nil
    end
    saved.Comm = toset.Name
    return toset
end

function POC_Comm.Initialize()
    xxx = POC.xxx
    saved = POC_Settings.SavedVariables
    saved.MapPing = nil
    myults = saved.MyUltId[ultix]
    if saved.Comm == nil then
	-- saved.Comm = 'POC_MapPing'
	saved.Comm = 'POC_PingPipe'
    end
    comm = commtype(saved.Comm)
    if comm == nil then
	POC_Error("Unknown communication type: " .. saved.Comm)
    end
    if not comm.active then
	toggle(false)
    end
    SLASH_COMMANDS["/poctoggle"] = function () toggle(true) end
    SLASH_COMMANDS["/poccomm"] = function(x)
	if string.len(x) ~= 0 then
	    local toset = commtype(x)
	    if toset ~= comm then
		comm.Unload()
		comm = toset
		comm.Load()
		CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
	    end
	end
	d("Communication method: " .. comm.Name:sub(5))
    end
end
