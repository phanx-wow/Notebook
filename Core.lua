--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2015 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info4544-Notebook.html
	http://www.curse.com/addons/wow/notebook
	https://github.com/Phanx/Notebook
----------------------------------------------------------------------]]

local NOTEBOOK, Notebook = ...
local L = Notebook.L
_G[NOTEBOOK] = Notebook

L.WELCOME_NOTE_TEXT = [[
Notebook allows you to write and keep track of notes on different topics and then share them with your guildmates, raid members, or even chat channels! So if you usually use macros for raid instructions, loot rules, enchanting lists, and the like, Notebook might be for you!

To create a new Note, simply click on the New button and enter a title for the note. Titles can be up to 60 characters long and can contain any characters you want to use. But they must be unique - you can't have two Notes both titled "Things to do" for example. (You could have "Things to do" and "Other things to do" instead though

Once you've created your note you can then edit it and save it as you need. Notes can be up to 4096 characters in length (about twice the length of this Note about Notebook). If you need more room, just create another note! There is no limit (apart from memory) to the number of Notes you can have.

The more interesting features that Notebook provides are available through right-clicking on the title of a Note in the above Notes list, which will bring up a menu showing you various options, including allowing you to send the note to other players through party, raid, or guild chat, by whisper, or any of your current chat channels. (You may first need to enable sending for that specific Note via the "Can be sent" box at the bottom of the window first).

After sending a note you will have to wait a few seconds before you can send something else. Remember though that just like with macros, it is still your responsibility to make sure that you don't abuse the features of Notebook and spam other players!

Notebook will also automatically recognize Notes sent by other players, and will show these under the Recent tab along with any you have sent this session. You will then be able to add these Notes to your own saved list, or get an update if you already had it. (If the Note hasn't changed, you'll just see your own existing Note there).

I hope you enjoy Notebook and find it useful!

-- Cirk of Doomhammer]]

------------------------------------------------------------------------
-- Constants

local PLAYER_NAME = UnitName("player")
local PLAYER_REALM = GetRealmName()
local PLAYER_CLASS = select(2, UnitClass("player"))

------------------------------------------------------------------------
-- State variables

------------------------------------------------------------------------
-- Initialize addon

function Notebook:OnLogin()
	local firstRun = not NotebookNotes --and not NotebookState
	self:Print("OnLogin")

	self.notes = self:InitializeDB("NotebookNotes")

	if NotebookState then
		self:Print("--- NotebookState exists")
		-- Import notes from old saved variable
		for title, note in pairs(NotebookState.Notes) do
			self:Print("--- old note:", title)
			if not self.notes[title] then
				self.notes[title] = {
					text    = note.description,
					date    = note.date,
					author  = note.author,
					canSend = note.send,
				}
				print("--- imported")
			else
				print("--- already exists")
			end
		end
	end

	if firstRun then
		self:Print("--- First run")
		self.notes[L["Welcome to Notebook!"]] = {
			text   = L["WELCOME_NOTE_TEXT"],
			date   = "05-12-24",
			author = "Cirk",
		}
	end

	self.sortedTitles = {}
	for title in pairs(self.notes) do
		tinsert(self.sortedTitles, title)
	end
	sort(self.sortedTitles)
end

------------------------------------------------------------------------
--- Utility function to construct a unique title.
-- @param title (string) Desired title
-- @param count (number) For internal use only!

function Notebook:ConstructUniqueTitle(title, count)
	title = title and strtrim(title) or L["Untitled Note"]
	local temp = count and (title .. "(" .. count .. ")") or title
	if self.notes[title] == temp then
		return self:ConstructUniqueTitle(title, count and (count + 1) or 2)
	end
	return temp
end

------------------------------------------------------------------------
--- API function to add a new note to the database.
-- @param title (string) Desired title of the note
-- @param text (string) (optional) Text contents of the note

function Notebook:AddNote(title, text)
	self:Print("AddNote", title, "=", text)
	title = self:ConstructUniqueTitle(title)
	self.notes[title] = {
		text        = text,
		date        = date("%y-%m-%d"),
		author      = PLAYER_NAME,
		authorRealm = PLAYER_REALM,
		authorClass = PLAYER_CLASS,
	}
	self:Update()
end

------------------------------------------------------------------------
--- API function to edit an existing note in the database.
-- Values not specified will remain unchanged.
-- @param title (string) Current title of the note
-- @param newTitle (string) (optional) New title for the note; if not provided, the current title will be preserved
-- @param newText (string) (optional) New text contents for the note; if not provided, the current text will be preserved

function Notebook:EditNote(title, newTitle, newText)
	newTitle = newTitle and strtrim(newTitle)
	newText = newText and strtrim(newText)

	local note = self.notes[title]
	if newTitle == title or (note and newText == note.text) then
		return
	end
	
	if not note then
		self:AddNote(newTitle, newText)
	else
		note.text        = newText or note.text
		note.date        = date("%Y-%m-%d")
		note.author      = PLAYER_NAME
		note.authorRealm = PLAYER_REALM
		note.authorClass = PLAYER_CLASS
		
		if newTitle and newTitle ~= title then
			self.notes[title] = nil
			self.notes[self:ConstructUniqueTitle(newTitle)] = note
		end
	end
	self:Update()
end

------------------------------------------------------------------------
--- API function to remove an existing note from the database.
-- @param title (string) Title of the note to send

function Notebook:DeleteNote(title)
	local note = self.notes[title]
	if note then
		self.notes[title] = nil
	end
	self:Update()
end

------------------------------------------------------------------------
--- API function to send a note over a chat channel.
-- @param title (string) Title of the note to send
-- @param channel (string) The type of chat channel to which the note should be sent
-- @param target (string or number) The number of the channel, or name of the player, to whom the note should be sent

function Notebook:SendNote(title, channel, target)
	local note = self.notes[title]
	if note and note.canSend then
		-- TODO
	end
end

------------------------------------------------------------------------
-- Internal function to be called when notes change.

function Notebook:Update()
	self:Print("Update")

	wipe(self.sortedTitles)
	for title in pairs(self.notes) do
		tinsert(self.sortedTitles, title)
	end
	sort(self.sortedTitles)

	self:UpdateFrame() -- defined in Frame.lua
end
