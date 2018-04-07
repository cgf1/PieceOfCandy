setfenv(1, POC)

LuaErrors = {
    Name = 'POC-LuaErrors'
}
LuaErrors.__index = LuaErrors

local uhoh = true
local seen_errors = {}
local errors = {}
local function error_handler(_, str)
    if not str:find("/POC/") then
	return
    end
    ZO_ERROR_FRAME:HideCurrentError()
    if uhoh then
	Error("Uh oh.  lua errors detected.  /pocerrors will show them")
	uhoh = false
    end
    local firstline, rest = str:match('([^\n]+)(.*)')
    if seen_errors[firstline] ~= nil then
	seen_errors[firstline] = seen_errors[firstline] + 1
    else
	errors[#errors + 1] = {firstline, rest}
	seen_errors[firstline] = 1
    end
end

local function plural(n)
    if n > 1 then
	return 's'
    else
	return ''
    end
end

function show_errors(n)
    if n == 'clear' then
	seen_errors = {}
	errors = {}
	Info("errors cleared")
        return
    end
    local yup = false
    for i, n in ipairs(errors) do
	if not yup then
	    Info("lua errors (sigh):")
	end
	local count = seen_errors[n[1]]
	df("|c42ebf4Saw %d time%s:|c\r\n%s%s", count, plural(count), n[1], n[2])
	yup = true
    end
    if not yup then
	Info("No lua errors found.  Phew!")
    end
end

local function clearernow(force)
    if force then
	seen_errors = {}
	errors = {}
    end
end

function LuaErrors.Initialize()
    EVENT_MANAGER:RegisterForEvent("POC-Errors", EVENT_LUA_ERROR, error_handler)
    Slash("errors", "show any POC lua errors", show_errors)
    SLASH_COMMANDS["/pocerr"] = show_errors
    SLASH_COMMANDS["/pocerror"] = show_errors
    SLASH_COMMANDS["/anerror"] = function()
	local a = {}
	a[nil] = 1
    end
    RegClear(clearernow)
end
