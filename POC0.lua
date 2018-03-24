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
    if x:len() == 0 then
	for _, n in ipairs(keys) do
	    df("%-8s %s", n, cmds[n].Help)
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

function Slash(name, help, func)
    cmds[name] = {
	Help = help,
	Func = func
    }
    SLASH_COMMANDS["/poc" .. name] = func
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
