setfenv(1, POC)
local GetTimeStamp = GetTimeStamp
local SOUNDS = SOUNDS
local ZO_EaseInQuadratic = ZO_EaseInQuadratic

Alert = {
    Name = 'POC-Alert'
}
Alert.__index = Alert
local Alert = Alert

local controls = {}
local animations = {}

local screenx, screeny

local MAX = 24
local ix = MAX / 2
local fontsize = 50
local above = MAX / 2
local last_alert = 0
local pool
local tlw
local font

local function create()
    local this = {}
    local control = WM:CreateControl(nil, tlw, CT_LABEL)
    control:SetDrawLayer(1)
    control:SetMouseEnabled(false)
    control:SetHidden(true)
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local fadeout = timeline:InsertAnimation(ANIMATION_ALPHA, control)
    local translate = timeline:InsertAnimation(ANIMATION_TRANSLATE, control)
    translate:SetEasingFunction(ZO_EaseInQuadratic)
    fadeout:SetAlphaValues(1, 0)
    this.Control = control
    this.Fadeout = fadeout
    this.Timeline = timeline
    this.Translate = translate
    return this
end

local function reset(this)
    -- nothing to do really
end

function Alert.NeedsHelp(tag)
    if not saved.NeedsHelp then
	return
    end
    local name = player_name(tag)
    for i = 1, 10 do
       PlaySound(SOUNDS.DUEL_BOUNDARY_WARNING)
    end
    Alert.Show(string.format("%s needs help", name), 5000, true)
end

function Alert.UltFired(tag, aid)
    if not saved.UltAlert then
	return
    end
    local ult = Ult.ByPing(aid)
    local duration = GetAbilityDuration(aid)
    if duration < 10000 then
	duration = 10000
    end
    local name = player_name(tag)
    watch('Alert.UltFired', tag, aid, name)
    local ultname = GetAbilityName(aid)
    local message = string.format("%s's %s", player_name(tag), ultname)
    Alert.Show(message, duration)
end

function Alert.Show(text, total_duration, flash)
    if (GetTimeStamp() - last_alert) > 8 then
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
	this.Func = function (self, n, m)
	    if self:GetPlaybackLoopsRemaining() == 1 then
		control:SetHidden(true)
		self:ClearAllCallbacks()
		pool:ReleaseObject(key)
		watch('alert', 'RELEASED!')
	    end
	end
    end
    local yloc = (fontsize * .60) * (ix - above)
    control:SetAnchor(CENTER, nil, CENTER, 0, yloc)
    control:SetHidden(false)

    local _, _, _, _, offx, offy = control:GetAnchor()
    local ease
    local font
    local atype
    local offset
    local loopcount
    local color
    if	flash then
	ease = ZO_EaseInOutCubic
	atype = ANIMATION_PLAYBACK_PING_PONG
	translate:SetTranslateOffsets(offx, offy, offx, offy)
	timeline:SetPlaybackLoopsRemaining(loopcount)
	loopcount = total_duration / 400
	duration = 400
	offset = loopcount
	font = flash_font
	color = 'ff0000'
    else
	local xto = screenx / 2
	if (ix % 2) == 0 then
	    xto = -xto
	end

	translate:SetTranslateOffsets(offx, offy, xto, -(screeny / 2))
	atype = ANIMATION_PLAYBACK_ONE_SHOT
	loopcount = 1
	duration = total_duration
	offset = duration
	font = alert_font
	color = 'ff6600'
    end
    control:SetFont(font)
    control:SetText(string.format("|c%s%s|r", color, text))
    translate:SetDuration(duration)
    timeline:SetPlaybackType(atype, loopcount)
    fadeout:SetDuration(duration)
    timeline:InsertCallback(this.Func, duration)
    timeline:PlayFromStart()
    last_alert = GetTimeStamp()
end

local function clearernow()
    last_alert = 0
    pool:ReleaseAllObjects()
end

function Alert.Initialize()
    CALLBACK_MANAGER:RegisterCallback(Alert.Name, ALERT, Alert.Show)
    tlw = WM:CreateTopLevelWindow()
    alert_font = "$(HANDWRITTEN_FONT)|" .. tostring(fontsize)
    flash_font = "$(BOLD_FONT)|" .. tostring(fontsize) .. "|soft-shadow-thick"
    screenx, screeny = GuiRoot:GetDimensions()
    tlw:SetDimensions(screenx, screeny)
    tlw:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 0, 0)
    pool = ZO_ObjectPool:New(create, reset)
    ZO_CreateStringId("SI_BINDING_NAME_POC_NEEDHELP_KEY", "Key to notify raid that you need help")
    RegClear(clearernow)
    Slash("fire", "debugging: test ultimate display", function()
	for i = 1, 24 do
	    Alert.Show("Fireworks!", 5000, false)
	end
    end)
end
