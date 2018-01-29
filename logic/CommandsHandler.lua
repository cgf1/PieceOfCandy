--[[
	Table POC_CommandsHandler
]]--
POC_CommandsHandler = {
    Name = "POC-CommandsHandler"
}
POC_CommandsHandler.__index = POC_CommandsHandler


--[[
	Called on /setgroupultimatestyle command
]]--
function POC_CommandsHandler.SetUltStyleCommand(style)
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
    if (groupName ~= nil and groupName ~= "") then
        local ult = POC_Ult.ByName(groupName)

        if (ult ~= nil) then
            POC_Settings.SetStaticUltimateIDSettings(ult.Gid)
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
        local ult = POC_Ult.ByName(swimlaneGroup)

        if (swimlane ~= nil and ult ~= nil and swimlane >= 1 and swimlane <= 6) then
            POC_Settings.SetSwimlaneUltId(swimlane, ult)
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
    local ultimates = POC_Ult.GetUlts()

    d("Ultimate Groups:")

    for i, group in ipairs(ultimate) do
        d(group.Name .. " - " .. group.Desc)
    end
end

--[[
	Initialize initializes POC_CommandsHandler
]]--
function POC_CommandsHandler.Initialize()
    -- Define commands
    SLASH_COMMANDS["/setgroupultimatestyle"] = POC_CommandsHandler.SetUltStyleCommand
    SLASH_COMMANDS["/setultimateid"] = POC_CommandsHandler.SetUltimateIdCommand
    SLASH_COMMANDS["/setswimlaneid"] = POC_CommandsHandler.SetSwimlaneIdCommand
    SLASH_COMMANDS["/getultimategroups"] = POC_CommandsHandler.GetUltsCommand
end
