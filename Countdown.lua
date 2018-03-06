setfenv(1, POC)
Countdown = {
    Name = "POC-Countdown"
}

Countdown.__index = Countdown

local counting

local first = 1

local nnn
local saved
local xxx

function init()
    nnn = CountdownNumber
    nnnlabel = CountdownNumberLabel
    saved = Settings.SavedVariables
    xxx = xxx

    nnn:ClearAnchors()
    if (saved.CountdownNumberPos == nil) then
	nnn:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	nnn:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.CountdownNumberPos[1],
				saved.CountdownNumberPos[2])
    end
    nnn:SetMovable(true)
    nnn:SetMouseEnabled(true)
    nnn:SetHidden(false)
    nnnlabel:SetFont("EsoUI/Common/Fonts/univers67.otf|200|soft-shadow-thin")
    nnnlabel:SetScale(2.0)
end
local function go()
    if first then
	init()
    end
    EVENT_MANAGER:UnregisterForUpdate('Countdown', go)
    local sound
    if counting == 0 then
	color = "00ff00"
	text = "Go!"
	sound = SOUNDS.DEATH_RECAP_KILLING_BLOW_SHOWN
    elseif counting == 1 then
	color = "ffff00"
	text = tostring(counting)
	sound = SOUNDS.LOCKPICKING_START
    elseif counting > 1 then
	color = "ff0000"
	text = tostring(counting)
	sound = SOUNDS.LOCKPICKING_START
    elseif counting < 0 then
	counting = 0
	nnnlabel:SetText("")
	nnnlabel:SetHidden(true)
	return
    end
    d("|c" .. color .. text .. "|r")
    PlaySound(sound)
    nnnlabel:SetText("|c" .. color .. text .. "|r")
    nnnlabel:SetHidden(false)

    counting = counting - 1

    EVENT_MANAGER:RegisterForUpdate('Countdown', 1000, go)
end

function Countdown.Start(n)
    counting = n
    go()
end

function Countdown.SavePos(self)
    saved.CountdownNumberPos = {self:GetLeft(),self:GetTop()}
end

SLASH_COMMANDS["/pocn"] = function(x)
    Comm.Send(COMM_TYPE_COUNTDOWN, tonumber(x))
end
ZO_CreateStringId("SI_BINDING_NAME_COUNTDOWN_KEY", "Send three second countdown")
