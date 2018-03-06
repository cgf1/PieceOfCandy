setfenv(1, POC)
Group = {
    Name = "POC-Group"
}
Group.__index = Group

-- Called when group member joined group
--
function Group.OnGroupMemberJoined(x, member)
    Swimlanes.Update("joined")
end

-- Called when group member left group
--
function Group.OnGroupMemberLeft(x, member)
    Swimlanes.Update("left")
end

-- Called when groupUnitTags updated
--
function Group.OnGroupUpdate(x, hmm)
    Swimlanes.Update("group update")
end

function Group.IsGrouped()
    return IsUnitGrouped("player")
end

-- Called on ???
--
function Group.OnUnitFrameUpdate()
    Swimlanes.Update("frame update")
end

-- Initialize Group
--
function Group.Initialize()
    -- Initial call
    Group:OnGroupUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_JOINED, Group.OnGroupMemberJoined)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_LEFT, Group.OnGroupMemberLeft)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_UPDATE, Group.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, Group.OnGroupUpdate)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_UNIT_FRAME_UPDATE, Group.OnUnitFrameUpdate)
end
