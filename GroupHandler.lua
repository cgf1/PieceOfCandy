setfenv(1, POC)
GroupHandler = {
    Name = "GroupHandler"
}
GroupHandler.__index = GroupHandler

-- Called when group member joined group
--
function GroupHandler.OnGroupMemberJoined(x, member)
    CALLBACK_MANAGER:FireCallbacks(GROUP_CHANGED, member, "joined")
end

-- Called when group member left group
--
function GroupHandler.OnGroupMemberLeft(x, member)
    CALLBACK_MANAGER:FireCallbacks(GROUP_CHANGED, member, "left")
end

-- Called when groupUnitTags updated
--
function GroupHandler.OnGroupUpdate(x, hmm)
    CALLBACK_MANAGER:FireCallbacks(GROUP_CHANGED, hmm, "update")
    CALLBACK_MANAGER:FireCallbacks(UNIT_GROUPED_CHANGED)
end

function GroupHandler.IsGrouped()
    return IsUnitGrouped("player")
end

-- Called on ???
--
function GroupHandler.OnUnitFrameUpdate()
    CALLBACK_MANAGER:FireCallbacks(GROUP_CHANGED, "frame update")
end

-- Initialize GroupHandler
--
function GroupHandler.Initialize()
    -- Initial call
    GroupHandler:OnGroupUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(GroupHandler.Name, EVENT_GROUP_MEMBER_JOINED, GroupHandler.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(GroupHandler.Name, EVENT_GROUP_MEMBER_LEFT, GroupHandler.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(GroupHandler.Name, EVENT_GROUP_UPDATE, GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(GroupHandler.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, GroupHandler.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(GroupHandler.Name, EVENT_UNIT_FRAME_UPDATE, GroupHandler.OnUnitFrameUpdate)
end
