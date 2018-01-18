--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table POC_GroupHandler
]]--
POC_GroupHandler = {}
POC_GroupHandler.__index = POC_GroupHandler

--[[
	Table Members
]]--
POC_GroupHandler.Name = "TGU-GroupHandler"
POC_GroupHandler.IsMocked = false

--[[
	Called when group member joined group
]]--
function POC_GroupHandler.OnGroupMemberJoined()
    if (LOG_ACTIVE) then _logger:logTrace("POC_GroupHandler.OnGroupMemberJoined") end
	
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED)
end

--[[
	Called when group member left group
]]--
function POC_GroupHandler.OnGroupMemberLeft()
    if (LOG_ACTIVE) then _logger:logTrace("POC_GroupHandler.OnGroupMemberLeft") end
	
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED)
end

--[[
	Called when groupUnitTags updated
]]--
function POC_GroupHandler.OnGroupUpdate()
    if (LOG_ACTIVE) then _logger:logTrace("POC_GroupHandler.OnGroupUpdate") end
	
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED)
    CALLBACK_MANAGER:FireCallbacks(POC_UNIT_GROUPED_CHANGED)
end

function POC_GroupHandler.IsGrouped()
    return POC_GroupHandler.IsMocked or IsUnitGrouped("player")
end

--[[
	Called on ???
]]--
function POC_GroupHandler.OnUnitFrameUpdate()
	if (LOG_ACTIVE) then _logger:logTrace("POC_GroupHandler.OnUnitFrameUpdate") end
	
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED)
end

--[[
	Initialize initializes POC_GroupHandler
]]--
function POC_GroupHandler.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then logger:logTrace("POC_GroupHandler.Initialize") end

    _logger = logger
    
    POC_GroupHandler.IsMocked = isMocked

    -- Initial call
    POC_GroupHandler:OnGroupUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_JOINED, POC_GroupHandler.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_LEFT, POC_GroupHandler.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_UPDATE, POC_GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, POC_GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_UNIT_FRAME_UPDATE, POC_GroupHandler.OnUnitFrameUpdate)
end
