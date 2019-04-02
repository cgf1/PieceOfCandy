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

function Error(x)
    d(string.format("POC error: |cff0000%s|r", x))
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
    xxx("|cffff00", "POC:", ...)
end

function xxx(...)
    local accum = ''
    local space = ''
    for i = 1, select('#', ...) do
	accum = accum .. space .. tostring(select(i, ...))
	if i > 1 then
	    space = ' '
	end
    end
    d(accum)
end

function HERE(...)
    xxx("|c00ffff", "HERE", ...)
end

local watchmen

local function mysplit(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	t[i] = str
	i = i + 1
    end
    return unpack(t)
end

local function empty_func()
end

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
	xxx("|c00ff11", what .. ': ', ...)
    end
end

local function setwatch(x)
    initwatch()
    if x == "clear" then
	saved.WatchMen = {}
	watchmen = saved.WatchMen
	Info("cleared all watchpoints")
	watch = empty_func
	return
    end
    if x:len() == 0 then
	Info("Watchpoints")
	for n, v in pairs(watchmen) do
	    xxx('', n .. ":", v)
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
    else
	watch = empty_func
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
    initwatch = empty_func
    if next(watchmen) then
	watch = real_watch
    else
	watch = empty_func
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
