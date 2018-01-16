--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table TGU_GroupHandler
]]--
TGU_GroupHandler = {}
TGU_GroupHandler.__index = TGU_GroupHandler

--[[
	Table Members
]]--
TGU_GroupHandler.Name = "TGU-GroupHandler"
TGU_GroupHandler.IsMocked = false

--[[
	Called when group member joined group
]]--
function TGU_GroupHandler.OnGroupMemberJoined()
	if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupHandler.OnGroupMemberJoined") end
	
    CALLBACK_MANAGER:FireCallbacks(TGU_GROUP_CHANGED)
end

--[[
	Called when group member left group
]]--
function TGU_GroupHandler.OnGroupMemberLeft()
	if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupHandler.OnGroupMemberLeft") end
	
    CALLBACK_MANAGER:FireCallbacks(TGU_GROUP_CHANGED)
end

--[[
	Called when groupUnitTags updated
]]--
function TGU_GroupHandler.OnGroupUpdate()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupHandler.OnGroupUpdate") end
	
    CALLBACK_MANAGER:FireCallbacks(TGU_GROUP_CHANGED)
    CALLBACK_MANAGER:FireCallbacks(TGU_UNIT_GROUPED_CHANGED)
end

function TGU_GroupHandler.IsGrouped()
    return TGU_GroupHandler.IsMocked or IsUnitGrouped("player")
end

--[[
	Called on ???
]]--
function TGU_GroupHandler.OnUnitFrameUpdate()
	if (LOG_ACTIVE) then _logger:logTrace("TGU_GroupHandler.OnUnitFrameUpdate") end
	
    CALLBACK_MANAGER:FireCallbacks(TGU_GROUP_CHANGED)
end

--[[
	Initialize initializes TGU_GroupHandler
]]--
function TGU_GroupHandler.Initialize(logger, isMocked)
    if (LOG_ACTIVE) then logger:logTrace("TGU_GroupHandler.Initialize") end

    _logger = logger
    
    TGU_GroupHandler.IsMocked = isMocked

    -- Initial call
    TGU_GroupHandler:OnGroupUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(TGU_GroupHandler.Name, EVENT_GROUP_MEMBER_JOINED, TGU_GroupHandler.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(TGU_GroupHandler.Name, EVENT_GROUP_MEMBER_LEFT, TGU_GroupHandler.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(TGU_GroupHandler.Name, EVENT_GROUP_UPDATE, TGU_GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(TGU_GroupHandler.Name, EVENT_UNIT_FRAME_UPDATE, TGU_GroupHandler.OnUnitFrameUpdate)
end
