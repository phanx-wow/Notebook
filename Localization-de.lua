--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2014
	http://www.wowinterface.com/downloads/info4544-Notebook
	http://www.curse.com/addons/wow/notebook
----------------------------------------------------------------------]]
--	Deutsch Übersetzung von Phanx
if GetLocale() ~= "deDE" then return end
local NOTEBOOK, Notebook = ...

BINDING_NAME_NOTEBOOK_PANEL = "Notebook ein/aus"

------------------------------------------------------------------------
-- Miscellaneous text commands
local T = Notebook.NOTEBOOK_TEXT

T.FRAME_TITLE_FORMAT = "Notebook von %s"
T.ALL_TAB = "Alle"
T.ALL_TAB_TOOLTIP = "Alle Notizen"
T.MINE_TAB = "Meine"
T.MINE_TAB_TOOLTIP_FORMAT = "Die Notizen, die %s sich selbst geschaffen"
T.KNOWN_TAB = "Bekannte"
T.KNOWN_TAB_TOOLTIP = "Die Noitzen, die Ihr habt gespeichert"
T.RECENT_TAB = "Kürzliche"
T.RECENT_TAB_TOOLTIP = "Die Notizen, die Ihr habt kürzlich erhalten"
T.SAVE_BUTTON = "Spiechen"
T.SAVE_BUTTON_TOOLTIP = "Die aktuellen Änderungen spiechen"
T.CANCEL_BUTTON = "Abbrechen"
T.CANCEL_BUTTON_TOOLTIP = "Nicht gespeichterte Änderungen verwerfen, und zum zuvor gespiecherte Version zurückkehren"
T.ADD_BUTTON = "Hinzufügen"
T.ADD_BUTTON_TOOLTIP = "Diese Notiz auf Euer Liste der zuvor gespiecherten Notizen hinzufügen"
T.UPDATE_BUTTON = "Aktualisieren"
T.UPDATE_BUTTON_TOOLTIP = "Eure zuvor gespiecherten Notiz mit diesem neuen Text aktualisieren"
T.NEW_BUTTON = "Neue"
T.NEW_BUTTON_TOOLTIP = "Eine neue Notiz schaffen"
T.CHECK_SEND_BUTTON = "Sendbare"
T.CHECK_CAN_SEND_TOOLTIP = "Diese Notiz kann gesendet werden"
T.CHECK_NOT_SEND_TOOLTIP = "Diese Notiz kann nicht gesendet werden"

T.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Gespiechert %s"
T.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s von %s"
T.DETAILS_DATE_UNSAVED_FORMAT = "%s von %s"
T.DETAILS_SIZE_FORMAT = "- %d Zeichen"
T.DETAILS_NOT_KNOWN_TEXT = "- nicht gespeichert"
T.DETAILS_SENT_FORMAT = "- gesendet %s"
T.TITLE_CHANGE_NOT_SAVED = "*"

T.SAVE_OPTION = "Spiechern"
T.ADD_OPTION = "Hinzufügen"
T.UPDATE_OPTION = "Aktualisieren"
T.RENAME_OPTION = "Unenennen"
T.DELETE_OPTION = "Löschen"
T.SEND_OPTION = "Senden zu"
T.SEND_TO_TARGET = "Ziel"
T.SEND_TO_PLAYER = "Spieler"
T.SEND_TO_INSTANCE = "Instanz"
T.SEND_TO_PARTY = "Gruppe"
T.SEND_TO_RAID = "Schlachtzug"
T.SEND_TO_GUILD = "Gilde"
T.SEND_TO_OFFICER = "Offizier"
T.SEND_TO_CHANNEL = "Channel"
T.CHANNEL_NAME_FORMAT = "%d. %s"

T.ENTER_PLAYER_NAME_TEXT = "Gebt den Spielername ein, denen diese Notiz senden:"
T.ENTER_NEW_TITLE_TEXT = "Gebt einen neuen Name für dieser Notiz ein:"
T.CONFIRM_REMOVE_FORMAT = "Wollt Ihr wirklich die Notiz %q dauerhaft löschen?"
T.CONFIRM_UPDATE_FORMAT = "Wollt Ihr wirklich die Notiz %q durch der Version von %s ersetzen?"
T.CONFIRM_SERVER_CHANNEL_FORMAT = "Wollt Ihr wirklich die Notiz %q zu dem Channel %s senden?"

T.NOTE_RECEIVED_FORMAT = "Notebook hat die Notiz %q von %s hinzugefügt."

------------------------------------------------------------------------
-- Slash commands and responses
local C = Notebook.NOTEBOOK_COMMANDS

-- Slash commands
C.COMMAND_HELP = "hilf"
C.COMMAND_LIST = "liste"
C.COMMAND_SHOW = "ein"
C.COMMAND_HIDE = "aus"
C.COMMAND_OPTIONS = "optionen"
C.COMMAND_DEBUGON = "debugein"
C.COMMAND_DEBUGOFF = "debugaus"
C.COMMAND_WELCOME = "wilkommen"
C.COMMAND_STATUS = "status"

-- Slash command responses
C.COMMAND_DEBUGON_CONFIRM = "Notebook-Debugging wird aktiviert."
C.COMMAND_DEBUGOFF_CONFIRM = "Notebook-Debugging wird deaktiviert."
C.COMMAND_LIST_CONFIRM = "Notebook enthält die folgenden Notizen:"
C.COMMAND_LIST_FORMAT = " - %s (%d Zeichen, von %s, %s)"
C.COMMAND_STATUS_FORMAT = "Notebook enthält %d Noitzen, und benutzt %.0fkB Spiecher."

-- Error messages
C.ERROR_RENAME_NOT_UNIQUE_FORMAT = "Ihr habt bereits eine Notiz von dem Namen %q. Namen müssen einzigartig sein."
C.ERROR_RENAME_EMPTY = "Namen dürfen nicht leer sein."
C.ERROR_SEND_COOLDOWN = "Ihr dürft eine weitere Notiz noch nicht senden."
C.ERROR_SEND_INVALID = "Ihr müsst eine gültige Notiz und Channel eingeben."
C.ERROR_SEND_INVALID_NOTE = "Notiz %q nicht gefunden."
C.ERROR_SEND_EDITING = "Ihr dürft eine Notiz mit nicht gespeicherten Änderungen nicht senden."
C.ERROR_SEND_RAID_LEADER = "Ihr seid nicht der Schlachtzugsleiter oder Assistent."
C.ERROR_SEND_NO_NAME = "Ihr müsst einen Charakternamen oder BattleTag eingeben."
C.ERROR_SEND_NO_CHANNEL = "Ihr müsst einen Channelnamen eingeben."
C.ERROR_SEND_INVALID_CHANNEL = "Channel %s nicht gefunden."
C.ERROR_SEND_UNKNOWN_CHANNEL = "%q ist kein unterstützter Chatnachrichtentyp."

------------------------------------------------------------------------
-- Help text

Notebook.NOTEBOOK_SLASH = "/notizbuch"

Notebook.NOTEBOOK_HELP = {
	"Gebt " .. Notebook.NOTEBOOK_SLASH .. ", /notebook oder /note mit den folgenden Befehlen ein:",
	"- " .. C.COMMAND_SHOW    .. " - Notebook anzeigen",
	"- " .. C.COMMAND_HIDE    .. " - Notebook ausblenden",
	"- " .. C.COMMAND_STATUS  .. " - die Status von Notebook anzeigen",
	"- " .. C.COMMAND_LIST    .. " - die Notizen in Eurem Notebook listen",
	"- " .. C.COMMAND_WELCOME .. " - die Wilkommen-Notiz wiederherstellen",
	"- " .. C.COMMAND_HELP    .. " - diese Hilfe anzeigen",
	"Gebt den Slash-Befehlen ohne weiteren Befehlen ein, oder eine Taste in Tastaturbelegungsmenü belegen, um den Notebook-Fenster zu anzeigen oder ausblenden.",
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.NOTEBOOK_FIRST_TIME_NOTE.title = "Wilkommen in Notebook!"
Notebook.NOTEBOOK_FIRST_TIME_NOTE.description = [[
Mit Notebook kann man viele Notizen im Spiel schreiben und spiechern, und sie zu die Freunde, Gruppe, Gilde und Chat-Kanäle senden. Wenn man normalerweise Makros benutzte, um Anweisung die Gruppe zu geben, oder Listen von Gegenständte zu führen -- Notebook könnte nützlich sein!

Um eine neue Notiz zu schaffen, einfach klickt auf den Button "Schaffen" und schreibt einen Namen für der Notiz. Namen können bis zu 60 Zeichen lang sein, und können beliebige Zeichen beinhalten. Jedoch müssen jeder Name einzigartich sein -- man kann nicht mehrere Noten mit dem gleichen Namen haben. Nach der Schaffung einer Notiz kann man sie jederzeit ändern. Notizen können bis zu 4096 Zeichen lang sein. Wenn man mehr Platz benötigt, kann eine weitere Notiz einfach geschaffen werden. Man kann beliebig viele Notizen haben -- es gibt kein Limit!

Die interessanteren Funktionen von Notebook können durch Rechtsklick auf dem Name einer Notiz gefunden werden. Bei diesem Menü kann man die Notiz zu anderen Spielern senden, obwohl muss man zuerst die Option "Sendbare" für die individuelle Notiz an der Unterseite der Fenster aktivieren. Nach dem Senden einer Notiz muss man einige Sekunden warten, bevor es möglich wird, weitere Notizen senden. Erinnert Euch -- wie bei Makros, es liegt in Euer Verantwortung, um andere Spieler durch diese Funktion nicht spammen!

Notebook speichert automatisch die Notizen, die von anderen Spielern empfangen werden, und zeigt sie in dem "Kürzlich"-Fach zusammen mit den Notizen, die Ihr in dieser Sitzung gesendet habt.

Notebook reconocerá automáticamente las notas enviadas por otros jugadores, y las mostrará en la pestaña "Recientes" junto con las notas que ha enviado en esta sesión. Podrás guardar estas notas a su propia lista, o actualizar tu copia si ya tenías. (Si la nota no ha cambiado, verás tu propria noa existente allí.)

Ich hoffe, Ihr erfreut über Notebook seid, und das nützlich findet!

-- Cirk von Doomhammer]]