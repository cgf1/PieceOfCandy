--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table POC_CommandsHandler
]]--
POC_CommandsHandler = {}
POC_CommandsHandler.__index = POC_CommandsHandler

--[[
	Table Members
]]--
POC_CommandsHandler.Name = "POC-CommandsHandler"

--[[
	Called on /setgroupultimatestyle command
]]--
function POC_CommandsHandler.SetUltStyleCommand(style)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CommandsHandler.SetUltStyleCommand")
        _logger:logDebug("style", style)
    end

    if (style ~= nil and style ~= "") then
        POC_Settings.SetStyleSettings(style)
    else
        d("Invalid style: " .. tostring(style))
    end
end

--[[
	Called on /setultimateid command
]]--
function POC_CommandsHandler.SetUltimateIdCommand(groupName)
	if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CommandsHandler.SetUltimateId")
        _logger:logDebug("groupName", groupName)
    end

    if (groupName ~= nil and groupName ~= "") then
        local ultimateGroup = POC_Ult.GetUltByName(groupName)

        if (ultimateGroup ~= nil) then
            POC_Settings.SetStaticUltimateIDSettings(ultimateGroup.GroupAbilityId)
        else
            d("Invalid group name: " .. tostring(groupName))
        end
    else
        d("Invalid group name: " .. tostring(groupName))
    end
end

-- Called on /setswimlaneid command
-- FIXME: Probably broken
--
function POC_CommandsHandler.SetSwimlaneIdCommand(option)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_CommandsHandler.SetSwimlaneId")
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
        local ultimateGroup = POC_Ult.GetUltByName(swimlaneGroup)

        if (swimlane ~= nil and ultimateGroup ~= nil and swimlane >= 1 and swimlane <= 6) then
            POC_Settings.SetSwimlaneUltIdSettings(swimlane, ultimateGroup)
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
function POC_CommandsHandler.GetUltsCommand()
    if (LOG_ACTIVE) then _logger:logTrace("POC_CommandsHandler.GetUltsCommand") end

    local ultimates = POC_Ult.GetUlts()

    d("Ultimate Groups:")

    for i, group in ipairs(ultimate) do
        d(group.GroupName .. " - " .. group.GroupDescription)
    end
end

--[[
	Initialize initializes POC_CommandsHandler
]]--
function POC_CommandsHandler.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_CommandsHandler.Initialize")
        logger:logDebug("Commands active:")
        logger:logDebug("/setgroupultimatestyle <STYLEID> - Sets the style (0 = SimpleList, 1 = SwimlaneList).")
        logger:logDebug("/setultimateid <GROUPNAME> - Sets the static ultimate group; See /getultimategroups to get group names.")
        logger:logDebug("/setswimlaneid <SWIMLANE> <GROUPNAME> - Sets the ultimate group of swimlane (1-6); See /getultimategroups to get group name.")
        logger:logDebug("/getultimategroups - Gets all ultimate group names")
    end

    _logger = logger

    -- Define commands
    SLASH_COMMANDS["/setgroupultimatestyle"] = POC_CommandsHandler.SetUltStyleCommand
    SLASH_COMMANDS["/setultimateid"] = POC_CommandsHandler.SetUltimateIdCommand
    SLASH_COMMANDS["/setswimlaneid"] = POC_CommandsHandler.SetSwimlaneIdCommand
    SLASH_COMMANDS["/getultimategroups"] = POC_CommandsHandler.GetUltsCommand
end
