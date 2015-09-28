--[[--------------------------------------------------------------------
PhanxAddonStub
Copyright (c) 2014-2015 Phanx <addons@phanx.net>
All rights reserved.

This file contains the entirety of the "PhanxAddonStub" software, to
which the following license applies:

1. Permission is granted for anyone to use, read, or otherwise interpret
this software for any purpose, without any restrictions.

2. Permission is granted for anyone to embed or include this software in
another work that makes use of the interface provided by this software
for the purpose of creating a package of the work and its required
libraries, and to distribute such packages as long as the software is
not modified in any way.

3. Permission is granted for anyone to modify this software or sample
from it, and to distribute such modified versions or derivative works
as long as neither the names of this software nor its authors are used
in the name or title of the work or in any other way that may cause it
to be confused with this software or interfere with the simultaneous
use of this software.

4. This software may not be distributed standalone or in any other way,
in whole or in part, modified or unmodified, without specific prior
written permission from its authors.

5. The names of this software and/or its authors may not be used to
promote or endorse works derived from this software without specific
prior written permission from the authors of this software.

6. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
----------------------------------------------------------------------]]

local ADDON, addon = ...
local frame = CreateFrame("Frame")

function addon:GetName() return ADDON end

------------------------------------------------------------------------
-- Localization

addon.L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	t[k] = k
	return k
end })

------------------------------------------------------------------------
-- Printing

addon.PRINT_PREFIX = "|cff00ddba" .. (addon.name or GetAddOnMetadata(ADDON, "Title") or ADDON) .. ":|r"

function addon:Print(str, ...)
	if select("#", ...) > 0 then
		if strmatch(str, "%%[dfqsx%d]") or strmatch(str, "%%%.%d") then
			str = format(str, ...)
		else
			str = strjoin(" ", str, tostringall(...))
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage(self.PRINT_PREFIX .. " " ..str)
end

------------------------------------------------------------------------
-- Event handling

local handlers = {}
local unitEvents = {}

frame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, event, ...)
	end
	return addon:TriggerEvent(event, ...)
end)

function addon:TriggerEvent(event, ...)
	if not handlers[event] then return end
	for func, handler in pairs(handlers[event]) do
		if handler == true then
			if func(...) == "UNREGISTER" then
				self:UnregisterEvent(event, func)
			end
		elseif func(handler, ...) == "UNREGISTER" then
			self:UnregisterEvent(event, func, handler)
		end
	end
end

local function getEventHandler(self, event, func, handler)
	if type(func) == "string" then
		if type(handler) == "table" then
			func = handler[func]
		else
			func = self[func]
			handler = self
		end
	elseif type(func) ~= "function" then
		func = self[event]
		handler = self
	else
		handler = nil
	end
	return type(func) == "function" and func or nil, handler
end

function addon:RegisterEvent(event, func, handler)
	assert(not unitEvents[event], event .. " already registered as a unit event!")
	func, handler = getEventHandler(self, event, func, handler)
	if func then
		handlers[event] = handlers[event] or {}
		handlers[event][func] = handler or true
		frame:RegisterEvent(event)
		return true
	end
end

function addon:RegisterUnitEvent(event, unit1, unit2, func, handler)
	assert(unitEvents[event] or not handlers[event], event .. " already registered as a non-unit event!")
	func, handler = getEventHandler(self, event, func, handler)
	if func then
		unitEvents[event] = true
		handlers[event] = handlers[event] or {}
		handlers[event][func] = handler or true
		frame:RegisterUnitEvent(event, unit1, unit2)
		return true
	end
end

function addon:UnregisterEvent(event, func, handler)
	if handlers[event] then
		func = getEventHandler(self, event, func, handler)
		if func then
			handlers[event][func] = nil
		end
		if not next(handlers[event]) then
			unitEvents[event] = nil -- TODO: check that this works as intended
			handlers[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end

function addon:UnregisterAllEvents()
	wipe(handlers)
	frame:UnregisterAllEvents()
end

function addon:IsEventRegistered(event)
	return frame:IsEventRegistered(event)
end

------------------------------------------------------------------------
-- Database initialization

local function initDB(db, defaults)
	if type(db) ~= "table" then db = {} end
	if type(defaults) ~= "table" then return db end
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			db[k] = initDB(db[k], v)
		elseif type(v) ~= type(db[k]) then
			db[k] = v
		end
	end
	return db
end

function addon:InitializeDB(db, defaults)
	_G[db] = initDB(_G[db], defaults)

	frame.db_defaults = frame.db_defaults or {}
	frame.db_defaults[db] = defaults

	return _G[db]
end

------------------------------------------------------------------------
-- Ignition sequence

frame:RegisterEvent("ADDON_LOADED")

function frame:ADDON_LOADED(event, name)
	if name ~= ADDON then return end

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if addon.dbName then
		addon:InitializeDB(addon.dbName, addon.dbDefaults)
	end
	if addon.dbpcName then
		addon:InitializeDB(addon.dbpcName, addon.dbpcDefaults)
	end

	if addon.OnLoad then
		addon:OnLoad()
		addon.OnLoad = nil
	end

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end
end

function frame:PLAYER_LOGIN(event)
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil

	if addon.OnLogin then
		addon:OnLogin()
		addon.OnLogin = nil
	end

	self:RegisterEvent("PLAYER_LOGOUT")
end

function frame:PLAYER_LOGOUT(event)
	if addon.OnLogout then
		addon:OnLogout()
		-- no point in cleaning up here since we're logging out
	end

	if self.db_defaults then
		local function cleanDB(db, defaults)
			if type(db) ~= "table" then return {} end
			if type(defaults) ~= "table" then return db end
			for k, v in pairs(db) do
				if type(v) == "table" then
					db[k] = cleanDB(v, defaults[k])
				elseif v == defaults[k] then
					db[k] = nil
				end
			end
			if not next(db) then
				return nil
			end
			return db
		end

		for db, defaults in pairs(frame.db_defaults) do
			_G[db] = cleanDB(_G[db], defaults)
		end
	end
end

------------------------------------------------------------------------
-- Miscellaneous utilities
