local LMP = LibStub("LibMapPing")
local LGPS = LibStub("LibGPS2", true)
POC_PingPipe = {
    Name = "POC_PingPipe",
    active = false
}
POC_PingPipe.__index = POC_PingPipe

local data = {}
local xxx

local WROTHGAR = 27

local function on_map_ping(event, etype, pingtype, tag, offx, offy, _)
    LMP:UnmutePing(MAP_PIN_TYPE_PING, GetUnitName("player"))
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(WROTHGAR)
    offx, offy = LMP:GetMapPing(pingtype, tag)
    LGPS:PopCurrentMap()
    if offx == 0 and offy == 0 then
	return
    end
    local ultver = math.floor((offx + .00005) * 10000)
    local pct = math.floor((offy + .00005) * 10000)
    if ultver >= POC_Ult.MaxPing or ultver < 0 then
	return
    end
    local ult = POC_Ult.ByPing(ultver)
    if ult == nil then return end
    local player = {
	PingTag = tag,
	UltPct = pct,
	InvalidClient = false,
	UltAid = ult.Aid
    }
    CALLBACK_MANAGER:FireCallbacks(POC_PLAYER_DATA_CHANGED, player)
end

function POC_PingPipe.Send(ultver, pct)
    local ultping = ultver / 10000
    local pctping = pct / 10000
    LMP:MutePing(MAP_PIN_TYPE_PING, GetUnitName("player"))
    
    LGPS:PushCurrentMap()
    SetMapToMapListIndex(WROTHGAR)
    PingMap(MAP_PIN_TYPE_PING, MAP_TYPE_LOCATION_CENTERED, ultping, pctping)
    LGPS:PopCurrentMap()
end

function POC_PingPipe.Unload()
    EVENT_MANAGER:UnregisterForEvent(POC_PingPipe.Name, EVENT_MAP_PING, on_map_ping)
    POC_PingPipe.active = false
end

function POC_PingPipe.Load()
    xxx = POC.xxx
    EVENT_MANAGER:RegisterForEvent(POC_PingPipe.Name, EVENT_MAP_PING, on_map_ping)
    POC_PingPipe.active = true
end
