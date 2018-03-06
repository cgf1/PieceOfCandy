setfenv(1, POC)
function IdSort(hash, key, debug)
    local function compare(a, b)
	print(tostring(a))
	local na = tonumber(a[key])
	local nb = tonumber(b[key])
	if na == nil and nb == nil then
	    return a < b
	end
	if na == nil then
	    return false
	end
	if nb == nil then
	    return true
	end
	return  a[key] < b[key]
    end
    local ret = {}
    for _,v in pairs(hash) do
	table.insert(ret, v)
    end

    table.sort(ret, compare)
    return ret
end

function Error(x)
    d("POC error: |cff0000" .. x .. "|c")
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

local watchmen = {}

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

local function setwatch(x)
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
    xxx("set", what, "to", todo)
end

function watch(what, ...)
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
	args[1] = "|cee22ee"
	for _, x in ipairs(inargs) do
	    args[#args + 1] = x
	end
	args[#args + 1] = "|c"
	xxx(unpack(args))
    end
end

SLASH_COMMANDS["/pocwatch"] = setwatch
