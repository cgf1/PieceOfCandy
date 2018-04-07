setfenv(1, POC)

local GetCampaignName = GetCampaignName
local saved

Campaign = {
    Name = 'POC-Campaign'
}
Campaign.__index = Campaign

local campaign = Campaign

local debug_pos = {
    [true] = nil,
    [false] = nil
}

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
	Info(string.format("%squeued for %s", s, name))
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

function Campaign.Initialize()
    saved = Settings.SavedVariables

    if saved.Campaign == nil then
	saved.Campaign = {
	    Name = 'vivec'
	}
    end

    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_JOINED, joined)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_LEFT, left)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, changed)
    EVENT_MANAGER:RegisterForEvent(Campaign.Name, EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, state_changed)
    Slash("campaign", 'specify desired PVP campaign (e.g. "vivec")', function(n)
	if n:len() ~= 0 then
	    saved.Campaign.Name = n:lower()
	end
	local pretty = string.gsub(" " .. saved.Campaign.Name, "%W%l", string.upper):sub(2)
	Info("Preferred campaign: ", pretty)
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
    RegClear(clearernow)
end
