--[[
	Local variables
]]--
local LOG_ACTIVE = false

local _logger = nil
local _control = nil

--[[
	Table UltSelector
]]--
POC_UltSelector = {}
POC_UltSelector.__index = POC_UltSelector

local ultix = GetUnitName("player")

--[[
	Table Members
]]--

-- SetUltimateIcon sets the button icon in base of staticUltimateID
--
function POC_UltSelector.SetUltimateIcon(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.SetUltimateIcon")
        _logger:logDebug("staticUltimateID", staticUltimateID)
    end

    local icon
    if (staticUltimateID == 0) then
        icon = "/esoui/art/icons/icon_missing.dds"
    else
        icon = GetAbilityIcon(staticUltimateID)
    end

    local iconControl = _control:GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")

    if (icon ~= nil and iconControl ~= nil) then
        iconControl:SetTexture(icon)
    else
        _logger:logError("POC_UltSelector.SetUltimateIcon, icon is " .. tostring(icon) .. "; iconControl is " .. tostring(iconControl))
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function POC_UltSelector.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets POC_UltSelector on settings position
]]--
function POC_UltSelector.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnPOC_UltSelectorMoveStop saves current POC_UltSelector position to settings
]]--
function POC_UltSelector.OnUltSelectorMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("POC_UltSelector.OnUltSelectorMoveStop") end

    local left = _control:GetLeft()
    local top = _control:GetTop()
	
    POC_Settings.SavedVariables.SelectorPosX = left
    POC_Settings.SavedVariables.SelectorPosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", POC_Settings.SavedVariables.SelectorPosX, POC_Settings.SavedVariables.SelectorPosY)
    end
end

--[[
	OnUltSelectorClicked shows ultimate group menu
]]--
function POC_UltSelector.OnUltSelectorClicked()
    if (LOG_ACTIVE) then _logger:logTrace("POC_UltSelector.OnUltSelectorClicked") end

    local button = _control:GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, POC_UltSelector.OnSetUltGrp)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button)
    else
        _logger:logError("POC_UltSelector.OnUltSelectorClicked, button nil")
    end
end

--[[
	OnSetUltGrp sets ultimate group for button
]]--
function POC_UltSelector.OnSetUltGrp(group)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.OnSetUltGrp")
        _logger:logDebug("group.GroupName", group.GroupName)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, POC_UltSelector.OnSetUltGrp)

    if (group ~= nil) then
        POC_Settings.SetStaticUltimateIDSettings(group.GroupAbilityId)
    else
        _logger:logError("POC_UltGrpMenu.ShowUltGrpMenu, group nil")
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function POC_UltSelector.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (POC_GroupHandler.IsGrouped()) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive activates/deactivates control
]]--
function POC_UltSelector.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltSelector.SetControlActive")
    end

    local isHidden = POC_Settings.IsControlsVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end

    POC_UltSelector.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, POC_UltSelector.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_STATIC_ULTIMATE_ID_CHANGED, POC_UltSelector.SetUltimateIcon)
        CALLBACK_MANAGER:UnregisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, POC_UltSelector.SetControlHidden)
    else
        POC_UltSelector.SetControlMovable(POC_Settings.SavedVariables.Movable)
        POC_UltSelector.RestorePosition(POC_Settings.SavedVariables.SelectorPosX, POC_Settings.SavedVariables.SelectorPosY)
        POC_UltSelector.SetUltimateIcon(POC_Settings.SavedVariables.MyUltId[ultix])

        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, POC_UltSelector.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_STATIC_ULTIMATE_ID_CHANGED, POC_UltSelector.SetUltimateIcon)
        CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, POC_UltSelector.SetControlHidden)
    end
end

--[[
	Initialize initializes POC_UltSelector
]]--
function POC_UltSelector.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_UltSelector.Initialize")
    end

    _logger = logger
    _control = POC_UltimateSelectorControl

    POC_UltSelector.SetUltimateIcon(staticUltimateID)

    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, POC_UltSelector.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, POC_UltSelector.SetControlActive)
end
