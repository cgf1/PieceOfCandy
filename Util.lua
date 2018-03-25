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
    d(string.format("POC error: |cff0000%s|c", x))
end

function Info(...)
    local args = {...}
    args[1] = "|cffff00POC: " .. args[1]
    xxx(unpack(args))
end

function xxx(...)
    local args = {...}
    local accum = ''
    local space = ''
    for i = 1, #args do
	accum = accum .. space .. tostring(args[i])
	space = ' '
    end
    d(accum)
end

function HERE(...)
    local newargs = {"|c00ffff HERE"}
    local args = {...}
    for _, x in ipairs(args) do
	newargs[#newargs + 1] = x
    end
    xxx(unpack(newargs))
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

local function initwatch()
    if not saved.WatchMen then
	saved.WatchMen = {}
    end
    if not watchmen then
	watchmen = saved.WatchMen
    end
    initwatch = function() end
end

local function setwatch(x)
    initwatch()
    if x == "clear" then
	saved.WatchMen = {}
	watchmen = saved.WatchMen
	Info("cleared all watchpoints")
	return
    end
    if x:len() == 0 then
	Info("Watchpoints")
	for n, v in pairs(watchmen) do
	    xxx(n .. ":", v)
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
    Info("watch", what, '=', todo)
end

function watch(what, ...)
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
	local args = {}
	args[1] = "|cee22ee" .. what .. ':'
	for _, x in ipairs(inargs) do
	    args[#args + 1] = x
	end
	args[#args + 1] = "|c"
	xxx(unpack(args))
    end
end

Slash("watch", 'display debugging info for given "thing"', setwatch)
