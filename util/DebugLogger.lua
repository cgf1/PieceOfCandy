--[[
	Class definition
]]--
-- A table in hole lua workspace must be unique
-- The debug logger is global util table, used in several of my addons
if (POCDebugLogger == nil) then
	POCDebugLogger = {}
	POCDebugLogger.__index = POCDebugLogger

	setmetatable(POCDebugLogger, {
		__call = function (cls, ...)
			return cls.new(...)
		end,
	})

	--[[
		Class constructor
	]]--
	function POCDebugLogger.new(name, logCommand, traceActive, debugActive, errorActive, directPrint, catchLuaErrors)
		local self = setmetatable({}, POCDebugLogger)
		
		-- class members
		self.name = name
		self.logCommand = logCommand
		self.buffer = {}
		
		self.TRACE_ACTIVE = traceActive
		self.DEBUG_ACTIVE = debugActive
		self.ERROR_ACTIVE = errorActive
		self.DIRECT_PRINT = directPrint
		self.CATCH_LUA_ERRORS = catchLuaErrors

		SLASH_COMMANDS[self.logCommand] = self:CommandShowLogs()
		EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function(eventCode) self:OnPlayerActivated(eventCode) end)
		EVENT_MANAGER:RegisterForEvent(self.name, EVENT_LUA_ERROR, function(eventCode, errorOutput) self:OnLuaError(eventCode, errorOutput) end)
		
		return self
	end

	--[[
		Trace
	]]--
	function POCDebugLogger:logTrace(functionName)
		if (self.TRACE_ACTIVE == false) then return end

		local formatMessage = "[%s - TRACE] %s"
		self:logMessage(formatMessage:format(GetTimeString(), functionName))
	end

	--[[
		Debug
	]]--
	function POCDebugLogger:logDebug(...)
		if (self.DEBUG_ACTIVE == false) then return end

		local formatMessage = "[%s - DEBUG] %s"
		local msg = ""
		
		for i = 1, select("#", ...) do
			if (i == 1) then
				msg = tostring(select(i, ...))
			else
				msg = msg .. "; " .. tostring(select(i, ...))
			end
		end
		
		self:logMessage(formatMessage:format(GetTimeString(), msg))
	end

	--[[
		Error
	]]--
	function POCDebugLogger:logError(...)
		if (self.ERROR_ACTIVE == false) then return end

		local formatMessage = "[%s - ERROR] %s"
		local msg = ""
		
		for i = 1, select("#", ...) do
			if (i == 1) then
				msg = tostring(select(i, ...))
			else
				msg = msg .. "; " .. tostring(select(i, ...))
			end
		end
		
		self:logMessage(formatMessage:format(GetTimeString(), msg))
	end

	--[[
		Log
	]]--
	function POCDebugLogger:logMessage(msg)
		self:AddMessage(msg)

		if (self.DIRECT_PRINT) then
			d(msg)
		end
	end

	--[[
		Adds messages to buffer
	]]--
	function POCDebugLogger:AddMessage(msg)
		if(not msg or self.buffer == nil) then return end

		local buf = self.buffer
		buf[#buf + 1] = msg
	end

	--[[
		Print buffered messages
	]]--
	function POCDebugLogger:PrintMessages()
		if(self.buffer == nil) then return end
		
		for i,msg in ipairs(self.buffer) do
			d(msg)
		end
	end

	--[[
		Prints buffered outputs
	]]--
	function POCDebugLogger:OnPlayerActivated(eventCode) 
		self:PrintMessages()

		EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_ACTIVATED)
	end

	--[[
		Catches lua errors
	]]--
	function POCDebugLogger:OnLuaError(eventCode, errorOutput)
		if (self.CATCH_LUA_ERRORS == false) then return end
		
		self:logMessage(errorOutput)
		ZO_UIErrors_HideCurrent()
	end

	--[[
		Handles /tapslogs command
	]]--
	function POCDebugLogger:CommandShowLogs()
		self:PrintMessages()
	end
end
