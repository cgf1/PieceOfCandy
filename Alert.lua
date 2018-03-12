setfenv(1, POC)
Alert = {
    Name = ALERT
}
Alert.__index = Alert

local controls = {}

local screenx, screeny

local ix = 12
local MAX = 24
local fontsize = 50
local midscreen
local above = MAX / 2

function Alert.Show(text, duration)
    ix = ix + 1
    if ix > MAX then
	ix = 1
    end
d(ix)
    local control = controls[ix]
    local yloc = (height / 3) * (ix - above)
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
    local wm = GetWindowManager()
    local font = "$(HANDWRITTEN_FONT)|" .. tostring(fontsize)
    local frame = wm:CreateTopLevelWindow()
    screenx, screeny = GuiRoot:GetDimensions()
    midscreen = screeny / 2
    frame:SetDimensions(screenx, screeny)
    frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)
    local control
    for i = 1, MAX do
	control = wm:CreateControl(nil, frame, CT_LABEL)
	control:SetFont(font)
	control:SetDrawLayer(1)
	control:SetMouseEnabled(false)
	control:SetHidden(true)
	controls[i] = control
    end
    height = control:GetHeight()
    SLASH_COMMANDS["/ppp"] = Show
end
