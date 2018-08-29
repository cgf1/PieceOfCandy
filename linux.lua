POC = {}
setmetatable(POC, {__index = _G})
local IsLinux = true
LGS={} LGS.__index = LGS
setmetatable(LGS, LGS)
function GetUnitName(x) end 
_G.EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent() end
function GetUnitClass(x) end
function GetUnitName(x) end
LGS = { saveData = 0 }
LGS.__index = LGS
function LGS:RegisterHandler(x, y)
    return {{}, 1}
end

function HERE()
end

function ZO_CreateStringId(x)
    return
end

function SafeAddVersion(x, y)
    return
end

function GetString(x)
    return ''
end

function GetCVar()
    return ''
end

function ZO_ShallowTableCopy(x, y)
    return
end

_G.MAP_PIN_TAG_PLAYER_WAYPOINT = 1
_G.MAP_PIN_TAG_RALLY_POINT = 2
_G.MAP_PIN_TYPE_PLAYER_WAYPOINT = 3
_G.MAP_PIN_TYPE_PING = 4
_G.MAP_PIN_TYPE_RALLY_POINT = 5

local base = {} base.__index = base
ZO_CallbackObject = {} ZO_CallbackObject.__index = ZO_CallbackObject
function ZO_CallbackObject:New()
    return base
end
_G.ZO_CallbackObject = ZO_CallbackObject

function base:RegisterCallback()
end

ZO_WorldMapPins = {} ZO_WorldMapPins.__index = ZO_WorldMapPins
ZO_WorldMapPins.RefreshCustomPins = {}
function ZO_WorldMap_RefreshCustomPinsOfType()
end
function ZO_WorldMap_GetPanAndZoom()
end
function ZO_WorldMap_GetPinManager()
end
function ZO_WorldMap_AddCustomPin()
end
function ZO_WorldMap_SetCustomPinEnabled()
end
function StoreTamrielMapMeasurements()
end
function SetMapToPlayerLocation()
end
function SetMapToMapListIndex()
end
function GetMapIndexByZoneId()
end
function DoesUnitExist()
end

SLASH_COMMANDS = {}

EVENT_MANAGER = {} EVENT_MANAGER.__index = EVENT_MANAGER
function EVENT_MANAGER:UnregisterForEvent()
end
function EVENT_MANAGER:RegisterForEvent()
end
function GetZoneIndex()
end
function ZO_DeepTableCopy()
end

ZO_Object = {} ZO_Object.__index = ZO_Object
function ZO_Object:New()
    local base = setmetatable({}, ZO_Object)
    return base
end
function ZO_Object:Initialize()
    return
end
function ZO_Object:Subclass()
    local base = {}
    base.__index = ZO_Object
    return base
end
_G.ZO_Object = ZO_Object

function GetAPIVersion()
    return 100023
end

function d(...) end

SCENE_MANAGER = {}
SCENE_MANAGER.__index = SCENE_MANAGER

function SCENE_MANAGER:GetScene() return base end
UltNumber = {}

function GetWindowManager()
end

function Slash() end
SOUNDS = {}
