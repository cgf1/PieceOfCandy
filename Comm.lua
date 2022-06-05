local GetAbilityCost = GetAbilityCost
local GetFrameTimeSeconds = GetFrameTimeSeconds
local GetGameTimeMilliseconds = GetGameTimeMilliseconds
local GetNextForwardCampRespawnTime = GetNextForwardCampRespawnTime
local GetUnitPower = GetUnitPower
local GetTimeStamp = GetTimeStamp
local HERE = POC.HERE
local IsUnitDead = IsUnitDead
local IsUnitGrouped = IsUnitGrouped
local IsUnitInCombat = IsUnitInCombat
local EVENT_MANAGER = EVENT_MANAGER
local SOUNDS = SOUNDS
local GetUnitName = GetUnitName
local POWERTYPE_ULTIMATE = POWERTYPE_ULTIMATE
local PlaySound = PlaySound
local zo_callLater = zo_callLater

COMM_MAGIC		= 90
COMM_TYPE_FWCAMPTIMER	=  1 + COMM_MAGIC
COMM_TYPE_COUNTDOWN	=  2 + COMM_MAGIC
COMM_TYPE_PCTULT	=  3 + COMM_MAGIC
COMM_TYPE_NEEDQUEST	=  4 + COMM_MAGIC
COMM_TYPE_MYVERSION	=  5 + COMM_MAGIC
COMM_TYPE_PCTULTPOS	=  6 + COMM_MAGIC
COMM_TYPE_MAKEMELEADER	=  7 + COMM_MAGIC
COMM_TYPE_ULTFIRED	=  8 + COMM_MAGIC
COMM_TYPE_NEEDHELP	=  9 + COMM_MAGIC

COMM_MAGIC1		= 80
COMM_TYPE_STAT_DAMAGE	=  0 + COMM_MAGIC1
COMM_TYPE_STAT_HEAL	=  1 + COMM_MAGIC1

COMM_ALL_PLAYERS	= 0

setfenv(1, POC)
local Player, Swimlanes, Stats, Alert, Campaign, Countdown, Error, Info, MapComm, Me, Quest, RegClear, Slash, Ult, Watching, watch
_ = ''

local D = COMM_TYPE_STAT_DAMAGE
local H = COMM_TYPE_STAT_HEAL
local myname = GetUnitName("player")

local packing = {
    [COMM_TYPE_FWCAMPTIMER] = {3},
    [COMM_TYPE_COUNTDOWN] = {3},
    [COMM_TYPE_PCTULT] = {4, 4},
    [COMM_TYPE_NEEDQUEST] = {1, 3},
    [COMM_TYPE_MYVERSION] = {2, 3, 2},
    [COMM_TYPE_PCTULTPOS] = {4, 4},
    [COMM_TYPE_MAKEMELEADER] = {},
    [COMM_TYPE_ULTFIRED] = {6},
    [COMM_TYPE_NEEDHELP] = {},
    [COMM_TYPE_STAT_DAMAGE] = {7, 1},
    [COMM_TYPE_STAT_HEAL] = {7, 1}
}

local update_interval
local update_interval_per_sec

local QUEST_PING = 2
local KEEPALIVE_PING_SECS = 8
local keepalive_ping

local major, minor, beta
local sendversion

local load_later = false
local queuepos
local max_ping
local oldqueue

local me

local saved

Comm = {
    active = false,
    Name = "POC-Comm",
    Packing = packing
}
Comm.__index = Comm

local Comm = Comm
local ultix = GetUnitName("player")
local comm
local notify_when_not_grouped = false
local tobytes

local function emptyfunc() end

local send = emptyfunc

local myults
local thispower

function Comm.Ready()
    return comm ~= nil
end

local lasttime = 0
local lastpower = 0
local lastult = 0
local function ult_fired(thistime)
    watch('ult_fired0', lastult)
    if lastult == 0 then
	return 0
    end
    local thispower = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local delta = thistime - lasttime
    watch('ult_fired', 'lastult', lastult, 'lastpower', lastpower, 'thispower', thispower, 'delta', delta)
    if thispower ~= 0 and thispower >= lastpower or delta <= 10000 then
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
    send(COMM_TYPE_MYVERSION, sendversion)
end

function Comm.ToBytes(n, max)
    local bytes = {}
    for i = 1, max - 1 do
	bytes[i] = n % 256
	n = math.floor(n / 256)
    end
    bytes[max] = n
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
    return (124 * (apid - 1)) + pct
end

local counter = 0
local lastupdate = 0
local pings = 0
local function sanity(now)
    local lu = now - lastupdate
    if lu < 500 then
-- watch('sanity', now, 'vs', lastupdate, lu)
	return false
    end
    lastupdate = now
-- watch('sanity', 'sane', lu)
    if saved.CommSanity then
	local lmy = now - comm.lastmytime
	watch("sanity", string.format('last update secs %d, since last ping %d, counter %d', lu, lmy, counter))
	local lx = 3 * update_interval_per_sec
	if (lu > lx) or (lmy < 30) or (counter < 10) then
	    -- ok
	elseif comm.lastmytime == 0 then
	    Error("Haven't ever heard from myself")
	else
	    Error(string.format("Haven't heard from myself in %d seconds, last command: %02x, last update %d/%d seconds", lmy, comm.lastmycomm, lu, lx))
	end
    end
    return true
end

local last_stat_ping = {
    [D] = {0, 0, 0, 'DAMAGE'},
    [H] = {0, 0, 0, 'HEAL'}
}

local function statwhich(me, now)
    local cmd, what
    local lsdping = last_stat_ping[D]
    local lshping = last_stat_ping[H]
    local me_damage, me_heal = me.Damage, me.Heal
    if me_damage ~= lsdping[1] and me_heal ~= lshping[1] then
	local ddelta = now - lsdping[2]
	local hdelta = now - lshping[2]
	if ddelta > hdelta then
	    cmd = D
	else
	    cmd = H
	end
    elseif me_damage ~= lsdping[1] then
	cmd = D
    else
	cmd = H
    end
    local tbl = last_stat_ping[cmd]
    what = tbl[4]
    local stat
    if cmd == D then
	stat = me_damage
    else
	stat = me_heal
    end
    local val = stat - tbl[1]
    local seq = tbl[3]
    tbl[1] = stat
    tbl[2] = now
    tbl[3] = tbl[3] + 1
    watch('statwhich', cmd, val, seq, what)
    return cmd, val, seq, what
end

local old_queue = 0
local before = 0
local last_ult_ping = {}
local tosend = {}
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
    Stats.Update("periodic update")

    counter = counter + 1
    if (not IsUnitInCombat('player')) and ((counter % QUEST_PING) == 0) then
	Quest.Ping()
    end

    local now = GetGameTimeMilliseconds()
    local queue = queuepos(false)
    local ultf = ult_fired(now)
    local cmd
    local fwctimer = (GetNextForwardCampRespawnTime() / 1000) - GetFrameTimeSeconds()
    local name
    local apid1pct1 = ultpct(myults[1])
    if IsUnitDead("player") and fwctimer > 0 then
	tosend[1] = math.floor(fwctimer)
	cmd = COMM_TYPE_FWCAMPTIMER
	name = 'FWCAMPTIMER'
    elseif ultf ~= 0 then
	tosend[1] = ultf
	cmd = COMM_TYPE_ULTFIRED
	name = 'ULTFIRED'
    elseif queue ~= old_queue then
	tosend[1] = apid1pct1
	tosend[2] = queue
	old_queue = queue
	cmd = COMM_TYPE_PCTULTPOS
	name = 'PCTULTPOS'
    else
	tosend[1] = apid1pct1
	tosend[2] = ultpct(myults[2])
	local same = true
	for i, x in ipairs(tosend) do
	    if last_ult_ping[i] ~= x then
		last_ult_ping[i] = x
		same = false
	    end
	end
	local cmdnext = COMM_TYPE_PCTULT
	local namenext = 'PCTULT'
	if not same then
	    -- fall through
	elseif saved.ShareStats and last_stat_ping[D][1] ~= me.Damage or last_stat_ping[H][1] ~= me.Heal then
	    cmdnext, tosend[1], tosend[2], namenext = statwhich(me, now)
	elseif (counter % keepalive_ping) ~= 0 then
	    return
	end
	cmd = cmdnext
	name = namenext
    end
    if not send or not sanity(now) then
	return	-- Don't ping too quickly
    end
    if Watching then
	local now = GetGameTimeMilliseconds()
	local s = ''
	for _, x in ipairs(tosend) do
	    s = s .. ' ' .. x
	end

	watch("on_update", string.format('%s counter %d, delta %d, sending: %s%s', name, counter, (now - before) / 1000, cmd, s))
	before = now
    end
    send(cmd, tosend)
end

function Comm.IsActive()
    return (comm ~= nil and comm.active) or load_later
end

function Comm.Dispatch(pingtag, cmd, data, unppct)
    local name
    local watchme = ''
    local before = GetGameTimeMilliseconds()
    local timenow = GetTimeStamp()
    if name == myname then
	comm.lastmytime = timenow
	comm.lastmycomm = cmd
    end
    local apid1, pct1, pos, apid2, pct2, heal, damage, dseq, hseq
    local fwctimer = 0
    if cmd == COMM_TYPE_COUNTDOWN then
	Countdown.Start(data[1])
	name = 'COUNTDOWN'
    elseif cmd == COMM_TYPE_NEEDQUEST then
	Quest.Process(pingtag, data[1], data[2])
	name = 'NEEDQUEST'
    elseif cmd == COMM_TYPE_MYVERSION then
	Player.SetVersion(pingtag, data[1], data[2], data[3])
	name = 'MYVERSION'
    elseif cmd == COMM_TYPE_MAKEMELEADER then
	Player.MakeLeader(pingtag)
	name = 'MAKEMELEADER'
    elseif cmd == COMM_TYPE_NEEDHELP then
	Alert.NeedsHelp(pingtag)
	name = 'NEEDSHELP'
    elseif cmd == COMM_TYPE_ULTFIRED then
	Alert.UltFired(pingtag, data[1])
	name = 'ULTFIRED'
    elseif cmd == COMM_TYPE_PCTULT or cmd == COMM_TYPE_PCTULTPOS then
	apid1, pct1, pos, apid2, pct2 =	 unppct(cmd, data)
	if Watching then
	    watchme = string.format(" ult info: apid1 %d, pct1 %d, pos %d, apid2 %d, pct2 %d", apid1, pct1, pos, apid2, pct2)
	end
	if cmd == COMM_TYPE_PCTULT then
	    name = 'PCTULT'
	else
	    name = 'PCULTPOS'
	end
    elseif cmd == COMM_TYPE_FWCAMPTIMER then
	fwctimer = data[1]
	name = 'FWCAMPTIMER'
    elseif cmd == COMM_TYPE_STAT_HEAL then
	heal = data[1]
	name = 'HEAL'
    elseif cmd == COMM_TYPE_STAT_DAMAGE then
	damage = data[1]
	name = 'DAMAGE'
    else
	name = 'UNKNOWN'
    end
    if apid1 or fwctimer or heal or damage then
	Player.New(pingtag, timenow, fwctimer, apid1, pct1, pos, apid2, pct2, damage, heal)
    end
    return before, name, watchme
end

local function setult()
    if not Ult.MaxPing then
       return
    end
    if me.UltMain == nil or me.UltMain == 0 or me.UltMain == Ult.MaxPing then
       Player.SetUlt()
    end
    if me.UltMain ~= nil and me.UltMain ~= 0  and me.UltMain ~= Ult.MaxPing then
       setult = function() end
    end
end

local last_stealth_state
local last_combat_state
function Comm.Load(verbose)
    local say
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
	sendversion = sendversion or {major, minor, beta}
	Comm.Send = comm.Send
	send = comm.Send
	EVENT_MANAGER:RegisterForUpdate(Comm.Name, update_interval, on_update)
	EVENT_MANAGER:RegisterForEvent(Comm.Name, EVENT_STEALTH_STATE_CHANGED, function(_, unittag, stealth_state)
	    if unittag == "player" and stealth_state ~= last_stealth_state then
		watch("stealth", "changed", unittag)
		last_stealth_state = stealth_state
		on_update()
	    end
	end)
	EVENT_MANAGER:RegisterForEvent(Comm.Name, EVENT_PLAYER_COMBAT_STATE, function(_, combat_state)
	    watch("combat", "changed", combat_state)
	    if last_combat_state ~= combat_state then
		last_combat_state = combat_state
		on_update()
	    end
	end)
	update_interval_per_sec = update_interval / 1000
	Comm.SendVersion()
	Stats.ShareThem(saved.ShareStats, true)
	say = "on"
	zo_callLater(setult, update_interval + 500)
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
	Comm.Send = emptyfunc
	send = emptyfunc
	EVENT_MANAGER:UnregisterForUpdate(Comm.Name)
	EVENT_MANAGER:UnregisterForEvent(Comm.Name, EVENT_STEALTH_STATE_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(Comm.Name, EVENT_PLAYER_COMBAT_STATE)
	Swimlanes.Update("off")
	Stats.ShareThem(false, true)
	say = "off"
    end
    if verbose then
	Info(say)
    end
end

local function commtype(s)
    local toset
    s = s:lower()
    if s:find('pipe') or s:find('mapcomm') then
	toset = MapComm
    elseif s == 'lgs' or s == 'libgroupsocket' then
	toset = MapComm
    else
	toset = MapComm
    end
    saved.Comm = toset.Name
    return toset
end

function clearernow()
    old_queue = 0
    counter = 0
end

function Comm.Initialize(inmajor, inminor, inbeta, _saved)
    saved = _saved
    saved.MapPing = nil
    Player = POC.Player
    Stats = POC.Stats
    Alert = POC.Alert
    Campaign = POC.Campaign
    Countdown = POC.Countdown
    Error = POC.Error
    Info = POC.Info
    MapComm = POC.MapComm
    Me = POC.Me
    Quest = POC.Quest
    RegClear = POC.RegClear
    Slash = POC.Slash
    Swimlanes = POC.Swimlanes
    Ult = POC.Ult
    Watching = POC.Watching
    watch = POC.watch

    myults = saved.MyUltId[ultix]
    if saved.Comm == nil or saved.Comm == 'PingPipe' then
	saved.Comm = 'MapComm'
    end
    if saved.OldCount then
	saved.OldCount = nil
    end
    queuepos = Campaign.QueuePosition

    Comm.Driver = commtype(saved.Comm)
    comm = Comm.Driver
    Comm.Type = comm.Name
    if comm == nil then
	Error(string.format("Unknown communication type: %s", saved.Comm))
    end

    tobytes = Comm.ToBytes

    major = inmajor
    minor = inminor
    beta = inbeta
    max_ping = Ult.MaxPing

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
	Info(string.format("update every %d seconds, keepalive every %d",  update_interval / 1000, keepalive_ping))
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
