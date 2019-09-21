local x = {
    __index = _G,
    CountdownNumber = POC_CountdownNumber,
    COUNTDOWN_KEY = POC_COUNTDOWN_KEY,
    POC_Main = POC_Main,
    UltNumber = POC_UltNumber,
    UltNumberLabel = POC_UltNumberLabel
}

POC = setmetatable(x, x)
POC.POC = POC

setfenv(1, POC)

local SLASH_COMMANDS = SLASH_COMMANDS

local localized = {
    'DoesUnitExist',
    'GetGroupUnitTagByIndex',
    'GetUnitClass',
    'GetUnitClassId',
    'GetUnitDisplayName',
    'GetUnitName',
    'GetUnitPower',
    'GetUnitStealthState',
    'GetUnitZone',
    'IsUnitDead',
    'IsUnitGrouped',
    'IsUnitGroupLeader',
    'IsUnitInCombat',
    'IsUnitInGroupSupportRange',
    'IsUnitOnline'
}

local real = {}

local execstring = SLASH_COMMANDS['/script']

function Localize(prefix)
    local doit = ''
    for _, n in ipairs(localized) do
	local func = prefix .. n
	if _G[func] then
	    doit = doit .. string.format("POC.%s = %s%s ", n, prefix, n)
	end
    end
    execstring(doit)
end

function Unlocalize()
    local doit = ''
    for _, n in ipairs(localized) do
	doit = doit .. string.format("POC.%s = _G['%s'] ", n, n)
    end
    execstring(doit)
end

local function POCize()
    local doit = ''
    Unlocalize('')
    for _, n in pairs(localized) do
	if _G["POC." .. n] then
	    doit = doit .. string.format("%s = POC.%s ", n, n)
	end
    end
    execstring(doit)
end

Localize('')
POCize = nil

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
		df("%-10s	%s", n, cmds[n].Help)
	    end
	end
    elseif cmds[x] == nil then
	Error(string.format("no such command: %s", x))
    else
	df("%s	%s", x, cmds[x].Help)
    end

end

local LSC = LibSlashCommander
function Slash(names, help, func)
    if type(names) ~= 'table' then
	names = {names}
    end
    for _, name in ipairs(names) do
	if name:sub(1, 1) ~= '/' then
	    name = "/poc" .. name
	end
	local this
	if func == nil then
	    this = cmds[name]
	    cmds[name] = nil
	else
	    this = {
		Debug = help:match('debug'),
		Help = help,
		Func = func
	    }
	    cmds[name] = this
	end
	if not LSC then
	    SLASH_COMMANDS[name] = func
	elseif func then
	    this.LSC = LSC:Register(name, func, "POC: " .. help)
	elseif this.LSC then
	    LSC:Unregister(this.LSC)
	end
    end
    return func
end

Slash("help", 'show POC slash commands', pochelp)

Slash('/poc', 'show POC settings screen', function(x)
    local c, rest = string.match(x, "([^ ]+)%s*(.*)")
    if c == nil or c:len() == 0 then
	LibAddonMenu2:OpenToPanel(POC.Panel)
	return
    end
    if cmds[c] == nil then
	Error(string.format("unknown command: %s", c))
	return
    end
    cmds[c].Func(rest)
end)

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
