------------------------------------------------------------------------
--	Notebook
--	Allows you to record and share notes in-game
--	Written by Cirk of Doomhammer, 2005-2009
--	Updated by Phanx with permission, 2012
--	http://www.wowinterface.com/downloads/info4544-Notebook.html
------------------------------------------------------------------------

local NOTEBOOK, Notebook = ...
NotebookState = { }

------------------------------------------------------------------------
--	AddOn name and version

local NOTEBOOK_NAME = GetAddOnMetadata( NOTEBOOK, "Title" )
local NOTEBOOK_VERSION = GetAddOnMetadata( NOTEBOOK, "Version" )

------------------------------------------------------------------------
--	Global constants

NOTEBOOK_LIST_BUTTON_COUNT = 7				-- number of buttons in list frame
NOTEBOOK_LIST_BUTTON_HEIGHT = 16			-- height of each button in list frame

------------------------------------------------------------------------
--	Local constants

local NOTEBOOK_DROPDOWN_MAX_CHARS = 48		-- maximum characters in dropdown title
local NOTEBOOK_CHANNEL_VALUE_FORMAT = "%s:%d:%s"
local NOTEBOOK_CHANNEL_VALUE_FIND = "(.+):(%d+):(.+)"
local NOTEBOOK_MAX_LINE_LENGTH = 80			-- maximum characters in one line
local NOTEBOOK_MAX_NUM_LINES = 64			-- maximum number of lines sent from a note
local NOTEBOOK_NEW_LINE = "\n"				-- newline character
local NOTEBOOK_GETDATE_FORMAT = "%y%m%d"	-- see strftime

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

local NotebookFrame					-- The frame pointer
local _serverName					-- set to current realm when loaded
local _playerName					-- set to current playername when known
local _debugFrame					-- debug output chat frame

local _original_ChatFrameEditBox_IsVisible	-- original ChatFrameEditBox:IsVisible()
local _original_ChatFrameEditBox_Insert		-- original ChatFrameEditBox:Insert()

local _notesList
--	notes contents:
--		title			text of title
--		author			who provided or last edited the text
--		date			date at which text was last edited
--		sent			date at which text was last sent
--		id				unique ID for the note
--		description		contents of note
--		known			true if note is in our own database, nil otherwise
--		recent			true if note has been edited/sent recently, nil otherwise
--		send			true if can send, nil otherwise
--		update			true if this is an update for an existing known note, nil otherwise

local _notesCount = 0			-- count of how many notes are in notesList
local _notesLastID = 0			-- last note ID used
local _filteredList = { }		-- filtered list of notes, contains indices into notesList
local _filteredCount = 0
local _filterBy = NOTEBOOK_TEXT.ALL_TAB

local _sendInProgress			-- set when sending a message to someone (nil otherwise)
local _sendCooldownTimer		-- set to time to send next line or to allow next send (nil if not used)
local _sendLines = { }			-- the pending lines to be sent
local _sendChannel				-- channel to use ("GUILD", "PARTY", "CHANNEL", etc.)
local _sendTarget				-- target for send
local _lastPlayer				-- last player we sent a note to
local _currentTitle				-- current title to be edited (if there is one)

local _firstTimeLoad			-- set to true if this Addon has not been run on the current server yet

local _receiveInProgress		-- true when receiving a message
local _receiveTimer				-- set to an expiration time when receiving
local _receiveSender			-- set to the name of the player we are listening to
local _receiveChannel			-- set to the channel we are listening to
local _receiveTarget			-- set to the channel # we are listening to (for chat channels)
local _receiveLinesExpected = 0		-- number of lines expected
local _receiveLines = { }		-- lines so far received
local _receiveTitle				-- title of new note

------------------------------------------------------------------------
--	Configuration flags

local _addSavedToRecent = true		-- false means that only sent and received notes go in the
									-- recent tab, true would add recently saved notes also

------------------------------------------------------------------------
--	First timer's brief manual
------------------------------------------------------------------------

local _firstTimeNote = NOTEBOOK_FIRST_TIME_NOTE

------------------------------------------------------------------------
--	Popup defines (see Blizzard's StaticPopup.lua)
------------------------------------------------------------------------

local _notebookPlayerNamePopup = {
	text = NOTEBOOK_TEXT.ENTER_PLAYER_NAME_TEXT,
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	hasEditBox = 1,
	maxLetters = 12,
	OnShow = function(self)
		local editBox = self.editBox or _G[self:GetName().."EditBox"]
		editBox:SetText(Notebook.GetPopupData("PLAYER"))
		editBox:HighlightText()
		editBox:SetFocus()
		NotebookFrame.NewButton:Disable()
	end,
	OnHide = function(self)
		local editBox = self.editBox or _G[self:GetName().."EditBox"]
		editBox:SetText("")
		NotebookFrame.NewButton:Enable()
		ChatEdit_FocusActiveWindow()
	end,
	OnAccept = function(self, data)
		local editBox = self.editBox or _G[self:GetName().."EditBox"]
		Notebook.HandlePopupAccept("PLAYER", data, string.gsub(editBox:GetText(), "(%s+)$", ""))
	end,
	EditBoxOnEnterPressed = function(self, data)
		Notebook.HandlePopupAccept("PLAYER", data, string.gsub(self:GetText(), "(%s+)$", ""))
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

local _notebookNewTitlePopup = {
	text = NOTEBOOK_TEXT.ENTER_NEW_TITLE_TEXT,
	button1 = TEXT(ACCEPT),
	button2 = TEXT(CANCEL),
	hasEditBox = 1,
	maxLetters = 60,
	OnShow = function(self)
		local editBox = self.editBox or _G[self:GetName().."WideEditBox"]
		editBox:SetText(Notebook.GetPopupData("TITLE"))
		editBox:HighlightText()
		editBox:SetFocus()
		NotebookFrame.NewButton:Disable()
	end,
	OnHide = function(self)
		local editBox = self.editBox or _G[self:GetName().."EditBox"]
		editBox:SetText("")
		NotebookFrame.NewButton:Enable()
		ChatEdit_FocusActiveWindow()
	end,
	OnAccept = function(self, data)
		local editBox = self.editBox or _G[self:GetName().."EditBox"]
		Notebook.HandlePopupAccept("TITLE", data, string.gsub(editBox:GetText(), "(%s+)$", ""))
	end,
	EditBoxOnEnterPressed = function(self, data)
		Notebook.HandlePopupAccept("TITLE", data, string.gsub(self:GetText(), "(%s+)$", ""))
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

local _notebookConfirmRemovePopup = {
	text = NOTEBOOK_TEXT.CONFIRM_REMOVE_FORMAT,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook.HandlePopupAccept("CONFIRM", data)
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

local _notebookConfirmUpdatePopup = {
	text = NOTEBOOK_TEXT.CONFIRM_UPDATE_FORMAT,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook.HandlePopupAccept("UPDATE", data)
	end,
	timeout = 60,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
	showAlert = 1,
}

local _notebookConfirmServerPopup = {
	text = NOTEBOOK_TEXT.CONFIRM_SERVER_CHANNEL_FORMAT,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	sound = "igCharacterInfoOpen",
	OnAccept = function(self, data)
		Notebook.HandlePopupAccept("SERVER", data)
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

function Notebook.Register()
	-- Register for events and hook functions
	NotebookFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
	NotebookFrame:RegisterEvent("CHAT_MSG_RAID")
	NotebookFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
	NotebookFrame:RegisterEvent("CHAT_MSG_PARTY")
	NotebookFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	NotebookFrame:RegisterEvent("CHAT_MSG_GUILD")
	NotebookFrame:RegisterEvent("CHAT_MSG_OFFICER")
	NotebookFrame:RegisterEvent("CHAT_MSG_WHISPER")
	NotebookFrame:RegisterEvent("CHAT_MSG_CHANNEL")

	-- See the comments for the Notebook.ChatFrameEditBox_IsVisible and
	-- Notebook.ChatFrameEditBox_Insert functions as to why these are disabled
	-- for now.
--	if (not _original_ChatFrameEditBox_IsVisible) then
--		_original_ChatFrameEditBox_IsVisible = ChatFrameEditBox.IsVisible
--		ChatFrameEditBox.IsVisible = Notebook.ChatFrameEditBox_IsVisible
--	end
--	if (not _original_ChatFrameEditBox_Insert) then
--		_original_ChatFrameEditBox_Insert = ChatFrameEditBox.Insert
--		ChatFrameEditBox.Insert = Notebook.ChatFrameEditBox_Insert
--	end
end

function Notebook.UnpackDate(packedDate)
	-- Notebook uses a date format of yymmdd, returned automatically by
	-- calling date("%y%m%d"), however we unpack this into a more human
	-- readable form.
	local _, _, y10, y1, m10, m1, d10, d1 = string.find(packedDate, "(%d)(%d)(%d)(%d)(%d)(%d)")
	local month = tonumber(m10)*10+tonumber(m1)
	local day = tonumber(d10)*10+tonumber(d1)
	return day.." "..NOTEBOOK_TEXT["MONTHNAME_"..month].." 20"..y10..y1
end

function Notebook.GenerateSignature(text, numLines)
	-- Generates a "secret" signature version of the provided text string that
	-- notebook can automatically recognize.
	return NOTEBOOK_HEADER_PRE..text..NOTEBOOK_HEADER_POST..string.rep(NOTEBOOK_HEADER_LINECOUNT_CHAR, numLines)
end

function Notebook.Reset()
	-- Resets the Notebook back to empty
	_notesList = { }
	_filteredList = { }
	_notesCount = 0
	_filteredCount = 0
	_notesLastID = 0
end

function Notebook.SaveData()
	-- Saves the currently known entries in the Notebook (not-known are not saved)
	local notes = { }
	for index, ndata in ipairs(_notesList) do
		if (ndata.known) then
			local saveNote = { }
			saveNote.author = ndata.author
			saveNote.date = ndata.date
			saveNote.sent = ndata.sent
			if (string.len(ndata.description) < NOTEBOOK_MAX_STRING_LENGTH) then
				saveNote.description = ndata.description
			else
				local data = ndata.description
				local result = { }
				while (string.len(data or "") > 0) do
					local prefix = string.sub(data, 1, NOTEBOOK_MAX_STRING_LENGTH)
					data = string.sub(data, NOTEBOOK_MAX_STRING_LENGTH + 1)
					table.insert(result, prefix)
				end
				saveNote.description = result
			end
			if (ndata.send) then
				saveNote.send = 1
			end
			notes[ndata.title] = saveNote
		end
	end
	NotebookState.Notes = notes
	NotebookState.Servers = nil
end

function Notebook.LoadOneNote(title, ndata)
	-- Given a saved note defined by a title and by ndata, this function
	-- creates a note structure for use in-memory.  The _notesLastID value is
	-- also automatically incremented to form the note's id value
	local newNote = { }
	newNote.title = title
	newNote.author = ndata.author
	newNote.date = ndata.date
	newNote.sent = ndata.sent
	if (type(ndata.description) == "string") then
		newNote.description = ndata.description
	else
		newNote.description = ""
		if (type(ndata.description) == "table") then
			for index, sdata in ipairs(ndata.description) do
				newNote.description = newNote.description..sdata
			end
		end
	end
	newNote.known = true
	if (ndata.send) then
		newNote.send = true
	end
	_notesLastID = _notesLastID + 1
	newNote.id = _notesLastID
	return newNote
end

function Notebook.LoadData()
	-- Loads all the notes from the current saved variables file.  This
	-- function implements code to read the previous save file format (where
	-- notes were saved per server) and handles notes with the same name from
	-- different servers by appending the server name.
	Notebook.Reset()
	for entry, ndata in pairs(NotebookState.Notes) do
		_notesCount = _notesCount + 1
		_notesList[_notesCount] = Notebook.LoadOneNote(entry, ndata)
	end
	if (NotebookState.Servers) then
		for server, sdata in pairs(NotebookState.Servers) do
			if (sdata.Notes) then
				for entry, ndata in pairs(sdata.Notes) do
					local title = entry
					repeat
						local found = nil
						for index, newdata in ipairs(_notesList) do
							if (newdata.title == title) then
								title = title.." -"..server
								found = true
								break
							end
						end
					until not found
					_notesCount = _notesCount + 1
					_notesList[_notesCount] = Notebook.LoadOneNote(title, ndata)
				end
			end
		end
	end
	if (_notesCount > 0) then
		_firstTimeLoad = nil
	end
end

function Notebook.CalculateChecksum(string)
	if (_debugFrame) then
		_debugFrame:AddMessage(NOTEBOOK_TEXT.DEBUG.."Notebook.CalculateChecksum is still TO DO")
	end
	return 0
end

function Notebook.FindByTitle(title, known)
	-- Returns the entry of the note with the matching title or nil if not found.  If known is true then only known entries are checked.
	if (known) then
		for index, ndata in ipairs(_notesList) do
			if (ndata.known and (ndata.title == title)) then
				return ndata
			end
		end
	else
		for index, ndata in ipairs(_notesList) do
			if (ndata.title == title) then
				return ndata
			end
		end
	end
	return nil
end

function Notebook.FindByID(id)
	-- Returns the entry with the matching id, or nil if not found
	if (id) then
		for index, ndata in ipairs(_notesList) do
			if (ndata.id == id) then
				return ndata
			end
		end
	end
	return nil
end

function Notebook.Add(title, author, date, description, known, recent, send)
	-- Adds a new entry to the notebook.  Note that it is the callers
	-- responsibility to make sure the title is valid and unique!  The
	-- function then returns the newly added note entry.
	local newNote = { }
	newNote.title = title
	newNote.author = author
	newNote.date = date
	newNote.description = description
	newNote.known = known
	newNote.recent = recent
	newNote.send = send
	_notesLastID = _notesLastID + 1
	newNote.id = _notesLastID
	_notesCount = _notesCount + 1
	_notesList[_notesCount] = newNote
	return newNote
end

function Notebook.RemoveByID(id)
	-- Removes (deletes) the note with the indicated id from the list.  Note
	-- that it appears that sometimes table.remove does not work properly (or
	-- at least reliably), at least when the index being removed is not the
	-- first or last index, so we do it the somewhat slower way of recreating
	-- the table entries without the one we don't want.
	local newList = { }
	for index = 1, _notesCount do
		local ndata = _notesList[index]
		if (ndata.id ~= id) then
			table.insert(newList, ndata)
		end
		_notesList[index] = nil
	end
	_notesCount = #newList
	_notesList = newList
end

function Notebook.Rename(ndata, title)
	-- Renames the indicated note entry with the given title.  It is the
	-- caller's responsibility to ensure that the new title is valid and
	-- unique.
	ndata.title = title
	if (_addSavedToRecent) then
		ndata.recent = true
	end
end

function Notebook.UpdateDescription(ndata, description)
	-- Updates the description in the note, and also sets the author (to the
	-- player) and date (to the current server date).
	ndata.description = description
	ndata.author = _playerName
	ndata.date = date(NOTEBOOK_GETDATE_FORMAT)
	if (_addSavedToRecent) then
		ndata.recent = true
	end
end

function Notebook.CompareDescription(desc1, desc2)
	-- Does a simple compare on the two passed descriptions to see if they are
	-- equal (or close enough to equal) by converting all whitespace sequences
	-- in the descriptions to single spaces.  If the two strings are then
	-- equal, the function will return true.
	local text1 = string.gsub(desc1.." ", "(%s+)", " ")
	local text2 = string.gsub(desc2.." ", "(%s+)", " ")
	if (text1 == text2) then
		return true
	end
end

function Notebook.CompareOnTitle(index1, index2)
	-- Filters the list into ascending title order.  If the title's are the
	-- same then we choose the known one first.  Note that it is important to
	-- check for the indices being different because the sort algorithm
	-- doesn't like sorting on secondary parameters.
	if (index1 == index2) then
		return false
	end
	if (_notesList[index1].title == _notesList[index2].title) then
		return _notesList[index1].known
	end
	return _notesList[index1].title < _notesList[index2].title
end

function Notebook.FilterList()
	_filteredList = { }
	_filteredCount = 0
	if (_filterBy == NOTEBOOK_TEXT.KNOWN_TAB) then
		for index, ndata in ipairs(_notesList) do
			if (ndata.known) then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = index
			end
		end
	elseif (_filterBy == NOTEBOOK_TEXT.MINE_TAB) then
		for index, ndata in ipairs(_notesList) do
			if (ndata.author == _playerName) then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = index
			end
		end
	elseif (_filterBy == NOTEBOOK_TEXT.RECENT_TAB) then
		for index, ndata in ipairs(_notesList) do
			if (ndata.recent) then
				_filteredCount = _filteredCount + 1
				_filteredList[_filteredCount] = index
			end
		end
	else
		for index, ndata in ipairs(_notesList) do
			table.insert(_filteredList, index)
		end
		_filteredCount = _notesCount
	end
	table.sort(_filteredList, Notebook.CompareOnTitle)
end

function Notebook.UpdateNotKnown(removeTitle)
	-- This function looks through all the notes currently not known, and
	-- determines whether they should be flagged for adding or for updating.
	-- If a note that is not-known is identical (title and description) to a
	-- existing known note, then the not-known note will be discarded, and the
	-- recent status transfered from it to the known note instead.  If the
	-- removeTitle parameter is set, then any not known entries with matching
	-- titles will be automatically removed (irrespective of their
	-- description)
	local removeList = { }
	for index, ndata in ipairs(_notesList) do
		if (not ndata.known) then
			if (ndata.title == removeTitle) then
				table.insert(removeList, ndata.id)
			else
				local pdata = Notebook.FindByTitle(ndata.title, true)
				if (pdata) then
					if (Notebook.CompareDescription(pdata.description, ndata.description)) then
						if (ndata.recent) then
							pdata.recent = true
						end
						table.insert(removeList, ndata.id)
					else
						ndata.update = true
					end
				else
					ndata.update = nil
				end
			end
		end
	end
	for index, id in ipairs(removeList) do
		Notebook.RemoveByID(id)
	end
end

function Notebook.ConvertToLines(text, maxLines, debug)
	-- Given a text string, this function converts it into a line-formatted
	-- table, suitable for sending to a target channel.  The formatting
	-- enforces a maximum per-line length of NOTEBOOK_MAX_NUM_LINES (with
	-- word-wrapping), reduces multiple empty lines to single empty lines,
	-- and enforces a maximum of maxLines in the resulting table, which is
	-- then returned.
	local lines = { }
	local lastLine = nil
	local numLines = 0
	while (text and (text ~= "")) do
		local thisLine
		local checkWrap
		local start = string.find(text, NOTEBOOK_NEW_LINE, 1, true)
		if (start) then
			if (start <= NOTEBOOK_MAX_LINE_LENGTH) then
				thisLine = string.sub(text, 1, start - 1)
				text = string.sub(text, start + 1)
				checkWrap = nil
			else
				thisLine = string.sub(text, 1, NOTEBOOK_MAX_LINE_LENGTH)
				if (start == NOTEBOOK_MAX_LINE_LENGTH + 1) then
					text = string.sub(text, NOTEBOOK_MAX_LINE_LENGTH + 2)
					checkWrap = nil
				else
					text = string.sub(text, NOTEBOOK_MAX_LINE_LENGTH + 1)
					checkWrap = true
				end
			end
		else
			if (string.len(text) > NOTEBOOK_MAX_LINE_LENGTH) then
				thisLine = string.sub(text, 1, NOTEBOOK_MAX_LINE_LENGTH)
				text = string.sub(text, NOTEBOOK_MAX_LINE_LENGTH + 1)
				checkWrap = true
			else
				thisLine = text
				text = ""
				checkWrap = nil
			end
		end
		if (checkWrap) then
			-- Do word wrapping and also whitespace stripping from the end and
			-- start of the broken line.
			local thisLength = string.find(thisLine, "[%s]+[^%s]*$")
			if (thisLength) then
				text = string.sub(thisLine, thisLength + 1)..text
				thisLine = string.sub(thisLine, 1, thisLength - 1)..NOTEBOOK_SEND_POSTFIX
				local textStart = string.find(text, "[^%s]")
				if (textStart) then
					text = string.sub(text, textStart)
				end
			end
		else
			-- Strip any whitespace from the end of the line (no need to send
			-- spaces at the end of a line)
			thisLine = string.gsub(thisLine, "(%s+)$", "")
		end
		if (thisLine == "") then
			if (lastLine ~= "") then
				numLines = numLines + 1
				lines[numLines] = ""
			end
		else
			numLines = numLines + 1
			lines[numLines] = thisLine
		end
		lastLine = thisLine
		if (maxLines and (numLines > maxLines)) then
			-- We wait until we get numLines greater than maxLines to allow
			-- for trailing "empty" lines to not show as an error.
			if (debug) then
				_debugFrame:AddMessage(NOTEBOOK_TEXT.DEBUG.."--> limiting number of lines to "..maxLines)
			end
			lines[numLines] = nil
			numLines = maxLines
			break
		end
	end
	-- Remove any trailing empty lines (there can only be one at most)
	if (lines[numLines] == "") then
		lines[numLines] = nil
		numLines = numLines - 1
	end
	return lines, numLines
end

function Notebook.SendNote(ndata, channel, target)
	-- Formats the provided note to be sent using the indicated channel and
	-- target (if needed).  Note that the actual sending of all text lines
	-- (apart from the title) is done via timer in OnUpdate.
	if (_debugFrame) then
		if (target) then
			_debugFrame:AddMessage(NOTEBOOK_TEXT.DEBUG.."Notebook.SendNote("..ndata.title..", "..channel..", "..target..")")
		else
			_debugFrame:AddMessage(NOTEBOOK_TEXT.DEBUG.."Notebook.SendNote("..ndata.title..", "..channel..")")
		end
	end
	-- Convert into lines table for sending
	local lines, numLines = Notebook.ConvertToLines(ndata.description, NOTEBOOK_MAX_NUM_LINES, _debugFrame)
	-- Format title string with our "secret" notebook code for any other
	-- notebooks to recognize.
	SendChatMessage(Notebook.GenerateSignature(ndata.title, numLines), channel, nil, target)
	if (numLines > 0) then
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
	Notebook.FilterList()
	Notebook.Frame_UpdateList()
end

------------------------------------------------------------------------
--	Chat event parsing functions
------------------------------------------------------------------------

function Notebook.ChatMessageHandler(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14)
	-- Called for raid, party, guild, whisper, and channel events.  Note that
	-- system channels (e.g., General, Trade, etc.) are indicated by arg7
	-- being non-zero, and are always ignored.  Similarly anything sent by
	-- ourselves should also be ignored.
	local channel = string.sub(event, 10)
	if ((tonumber(arg7) ~= 0) or (arg2 == _playerName)) then
		return
	end
	if (not _receiveInProgress) then
		local _, _, title, countString = string.find(arg1, NOTEBOOK_HEADER_PATTERN)
		if (title and countString) then
			local lineCount = string.len(countString)
			if ((lineCount >= 1) and (lineCount <= NOTEBOOK_MAX_NUM_LINES)) then
				_receiveInProgress = true
				_receiveTimer = GetTime() + (NOTEBOOK_SEND_LINE_COOLDOWN*lineCount) + NOTEBOOK_RECEIVE_TIMEOUT
				_receiveSender = arg2
				_receiveChannel = channel
				_receiveTarget = arg8
				_receiveLinesExpected = lineCount
				_receiveLines = { }
				_receiveTitle = title
				NotebookFrame:SetScript("OnUpdate", Notebook.Frame_OnUpdate)
			end
		end
	elseif ((arg2 == _receiveSender) and (_receiveChannel == channel) and (_receiveTarget == arg8)) then
		if (string.sub(arg1, 1, 1) == NOTEBOOK_SEND_PREFIX) then
			table.insert(_receiveLines, string.sub(arg1, 2))
			if (#_receiveLines == _receiveLinesExpected) then
				if (_debugFrame) then
					_debugFrame:AddMessage(NOTEBOOK_TEXT.DEBUG.."Received note \"".._receiveTitle.."\" from ".._receiveSender)
				end
				_receiveInProgress = nil
				_receiveTimer = nil
				description = ""
				for index, text in ipairs(_receiveLines) do
					local len = string.len(text)
					if (string.sub(text, len) == NOTEBOOK_SEND_POSTFIX) then
						description = description..string.sub(text, 1, len - 1).." "
					else
						description = description..text..NOTEBOOK_NEW_LINE
					end
				end
				-- Check to see if we have this entry already
				local addNote = true
				for index, ndata in ipairs(_notesList) do
					if (ndata.title == _receiveTitle) then
						if (Notebook.CompareDescription(ndata.description, description)) then
							-- Same note already exists, so don't add it again
							ndata.recent = true
							addNote = nil
							break
						end
					end
				end
				if (addNote) then
					if (DEFAULT_CHAT_FRAME) then
						DEFAULT_CHAT_FRAME:AddMessage(format(NOTEBOOK_TEXT.NOTE_RECEIVED_FORMAT, _receiveTitle, _receiveSender))
					end
					Notebook.Add(_receiveTitle, _receiveSender, date(NOTEBOOK_GETDATE_FORMAT), description, false, true, true)
				end
				Notebook.UpdateNotKnown()
				Notebook.FilterList()
				Notebook.Frame_UpdateList()
			end
		end
	end
end

------------------------------------------------------------------------
--	Local utility functions
------------------------------------------------------------------------

function Notebook.GetNextParam(text)
	-- Extracts the next parameter out of the passed text, and returns it and
	-- the rest of the string
	for param, remain in string.gmatch(text, "(%w+) +(.*)") do
		return param, remain
	end
	return text
end

------------------------------------------------------------------------
--	Initialization functions
------------------------------------------------------------------------

function Notebook.VariablesLoaded()
	if (not NotebookState) then
		NotebookState = { }
	end
	if (not NotebookState.Notes) then
		NotebookState.Notes = { }
		_firstTimeLoad = true
	end
	_notesList = NotebookState.Notes
end

function Notebook.PlayerLogin()
	-- Load notes
	Notebook.LoadData()
	if (_firstTimeLoad) then
		Notebook.Add(_firstTimeNote.title, _firstTimeNote.author, _firstTimeNote.date, _firstTimeNote.description, true, false, false)
	end
	Notebook.FilterList()
	Notebook.Frame_UpdateList()

	-- Register for required events now
	Notebook.Register()
end

function Notebook.PlayerLogout()
	Notebook.SaveData()
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
	if (known) then
		NotebookFrame.TextScrollFrame:Hide()
		NotebookFrame.EditScrollFrame:Show()
		NotebookFrame.EditBox:ClearFocus()
		if (text == "") then
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
	if (enable) then
		NotebookFrame.CanSendCheckButton:SetChecked(send)
		NotebookFrame.CanSendCheckButton:Enable()
		NotebookFrame.CanSendCheckButton.Text:SetTextColor(_colorTextEnabled.r, _colorTextEnabled.g, _colorTextEnabled.b)
		if (GameTooltip:IsOwned(NotebookFrame.CanSendCheckButton)) then
			if (send) then
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
	if (editing) then
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript( "OnClick", Notebook.Frame_SaveButtonOnClick )
		NotebookFrame.SaveButton:SetText( NOTEBOOK_TEXT.SAVE_BUTTON )
		NotebookFrame.SaveButton.tooltipText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Enable()
	elseif (known) then
		NotebookFrame.SaveButton:Disable()
		NotebookFrame.SaveButton:SetScript( "OnClick", Notebook.Frame_SaveButtonOnClick )
		NotebookFrame.SaveButton:SetText( NOTEBOOK_TEXT.SAVE_BUTTON )
		NotebookFrame.SaveButton.tooltipText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Disable()
	elseif (update) then
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript( "OnClick", Notebook.Frame_UpdateButtonOnClick )
		NotebookFrame.SaveButton:SetText( NOTEBOOK_TEXT.UPDATE_BUTTON )
		NotebookFrame.SaveButton.tooltipText = NOTEBOOK_TEXT.UPDATE_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = NOTEBOOK_TEXT.UPDATE_BUTTON_TOOLTIP
		NotebookFrame.CancelButton:Disable()
	else
		NotebookFrame.SaveButton:Enable()
		NotebookFrame.SaveButton:SetScript( "OnClick", Notebook.Frame_AddButtonOnClick )
		NotebookFrame.SaveButton:SetText( NOTEBOOK_TEXT.ADD_BUTTON )
		NotebookFrame.SaveButton.tooltipText = NOTEBOOK_TEXT.ADD_BUTTON_TOOLTIP
		NotebookFrame.SaveButton.newbieText = NOTEBOOK_TEXT.ADD_BUTTON_TOOLTIP
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
	if (not NotebookFrame:IsShown()) then
		return
	end
	local currentOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	if (not offset) then
		offset = currentOffset
	end
	if ((offset + NOTEBOOK_LIST_BUTTON_COUNT) > _filteredCount) then
		offset = _filteredCount - NOTEBOOK_LIST_BUTTON_COUNT
		if (offset < 0) then
			offset = 0
		end
	end
	if (autoScroll and NotebookFrame.selectedID) then
		local index = nil
		for i = 1, _filteredCount do
			local ndata = _notesList[_filteredList[i]]
			if (ndata.id == NotebookFrame.selectedID) then
				index = i
				break
			end
		end
		if (index) then
			local newOffset = offset
			if ((offset + NOTEBOOK_LIST_BUTTON_COUNT) < index) then
				offset = index - NOTEBOOK_LIST_BUTTON_COUNT
			elseif (index < offset) then
				offset = index - 1
			end
		end
	end
	if (offset ~= currentOffset) then
		FauxScrollFrame_SetOffset(NotebookFrame.ListScrollFrame, offset)
		NotebookFrame.ListScrollBar:SetValue(offset * NOTEBOOK_LIST_BUTTON_HEIGHT)
	end

	-- Update buttons
	NotebookFrame.selectedButton = nil
	for i = 1, NOTEBOOK_LIST_BUTTON_COUNT do
		local button = NotebookFrame.ListButtons[i]
		local index = i + offset
		if (index <= _filteredCount) then
			local titleText = button.TitleText
			local titleHighlight = button.TitleHighlight
			local ndata = _notesList[_filteredList[index]]
			button.nindex = _filteredList[index]
			if (ndata.saved or (NotebookFrame.editing and (NotebookFrame.selectedID == ndata.id))) then
				titleText:SetText(ndata.title..NOTEBOOK_TEXT.TITLE_CHANGE_NOT_SAVED)
			else
				titleText:SetText(ndata.title)
			end
			if (ndata.known) then
				titleText:SetTextColor(_colorKnown.r, _colorKnown.g, _colorKnown.b)
				titleHighlight:SetVertexColor(_colorKnown.r, _colorKnown.g, _colorKnown.b, _colorKnown.a)
			else
				titleText:SetTextColor(_colorNotKnown.r, _colorNotKnown.g, _colorNotKnown.b)
				titleHighlight:SetVertexColor(_colorNotKnown.r, _colorNotKnown.g, _colorNotKnown.b, _colorNotKnown.a)
			end
			if (NotebookFrame.selectedID == ndata.id) then
				NotebookFrame.selectedButton = button
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			local tooltipText
			if (ndata.known) then
				if (ndata.author == _playerName) then
					tooltipText = format(NOTEBOOK_TEXT.DETAILS_DATE_KNOWN_SAVED_FORMAT, Notebook.UnpackDate(ndata.date))
				else
					tooltipText = format(NOTEBOOK_TEXT.DETAILS_DATE_KNOWN_UPDATED_FORMAT, Notebook.UnpackDate(ndata.date), ndata.author)
				end
			else
				tooltipText = format(NOTEBOOK_TEXT.DETAILS_DATE_UNSAVED_FORMAT, Notebook.UnpackDate(ndata.date), ndata.author)
			end
			if (ndata.sent) then
				tooltipText = tooltipText.."\n"..format(NOTEBOOK_TEXT.DETAILS_SENT_FORMAT, Notebook.UnpackDate(ndata.sent))
			end
			if (not ndata.known) then
				tooltipText = tooltipText.."\n"..NOTEBOOK_TEXT.DETAILS_NOT_KNOWN_TEXT
			end
			tooltipText = tooltipText.."\n"..format(NOTEBOOK_TEXT.DETAILS_SIZE_FORMAT, string.len(ndata.description))
			button.tooltipText = tooltipText
			if (GameTooltip:IsOwned(button)) then
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
	if (NotebookFrame.selectedID ~= ndata.id) then
		if (NotebookFrame.editing) then
			local pdata = Notebook.FindByID(NotebookFrame.selectedID)
			if (pdata) then
				local text = NotebookFrame.EditBox:GetText()
				if (text ~= pdata.description) then
					pdata.saved = text
				else
					pdata.saved = nil
				end
			end
		end
		if (ndata.saved) then
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
	if (clicked == "RightButton") then
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
	local ChatTypeInfo = getmetatable(ChatTypeInfo).__index -- Blizzard stupidity in 5.1

	-- Called by the UI dropdown code when building the dropdown menu, it sets
	-- the UIDROPDOWNMENU_MENU_LEVEL (1 to N) and UIDROPDOWNMENU_MENU_VALUE
	-- (set to passed text string) fields as needed for the various menus and
	-- sub-menus
	local info = UIDropDownMenu_CreateInfo()
	local ndata = _notesList[NotebookDropDown.noteIndex]

	if (UIDROPDOWNMENU_MENU_LEVEL == 1) then
		-- Send options sub-menu.  This is disabled when the note has been
		-- edited but not saved, we are in send cooldown, or the note is not
		-- flagged for sending.
		info.text = NOTEBOOK_TEXT.SEND_OPTION
		info.notCheckable = 1
		info.keepShownOnClick = 1
		if (NotebookFrame.editing or _sendCooldownTimer or not ndata.send) then
			info.disabled = 1
			info.hasArrow = nil
		else
			info.hasArrow = 1
		end
		UIDropDownMenu_AddButton(info)

		-- Save/Add/Update option.
		info.disabled = nil
		info.hasArrow = nil
		if (ndata.known) then
			info.text = NOTEBOOK_TEXT.SAVE_OPTION
			info.value = NOTEBOOK_TEXT.SAVE_OPTION
			if (not NotebookFrame.editing) then
				info.disabled = 1
			end
		elseif (ndata.update) then
			info.text = NOTEBOOK_TEXT.UPDATE_OPTION
			info.value = NOTEBOOK_TEXT.UPDATE_OPTION
		else
			info.text = NOTEBOOK_TEXT.ADD_OPTION
			info.value = NOTEBOOK_TEXT.ADD_OPTION
		end
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Rename option
		info.disabled = nil
		info.text = NOTEBOOK_TEXT.RENAME_OPTION
		info.value = NOTEBOOK_TEXT.RENAME_OPTION
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Delete option
		info.text = NOTEBOOK_TEXT.DELETE_OPTION
		info.value = NOTEBOOK_TEXT.DELETE_OPTION
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

		-- Cancel option
		info.text = CANCEL
		info.value = CANCEL
		info.func = Notebook.Frame_DropdownSelect
		UIDropDownMenu_AddButton(info)

	elseif (UIDROPDOWNMENU_MENU_LEVEL == 2) then
		if (UIDROPDOWNMENU_MENU_VALUE == NOTEBOOK_TEXT.SEND_OPTION) then
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = 1

			-- Send to target
			info.text = NOTEBOOK_TEXT.SEND_TO_TARGET
			info.value = NOTEBOOK_TEXT.SEND_TO_TARGET
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["WHISPER"].r * 255, ChatTypeInfo["WHISPER"].g * 255, ChatTypeInfo["WHISPER"].b * 255 )
			info.disabled = (not UnitCanCooperate("player", "target")) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to player
			info.text = NOTEBOOK_TEXT.SEND_TO_PLAYER
			info.value = NOTEBOOK_TEXT.SEND_TO_PLAYER
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["WHISPER"].r * 255, ChatTypeInfo["WHISPER"].g * 255, ChatTypeInfo["WHISPER"].b * 255 )
			info.disabled = nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to instance
			info.text = NOTEBOOK_TEXT.SEND_TO_INSTANCE
			info.value = NOTEBOOK_TEXT.SEND_TO_INSTANCE
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["INSTANCE_CHAT"].r * 255, ChatTypeInfo["INSTANCE_CHAT"].g * 255, ChatTypeInfo["INSTANCE_CHAT"].b * 255 )
			info.disabled = (GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) == 0) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to party
			info.text = NOTEBOOK_TEXT.SEND_TO_PARTY
			info.value = NOTEBOOK_TEXT.SEND_TO_PARTY
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["PARTY"].r * 255, ChatTypeInfo["PARTY"].g * 255, ChatTypeInfo["PARTY"].b * 255 )
			info.disabled = (IsInRaid() or not IsInGroup()) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to raid (only if you are leader or officer)
			info.text = NOTEBOOK_TEXT.SEND_TO_RAID
			info.value = NOTEBOOK_TEXT.SEND_TO_RAID
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["RAID"].r * 255, ChatTypeInfo["RAID"].g * 255, ChatTypeInfo["RAID"].b * 255 )
			info.disabled = (not IsInRaid() or not UnitIsGroupLeader("player") or not UnitIsGroupAssistant("player")) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to guild
			info.text = NOTEBOOK_TEXT.SEND_TO_GUILD
			info.value = NOTEBOOK_TEXT.SEND_TO_GUILD
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["GUILD"].r * 255, ChatTypeInfo["GUILD"].g * 255, ChatTypeInfo["GUILD"].b * 255 )
			info.disabled = (not IsInGuild()) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to officer
			info.text = NOTEBOOK_TEXT.SEND_TO_OFFICER
			info.value = NOTEBOOK_TEXT.SEND_TO_OFFICER
			info.colorCode = format( "\124cff%02x%02x%02x", ChatTypeInfo["OFFICER"].r * 255, ChatTypeInfo["OFFICER"].g * 255, ChatTypeInfo["OFFICER"].b * 255 )
			info.disabled = (not IsInGuild()) and 1 or nil
			info.func = Notebook.Frame_DropdownSelect
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			-- Send to channel
			info.text = NOTEBOOK_TEXT.SEND_TO_CHANNEL
			info.value = NOTEBOOK_TEXT.SEND_TO_CHANNEL
			info.colorCode = nil
			info.disabled = nil
			info.func = nil
			info.hasArrow = 1
			info.keepShownOnClick = 1
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end

	elseif (UIDROPDOWNMENU_MENU_LEVEL == 3) then
		if (UIDROPDOWNMENU_MENU_VALUE == NOTEBOOK_TEXT.SEND_TO_CHANNEL) then
			local channelList = {GetChannelList()}
			for index=1, #channelList, 2 do
				local channelNum = channelList[index]
				local channelName = channelList[index + 1]
				local displayNum = channelNum
				if (Chatmanager and Chatmanager.GetChannelInfo) then
					displayNum = Chatmanager.GetChannelInfo(channelNum)
				end
				local color = ChatTypeInfo["CHANNEL"..channelNum]
				info = UIDropDownMenu_CreateInfo()
				info.text = format(NOTEBOOK_TEXT.CHANNEL_NAME_FORMAT, displayNum, channelName)
				info.value = format(NOTEBOOK_CHANNEL_VALUE_FORMAT, NOTEBOOK_TEXT.SEND_TO_CHANNEL, channelNum, channelName)
				info.colorCode = format("|cff%02x%02x%02x", 255*color.r, 255*color.g, 255*color.b)
				info.notCheckable = 1
				info.func = Notebook.Frame_DropdownSelect
				UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
			end
		end
	end
end

function Notebook.Frame_SaveButtonOnClick(self, ndata)
	-- Saves the current changes in the editBox to the indicated (or current)
	-- note entry.
	CloseDropDownMenus()
	if (NotebookFrame.editing) then
		if type(ndata) ~= "table" then
			ndata = Notebook.FindByID(NotebookFrame.selectedID)
		end
		if (ndata) then
			Notebook.UpdateDescription(ndata, NotebookFrame.EditBox:GetText())
			NotebookFrame.editing = nil
			ndata.known = true
			ndata.saved = nil
			Notebook.UpdateNotKnown()
			Notebook.FilterList()
			Notebook.Frame_UpdateList()
			Notebook.Frame_UpdateButtons(nil, true)
		end
	end
end

function Notebook.Frame_AddButtonOnClick(self, ndata)
	-- Adds the indicated (or current) note to the known list.
	CloseDropDownMenus()
	if (not NotebookFrame.editing) then
		if type(ndata) ~= "table" then
			ndata = Notebook.FindByID(NotebookFrame.selectedID)
		end
		if (ndata) then
			ndata.known = true
			Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
			Notebook.UpdateNotKnown(ndata.title)
			Notebook.FilterList()
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
		ndata = Notebook.FindByID(NotebookFrame.selectedID)
	end
	if (ndata) then
		local dialogFrame = StaticPopup_Show("NOTEBOOK_UPDATE_CONFIRM", ndata.title, ndata.author)
		if (dialogFrame) then
			dialogFrame.data = ndata.id
		end
	end
end

function Notebook.Frame_CancelButtonOnClick(self)
	-- Restore the last saved contents of the current note
	CloseDropDownMenus()
	if (NotebookFrame.editing) then
		local ndata = Notebook.FindByID(NotebookFrame.selectedID)
		if (ndata) then
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
	if (dialogFrame) then
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
	local ndata = Notebook.FindByID(NotebookFrame.selectedID)
	if (ndata) then
		NotebookFrame.lastSelectedID = NotebookFrame.selectedID
	else
		ndata = Notebook.FindByID(NotebookFrame.lastSelectedID)
	end

	if ((id == 1) and (_filterBy ~= NOTEBOOK_TEXT.ALL_TAB)) then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab2)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab3)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab1)
		filterMode = NOTEBOOK_TEXT.ALL_TAB
		if (ndata) then
			showText = true
		end
		scrollOffset = NotebookFrame.lastKnownOffset
		NotebookFrame.lastRecentOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	elseif ((id == 2) and (_filterBy ~= NOTEBOOK_TEXT.MINE_TAB)) then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab1)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab3)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab2)
		filterMode = NOTEBOOK_TEXT.MINE_TAB
		if (ndata and (ndata.author == _playerName)) then
			showText = true
		end
		scrollOffset = NotebookFrame.lastRecentOffset
		NotebookFrame.lastKnownOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	elseif ((id == 3) and (_filterBy ~= NOTEBOOK_TEXT.RECENT_TAB)) then
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab1)
		PanelTemplates_DeselectTab(NotebookFrame.FilterTab2)
		PanelTemplates_SelectTab(NotebookFrame.FilterTab3)
		filterMode = NOTEBOOK_TEXT.RECENT_TAB
		if (ndata and ndata.recent) then
			showText = true
		end
		scrollOffset = NotebookFrame.lastRecentOffset
		NotebookFrame.lastKnownOffset = FauxScrollFrame_GetOffset(NotebookFrame.ListScrollFrame)
	end
	if (_filterBy ~= filterMode) then
		if (showText) then
			if (NotebookFrame.selectedID ~= ndata.id) then
				if (NotebookFrame.editing) then
					local pdata = Notebook.FindByID(NotebookFrame.selectedID)
					if (pdata) then
						local text = NotebookFrame.EditBox:GetText()
						if (text ~= pdata.description) then
							pdata.saved = text
						else
							pdata.saved = nil
						end
					end
				end
				if (ndata.saved) then
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
			if (NotebookFrame.editing) then
				local pdata = Notebook.FindByID(NotebookFrame.selectedID)
				if (pdata) then
					local text = NotebookFrame.EditBox:GetText()
					if (text ~= pdata.description) then
						pdata.saved = text
					else
						pdata.saved = nil
					end
				end
			end
			if (NotebookFrame.selectedID) then
				Notebook.Frame_SetDescriptionText("")
				NotebookFrame.editing = nil
				Notebook.Frame_UpdateButtons(nil, true)
				Notebook.Frame_SetCanSendCheckbox()
				NotebookFrame.selectedID = nil
			end
		end
		_filterBy = filterMode
		Notebook.FilterList()
		Notebook.Frame_UpdateList(nil, scrollOffset, true)
	end
end

function Notebook.Frame_OnUpdate(self)
	-- This function handles sending of messages (to limit send speed) and
	-- cooldown and receive timing.
	local time = GetTime()
	if (_sendInProgress) then
		if (time > _sendCooldownTimer) then
			local thisLine = _sendLines[1]
			if (thisLine) then
				-- Prefix each line with something to assist in identifying it
				-- on the receiving end and to make empty lines get sent.
				SendChatMessage(NOTEBOOK_SEND_PREFIX..thisLine, _sendChannel, nil, _sendTarget)
			end
			table.remove(_sendLines, 1)
			if (#_sendLines > 0) then
				-- More lines to send, set the timer for the next line
				_sendCooldownTimer = time + NOTEBOOK_SEND_LINE_COOLDOWN
			else
				-- All lines sent, set cooldown timer
				_sendInProgress = nil
				_sendCooldownTimer = time + NOTEBOOK_SEND_FINISHED_COOLDOWN
			end
		end
	elseif (_sendCooldownTimer) then
		if (time > _sendCooldownTimer) then
			_sendCooldownTimer = nil
			-- If the UI dropdown list is already shown (i.e., the global
			-- DropDownList1 frame is visible) then refresh it so that it can
			-- show the Send option again.
			if (DropDownList1:IsVisible()) then
				CloseDropDownMenus()
				ToggleDropDownMenu(1, nil, NotebookDropDown, "UIParent", NotebookDropDown.offsetX, NotebookDropDown.offsetY)
			end
		end
	end
	if (_receiveTimer) then
		if (time > _receiveTimer) then
			_receiveInProgress = nil
			_receiveTimer = nil
		end
	end
	if (not _sendInProgress and not _sendCooldownTimer and not _receiveTimer) then
		NotebookFrame:SetScript("OnUpdate", nil)
	end
end

function Notebook.Frame_DropdownSelect(self)
	-- Handles each of the options selected in the drop-down menu
	CloseDropDownMenus()
	local ndata = _notesList[NotebookDropDown.noteIndex]
	if (not ndata) then
		return
	end

	if (self.value == CANCEL) then
		-- Dummy action for cancel just to close the drop down menus
	elseif (self.value == NOTEBOOK_TEXT.SAVE_OPTION) then
		-- Save the current description
		Notebook.Frame_SaveButtonOnClick(ndata)
	elseif (self.value == NOTEBOOK_TEXT.UPDATE_OPTION) then
		-- Update the corresponding note with this one
		Notebook.Frame_UpdateButtonOnClick(ndata)
	elseif (self.value == NOTEBOOK_TEXT.ADD_OPTION) then
		-- Add the current note
		Notebook.Frame_AddButtonOnClick(self, ndata)
	elseif (self.value == NOTEBOOK_TEXT.RENAME_OPTION) then
		-- Set current title so that it will be set in the dialog box
		_currentTitle = ndata.title
		local dialogFrame = StaticPopup_Show("NOTEBOOK_NEW_TITLE")
		if (dialogFrame) then
			dialogFrame.data = ndata.id
			dialogFrame:SetWidth(420)
		end
	elseif (self.value == NOTEBOOK_TEXT.DELETE_OPTION) then
		-- If its a known entry, prompt for confirmation, otherwise just
		-- remove it
		if (ndata.known) then
			local dialogFrame = StaticPopup_Show("NOTEBOOK_REMOVE_CONFIRM", ndata.title)
			if (dialogFrame) then
				dialogFrame.data = ndata.id
			end
		else
			Notebook.RemoveByID(ndata.id)
			Notebook.UpdateNotKnown()
			NotebookFrame.selectedID = nil
			Notebook.Frame_SetDescriptionText("")
			NotebookFrame.editing = nil
			Notebook.Frame_UpdateButtons(nil, true)
			Notebook.Frame_SetCanSendCheckbox()
			Notebook.FilterList()
			Notebook.Frame_UpdateList()
		end
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_INSTANCE) then
		Notebook.SendNote(ndata, "INSTANCE_CHAT", nil)
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_RAID) then
		Notebook.SendNote(ndata, "RAID", nil)
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_PARTY) then
		Notebook.SendNote(ndata, "PARTY", nil)
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_GUILD) then
		Notebook.SendNote(ndata, "GUILD", nil)
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_OFFICER) then
		Notebook.SendNote(ndata, "OFFICER", nil)
	elseif (self.value == NOTEBOOK_TEXT.SEND_TO_PLAYER) then
		local dialogFrame = StaticPopup_Show("NOTEBOOK_SEND_TO_PLAYER")
		if (dialogFrame) then
			dialogFrame.data = ndata.id
		end
	else
		local _, _, option, channelNum, channelName = string.find(self.value, NOTEBOOK_CHANNEL_VALUE_FIND)
		if (option == NOTEBOOK_TEXT.SEND_TO_CHANNEL) then
			local serverList = {EnumerateServerChannels()}
			local isServerChannel = nil
			for index=1, #serverList do
				if (serverList[index] == channelName) then
					isServerChannel = true
					break
				end
			end
			if (isServerChannel) then
				local dialogFrame = StaticPopup_Show("NOTEBOOK_SERVER_CONFIRM", ndata.title, channelName)
				if (dialogFrame) then
					dialogFrame.data = { }
					dialogFrame.data.id = ndata.id
					dialogFrame.data.channelNum = channelNum
				end
			else
				Notebook.SendNote(ndata, "CHANNEL", tonumber(channelNum))
			end
		end
	end
end

function Notebook.Frame_TextChanged(self)
	-- Called when the text in the description edit box changes
	if (not NotebookFrame.editing and self.hasFocus and NotebookFrame.selectedID) then
		-- We are now editing this note, which means we enable the save and
		-- cancel buttons.  Note that we don't need to update the filter list
		-- here because if the note wasn't already on the list then it
		-- wouldn't have been editable.
		local ndata = Notebook.FindByID(NotebookFrame.selectedID)
		if (ndata) then
			-- First work around the timing of setting focus and getting the
			-- text changed notification by seeing if the description is ""
			-- when the editBox text contents is empty.
			if ((ndata.description ~= "") or (self:GetNumLetters() ~= 0)) then
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
	if (scroll < (min + 0.1)) then
		scrollbar.ScrollUpButton:Disable()
	else
		scrollbar.ScrollUpButton:Enable()
	end
	if (scroll > (max - 0.1)) then
		scrollbar.ScrollDownButton:Disable()
	else
		scrollbar.ScrollDownButton:Enable()
	end
end

------------------------------------------------------------------------
--	Popup support functions
------------------------------------------------------------------------

function Notebook.GetPopupData(type)
	if (type == "PLAYER") then
		if (_lastPlayer) then
			return _lastPlayer
		end
	elseif (type == "TITLE") then
		if (_currentTitle) then
			return _currentTitle
		end
	end
	return ""
end

function Notebook.HandlePopupAccept(type, data, text)
	if (type == "PLAYER") then
		-- Dialog for accepting player name
		if (text ~= "") then
			local ndata = Notebook.FindByID(data)
			if (ndata) then
				_lastPlayer = text
				Notebook.SendNote(ndata, "WHISPER", _lastPlayer)
			end
		end
	elseif (type == "TITLE") then
		-- Dialog for accepting new title name.  If the data parameter is not
		-- nil then we are changing the name of an existing note, otherwise we
		-- are doing the "New" dialog with a new note.
		if (text ~= "") then
			if (data) then
				-- Rename of note
				local ndata = Notebook.FindByID(data)
				if (ndata and (text ~= ndata.title)) then
					if (not Notebook.FindByTitle(text)) then
						Notebook.Rename(ndata, text)
						Notebook.UpdateNotKnown()
						Notebook.Frame_UpdateButtons(NotebookFrame.editing, ndata.known, ndata.update)
						Notebook.FilterList()
						Notebook.Frame_UpdateList()
					else
						ChatFrame1:AddMessage(format(NOTEBOOK_COMMANDS.ERROR_RENAME_NOT_UNIQUE_FORMAT, text))
					end
				end
			else
				-- Add a new (empty) note
				if (not Notebook.FindByTitle(text, true)) then
					local ndata = Notebook.Add(text, _playerName, date(NOTEBOOK_GETDATE_FORMAT), "", true, _addSavedToRecent, false)
					NotebookFrame.selectedID = ndata.id
					Notebook.FilterList()
					Notebook.Frame_UpdateList(nil, nil, true)
					NotebookFrame.editing = nil
					Notebook.Frame_UpdateButtons(nil, true)
					Notebook.Frame_SetCanSendCheckbox(true, ndata.send)
					Notebook.Frame_SetDescriptionText(ndata.description, ndata.known)
					NotebookFrame.EditBox:SetFocus()
				else
					ChatFrame1:AddMessage(format(NOTEBOOK_COMMANDS.ERROR_RENAME_NOT_UNIQUE_FORMAT, text))
				end
			end
		else
			ChatFrame1:AddMessage(NOTEBOOK_COMMANDS.ERROR_RENAME_EMPTY)
		end
	elseif (type == "CONFIRM") then
		local ndata = Notebook.FindByID(data)
		if (ndata) then
			Notebook.RemoveByID(ndata.id)
			Notebook.UpdateNotKnown()
			NotebookFrame.selectedID = nil
			Notebook.Frame_SetDescriptionText("")
			NotebookFrame.editing = nil
			Notebook.Frame_UpdateButtons(nil, true)
			Notebook.Frame_SetCanSendCheckbox()
			Notebook.FilterList()
			Notebook.Frame_UpdateList()
		end
	elseif (type == "UPDATE") then
		local ndata = Notebook.FindByID(data)
		if (ndata) then
			local pdata = Notebook.FindByTitle(ndata.title, true)
			if (pdata) then
				-- Update description and author, but not send flag
				Notebook.UpdateDescription(pdata, ndata.description)
				pdata.author = ndata.author
				pdata.saved = nil
				pdata.recent = true
				Notebook.UpdateNotKnown(pdata.title)
				NotebookFrame.selectedID = pdata.id
				Notebook.Frame_SetDescriptionText(pdata.description, true)
				NotebookFrame.editing = nil
				Notebook.Frame_UpdateButtons(nil, true)
				Notebook.Frame_SetCanSendCheckbox(true, pdata.send)
				Notebook.FilterList()
				Notebook.Frame_UpdateList()
			end
		end
	elseif (type == "SERVER") then
		if (data) then
			local ndata = Notebook.FindByID(data.id)
			if (ndata) then
				Notebook.SendNote(ndata, "CHANNEL", tonumber(data.channelNum))
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
	if (_original_ChatFrameEditBox_IsVisible(self)) then
		return true
	elseif (IsShiftKeyDown() and NotebookFrame.EditBox:IsVisible() and NotebookFrame.EditBox.hasFocus) then
		return true
	end
	return false
end

function Notebook.ChatFrameEditBox_Insert(self, text)
	-- Hooked version of ChatFrameEditBox:Insert that allows us to get item
	-- links into Notebook instead of always into the ChatFrameEditBox.
	if (IsShiftKeyDown() and NotebookFrame.EditBox:IsVisible() and NotebookFrame.EditBox.hasFocus) then
		NotebookFrame.EditBox:Insert(text)
	else
		_original_ChatFrameEditBox_Insert(self, text)
	end
end

------------------------------------------------------------------------
--	OnEvent handler
------------------------------------------------------------------------

function Notebook.OnEvent(self, event, ...)
	if ((event == "CHAT_MSG_INSTANCE_CHAT") or
		(event == "CHAT_MSG_RAID") or
		(event == "CHAT_MSG_RAID_LEADER") or
		(event == "CHAT_MSG_PARTY") or
		(event == "CHAT_MSG_PARTY_LEADER") or
		(event == "CHAT_MSG_GUILD") or
		(event == "CHAT_MSG_OFFICER") or
		(event == "CHAT_MSG_WHISPER") or
		(event == "CHAT_MSG_CHANNEL")) then
		Notebook.ChatMessageHandler(event, ...)

	elseif (event == "ADDON_LOADED") and (...) == NOTEBOOK then
		_serverName = GetRealmName()
		Notebook.VariablesLoaded()
		if (_serverName and _playerName) then
			Notebook.PlayerLogin()
		end
		self:UnregisterEvent("ADDON_LOADED")

	elseif (event == "PLAYER_LOGIN") then
		_playerName = UnitName("player")
		if (_serverName and _playerName) then
			Notebook.PlayerLogin()
		end

	elseif (event == "PLAYER_LOGOUT") then
		if (_serverName and _playerName) then
			Notebook.PlayerLogout()
		end

	end
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

	-- Register slash command handler
	SLASH_NOTEBOOK1 = "/notebook"
	SLASH_NOTEBOOK2 = "/note"
	SlashCmdList["NOTEBOOK"] = function(text)
		Notebook.SlashCommand(text)
	end

	-- Add our static popup dialogs for the actions we need
	StaticPopupDialogs["NOTEBOOK_SEND_TO_PLAYER"] = _notebookPlayerNamePopup
	StaticPopupDialogs["NOTEBOOK_NEW_TITLE"] = _notebookNewTitlePopup
	StaticPopupDialogs["NOTEBOOK_REMOVE_CONFIRM"] = _notebookConfirmRemovePopup
	StaticPopupDialogs["NOTEBOOK_UPDATE_CONFIRM"] = _notebookConfirmUpdatePopup
	StaticPopupDialogs["NOTEBOOK_SERVER_CONFIRM"] = _notebookConfirmServerPopup

	-- Register with Blizzard interface options
	Notebook.RegisterOptions(NOTEBOOK_NAME, NOTEBOOK_NAME.." v"..NOTEBOOK_VERSION, NOTEBOOK_DESCRIPTION, NOTEBOOK_HELP)
end

------------------------------------------------------------------------
--	Macro callable function
------------------------------------------------------------------------

function NotebookSendNote(title, channel, target)
	-- This function is basically a wrapper for Notebook.SendNote, taking a
	-- note title and determining the note to which this applies (looking at
	-- known notes only) and then sendingit to the indicated channel and
	-- target.  The target can either be a player name (for channel "WHISPER")
	-- or the name of a chat channel (for target "CHANNEL").
	if (_sendCooldownTimer) then
		if (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You cannot send another Note just yet")
		end
		return
	end
	if (title and (title ~= "") and channel and (channel ~= "")) then
		local ndata = Notebook.FindByTitle(title, true)
		if (ndata) then
			if ((NotebookFrame.selectedID ~= ndata.id) or not NotebookFrame.editing) then
				if (channel == "INSTANCE") then
					if GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 0 then
						Notebook.SendMode(ndata, "INSTANCE_CHAT", nil)
					elseif DEFAULT_CHAT_FRAME then
						DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You are not in an instance group")
					end
				elseif (channel == "RAID") then
					if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
						Notebook.SendNote(ndata, "RAID", nil)
					else
						if (DEFAULT_CHAT_FRAME) then
							DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You must be in a raid, and be the leader or an officer")
						end
					end
				elseif (channel == "PARTY") then
					if IsInGroup() and not IsInRaid() then
						Notebook.SendNote(ndata, "PARTY", nil)
					else
						if (DEFAULT_CHAT_FRAME) then
							DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You are not in a party")
						end
					end
				elseif (channel == "GUILD") then
					if IsInGuild() then
						Notebook.SendNote(ndata, "GUILD", nil)
					else
						if (DEFAULT_CHAT_FRAME) then
							DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You are not in a guild!")
						end
					end
				elseif (channel == "WHISPER") then
					if (target and (target ~= "")) then
						Notebook.SendNote(ndata, "WHISPER", target)
					else
						if (DEFAULT_CHAT_FRAME) then
							DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You must provide the name of a player to whisper to")
						end
					end
				elseif (channel == "CHANNEL") then
					if (target and (target ~= "")) then
						local channelNum = GetChannelName(target)
						if (channelNum and (channelNum ~= 0)) then
							Notebook.SendNote(ndata, "CHANNEL", channelNum)
						else
							if (DEFAULT_CHAT_FRAME) then
								DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."Cannot find channel \""..target.."\"")
							end
						end
					else
						if (DEFAULT_CHAT_FRAME) then
							DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You must provide a channel name to send to")
						end
					end
				else
					if (DEFAULT_CHAT_FRAME) then
						DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."Unsupported channel type \""..channel.."\"")
					end
				end
			else
				if (DEFAULT_CHAT_FRAME) then
					DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."Cannot send Note while being edited")
				end
			end
		else
			if (DEFAULT_CHAT_FRAME) then
				DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."Could not find a Note titled \""..title.."\"")
			end
		end
	else
		if (DEFAULT_CHAT_FRAME) then
			DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_TEXT.ERROR.."You must provide a valid note title and channel")
		end
	end
end

------------------------------------------------------------------------
--	Slash command function
------------------------------------------------------------------------

function Notebook.SlashCommand(text)
	if (text) then
		local command, params = Notebook.GetNextParam(string.lower(text))
		if (command == NOTEBOOK_COMMANDS.COMMAND_LIST) then
			if (DEFAULT_CHAT_FRAME) then
				DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_COMMANDS.COMMAND_LIST_CONFIRM)
			end
			local filterMode = _filterBy
			_filterBy = NOTEBOOK_TEXT.KNOWN_TAB
			Notebook.FilterList()
			for index in ipairs(_filteredList) do
				local ndata = _notesList[_filteredList[index]]
				if (ndata) then
					local text = format(NOTEBOOK_COMMANDS.COMMAND_LIST_FORMAT, ndata.title, string.len(ndata.description), ndata.author, Notebook.UnpackDate(ndata.date))
					DEFAULT_CHAT_FRAME:AddMessage(text)
				end
			end
			if (_filterBy ~= filterMode) then
				_filterBy = filterMode
				Notebook.FilterList()
			end

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_SHOW) then
			ShowUIPanel(NotebookFrame)

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_HIDE) then
			HideUIPanel(NotebookFrame)

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_WELCOME) then
			local ndata = Notebook.FindByTitle(_firstTimeNote.title, true)
			if (not ndata) then
				local ndata = Notebook.Add(_firstTimeNote.title, _firstTimeNote.author, _firstTimeNote.date, _firstTimeNote.description, true, true, false)
				Notebook.UpdateNotKnown()
				Notebook.FilterList()
				Notebook.Frame_UpdateList()
				Notebook.Frame_TabButtonOnClick(1)
				NotebookFrame:Show()
			else
				ChatFrame1:AddMessage(format(NOTEBOOK_COMMANDS.ERROR_RENAME_NOT_UNIQUE_FORMAT, _firstTimeNote.title))
			end

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_STATUS) then
			UpdateAddOnMemoryUsage()
			DEFAULT_CHAT_FRAME:AddMessage(format(NOTEBOOK_COMMANDS.COMMAND_STATUS_FORMAT, _notesCount, GetAddOnMemoryUsage(NOTEBOOK) + 0.5))

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_DEBUGON) then
			_debugFrame = DEFAULT_CHAT_FRAME
			if (DEFAULT_CHAT_FRAME) then
				DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_COMMANDS.COMMAND_DEBUGON_CONFIRM)
			end

		elseif (command == NOTEBOOK_COMMANDS.COMMAND_DEBUGOFF) then
			_debugFrame = nil
			if (DEFAULT_CHAT_FRAME) then
				DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_COMMANDS.COMMAND_DEBUGOFF_CONFIRM)
			end

		elseif (command == "") then
			ToggleFrame(NotebookFrame)

		else
			DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_EM.ON..NOTEBOOK_NAME.." v"..NOTEBOOK_VERSION..NOTEBOOK_EM.OFF)
			DEFAULT_CHAT_FRAME:AddMessage(NOTEBOOK_DESCRIPTION)
			for _, text in pairs(NOTEBOOK_HELP) do
				DEFAULT_CHAT_FRAME:AddMessage(text)
			end
		end
	end
end

------------------------------------------------------------------------
--	Blizzard options panel functions
------------------------------------------------------------------------

function Notebook.RegisterOptions(name, titleText, descriptionText, helpText)
	local panel = CreateFrame("Frame", nil)
	panel.name = name

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, -15)
	title:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -15, -15)
	title:SetJustifyH("LEFT")
	title:SetJustifyV("TOP")
	title:SetText(titleText)
	local last = title
	local spacing = 10

	if (descriptionText) then
		local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
		description:SetWidth(380)
		description:SetJustifyH("LEFT")
		description:SetJustifyV("TOP")
		description:SetNonSpaceWrap(1)
		description:SetText(descriptionText)
		last = description
	end

	if (helpText) then
		local helpTextList = helpText
		if (type(helpText) == "string") then
			helpTextList = {helpText}
		end
		for _, text in ipairs(helpTextList) do
			local line = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			line:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -(1 + spacing))
			line:SetWidth(380)
			line:SetJustifyH("LEFT")
			line:SetJustifyV("TOP")
			line:SetNonSpaceWrap(1)
			local uncolored = string.gsub(text, "(|c%x%x%x%x%x%x%x%x)", "")
			if (string.sub(uncolored, 1, 1) == "/") then
				line:SetWordWrap(true)
			else
				line:SetWordWrap(false)
			end
			line:SetSpacing(1)
			if (text ~= "") then
				line:SetText(text)
			else
				line:SetText(" ")
			end
			last = line
			spacing = 0
		end
	end

	InterfaceOptions_AddCategory(panel)
end