setfenv(1, POC)

local GetCampaignName = GetCampaignName
local saved

Campaign = {
    Name = 'POC-Campaign',
    GroupPos = 0,
    Pos = 0,
}
Campaign.__index = Campaign

local function joined(_, n, isgroup)
    watch("joined", n, isgroup, GetCampaignName(n))
    if isgroup then
	Campaign.GroupPos = GetCampaignQueuePosition(n, true)
    else
	Campaign.Pos = GetCampaignQueuePosition(n, false)
    end
end

local function left(_, n, isgroup)
    watch("left", n, isgroup)
    Campaign.GroupPos = 0
    Campaign.Pos = 0
end

local function changed(_, n, isgroup, pos)
    watch("changed", n, isgroup, pos)
    if isgroup then
	Campaign.GroupPos = pos
    else
	Campaign.Pos = pos
    end
end

local function state_changed(_, n, isgroup, state)
    watch("state_changed", n, isgroup, state, CAMPAIGN_QUEUE_REQUEST_STATE_FINISHED)
    if isgroup then
	Campaign.GroupPos = GetCampaignQueuePosition(n, true)
    else
	Campaign.Pos = GetCampaignQueuePosition(n, false)
    end
end

function Campaign.Initialize()
    saved = Settings.SavedVariables

    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_JOINED, joined)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_LEFT, left)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, changed)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, state_changed)
    Slash("queue", "debugging: specify pretend queue position", function (n)
	if n:len() ~= 0 then
	    Campaign.Pos = tonumber(n)
	end
	Info('Queue: ', Campaign.Pos)
    end)
    Slash("gqueue", "debugging: specify pretend group queue position", function (n)
	if n:len() ~= 0 then
	    Campaign.GroupPos = tonumber(n)
	end
	Info('Group queue: ', Campaign.GroupPos)
    end)
end
