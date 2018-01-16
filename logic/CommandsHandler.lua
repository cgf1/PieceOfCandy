--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table TGU_CommandsHandler
]]--
TGU_CommandsHandler = {}
TGU_CommandsHandler.__index = TGU_CommandsHandler

--[[
	Table Members
]]--
TGU_CommandsHandler.Name = "TGU-CommandsHandler"

--[[
	Called on /setgroupultimatestyle command
]]--
function TGU_CommandsHandler.SetGroupUltimateStyleCommand(style)
	if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CommandsHandler.SetGroupUltimateStyleCommand")
        _logger:logDebug("style", style)
    end

    if (style ~= nil and style ~= "") then
        TGU_SettingsHandler.SetStyleSettings(style)
    else
        d("Invalid style: " .. tostring(style))
    end
end

--[[
	Called on /setultimateid command
]]--
function TGU_CommandsHandler.SetUltimateIdCommand(groupName)
	if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CommandsHandler.SetUltimateId")
        _logger:logDebug("groupName", groupName)
    end

    if (groupName ~= nil and groupName ~= "") then
        local ultimateGroup = TGU_UltimateGroupHandler.GetUltimateGroupByGroupName(groupName)

        if (ultimateGroup ~= nil) then
            TGU_SettingsHandler.SetStaticUltimateIDSettings(ultimateGroup.GroupAbilityId)
        else
            d("Invalid group name: " .. tostring(groupName))
        end
    else
        d("Invalid group name: " .. tostring(groupName))
    end
end

--[[
	Called on /setswimlaneid command
]]--
function TGU_CommandsHandler.SetSwimlaneIdCommand(option)
	if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_CommandsHandler.SetSwimlaneId")
        _logger:logDebug("option", option)
    end

    -- Parse options
    local options = {}
    local arrayLength = 0
    local searchResult = { string.match(option,"^(%S*)%s*(.-)$") }
    for i, v in pairs(searchResult) do
        if (v ~= nil and v ~= "") then
            options[i] = string.lower(v)
            arrayLength = i
        end
    end

    if (arrayLength == 2) then
        local swimlane = tonumber(options[1])
        local swimlaneGroup = options[2]
        local ultimateGroup = TGU_UltimateGroupHandler.GetUltimateGroupByGroupName(swimlaneGroup)

        if (swimlane ~= nil and ultimateGroup ~= nil and swimlane >= 1 and swimlane <= 6) then
            TGU_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlane, ultimateGroup)
        else
            d("Invalid options: " .. tostring(option))
        end
    else
        d("Invalid options: " .. tostring(option))
    end
end

--[[
	Called on /getultimategroups command
]]--
function TGU_CommandsHandler.GetUltimateGroupsCommand()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_CommandsHandler.GetUltimateGroupsCommand") end

    local ultimateGroups = TGU_UltimateGroupHandler.GetUltimateGroups()

    d("Ultimate Groups:")

    for i, group in pairs(ultimateGroups) do
        d(group.GroupName .. " - " .. group.GroupDescription)
    end
end

--[[
	Initialize initializes TGU_CommandsHandler
]]--
function TGU_CommandsHandler.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_CommandsHandler.Initialize")
        logger:logDebug("Commands active:")
        logger:logDebug("/setgroupultimatestyle <STYLEID> - Sets the style (0 = SimpleList, 1 = SwimlaneList).")
        logger:logDebug("/setultimateid <GROUPNAME> - Sets the static ultimate group; See /getultimategroups to get group names.")
        logger:logDebug("/setswimlaneid <SWIMLANE> <GROUPNAME> - Sets the ultimate group of swimlane (1-6); See /getultimategroups to get group name.")
        logger:logDebug("/getultimategroups - Gets all ultimate group names")
    end

    _logger = logger

    -- Define commands
    SLASH_COMMANDS["/setgroupultimatestyle"] = TGU_CommandsHandler.SetGroupUltimateStyleCommand
    SLASH_COMMANDS["/setultimateid"] = TGU_CommandsHandler.SetUltimateIdCommand
    SLASH_COMMANDS["/setswimlaneid"] = TGU_CommandsHandler.SetSwimlaneIdCommand
    SLASH_COMMANDS["/getultimategroups"] = TGU_CommandsHandler.GetUltimateGroupsCommand
end
