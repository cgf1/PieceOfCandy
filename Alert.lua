setfenv(1, POC)
local GetTimeStamp = GetTimeStamp

Alert = {
    Name = 'POC-Alert'
}
Alert.__index = Alert

local controls = {}
local animations = {}

local screenx, screeny

local MAX = 24
local ix = MAX / 2
local fontsize = 50
local midscreen
local above = MAX / 2
local last_alert = 0

function Alert.Show(text, duration)
    if (GetTimeStamp() - last_alert) >= 10 then
	ix = MAX / 2
    else
	ix = ix + 1
	if ix > MAX then
	    ix = 1
	end
    end
    local this = controls[ix]
    local control = this.Control
    local timeline = this.Timeline
    local fadeout
    local translate
    if timeline then
	fadeout = this.Fadeout
	translate = this.Translate
    else
	timeline = ANIMATION_MANAGER:CreateTimeline()
	fadeout = timeline:InsertAnimation(ANIMATION_ALPHA, control)
	translate = timeline:InsertAnimation(ANIMATION_TRANSLATE, control)
	this.Timeline = timeline
	this.Fadeout = fadeout
	this.Translate = translate
    end
    local yloc = (fontsize * .60) * (ix - above)
    control:SetAnchor(CENTER, nil, CENTER, 0, yloc)
    control:SetHidden(false)
--    control:SetText("|c66ff66" .. text)
--    control:SetText("|cffa500" .. text)
    control:SetText(string.format("|cff6600%s", text))

    local _, _, _, _, offx, offy = control:GetAnchor()
    local xto
    xto = screenx / 2
    if (ix % 2) == 0 then
	xto = -xto
    end

    translate:SetTranslateOffsets(offx, offy, xto, -(screeny / 2))
    translate:SetDuration(duration)
    translate:SetEasingFunction(ZO_EaseInQuadratic)
    fadeout:SetAlphaValues(1, 0)
    fadeout:SetDuration(duration + 1000)
    timeline:PlayFromStart()
    last_alert = GetTimeStamp()
end

local function clearernow()
    last_alert = 0
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
	controls[i] = {Control = control}
    end
    RegClear(clearernow)
end
