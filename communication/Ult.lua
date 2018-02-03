-- The Ultimate Protocol
-- *bitArray* flags, *uint8* ultimate[, *uint8* ultCost, *uint8* ultimageGroupId]
-- flags:
--   1: isFullUpdate - the user is sending cost in addition to percentages in this packet
--   2: requestsFullUpdate - the user does not have all the necessary data and wants to have a full update from everyone (e.g. after reloading the ui)

local LGS = LibStub("LibGroupSocket")
LGS.MESSAGE_TYPE_ULTIMATE = 21 -- aka, the code for 'u'
local type, version = LGS.MESSAGE_TYPE_ULTIMATE, 3
local handler, saveData = LGS:RegisterHandler(type, version)
if(not handler) then return end
local SKIP_CREATE = true
local ON_ULTIMATE_CHANGED = "OnUltChanged"
local MIN_SEND_TIMEOUT = 2
local MIN_COMBAT_SEND_TIMEOUT = 1
local Log = LGS.Log

handler.resources = {}
local resources = handler.resources
local send_full_update = true
local needFullUpdate = true
local ultCost = 0
local id = 0
local lastSendTime = 0
local defaultData = {
    version = 1,
    enabled = true,
}
handler.callbacks = handler.callbacks or 0

local function GetCachedUnitResources(unitTag, skipCreate)
    local unitName = GetUnitName(unitTag)
    local unitResources = resources[unitName]
    if not unitResources and not skipCreate then
	resources[unitName] = {
	    [POWERTYPE_ULTIMATE] = {cur=0, cost=0, gid=0},
	    lastUpdate = 0,
	}
	unitResources = resources[unitName]
    end
    return unitResources
end

function handler:GetLastUpdateTime(unitTag)
    local unitResources = GetCachedUnitResources(unitTag, SKIP_CREATE)
    if unitResources then
	return unitResources.lastUpdate
    end
    return -1
end

function handler:SetUltCost(cost)
    ultCost = cost
end

function handler:Setid(gid)
    id = gid
end

local function OnData(unitTag, data, isSelf)
    if (handler.callbacks == 0) then return end --dont do anything if nobody is using this handler

    local index, bitIndex = 1, 1
    local isFullUpdate, index, bitIndex = LGS:ReadBit(data, index, bitIndex)
    local requestsFullUpdate, index, bitIndex = LGS:ReadBit(data, index, bitIndex)

    --	Log("OnData %s (%d byte): is full: %s, needs full: %s", GetUnitName(unitTag), #data, tostring(isFullUpdate), tostring(requestsFullUpdate))
    index = index + 1
    if not isSelf and requestsFullUpdate then
	send_full_update = true
    end

    --local expectedLength = isFullUpdate and 3 or 2
    --if(#data < expectedLength) then Log("UltHandler received only %d of %d byte", #data, expectedLength) return end

    local unitResources = GetCachedUnitResources(unitTag)
    local ult = unitResources[POWERTYPE_ULTIMATE]
    ult.cur, index = LGS:ReadUint8(data, index)
    if isFullUpdate then
	ult.cost, index = LGS:ReadUint8(data, index)
	ult.gid, index = LGS:ReadUint8(data, index)
    end

    unitResources.lastUpdate = GetTimeStamp()

    --	Log("ult: %d, cost: %d", ult.cur, ult.cost)
    LGS.cm:FireCallbacks(ON_ULTIMATE_CHANGED, unitTag, ult.cur, ult.cost, ult.gid, isSelf)
end

local function NumCallbacks()
    local registry = LGS.cm.callbackRegistry[ON_ULTIMATE_CHANGED]
    handler.callbacks = registry and #registry or 0
end

function handler:RegisterForUltChanges(callback)
    LGS.cm:RegisterCallback(ON_ULTIMATE_CHANGED, callback)
    NumCallbacks()
end

function handler:UnregisterForUltChanges(callback)
    LGS.cm:UnregisterCallback(ON_ULTIMATE_CHANGED, callback)
    NumCallbacks()
end

local function GetPowerValues(unitResources, powerType)
    local data = unitResources[powerType]
    local cur, maximum = GetUnitPower("player", powerType)
    return data, cur, data.cost
end

function handler:Send()
    if not saveData.enabled or not IsUnitGrouped("player") or handler.callbacks == 0 then
	return
    end
    local now = GetTimeStamp()
    local timeout = IsUnitInCombat("player") and MIN_COMBAT_SEND_TIMEOUT or MIN_SEND_TIMEOUT
    if now - lastSendTime < timeout then
	return
    end

    local unitResources = GetCachedUnitResources("player")
    local ult, ultcur, ultmax = GetPowerValues(unitResources, POWERTYPE_ULTIMATE)
POC.xxx('handler:Send', ult, ultcur, ultmax)
    ultcur = zo_min(ultcur, ultmax)

    send_full_update = send_full_update or ult.cost ~= ultCost or ult.gid ~= id
    if ult.cur ~= ultcur or send_full_update then
	local data = {}
	local index, bitIndex = 1, 1
	index, bitIndex = LGS:WriteBit(data, index, bitIndex, send_full_update)
	index, bitIndex = LGS:WriteBit(data, index, bitIndex, needFullUpdate)
	index = index + 1
	index = LGS:WriteUint8(data, index, ultcur)
	if send_full_update then
	    index = LGS:WriteUint8(data, index, ultCost)
	    index = LGS:WriteUint8(data, index, id)
	end

	--	Log("Send %d byte: is full: %s, needs full: %s, ult: %s, cost: %s", #data, tostring(send_full_update), tostring(needFullUpdate), tostring(ultcur), tostring(ultCost))
	if LGS:Send(type, data) then
	    --	Log("Send Complete")
	    lastSendTime = now
	    ult.cur = ultcur
	    if send_full_update then
		ult.cost = ultCost
		ult.gid = id
	    end
	    send_full_update = false
	    needFullUpdate = false
	end
    end
end

function handler:Refresh()
    send_full_update = true
    needFullUpdate = true
end

local function OnUpdate()
    handler:Send()
end

local isActive = false

local function StartSending()
    if not isActive and saveData.enabled and IsUnitGrouped("player") then
	EVENT_MANAGER:RegisterForUpdate("LibGroupSocketUltHandler", 1000, OnUpdate)
	isActive = true
    end
end

local function StopSending()
    if(isActive) then
	EVENT_MANAGER:UnregisterForUpdate("LibGroupSocketUltHandler")
	isActive = false
    end
end

local function OnUnitCreated(_, unitTag)
    send_full_update = true
    StartSending()
end

local function OnUnitDestroyed(_, unitTag)
    resources[GetUnitName(unitTag)] = nil
    if(isActive and not IsUnitGrouped("player")) then
	StopSending()
    end
end

function handler:InitializeSettings(optionsData, IsSendingDisabled) -- TODO: localization
    optionsData[#optionsData + 1] = {
	type = "header",
	name = "Ult Handler",
    }
    optionsData[#optionsData + 1] = {
	type = "checkbox",
	name = "Enable sending",
	tooltip = "Controls if the handler does send data. It will still receive and process incoming data.",
	getFunc = function() return saveData.enabled end,
	setFunc = function(value)
	    saveData.enabled = value
	    if value then
		StartSending()
	    else
		StopSending()
	    end
	end,
	disabled = IsSendingDisabled,
	default = defaultData.enabled
    }
end

-- savedata becomes available twice in case the standalone lib is loaded
local function InitializeSaveData(data)
    saveData = data

    if not saveData.version then
	ZO_DeepTableCopy(defaultData, saveData)
    end

    --  if(saveData.version == 1) then
    --      -- update it
    --  end
end

local function Unload()
    LGS.cm:UnregisterCallback(type, handler.dataHandler)
    LGS.cm:UnregisterCallback("savedata-ready", InitializeSaveData)
    EVENT_MANAGER:UnregisterForEvent("LibGroupSocketUltHandler", EVENT_UNIT_CREATED)
    EVENT_MANAGER:UnregisterForEvent("LibGroupSocketUltHandler", EVENT_UNIT_DESTROYED)
    StopSending()
end

local function Load()
    InitializeSaveData(saveData)
    LGS.cm:RegisterCallback("savedata-ready", function(data)
	InitializeSaveData(data.handlers[type])
    end)

    handler.dataHandler = OnData
    LGS.cm:RegisterCallback(type, OnData)
    EVENT_MANAGER:RegisterForEvent("LibGroupSocketUltHandler", EVENT_UNIT_CREATED, OnUnitCreated)
    EVENT_MANAGER:AddFilterForEvent("LibGroupSocketUltHandler",EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
    EVENT_MANAGER:RegisterForEvent("LibGroupSocketUltHandler", EVENT_UNIT_DESTROYED, OnUnitDestroyed)
    EVENT_MANAGER:AddFilterForEvent("LibGroupSocketUltHandler",EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, "group")
    handler.Unload = Unload

    StartSending()
end

if(handler.Unload) then handler.Unload() end
Load()
