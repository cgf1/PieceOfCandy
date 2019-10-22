setfenv(1, POC)
Countdown = {
    Name = "POC-Countdown"
}

Countdown.__index = Countdown

local counting

local first = 1

local nnn

local function init()
    nnn = POC_Countdown
    nnnlabel = POC_CountdownLabel

    saved = Settings.SavedVariables	-- convenience

    nnn:ClearAnchors()
    if (saved.CountdownPos == nil) then
	nnn:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	nnn:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.CountdownPos[1],
				saved.CountdownPos[2])
    end
    nnn:SetMovable(true)
    nnn:SetMouseEnabled(true)
    nnn:SetHidden(false)
    nnnlabel:SetFont("EsoUI/Common/Fonts/univers67.otf|200|soft-shadow-thin")
    nnnlabel:SetScale(2.0)
    init = function() end
end

local function go()
    init()
    EVENT_MANAGER:UnregisterForUpdate(Countdown.Name, go)
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
    EVENT_MANAGER:RegisterForUpdate(Countdown.Name, 1000, go)
end

function Countdown.Start(n)
    counting = n
    go()
end

function Countdown.SavePos(self)
    saved.CountdownPos = {self:GetLeft(),self:GetTop()}
end

Slash("n", "send a countdown of n seconds (specified) to group", function(x)
    Comm.Send(COMM_TYPE_COUNTDOWN, {tonumber(x)})
end)
ZO_CreateStringId("SI_BINDING_NAME_POC_COUNTDOWN_KEY", "Send three second countdown")
