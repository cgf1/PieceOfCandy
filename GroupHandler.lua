--[[
	Table POC_GroupHandler
]]--
POC_GroupHandler = {}
POC_GroupHandler.__index = POC_GroupHandler

--[[
	Table Members
]]--
POC_GroupHandler.Name = "POC-GroupHandler"

-- Called when group member joined group
--
function POC_GroupHandler.OnGroupMemberJoined(x, member)
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, member, "joined")
end

-- Called when group member left group
--
function POC_GroupHandler.OnGroupMemberLeft(x, member)
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, member, "left")
end

-- Called when groupUnitTags updated
--
function POC_GroupHandler.OnGroupUpdate(x, hmm)
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, hmm, "update")
    CALLBACK_MANAGER:FireCallbacks(POC_UNIT_GROUPED_CHANGED)
end

function POC_GroupHandler.IsGrouped()
    return IsUnitGrouped("player")
end

-- Called on ???
--
function POC_GroupHandler.OnUnitFrameUpdate()
    CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, "frame update")
end

-- Initialize POC_GroupHandler
--
function POC_GroupHandler.Initialize()
    -- Initial call
    POC_GroupHandler:OnGroupUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_JOINED, POC_GroupHandler.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_LEFT, POC_GroupHandler.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_UPDATE, POC_GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, POC_GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(POC_GroupHandler.Name, EVENT_UNIT_FRAME_UPDATE, POC_GroupHandler.OnUnitFrameUpdate)
end
