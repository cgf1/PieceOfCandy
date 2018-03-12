setfenv(1, POC)
Alert = {
    Name = ALERT
}
Alert.__index = Alert

local controls = {}

local screenx, screeny

local ix = 0
local MAX = 24

function Alert.Show(text, duration)
    ix = ix + 1
    if ix > MAX then
	ix = 1
    end
    local control = controls[ix]
    control:SetAnchor(CENTER, nil, CENTER, 0, yloc)
    control:SetHidden(false)
--    control:SetText("|c66ff66" .. text)
    control:SetText("|cffa500" .. text)

    local _, _, _, _, offx, offy = control:GetAnchor()
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local translate = timeline:InsertAnimation(ANIMATION_TRANSLATE, control)
    local xto
    xto = screenx / 2
    if (ix % 2) == 0 then
	xto = -xto
    end

    translate:SetTranslateOffsets(offx, offy, xto, -(screeny / 2))
    translate:SetDuration(duration)
    translate:SetEasingFunction(ZO_EaseInQuadratic)
    local fadeout = timeline:InsertAnimation(ANIMATION_ALPHA, control)
    fadeout:SetAlphaValues(1, 0)
    fadeout:SetDuration(duration + 1000)
    timeline:PlayFromStart()
end

function Alert.Initialize()
    CALLBACK_MANAGER:RegisterCallback(Alert.Name, ALERT, Alert.Show)
    local above = MAX / 2
    local wm = GetWindowManager()
    local height = 50
    local font = "$(HANDWRITTEN_FONT)|" .. tostring(height)
    local frame = wm:CreateTopLevelWindow()
    screenx, screeny = GuiRoot:GetDimensions()
    frame:SetDimensions(screenx, screeny)
    frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)
    for i = 1, MAX do
	control = wm:CreateControl(nil, frame, CT_LABEL)
	control:SetFont(font)
	local yloc = (i - above) * (1.5 * height)
	control:SetDrawLayer(1)
	control:SetMouseEnabled(false)
	control:SetHidden(true)
	controls[i] = control
    end
    SLASH_COMMANDS["/pocalert"] = Show
end
