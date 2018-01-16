--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table TGU_UltimateGroupHandler
]]--
TGU_UltimateGroupHandler = {}
TGU_UltimateGroupHandler.__index = TGU_UltimateGroupHandler

--[[
	Table Members
]]--
TGU_UltimateGroupHandler.Name = "TGU-UltimateGroupHandler"
TGU_UltimateGroupHandler.UltimateGroups = nil

--[[
	GetUltimateGroupByAbilityPing gets the ultimate group from given ability ping
]]--
function TGU_UltimateGroupHandler.GetUltimateGroupByAbilityPing(abilityPing)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_UltimateGroupHandler.GetUltimateGroupByAbilityPing")
        _logger:logDebug("abilityPing", abilityPing)
    end

    for i, group in pairs(TGU_UltimateGroupHandler.UltimateGroups) do
        if (group.GroupAbilityPing == abilityPing) then
            return group
        end
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(abilityPing))

    return nil
end

--[[
	GetUltimateGroupByAbilityId gets the ultimate group from given ability ID
]]--
function TGU_UltimateGroupHandler.GetUltimateGroupByAbilityId(abilityID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_UltimateGroupHandler.GetUltimateGroupByAbilityId")
        _logger:logDebug("abilityID", abilityID)
    end

    for i, group in pairs(TGU_UltimateGroupHandler.UltimateGroups) do
        if (group.GroupAbilityId == abilityID) then
            return group
        end
    end

    -- not found
    _logger:logError("AbilityId not found " .. tostring(abilityID))

    return nil
end

--[[
	GetUltimateGroupByGroupName gets the ultimate group from given group name
]]--
function TGU_UltimateGroupHandler.GetUltimateGroupByGroupName(groupName)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_UltimateGroupHandler.GetUltimateGroupByGroupName")
        _logger:logDebug("groupName", groupName)
    end

    for i, group in pairs(TGU_UltimateGroupHandler.UltimateGroups) do
        if (string.lower(group.GroupName) == string.lower(groupName)) then
            return group
        end
    end

    -- not found
    _logger:logError("GroupName not found " .. tostring(groupName))

    return nil
end

--[[
	GetUltimateGroups gets all ultimate groups
]]--
function TGU_UltimateGroupHandler.GetUltimateGroups()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_UltimateGroupHandler.GetUltimateGroups") end

    return TGU_UltimateGroupHandler.UltimateGroups
end

--[[
	CreateUltimateGroups Creates UltimateGroups array
]]--
function TGU_UltimateGroupHandler.CreateUltimateGroups()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_UltimateGroupHandler.CreateUltimateGroups") end

    -- Sorc
    local negate = {}
    negate.GroupName = "NEGATE"
    negate.GroupDescription = GetString(TGU_DESCRIPTIONS_NEGATE)
    negate.GroupAbilityPing = 1
    negate.GroupAbilityId = 29861

    local atro = {}
    atro.GroupName = "ATRO"
    atro.GroupDescription = GetString(TGU_DESCRIPTIONS_ATRO)
    atro.GroupAbilityPing = 2
    atro.GroupAbilityId = 30553

    local overload = {}
    overload.GroupName = "OVER"
    overload.GroupDescription = GetString(TGU_DESCRIPTIONS_OVER)
    overload.GroupAbilityPing = 3
    overload.GroupAbilityId = 30366

    -- Templar
    local sweep = {}
    sweep.GroupName = "SWEEP"
    sweep.GroupDescription = GetString(TGU_DESCRIPTIONS_SWEEP)
    sweep.GroupAbilityPing = 4
    sweep.GroupAbilityId = 23788
    
    local nova = {}
    nova.GroupName = "NOVA"
    nova.GroupDescription = GetString(TGU_DESCRIPTIONS_NOVA)
    nova.GroupAbilityPing = 5
    nova.GroupAbilityId = 24301

    local templarHeal = {}
    templarHeal.GroupName = "TPHEAL"
    templarHeal.GroupDescription = GetString(TGU_DESCRIPTIONS_TPHEAL)
    templarHeal.GroupAbilityPing = 6
    templarHeal.GroupAbilityId = 27413

    -- DK
    local standard = {}
    standard.GroupName = "STAND"
    standard.GroupDescription = GetString(TGU_DESCRIPTIONS_STAND)
    standard.GroupAbilityPing = 7
    standard.GroupAbilityId = 34021

    local leap = {}
    leap.GroupName = "LEAP"
    leap.GroupDescription = GetString(TGU_DESCRIPTIONS_LEAP)
    leap.GroupAbilityPing = 8
    leap.GroupAbilityId = 33668

    local magma = {}
    magma.GroupName = "MAGMA"
    magma.GroupDescription = GetString(TGU_DESCRIPTIONS_MAGMA)
    magma.GroupAbilityPing = 9
    magma.GroupAbilityId = 33841

    -- NB
    local stroke = {}
    stroke.GroupName = "STROKE"
    stroke.GroupDescription = GetString(TGU_DESCRIPTIONS_STROKE)
    stroke.GroupAbilityPing = 10
    stroke.GroupAbilityId = 37545

    local veil = {}
    veil.GroupName = "VEIL"
    veil.GroupDescription = GetString(TGU_DESCRIPTIONS_VEIL)
    veil.GroupAbilityPing = 11
    veil.GroupAbilityId = 37713

    local nbSoul = {}
    nbSoul.GroupName = "NBSOUL"
    nbSoul.GroupDescription = GetString(TGU_DESCRIPTIONS_NBSOUL)
    nbSoul.GroupAbilityPing = 12
    nbSoul.GroupAbilityId = 36207

    -- Warden
    -- BEAR not useful, its always up

    local wardenIce = {}
    wardenIce.GroupName = "FREEZE"
    wardenIce.GroupDescription = GetString(TGU_DESCRIPTIONS_FREEZE)
    wardenIce.GroupAbilityPing = 13
    wardenIce.GroupAbilityId = 86112

    local wardenHealing = {}
    wardenHealing.GroupName = "WDHEAL"
    wardenHealing.GroupDescription = GetString(TGU_DESCRIPTIONS_WDHEAL)
    wardenHealing.GroupAbilityPing = 14
    wardenHealing.GroupAbilityId = 93971

    -- Destro
    local staffIce = {}
    staffIce.GroupName = "ICE"
    staffIce.GroupDescription = GetString(TGU_DESCRIPTIONS_ICE)
    staffIce.GroupAbilityPing = 15
    staffIce.GroupAbilityId = 86542

    local staffFire = {}
    staffFire.GroupName = "FIRE"
    staffFire.GroupDescription = GetString(TGU_DESCRIPTIONS_FIRE)
    staffFire.GroupAbilityPing = 16
    staffFire.GroupAbilityId = 86536

    local staffLightning = {}
    staffLightning.GroupName = "LIGHT"
    staffLightning.GroupDescription = GetString(TGU_DESCRIPTIONS_LIGHT)
    staffLightning.GroupAbilityPing = 17
    staffLightning.GroupAbilityId = 86550

    -- Restro
    local staffHeal = {}
    staffHeal.GroupName = "STHEAL"
    staffHeal.GroupDescription = GetString(TGU_DESCRIPTIONS_STHEAL)
    staffHeal.GroupAbilityPing = 18
    staffHeal.GroupAbilityId = 86454

    -- 2H
    local twoHand = {}
    twoHand.GroupName = "BERSERK"
    twoHand.GroupDescription = GetString(TGU_DESCRIPTIONS_BERSERK)
    twoHand.GroupAbilityPing = 19
    twoHand.GroupAbilityId = 86284

    -- SB
    local shield = {}
    shield.GroupName = "SHIELD"
    shield.GroupDescription = GetString(TGU_DESCRIPTIONS_SHIELD)
    shield.GroupAbilityPing = 20
    shield.GroupAbilityId = 83292

    -- DW
    local dual = {}
    dual.GroupName = "DUAL"
    dual.GroupDescription = GetString(TGU_DESCRIPTIONS_DUAL)
    dual.GroupAbilityPing = 21
    dual.GroupAbilityId = 86410

    -- BOW
    local bow = {}
    bow.GroupName = "BOW"
    bow.GroupDescription = GetString(TGU_DESCRIPTIONS_BOW)
    bow.GroupAbilityPing = 22
    bow.GroupAbilityId = 86620

    -- Soul
    local soul = {}
    soul.GroupName = "SOUL"
    soul.GroupDescription = GetString(TGU_DESCRIPTIONS_SOUL)
    soul.GroupAbilityPing = 23
    soul.GroupAbilityId = 43109

    -- Werewolf
    local werewolf = {}
    werewolf.GroupName = "WERE"
    werewolf.GroupDescription = GetString(TGU_DESCRIPTIONS_WERE)
    werewolf.GroupAbilityPing = 24
    werewolf.GroupAbilityId = 42379

    -- Vamp
    local vamp = {}
    vamp.GroupName = "VAMP"
    vamp.GroupDescription = GetString(TGU_DESCRIPTIONS_VAMP)
    vamp.GroupAbilityPing = 25
    vamp.GroupAbilityId = 41937

    -- Mageguild
    local meteor = {}
    meteor.GroupName = "METEOR"
    meteor.GroupDescription = GetString(TGU_DESCRIPTIONS_METEOR)
    meteor.GroupAbilityPing = 26
    meteor.GroupAbilityId = 42492

    -- Fighterguild
    local dawnbreaker = {}
    dawnbreaker.GroupName = "DAWN"
    dawnbreaker.GroupDescription = GetString(TGU_DESCRIPTIONS_DAWN)
    dawnbreaker.GroupAbilityPing = 27
    dawnbreaker.GroupAbilityId = 42598

    -- Support
    local barrier = {}
    barrier.GroupName = "BARRIER"
    barrier.GroupDescription = GetString(TGU_DESCRIPTIONS_BARRIER)
    barrier.GroupAbilityPing = 28
    barrier.GroupAbilityId = 46622

    -- Assault
    local horn = {}
    horn.GroupName = "HORN"
    horn.GroupDescription = GetString(TGU_DESCRIPTIONS_HORN)
    horn.GroupAbilityPing = 29
    horn.GroupAbilityId = 46537

    -- Add groups
    TGU_UltimateGroupHandler.UltimateGroups = 
    { 
        negate, atro, overload, 
        sweep, nova, templarHeal, 
        standard, leap, magma, 
        stroke, veil, nbSoul,
        wardenIce, wardenHealing, 
        staffIce, staffFire, staffLightning, staffHeal, 
        twoHand, shield, dual, bow,
        soul, werewolf, vamp,
        meteor, dawnbreaker, 
        barrier, horn
    }
end

--[[
	Initialize initializes TGU_UltimateGroupHandler
]]--
function TGU_UltimateGroupHandler.Initialize(logger)
    if (LOG_ACTIVE) then logger:logTrace("TGU_UltimateGroupHandler.Initialize") end

    _logger = logger

    TGU_UltimateGroupHandler.CreateUltimateGroups()
end
