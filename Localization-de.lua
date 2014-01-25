--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2013
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
T.ALL_TAB_TOOLTIP = "Alle Noten"
T.MINE_TAB = "Meine"
T.MINE_TAB_TOOLTIP_FORMAT = "Die Notizen, die %s sich selbst geschaffen"
T.KNOWN_TAB = "Bekannt"
T.KNOWN_TAB_TOOLTIP = "Die Noitzen, die Ihr habt gespeichert"
T.RECENT_TAB = "Kürzlich"
T.RECENT_TAB_TOOLTIP = "Die Notizen, die Ihr habt kürzlich erhalten"
T.SAVE_BUTTON = "Spiecht"
T.SAVE_BUTTON_TOOLTIP = "Die aktuellen Änderungen spiechen"
T.CANCEL_BUTTON = "Abbrecht"
T.CANCEL_BUTTON_TOOLTIP = "Nicht gespeichterte Änderungen verwerfen, und zum zuvor gespiecherte Version zurückkehren"
T.ADD_BUTTON = "Fügt hinzu"
T.ADD_BUTTON_TOOLTIP = "Diese Notiz auf Euer Liste der zuvor gespiecherten Notizen hinzufügen"
T.UPDATE_BUTTON = "Aktualisiert"
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
T.CONFIRM_REMOVE_FORMAT = "Wollt Ihr wirklich die Notiz \"%s\" dauerhaft löschen?"
T.CONFIRM_UPDATE_FORMAT = "Wollt Ihr wirklich die Notiz \"%s\" durch der Version von %s ersetzen?"
T.CONFIRM_SERVER_CHANNEL_FORMAT = "Wollt Ihr wirklich die Notiz \"%s\" zu dem Channel %s senden?"

T.NOTE_RECEIVED_FORMAT = NOTEBOOK_EM.ON .. "Notebook hat die Notiz \"" .. NOTEBOOK_EM.OFF .. "%s" .. NOTEBOOK_EM.ON .. "\" von " .. NOTEBOOK_EM.OFF .. "%s" .. NOTEBOOK_EM.ON .. "hinzugefügt." .. NOTEBOOK_EM.OFF

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
C.COMMAND_LIST_CONFIRM = NOTEBOOK_EM.ON .. "Notebook enthält die folgenden Notizen:" .. NOTEBOOK_EM.OFF
C.COMMAND_LIST_FORMAT = NOTEBOOK_EM.ON .. "- " .. NOTEBOOK_EM.OFF .. "%s " .. NOTEBOOK_EM.ON .. "(%d Zeichen, von %s, %s)" .. NOTEBOOK_EM.OFF
C.COMMAND_STATUS_FORMAT = NOTEBOOK_EM.ON .. "Notebook enthält %d Noitzen, und benutzt %.0fkB Spiecher." .. NOTEBOOK_EM.OFF

-- Error messages
C.ERROR_RENAME_NOT_UNIQUE_FORMAT = NOTEBOOK_TEXT.ERROR .. NOTEBOOK_EM.ON .. "Ihr habt bereits eine Notiz von dem Namen \"" .. NOTEBOOK_EM.OFF .. "%s" .. NOTEBOOK_EM.ON .. "\" (Namen müssen einzigartig sein)" .. NOTEBOOK_EM.OFF
C.ERROR_RENAME_EMPTY = NOTEBOOK_TEXT.ERROR .. NOTEBOOK_EM.ON .. "Namen dürfen nicht leer sein." .. NOTEBOOK_EM.OFF

------------------------------------------------------------------------
-- Help text

Notebook.NOTEBOOK_SLASH = "/notizbuch"

Notebook.NOTEBOOK_HELP = {
	"Benutzt /notebook, /note, oder" .. Notebook.NOTEBOOK_SLASH .. "mit den folgenden Befehlen:",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_SHOW .. NOTEBOOK_EM.OFF .. " - Notebook anzeigen",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_HIDE .. NOTEBOOK_EM.OFF .. " - Notebook ausblenden",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_STATUS .. NOTEBOOK_EM.OFF .. " - die Status von Notebook anzeigen",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_LIST .. NOTEBOOK_EM.OFF .. " - die Notizen in Eurem Notebook listen",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_WELCOME .. NOTEBOOK_EM.OFF .. " - die Wilkommen-Notiz wiederherstellen",
	"   " .. NOTEBOOK_EM.ON .. NOTEBOOK_COMMANDS.COMMAND_HELP .. NOTEBOOK_EM.OFF .. " - diese Hilfe anzeigen",
	"Gebt den Slash-Befehlen ohne weiteren Befehlen ein, oder eine Taste in Tastaturbelegungsmenü belegen, um den Notebook-Fenster zu anzeigen oder ausblenden.",
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.NOTEBOOK_FIRST_TIME_NOTE["title"] = "Wilkommen in Notebook!"
Notebook.NOTEBOOK_FIRST_TIME_NOTE["description"] = [[Mit Notebook kann man viele Notizen im Spiel schreiben und spiechern, und sie zu die Freunde, Gruppe, Gilde und Chat-Kanäle senden. Wenn man normalerweise Makros benutzte, um Anweisung die Gruppe zu geben, oder Listen von Gegenständte zu führen -- Notebook könnte nützlich sein!

Um eine neue Notiz zu schaffen, einfach klickt auf den Button "Schaffen" und schreibt einen Namen für der Notiz. Namen können bis zu 60 Zeichen lang sein, und können beliebige Zeichen beinhalten. Jedoch müssen jeder Name einzigartich sein -- man kann nicht mehrere Noten mit dem gleichen Namen haben. Nach der Schaffung einer Notiz kann man sie jederzeit ändern. Notizen können bis zu 4096 Zeichen lang sein. Wenn man mehr Platz benötigt, kann eine weitere Notiz einfach geschaffen werden. Man kann beliebig viele Notizen haben -- es gibt kein Limit!

Die interessanteren Funktionen von Notebook können durch Rechtsklick auf dem Name einer Notiz gefunden werden. Bei diesem Menü kann man die Notiz zu anderen Spielern senden, obwohl muss man zuerst die Option "Sendbare" für die individuelle Notiz an der Unterseite der Fenster aktivieren. Nach dem Senden einer Notiz muss man einige Sekunden warten, bevor es möglich wird, weitere Notizen senden. Erinnert Euch -- wie bei Makros, es liegt in Euer Verantwortung, um andere Spieler durch diese Funktion nicht spammen!

Notebook speichert automatisch die Notizen, die von anderen Spielern empfangen werden, und zeigt sie in dem "Kürzlich"-Fach zusammen mit den Notizen, die Ihr in dieser Sitzung gesendet habt.

Notebook reconocerá automáticamente las notas enviadas por otros jugadores, y las mostrará en la pestaña "Recientes" junto con las notas que ha enviado en esta sesión. Podrás guardar estas notas a su propia lista, o actualizar tu copia si ya tenías. (Si la nota no ha cambiado, verás tu propria noa existente allí.)

Ich hoffe, Ihr erfreut über Notebook seid, und das nützlich findet!

-- Cirk von Doomhammer]]