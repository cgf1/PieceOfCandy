setfenv(1, POC)

local GetUnitPower = GetUnitPower
local GetAbilityCost = GetAbilityCost
local IsUnitGrouped = IsUnitGrouped
local EVENT_MANAGER = EVENT_MANAGER
local Swimlanes = Swimlanes
local SOUNDS = SOUNDS

COMM_MAGIC		= 0x0c
COMM_TYPE_FWCAMPTIMER	= 0x01 + (COMM_MAGIC * 16)
COMM_TYPE_COUNTDOWN	= 0x02 + (COMM_MAGIC * 16)
COMM_TYPE_PCTULT	= 0x03 + (COMM_MAGIC * 16)
COMM_TYPE_NEEDQUEST	= 0x04 + (COMM_MAGIC * 16)
COMM_TYPE_MYVERSION	= 0x05 + (COMM_MAGIC * 16)
COMM_TYPE_PCTULTPOS	= 0x06 + (COMM_MAGIC * 16)
COMM_TYPE_KEEPALIVE	= 0x07 + (COMM_MAGIC * 16)
COMM_TYPE_MAKEMELEADER	= 0x08 + (COMM_MAGIC * 16)
COMM_TYPE_ULTFIRED	= 0x09 + (COMM_MAGIC * 16)
COMM_TYPE_NEEDHELP	= 0x0a + (COMM_MAGIC * 16)

COMM_ALL_PLAYERS	= 0

local update_interval
local update_interveal_per_sec

local QUEST_PING = 2
local KEEPALIVE_PING_SECS = 6
local keepalive_ping

local major, minor, beta

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
    if comm and comm.active then
	comm.Send(...)
    end
end

function Comm.Ready()
    return comm ~= nil
end

local lasttime = 0
local lastpower = 0
local lastult = 0
local function ult_fired()
    watch('ult_fired0', lastult)
    if lastult == 0 then
	return 0
    end
    local thistime = GetTimeStamp()
    thispower = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local delta = thistime - lasttime
    watch('ult_fired', 'lastult', lastult, 'lastpower', lastpower, 'thispower', thispower, 'delta', delta)
    if thispower ~= 0 and thispower >= lastpower or delta <= 10 then
	watch('ult_fired', 'not sending', thispower, lastpower, delta)
	lastult = 0
	return 0
    end
    local n = lastult
    lastult = 0
    lastpower = 0
    lasttime = thistime
    if saved.UltNoise then
	PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)
	PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)
	PlaySound(SOUNDS.NEW_TIMED_NOTIFICATION)
    end
    return n
end

function Comm.UltFired(n, p)
    if comm and comm.active then
	lastult = n
	lastpower = p
	watch('Comm.UltFired', 'lastult', lastult, 'lastpower', lastpower)
    end
end

function Comm.SendVersion()
    Comm.Send(COMM_TYPE_MYVERSION, major, minor, beta)
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
local lastupdate = 0
local function sanity()
    if not saved.CommSanity then
	return
    end
    local now = GetTimeStamp()
    local lu = now - lastupdate
    local lmy = now - PingPipe.lastmytime
    lastupdate = now
    watch("sanity", string.format('last update secs %d, since last ping %d, counter %d', lu, lmy, counter))
    local lx = 3 * update_interval_per_sec
    if (lu > lx) or (lmy < 30) or (counter < 10) then
	return
    end
    if PingPipe.lastmytime == 0 then
	Error("Haven't ever heard from myself")
    else
	Error(string.format("Haven't heard from myself in %d seconds, last command: %02x, last update %d/%d seconds", lmy, PingPipe.lastmycomm, lu, lx))
    end
end

local function setult()
    if Me.UltMain == nil or Me.UltMain == 0 or Me.UltMain == 30 then
	Player.SetUlt()
    end
    if me.UltMain ~= nil and Me.UltMain ~= 0  and me.UltMain ~= 30 then
	local function setult() end
    end
end

local old_queue = 0
local function on_update()
    if not comm.active then
	return
    end
    if not IsUnitGrouped("player") then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    Swimlanes.Update("left")
	    lastult = 0
	    lastpower = 0
	    lasttime = 0
	end
	return
    end
    local notify_when_not_grouped = true
    Swimlanes.Update("map update")
    sanity()
    setult()

    counter = counter + 1
    if (counter % QUEST_PING) == 0 then
	Quest.Ping()
    end

    local apid1pct1 = ultpct(myults[1])
    local queue = campaign.QueuePosition(false)
    local send = COMM_ULTPCT_MUL1 * apid1pct1
    local ultf = ult_fired()
    local cmd
    local fwctimer = (GetNextForwardCampRespawnTime() / 1000) - GetFrameTimeSeconds()
    if IsUnitDead("player") and fwctimer > 0 then
	cmd = COMM_TYPE_FWCAMPTIMER
	send = math.floor(fwctimer)
    elseif ultf ~= 0 then
	cmd = COMM_TYPE_ULTFIRED
	send = ultf
    elseif queue ~= old_queue then
	send = send + queue
	cmd = COMM_TYPE_PCTULTPOS
	old_queue = queue
    else
	send = send + ultpct(myults[2])
	if send ~= last_ult_ping then
	    last_ult_ping = send
	elseif (counter % keepalive_ping) ~= 0 then
	    return
	end
	cmd = COMM_TYPE_PCTULT
    end
    watch("on_update", myults[1], myults[2], tostring(send))
    local bytes = Comm.ToBytes(send)
    Comm.Send(cmd, bytes[1], bytes[2], bytes[3])
end

function Comm.IsActive()
    return (comm ~= nil and comm.active) or load_later
end

function Comm.Load(verbose)
    if saved.CommOff then
	return
    elseif comm == nil then
	load_later = true
    elseif comm.active then
	say = "already on"
    else
	lasttime = 0
	lastpower = 0
	lastult = 0
	comm.Load()
	EVENT_MANAGER:RegisterForUpdate(Comm.Name, update_interval, on_update)
	EVENT_MANAGER:RegisterForEvent(Comm.Name, EVENT_STEALTH_STATE_CHANGED, function(_, unittag, y)
	    if unittag == "player" then
		watch("stealth", "changed", unittag, y)
		on_update()
	    end
	end)
	EVENT_MANAGER:RegisterForEvent(Comm.Name, EVENT_PLAYER_COMBAT_STATE, function(_, x)
	    watch("combat", "changed", x)
	    on_update()
	end)
	update_interval_per_sec = update_interval / 1000
	Comm.SendVersion()
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
	EVENT_MANAGER:UnregisterForUpdate(Comm.Name)
	EVENT_MANAGER:UnregisterForEvent(Comm.Name, EVENT_STEALTH_STATE_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(Comm.Name, EVENT_PLAYER_COMBAT_STATE)
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

function clearernow()
    old_queue = 0
    counter = 0
end

function Comm.Initialize(inmajor, inminor, inbeta, _saved)
    saved = saved
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
    beta = inbeta
    max_ping = Ult.MaxPing
    COMM_ULTPCT_MUL1 = max_ping * 124
    ultpct_mul2 = COMM_ULTPCT_MUL1 ^ 2

    if saved.UpdateInterval == nil then
	saved.UpdateInterval = 2000
    elseif saved.UpdateInterval < 1000 then
	saved.UpdateInterval = 1000
    end
    update_interval = saved.UpdateInterval
    update_interval_per_sec = update_interval / 1000
    keepalive_ping = math.floor((KEEPALIVE_PING_SECS / (update_interval / 1000)) + .5)
    me = Me
    if load_later then
	Comm.Load()
	load_later = false
    end

    Slash("on", "Turn POC on",	function ()
	saved.CommOff = false
	Comm.Load(true)
    end)
    Slash("off", "Turn POC off",  function ()
	Comm.Unload(true)
	saved.CommOff = true
    end)
    Slash("ka", "debugging: show keep alive interval", function () Info(string.format("keep alive is %d", keepalive_ping)) end)
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
	if n:len() ~= 0 then
	    n = tonumber(n)
	    if n == nil or n < 1 then
		Error("invalid value")
	    else
		keepalive_ping = math.floor((KEEPALIVE_PING_SECS / n) + .5)
		update_interval = n * 1000
		saved.UpdateInterval = update_interval
	    end
	end
	Info(string.format("update every %d seconds",  update_interval / 1000))
    end)
    Slash("sanity", "debugging: do behind the scenes sanity-checking", function (x)
	x = x:lower()
	if x == 'on' or x == 'true' then
	    saved.CommSanity = true
	elseif x == 'off' or x == 'false' then
	    saved.CommSanity = false
	end
	Info('Sanity is: ', saved.CommSanity)
    end)

    RegClear(clearernow)
end
