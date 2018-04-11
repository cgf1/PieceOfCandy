setfenv(1, POC)
local GetTimeStamp = GetTimeStamp
local ZO_EaseInQuadratic = ZO_EaseInQuadratic

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
local pool
local frame
local font

local function create()
    local this = {}
    local control = WM:CreateControl(nil, frame, CT_LABEL)
    control:SetFont(font)
    control:SetDrawLayer(1)
    control:SetMouseEnabled(false)
    control:SetHidden(true)
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local fadeout = timeline:InsertAnimation(ANIMATION_ALPHA, control)
    local translate = timeline:InsertAnimation(ANIMATION_TRANSLATE, control)
    this.Control = control
    this.Fadeout = fadeout
    this.Timeline = timeline
    this.Translate = translate
    return this
end

local function reset(this)
    -- nothing to do really
end

function Alert.Show(text, duration)
    if (GetTimeStamp() - last_alert) >= 10 then
	ix = MAX / 2
    else
	ix = ix + 1
	if ix > MAX then
	    ix = 1
	end
    end
    local this, key = pool:AcquireObject()
    local control = this.Control
    local fadeout = this.Fadeout
    local timeline = this.Timeline
    local translate = this.Translate
    if this.Func == nil then
	this.Func = function () pool:ReleaseObject(key) end
    end
    local yloc = (fontsize * .60) * (ix - above)
    control:SetAnchor(CENTER, nil, CENTER, 0, yloc)
    control:SetHidden(false)
    control:SetText(string.format("|cff6600%s", text))

    local _, _, _, _, offx, offy = control:GetAnchor()
    local xto = screenx / 2
    if (ix % 2) == 0 then
	xto = -xto
    end

    translate:SetTranslateOffsets(offx, offy, xto, -(screeny / 2))
    translate:SetDuration(duration)
    translate:SetEasingFunction(ZO_EaseInQuadratic)
    fadeout:SetAlphaValues(1, 0)
    fadeout:SetDuration(duration + 1000)
    timeline:InsertCallback(this.Func, timeline:GetDuration())
    timeline:PlayFromStart()
    last_alert = GetTimeStamp()
end

local function clearernow()
    last_alert = 0
    pool:ReleaseAllObjects()
end

function Alert.Initialize()
    CALLBACK_MANAGER:RegisterCallback(Alert.Name, ALERT, Alert.Show)
    frame = WM:CreateTopLevelWindow()
    font = "$(HANDWRITTEN_FONT)|" .. tostring(fontsize)
    screenx, screeny = GuiRoot:GetDimensions()
    midscreen = screeny / 2
    frame:SetDimensions(screenx, screeny)
    frame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)
    pool = ZO_ObjectPool:New(create, reset)
    RegClear(clearernow)
end
