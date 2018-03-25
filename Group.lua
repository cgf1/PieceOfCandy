setfenv(1, POC)
Group = {
    Name = "POC-Group"
}
Group.__index = Group

-- Called when group member joined group
--
function Group.OnMemberJoined(x, member)
    Swimlanes.Update("joined")
end

-- Called when group member left group
--
function Group.OnMemberLeft(x, member)
    Swimlanes.Update("left")
end

-- Called when groupUnitTags updated
--
function Group.OnUpdate(x, hmm)
    Swimlanes.Update("group update")
end

function Group.IsGrouped()
    return IsUnitGrouped("player")
end

-- Initialize Group
--
function Group.Initialize()
    -- Initial call
    Group:OnUpdate()

    -- Register events
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_JOINED, Group.OnMemberJoined)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_LEFT, Group.OnMemberLeft)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_UPDATE, Group.OnUpdate)
    EVENT_MANAGER:RegisterForEvent(Group.Name, EVENT_GROUP_MEMBER_ROLES_CHANGED, Group.OnUpdate)
end
