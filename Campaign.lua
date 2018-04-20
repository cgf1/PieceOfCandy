setfenv(1, POC)

local GetCampaignName = GetCampaignName
local QueueForCampaign = QueueForCampaign
local saved

Campaign = {
    Name = 'POC-Campaign'
}
Campaign.__index = Campaign

local campaign = Campaign
local campaign_id
local campaign_index

local function pretty()
    return string.gsub(" " .. saved.Campaign.Name, "%W%l", string.upper):sub(2)
end

function Campaign.QueuePosition(isgroup)
    local pos = GetCampaignQueuePosition(campaign_id, isgroup)
    watch("Campaign.QueuePosition", saved.Campaign[isgroup], isgroup, pos)
    return pos
end

local function joined(_, n, isgroup)
    local name = GetCampaignName(n)
    watch("joined", n, isgroup, name)
    if name:lower() == saved.Campaign.Name then
	saved.Campaign[isgroup] = n
	local s
	if isgroup then
	    s = 'group '
	else
	    s = ''
	end
	Info(string.format("%squeued for campaign %s", s, pretty()))
    end
end

local function left(_, n, isgroup)
    watch("left", n, isgroup)
    saved.Campaign[isgroup] = 0
end

local function changed(_, n, isgroup, pos)
    watch("changed", n, isgroup, pos)
end

local function state_changed(_, n, isgroup, state)
    watch("state_changed", n, isgroup, state, CAMPAIGN_QUEUE_REQUEST_STATE_FINISHED)
end

local function clearernow()
    -- maybe
end

local function get_campaign_id(name)
    for i = 1, GetNumSelectionCampaigns() do
	local id = GetSelectionCampaignId(i)
	if GetCampaignName(id):lower() == name then
	    campaign_id = id
	    campaign_index = i
	    return
	end
    end
    campaign_id = nil
    campaign_index = nil
end

function Campaign.Initialize()
    saved = Settings.SavedVariables

    if saved.Campaign == nil then
	saved.Campaign = {
	    Name = 'vivec'
	}
    end
    saved.Campaign = {Name = saved.Campaign.Name}
    get_campaign_id(saved.Campaign.Name)

    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_JOINED, joined)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_LEFT, left)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, changed)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, state_changed)
    Slash("campaign", 'specify desired PVP campaign (e.g. "vivec")', function(n)
	if n:len() ~= 0 then
	    n = n:lower()
	    saved.Campaign.Name = n
	    get_campaign_id(n)
	end
	local id
	if campaign_id then
	    id = "(" .. tostring(campaign_id) .. ")"
	else
	    id = "(unknown)"
	end
	Info("Preferred campaign: ", pretty(), id)
    end)
    Slash("queue", "show position in queue (any argument means show group queue)", function (n)
	isgroup = n:len() > 0
	local s
	if isgroup then
	    s = 'Group queue: '
	else
	    s = 'Queue: '
	end
	local pos = Campaign.QueuePosition(isgroup)
	watch("queue", "isgroup", isgroup, '=', pos)
	if pos ~= 0 then
	    Info(string.format("%s for %s: %d", s, pretty(), pos))
	end
	local wait = GetSelectionCampaignQueueWaitTime(campaign_index)
	local seconds = wait % 60
	wait = math.floor(wait / 60)
	local minutes = wait % 60
	wait = math.floor(wait / 60)
	Info(string.format("game says estimated wait time for %s is %02d:%02d:%02d", pretty(), wait, minutes, seconds))
    end)
    Slash("pvp", "queue for your preferred PVP campaign (e.g., 'Vivec')", function()
	if not campaign_id then
	    get_campaign_id(saved.Campaign.Name)
	end
	if not campaign_id then
	    Error(string.format("don't know how to queue for campaign %s", pretty()))
	else
	    QueueForCampaign(campaign_id)
	    Info(string.format("queuing for campaign %s", pretty()))
	end
    end)
    RegClear(clearernow)
end
