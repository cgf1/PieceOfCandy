setfenv(1, POC)
GroupHandler = {
    Name = "GroupHandler"
}
GroupHandler.__index = GroupHandler

-- Called when group member joined group
--
function GroupHandler.OnGroupMemberJoined(x, member)
    Swimlanes.Update("joined")
end

-- Called when group member left group
--
function GroupHandler.OnGroupMemberLeft(x, member)
    Swimlanes.Update("left")
end

-- Called when groupUnitTags updated
--
function GroupHandler.OnGroupUpdate(x, hmm)
    Swimlanes.Update("group update")
end

function GroupHandler.IsGrouped()
    return IsUnitGrouped("player")
end

-- Called on ???
--
function GroupHandler.OnUnitFrameUpdate()
    Swimlanes.Update("frame update")
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
