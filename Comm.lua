setfenv(1, POC)
COMM_MAGIC              = 0x0c
COMM_TYPE_PCTULTOLD     = 0x01 + (COMM_MAGIC * 16)
COMM_TYPE_COUNTDOWN     = 0x02 + (COMM_MAGIC * 16)
COMM_TYPE_PCTULT        = 0x03 + (COMM_MAGIC * 16)
COMM_TYPE_NEEDQUEST     = 0x04 + (COMM_MAGIC * 16)
COMM_TYPE_MAX           = 0x03
COMM_ALL_PLAYERS        = 0

local DEFAULT_OLDCOUNT = 5
local QUEST_PING = 4

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local lgs_handler

Comm = {
    active = false,
    Name = "POC-Comm",
}
Comm.__index = Comm
local ultix = GetUnitName("player")
local comm
local notify_when_not_grouped = false

local myults
local quest_ping = QUEST_PING

function Comm.Send(...)
    comm.Send(...)
end

function Comm.ToBytes(n)
    local bytes = {}
    for i = 1, 4 do
	bytes[i] = n % 256
	n = math.floor(n / 256)
    end
    return bytes
end

local function ultpct(apid)
    local pct = 0
    if apid ~= nil and apid ~= 0 then
	local curpct = Me.Ults[apid]
	local ult = Ult.ByPing(apid)
	if ult == nil then
	    apid = Ult.MaxPing
	else
	    local current, max = GetUnitPower("player", POWERTYPE_ULTIMATE)
	    local cost = math.max(1, GetAbilityCost(ult.Aid))
	    pct = math.min(100, math.floor((current / cost) * 100))
	    if pct == 100 and curpct and curpct > 100 then
		pct = curpct
	    end
	end
    end
    return apid, pct
end

local counter = 0
local function on_update()
    if not comm.active then
	return
    end
    if not IsUnitGrouped("player") then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    Swimlanes.Update("left group")
	end
	return
    end
    local notify_when_not_grouped = true
    Swimlanes.Update("map update")

    counter = counter + 1
    if counter == saved.OldCount then
	local ult, pct = ultpct(myults[1])
	comm.Send(COMM_TYPE_PCTULTOLD, ult,  pct)
	counter = 0
    else
	local send = 0
	for i, apid in ipairs(myults) do
	    local apid, p = ultpct(apid)
	    send = (send * 30) + (apid - 1)
	    send = (send * 124) + p
	end
	local bytes = Comm.ToBytes(send)
-- d("Sending " .. tostring(send))
	comm.Send(COMM_TYPE_PCTULT, bytes[1], bytes[2], bytes[3])
    end
    quest_ping = quest_ping - 1
    if quest_ping <= 0 then
	quest_ping = QUEST_PING
	Quest.Ping()
    end
end

local function toggle(verbose)
    local activate = not comm.active
    if verbose then
	msg = d
    else
	msg = function() end
    end
    if activate then
	msg("POC: on")
	comm.Load()
	EVENT_MANAGER:RegisterForUpdate('UltPing', 1000, on_update)
    else
	msg("POC: off")
	comm.Unload()
	EVENT_MANAGER:UnregisterForUpdate('UltPing')
    end
    Swimlanes.Sched()
end

function Comm.IsActive()
    return comm ~= nil and comm.active
end

local function commtype(s)
    local toset
    if s == 'ping' or s == 'mapping' or s == 'MapPing' then
	toset = MapPing
    elseif s == 'lgs' or s == 'libgroupsocket' or s == 'LGS' then
	toset = LGS
    elseif s == 'pipe' or s == 'pingpipe' or s == 'PingPipe' or s == 'POC-PingPipe' then
	toset = PingPipe
    else
	return nil
    end
    saved.Comm = toset.Name
    return toset
end

function Comm.Initialize()
    saved = Settings.SavedVariables
    saved.MapPing = nil
    myults = saved.MyUltId[ultix]
    if saved.Comm == nil then
	saved.Comm = 'PingPipe'
    end
    if not saved.OldCount then
	saved.OldCount = DEFAULT_OLDCOUNT
    end

    Comm.Driver = commtype(saved.Comm)
    comm = Comm.Driver
    Comm.Type = comm.Name
    if comm == nil then
	Error("Unknown communication type: " .. saved.Comm)
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
		Swimlanes.Update("Communication method changed")
	    end
	end
	d("Communication method: " .. comm.Name:sub(5))
    end
    SLASH_COMMANDS["/pocoldcount"] = function (n)
	local was = saved.OldCount
	saved.OldCount = tonumber(n)
	xxx("Changed interval from", was, "to", saved.OldCount)
    end
end
