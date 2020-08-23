local log
if LibDebugLogger ~= nil then
    log = LibDebugLogger.Create('POC')
    log:SetEnabled(true)
    LibDebugLogger:SetBlockChatOutputEnabled(false)
end
local lcm = LibChatMessage("Piece of Candy", "POC")
local d = d
local df = df
local GetUIGlobalScale = GetUIGlobalScale
local GetUnitDisplayName = GetUnitDisplayName
local GetUnitName = GetUnitName

setfenv(1, POC)

local function iter(tmp)
    return table.remove(tmp, 1)
end

function idpairs(hash, key, tmp)
    for _ in pairs(tmp) do
	table.remove(tmp)
    end
    for _, v in pairs(hash) do
	local i = v[key]
	tmp[i] = v
    end

    return iter, tmp, nil
end

local prefix = {[194] = true, [195] = true, [196] = true, [197] = true}

function namefit(control, name, sizex)
    local toobig = false
    local scale = GetUIGlobalScale()
    while (control:GetStringWidth(name) / scale) > sizex do
	name = name:sub(1, -2)
	toobig = true
    end
    if toobig then
	local n
	name = name:sub(1, -2)
	if prefix[name:sub(-1):byte()] then
	    name = name:sub(1, -2)
	end
	name = name .. '|cffff00·|r'
    end
    return name
end

function Error(x)
    df("POC error: |cff0000%s|r", x)
end

function myunpack(t, n, i)
    if n == nil then
	n = #t
	i = 1
    end
    if i <= n then
	return t[i], myunpack(t, n, i + 1)
    end
end

function Info(...)
    xxx(true, "|cffff00", ...)
end

function Verbose(...)
    if saved.Verbose then
	Info(...)
    end
end

function xxx(chat, ...)
    local accum = ''
    local space = ''
    for i = 1, select('#', ...) do
	local s = select(i, ...)
	if not log or i ~= 1 or not s:find('|') then
	    accum = accum .. space .. tostring(s)
	    if i > 1 then
		space = ' '
	    end
	end
    end
    if chat or not log then
	lcm:Print(accum)
    else
	log:Warn(accum)
    end
end

function HERE(...)
    xxx(false, '|c00ffffXXX ', ...)
end

local watchmen

function mysplit(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local t = {}
    for str in inputstr:gmatch("([^"..sep.."]+)") do
	t[#t + 1] = str
    end
    return unpack(t)
end

local mysplit = mysplit

local function emptyfunc()
end

Watching = false

local initwatch

local function real_watch(what, ...)
    initwatch()
    local inargs = {...}
    if watchmen[what] == nil then
	return
    end
    local doit
    if type(watchmen[what]) ~= 'number' then
	doit = watchmen[what]
    elseif watchmen[what] <= 0 then
	return
    else
	watchmen[what] = watchmen[what] - 1
	doit = true
    end
    if doit then
	xxx(false, "|c00ff11", what .. ': ', ...)
    end
end

local function setwatch(x)
    initwatch()
    if x == "clear" then
	saved.WatchMen = {}
	watchmen = saved.WatchMen
	Info("cleared all watchpoints")
	watch = emptyfunc
	Watching = false
	return
    end
    if x:len() == 0 then
	Info("Watchpoints")
	for n, v in pairs(watchmen) do
	    xxx(true, '', n .. ":", v)
	end
	return
    end
    local what, todo = mysplit(x)
    local n = tonumber(todo)
    if n ~= nil then
	todo = n
    elseif todo == nil then
	todo = true
    elseif todo == "on" or "todo" == "true" then
	todo = true
    elseif todo == "off" or todo == "false" then
	todo = false
    else
	Error("Can't grok" .. todo)
    end
    watchmen[what] = todo
    if next(watchmen) then
	watch = real_watch
	Watching = true
    else
	watch = emptyfunc
	Watching = false
    end
    Info("watch", what, '=', todo)
end

initwatch = function()
    if not saved.WatchMen then
	saved.WatchMen = {}
    end
    if not watchmen then
	watchmen = saved.WatchMen
    end
    initwatch = emptyfunc
    if next(watchmen) then
	watch = real_watch
	Watching = true
    else
	watch = emptyfunc
	Watching = false
    end
end

function player_name(tag)
    if saved.AtNames then
	name = GetUnitDisplayName(tag)
    else
	name = GetUnitName(tag)
    end
    return name
end

watch = real_watch

Slash("watch", 'display debugging info for given "thing"', setwatch)
Slash("here", 'debugging: here', function (x) xxx(x) end)
if LibDebugLogger then
    Slash("/lno", "turn of LibDebugLogger chat output block", function ()
	LibDebugLogger:SetBlockChatOutputEnabled(false)
	d("SetBlockChatOutputEnabled = false")
    end)
end
