--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2014 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info4544-Notebook.html
	http://www.curse.com/addons/wow/notebook
	https://github.com/Phanx/Notebook
----------------------------------------------------------------------]]

local NOTEBOOK, Notebook = ...
local L = Notebook.L
local HELP_TEXT = Notebook.HELP_TEXT

Notebook.name = GetAddOnMetadata(NOTEBOOK, "Title")
Notebook.description = GetAddOnMetadata(NOTEBOOK, "Notes")
Notebook.version = GetAddOnMetadata(NOTEBOOK, "Version")

BINDING_HEADER_NOTEBOOK_TITLE = Notebook.name

NotebookState = {}

------------------------------------------------------------------------
--	Global constants

NOTEBOOK_LIST_BUTTON_COUNT = 7				-- number of buttons in list frame
NOTEBOOK_LIST_BUTTON_HEIGHT = 16			-- height of each button in list frame

------------------------------------------------------------------------
--	Local constants

local NOTEBOOK_CHANNEL_VALUE_FORMAT = "%s:%d:%s"
local NOTEBOOK_CHANNEL_VALUE_FIND = "(.+):(%d+):(.+)"
local NOTEBOOK_MAX_LINE_LENGTH = 240		-- maximum characters in one line
local NOTEBOOK_MAX_NUM_LINES = 64			-- maximum number of lines sent from a note
local NOTEBOOK_NEW_LINE = "\n"				-- newline character
local NOTEBOOK_GETDATE_FORMAT = "%y-%m-%d"	-- see strftime

local NOTEBOOK_SEND_PREFIX = "\032"			-- used to indicate start of a sent line (a non-printing character)
local NOTEBOOK_SEND_POSTFIX = "\032"		-- used to indicate where lines join (a non-printing character)
local NOTEBOOK_HEADER_PRE = "\032##\032  "
local NOTEBOOK_HEADER_POST = "\032  ##"
local NOTEBOOK_HEADER_LINECOUNT_CHAR = "\032"
local NOTEBOOK_HEADER_PATTERN = "^" .. NOTEBOOK_HEADER_PRE .. "(.+)" .. NOTEBOOK_HEADER_POST .. "(" .. NOTEBOOK_HEADER_LINECOUNT_CHAR .. "+)$"

local NOTEBOOK_SEND_LINE_COOLDOWN = 0.25	-- 250 ms per line (max message rate of 1 per sec average over 10)
local NOTEBOOK_SEND_FINISHED_COOLDOWN = 5	-- delay after sending last line
local NOTEBOOK_RECEIVE_TIMEOUT = 3			-- how long to wait after it all should have been received

local NOTEBOOK_MAX_STRING_LENGTH = 768		-- If we go over 900 characters or so (exact value unknown) in a single string,
											-- WoW gets unhappy when saving the string to a file, so use a maximum limit
											-- and wrap longer lines into a table.

------------------------------------------------------------------------
--	Color information

local _colorKnown        = { r = 1,   g = 0.82, b = 0,   a = 0.6 }	-- GameFontNormal yellow ("a" used for highlight alpha)
local _colorNotKnown     = { r = 0.8, g = 0.8,  b = 0.8, a = 0.6 }	-- Light grey ("a" used for highlight alpha)
local _colorTextEnabled  = { r = 1,   g = 0.82, b = 0 }				-- GameFontNormal yellow
local _colorTextDisabled = { r = 0.5, g = 0.5,  b = 0.5 }			-- Light grey

------------------------------------------------------------------------
--	Local variables

local NotebookFrame				-- The frame pointer
local _debugFrame					-- debug output chat frame

local _serverName = GetRealmName()
local _playerName = UnitName("player")

local _original_ChatFrameEditBox_IsVisible	-- original ChatFrameEditBox:IsVisible()
local _original_ChatFrameEditBox_Insert		-- original ChatFrameEditBox:Insert()

local _notesList
--	notes contents:
--		title			text of title
--		author		who provided or last edited the text
--		date			date at which text was last edited
--		sent			date at which text was last sent
--		id				unique ID for the note
--		description	contents of note
--		known			true if note is in our own database, nil otherwise
--		recent		true if note has been edited/sent recently, nil otherwise
--		send			true if can send, nil otherwise
--		update		true if this is an update for an existing known note, nil otherwise

local _notesCount = 0			-- count of how many notes are in notesList
local _notesLastID = 0			-- last note ID used
local _filteredList = {}		-- filtered list of notes, contains indices into notesList
local _filteredCount = 0
local _filterBy = L.ALL_TAB

local _sendInProgress			-- set when sending a message to someone (nil otherwise)
local _sendCooldownTimer		-- set to time to send next line or to allow next send (nil if not used)
local _sendLines = {}			-- the pending lines to be sent
local _sendChannel				-- channel to use ("GUILD", "PARTY", "CHANNEL", etc.)
local _sendTarget				-- target for send
local _lastPlayer				-- last player we sent a note to
local _currentTitle				-- current title to be edited (if there is one)

local _firstTimeLoad			-- set to true if this Notebook has not been run on the current server yet

local _receiveInProgress		-- true when receiving a message
local _receiveTimer				-- set to an expiration time when receiving
local _receiveSender			-- set to the name of the player we are listening to
local _receiveChannel			-- set to the channel we are listening to
local _receiveTarget			-- set to the channel # we are listening to (for chat channels)
local _receiveLinesExpected = 0		-- number of lines expected
local _receiveLines = {}		-- lines so far received
local _receiveTitle				-- title of new note

------------------------------------------------------------------------
--	Configuration flags

local _addSavedToRecent = true		-- false means that only sent and received notes go in the
									-- recent tab, true would add recently saved notes also

------------------------------------------------------------------------
--	First timer's brief manual
------------------------------------------------------------------------

local _firstTimeNote = {
	title = L.WELCOME_NOTE_TITLE,
	description = L.WELCOME_NOTE_DESCRIPTION,
	author = "Cirk",
	date = "05-12-24",
}

------------------------------------------------------------------------
--	Popup defines (see Blizzard's StaticPopup.lua)
------------------------------------------------------------------------

StaticPopupDialogs["NOTEBOOK_SEND_TO_PLAYER"] = {
	text = L.ENTER_PLAYER_NAME_TEXT,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 32,
	OnShow = function(self)
		local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
		editBox:SetText(Notebook:GetPopupData("PLAYER"))
		editBox:HighlightText()
		editBox:SetFocus()
		NotebookFrame.NewButton:Disable()
	end,
	OnHide = function(self)
		local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
		editBox:SetText("")
		NotebookFrame.NewButton:Enable()
		ChatEdit_FocusActiveWindow()
	end,
	OnAccept = function(self, data)
		local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
		Notebook:HandlePopupInput("PLAYER", data, editBox:GetText())
	end,
	EditBoxOnEnterPressed = function(self, data)
		Notebook:HandlePopupInput("PLAYER", data, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["NOTEBOOK_NEW_TITLE"] = {
	text = L.ENTER_NEW_TITLE_TEXT,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 60,
	OnShow = function(self)
		local editBox = self.editBox or _G[self:GetName() .. "WideEditBox"]
		editBox:SetText(Notebook:GetPopupData("TITLE"))
		editBox:HighlightText()
		editBox:SetFocus()
		NotebookFrame.NewButton:Disable()
	end,
	OnHide = function(self)
		local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
		editBox:SetText("")
		NotebookFrame.NewButton:Enable()
		ChatEdit_FocusActiveWindow()
	end,
	OnAccept = function(self, data)
		local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
		Notebook:HandlePopupInput("TITLE", data, editBox:GetText())
	end,
	EditBoxOnEnterPressed = function(self, data)
		Notebook:HandlePopupInput("TITLE", data, self:GetText())
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["NOTEBOOK_REMOVE_CONFIRM"] = {
	text = L.CONFIRM_REMOVE_FORMAT,
	button1 = YES,
	button2 = NO,
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook:HandlePopupInput("CONFIRM", data)
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

StaticPopupDialogs["NOTEBOOK_UPDATE_CONFIRM"] = {
	text = L.CONFIRM_UPDATE_FORMAT,
	button1 = YES,
	button2 = NO,
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook:HandlePopupInput("UPDATE", data)
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

StaticPopupDialogs["NOTEBOOK_SERVER_CONFIRM"] = {
	text = L.CONFIRM_SERVER_CHANNEL_FORMAT,
	button1 = YES,
	button2 = NO,
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook:HandlePopupInput("SERVER", data)
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

------------------------------------------------------------------------
--	Local functions
------------------------------------------------------------------------

local PRINT_PREFIX = NORMAL_FONT_COLOR_CODE .. Notebook.name .. ":|r "
local ERROR_PREFIX = "|cffff7f7f" .. Notebook.name .. ":|r "
local DEBUG_PREFIX = "|cff7fff7f" .. NOTEBOOK .. ":|r "

function Notebook:Print(str, noPrefix)
	DEFAULT_CHAT_FRAME:AddMessage((noPrefix and "   " or PRINT_PREFIX) .. str)
end

function Notebook:Error(str)
	DEFAULT_CHAT_FRAME:AddMessage(ERROR_PREFIX .. str)
end

function Notebook:Debug(str)
	if not _debugFrame then return end
	_debugFrame:AddMessage(DEBUG_PREFIX .. str)
end

------------------------------------------------------------------------

local MONTH_NAMES = {
	["01"] = FULLDATE_MONTH_JANUARY,
	["02"] = FULLDATE_MONTH_FEBRUARY,
	["03"] = FULLDATE_MONTH_MARCH,
	["04"] = FULLDATE_MONTH_APRIL,
	["05"] = FULLDATE_MONTH_MAY,
	["06"] = FULLDATE_MONTH_JUNE,
	["07"] = FULLDATE_MONTH_JULY,
	["08"] = FULLDATE_MONTH_AUGUST,
	["09"] = FULLDATE_MONTH_SEPTEMBER,
	["10"] = FULLDATE_MONTH_OCTOBER,
	["11"] = FULLDATE_MONTH_NOVEMBER,
	["12"] = FULLDATE_MONTH_DECEMBER,
}

function Notebook:GetDateText(packedDate)
	-- Notebook uses a date format of yymmdd, returned automatically by
	-- calling date("%y%m%d"), however we unpack this into a more human
	-- readable form.
	-- local year, month, day = strmatch(packedDate, "(%d%d)(%d%d)(%d%d)")
	local year, month, day = strsplit("-", packedDate)
	return format("%s %s 20%s", day, MONTH_NAMES[month], year)
end

------------------------------------------------------------------------

function Notebook:GenerateSignature(text, numLines)
	-- Generates a "secret" signature version of the provided text string
	-- that other Notebooks can automatically recognize.
	return NOTEBOOK_HEADER_PRE .. text .. NOTEBOOK_HEADER_POST .. strrep(NOTEBOOK_HEADER_LINECOUNT_CHAR, numLines)
end

------------------------------------------------------------------------

function Notebook:Reset()
	-- Resets the Notebook back to empty
	_notesList = {}
	_filteredList = {}
	_notesCount = 0
	_filteredCount = 0
	_notesLastID = 0
end

function Notebook:SaveData()
	-- Saves the currently known entries in the Notebook (not-known are not saved)
	local notes = {}
	for i = 1, #_notesList do
		local ndata = _notesList[i]
		if ndata.known then
			local saveNote = {}
			saveNote.author = ndata.author
			saveNote.date = ndata.date
			saveNote.sent = ndata.sent
			if strlen(ndata.description) < NOTEBOOK_MAX_STRING_LENGTH then
				saveNote.description = ndata.description
			else
				local data = ndata.description
				local result = {}
				while strlen(data or "") > 0 do
					local prefix = strsub(data, 1, NOTEBOOK_MAX_STRING_LENGTH)
					data = strsub(data, NOTEBOOK_MAX_STRING_LENGTH + 1)
					tinsert(result, prefix)
				end
				saveNote.description = result
			end
			if ndata.send then
				saveNote.send = 1
			end
			notes[ndata.title] = saveNote
		end
	end
	NotebookState.Notes = notes
	NotebookState.Servers = nil
end

function Notebook:LoadOneNote(title, ndata)
	-- Given a saved note defined by a title and by ndata, this function
	-- creates a note structure for use in-memory.  The _notesLastID value is
	-- also automatically incremented to form the note's id value
	local newNote = {
		title = title,
		author = ndata.author,
		date = ndata.date,
		sent = ndata.sent,
		known = true,
	}
	if not strfind(ndata.date, "%-") then
		-- @PHANX, 15 Mar 2014, upgrade old date storage format
		local y, m, d = strmatch(ndata.date, "(%d%d)(%d%d)(%d%d)")
		newNote.date = strjoin("-", y, m, d)
	end
	if type(ndata.description) == "string" then
		newNote.description = ndata.description
	else
		newNote.description = ""
		if type(ndata.description) == "table" then
			for i = 1, #ndata.description do
				newNote.description = newNote.description .. ndata.description[i]
			end
		end
	end
	if ndata.send then
		newNote.send = true
	end
	_notesLastID = _notesLastID + 1
	newNote.id = _notesLastID
	return newNote
end

function Notebook:LoadData()
	-- Loads all the notes from the current saved variables file.  This
	-- function implements code to read the previous save file format (where
	-- notes were saved per server) and handles notes with the same name from
	-- different servers by appending the server name.
	Notebook:Reset()
	for entry, ndata in pairs(NotebookState.Notes) do
		_notesCount = _notesCount + 1
		_notesList[_notesCount] = Notebook:LoadOneNote(entry, ndata)
	end
	if NotebookState.Servers then
		for server, sdata in pairs(NotebookState.Servers) do
			if sdata.Notes then
				for entry, ndata in pairs(sdata.Notes) do
					local title = entry
					repeat
						local found = nil
						for i = 1, #_notesList do
							if _notesList[i].title == title then
								title = title .. " -" .. server
								found = true
								break
							end
						end
					until not found
					_notesCount = _notesCount + 1
					_notesList[_notesCount] = Notebook:LoadOneNote(title, ndata)
				end
			end
		end
	end
	if _notesCount > 0 then
		_firstTimeLoad = nil
	end
end

function Notebook:CalculateChecksum(string)
	Notebook:Debug("Notebook:CalculateChecksum is still TO DO")
	return 0
end

function Notebook:FindByTitle(title, known)
	-- Returns the entry of the note with the matching title or nil if not found.  If known is true then only known entries are checked.
	if known then
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.known and ndata.title == title then
				return ndata
			end
		end
	else
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.title == title then
				return ndata
			end
		end
	end
	return nil
end

function Notebook:FindNoteByID(id)
	-- Returns the entry with the matching id, or nil if not found
	if id then
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.id == id then
				return ndata
			end
		end
	end
	return nil
end

function Notebook:AddNote(title, author, date, description, known, recent, send)
	-- Adds a new entry to the notebook.  Note that it is the callers
	-- responsibility to make sure the title is valid and unique!  The
	-- function then returns the newly added note entry.
	local newNote = {
		title = title,
		author = author,
		date = date,
		description = description,
		known = known,
		recent = recent,
		send = send,
	}
	_notesLastID = _notesLastID + 1
	newNote.id = _notesLastID
	_notesCount = _notesCount + 1
	_notesList[_notesCount] = newNote
	return newNote
end

function Notebook:RemoveNoteByID(id)
	-- Removes (deletes) the note with the indicated id from the list.  Note
	-- that it appears that sometimes tremove does not work properly (or
	-- at least reliably), at least when the index being removed is not the
	-- first or last index, so we do it the somewhat slower way of recreating
	-- the table entries without the one we don't want.
	local newList = {}
	for index = 1, _notesCount do
		local ndata = _notesList[index]
		if ndata.id ~= id then
			tinsert(newList, ndata)
		end
		_notesList[index] = nil
	end
	_notesCount = #newList
	_notesList = newList
end

function Notebook:Rename(ndata, title)
	-- Renames the indicated note entry with the given title.  It is the
	-- caller's responsibility to ensure that the new title is valid and
	-- unique.
	ndata.title = title
	if _addSavedToRecent then
		ndata.recent = true
	end
end

function Notebook:UpdateDescription(ndata, description)
	-- Updates the description in the note, and also sets the author (to the
	-- player) and date (to the current server date).
	ndata.description = description
	ndata.author = _playerName
	ndata.date = date(NOTEBOOK_GETDATE_FORMAT)
	if _addSavedToRecent then
		ndata.recent = true
	end
end

function Notebook:CompareDescription(desc1, desc2)
	-- Does a simple compare on the two passed descriptions to see if they are
	-- equal (or close enough to equal) by converting all whitespace sequences
	-- in the descriptions to single spaces.  If the two strings are then
	-- equal, the function will return true.
	local text1 = gsub(desc1 .. " ", "(%s+)", " ")
	local text2 = gsub(desc2 .. " ", "(%s+)", " ")
	if text1 == text2 then
		return true
	end
end

function Notebook.CompareOnTitle(index1, index2)
	-- Filters the list into ascending title order.  If the title's are the
	-- same then we choose the known one first.  Note that it is important to
	-- check for the indices being different because the sort algorithm
	-- doesn't like sorting on secondary parameters.
	if index1 == index2 then
		return false
	end
	if _notesList[index1].title == _notesList[index2].title then
		return _notesList[index1].known
	end
	return _notesList[index1].title < _notesList[index2].title
end

function Notebook:FilterList()
	_filteredList = {}
	_filteredCount = 0
	if _filterBy == L.KNOWN_TAB then
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.known then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = i
			end
		end
	elseif _filterBy == L.MINE_TAB then
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.author == _playerName then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = i
			end
		end
	elseif _filterBy == L.RECENT_TAB then
		for i = 1, #_notesList do
			local ndata = _notesList[i]
			if ndata.recent then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = i
			end
		end
	else
		for i = 1, #_notesList do
			tinsert(_filteredList, i)
		end
		_filteredCount = _notesCount
	end
	sort(_filteredList, Notebook.CompareOnTitle)
end

function Notebook:UpdateNotKnown(removeTitle)
	-- This function looks through all the notes currently not known, and
	-- determines whether they should be flagged for adding or for updating.
	-- If a note that is not-known is identical (title and description) to a
	-- existing known note, then the not-known note will be discarded, and the
	-- recent status transfered from it to the known note instead.  If the
	-- removeTitle parameter is set, then any not known entries with matching
	-- titles will be automatically removed (irrespective of their
	-- description)
	local removeList = {}
	for i = 1, #_notesList do
		local ndata = _notesList[i]
		if not ndata.known then
			if ndata.title == removeTitle then
				tinsert(removeList, ndata.id)
			else
				local pdata = Notebook:FindByTitle(ndata.title, true)
				if pdata then
					if Notebook:CompareDescription(pdata.description, ndata.description) then
						if ndata.recent then
							pdata.recent = true
						end
						tinsert(removeList, ndata.id)
					else
						ndata.update = true
					end
				else
					ndata.update = nil
				end
			end
		end
	end
	for i = 1, #removeList do
		Notebook:RemoveNoteByID(removeList[i])
	end
end

function Notebook:ConvertToLines(text, maxLines, debug)
	-- Given a text string, this function converts it into a line-formatted
	-- table, suitable for sending to a target channel.  The formatting
	-- enforces a maximum per-line length of NOTEBOOK_MAX_NUM_LINES (with
	-- word-wrapping), reduces multiple empty lines to single empty lines,
	-- and enforces a maximum of maxLines in the resulting table, which is
	-- then returned.
	local lines = {}
	local lastLine = nil
	local numLines = 0
	while text and text ~= "" do
		local thisLine
		local checkWrap
		local start = strfind(text, NOTEBOOK_NEW_LINE, 1, true)
		if start then
			if start <= NOTEBOOK_MAX_LINE_LENGTH then
				thisLine = strsub(text, 1, start - 1)
				text = strsub(text, start + 1)
				checkWrap = nil
			else
				thisLine = strsub(text, 1, NOTEBOOK_MAX_LINE_LENGTH)
				if start == NOTEBOOK_MAX_LINE_LENGTH + 1 then
					text = strsub(text, NOTEBOOK_MAX_LINE_LENGTH + 2)
					checkWrap = nil
				else
					text = strsub(text, NOTEBOOK_MAX_LINE_LENGTH + 1)
					checkWrap = true
				end
			end
		else
			if strlen(text) > NOTEBOOK_MAX_LINE_LENGTH then
				thisLine = strsub(text, 1, NOTEBOOK_MAX_LINE_LENGTH)
				text = strsub(text, NOTEBOOK_MAX_LINE_LENGTH + 1)
				checkWrap = true
			else
				thisLine = text
				text = ""
				checkWrap = nil
			end
		end
		if checkWrap then
			-- Do word wrapping and also whitespace stripping from the end and
			-- start of the broken line.
			local thisLength = strfind(thisLine, "[%s]+[^%s]*$")
			if thisLength then
				text = strsub(thisLine, thisLength + 1) .. text
				thisLine = strsub(thisLine, 1, thisLength - 1) .. NOTEBOOK_SEND_POSTFIX
				local textStart = strfind(text, "[^%s]")
				if textStart then
					text = strsub(text, textStart)
				end
			end
		else
			-- Strip any whitespace from the end of the line (no need to send
			-- spaces at the end of a line)
			thisLine = gsub(thisLine, "(%s+)$", "")
		end
		if thisLine == "" then
			if lastLine ~= "" then
				numLines = numLines + 1
				lines[numLines] = ""
			end
		else
			numLines = numLines + 1
			lines[numLines] = thisLine
		end
		lastLine = thisLine
		if maxLines and numLines > maxLines then
			-- We wait until we get numLines greater than maxLines to allow
			-- for trailing "empty" lines to not show as an error.
			Notebook:Debug("--> limiting number of lines to " .. maxLines)
			lines[numLines] = nil
			numLines = maxLines
			break
		end
	end
	-- Remove any trailing empty lines (there can only be one at most)
	if lines[numLines] == "" then
		lines[numLines] = nil
		numLines = numLines - 1
	end
	return lines, numLines
end

function Notebook:SendNote(ndata, channel, target)
	-- Formats the provided note to be sent using the indicated channel and
	-- target (if needed).  Note that the actual sending of all text lines
	-- (apart from the title dois done via timer in OnUpdate.
	if target then
		Notebook:Debug("SendNote: " .. ndata.title .. ", " .. channel .. ", " .. target)
	else
		Notebook:Debug("SendNote: " .. ndata.title .. ", " .. channel)
	end
	-- Convert into lines table for sending
	local lines, numLines = Notebook:ConvertToLines(ndata.description, NOTEBOOK_MAX_NUM_LINES, _debugFrame)
	-- Format title string with our "secret" notebook code for any other
	-- notebooks to recognize.
	if channel == "BN_WHISPER" then
		BNSendWhisper(target, Notebook:GenerateSignature(ndata.title, numLines))
	else
		SendChatMessage(Notebook:GenerateSignature(ndata.title, numLines), channel, nil, target)
	end
	if numLines > 0 then
		_sendInProgress = true
		_sendCooldownTimer = GetTime() + NOTEBOOK_SEND_LINE_COOLDOWN
		_sendLines = lines
		_sendChannel = channel
		_sendTarget = target
		NotebookFrame:SetScript("OnUpdate", Notebook.Frame_OnUpdate)
	end
	-- Set the recent flag (we don't have to refilter the list because this
	-- entry must already be on the current one)
	ndata.recent = true
	-- Update the sent date
	ndata.sent = date(NOTEBOOK_GETDATE_FORMAT)
	-- Update the displayed list
	Notebook:FilterList()
	Notebook.Frame_UpdateList()
end

------------------------------------------------------------------------
--	Chat event parsing functions
------------------------------------------------------------------------

function Notebook:ProcessChatMessage(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	-- Called for raid, party, guild, whisper, and channel events.  Note that
	-- system channels (e.g., General, Trade, etc.) are indicated by arg7
	-- being non-zero, and are always ignored.  Similarly anything sent by
	-- ourselves should also be ignored.
	if arg2 == _playerName or tonumber(arg7) ~= 0 then
		return
	end
	local channel = strsub(event, 10)
	if not _receiveInProgress then
		local _, _, title, countString = strfind(arg1, NOTEBOOK_HEADER_PATTERN)
		if title and countString then
			local lineCount = strlen(countString)
			if lineCount >= 1 and lineCount <= NOTEBOOK_MAX_NUM_LINES then
				_receiveInProgress = true
				_receiveTimer = GetTime() + (NOTEBOOK_SEND_LINE_COOLDOWN * lineCount) + NOTEBOOK_RECEIVE_TIMEOUT
				_receiveSender = arg2
				_receiveChannel = channel
				_receiveTarget = arg8
				_receiveLinesExpected = lineCount
				_receiveLines = {}
				_receiveTitle = title
				NotebookFrame:SetScript("OnUpdate", self.Frame_OnUpdate)
			end
		end
	elseif arg2 == _receiveSender and _receiveChannel == channel and _receiveTarget == arg8 then
		if strsub(arg1, 1, 1) == NOTEBOOK_SEND_PREFIX then
			tinsert(_receiveLines, strsub(arg1, 2))
			if #_receiveLines == _receiveLinesExpected then
				self:Debug("Received note \"" .. _receiveTitle .. "\" from " .. _receiveSender)
				_receiveInProgress = nil
				_receiveTimer = nil
				description = ""
				for i = 1, #_receiveLines do
					local text = _receiveLines[i]
					local len = strlen(text)
					if strsub(text, len) == NOTEBOOK_SEND_POSTFIX then
						description = description .. strsub(text, 1, len - 1) .. " "
					else
						description = description .. text .. NOTEBOOK_NEW_LINE
					end
				end
				-- Check to see if we have this entry already
				local addNote = true
				for i = 1, #_notesList do
					local text = _notesList[i]
					if ndata.title == _receiveTitle then
						if self:CompareDescription(ndata.description, description) then
							-- Same note already exists, so don't add it again
							ndata.recent = true
							addNote = nil
							break
						end
					end
				end
				if addNote then
					self:Print(format(L.NOTE_RECEIVED_FORMAT, _receiveTitle, _receiveSender))
					Notebook:AddNote(_receiveTitle, _receiveSender, date(NOTEBOOK_GETDATE_FORMAT), description, false, true, true)
				end
				Notebook:UpdateNotKnown()
				Notebook:FilterList()
				Notebook.Frame_UpdateList()
			end
		end
	end
end

------------------------------------------------------------------------
--	Initialization functions
------------------------------------------------------------------------

function Notebook:ADDON_LOADED(addon)
	if addon ~= NOTEBOOK then return end
	NotebookFrame:UnregisterEvent("ADDON_LOADED")

	if not NotebookState then
		NotebookState = {}
	end
	if not NotebookState.Notes then
		NotebookState.Notes = {}
		_firstTimeLoad = true
	end
	_notesList = NotebookState.Notes

	if IsLoggedIn() then
		Notebook:PLAYER_LOGIN()
	end
end

function Notebook:PLAYER_LOGIN()
	NotebookFrame:UnregisterEvent("PLAYER_LOGIN")

	-- Load notes
	Notebook:LoadData()
	if _firstTimeLoad then
		Notebook:AddNote(_firstTimeNote.title, _firstTimeNote.author, _firstTimeNote.date, _firstTimeNote.description, true, false, false)
	end
	Notebook:FilterList()
	Notebook.Frame_UpdateList()

	-- Register for required events now
	NotebookFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
	NotebookFrame:RegisterEvent("CHAT_MSG_RAID")
	NotebookFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	NotebookFrame:RegisterEvent("CHAT_MSG_PARTY")
	NotebookFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	NotebookFrame:RegisterEvent("CHAT_MSG_GUILD")
	NotebookFrame:RegisterEvent("CHAT_MSG_OFFICER")
	NotebookFrame:RegisterEvent("CHAT_MSG_WHISPER")
	NotebookFrame:RegisterEvent("CHAT_MSG_CHANNEL")

	-- Register for events and hook functions
	-- See the comments for the Notebook.ChatFrameEditBox_IsVisible and
	-- Notebook.ChatFrameEditBox_Insert functions as to why these are disabled
	-- for now.
--	if not _original_ChatFrameEditBox_IsVisible then
--		_original_ChatFrameEditBox_IsVisible = ChatFrameEditBox.IsVisible
--		ChatFrameEditBox.IsVisible = Notebook.ChatFrameEditBox_IsVisible
--	end
--	if not _original_ChatFrameEditBox_Insert then
--		_original_ChatFrameEditBox_Insert = ChatFrameEditBox.Insert
--		ChatFrameEditBox.Insert = Notebook.ChatFrameEditBox_Insert
--	end
end

function Notebook:PLAYER_LOGOUT()
	Notebook:SaveData()
end

------------------------------------------------------------------------
--	NotebookFrame UI functions
------------------------------------------------------------------------

function Notebook.Frame_SetDescriptionText(text, known)
	-- For notes that are known (known is true) we use the scrolling editbox
	-- to show the text.  In order to get the scrolling editbox to play nicely
	-- when we reset its text contents (specifically to force the scrollbar to
	-- go to the top of the text rather than the bottom) we have to jump
	-- through a few hoops, which is done between this function and the
	-- editbox scripts in the XML file.  Basically the function here sets some
	-- flags to reset the cursor position when the actual text update occurs,
	-- or when a cursor update occurs (if the text didn't change), and in the
	-- case where neither the text or cursor position changed, we set a
	-- private variable that ScrollingEdit_OnUpdate uses (normally set by the
	-- ScrollingEdit_OnCursorChanged function) and trigger an OnUpdate call.
	-- The case where we are setting the editbox to the empty string has to be
	-- dealt with as a special case due to the way the editbox doesn't perform
	-- updates correctly if it is empty.  To avoid that we set instead a
	-- special character to force a text update, and set a flag to request the
	-- XML script code to reset the contents back to empty (which will occur
	-- after the editbox scrolling, etc., has been updated).
	-- For notes that are not known (known is nil or false) we instead use the
	-- scrolling textbox to display the text, which is a little simpler to
	-- reset to the top of the text when needed.
	-- This function also stores the id of the note being edited or displayed
	-- in NotebookFrame object itself, so that this can be checked for easily
	-- when changing between tabs or knowing when to start an edit.
	if known then
		NotebookFrame.TextScrollFrame:Hide()
		NotebookFrame.EditScrollFrame:Show()
		NotebookFrame.EditBox:ClearFocus()
		if text == "" then
			-- Set a fake string into the editbox, noting that it is important
			-- that this string doesn't match what the editbox has in it
			-- already (or else it won't generate a OnTextUpdate event) so we
			-- use a non-visible non-enterable character simply to avoid
			-- having to check the current contents.
			NotebookFrame.EditBox.textResetToEmpty = true
			NotebookFrame.EditBox:SetText(NOTEBOOK_SEND_PREFIX)
		else
			NotebookFrame.EditBox:SetText(text)
			NotebookFrame.EditBox:SetCursorPosition(0)
		end
		NotebookFrame.EditBox.textReset = true
		NotebookFrame.EditBox.cursorOffset = 0
		ScrollingEdit_OnUpdate( NotebookFrame.EditBox, 0, NotebookFrame.EditBox:GetParent() )
	else
		NotebookFrame.EditBox:ClearFocus()
		NotebookFrame.EditScrollFrame:Hide()
		NotebookFrame.TextScrollFrame:Show()
		NotebookFrame.TextBox:SetText(text)
		NotebookFrame.TextScrollFrame.ScrollBar:SetValue(0)
		NotebookFrame.TextScrollFrame:UpdateScrollChildRect()
	end
end

function Notebook.Frame_SetCanSendCheckbox(enable, send)
	-- Sets whether the Can-send checkbox is enabled or not, and if enabled,
	-- whether it should be checked or not
	if enable then
		NotebookFrame.CanSendCheckButton:SetChecked(send)
		NotebookFrame.CanSendCheckButton:Enable()
		NotebookFrame.CanSendCheckButton.Text:SetTextColor(_colorTextEnabled.r, _colorTextEnabled.g, _colorTextEnabled.b)
		if GameTooltip:IsOwned(NotebookFrame.CanSendCheckButton) then
			if send then
				GameTooltip:SetText(NotebookFrame.CanSendCheckButton.tooltipOnText)
			else
				GameTooltip:SetText(NotebookFrame.CanSendCheckButton.tooltipOffText)
			end
		end
	else
		NotebookFrame.CanSendCheckButton:SetChecked(nil)
		NotebookFrame.CanSendCheckButton:Disable()
		NotebookFrame.CanSendCheckButton.Text:SetTextColor(_colorTextDisabled.r, _colorTextDisabled.g, _colorTextDisabled.b)
	end
end

function Notebook.Frame_UpdateButtons(editing, known, update)
	-- Sets the status of the Add, Save, Cancel, Update buttons as required
	-- based on whether the current entry is known, being edited, etc.
	if editing then
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript("OnClick", Notebook.Frame_SaveButtonOnClick)
		NotebookFrame.SaveButton:SetText(L.SAVE_BUTTON)
		NotebookFrame.SaveButton.tooltipText = L.SAVE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = L.SAVE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Enable()
	elseif known then
		NotebookFrame.SaveButton:Disable()
		NotebookFrame.SaveButton:SetScript("OnClick", Notebook.Frame_SaveButtonOnClick)
		NotebookFrame.SaveButton:SetText(L.SAVE_BUTTON)
		NotebookFrame.SaveButton.tooltipText = L.SAVE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = L.SAVE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Disable()
	elseif update then
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript("OnClick", Notebook.Frame_UpdateButtonOnClick)
		NotebookFrame.SaveButton:SetText(L.UPDATE_BUTTON)
		NotebookFrame.SaveButton.tooltipText = L.UPDATE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = L.UPDATE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Disable()
	else
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript("OnClick", Notebook.Frame_AddButtonOnClick)
		NotebookFrame.SaveButton:SetText(L.ADD_BUTTON)
		NotebookFrame.SaveButton.tooltipText = L.ADD_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = L.ADD_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Disable()
	end
end

function Notebook.Frame_OnLoad(self)
	-- Set the Can-send check button initial state
	Notebook.Frame_SetCanSendCheckbox()

	-- Set the text colors of the editbox and textbox
	NotebookFrame.EditBox:SetTextColor(_colorKnown.r, _colorKnown.g, _colorKnown.b)
	NotebookFrame.TextBox:SetTextColor(_colorNotKnown.r, _colorNotKnown.g, _colorNotKnown.b)
end

function Notebook.Frame_UpdateList(self, offset, autoScroll)
	-- Updates the displayed list of notes in the NotebookListFrame.  If the
	-- offset parameter is specified then it is used as the new offset
	-- (adjusted for the actual size of the list).  If autoScroll is true
	-- then the offset is automatically adjusted to show the currently
	-- selected entry (if available).
	if not NotebookFrame:IsShown() then
		return
	end
	local currentOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	if not offset then
		offset = currentOffset
	end
	if (offset + NOTEBOOK_LIST_BUTTON_COUNT) > _filteredCount then
		offset = _filteredCount - NOTEBOOK_LIST_BUTTON_COUNT
		if offset < 0 then
			offset = 0
		end
	end
	if autoScroll and NotebookFrame.selectedID then
		local index
		for i = 1, _filteredCount do
			local ndata = _notesList[_filteredList[i]]
			if ndata.id == NotebookFrame.selectedID then
				index = i
				break
			end
		end
		if index then
			local newOffset = offset
			if (offset + NOTEBOOK_LIST_BUTTON_COUNT) < index then
				offset = index - NOTEBOOK_LIST_BUTTON_COUNT
			elseif index < offset then
				offset = index - 1
			end
		end
	end
	if offset ~= currentOffset then
		FauxScrollFrame_SetOffset(NotebookFrame.ListScrollFrame, offset)
		NotebookFrame.ListScrollBar:SetValue(offset * NOTEBOOK_LIST_BUTTON_HEIGHT)
	end

	-- Update buttons
	NotebookFrame.selectedButton = nil
	for i = 1, NOTEBOOK_LIST_BUTTON_COUNT do
		local button = NotebookFrame.ListButtons[i]
		local index = i + offset
		if index <= _filteredCount then
			local titleText = button.TitleText
			local titleHighlight = button.TitleHighlight
			local filteredIndex = _filteredList[index]
			local ndata = _notesList[filteredIndex]
			button.nindex = filteredIndex
			if ndata.saved or (NotebookFrame.editing and NotebookFrame.selectedID == ndata.id) then
				titleText:SetText(ndata.title .. L.TITLE_CHANGE_NOT_SAVED)
			else
				titleText:SetText(ndata.title)
			end
			if ndata.known then
				titleText:SetTextColor(_colorKnown.r, _colorKnown.g, _colorKnown.b)
				titleHighlight:SetVertexColor(_colorKnown.r, _colorKnown.g, _colorKnown.b, _colorKnown.a)
			else
				titleText:SetTextColor(_colorNotKnown.r, _colorNotKnown.g, _colorNotKnown.b)
				titleHighlight:SetVertexColor(_colorNotKnown.r, _colorNotKnown.g, _colorNotKnown.b, _colorNotKnown.a)
			end
			if NotebookFrame.selectedID == ndata.id then
				NotebookFrame.selectedButton = button
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			local tooltipText
			if ndata.known then
				if ndata.author == _playerName then
					tooltipText = format(L.DETAILS_DATE_KNOWN_SAVED_FORMAT, Notebook:GetDateText(ndata.date))
				else
					tooltipText = format(L.DETAILS_DATE_KNOWN_UPDATED_FORMAT, Notebook:GetDateText(ndata.date), ndata.author)
				end
			else
				tooltipText = format(L.DETAILS_DATE_UNSAVED_FORMAT, Notebook:GetDateText(ndata.date), ndata.author)
			end
			if ndata.sent then
				tooltipText = tooltipText .. "\n" .. format(L.DETAILS_SENT_FORMAT, Notebook:GetDateText(ndata.sent))
			end
			if not ndata.known then
				tooltipText = tooltipText .. "\n" .. L.DETAILS_NOT_KNOWN_TEXT
			end
			tooltipText = tooltipText .. "\n" .. format(L.DETAILS_SIZE_FORMAT, strlen(ndata.description))
			button.tooltipText = tooltipText
			if GameTooltip:IsOwned(button) then
				GameTooltip:SetText(button.tooltipText, 1, 1, 1)
			end

			button:Show()
		else
			button.nindex = nil
			button:Hide()
		end
	end

	-- Update scrollbar
	FauxScrollFrame_Update(NotebookFrame.ListScrollFrame, _filteredCount, NOTEBOOK_LIST_BUTTON_COUNT, NOTEBOOK_LIST_BUTTON_HEIGHT)
end

function Notebook.Frame_ListButtonOnClick(self, clicked)
	-- On either a left or right mouse button click we switch focus to the
	-- indicated note (which will discard any unsaved changes in the previous
	-- note).  This means we don't have to worry about indicating which note
	-- we are referring to in the drop-down menu (with note titles able to be
	-- quite long, this can cause a problem).

	-- Close any open drop-down menus (do this even on a left-click)
	CloseDropDownMenus()

	-- If we are changing focus to a different note, check if we were editing
	-- the previous entry and save its contents if needed.  Then set the new
	-- text and set the button and editing status flags before updating the
	-- list to show the current status.
	local ndata = _notesList[self.nindex]
	if NotebookFrame.selectedID ~= ndata.id then
		if NotebookFrame.editing then
			local pdata = Notebook:FindNoteByID(NotebookFrame.selectedID)
			if pdata then
				local text = NotebookFrame.EditBox:GetText()
				if text ~= pdata.description then
					pdata.saved = text
				else
					pdata.saved = nil
				end
			end
		end
		if ndata.saved then
			Notebook.Frame_SetDescriptionText(ndata.saved, ndata.known)
			NotebookFrame.editing = true
		else
			Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
			NotebookFrame.editing = nil
		end
		Notebook.Frame_UpdateButtons(NotebookFrame.editing, ndata.known, ndata.update)
		Notebook.Frame_SetCanSendCheckbox(true, ndata.send)
		NotebookFrame.selectedID = ndata.id
		Notebook.Frame_UpdateList()
	end
	if clicked == "RightButton" then
		NotebookFrame.EditBox:ClearFocus()
		NotebookDropDown.name = ndata.title
		NotebookDropDown.noteIndex = self.nindex
		NotebookDropDown.initialize = Notebook.Frame_DropdownInitialize
		NotebookDropDown.displayMode = "MENU"
		-- Calculate position of drop-down menu here manually based on the
		-- cursor position so that OnUpdate can reuse it.  This is effectively
		-- the same as ToggleDropDownMenu(1, nil, NotebookDropDown, "cursor")
		local cursorX, cursorY = GetCursorPosition()
		local uiScale = UIParent:GetScale()
		NotebookDropDown.offsetX = cursorX/uiScale
		NotebookDropDown.offsetY = cursorY/uiScale
		ToggleDropDownMenu(1, nil, NotebookDropDown, "UIParent", NotebookDropDown.offsetX, NotebookDropDown.offsetY)
	end
end

function Notebook.Frame_DropdownInitialize(self)
	-- Called by the UI dropdown code when building the dropdown menu, it sets
	-- the UIDROPDOWNMENU_MENU_LEVEL (1 to N) and UIDROPDOWNMENU_MENU_VALUE
	-- (set to passed text string) fields as needed for the various menus and
	-- sub-menus
	local info = UIDropDownMenu_CreateInfo()
	local ndata = _notesList[NotebookDropDown.noteIndex]
	local channelList = { GetChannelList() }

	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		-- Send options sub-menu.  This is disabled when the note has been
		-- edited but not saved, we are in send cooldown, or the note is not
		-- flagged for sending.
		info.text = L.SEND_OPTION
		info.notCheckable = 1
		info.keepShownOnClick = 1
		if NotebookFrame.editing or _sendCooldownTimer or not ndata.send then
			info.disabled = 1
			info.hasArrow = nil
		else
			info.hasArrow = 1
		end
		UIDropDownMenu_AddButton(info)

		-- Save/Add/Update option.
		info.disabled = nil
		info.hasArrow = nil
		if ndata.known then
			info.text = L.SAVE_OPTION
			info.value = L.SAVE_OPTION
			if not NotebookFrame.editing then
				info.disabled = 1
			end
		elseif ndata.update then
			info.text = L.UPDATE_OPTION
			info.value = L.UPDATE_OPTION
		else
			info.text = L.ADD_OPTION
			info.value = L.ADD_OPTION
		end
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Rename option
		info.disabled = nil
		info.text = L.RENAME_OPTION
		info.value = L.RENAME_OPTION
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Delete option
		info.text = L.DELETE_OPTION
		info.value = L.DELETE_OPTION
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Cancel option
		info.text = CANCEL
		info.value = CANCEL
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == L.SEND_OPTION then
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = 1
			info.func = Notebook.Frame_DropdownSelect

			-- Send to specified player
			info.text = L.SEND_TO_PLAYER
			info.value = L.SEND_TO_PLAYER
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["WHISPER"].r * 255, ChatTypeInfo["WHISPER"].g * 255, ChatTypeInfo["WHISPER"].b * 255 )
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			if UnitCanCooperate("player", "target") then
				-- Send to target
				info.text = L.SEND_TO_TARGET
				info.value = L.SEND_TO_TARGET
				info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["WHISPER"].r * 255, ChatTypeInfo["WHISPER"].g * 255, ChatTypeInfo["WHISPER"].b * 255 )
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end

			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
				-- Send to instance
				info.text = L.SEND_TO_INSTANCE
				info.value = L.SEND_TO_INSTANCE
				info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["INSTANCE_CHAT"].r * 255, ChatTypeInfo["INSTANCE_CHAT"].g * 255, ChatTypeInfo["INSTANCE_CHAT"].b * 255 )
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end

			if IsInRaid() or IsInGroup(LE_PARTY_CATEGORY_HOME) then
				-- Send to party
				info.text = L.SEND_TO_PARTY
				info.value = L.SEND_TO_PARTY
				info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["PARTY"].r * 255, ChatTypeInfo["PARTY"].g * 255, ChatTypeInfo["PARTY"].b * 255 )
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end

			if IsInRaid() and (UnitIsGroupLeader("player") and UnitIsGroupAssistant("player")) then
				-- Send to raid (only if you are leader or officer)
				info.text = L.SEND_TO_RAID
				info.value = L.SEND_TO_RAID
				info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["RAID"].r * 255, ChatTypeInfo["RAID"].g * 255, ChatTypeInfo["RAID"].b * 255 )
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end

			if IsInGuild() then
				local _, _, rank = GetGuildInfo("player")
				GuildControlSetRank(1 + rank)
				local _, guildSpeak, _, officerSpeak = GuildControlGetRankFlags()

				if guildSpeak then
					-- Send to guild
					info.text = L.SEND_TO_GUILD
					info.value = L.SEND_TO_GUILD
					info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["GUILD"].r * 255, ChatTypeInfo["GUILD"].g * 255, ChatTypeInfo["GUILD"].b * 255 )
					info.func = Notebook.Frame_DropdownSelect
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end

				if officerSpeak then
					-- Send to officer
					info.text = L.SEND_TO_OFFICER
					info.value = L.SEND_TO_OFFICER
					info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["OFFICER"].r * 255, ChatTypeInfo["OFFICER"].g * 255, ChatTypeInfo["OFFICER"].b * 255 )
					info.func = Notebook.Frame_DropdownSelect
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end

			if #channelList > 0 or BNGetConversationInfo(1) then
				-- Send to channel
				info.text = L.SEND_TO_CHANNEL
				info.value = L.SEND_TO_CHANNEL
				info.colorCode = nil
				info.func = nil
				info.hasArrow = 1
				info.keepShownOnClick = 1
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end

	elseif UIDROPDOWNMENU_MENU_LEVEL == 3 then
		if UIDROPDOWNMENU_MENU_VALUE == L.SEND_TO_CHANNEL then
			for i = 1, #channelList, 2 do
				local channelNum = channelList[i]
				local channelName = channelList[i + 1]
				local displayNum = channelNum
				if Chatmanager and Chatmanager.GetChannelInfo then
					displayNum = Chatmanager.GetChannelInfo(channelNum)
				end
				local color = ChatTypeInfo["CHANNEL" .. channelNum]
				info.text = format(L.CHANNEL_NAME_FORMAT, displayNum, channelName)
				info.value = format(NOTEBOOK_CHANNEL_VALUE_FORMAT, L.SEND_TO_CHANNEL, channelNum, channelName)
				info.colorCode = format("|cff%02x%02x%02x", 255*color.r, 255*color.g, 255*color.b)
				info.notCheckable = 1
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
			for i = 1, BNGetMaxNumConversations() do
				if BNGetConversationInfo(i) == "conversation" then
					local color = ChatTypeInfo["BN_CONVERSATION"]
					info.text = format(CONVERSATION_NAME, i + MAX_WOW_CHAT_CHANNELS)
					info.value = format(NOTEBOOK_CHANNEL_VALUE_FORMAT, L.SEND_TO_CHANNEL, i, "BN_CONVERSATION")
					info.colorCode = format("|cff%02x%02x%02x", 255*color.r, 255*color.g, 255*color.b)
					info.notCheckable = 1
					info.func = Notebook.Frame_DropdownSelect
					UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
	end
end

function Notebook.Frame_SaveButtonOnClick(self, ndata)
	-- Saves the current changes in the editBox to the indicated (or current)
	-- note entry.
	CloseDropDownMenus()
	if NotebookFrame.editing then
		if type(ndata) ~= "table" then
			ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
		end
		if ndata then
			Notebook:UpdateDescription(ndata, NotebookFrame.EditBox:GetText())
			NotebookFrame.editing = nil
			ndata.known = true
			ndata.saved = nil
			Notebook:UpdateNotKnown()
			Notebook:FilterList()
			Notebook.Frame_UpdateList()
			Notebook.Frame_UpdateButtons(nil, true)
		end
	end
end

function Notebook.Frame_AddButtonOnClick(self, ndata)
	-- Adds the indicated (or current) note to the known list.
	CloseDropDownMenus()
	if not NotebookFrame.editing then
		if type(ndata) ~= "table" then
			ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
		end
		if ndata then
			ndata.known = true
			Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
			Notebook:UpdateNotKnown(ndata.title)
			Notebook:FilterList()
			Notebook.Frame_UpdateList()
			Notebook.Frame_UpdateButtons(nil, true)
		end
	end
end

function Notebook.Frame_UpdateButtonOnClick(self, ndata)
	-- Launches the NOTEBOOK_UPDATE_CONFIRM dialog to prompt user about
	-- updating an existing note.
	CloseDropDownMenus()
	if type(ndata) ~= "table" then
		ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
	end
	if ndata then
		local dialogFrame = StaticPopup_Show("NOTEBOOK_UPDATE_CONFIRM", ndata.title, ndata.author)
		if dialogFrame then
			dialogFrame.data = ndata.id
		end
	end
end

function Notebook.Frame_CancelButtonOnClick(self)
	-- Restore the last saved contents of the current note
	CloseDropDownMenus()
	if NotebookFrame.editing then
		local ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
		if ndata then
			Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
			NotebookFrame.editing = nil
			ndata.saved = nil
			Notebook.Frame_UpdateList()
			Notebook.Frame_UpdateButtons(nil, true)
		end
	end
end

function Notebook.Frame_NewButtonOnClick(self)
	-- Launches the NOTEBOOK_NEW_TITLE dialog to prompt user to enter a new
	-- note title
	CloseDropDownMenus()
	_currentTitle = ""
	local dialogFrame = StaticPopup_Show("NOTEBOOK_NEW_TITLE")
	if dialogFrame then
		dialogFrame.data = nil
		dialogFrame:SetWidth(420)
	end
end

function Notebook.Frame_TabButtonOnClick(id)
	-- Called when a tab button is selected, this function switches which set
	-- of filtered list items is show, and switches between the two tab's
	-- selected items, adjusting scrollbar positions, etc., as needed.  This
	-- tab switching code uses the following variables within the
	-- NotebookFrame object:
	--   lastSelectedID = last good selectedID value, used for returning to a
	--                    tab without selecting a new item on the other tab
	--   lastKnownOffset = last offset of Known tab scrollbar
	--   lastRecentOffset = last offset of Recent tab scrollbar
	CloseDropDownMenus()
	local filterMode = _filterBy
	local showText = nil
	local scrollOffset = nil
	local ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
	if ndata then
		NotebookFrame.lastSelectedID = NotebookFrame.selectedID
	else
		ndata = Notebook:FindNoteByID(NotebookFrame.lastSelectedID)
	end

	if id == 1 and _filterBy ~= L.ALL_TAB then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab2)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab3)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab1)
		filterMode = L.ALL_TAB
		if ndata then
			showText = true
		end
		scrollOffset = NotebookFrame.lastKnownOffset
		NotebookFrame.lastRecentOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	elseif id == 2 and _filterBy ~= L.MINE_TAB then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab1)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab3)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab2)
		filterMode = L.MINE_TAB
		if ndata and (ndata.author == _playerName) then
			showText = true
		end
		scrollOffset = NotebookFrame.lastRecentOffset
		NotebookFrame.lastKnownOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	elseif id == 3 and _filterBy ~= L.RECENT_TAB then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab1)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab2)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab3)
		filterMode = L.RECENT_TAB
		if ndata and ndata.recent then
			showText = true
		end
		scrollOffset = NotebookFrame.lastRecentOffset
		NotebookFrame.lastKnownOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	end
	if _filterBy ~= filterMode then
		if showText then
			if NotebookFrame.selectedID ~= ndata.id then
				if NotebookFrame.editing then
					local pdata = Notebook:FindNoteByID(NotebookFrame.selectedID)
					if pdata then
						local text = NotebookFrame.EditBox:GetText()
						if text ~= pdata.description then
							pdata.saved = text
						else
							pdata.saved = nil
						end
					end
				end
				if ndata.saved then
					Notebook.Frame_SetDescriptionText(ndata.saved, ndata.known)
					NotebookFrame.editing = true
				else
					Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
					NotebookFrame.editing = nil
				end
				Notebook.Frame_UpdateButtons(NotebookFrame.editing, ndata.known, ndata.update)
				Notebook.Frame_SetCanSendCheckbox(true, ndata.send)
				NotebookFrame.selectedID = ndata.id
			end
		else
			if NotebookFrame.editing then
				local pdata = Notebook:FindNoteByID(NotebookFrame.selectedID)
				if pdata then
					local text = NotebookFrame.EditBox:GetText()
					if text ~= pdata.description then
						pdata.saved = text
					else
						pdata.saved = nil
					end
				end
			end
			if NotebookFrame.selectedID then
				Notebook.Frame_SetDescriptionText("")
				NotebookFrame.editing = nil
				Notebook.Frame_UpdateButtons(nil, true)
				Notebook.Frame_SetCanSendCheckbox()
				NotebookFrame.selectedID = nil
			end
		end
		_filterBy = filterMode
		Notebook:FilterList()
		Notebook.Frame_UpdateList(nil, scrollOffset, true)
	end
end

function Notebook.Frame_OnUpdate(self)
	-- This function handles sending of messages (to limit send speed) and
	-- cooldown and receive timing.
	local time = GetTime()
	if _sendInProgress then
		if time > _sendCooldownTimer then
			local thisLine = _sendLines[1]
			if thisLine then
				-- Prefix each line with something to assist in identifying it
				-- on the receiving end and to make empty lines get sent.
				if _sendChannel == "BN_WHISPER" then
					BNSendWhisper(_sendTarget, NOTEBOOK_SEND_PREFIX .. thisLine)
				else
					SendChatMessage(NOTEBOOK_SEND_PREFIX .. thisLine, _sendChannel, nil, _sendTarget)
				end
			end
			tremove(_sendLines, 1)
			if #_sendLines > 0 then
				-- More lines to send, set the timer for the next line
				_sendCooldownTimer = time + NOTEBOOK_SEND_LINE_COOLDOWN
			else
				-- All lines sent, set cooldown timer
				_sendInProgress = nil
				_sendCooldownTimer = time + NOTEBOOK_SEND_FINISHED_COOLDOWN
			end
		end
	elseif _sendCooldownTimer then
		if time > _sendCooldownTimer then
			_sendCooldownTimer = nil
			-- If the UI dropdown list is already shown (i.e., the global
			-- DropDownList1 frame is visible then refresh it so that it can
			-- show the Send option again.
			if DropDownList1:IsVisible() then
				CloseDropDownMenus()
				ToggleDropDownMenu(1, nil, NotebookDropDown, "UIParent", NotebookDropDown.offsetX, NotebookDropDown.offsetY)
			end
		end
	end
	if _receiveTimer then
		if time > _receiveTimer then
			_receiveInProgress = nil
			_receiveTimer = nil
		end
	end
	if not _sendInProgress and not _sendCooldownTimer and not _receiveTimer then
		NotebookFrame:SetScript("OnUpdate", nil)
	end
end

function Notebook.Frame_DropdownSelect(self)
	-- Handles each of the options selected in the drop-down menu
	CloseDropDownMenus()
	local ndata = _notesList[NotebookDropDown.noteIndex]
	if not ndata then
		return
	end

	if self.value == CANCEL then
		-- Dummy action for cancel just to close the drop down menus

	elseif self.value == L.SAVE_OPTION then
		-- Save the current description
		Notebook.Frame_SaveButtonOnClick(ndata)

	elseif self.value == L.UPDATE_OPTION then
		-- Update the corresponding note with this one
		Notebook.Frame_UpdateButtonOnClick(ndata)

	elseif self.value == L.ADD_OPTION then
		-- Add the current note
		Notebook.Frame_AddButtonOnClick(self, ndata)

	elseif self.value == L.RENAME_OPTION then
		-- Set current title so that it will be set in the dialog box
		_currentTitle = ndata.title
		local dialogFrame = StaticPopup_Show("NOTEBOOK_NEW_TITLE")
		if dialogFrame then
			dialogFrame.data = ndata.id
			dialogFrame:SetWidth(420)
		end

	elseif self.value == L.DELETE_OPTION then
		-- If its a known entry, prompt for confirmation, otherwise just
		-- remove it
		if ndata.known then
			local dialogFrame = StaticPopup_Show("NOTEBOOK_REMOVE_CONFIRM", ndata.title)
			if dialogFrame then
				dialogFrame.data = ndata.id
			end
		else
			Notebook:RemoveNoteByID(ndata.id)
			Notebook:UpdateNotKnown()
			NotebookFrame.selectedID = nil
			Notebook.Frame_SetDescriptionText("")
			NotebookFrame.editing = nil
			Notebook.Frame_UpdateButtons(nil, true)
			Notebook.Frame_SetCanSendCheckbox()
			Notebook:FilterList()
			Notebook.Frame_UpdateList()
		end

	elseif self.value == L.SEND_TO_INSTANCE then
		Notebook:SendNote(ndata, "INSTANCE_CHAT")

	elseif self.value == L.SEND_TO_RAID then
		Notebook:SendNote(ndata, "RAID")

	elseif self.value == L.SEND_TO_PARTY then
		Notebook:SendNote(ndata, "PARTY")

	elseif self.value == L.SEND_TO_GUILD then
		Notebook:SendNote(ndata, "GUILD")

	elseif self.value == L.SEND_TO_OFFICER then
		Notebook:SendNote(ndata, "OFFICER")

	elseif self.value == L.SEND_TO_TARGET then
		local target = GetUnitName("target", true)
		if target then
			Notebook:SendNote(ndata, "WHISPER", target)
		end

	elseif self.value == L.SEND_TO_PLAYER then
		local dialogFrame = StaticPopup_Show("NOTEBOOK_SEND_TO_PLAYER")
		if dialogFrame then
			dialogFrame.data = ndata.id
		end

	else
		local _, _, option, channelNum, channelName = strfind(self.value, NOTEBOOK_CHANNEL_VALUE_FIND)
		if option == L.SEND_TO_CHANNEL then
			if channelName == "BN_CONVERSATION" then
				return Notebook:SendNote(ndata, "BN_CONVERSATION", channelNum)
			end

			local serverList = { EnumerateServerChannels() }
			local isServerChannel
			for index = 1, #serverList do
				if serverList[index] == channelName then
					isServerChannel = true
					break
				end
			end
			if isServerChannel then
				local dialogFrame = StaticPopup_Show("NOTEBOOK_SERVER_CONFIRM", ndata.title, channelName)
				if dialogFrame then
					dialogFrame.data = {}
					dialogFrame.data.id = ndata.id
					dialogFrame.data.channelNum = channelNum
				end
			else
				Notebook:SendNote(ndata, "CHANNEL", tonumber(channelNum))
			end
		end
	end
end

function Notebook.Frame_TextChanged(self)
	-- Called when the text in the description edit box changes
	if not NotebookFrame.editing and self.hasFocus and NotebookFrame.selectedID then
		-- We are now editing this note, which means we enable the save and
		-- cancel buttons.  Note that we don't need to update the filter list
		-- here because if the note wasn't already on the list then it
		-- wouldn't have been editable.
		local ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
		if ndata then
			-- First work around the timing of setting focus and getting the
			-- text changed notification by seeing if the description is ""
			-- when the editBox text contents is empty.
			if ndata.description ~= "" or self:GetNumLetters() ~= 0 then
				NotebookFrame.editing = true
				Notebook.Frame_UpdateButtons(true, true)
				Notebook.Frame_UpdateList()
			end
		end
	end
end

function Notebook.Frame_OnVerticalScroll(self, arg1)
	-- Under some circumstances, when the OnVerticalScroll handler calls the
	-- scrollbar:SetValue function, the scrollbar calls back into the
	-- OnVerticalScroll handler itself, although in this nexted call arg1 is
	-- set to nil and does not call itself further.  As a result though, the
	-- default implementation of the OnVerticalScroll handler in
	-- UIPanelTemplates.lua will sometimes enable the scroll arrow buttons
	-- when it shouldn't.  This code below works around this by getting the
	-- current scrollbar value after passing it arg1 (so arg1 is thereafter
	-- ignored).  It also accommodates rounding errors in the min/max
	-- positions for robustness.  Note that for some reason we cannot use
	-- greater and less than comparisons in the script in the XML file itself,
	-- which is why this is in its own function here.
	local scrollbar = self.ScrollBar
	scrollbar:SetValue(arg1)
	local min, max = scrollbar:GetMinMaxValues()
	local scroll = scrollbar:GetValue()
	if scroll < (min + 0.1) then
		scrollbar.ScrollUpButton:Disable()
	else
		scrollbar.ScrollUpButton:Enable()
	end
	if scroll > (max - 0.1) then
		scrollbar.ScrollDownButton:Disable()
	else
		scrollbar.ScrollDownButton:Enable()
	end
end

------------------------------------------------------------------------
--	Popup support functions
------------------------------------------------------------------------

function Notebook:GetPopupData(type)
	if type == "PLAYER" then
		if _lastPlayer then
			return _lastPlayer
		end
	elseif type == "TITLE" then
		if _currentTitle then
			return _currentTitle
		end
	end
	return ""
end

function Notebook:HandlePopupInput(type, data, text)
	if text then
		text = strtrim(text)
	end

	if type == "PLAYER" then
		-- Dialog for accepting player name
		text = gsub("%s", "") -- remove spaces
		if text ~= "" then
			local ndata = Notebook:FindNoteByID(data)
			if ndata then
				local presenceID = GetAutoCompletePresenceID(text)
				--print("HandlePopupAccept", type, text, presenceID)
				if presenceID then
					_lastPlayer = presenceID
					Notebook:SendNote(ndata, "BN_WHISPER", presenceID)
				elseif text and text ~= "" then
					_lastPlayer = text
					Notebook:SendNote(ndata, "WHISPER", text)
				end
			end
		end
	elseif type == "TITLE" then
		-- Dialog for accepting new title name.  If the data parameter is not
		-- nil then we are changing the name of an existing note, otherwise we
		-- are doing the "New" dialog with a new note.
		if text ~= "" then
			if data then
				-- Rename of note
				local ndata = Notebook:FindNoteByID(data)
				if ndata and (text ~= ndata.title) then
					if not Notebook:FindByTitle(text) then
						Notebook:Rename(ndata, text)
						Notebook:UpdateNotKnown()
						Notebook.Frame_UpdateButtons(NotebookFrame.editing, ndata.known, ndata.update)
						Notebook:FilterList()
						Notebook.Frame_UpdateList()
					else
						Notebook:Error(format(L.ERR_RENAME_NOT_UNIQUE_FORMAT, text))
					end
				end
			else
				-- Add a new (empty) note
				if not Notebook:FindByTitle(text, true) then
					local ndata = Notebook:AddNote(text, _playerName, date(NOTEBOOK_GETDATE_FORMAT), "", true, _addSavedToRecent, false)
					NotebookFrame.selectedID = ndata.id
					Notebook:FilterList()
					Notebook.Frame_UpdateList(nil, nil, true)
					NotebookFrame.editing = nil
					Notebook.Frame_UpdateButtons(nil, true)
					Notebook.Frame_SetCanSendCheckbox(true, ndata.send)
					Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
					NotebookFrame.EditBox:SetFocus()
				else
					Notebook:Error(format(L.ERR_RENAME_NOT_UNIQUE_FORMAT, text))
				end
			end
		else
			Notebook:Error(L.ERR_RENAME_EMPTY)
		end
	elseif type == "CONFIRM" then
		local ndata = Notebook:FindNoteByID(data)
		if ndata then
			Notebook:RemoveNoteByID(ndata.id)
			Notebook:UpdateNotKnown()
			NotebookFrame.selectedID = nil
			Notebook.Frame_SetDescriptionText("")
			NotebookFrame.editing = nil
			Notebook.Frame_UpdateButtons(nil, true)
			Notebook.Frame_SetCanSendCheckbox()
			Notebook:FilterList()
			Notebook.Frame_UpdateList()
		end
	elseif type == "UPDATE" then
		local ndata = Notebook:FindNoteByID(data)
		if ndata then
			local pdata = Notebook:FindByTitle(ndata.title, true)
			if pdata then
				-- Update description and author, but not send flag
				Notebook:UpdateDescription(pdata, ndata.description)
				pdata.author = ndata.author
				pdata.saved = nil
				pdata.recent = true
				Notebook:UpdateNotKnown(pdata.title)
				NotebookFrame.selectedID = pdata.id
				Notebook.Frame_SetDescriptionText(pdata.description, true)
				NotebookFrame.editing = nil
				Notebook.Frame_UpdateButtons(nil, true)
				Notebook.Frame_SetCanSendCheckbox(true, pdata.send)
				Notebook:FilterList()
				Notebook.Frame_UpdateList()
			end
		end
	elseif type == "SERVER" then
		if data then
			local ndata = Notebook:FindNoteByID(data.id)
			if ndata then
				Notebook:SendNote(ndata, "CHANNEL", tonumber(data.channelNum))
			end
		end
	end
end

------------------------------------------------------------------------
--	Hooked functions
--
--	These functions were intended to allow pasting of item links into Notes.
--	However the EditBox doesn't generate the OnHyperLinkClick event (in fact
--	only the ScrollingMessageFrame appears to do this) which means that once an
--	item was pasted into a Note, it can't easily be displayed through the usual
--	methods (we could add code to determine the location of the link in the
--	frame on a mouse event using a font object with SetText and GetStringWidth
--	for the location parsing, since SetText updates GetStringWidth immediately
--	unlike actions on an EditBox) but that'd be a lot of work.  We'd also need
--	to make sure that the line wrapping code in Notebook.ConvertToLines would
--	never break a hyperlink when doing its wrap calculations, since doing so
--	results in an unrecoverable error in SendChatMessage (have to do a reload
--	to escape out of it).  So for now these functions remain here, but unused.
--	See Notebook.Register for their initialization.
------------------------------------------------------------------------

function Notebook.ChatFrameEditBox_IsVisible(self)
	-- Hooked version of ChatFrameEditBox:IsVisible that (in conjunction with
	-- the hooked ChatFrameEditBox:Insert) allows us to get item links into
	-- Notebook instead of always into the ChatFrameEditBox.  Because the
	-- :IsVisible call is not always associated with :Insert of a link, we
	-- give the original :IsVisible check priority over Notebook having focus.
	if _original_ChatFrameEditBox_IsVisible(self) then
		return true
	elseif IsShiftKeyDown() and NotebookFrame.EditBox:IsVisible() and NotebookFrame.EditBox.hasFocus then
		return true
	end
	return false
end

function Notebook.ChatFrameEditBox_Insert(self, text)
	-- Hooked version of ChatFrameEditBox:Insert that allows us to get item
	-- links into Notebook instead of always into the ChatFrameEditBox.
	if IsShiftKeyDown() and NotebookFrame.EditBox:IsVisible() and NotebookFrame.EditBox.hasFocus then
		NotebookFrame.EditBox:Insert(text)
	else
		_original_ChatFrameEditBox_Insert(self, text)
	end
end

------------------------------------------------------------------------
--	OnEvent handler
------------------------------------------------------------------------

function Notebook.OnEvent(self, event, ...)
	return Notebook[event] and Notebook[event](Notebook, ...) or Notebook:ProcessChatMessage(event, ...)
end

------------------------------------------------------------------------
--	OnLoad function
------------------------------------------------------------------------

function Notebook.OnLoad(self)
	-- Record our frame pointer for later
	NotebookFrame = self

	-- Register for player events
	NotebookFrame:RegisterEvent("ADDON_LOADED")
	NotebookFrame:RegisterEvent("PLAYER_LOGIN")
	NotebookFrame:RegisterEvent("PLAYER_LOGOUT")
end

------------------------------------------------------------------------
--	Macro callable function
------------------------------------------------------------------------

function NotebookSendNote(title, channel, target)
	-- This function is basically a wrapper for Notebook:SendNote, taking a
	-- note title and determining the note to which this applies (looking at
	-- known notes only) and then sending it to the indicated channel and
	-- target. The target can either be a player name (for channel "WHISPER")
	-- or the name of a chat channel (for target "CHANNEL").
	if _sendCooldownTimer then
		return Notebook:Error(L.ERR_SEND_COOLDOWN)
	end
	if not title or title == "" or not channel or channel == "" then
		return Notebook:Error(L.ERR_SEND_INVALID)
	end

	local ndata = Notebook:FindByTitle(title, true)
	if not ndata then
		return Notebook:Error(format(L.ERR_SEND_INVALID_NOTE, title))
	elseif NotebookFrame.selectedID == ndata.id and NotebookFrame.editing then
		return Notebook:Error(L.ERR_SEND_EDITING)

	elseif channel == "INSTANCE" then
		if GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 0 then
			return Notebook:SendNote(ndata, "INSTANCE_CHAT")
		end
		return Notebook:Error(ERR_NOT_IN_INSTANCE_GROUP)

	elseif channel == "RAID" then
		if IsInRaid() then
			if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
				return Notebook:SendNote(ndata, "RAID")
			end
			return Notebook:Error(L.ERR_SEND_RAID_LEADER)
		end
		return Notebook:Error(ERR_NOT_IN_RAID)

	elseif channel == "PARTY" then
		if IsInGroup() and not IsInRaid() then
			return Notebook:CompareOnTitleSendNote(ndata, "PARTY")
		end
		return Notebook:Error(ERR_NOT_IN_GROUP)

	elseif channel == "GUILD" then
		if IsInGuild() then
			return Notebook:CompareOnTitleSendNote(ndata, "GUILD")
		end
		return Notebook:Error(ERR_GUILD_PLAYER_NOT_IN_GUILD)

	elseif channel == "TARGET" then
		if UnitCanCooperate("player", "target") then
			local target = GetUnitName("target", true)
			return Notebook:SendNote(ndata, "WHISPER", target)
		end
		return Notebook:Error(ERR_GENERIC_NO_TARGET) -- TODO: better error message

	elseif channel == "WHISPER" then
		local presenceID = GetAutoCompletePresenceID(target)
		if presenceID then
			return Notebook:SendNote(ndata, "BN_WHISPER", presenceID)
		elseif target and target ~= "" then
			return Notebook:SendNote(ndata, "WHISPER", target)
		end
		return Notebook:Error(L.ERR_SEND_NO_NAME)

	elseif channel == "BN_CONVERSATION" then
		if target and target ~= "" then
			if BNGetConversationInfo(target) then
				return Notebook:SendNote(ndata, "BN_CONVERSATION", target)
			end
			return Notebook:Error(format(L.ERR_SEND_INVALID_CHANNEL, target))
		end
		return Notebook:Error(L.ERR_SEND_NO_CHANNEL)

	elseif channel == "CHANNEL" then
		if target and target ~= "" then
			local channelNum = GetChannelName(target)
			if channelNum and channelNum ~= 0 then
				return Notebook:SendNote(ndata, "CHANNEL", channelNum)
			end
			return Notebook:Error(format(L.ERR_SEND_INVALID_CHANNEL, target))
		end
		return Notebook:Error(L.ERR_SEND_NO_CHANNEL)
	end

	return Notebook:Error(format(ERROR_SEND_UNKNOWN_CHANNEL, channel))
end

------------------------------------------------------------------------
--	Slash command function
------------------------------------------------------------------------

SLASH_NOTEBOOK1 = "/notebook"
SLASH_NOTEBOOK2 = "/note"
SLASH_NOTEBOOK3 = Notebook.SLASH_COMMAND

local SlashHandlers = {
	[L.CMD_DEBUGON] = function(params)
		_debugFrame = params and _G[params] or DEFAULT_CHAT_FRAME
		Notebook:Print(L.CMD_DEBUGON_CONFIRM)
	end,
	[L.CMD_DEBUGOFF] = function()
		_debugFrame = nil
		Notebook:Print(L.CMD_DEBUGOFF_CONFIRM)
	end,
	[L.CMD_SHOW] = function()
		ShowUIPanel(NotebookFrame)
	end,
	[L.CMD_HIDE] = function()
		HideUIPanel(NotebookFrame)
	end,
	[L.CMD_STATUS] = function()
		UpdateAddOnMemoryUsage()
		Notebook:Print(format(L.CMD_STATUS_FORMAT, _notesCount, GetAddOnMemoryUsage(NOTEBOOK) + 0.5))
	end,
	[L.CMD_LIST] = function()
		Notebook:Print(L.CMD_LIST_CONFIRM)
		local filterMode = _filterBy
		_filterBy = L.KNOWN_TAB
		Notebook:FilterList()
		for i = 1, #_filteredList do
			local ndata = _notesList[_filteredList[i]]
			if ndata then
				local text = format(L.CMD_LIST_FORMAT, ndata.title, strlen(ndata.description), ndata.author, Notebook:GetDateText(ndata.date))
				Notebook:Print(false, text)
			end
		end
		if _filterBy ~= filterMode then
			_filterBy = filterMode
			Notebook:FilterList()
		end
	end,
	[L.CMD_SEND] = function(params)
		local title, channel, target = strmatch(params, "(.+) (%S+) (%S+)$")
		if title and channel and target then
			NotebookSendNote(title, channel, target)
		end
	end,
	[L.CMD_WELCOME] = function()
		local ndata = Notebook:FindByTitle(_firstTimeNote.title, true)
		if not ndata then
			local ndata = Notebook:AddNote(_firstTimeNote.title, _firstTimeNote.author, _firstTimeNote.date, _firstTimeNote.description, true, true, false)
			Notebook:UpdateNotKnown()
			Notebook:FilterList()
			Notebook.Frame_UpdateList()
			Notebook.Frame_TabButtonOnClick(1)
			NotebookFrame:Show()
		else
			Notebook:Error(format(L.ERR_PREFIX, _firstTimeNote.title))
		end
	end,
}

SlashCmdList["NOTEBOOK"] = function(text)
	if not text or text == "" then
		return ToggleFrame(NotebookFrame)
	end

	local command, params = strsplit(" ", text, 2)
	if SlashHandlers[command] then
		SlashHandlers[command](params)
	else
		Notebook:Print(NORMAL_FONT_COLOR_CODE .. Notebook.name .. "|r " .. GAME_VERSION_LABEL .. " " .. Notebook.version)
		Notebook:Print(false, Notebook.description)
		for i = 1, #HELP_TEXT do
			Notebook:Print(false, HELP_TEXT[i])
		end
	end
end

------------------------------------------------------------------------
--	Blizzard options panel functions
------------------------------------------------------------------------

do
	local Options = CreateFrame("Frame", "NotebookOptions", InterfaceOptionsFramePanelContainer)
	Options.name = Notebook.name
	Notebook.OptionsPanel = Options
	InterfaceOptions_AddCategory(Options)

	Options:Hide()
	Options:SetScript("OnShow", function(self)
		local Title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		Title:SetPoint("TOPLEFT", 16, -16)
		Title:SetText(Notebook.name)

		local Version = self:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		Version:SetPoint("BOTTOMLEFT", Title, "BOTTOMRIGHT", 16, 0)
		Version:SetPoint("RIGHT", -24, 0)
		Version:SetJustifyH("RIGHT")
		Version:SetText(GAME_VERSION_LABEL .. ": " .. HIGHLIGHT_FONT_COLOR_CODE .. Notebook.version)

		local SubText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		SubText:SetPoint("TOPLEFT", Title, "BOTTOMLEFT", 0, -8)
		SubText:SetPoint("TOPRIGHT", Version, "BOTTOMRIGHT", 0, -8)
		SubText:SetJustifyH("LEFT")
		SubText:SetText(Notebook.description)

		local helpText = ""
		local slash = Notebook.SLASH_COMMAND or "/notebook"
		for i = 1, #HELP_TEXT do
			local command, description = strmatch(HELP_TEXT[i], "%- (%S+) %- (.+)")
			if command and description then
				helpText = format("%s\n\n%s%s %s|r\n%s", helpText, NORMAL_FONT_COLOR_CODE, slash, command, description)
			else
				helpText = helpText .. "\n\n" .. gsub(HELP_TEXT[i], " /([^%s,]+)", NORMAL_FONT_COLOR_CODE .. " /%1|r")
			end
		end
		helpText = strsub(helpText, 3)

		local HelpText = self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		HelpText:SetPoint("TOPLEFT", SubText, "BOTTOMLEFT", 0, -24)
		HelpText:SetPoint("BOTTOMRIGHT", -24, 16)
		HelpText:SetJustifyH("LEFT")
		HelpText:SetJustifyV("TOP")
		HelpText:SetText(helpText)

		self:SetScript("OnShow", nil)
	end)
end