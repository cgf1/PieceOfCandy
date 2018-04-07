local x = {
    __index = _G,
    CompactSwimlaneControl = POC_CompactSwimlaneControl,
    CountdownNumber = POC_CountdownNumber,
    COUNTDOWN_KEY = POC_COUNTDOWN_KEY,
    SwimlaneControl = POC_SwimlaneControl,
    UltNumber = POC_UltNumber,
    UltNumberLabel = POC_UltNumberLabel
}

POC = setmetatable(x, x)
POC.POC = POC

setfenv(1, POC)

local cmds = {}
local keys = {}

local function pochelp(x)
    if #keys == 0 then
	for n, _ in pairs(cmds) do
	    keys[#keys+1] = n
	end
	table.sort(keys)
    end
    local showdebug
    if x ~= 'debug' then
	showdebug = false
    else
	showdebug = true
	x = ''
    end
    if x:len() == 0 then
	for _, n in ipairs(keys) do
	    if not cmds[n].Debug or showdebug then
		d("|u0:10::" .. n .. "|u " .. cmds[n].Help)
	    end
	end
    elseif cmds[x] == nil then
	Error(string.format("no such command: %s", x))
    else
	df("%s  %s", x, cmds[x].Help)
    end

end

cmds.help = {
    Help = 'show POC slash commands',
    Func = pochelp
}
SLASH_COMMANDS["/pochelp"] = pochelp

function Slash(name, help, func)
    if func == nil then
	cmds[name] = nil
    else
	cmds[name] = {
	    Debug = help:match('debug'),
	    Help = help,
	    Func = func
	}
    end
    if name:sub(1, 1) ~= '/' then
	name = "/poc" .. name
    end
    SLASH_COMMANDS[name] = func
end

local lam = LibStub("LibAddonMenu-2.0")
SLASH_COMMANDS["/poc"] = function(x)
    local c, rest = string.match(x, "([^ ]+)%s*(.*)")
    if c == nil or c:len() == 0 then
	lam:OpenToPanel(POC.Panel)
	return
    end
    if cmds[c] == nil then
	Error(string.format("unknown command: %s", c))
	return
    end
    cmds[c].Func(rest)
end

Slash("/leave", "leave group", function () GroupLeave() end)

local clearfuncs = {}
function RegClear(func)
    clearfuncs[#clearfuncs + 1] = func
end

function RunClear(force)
    for _, func in ipairs(clearfuncs) do
	func(force)
    end
end
