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
local L = Notebook.L

BINDING_NAME_NOTEBOOK_PANEL = "Mostrar/ocultar Notebook"

L.FRAME_TITLE_FORMAT = "Notebook de %s"
L.ALL_TAB = "Todas"
L.ALL_TAB_TOOLTIP = "Todas notas"
L.MINE_TAB = "Mis"
L.MINE_TAB_TOOLTIP_FORMAT = "Notas creadas por %s"
L.KNOWN_TAB = "Guardadas"
L.KNOWN_TAB_TOOLTIP = "Notas que tú ha guardado de otros jugadores"
L.RECENT_TAB = "Nuevas"
L.RECENT_TAB_TOOLTIP = "Notas que tú ha recibido recientemente"
L.SAVE_BUTTON = "Guardar"
L.SAVE_BUTTON_TOOLTIP = "Guardar los cambios actuales"
L.CANCEL_BUTTON = "Cancelar"
L.CANCEL_BUTTON_TOOLTIP = "Volver a la última versión guardada"
L.ADD_BUTTON = "Agregar"
L.ADD_BUTTON_TOOLTIP = "Agregar esta nota a la lista guardada"
L.UPDATE_BUTTON = "Actualizar"
L.UPDATE_BUTTON_TOOLTIP = "Actualizar su nota guadada con este nuevo texto"
L.NEW_BUTTON = "Crear"
L.NEW_BUTTON_TOOLTIP = "Crear una nueva nota"
L.CHECK_SEND_BUTTON = "Puede enviarse"
L.CHECK_CAN_SEND_TOOLTIP = "Esta nota puede enviarse"
L.CHECK_NOT_SEND_TOOLTIP = "Esta nota no se enviará"

L.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Guardó %s"
L.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s por %s"
L.DETAILS_DATE_UNSAVED_FORMAT = "%s de %s"
L.DETAILS_SIZE_FORMAT = "- %d caracteres"
L.DETAILS_NOT_KNOWN_TEXT = "- no se guarda"
L.DETAILS_SENT_FORMAT = "- enviado %s"
L.TITLE_CHANGE_NOT_SAVED = "*"

L.NOTE_RECEIVED_FORMAT = "Notebook añadió nota “%s” de %s."

-- Right-click menu
L.SAVE_OPTION = "Guardar"
L.ADD_OPTION = "Agregar"
L.UPDATE_OPTION = "Actualizar"
L.RENAME_OPTION = "Cambiar nombre"
L.DELETE_OPTION = "Borrar"
L.SEND_OPTION = "Enviar a"
L.SEND_TO_TARGET = "Objetivo"
L.SEND_TO_PLAYER = "Personaje"
L.SEND_TO_INSTANCE = "Instancia"
L.SEND_TO_PARTY = "Gruop"
L.SEND_TO_RAID = "Banda"
L.SEND_TO_GUILD = "Hermandad"
L.SEND_TO_OFFICER = "Oficial"
L.SEND_TO_CHANNEL = "Canal"
L.CHANNEL_NAME_FORMAT = "%d. %s"

-- Popup dialogs
L.ENTER_PLAYER_NAME_TEXT = "Escribe el nombre del jugardor al que enviar:"
L.ENTER_NEW_TITLE_TEXT = "Escribe un nuevo título para esta nota:"
L.CONFIRM_REMOVE_FORMAT = "¿Seguro que desea borrar “%s”?"
L.CONFIRM_UPDATE_FORMAT = "¿Seguro que desea reemplazar “%s” con la versión de %s?"
L.CONFIRM_SERVER_CHANNEL_FORMAT = "¿Seguro que desea enviar “%s” al canal %s?"

-- Slash commands
L.CMD_HELP = "ayuda"
L.CMD_LIST = "lista"
L.CMD_SHOW = "muestra"
L.CMD_HIDE = "oculta"
L.CMD_SEND = "envía"
L.CMD_OPTIONS = "opciones"
L.CMD_DEBUGON = "debugon"
L.CMD_DEBUGOFF = "debugoff"
L.CMD_WELCOME = "bienvenida"
L.CMD_STATUS = "estado"

-- Slash command responses
L.CMD_DEBUGON_CONFIRM = "Depuración de Notebook está activada."
L.CMD_DEBUGOFF_CONFIRM = "Depuración de Notebook está desactivada."
L.CMD_LIST_CONFIRM = "Notebook contiene las siguientes notas:"
L.CMD_LIST_FORMAT = "- %s (%d caracteres, de %s, %s)"
L.CMD_STATUS_FORMAT = "Notebook contiene %d notas y se utiliza %.0fkB de memoria."

-- Error messages
L.ERR_RENAME_NOT_UNIQUE_FORMAT = "Ya tienes una nota titulado “%s”. Títulos deben ser únicos."
L.ERR_RENAME_EMPTY = "Títulos no pueden estar vacíos."
L.ERR_SEND_COOLDOWN = "No puedes enviar otra nota todavía."
L.ERR_SEND_INVALID = "Debes introducir un título y un canal valido."
L.ERR_SEND_INVALID_NOTE = "No se puede encontrar una nota “%s”."
L.ERR_SEND_EDITING = "No puedes enviar una nota con cambios sin guardar."
L.ERR_SEND_RAID_LEADER = "No estás el líder o un asistente de la banda."
L.ERR_SEND_NO_NAME = "Debes indroducir un nombre de personaje o un BattleTag."
L.ERR_SEND_NO_CHANNEL = "Debes introducir un nombre de canal."
L.ERR_SEND_INVALID_CHANNEL = "No se puede encontrar un canal “%s”."
L.ERR_SEND_UNKNOWN_CHANNEL = "“%s” no es un tipo compatible de canal."

------------------------------------------------------------------------
-- Help text

Notebook.SLASH_COMMAND = "/cuaderno"

Notebook.NOTEBOOK_HELP = {
	"Utilizar /cuaderno, /notebook o /note con los siguientes comandos:",
	"- " .. L.CMD_SHOW    .. " - mostrar Notebook",
	"- " .. L.CMD_HIDE    .. " - ocultar Notebook",
	"- " .. L.CMD_STATUS  .. " - informarle el estado de Notebook",
	"- " .. L.CMD_LIST    .. " - enumerar las notas en su Notebook",
	"- " .. L.CMD_WELCOME .. " - restaurar la nota Bienvenida",
	"- " .. L.CMD_HELP    .. " - mostrar este ayuda",
	"Utilizarlo sin comando para mostrar o ocultar Notebook, o asignar una tecla.",
}

------------------------------------------------------------------------
--	First timer’s brief manual

L.WELCOME_NOTE_TITLE = "Bienvenido a Notebook!"
L.WELCOME_NOTE_DESCRIPTION = [[
Notebook te permite escribar y guardar notas sobre diversos temas, y compartirlas con tus amigos, tu grupo, tu hermandad, y los canales de chat! Si normalmente utiliza macros para dar instrucciones al grupo, explicar explicar las reglas de saqueo, recordar listas de encantamientos, o propósitos similares -- Notebook puede ser útil para ti!

Para crearon una nueva nota, sólo clic en la boton “Crear” y escriba un título para la nota. Títulos pueden tener hasta 60 caracteres de largo, y pueden incluyir cualqier carácter. Pero, cada título tiene que ser único -- no puedes tener dos notas con el mismo título.

Después de crear la nota, puedes editarlo y guardarlo en cualquier momento. Notas pueden tener hasta 4096 caracters de largo. Sí necesitas más espacio, simplemente crear otra nota! No hay un límite en el número de notas que puedes tener.

Las funcionas más interesantes de Notebook son disponibles haciendo clic derecho sobre el título de una nota en la lista de notas. Esto aparecerá un menú con muchas opciones, incluyendo opciones para enviar la nota a otros jugadores en tu grupo, banda, o hermandad, por susurro, o por un canal de chat. (Antes de puedes enviar una nota, debes activar la opción “Puede enviarse” para esa nota específica, en el abajo del marco.)

Despúes de enviar una nota, debes esperar unos segundos antes de poder enviar otras. Recuerde, al igual que con los macros, es tu responsabilidad para evitar molestar a otros jugadores por el abuso de esta función!

Notebook reconocerá automáticamente las notas enviadas por otros jugadores, y las mostrará en la pestaña “Recientes” junto con las notas que ha enviado en esta sesión. Podrás guardar estas notas a su propia lista, o actualizar tu copia si ya tenías. (Si la nota no ha cambiado, verás tu propria noa existente allí.)

Espero que disfrutes de Notebook, y es te útil!

-- Cirk de Doomhammer]]