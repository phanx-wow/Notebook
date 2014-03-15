--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2014
	http://www.wowinterface.com/downloads/info4544-Notebook
	http://www.curse.com/addons/wow/notebook
----------------------------------------------------------------------]]
--	Traducción al español por Phanx
if not GetLocale():match("^es") then return end
local NOTEBOOK, Notebook = ...

BINDING_NAME_NOTEBOOK_PANEL = "Mostrar/ocultar Notebook"

------------------------------------------------------------------------
-- Miscellaneous text commands
local T = Notebook.NOTEBOOK_TEXT

T.FRAME_TITLE_FORMAT = "Notebook de %s"
T.ALL_TAB = "Todo"
T.ALL_TAB_TOOLTIP = "Todas notas"
T.MINE_TAB = UnitSex("player") == 3 and "Mía" or "Mío"
T.MINE_TAB_TOOLTIP_FORMAT = "Notas creadas por %s"
T.KNOWN_TAB = "Guardada"
T.KNOWN_TAB_TOOLTIP = "Notas que tú ha guardado"
T.RECENT_TAB = "Nuevo"
T.RECENT_TAB_TOOLTIP = "Notas que tú ha recibido recientemente"
T.SAVE_BUTTON = "Guardar"
T.SAVE_BUTTON_TOOLTIP = "Guardar los cambios actuales"
T.CANCEL_BUTTON = "Cancelar"
T.CANCEL_BUTTON_TOOLTIP = "Volver a la última versión guardada"
T.ADD_BUTTON = "Agregar"
T.ADD_BUTTON_TOOLTIP = "Agregar esta nota a la lista guardada"
T.UPDATE_BUTTON = "Actualizar"
T.UPDATE_BUTTON_TOOLTIP = "Actualizar su nota guadada con este nuevo texto"
T.NEW_BUTTON = "Crear"
T.NEW_BUTTON_TOOLTIP = "Crear una nueva nota"
T.CHECK_SEND_BUTTON = "Puede enviarse"
T.CHECK_CAN_SEND_TOOLTIP = "Esta nota puede enviarse"
T.CHECK_NOT_SEND_TOOLTIP = "Esta nota no se enviará"

T.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Guardó %s"
T.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s por %s"
T.DETAILS_DATE_UNSAVED_FORMAT = "%s de %s"
T.DETAILS_SIZE_FORMAT = "- %d caracteres"
T.DETAILS_NOT_KNOWN_TEXT = "- no se guarda"
T.DETAILS_SENT_FORMAT = "- enviado %s"
T.TITLE_CHANGE_NOT_SAVED = "*"

T.SAVE_OPTION = "Guardar"
T.ADD_OPTION = "Agregar"
T.UPDATE_OPTION = "Actualizar"
T.RENAME_OPTION = "Cambiar nombre"
T.DELETE_OPTION = "Borrar"
T.SEND_OPTION = "Enviar a"
T.SEND_TO_TARGET = "Objetivo"
T.SEND_TO_PLAYER = "Personaje"
T.SEND_TO_INSTANCE = "Instancia"
T.SEND_TO_PARTY = "Gruop"
T.SEND_TO_RAID = "Banda"
T.SEND_TO_GUILD = "Hermandad"
T.SEND_TO_OFFICER = "Oficial"
T.SEND_TO_CHANNEL = "Canal"
T.CHANNEL_NAME_FORMAT = "%d. %s"

T.ENTER_PLAYER_NAME_TEXT = "Escribe el nombre del jugardor al que enviar:"
T.ENTER_NEW_TITLE_TEXT = "Escribe un nuevo título para esta nota:"
T.CONFIRM_REMOVE_FORMAT = "¿Seguro que desea borrar %q?"
T.CONFIRM_UPDATE_FORMAT = "¿Seguro que desea reemplazar %q con la versión de %s?"
T.CONFIRM_SERVER_CHANNEL_FORMAT = "¿Seguro que desea enviar %q al canal %s?"

T.NOTE_RECEIVED_FORMAT = "Notebook añadió nota %q de %s."

------------------------------------------------------------------------
-- Slash commands and responses
local C = Notebook.NOTEBOOK_COMMANDS

-- Slash commands
C.COMMAND_HELP = "ayuda"
C.COMMAND_LIST = "lista"
C.COMMAND_SHOW = "muestra"
C.COMMAND_HIDE = "oculta"
C.COMMAND_OPTIONS = "opciones"
C.COMMAND_DEBUGON = "debugon"
C.COMMAND_DEBUGOFF = "debugoff"
C.COMMAND_WELCOME = "bienvenida"
C.COMMAND_STATUS = "estado"

-- Slash command responses
C.COMMAND_DEBUGON_CONFIRM = "Depuración de Notebook está activada."
C.COMMAND_DEBUGOFF_CONFIRM = "Depuración de Notebook está desactivada."
C.COMMAND_LIST_CONFIRM = "Notebook contiene las siguientes notas:"
C.COMMAND_LIST_FORMAT = "- %s (%d caracteres, de %s, %s)"
C.COMMAND_STATUS_FORMAT = "Notebook contiene %d notas y se utiliza %.0fkB de memoria."

-- Error messages
C.ERROR_RENAME_NOT_UNIQUE_FORMAT = "Ya tienes una nota titulado %q. Títulos deben ser únicos."
C.ERROR_RENAME_EMPTY = "Títulos no pueden estar vacíos."
C.ERROR_SEND_COOLDOWN = "No puedes enviar otra nota todavía."
C.ERROR_SEND_INVALID = "Debes introducir un título y un canal valido."
C.ERROR_SEND_INVALID_NOTE = "No se puede encontrar una nota %q."
C.ERROR_SEND_EDITING = "No puedes enviar una nota con cambios sin guardar."
C.ERROR_SEND_RAID_LEADER = "No estás el líder o un asistente de la banda."
C.ERROR_SEND_NO_NAME = "Debes indroducir un nombre de personaje o un BattleTag."
C.ERROR_SEND_NO_CHANNEL = "Debes introducir un nombre de canal."
C.ERROR_SEND_INVALID_CHANNEL = "No se puede encontrar un canal %s."
C.ERROR_SEND_UNKNOWN_CHANNEL = "%q no es un tipo compatible de canal."

------------------------------------------------------------------------
-- Help text

Notebook.NOTEBOOK_SLASH = "/cuaderno"

Notebook.NOTEBOOK_HELP = {
	"Utilizar " ..  Notebook.NOTEBOOK_SLASH  ..  ", /notebook o /note con los siguientes comandos:",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_SHOW    .. " - mostrar Notebook",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_HIDE    .. " - ocultar Notebook",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_STATUS  .. " - informarle el estado de Notebook",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_LIST    .. " - enumerar las notas en su Notebook",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_WELCOME .. " - restaurar la nota Bienvenida",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_HELP    .. " - mostrar este ayuda",
	"Utilizarlo sin comando para mostrar o ocultar Notebook, o asignar una tecla.",
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.NOTEBOOK_FIRST_TIME_NOTE.title = "Bienvenido a Notebook!"
Notebook.NOTEBOOK_FIRST_TIME_NOTE.description = [[Notebook te permite escribar y guardar notas sobre diversos temas, y compartirlas con tus amigos, tu grupo, tu hermandad, y los canales de chat! Si normalmente utiliza macros para dar instrucciones al grupo, explicar explicar las reglas de saqueo, recordar listas de encantamientos, o propósitos similares -- Notebook puede ser útil para ti!

Para crearon una nueva nota, sólo clic en la boton "Crear" y escriba un título para la nota. Títulos pueden tener hasta 60 caracteres de largo, y pueden incluyir cualqier carácter. Pero, cada título tiene que ser único -- no puedes tener dos notas con el mismo título.

Después de crear la nota, puedes editarlo y guardarlo en cualquier momento. Notas pueden tener hasta 4096 caracters de largo. Sí necesitas más espacio, simplemente crear otra nota! No hay un límite en el número de notas que puedes tener.

Las funcionas más interesantes de Notebook son disponibles haciendo clic derecho sobre el título de una nota en la lista de notas. Esto aparecerá un menú con muchas opciones, incluyendo opciones para enviar la nota a otros jugadores en tu grupo, banda, o hermandad, por susurro, o por un canal de chat. (Antes de puedes enviar una nota, debes activar la opción "Puede enviarse" para esa nota específica, en el abajo del marco.)

Despúes de enviar una nota, debes esperar unos segundos antes de poder enviar otras. Recuerde, al igual que con los macros, es tu responsabilidad para evitar molestar a otros jugadores por el abuso de esta función!

Notebook reconocerá automáticamente las notas enviadas por otros jugadores, y las mostrará en la pestaña "Recientes" junto con las notas que ha enviado en esta sesión. Podrás guardar estas notas a su propia lista, o actualizar tu copia si ya tenías. (Si la nota no ha cambiado, verás tu propria noa existente allí.)

Espero que disfrutes de Notebook, y es te útil!

-- Cirk de Doomhammer]]