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

local debug_pos = {
    [true] = nil,
    [false] = nil
}

local function pretty()
    return string.gsub(" " .. saved.Campaign.Name, "%W%l", string.upper):sub(2)
end

function Campaign.QueuePosition(isgroup)
    if debug_pos[isgroup] ~= nil then
	return debug_pos[isgroup]
    end
    return GetCampaignQueuePosition(saved.Campaign[isgroup], isgroup)
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
   debug_pos = {} 
end

local function get_campaign_id(name)
    for i = 1, GetNumSelectionCampaigns() do
	local id = GetSelectionCampaignId(i)
	if GetCampaignName(id):lower() == name then
	    campaign_id = id
	    return
	end
    end
    campaign_id = nil
end

function Campaign.Initialize()
    saved = Settings.SavedVariables

    if saved.Campaign == nil then
	saved.Campaign = {
	    Name = 'vivec'
	}
    end
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
    Slash("queue", "debugging: specify pretend queue position, extra arg means group", function (n)
	local n, isgroup = n:match("(%S*)%s*(%S*)")
	local i
	isgroup = isgroup:len() > 0
	if n:len() ~= 0 then
	    if n == 'nil' or n == 'off' then
		debug_pos[isgroup] = nil
	    else
		debug_pos[isgroup]= tonumber(n)
	    end
	end
	local s
	if isgroup then
	    s = 'Group queue: '
	else
	    s = 'Queue: '
	end
	Info(s, Campaign.QueuePosition(isgroup))
    end)
    Slash("pvp", "queue for your preferred PVP campaign (e.g., 'Vivec')", function()
	if not campaign_id then
	    Error(string.format("don't know how to queue for campaign %s", pretty()))
	else
	    QueueForCampaign(campaign_id)
	    Info(string.format("queuing for campaign %s", pretty()))
	end
    end)
    RegClear(clearernow)
end
