------------------------------------------------------------------------
--	Notebook
--	Allows you to record and share notes in-game
--	Written by Cirk of Doomhammer, December 2005, last updated August 2009
--	Updated by Phanx
--	http://www.wowinterface.com/downloads/info4544-CirksNotebook.html
------------------------------------------------------------------------
--	Localization

BINDING_HEADER_NOTEBOOK_TITLE = "Notebook Bindings"
BINDING_NAME_NOTEBOOK_PANEL = "Show Notebook"

NOTEBOOK_EM = {
	ON = "|cffffff00",
	RED = "|cffff4000",
	OFF = "|r",
}

-- Miscellaneous text commands
NOTEBOOK_TEXT = {
	FRAME_TITLE_FORMAT = "%s's Notebook",
	ALL_TAB = "All",
	ALL_TAB_TOOLTIP = "All notes",
	MINE_TAB = "Mine",
	MINE_TAB_TOOLTIP_FORMAT = "%s's notes",
	KNOWN_TAB = "Saved",
	KNOWN_TAB_TOOLTIP = "Saved notes only",
	RECENT_TAB = "Recent",
	RECENT_TAB_TOOLTIP = "Recent notes",
	SAVE_BUTTON = "Save",
	SAVE_BUTTON_TOOLTIP = "Save the current changes",
	CANCEL_BUTTON = "Cancel",
	CANCEL_BUTTON_TOOLTIP = "Revert to the previous text",
	ADD_BUTTON = "Add",
	ADD_BUTTON_TOOLTIP = "Add this note to Notebook's saved list",
	UPDATE_BUTTON = "Update",
	UPDATE_BUTTON_TOOLTIP = "Update your previously saved note with this new text",
	NEW_BUTTON = "New",
	NEW_BUTTON_TOOLTIP = "Create a new note",
	CHECK_SEND_BUTTON = "Can be sent",
	CHECK_CAN_SEND_TOOLTIP = "This note can be sent",
	CHECK_NOT_SEND_TOOLTIP = "This note will not be sent",

	DETAILS_DATE_KNOWN_SAVED_FORMAT = "Saved %s",
	DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s by %s",
	DETAILS_DATE_UNSAVED_FORMAT = "%s from %s",
	DETAILS_SIZE_FORMAT = "- %d characters",
	DETAILS_NOT_KNOWN_TEXT = "- not saved",
	DETAILS_SENT_FORMAT = "- sent %s",
	TITLE_CHANGE_NOT_SAVED = "*",

	SAVE_OPTION = "Save",
	ADD_OPTION = "Add",
	UPDATE_OPTION = "Update",
	RENAME_OPTION = "Rename",
	DELETE_OPTION = "Delete",
	SEND_OPTION = "Send To",
	SEND_TO_TARGET = "Target",
	SEND_TO_PLAYER = "Player",
	SEND_TO_RAID = "Raid",
	SEND_TO_PARTY = "Party",
	SEND_TO_GUILD = "Guild",
	SEND_TO_CHANNEL = "Channel",
	CHANNEL_NAME_FORMAT = "%d. %s",

	ENTER_PLAYER_NAME_TEXT = "Enter name of player to send to:",
	ENTER_NEW_TITLE_TEXT = "Enter new title for note:",
	CONFIRM_REMOVE_FORMAT = "Really delete \"%s\"?",
	CONFIRM_UPDATE_FORMAT = "Really replace \"%s\" with the one from %s?",
	CONFIRM_SERVER_CHANNEL_FORMAT = "Really send \"%s\" to %s channel?",

	NOTE_RECEIVED_FORMAT = NOTEBOOK_EM.ON.."Notebook added note \""..NOTEBOOK_EM.OFF.."%s"..NOTEBOOK_EM.ON.."\" from "..NOTEBOOK_EM.OFF.."%s",

	ELLIPSIS = "...",
	MONTHNAME_1 = FULLDATE_MONTH_JANUARY, -- "Jan",
	MONTHNAME_2 = FULLDATE_MONTH_FEBRUARY, -- "Feb",
	MONTHNAME_3 = FULLDATE_MONTH_MARCH, -- "Mar",
	MONTHNAME_4 = FULLDATE_MONTH_APRIL, -- "Apr",
	MONTHNAME_5 = FULLDATE_MONTH_MAY, -- "May",
	MONTHNAME_6 = FULLDATE_MONTH_JUNE, -- "Jun",
	MONTHNAME_7 = FULLDATE_MONTH_JULY, -- "Jul",
	MONTHNAME_8 = FULLDATE_MONTH_AUGUST, -- "Aug",
	MONTHNAME_9 = FULLDATE_MONTH_SEPTEMBER, -- "Sep",
	MONTHNAME_10 = FULLDATE_MONTH_OCTOBER, -- "Oct",
	MONTHNAME_11 = FULLDATE_MONTH_NOVEMBER, -- "Nov",
	MONTHNAME_12 = FULLDATE_MONTH_DECEMBER, -- "Dec",
	DEBUG = NOTEBOOK_EM.ON.."Notebook: "..NOTEBOOK_EM.OFF,
	ERROR = NOTEBOOK_EM.RED.."Notebook: "..NOTEBOOK_EM.OFF,
}

-- Slash commands and responses
NOTEBOOK_COMMANDS = {
	-- Slash commands
	COMMAND_HELP = "help",
	COMMAND_LIST = "list",
	COMMAND_SHOW = "show",
	COMMAND_HIDE = "hide",
	COMMAND_OPTIONS = "options",
	COMMAND_DEBUGON = "debugon",
	COMMAND_DEBUGOFF = "debugoff",
	COMMAND_WELCOME = "welcome",
	COMMAND_STATUS = "status",

	-- Slash command responses
	COMMAND_DEBUGON_CONFIRM = "Notebook debug is enabled",
	COMMAND_DEBUGOFF_CONFIRM = "Notebook debug is disabled",
	COMMAND_LIST_CONFIRM = NOTEBOOK_EM.ON.."Notebook contains the following notes:"..NOTEBOOK_EM.OFF,
	COMMAND_LIST_FORMAT = NOTEBOOK_EM.ON.."- "..NOTEBOOK_EM.OFF.."%s "..NOTEBOOK_EM.ON.."(%d characters, by %s, %s)"..NOTEBOOK_EM.OFF,
	COMMAND_STATUS_FORMAT = NOTEBOOK_EM.ON.."Notebook currently contains %d notes and is using %.0fkB of memory"..NOTEBOOK_EM.OFF,

	-- Error messages
	ERROR_RENAME_NOT_UNIQUE_FORMAT = NOTEBOOK_TEXT.ERROR..NOTEBOOK_EM.ON.."You already have a note titled \""..NOTEBOOK_EM.OFF.."%s"..NOTEBOOK_EM.ON.."\" (titles must be unique)"..NOTEBOOK_EM.OFF,
	ERROR_RENAME_EMPTY = NOTEBOOK_TEXT.ERROR..NOTEBOOK_EM.ON.."You cannot have an empty title"..NOTEBOOK_EM.OFF,
}

-- Help text
NOTEBOOK_DESCRIPTION = "Allows you to record and share notes in-game."
NOTEBOOK_HELP = {
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_HELP..NOTEBOOK_EM.OFF.." shows this help message",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_EM.OFF.."toggles showing the Notebook window",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_SHOW..NOTEBOOK_EM.OFF.." shows Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_HIDE..NOTEBOOK_EM.OFF.." hides Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_LIST..NOTEBOOK_EM.OFF.." lists the notes in your Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_WELCOME..NOTEBOOK_EM.OFF.." restores the Welcome note",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_STATUS..NOTEBOOK_EM.OFF.." shows the status of Notebook",
	"",
	"You can also use "..NOTEBOOK_EM.ON.."/note"..NOTEBOOK_EM.OFF.." instead of "..NOTEBOOK_EM.ON.."/notebook"..NOTEBOOK_EM.OFF.." and there is a key-binding available to open and close the Notebook window.",
}

------------------------------------------------------------------------
--	First timer's brief manual
------------------------------------------------------------------------

NOTEBOOK_FIRST_TIME_NOTE = {
	["title"] = "Welcome to Notebook!",
	["author"] = "Cirk",
	["date"] = "051224",
	["description"] = [[Notebook allows you to write and keep track of notes on different topics and then share them with your guildmates, raid members, or even chat channels!  So if you usually use macros for raid instructions, loot rules, enchanting lists, and the like, Notebook might be for you!

To create a new Note, simply click on the New button and enter a title for the note.  Titles can be up to 60 characters long and can contain any characters you want to use.  But they must be unique - you can't have two Notes both titled "Things to do" for example.  (You could have "Things to do" and "Other things to do" instead though :)

Once you've created your note you can then edit it and save it as you need.  Notes can be up to 4096 characters in length (about twice the length of this Note about Notebook).   If you need more room, just create another note!  There is no limit (apart from memory) to the number of Notes you can have.

The more interesting features that Notebook provides are available through right-clicking on the title of a Note in the above Notes list, which will bring up a menu showing you various options, including allowing you to send the note to other players through party, raid, or guild chat, by whisper, or any of your current chat channels.  (You may first need to enable sending for that specific Note via the "Can be sent" box at the bottom of the window first).

After sending a note you will have to wait a few seconds before you can send something else.  Remember though that just like with macros, it is still your responsibility to make sure that you don't abuse the features of Notebook and spam other players!

Notebook will also automatically recognize Notes sent by other players, and will show these under the Recent tab along with any you have sent this session. You will then be able to add these Notes to your own saved list, or get an update if you already had it.  (If the Note hasn't changed, you'll just see your own existing Note there).

I hope you enjoy Notebook and find it useful!

-- Cirk of Doomhammer]],
}