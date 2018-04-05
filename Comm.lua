setfenv(1, POC)

local GetUnitPower = GetUnitPower
local GetAbilityCost = GetAbilityCost
local IsUnitGrouped = IsUnitGrouped
local EVENT_MANAGER = EVENT_MANAGER
local Swimlanes

COMM_MAGIC		= 0x0c
COMM_TYPE_PCTULTOLD	= 0x01 + (COMM_MAGIC * 16)
COMM_TYPE_COUNTDOWN	= 0x02 + (COMM_MAGIC * 16)
COMM_TYPE_PCTULT	= 0x03 + (COMM_MAGIC * 16)
COMM_TYPE_NEEDQUEST	= 0x04 + (COMM_MAGIC * 16)
COMM_TYPE_MYVERSION	= 0x05 + (COMM_MAGIC * 16)
COMM_TYPE_PCTULTPOS	= 0x06 + (COMM_MAGIC * 16)

COMM_ALL_PLAYERS	= 0

COMM_MAXQUEUE		= 200

local update_interval

local QUEST_PING = 4

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local lgs_handler
local version
local major, minor

local load_later = false
local campaign
local max_ping
local oldqueue

local me

Comm = {
    active = false,
    Name = "POC-Comm",
}
Comm.__index = Comm

local Comm = Comm
local ultix = GetUnitName("player")
local comm
local notify_when_not_grouped = false

local ultpct_mul2

local myults

function Comm.Send(...)
    comm.Send(...)
end

function Comm.Ready()
    return comm ~= nil
end

function Comm.SendVersion(x)
    if comm == nil then
	return
    end
    if not x then
	x = 0
    else
	x = 1
    end
    comm.Send(COMM_TYPE_MYVERSION, major, minor)
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
    local pct
    local ult = Ult.ByPing(apid)
    if ult.IsMIA then
	apid = max_ping
	pct = 0
    else
	local curpct = me.Ults[apid]
	local current, max = GetUnitPower("player", POWERTYPE_ULTIMATE)
	local cost = math.max(1, GetAbilityCost(ult.Aid))
	pct = math.min(100, math.floor((current / cost) * 100))
	if pct == 100 and curpct and curpct > 100 then
	    pct = curpct
	end
    end
    return (((apid - 1) * 124) + pct)
end

local counter = 0
local function on_update()
    if not comm.active then
	return
    end
    if not IsUnitGrouped("player") then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    Swimlanes.Update("left")
	end
	return
    end
    local notify_when_not_grouped = true
    Swimlanes.Update("map update")

    counter = counter + 1
    local send = 0
    local apid1pct1 = ultpct(myults[1])
    local queue = campaign.Pos
    send = COMM_ULTPCT_MUL1 * apid1pct1
    local cmd
    if queue == 0 or queue == old_queue then
	send = send + ultpct(myults[2])
	cmd = COMM_TYPE_PCTULT
    else
	send = send + queue
	cmd = COMM_TYPE_PCTULTPOS
    end
    watch("on_update", myults[1], myults[2], tostring(send))
    local bytes = Comm.ToBytes(send)
    comm.Send(cmd, bytes[1], bytes[2], bytes[3])
    if (counter % QUEST_PING) == 0 then
	quest_ping = QUEST_PING
	Quest.Ping()
    end
end

function Comm.IsActive()
    return comm ~= nil and comm.active
end

function Comm.Load(verbose)
    local say
    if comm == nil then
	load_later = true
    elseif comm.active then
	say = "already on"
    else
	comm.Load()
	EVENT_MANAGER:RegisterForUpdate('UltPing', update_interval, on_update)
	Comm.SendVersion(false)
	say = "on"
    end
    if verbose then
	Info(say)
    end
end

function Comm.Unload(verbose)
    local say
    if comm == nil then
	load_later = false
    elseif not comm.active then
	say = "already off"
    else
	comm.Unload()
	EVENT_MANAGER:UnregisterForUpdate('UltPing')
	Swimlanes.Update("off")
	say = "off"
    end
    if verbose then
	Info(say)
    end
end

local function commtype(s)
    local toset
    s = s:lower()
    if s:find('pipe') ~= nil then
	toset = PingPipe
    elseif s:find('ping') then
	toset = MapPing
    elseif s == 'lgs' or s == 'libgroupsocket' then
	toset = LGS
    else
	return nil
    end
    saved.Comm = toset.Name
    return toset
end

function Comm.Initialize(inmajor, inminor)
    saved = Settings.SavedVariables
    saved.MapPing = nil
    Swimlanes = POC.Swimlanes
    myults = saved.MyUltId[ultix]
    if saved.Comm == nil then
	saved.Comm = 'PingPipe'
    end
    if saved.OldCount then
	saved.OldCount = nil
    end
    campaign = Campaign

    Comm.Driver = commtype(saved.Comm)
    comm = Comm.Driver
    Comm.Type = comm.Name
    if comm == nil then
	Error(string.format("Unknown communication type: %s", saved.Comm))
    end

    major = inmajor
    minor = inminor
    max_ping = Ult.MaxPing
    COMM_ULTPCT_MUL1 = max_ping * 124
    ultpct_mul2 = COMM_ULTPCT_MUL1 ^ 2

    if saved.UpdateInterval == nil then
	saved.UpdateInterval = 2000
    end
    update_interval = saved.UpdateInterval
    me = Me
    if load_later then
	Comm.Load()
	load_later = false
    end

    Slash("on", "Turn POC on",	function () Comm.Load(true) end)
    Slash("off", "Turn POC off",  function () Comm.Unload(true) end)
    if false then
    Slash("comm", "change communication method (don't use)",function(x)
	if string.len(x) ~= 0 then
	    local toset = commtype(x)
	    if toset ~= comm then
		comm.Unload()
		comm = toset
		comm.Load()
		Swimlanes.Update("Communication method changed")
	    end
	end
	Info(string.format("Communication method: %s", comm.Name:sub(5)))
    end)
    end
    Slash("update", "update every n seconds", function (n)
	n = tonumber(n)
	if n == nil or n < 1 then
	    Error("invalid value")
	else
	    update_interval = n * 1000
	    saved.UpdateInterval = update_interval
	end
    end)
end
