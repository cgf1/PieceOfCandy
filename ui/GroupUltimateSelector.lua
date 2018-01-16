--[[
	Local variables
]]--
local LOG_ACTIVE = false

local _logger = nil
local _control = nil

--[[
	Table GroupUltimateSelector
]]--
TGU_GroupUltimateSelector = {}
TGU_GroupUltimateSelector.__index = TGU_GroupUltimateSelector

--[[
	Table Members
]]--

--[[
	SetUltimateIcon sets the button icon in base of staticUltimateID
]]--
function TGU_GroupUltimateSelector.SetUltimateIcon(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.SetUltimateIcon")
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
        _logger:logError("TGU_GroupUltimateSelector.SetUltimateIcon, icon is " .. tostring(icon) .. "; iconControl is " .. tostring(iconControl))
    end
end

--[[
	SetControlMovable sets the Movable and MouseEnabled flag in UI elements
]]--
function TGU_GroupUltimateSelector.SetControlMovable(isMovable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.SetControlMovable")
        _logger:logDebug("isMovable", isMovable)
    end

    _control:GetNamedChild("MovableControl"):SetHidden(isMovable == false)

    _control:SetMovable(isMovable)
	_control:SetMouseEnabled(isMovable)
end

--[[
	RestorePosition sets TGU_GroupUltimateSelector on settings position
]]--
function TGU_GroupUltimateSelector.RestorePosition(posX, posY)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.RestorePosition")
        _logger:logDebug("posX, posY", posX, posY)
    end

	_control:ClearAnchors()
	_control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

--[[
	OnTGU_GroupUltimateSelectorMoveStop saves current TGU_GroupUltimateSelector position to settings
]]--
function TGU_GroupUltimateSelector.OnGroupUltimateSelectorMoveStop()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupUltimateSelector.OnGroupUltimateSelectorMoveStop") end

	local left = _control:GetLeft()
	local top = _control:GetTop()
	
    TGU_SettingsHandler.SavedVariables.SelectorPosX = left
    TGU_SettingsHandler.SavedVariables.SelectorPosY = top

    if (LOG_ACTIVE) then 
        _logger:logDebug("PosX, PosY", TGU_SettingsHandler.SavedVariables.SelectorPosX, TGU_SettingsHandler.SavedVariables.SelectorPosY)
    end
end

--[[
	OnGroupUltimateSelectorClicked shows ultimate group menu
]]--
function TGU_GroupUltimateSelector.OnGroupUltimateSelectorClicked()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupUltimateSelector.OnGroupUltimateSelectorClicked") end

    local button = _control:GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")

    if (button ~= nil) then
        CALLBACK_MANAGER:RegisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_GroupUltimateSelector.OnSetUltimateGroup)
        CALLBACK_MANAGER:FireCallbacks(TGU_SHOW_ULTIMATE_GROUP_MENU, button)
    else
        _logger:logError("TGU_GroupUltimateSelector.OnGroupUltimateSelectorClicked, button nil")
    end
end

--[[
	OnSetUltimateGroup sets ultimate group for button
]]--
function TGU_GroupUltimateSelector.OnSetUltimateGroup(group)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.OnSetUltimateGroup")
        _logger:logDebug("group.GroupName", group.GroupName)
    end

    CALLBACK_MANAGER:UnregisterCallback(TGU_SET_ULTIMATE_GROUP, TGU_GroupUltimateSelector.OnSetUltimateGroup)

    if (group ~= nil) then
        TGU_SettingsHandler.SetStaticUltimateIDSettings(group.GroupAbilityId)
    else
        _logger:logError("TGU_UltimateGroupMenu.ShowUltimateGroupMenu, group nil")
    end
end

--[[
	SetControlHidden sets hidden on control
]]--
function TGU_GroupUltimateSelector.SetControlHidden(isHidden)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.SetControlHidden")
        _logger:logDebug("isHidden", isHidden)
    end

    if (TGU_GroupHandler.IsGrouped()) then
        _control:SetHidden(isHidden)
    else
        _control:SetHidden(true)
    end
end

--[[
	SetControlActive activates/deactivates control
]]--
function TGU_GroupUltimateSelector.SetControlActive()
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_GroupUltimateSelector.SetControlActive")
    end

    local isHidden = TGU_SettingsHandler.IsControlsVisible() == false
    if (LOG_ACTIVE) then _logger:logDebug("isHidden", isHidden) end

    TGU_GroupUltimateSelector.SetControlHidden(isHidden or CurrentHudHiddenState())

    if (isHidden) then
        CALLBACK_MANAGER:UnregisterCallback(TGU_MOVABLE_CHANGED, TGU_GroupUltimateSelector.SetControlMovable)
        CALLBACK_MANAGER:UnregisterCallback(TGU_STATIC_ULTIMATE_ID_CHANGED, TGU_GroupUltimateSelector.SetUltimateIcon)
        CALLBACK_MANAGER:UnregisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_GroupUltimateSelector.SetControlHidden)
    else
        TGU_GroupUltimateSelector.SetControlMovable(TGU_SettingsHandler.SavedVariables.Movable)
        TGU_GroupUltimateSelector.RestorePosition(TGU_SettingsHandler.SavedVariables.SelectorPosX, TGU_SettingsHandler.SavedVariables.SelectorPosY)
        TGU_GroupUltimateSelector.SetUltimateIcon(TGU_SettingsHandler.SavedVariables.StaticUltimateID)

        CALLBACK_MANAGER:RegisterCallback(TGU_MOVABLE_CHANGED, TGU_GroupUltimateSelector.SetControlMovable)
        CALLBACK_MANAGER:RegisterCallback(TGU_STATIC_ULTIMATE_ID_CHANGED, TGU_GroupUltimateSelector.SetUltimateIcon)
        CALLBACK_MANAGER:RegisterCallback(TUI_HUD_HIDDEN_STATE_CHANGED, TGU_GroupUltimateSelector.SetControlHidden)
    end
end

--[[
	Initialize initializes TGU_GroupUltimateSelector
]]--
function TGU_GroupUltimateSelector.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_GroupUltimateSelector.Initialize")
    end

    _logger = logger
    _control = TGU_UltimateSelectorControl

    TGU_GroupUltimateSelector.SetUltimateIcon(staticUltimateID)

    CALLBACK_MANAGER:RegisterCallback(TGU_IS_ZONE_CHANGED, TGU_GroupUltimateSelector.SetControlActive)
    CALLBACK_MANAGER:RegisterCallback(TGU_UNIT_GROUPED_CHANGED, TGU_GroupUltimateSelector.SetControlActive)
end
