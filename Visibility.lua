setfenv(1, POC)
Visibility = {}
Visibility.__index = Player

local SCENE_MANAGER = SCENE_MANAGER
local ZO_SimpleSceneFragment = ZO_SimpleSceneFragment

local frags = {}
local scene_showing
local function widget_should_be_visible()
    if not (Group.IsGrouped() and Comm.IsActive()) then
	return false
    else
	return (not saved.OnlyAva) or IsInCampaign()
    end
end
--
-- Set hidden on control
--
local function show_widget(showit)
    if showit == nil then
	showit = widget_should_be_visible()
    else
	showit = showit and widget_should_be_visible()
    end
    if scene_showing ~= showit then
	scene_showing = showit
	if not showit then
	    for _, f in pairs(frags) do
		SCENE_MANAGER:GetScene("hud"):RemoveFragment(f)
		SCENE_MANAGER:GetScene("hudui"):RemoveFragment(f)
		SCENE_MANAGER:GetScene("siegeBar"):RemoveFragment(f)
	    end
	else
	    for _, f in pairs(frags) do
		SCENE_MANAGER:GetScene("hud"):AddFragment(f)
		SCENE_MANAGER:GetScene("hudui"):AddFragment(f)
		SCENE_MANAGER:GetScene("siegeBar"):AddFragment(f)
	    end
	end
    end
end

function register_widget(widget)
    frags[#frags + 1] = ZO_SimpleSceneFragment:New(widget)
end

function Visibility.Export()
    return register_widget, show_widget
end
