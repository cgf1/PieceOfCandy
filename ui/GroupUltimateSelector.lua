--[[
	Local variables
]]--
local LOG_ACTIVE = false

local _logger = nil
local _control = nil

--[[
	Table GroupUltimateSelector
]]--
POC_GroupUltimateSelector = {}
POC_GroupUltimateSelector.__index = POC_GroupUltimateSelector

--[[
	Table Members
]]--

--[[
	SetUltimateIcon sets the button icon in base of staticUltimateID
]]--
function POC_GroupUltimateSelector.SetUltimateIcon(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.SetUltimateIcon")
        _logger:logDebug("staticUltimateID", staticUltimateID)
    end

    local icon = "/esoui/art/icons/icon_missing.dds"

    if (staticUltimateID ~= 0) then
        icon = GetAbilityIcon(staticUltimateID)
    end

    local iconControl = _control:GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")

    if (icon ~= nil and iconControl ~= nil) then
        iconControl:SetTexture(icon)
    else
        _logger:logError("POC_GroupUltimateSelector.SetUltimateIcon, icon is " .. tostring(icon) .. "; iconControl is " .. tostring(iconControl))
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function POC_GroupUltimateSelector.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets POC_GroupUltimateSelector on settings position
]]--
function POC_GroupUltimateSelector.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnPOC_GroupUltimateSelectorMoveStop saves current POC_GroupUltimateSelector position to settings
]]--
function POC_GroupUltimateSelector.OnGroupUltimateSelectorMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("POC_GroupUltimateSelector.OnGroupUltimateSelectorMoveStop") end

	local left = _control:GetLeft()
	local top = _control:GetTop()
	
    POC_Settings.SavedVariables.SelectorPosX = left
    POC_Settings.SavedVariables.SelectorPosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", POC_Settings.SavedVariables.SelectorPosX, POC_Settings.SavedVariables.SelectorPosY)
    end
end

--[[
	OnGroupUltimateSelectorClicked shows ultimate group menu
]]--
function POC_GroupUltimateSelector.OnGroupUltimateSelectorClicked()
    if (LOG_ACTIVE) then _logger:logTrace("POC_GroupUltimateSelector.OnGroupUltimateSelectorClicked") end

    local button = _control:GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, POC_GroupUltimateSelector.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, button)
    else
        _logger:logError("POC_GroupUltimateSelector.OnGroupUltimateSelectorClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup sets ultimate group for button
]]--
function POC_GroupUltimateSelector.OnSetUltimateGroup(group)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName", group.GroupName)
    end

    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, POC_GroupUltimateSelector.OnSetUltimateGroup)

    if (group ~= nil) then
        POC_Settings.SetStaticUltimateIDSettings(group.GroupAbilityId)
    else
        _logger:logError("POC_UltimateGroupMenu.ShowUltimateGroupMenu, group nil")
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function POC_GroupUltimateSelector.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.SetControlHidden")
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
function POC_GroupUltimateSelector.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_GroupUltimateSelector.SetControlActive")
    end

    local isHidden = POC_Settings.IsControlsVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end

    POC_GroupUltimateSelector.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
        CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, POC_GroupUltimateSelector.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(POC_STATIC_ULTIMATE_ID_CHANGED, POC_GroupUltimateSelector.SetUltimateIcon)
        CALLBACK_MANAGER:UnregisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, POC_GroupUltimateSelector.SetControlHidden)
    else
        POC_GroupUltimateSelector.SetControlMovable(POC_Settings.SavedVariables.Movable)
        POC_GroupUltimateSelector.RestorePosition(POC_Settings.SavedVariables.SelectorPosX, POC_Settings.SavedVariables.SelectorPosY)
        POC_GroupUltimateSelector.SetUltimateIcon(POC_Settings.SavedVariables.StaticUltimateID)

        CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, POC_GroupUltimateSelector.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(POC_STATIC_ULTIMATE_ID_CHANGED, POC_GroupUltimateSelector.SetUltimateIcon)
        CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, POC_GroupUltimateSelector.SetControlHidden)
    end
end

--[[
	Initialize initializes POC_GroupUltimateSelector
]]--
function POC_GroupUltimateSelector.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_GroupUltimateSelector.Initialize")
    end

    _logger = logger
    _control = POC_UltimateSelectorControl

    POC_GroupUltimateSelector.SetUltimateIcon(staticUltimateID)

    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, POC_GroupUltimateSelector.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, POC_GroupUltimateSelector.SetControlActive)
end
