--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2013
	http://www.wowinterface.com/downloads/info4544-Notebook
	http://www.curse.com/addons/wow/notebook
----------------------------------------------------------------------]]
--	Spanish Localization by Phanx

if not GetLocale():match("^es") then return end

BINDING_HEADER_NOTEBOOK_TITLE = "Notebook"
BINDING_NAME_NOTEBOOK_PANEL = "Mostrar/ocultar Notebook"

-- Miscellaneous text commands
NOTEBOOK_TEXT = {
	FRAME_TITLE_FORMAT = "Notebook de %s",
	ALL_TAB = "Todo",
	ALL_TAB_TOOLTIP = "Todas notas",
	MINE_TAB = UnitSex("player") == 3 and "Mía" or "Mío",
	MINE_TAB_TOOLTIP_FORMAT = "Notas creadas por %s",
	KNOWN_TAB = "Guardada",
	KNOWN_TAB_TOOLTIP = "Notas que tú ha guardado",
	RECENT_TAB = "Nuevo",
	RECENT_TAB_TOOLTIP = "Notas que tú ha recibido recientemente",
	SAVE_BUTTON = "Guardar",
	SAVE_BUTTON_TOOLTIP = "Guardar los cambios actuales",
	CANCEL_BUTTON = "Cancelar",
	CANCEL_BUTTON_TOOLTIP = "Volver a la última versión guardada",
	ADD_BUTTON = "Agregar",
	ADD_BUTTON_TOOLTIP = "Agregar esta nota a la lista guardada",
	UPDATE_BUTTON = "Actualizar",
	UPDATE_BUTTON_TOOLTIP = "Actualizar su nota guadada con este nuevo texto",
	NEW_BUTTON = "Crear",
	NEW_BUTTON_TOOLTIP = "Crear una nueva nota",
	CHECK_SEND_BUTTON = "Puede enviarse",
	CHECK_CAN_SEND_TOOLTIP = "Esta nota puede enviarse",
	CHECK_NOT_SEND_TOOLTIP = "Esta nota no se enviará",

	DETAILS_DATE_KNOWN_SAVED_FORMAT = "Guardó %s",
	DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s por %s",
	DETAILS_DATE_UNSAVED_FORMAT = "%s de %s",
	DETAILS_SIZE_FORMAT = "- %d caracteres",
	DETAILS_NOT_KNOWN_TEXT = "- no se guarda",
	DETAILS_SENT_FORMAT = "- enviado %s",
	TITLE_CHANGE_NOT_SAVED = "*",

	SAVE_OPTION = "Guardar",
	ADD_OPTION = "Agregar",
	UPDATE_OPTION = "Actualizar",
	RENAME_OPTION = "Cambiar nombre",
	DELETE_OPTION = "Borrar",
	SEND_OPTION = "Enviar a",
	SEND_TO_TARGET = "Objetivo",
	SEND_TO_PLAYER = "Personaje",
	SEND_TO_INSTANCE = "Instancia",
	SEND_TO_PARTY = "Gruop",
	SEND_TO_RAID = "Banda",
	SEND_TO_GUILD = "Hermandad",
	SEND_TO_OFFICER = "Oficial",
	SEND_TO_CHANNEL = "Canal",
	CHANNEL_NAME_FORMAT = "%d. %s",

	ENTER_PLAYER_NAME_TEXT = "Escribe el nombre del jugardor al que enviar:",
	ENTER_NEW_TITLE_TEXT = "Escribe un nuevo título para esta nota:",
	CONFIRM_REMOVE_FORMAT = "¿Seguro que desea borrar \"%s\"?",
	CONFIRM_UPDATE_FORMAT = "¿Seguro que desea reemplazar \"%s\" con la versión de %s?",
	CONFIRM_SERVER_CHANNEL_FORMAT = "¿Seguro que desea enviar \"%s\" al canal %s?",

	NOTE_RECEIVED_FORMAT = NOTEBOOK_EM.ON.."Notebook añadió nota \""..NOTEBOOK_EM.OFF.."%s"..NOTEBOOK_EM.ON.."\" de "..NOTEBOOK_EM.OFF.."%s",

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
	COMMAND_HELP = "ayuda",
	COMMAND_LIST = "lista",
	COMMAND_SHOW = "muestra",
	COMMAND_HIDE = "oculta",
	COMMAND_OPTIONS = "opciones",
	COMMAND_DEBUGON = "debugon",
	COMMAND_DEBUGOFF = "debugoff",
	COMMAND_WELCOME = "bienvenida",
	COMMAND_STATUS = "estado",

	-- Slash command responses
	COMMAND_DEBUGON_CONFIRM = "Depuración de Notebook está activada",
	COMMAND_DEBUGOFF_CONFIRM = "Depuración de Notebook está desactivada",
	COMMAND_LIST_CONFIRM = NOTEBOOK_EM.ON.."Notebook contiene las siguientes notas:"..NOTEBOOK_EM.OFF,
	COMMAND_LIST_FORMAT = NOTEBOOK_EM.ON.."- "..NOTEBOOK_EM.OFF.."%s "..NOTEBOOK_EM.ON.."(%d caracteres, de %s, %s)"..NOTEBOOK_EM.OFF,
	COMMAND_STATUS_FORMAT = NOTEBOOK_EM.ON.."Notebook contiene %d notas y se utiliza %.0fkB de memoria"..NOTEBOOK_EM.OFF,

	-- Error messages
	ERROR_RENAME_NOT_UNIQUE_FORMAT = NOTEBOOK_TEXT.ERROR..NOTEBOOK_EM.ON.."Ya tienes una nota titulado \""..NOTEBOOK_EM.OFF.."%s"..NOTEBOOK_EM.ON.."\" (títulos deben ser únicos)"..NOTEBOOK_EM.OFF,
	ERROR_RENAME_EMPTY = NOTEBOOK_TEXT.ERROR..NOTEBOOK_EM.ON.."Títulos no pueden estar vacíos."..NOTEBOOK_EM.OFF,
}

-- Help text
NOTEBOOK_DESCRIPTION = "Escribir y guardar notas, y compartirlas en el juego."
NOTEBOOK_HELP = {
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_HELP..NOTEBOOK_EM.OFF.." mostrar este ayuda",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_EM.OFF.."mostrar o ocultar el marco de Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_SHOW..NOTEBOOK_EM.OFF.." mostrar Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_HIDE..NOTEBOOK_EM.OFF.." ocultar Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_LIST..NOTEBOOK_EM.OFF.." listar las notas en su Notebook",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_WELCOME..NOTEBOOK_EM.OFF.." restaurar la nota Bienvenida",
	NOTEBOOK_EM.ON.."/notebook "..NOTEBOOK_COMMANDS.COMMAND_STATUS..NOTEBOOK_EM.OFF.." informar el estado de Notebook",
	"",
	"También puede utilizar "..NOTEBOOK_EM.ON.."/note"..NOTEBOOK_EM.OFF.." en vez de "..NOTEBOOK_EM.ON.."/notebook"..NOTEBOOK_EM.OFF.." y hay una tecla para mostrar y ocultar el marco de Notebook.",
}

------------------------------------------------------------------------
--	First timer's brief manual
------------------------------------------------------------------------

NOTEBOOK_FIRST_TIME_NOTE = {
	["title"] = "Bienvenido a Notebook!",
	["author"] = "Cirk",
	["date"] = "051224",
	["description"] = [[Notebook te permite escribar y guardar notas sobre diversos temas, y compartirlas con tus amigos, tu grupo, tu hermandad, y los canales de chat! Si normalmente utiliza macros para dar instrucciones al grupo, explicar explicar las reglas de saqueo, recordar listas de encantamientos, o propósitos similares -- Notebook puede ser útil para ti!

Para crearon una nueva nota, sólo clic en la boton "Crear" y escriba un título para la nota. Títulos pueden tener hasta 60 caracteres de largo, y pueden incluyir cualqier carácter. Pero, cada título tiene que ser único -- no puedes tener dos notas con el mismo título.

Después de crear la nota, puedes editarlo y guardarlo en cualquier momento. Notas pueden tener hasta 4096 caracters de largo. Sí necesitas más espacio, simplemente crear otra nota! No hay un límite en el número de notas que puedes tener.

Las funcionas más interesantes de Notebook son disponibles haciendo clic derecho sobre el título de una nota en la lista de notas. Esto aparecerá un menú con muchas opciones, incluyendo opciones para enviar la nota a otros jugadores en tu grupo, banda, o hermandad, por susurro, o por un canal de chat. (Antes de puedes enviar una nota, debes activar la opción "Puede enviarse" para esa nota específica, en el abajo del marco.)

Despúes de enviar una nota, debes esperar unos segundos antes de poder enviar otras. Recuerde, al igual que con los macros, es tu responsabilidad para evitar molestar a otros jugadores por el abuso de esta función!

Notebook reconocerá automáticamente las notas enviadas por otros jugadores, y las mostrará en la pestaña "Recientes" junto con las notas que ha enviado en esta sesión. Podrás guardar estas notas a su propia lista, o actualizar tu copia si ya tenías. (Si la nota no ha cambiado, verás tu propria noa existente allí.)

Espero que disfrutes de Notebook, y es te útil!

-- Cirk de Doomhammer]],
}