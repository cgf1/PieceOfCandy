POC = {}
setmetatable(POC, {__index = _G})
CyroDeal = {}
setmetatable(CyroDeal, {__index = _G})
local IsLinux = true
LGS={} LGS.__index = LGS
setmetatable(LGS, LGS)
function GetUnitName(x) return "foo" end
_G.EVENT_MANAGER = {}
function EVENT_MANAGER:RegisterForEvent() end
function GetUnitClass(x) return "foo" end
LGS = { saveData = 0 }
LGS.__index = LGS
function LGS:RegisterHandler(x, y)
    return {{}, 1}
end

function HERE()
end

function GetTimeStamp()
    return 0
end

function GetGameTimeMilliseconds()
    return 0
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
function ZO_WorldMap_AddCustomPin(pinType, func)
    local tbl = {customPins = {}, m_keyToPinMapping = {}}
    func(tbl)
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
SLASH_COMMANDS['/script'] = function(...)
    x = assert(load(...))
    x()
end

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

function d(...) print(...) end

SCENE_MANAGER = {}
SCENE_MANAGER.__index = SCENE_MANAGER

function SCENE_MANAGER:GetScene() return base end
UltNumber = {}

function GetWindowManager()
end

function Slash() end
SOUNDS = {}

local define = {
    'GetGroupUnitTagByIndex',
    'GetUnitClassId',
    'GetUnitDisplayName',
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

for _, fn in pairs(define) do
    local doit = string.format("function %s(...) end", fn)
    f=assert(load(doit))
    f()
end

ACTION_RESULT_ABILITY_ON_COOLDOWN = 2080
ACTION_RESULT_ABSORBED = 2120
ACTION_RESULT_BAD_TARGET = 2040
ACTION_RESULT_BATTLE_STANDARD_ALREADY_EXISTS_FOR_GUILD = 3180
ACTION_RESULT_BATTLE_STANDARD_LIMIT = 3160
ACTION_RESULT_BATTLE_STANDARD_NO_PERMISSION = 3200
ACTION_RESULT_BATTLE_STANDARD_TABARD_MISMATCH = 3170
ACTION_RESULT_BATTLE_STANDARD_TOO_CLOSE_TO_CAPTURABLE = 3190
ACTION_RESULT_BATTLE_STANDARDS_DISABLED = 3210
ACTION_RESULT_BEGIN_CHANNEL = 2210
ACTION_RESULT_BEGIN = 2200
ACTION_RESULT_BLADETURN = 2360
ACTION_RESULT_BLOCKED_DAMAGE = 2151
ACTION_RESULT_BLOCKED = 2150
ACTION_RESULT_BUSY = 2030
ACTION_RESULT_CANNOT_USE = 2290
ACTION_RESULT_CANT_SEE_TARGET = 2330
ACTION_RESULT_CANT_SWAP_WHILE_CHANGING_GEAR = 3410
ACTION_RESULT_CASTER_DEAD = 2060
ACTION_RESULT_CRITICAL_DAMAGE = 2
ACTION_RESULT_CRITICAL_HEAL = 32
ACTION_RESULT_DAMAGE_SHIELDED = 2460
ACTION_RESULT_DAMAGE = 1
ACTION_RESULT_DEFENDED = 2190
ACTION_RESULT_DIED_XP = 2262
ACTION_RESULT_DIED = 2260
ACTION_RESULT_DISARMED = 2430
ACTION_RESULT_DISORIENTED = 2340
ACTION_RESULT_DODGED = 2140
ACTION_RESULT_DOT_TICK_CRITICAL = 1073741826
ACTION_RESULT_DOT_TICK = 1073741825
ACTION_RESULT_EFFECT_FADED = 2250
ACTION_RESULT_EFFECT_GAINED_DURATION = 2245
ACTION_RESULT_EFFECT_GAINED = 2240
ACTION_RESULT_FAILED_REQUIREMENTS = 2310
ACTION_RESULT_FAILED_SIEGE_CREATION_REQUIREMENTS = 3100
ACTION_RESULT_FAILED = 2110
ACTION_RESULT_FALL_DAMAGE = 2420
ACTION_RESULT_FALLING = 2500
ACTION_RESULT_FEARED = 2320
ACTION_RESULT_FORWARD_CAMP_ALREADY_EXISTS_FOR_GUILD = 3230
ACTION_RESULT_FORWARD_CAMP_NO_PERMISSION = 3240
ACTION_RESULT_FORWARD_CAMP_TABARD_MISMATCH = 3220
ACTION_RESULT_GRAVEYARD_DISALLOWED_IN_INSTANCE = 3080
ACTION_RESULT_GRAVEYARD_TOO_CLOSE = 3030
ACTION_RESULT_HEAL = 16
ACTION_RESULT_HOT_TICK_CRITICAL = 1073741856
ACTION_RESULT_HOT_TICK = 1073741840
ACTION_RESULT_IMMUNE = 2000
ACTION_RESULT_IN_AIR = 2510
ACTION_RESULT_IN_COMBAT = 2300
ACTION_RESULT_IN_ENEMY_KEEP = 2610
ACTION_RESULT_IN_ENEMY_OUTPOST = 2613
ACTION_RESULT_IN_ENEMY_RESOURCE = 2612
ACTION_RESULT_IN_ENEMY_TOWN = 2611
ACTION_RESULT_IN_HIDEYHOLE = 3440
ACTION_RESULT_INSUFFICIENT_RESOURCE = 2090
ACTION_RESULT_INTERCEPTED = 2410
ACTION_RESULT_INTERRUPT = 2230
ACTION_RESULT_INVALID_FIXTURE = 2810
ACTION_RESULT_INVALID_JUSTICE_TARGET = 3420
ACTION_RESULT_INVALID_TERRAIN = 2800
ACTION_RESULT_INVALID = -1
ACTION_RESULT_ITERATION_BEGIN = -1
ACTION_RESULT_ITERATION_END = 1073741856
ACTION_RESULT_KILLED_BY_SUBZONE = 3130
ACTION_RESULT_KILLING_BLOW = 2265
ACTION_RESULT_KNOCKBACK = 2475
ACTION_RESULT_LEVITATED = 2400
ACTION_RESULT_LINKED_CAST = 2392
ACTION_RESULT_MAX_VALUE = 1073741856
ACTION_RESULT_MERCENARY_LIMIT = 3140
ACTION_RESULT_MIN_VALUE = -1
ACTION_RESULT_MISS = 2180
ACTION_RESULT_MISSING_EMPTY_SOUL_GEM = 3040
ACTION_RESULT_MISSING_FILLED_SOUL_GEM = 3060
ACTION_RESULT_MOBILE_GRAVEYARD_LIMIT = 3150
ACTION_RESULT_MOUNTED = 3070
ACTION_RESULT_MUST_BE_IN_OWN_KEEP = 2630
ACTION_RESULT_NO_LOCATION_FOUND = 2700
ACTION_RESULT_NO_RAM_ATTACKABLE_TARGET_WITHIN_RANGE = 2910
ACTION_RESULT_NO_WEAPONS_TO_SWAP_TO = 3400
ACTION_RESULT_NOT_ENOUGH_INVENTORY_SPACE_SOUL_GEM = 3050
ACTION_RESULT_NOT_ENOUGH_INVENTORY_SPACE = 3430
ACTION_RESULT_NOT_ENOUGH_SPACE_FOR_SIEGE = 3090
ACTION_RESULT_NPC_TOO_CLOSE = 2640
ACTION_RESULT_OFFBALANCE = 2440
ACTION_RESULT_PACIFIED = 2390
ACTION_RESULT_PARRIED = 2130
ACTION_RESULT_PARTIAL_RESIST = 2170
ACTION_RESULT_POWER_DRAIN = 64
ACTION_RESULT_POWER_ENERGIZE = 128
ACTION_RESULT_PRECISE_DAMAGE = 4
ACTION_RESULT_QUEUED = 2350
ACTION_RESULT_RAM_ATTACKABLE_TARGETS_ALL_DESTROYED = 3120
ACTION_RESULT_RAM_ATTACKABLE_TARGETS_ALL_OCCUPIED = 3110
ACTION_RESULT_RECALLING = 2520
ACTION_RESULT_REFLECTED = 2111
ACTION_RESULT_REINCARNATING = 3020
ACTION_RESULT_RESIST = 2160
ACTION_RESULT_RESURRECT = 2490
ACTION_RESULT_ROOTED = 2480
ACTION_RESULT_SIEGE_LIMIT = 2620
ACTION_RESULT_SIEGE_NOT_ALLOWED_IN_ZONE = 2605
ACTION_RESULT_SIEGE_TOO_CLOSE = 2600
ACTION_RESULT_SILENCED = 2010
ACTION_RESULT_SNARED = 2025
ACTION_RESULT_SPRINTING = 3000
ACTION_RESULT_STAGGERED = 2470
ACTION_RESULT_STUNNED = 2020
ACTION_RESULT_SWIMMING = 3010
ACTION_RESULT_TARGET_DEAD = 2050
ACTION_RESULT_TARGET_NOT_IN_VIEW = 2070
ACTION_RESULT_TARGET_NOT_PVP_FLAGGED = 2391
ACTION_RESULT_TARGET_OUT_OF_RANGE = 2100
ACTION_RESULT_TARGET_TOO_CLOSE = 2370
ACTION_RESULT_UNEVEN_TERRAIN = 2900
ACTION_RESULT_WEAPONSWAP = 2450
ACTION_RESULT_WRECKING_DAMAGE = 8
ACTION_RESULT_WRONG_WEAPON = 2380
_G["LibMapPins_Hack_to_get_PinManager"] = 'BLAH'

CALLBACK_MANAGER = {}
function CALLBACK_MANAGER:RegisterCallback()
    return
end

function ZO_PreHook()
    return
end

function ZO_PostHook()
end

ZO_ColorDef={} ZO_ColorDef.__index = ZO_ColorDef
setmetatable(ZO_ColorDef, ZO_ColorDef)

function ZO_ColorDef:New()
end
-- dofile('addons/LibStub/LibStub/LibStub.lua')
dofile('addons/LibAddonMenu-2.0/LibAddonMenu-2.0.lua')

local addons = {
    'LibStub/LibStub/LibStub',

    'LibAddonMenu-2.0/LibAddonMenu-2.0',

    -- 'LibChatMessage/LibChatMessage',

    --[[ 'LibDebugLogger/LibDebugLogger',
    'LibDebugLogger/Constants',
    'LibDebugLogger/Logger',
    'LibDebugLogger/Settings',
    'LibDebugLogger/StartUpConfig',
    'LibDebugLogger/LogHandler',
    'LibDebugLogger/Callbacks',
    'LibDebugLogger/API',
    'LibDebugLogger/Compatibility', --]]
    -- 'LibDebugLogger/Initialization',

    --[[ 'LibGPS/StartUp',
    'LibGPS/Measurement',
    'LibGPS/MapStack',
    'LibGPS/MapAdapter',
    'LibGPS/TamrielOMeter',
    'LibGPS/WaypointManager',
    'LibGPS/api',
    'LibGPS/compatibility', --]]

    'LibMapPing/LibMapPing',

    'LibMapPins-1.0/LibMapPins-1.0',
}

ADDON_STATE_NO_STATE = 1
ADDON_STATE_TOC_LOADED = 2
ADDON_STATE_ENABLED = 3
ADDON_STATE_DISABLED = 4
ADDON_STATE_VERSION_MISMATCH = 5
ADDON_STATE_DEPENDENCIES_DISABLED = 6
ADDON_STATE_ERROR_STATE_UNABLE_TO_LOAD = 7
EVENT_CHAT_MESSAGE_CHANNEL = 1
EVENT_BROADCAST = 2
EVENT_FRIEND_PLAYER_STATUS_CHANGED = 3
EVENT_IGNORE_ADDED = 4
EVENT_IGNORE_REMOVED = 5
EVENT_GROUP_TYPE_CHANGED = 6
EVENT_GROUP_INVITE_RESPONSE = 7
EVENT_SOCIAL_ERROR = 8
EVENT_TRIAL_FEATURE_RESTRICTED = 9
EVENT_GROUP_MEMBER_LEFT = 10
EVENT_BATTLEGROUND_INACTIVITY_WARNING = 11

CHAT_ROUTER = {}
setmetatable(CHAT_ROUTER, {__index = _G})
CHAT_ROUTER[EVENT_CHAT_MESSAGE_CHANNEL] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end
CHAT_ROUTER[EVENT_BROADCAST] = function () end

LibChatMessage = {}
function LibChatMessage.Create()
end

function CHAT_ROUTER:GetRegisteredMessageFormatters()
    return CHAT_ROUTER
end

AM = {}
setmetatable(AM, {__index = _G})

function GetAddOnManager()
    return AM
end

function AM:GetNumAddOns()
    return 0
end

for _, s in ipairs(addons) do
    dofile('addons/' .. s .. '.lua')
end

local x = {
    __index = _G,
}
CyroDoor = setmetatable(x, x)
CyroDoor.CyroDoor = CyroDoor

function setfenv()
end

WINDOW_MANAGER = { saveData = 0 }
WINDOW_MANAGER.__index = WINDOW_MANAGER
function WINDOW_MANAGER:CreateControl()
    return {}
end
