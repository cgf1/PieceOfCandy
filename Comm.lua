local Comm

POC_Comm = {}
POC_Comm.__index = POC_Comm

local lgs_type = 21 -- aka, the code for 'u'

local lgs_on = false
local lgs_handler

POC_Comm = {
    Name = "POC_Comm",
    active = false,
}
POC_Comm.__index = POC_Comm
local ultix = GetUnitName("player")
local comm
local notify_when_not_grouped = false

local function on_update()
    if not comm.active then
	return
    end
    if not IsUnitGrouped("player") then
	if notify_when_not_grouped then
	    notify_when_not_grouped = false
	    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_GROUP_CHANGED, "left")
	end
	return
    end
    local notify_when_not_grouped = true

    local myult = POC_Ult.Me
    local current, max, effective_max = GetUnitPower("player", POWERTYPE_ULTIMATE)
    local cost = math.max(1, GetAbilityCost(myult.Aid))
    local pct = math.floor((current / cost) * 100)

    -- d("UltPct " .. tostring(POC_Swimlanes.UltPct))
    if (pct < 100) then
	-- nothing to do
    elseif (POC_Swimlanes.UltPct ~= nil) then
	pct = POC_Swimlanes.UltPct
    else
	pct = 100
    end
    -- Ultimate type + our API #
    local ultver = myult.Ping + POC_Ult.MaxPing * POC_API_VERSION

    comm.Send(ultver, pct)
end

local function toggle(verbose)
    comm.active = not comm.active
    if verbose then
	msg = d
    else
	msg = function() end
    end
    if comm.active then
	msg("POC: on")
	comm.Load()
	EVENT_MANAGER:RegisterForUpdate('POC_UltPing', 1000, on_update)
    else
	msg("POC: off")
	comm.Unload()
	EVENT_MANAGER:UnregisterForUpdate('POC_UltPing')
    end
    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
end

function POC_Comm.IsActive()
    return comm ~= nil and comm.active
end

local function commtype(s)
    local toset
    if s == 'ping' or s == 'mapping' or s == 'POC_MapPing' then
	toset = POC_MapPing
    elseif s == 'lgs' or s == 'libgroupsocket' or s == 'POC_LGS' then
	toset = POC_LGS
    else
	return nil
    end
    saved.Comm = toset.Name
    return toset
end

function POC_Comm.Initialize()
    saved = POC_Settings.SavedVariables
    saved.MapPing = nil
    if saved.Comm == nil then
	saved.Comm = 'POC_MapPing'
    end
    comm = commtype(saved.Comm)
    if comm == nil then
	POC_Error("Unknown communication type: " .. saved.Comm)
    end
    if not comm.active then
	toggle(false)
    end
    SLASH_COMMANDS["/poctoggle"] = function () toggle(true) end
    SLASH_COMMANDS["/poccomm"] = function(x)
	if string.len(x) ~= 0 then
	    local toset = commtype(x)
	    if toset ~= comm then
		comm.Unload()
		comm = toset
		comm.Load()
		CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
	    end
	end
	d("Communication method: " .. comm.Name:sub(4))
    end
end
