--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2017 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/Notebook
	https://mods.curse.com/addons/wow/notebook
	https://www.wowinterface.com/downloads/info4544-Notebook.html
----------------------------------------------------------------------]]
--	English Localization

local NOTEBOOK, Notebook = ...
local L = {}
Notebook.L = L

BINDING_NAME_NOTEBOOK_PANEL = "Toggle Notebook"

L.FRAME_TITLE_FORMAT = "%s’s Notebook"
L.ALL_TAB = "All"
L.ALL_TAB_TOOLTIP = "All notes"
L.MINE_TAB = "Mine"
L.MINE_TAB_TOOLTIP_FORMAT = "%s’s notes"
L.KNOWN_TAB = "Saved"
L.KNOWN_TAB_TOOLTIP = "Saved notes only"
L.RECENT_TAB = "Recent"
L.RECENT_TAB_TOOLTIP = "Recent notes"
L.SAVE_BUTTON = "Save"
L.SAVE_BUTTON_TOOLTIP = "Save the current changes"
L.CANCEL_BUTTON = "Cancel"
L.CANCEL_BUTTON_TOOLTIP = "Revert to the previous text"
L.ADD_BUTTON = "Add"
L.ADD_BUTTON_TOOLTIP = "Add this note to Notebook's saved list"
L.UPDATE_BUTTON = "Update"
L.UPDATE_BUTTON_TOOLTIP = "Update your previously saved note with this new text"
L.NEW_BUTTON = "New"
L.NEW_BUTTON_TOOLTIP = "Create a new note"
L.CHECK_SEND_BUTTON = "Can be sent"
L.CHECK_CAN_SEND_TOOLTIP = "This note can be sent"
L.CHECK_NOT_SEND_TOOLTIP = "This note will not be sent"

L.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Saved %s"
L.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s by %s"
L.DETAILS_DATE_UNSAVED_FORMAT = "%s from %s"
L.DETAILS_SIZE_FORMAT = "- %d characters"
L.DETAILS_NOT_KNOWN_TEXT = "- not saved"
L.DETAILS_SENT_FORMAT = "- sent %s"
L.TITLE_CHANGE_NOT_SAVED = "*"

L.NOTE_RECEIVED_FORMAT = "Notebook added note “%s” from %s."

-- Right-click menu
L.SAVE_OPTION = "Save"
L.ADD_OPTION = "Add"
L.UPDATE_OPTION = "Update"
L.RENAME_OPTION = "Rename"
L.DELETE_OPTION = "Delete"
L.SEND_OPTION = "Send To"
L.SEND_TO_TARGET = "Target"
L.SEND_TO_PLAYER = "Player"
L.SEND_TO_INSTANCE = "Instance"
L.SEND_TO_PARTY = "Party"
L.SEND_TO_RAID = "Raid"
L.SEND_TO_GUILD = "Guild"
L.SEND_TO_OFFICER = "Officer"
L.SEND_TO_CHANNEL = "Channel"
L.CHANNEL_NAME_FORMAT = "%d. %s"

-- Popup dialogs
L.ENTER_PLAYER_NAME_TEXT = "Enter name of player to send to:"
L.ENTER_NEW_TITLE_TEXT = "Enter new title for note:"
L.CONFIRM_REMOVE_FORMAT = "Really delete “%s”?"
L.CONFIRM_UPDATE_FORMAT = "Really replace “%s” with the one from %s?"
L.CONFIRM_SERVER_CHANNEL_FORMAT = "Really send “%s” to the %s channel?"

-- Slash commands
L.CMD_HELP = "help"
L.CMD_LIST = "list"
L.CMD_SHOW = "show"
L.CMD_HIDE = "hide"
L.CMD_SEND = "send"
L.CMD_OPTIONS = "options"
L.CMD_DEBUGON = "debugon"
L.CMD_DEBUGOFF = "debugoff"
L.CMD_WELCOME = "welcome"
L.CMD_STATUS = "status"

-- Slash command responses
L.CMD_DEBUGON_CONFIRM = "Notebook debugging is enabled."
L.CMD_DEBUGOFF_CONFIRM = "Notebook debugging is disabled."
L.CMD_LIST_CONFIRM = "Notebook contains the following notes:"
L.CMD_LIST_FORMAT = "- %s (%d characters, by %s, %s)"
L.CMD_STATUS_FORMAT = "Notebook currently contains %d notes and is using %.0fkB of memory."

-- Error messages
L.ERR_RENAME_NOT_UNIQUE_FORMAT = "You already have a note titled “%s”. Titles must be unique."
L.ERR_RENAME_EMPTY = "You cannot have an empty title."
L.ERR_SEND_COOLDOWN = "You cannot send another note just yet."
L.ERR_SEND_INVALID = "You must provide a valid note title and channel."
L.ERR_SEND_INVALID_NOTE = "Could not find a note titled “%s”."
L.ERR_SEND_EDITING = "You cannot send a note with unsaved changes."
L.ERR_SEND_RAID_LEADER = "You are not the raid leader or assistant."
L.ERR_SEND_NO_NAME = "You must enter a character name or BattleTag."
L.ERR_SEND_NO_CHANNEL = "You must enter a channel name."
L.ERR_SEND_INVALID_CHANNEL = "Could not find a channel “%s”."
L.ERR_SEND_UNKNOWN_CHANNEL = "“%s” is not a supported channel type."

------------------------------------------------------------------------
-- Help text

-- Notebook.SLASH_COMMAND not needed for English

Notebook.HELP_TEXT = {
	"Use /notebook or /note with the following commands:",
	"   " .. L.CMD_SHOW    .. " - show Notebook",
	"   " .. L.CMD_HIDE    .. " - hide Notebook",
	"   " .. L.CMD_STATUS  .. " - report the status of Notebook",
	"   " .. L.CMD_LIST    .. " - list the notes in your Notebook",
	"   " .. L.CMD_WELCOME .. " - restore the Welcome note",
	"   " .. L.CMD_HELP    .. " - show this help message",
	"Use the slash command without any additional commands, or bind a key in the Key Bindings menu, to toggle the Notebook window.",
}

------------------------------------------------------------------------
--	First timer's brief manual

L.WELCOME_NOTE_TITLE = "Welcome to Notebook!"
L.WELCOME_NOTE_DESCRIPTION = [[
Notebook allows you to write and keep track of notes on different topics and then share them with your guildmates, raid members, or even chat channels!  So if you usually use macros for raid instructions, loot rules, enchanting lists, and the like, Notebook might be for you!

To create a new Note, simply click on the New button and enter a title for the note.  Titles can be up to 60 characters long and can contain any characters you want to use.  But they must be unique - you can't have two Notes both titled "Things to do" for example.  (You could have "Things to do" and "Other things to do" instead though :)

Once you've created your note you can then edit it and save it as you need.  Notes can be up to 4096 characters in length (about twice the length of this Note about Notebook).   If you need more room, just create another note!  There is no limit (apart from memory) to the number of Notes you can have.

The more interesting features that Notebook provides are available through right-clicking on the title of a Note in the above Notes list, which will bring up a menu showing you various options, including allowing you to send the note to other players through party, raid, or guild chat, by whisper, or any of your current chat channels.  (You may first need to enable sending for that specific Note via the "Can be sent" box at the bottom of the window first).

After sending a note you will have to wait a few seconds before you can send something else.  Remember though that just like with macros, it is still your responsibility to make sure that you don't abuse the features of Notebook and spam other players!

Notebook will also automatically recognize Notes sent by other players, and will show these under the Recent tab along with any you have sent this session. You will then be able to add these Notes to your own saved list, or get an update if you already had it.  (If the Note hasn't changed, you'll just see your own existing Note there).

I hope you enjoy Notebook and find it useful!

-- Cirk of Doomhammer]]
