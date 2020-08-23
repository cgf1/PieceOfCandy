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

local function pretty()
    return string.gsub(" " .. (saved.Campaign.Name or "(unknown)"), "%W%l", string.upper):sub(2)
end

function Campaign.QueuePosition(isgroup)
    local pos = GetCampaignQueuePosition(campaign_id, isgroup)
    watch("Campaign.QueuePosition", campaign_id, isgroup, pos)
    return pos
end

local function joined(_, id, isgroup)
    watch("joined", id, isgroup)
    if saved.RelaxedCampaignAccept or id == campaign_id then
	local s
	if isgroup then
	    s = 'group '
	else
	    s = ''
	end
	Info(string.format("%squeued for campaign %s", s, pretty()))
	if saved.AcceptPVP and isgroup and not IsUnitGroupLeader("player") and GetCampaignQueuePosition(id, isgroup) == 0 then
	    watch("joined", "delayed start")
	    zo_callLater(function () ConfirmCampaignEntry(id, isgroup, true) end, 3000)
	end
    end
end

local function initialized(_, id)
    watch("initialized", id)
end

local function response(_, resp)
    watch("response", resp)
end

local function left(_, id, isgroup)
    watch("left", id, isgroup)
end

local function pos_changed(_, id, isgroup, pos)
    watch("pos_changed", id, isgroup, pos)
end

local function state_changed(_, id, isgroup, state)
    watch("state_changed", id, isgroup, state, id == campaign_id, state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING, saved.RelaxedCampaignAccept)
    if saved.AcceptPVP and state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING and (saved.RelaxedCampaignAccept or id == campaign_id) then
	ConfirmCampaignEntry(id, isgroup, true)
    end
end

local function clearernow()
    -- maybe
end

local function get_campaign_id(name)
    -- don't really know why this is necessary
    if GetNumSelectionCampaigns() == 0 and saved.KnownCampaigns and saved.KnownCampaigns[name] then
	campaign_id = saved.KnownCampaigns[name]
	return campaign_id
    end
    if GetNumSelectionCampaigns() ~= 0 then
	saved.KnownCampaigns = {}
    end
    -- the below two assignments seem to initialize the campaign list
    for i = 1, GetNumSelectionCampaigns() do
	local id = GetSelectionCampaignId(i)
	if id and id ~= 0 then
	    local thisname = GetCampaignName(id):lower()
	    saved.KnownCampaigns[thisname] = id
	    if GetCampaignName(id):lower() == name then
		return id
	    end
	end
    end
    return GetAssignedCampaignId()
end

function curcampaign()
end

function Campaign.Initialize(_saved)
    saved = _saved

    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_JOINED, joined)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_LEFT, left)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, pos_changed)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, state_changed)
    Slash("campaign", 'specify desired PVP campaign (e.g. "kaalgrontiid")', function(n)
	if n:len() ~= 0 then
	    local newcampaign_id = get_campaign_id(n:lower())
	    if not newcampaign_id then
		Error(string.format("unknown campaign: %s", n))
		return
	    else
		saved.Campaign.Name = n:lower()
		campaign_id = newcampaign_id
	    end
	end
	local id
	if campaign_id then
	    id = "(" .. tostring(campaign_id) .. ")"
	else
	    id = "(unknown)"
	end
	Info("Preferred campaign: ", pretty(), id)
    end)
    Slash("queue", "show position in queue", function ()
	local s
	if isgroup then
	    s = 'Group queue: '
	else
	    s = 'Queue: '
	end
	local pos = Campaign.QueuePosition(false)
	local gpos = Campaign.QueuePosition(true)
	watch("queue", "isgroup", 'group', gpos, 'pos', pos)
	if pos ~= 0 then
	    Info(string.format("solo queue for %s: %d", pretty(), pos))
	end
	if gpos ~= 0 then
	    Info(string.format("group queue for %s: %d", pretty(), gpos))
	end
    end)
    Slash("pvp", "queue for your preferred PVP campaign (e.g., 'Vivec')", function(x)
	local what
	if x:lower() == 'group' then
	    what = 'group '
	else
	    what = ''
	end

	campaign_id = get_campaign_id(saved.Campaign.Name)
	if not campaign_id then
	    Error(string.format("don't know how to queue for campaign %s", pretty()))
	elseif what ~= '' and not IsUnitGroupLeader("player") then
	    Error("you're not the group leader")
	elseif x == 'leave' then
	    LeaveCampaignQueue(campaign_id, false)
	    Info(string.format("left campaign queue for %s", pretty()))
	else
	    QueueForCampaign(campaign_id, what:len() > 0)
	    saved.Campaign.Name = GetCampaignName(campaign_id):lower()
	    Info(string.format("%squeuing for campaign %s", what, pretty()))
	end
    end)
    RegClear(clearernow)
end

