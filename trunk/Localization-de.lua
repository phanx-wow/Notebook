--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2014
	http://www.wowinterface.com/downloads/info4544-Notebook
	http://www.curse.com/addons/wow/notebook
----------------------------------------------------------------------]]
--	Deutsche Übersetzung von Phanx

if GetLocale() ~= "deDE" then return end
local NOTEBOOK, Notebook = ...
local L = Notebook.L

BINDING_NAME_NOTEBOOK_PANEL = "Notebook ein/aus"

L.FRAME_TITLE_FORMAT = "Notebook von %s"
L.ALL_TAB = "Alle"
L.ALL_TAB_TOOLTIP = "Alle Notizen"
L.MINE_TAB = "Meine"
L.MINE_TAB_TOOLTIP_FORMAT = "Die Notizen, die %s sich selbst geschaffen"
L.KNOWN_TAB = "Bekannte"
L.KNOWN_TAB_TOOLTIP = "Die Noitzen, die Ihr habt gespeichert"
L.RECENT_TAB = "Kürzliche"
L.RECENT_TAB_TOOLTIP = "Die Notizen, die Ihr habt kürzlich erhalten"
L.SAVE_BUTTON = "Spiechen"
L.SAVE_BUTTON_TOOLTIP = "Die aktuellen Änderungen spiechen"
L.CANCEL_BUTTON = "Abbrechen"
L.CANCEL_BUTTON_TOOLTIP = "Nicht gespeichterte Änderungen verwerfen, und zum zuvor gespiecherte Version zurückkehren"
L.ADD_BUTTON = "Hinzufügen"
L.ADD_BUTTON_TOOLTIP = "Diese Notiz auf Euer Liste der zuvor gespiecherten Notizen hinzufügen"
L.UPDATE_BUTTON = "Aktualisieren"
L.UPDATE_BUTTON_TOOLTIP = "Eure zuvor gespiecherten Notiz mit diesem neuen Text aktualisieren"
L.NEW_BUTTON = "Neue"
L.NEW_BUTTON_TOOLTIP = "Eine neue Notiz schaffen"
L.CHECK_SEND_BUTTON = "Sendbare"
L.CHECK_CAN_SEND_TOOLTIP = "Diese Notiz kann gesendet werden"
L.CHECK_NOT_SEND_TOOLTIP = "Diese Notiz kann nicht gesendet werden"

L.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Gespiechert %s"
L.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s von %s"
L.DETAILS_DATE_UNSAVED_FORMAT = "%s von %s"
L.DETAILS_SIZE_FORMAT = "- %d Zeichen"
L.DETAILS_NOT_KNOWN_TEXT = "- nicht gespeichert"
L.DETAILS_SENT_FORMAT = "- gesendet %s"
L.TITLE_CHANGE_NOT_SAVED = "*"

L.NOTE_RECEIVED_FORMAT = "Notebook hat die Notiz %q von %s hinzugefügt."

-- Right-click menu
L.SAVE_OPTION = "Spiechern"
L.ADD_OPTION = "Hinzufügen"
L.UPDATE_OPTION = "Aktualisieren"
L.RENAME_OPTION = "Unenennen"
L.DELETE_OPTION = "Löschen"
L.SEND_OPTION = "Senden zu"
L.SEND_TO_TARGET = "Ziel"
L.SEND_TO_PLAYER = "Spieler"
L.SEND_TO_INSTANCE = "Instanz"
L.SEND_TO_PARTY = "Gruppe"
L.SEND_TO_RAID = "Schlachtzug"
L.SEND_TO_GUILD = "Gilde"
L.SEND_TO_OFFICER = "Offizier"
L.SEND_TO_CHANNEL = "Channel"
L.CHANNEL_NAME_FORMAT = "%d. %s"

-- Popup dialogs
L.ENTER_PLAYER_NAME_TEXT = "Gebt den Spielername ein, denen diese Notiz senden:"
L.ENTER_NEW_TITLE_TEXT = "Gebt einen neuen Name für dieser Notiz ein:"
L.CONFIRM_REMOVE_FORMAT = "Wollt Ihr wirklich die Notiz %q dauerhaft löschen?"
L.CONFIRM_UPDATE_FORMAT = "Wollt Ihr wirklich die Notiz %q durch der Version von %s ersetzen?"
L.CONFIRM_SERVER_CHANNEL_FORMAT = "Wollt Ihr wirklich die Notiz %q zu dem Channel %s senden?"

-- Slash commands
L.CMD_HELP = "hilf"
L.CMD_LIST = "liste"
L.CMD_SHOW = "ein"
L.CMD_HIDE = "aus"
L.CMD_SEND = "send"
L.CMD_OPTIONS = "optionen"
L.CMD_DEBUGON = "debugein"
L.CMD_DEBUGOFF = "debugaus"
L.CMD_WELCOME = "wilkommen"
L.CMD_STATUS = "status"

-- Slash command responses
L.CMD_DEBUGON_CONFIRM = "Notebook-Debugging wird aktiviert."
L.CMD_DEBUGOFF_CONFIRM = "Notebook-Debugging wird deaktiviert."
L.CMD_LIST_CONFIRM = "Notebook enthält die folgenden Notizen:"
L.CMD_LIST_FORMAT = " - %s (%d Zeichen, von %s, %s)"
L.CMD_STATUS_FORMAT = "Notebook enthält %d Noitzen, und benutzt %.0fkB Spiecher."

-- Error messages
L.ERR_RENAME_NOT_UNIQUE_FORMAT = "Ihr habt bereits eine Notiz von dem Namen %q. Namen müssen einzigartig sein."
L.ERR_RENAME_EMPTY = "Namen dürfen nicht leer sein."
L.ERR_SEND_COOLDOWN = "Ihr dürft eine weitere Notiz noch nicht senden."
L.ERR_SEND_INVALID = "Ihr müsst eine gültige Notiz und Channel eingeben."
L.ERR_SEND_INVALID_NOTE = "Notiz %q nicht gefunden."
L.ERR_SEND_EDITING = "Ihr dürft eine Notiz mit nicht gespeicherten Änderungen nicht senden."
L.ERR_SEND_RAID_LEADER = "Ihr seid nicht der Schlachtzugsleiter oder Assistent."
L.ERR_SEND_NO_NAME = "Ihr müsst einen Charakternamen oder BattleTag eingeben."
L.ERR_SEND_NO_CHANNEL = "Ihr müsst einen Channelnamen eingeben."
L.ERR_SEND_INVALID_CHANNEL = "Channel %s nicht gefunden."
L.ERR_SEND_UNKNOWN_CHANNEL = "%q ist kein unterstützter Chatnachrichtentyp."

------------------------------------------------------------------------
-- Help text

Notebook.SLASH_COMMAND = "/notizbuch"

Notebook.HELP_TEXT = {
	"Gebt /notizbuch, /notebook oder /note mit den folgenden Befehlen ein:",
	"- " .. L.CMD_SHOW    .. " - Notebook anzeigen",
	"- " .. L.CMD_HIDE    .. " - Notebook ausblenden",
	"- " .. L.CMD_STATUS  .. " - die Status von Notebook anzeigen",
	"- " .. L.CMD_LIST    .. " - die Notizen in Eurem Notebook listen",
	"- " .. L.CMD_WELCOME .. " - die Wilkommen-Notiz wiederherstellen",
	"- " .. L.CMD_HELP    .. " - diese Hilfe anzeigen",
	"Gebt den Slash-Befehl ohne weiteren Befehlen ein, oder eine Taste in Tastaturbelegungsmenü belegen, um den Notebook-Fenster zu anzeigen oder ausblenden.",
}

------------------------------------------------------------------------
--	First timer's brief manual

L.WELCOME_NOTE_TITLE = "Wilkommen in Notebook!"
L.WELCOME_NOTE_DESCRIPTION = [[
Mit Notebook kann man viele Notizen im Spiel schreiben und spiechern, und sie zu die Freunde, Gruppe, Gilde und Chat-Kanäle senden. Wenn man normalerweise Makros benutzte, um Anweisung die Gruppe zu geben, oder Listen von Gegenständte zu führen -- Notebook könnte nützlich sein!

Um eine neue Notiz zu schaffen, einfach klickt auf den Button "Schaffen" und schreibt einen Namen für der Notiz. Namen können bis zu 60 Zeichen lang sein, und können beliebige Zeichen beinhalten. Jedoch müssen jeder Name einzigartich sein -- man kann nicht mehrere Noten mit dem gleichen Namen haben.

Nach der Schaffung einer Notiz kann man sie jederzeit ändern. Notizen können bis zu 4096 Zeichen lang sein. Wenn man mehr Platz benötigt, kann eine weitere Notiz einfach geschaffen werden. Man kann beliebig viele Notizen haben -- es gibt kein Limit!

Die interessanteren Funktionen von Notebook können durch Rechtsklick auf dem Name einer Notiz gefunden werden. Bei diesem Menü kann man die Notiz zu anderen Spielern senden, obwohl muss man zuerst die Option "Sendbare" für die individuelle Notiz an der Unterseite der Fenster aktivieren.

Nach dem Senden einer Notiz muss man einige Sekunden warten, bevor es möglich wird, weitere Notizen senden. Erinnert Euch -- wie bei Makros, es liegt in Euer Verantwortung, um andere Spieler durch diese Funktion nicht spammen!

Notebook speichert automatisch die Notizen, die von anderen Spielern empfangen werden, und zeigt sie in dem "Kürzlich"-Fach zusammen mit den Notizen, die Ihr in dieser Sitzung gesendet habt. Bei diesem Fach könnt Ihr diesen Notizen in eiginer Liste hinzufügen, oder Eure eigene Note zu aktualisieren.

Ich hoffe, Ihr erfreut über Notebook seid, und das nützlich findet!

-- Cirk von Doomhammer]]