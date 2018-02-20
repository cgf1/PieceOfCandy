POC_Countdown = {
    Name = "POC_Countdown"
}

POC_Countdown.__index = POC_Countdown

local counting

local first = 1

local nnn
local saved
local xxx

function init()
    nnn = POC_CountdownNumber
    nnnlabel = POC_CountdownNumberLabel
    saved = POC_Settings.SavedVariables
    xxx = POC_xxx

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
    EVENT_MANAGER:UnregisterForUpdate('POC_Countdown', go)
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

    EVENT_MANAGER:RegisterForUpdate('POC_Countdown', 1000, go)
end

function POC_Countdown.Start(n)
    counting = n
    go()
end

function POC_Countdown.SavePos(self)
    saved.CountdownNumberPos = {self:GetLeft(),self:GetTop()}
end

SLASH_COMMANDS["/pocn"] = function(x)
    POC_Comm.Send(POC_COMM_TYPE_COUNTDOWN, tonumber(x))
end
ZO_CreateStringId("SI_BINDING_NAME_POC_COUNTDOWN_KEY", "Send three second countdown")
