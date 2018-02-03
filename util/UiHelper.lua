--[[
	Class definition (Static class)
]]--
-- A table in whole lua workspace must be unique
-- The ui helper is global util table, used in several of my addons
-- The table is created as "static" class without constructor and static helper methods
if (POCUiHelper == nil) then
	POCUiHelper = {}
	POCUiHelper.__index = POCUiHelper

    -- Global Callback Variables
    POC_HUD_HIDDEN_STATE_CHANGED = "POC-HudHiddenStateChange"

	-- isHidden logic for hud scenes
    -- This logic will fire POC_HUD_HIDDEN_STATE_CHANGED if hud scenes not visible:
    -- hud = true; hudui = true -> isHidden = true
    -- hud = true; hudui = false -> isHidden = false
    -- hud = false; hudui = true -> isHidden = false
    -- hud = false; hudui = false -> isHidden = false
    local internalHudSceneState = true
    local internalHudUiSceneState = true
    local internalHudHiddenState = true

    --[[
	POC_CurrentHudHiddenState Gets the hidden state of hud/hudui
    ]]--
    function POC_CurrentHudHiddenState()
	return internalHudHiddenState
    end

    --[[
	UpdateHiddenState updates the hidden state on base of hud/hudui state
    ]]--
    local function UpdateHiddenState()
		local isHidden = internalHudSceneState and internalHudUiSceneState

	if (isHidden ~= internalHudHiddenState) then
	    internalHudHiddenState = isHidden
	    CALLBACK_MANAGER:FireCallbacks(POC_HUD_HIDDEN_STATE_CHANGED, isHidden)
	end
    end

    --[[
	HudSceneOnStateChange callback of hud OnStateChange
    ]]--
    local function HudSceneOnStateChange(oldState, newState)
	if (newState == SCENE_HIDING) then
	    internalHudSceneState = true
			-- make call async to catch both state changes before changing visibility
			zo_callLater(UpdateHiddenState, 1)
	elseif (newState == SCENE_SHOWING) then
	    internalHudSceneState = false
			-- make call async to catch both state changes before changing visibility
			zo_callLater(UpdateHiddenState, 1)
	end
    end

    --[[
	HudUiSceneOnStateChange callback of hudui OnStateChange
    ]]--
    local function HudUiSceneOnStateChange(oldState, newState)
		if (newState == SCENE_HIDING) then
	    internalHudUiSceneState = true
			-- make call async to catch both state changes before changing visibility
			zo_callLater(UpdateHiddenState, 1)
	elseif (newState == SCENE_SHOWING) then
	    internalHudUiSceneState = false
			-- make call async to catch both state changes before changing visibility
			zo_callLater(UpdateHiddenState, 1)
	end
    end

    --[[
	Register callbacks to scenes
    ]]--
     -- Reticle Scene
    SCENE_MANAGER:GetScene("hud"):RegisterCallback("StateChange", HudSceneOnStateChange)
     -- Mouse Scene
    SCENE_MANAGER:GetScene("hudui"):RegisterCallback("StateChange", HudUiSceneOnStateChange)

end
