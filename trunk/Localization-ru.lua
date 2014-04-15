--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2014
	http://www.wowinterface.com/downloads/info4544-Notebook
	http://www.curse.com/addons/wow/notebook
----------------------------------------------------------------------]]
--	Перевод на Русский: Джоан-Подземье

if GetLocale() ~= "ruRU" then return end
local NOTEBOOK, Notebook = ...
local T = Notebook.L

BINDING_NAME_NOTEBOOK_PANEL = "Отобразить Блокнот"

L.FRAME_TITLE_FORMAT = "Личный Блокнот %s"
L.ALL_TAB = "Все"
L.ALL_TAB_TOOLTIP = "Все заметки"
L.MINE_TAB = "Личные"
L.MINE_TAB_TOOLTIP_FORMAT = "Личные заметки %s"
L.KNOWN_TAB = "Сохраненные"
L.KNOWN_TAB_TOOLTIP = "Только Сохранить"
L.RECENT_TAB = "Отправ."
L.RECENT_TAB_TOOLTIP = "Отправленные заметки"
L.SAVE_BUTTON = "Сохранить"
L.SAVE_BUTTON_TOOLTIP = "Сохранить изменения"
L.CANCEL_BUTTON = "Отмена"
L.CANCEL_BUTTON_TOOLTIP = "Откат изменений заметки"
L.ADD_BUTTON = "Добавить"
L.ADD_BUTTON_TOOLTIP = "Добавить эту заметку в блокнот"
L.UPDATE_BUTTON = "Обновить"
--L.UPDATE_BUTTON_TOOLTIP = "Update your previously saved note with this new text"
L.NEW_BUTTON = "Новая"
L.NEW_BUTTON_TOOLTIP = "Создать новую заметку"
L.CHECK_SEND_BUTTON = "Возможно отпр."
L.CHECK_CAN_SEND_TOOLTIP = "Эту заметку возможно отправить"
L.CHECK_NOT_SEND_TOOLTIP = "Эту заметку невозможно отправить"

L.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Сохранено %s"
--L.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s by %s"
L.DETAILS_DATE_UNSAVED_FORMAT = "%s для %s"
L.DETAILS_SIZE_FORMAT = "- %d символов"
L.DETAILS_NOT_KNOWN_TEXT = "- Не сохранено"
L.DETAILS_SENT_FORMAT = "- Отправить %s"
L.TITLE_CHANGE_NOT_SAVED = "*"

L.NOTE_RECEIVED_FORMAT = "В Блокнот Добавлена Заметка “%s” от %s"

-- Right-click menu
L.SAVE_OPTION = "Сохранить"
L.ADD_OPTION = "Добавить"
L.UPDATE_OPTION = "Обновить"
L.RENAME_OPTION = "Переименовать"
L.DELETE_OPTION = "Удалить"
L.SEND_OPTION = "Отправить"
L.SEND_TO_TARGET = "Цель"
L.SEND_TO_PLAYER = "Игрок"
L.SEND_TO_INSTANCE = "Образец"
L.SEND_TO_PARTY = "Группа"
L.SEND_TO_RAID = "Рейд"
L.SEND_TO_GUILD = "Гильдия"
L.SEND_TO_OFFICER = "Офицеры"
L.SEND_TO_CHANNEL = "Канал"
L.CHANNEL_NAME_FORMAT = "%d. %s"

-- Popup dialogs
L.ENTER_PLAYER_NAME_TEXT = "Введите имя игрока что бы отправить:"
L.ENTER_NEW_TITLE_TEXT = "Введите название новой заметки:"
L.CONFIRM_REMOVE_FORMAT = "Вы действительно хотите удалить “%s”?"
L.CONFIRM_UPDATE_FORMAT = "Хоите заменить “%s” заметку от %s?"
L.CONFIRM_SERVER_CHANNEL_FORMAT = "Хотите отправить “%s” в канал %s ?"

-- Slash commands
C.CMD_HELP = "помощь"
C.CMD_LIST = "лист"
C.CMD_SHOW = "показать"
C.CMD_HIDE = "скрыть"
L.CMD_SEND = "послать"
C.CMD_OPTIONS = "опции"
--C.CMD_DEBUGON = "debugon"
--C.CMD_DEBUGOFF = "debugoff"
--C.CMD_WELCOME = "welcome"
C.CMD_STATUS = "статус"

-- Slash command responses
C.CMD_DEBUGON_CONFIRM = "Отладка Блокнота Включена"
C.CMD_DEBUGOFF_CONFIRM = "Отладка Блокнота Выключена"
--C.CMD_LIST_CONFIRM = "Notebook contains the following notes:"
--C.CMD_LIST_FORMAT = "- %s (%d characters, by %s, %s)"
C.CMD_STATUS_FORMAT = "Блокнот содержит %d заметок и они занимают %.0fkB памяти"

-- Error messages
--C.ERR_RENAME_NOT_UNIQUE_FORMAT = "You already have a note titled “%s”. Titles must be unique."
--C.ERR_RENAME_EMPTY = "You cannot have an empty title."
--C.ERR_SEND_COOLDOWN = "You cannot send another note just yet."
--C.ERR_SEND_INVALID = "You must provide a valid note title and channel."
--C.ERR_SEND_INVALID_NOTE = "Could not find a note titled “%s”."
--C.ERR_SEND_EDITING = "You cannot send a note with unsaved changes."
--C.ERR_SEND_RAID_LEADER = "You are not the raid leader or assistant."
--C.ERR_SEND_NO_NAME = "You must enter a character name or BattleTag."
--C.ERR_SEND_NO_CHANNEL = "You must enter a channel name."
--C.ERR_SEND_INVALID_CHANNEL = "Could not find a channel “%s”."
--C.ERR_SEND_UNKNOWN_CHANNEL = "“%s” is not a supported channel type."

------------------------------------------------------------------------
-- Help text

Notebook.SLASH_COMMAND = "/блокнот"

Notebook.HELP_TEXT = {
	"Введите /блокнот, /notebook или /note с этих команд:", -- needs check
	"- " .. NOTEBOOK_COMMANDS.CMD_SHOW    .. " - Показывает окно Блокнота",
	"- " .. NOTEBOOK_COMMANDS.CMD_HIDE    .. " - Уберает окно Блокнота",
	"- " .. NOTEBOOK_COMMANDS.CMD_LIST    .. " - Выводит лист названий заметок и данными о них",
--	"- " .. NOTEBOOK_COMMANDS.CMD_WELCOME .. " - restores the Welcome note",
	"- " .. NOTEBOOK_COMMANDS.CMD_STATUS  .. " - Выводит статус Блокнота, кол-во заметок и кол-во исп. памяти",
	"- " .. NOTEBOOK_COMMANDS.CMD_HELP .. " Показывает это сообщение:",
	"Для вызова Блокнота наберите в чате используйте данную команду для кнопки вызова окна Блокнота.", -- needs check
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.WELCOME_NOTE.title = "Добро Пожаловать в Блокнот!"
Notebook.WELCOME_NOTE.description = [[
Блокнот позволяет записывать, сохранять и упорядочивать ваши заметки на самые разные темы. Кроме этого вы так же можете отправить как саму заметку так и ее текст игроку или в любой из каналов. Например в общий канал, канал гильдии, канал офицеров канал группы или рейда!

Что бы создать новую заметку нажмите на кнопку “Новая” после введите название. Название заметок может содержать до 60 абсолютно любых символов, но должно быть уникальным! Например вы не сможете создать две заметки с одинаковыми названиями “Развлечения” и “Развлечения”, используйте фантазию и назовите вторую заметку “Развлечения 2” или “Другие Развлечения”

После того как вы создали новую заметку вы можете внести в нее нужный текст. Есть один нюанс, если вы кликаете по окну где вводить заметку и ввод символов не возможен, совершите клик в верхней части этого окна примерно по середине. Всего любая заметка может содержать до 4096 символов.

Одна из особенностей Блокнота эта отправка ваших заметок, в каналы чата или другим обладателям Блокнота. Для этого Кликните по названию заметки в списке и выберите нужный пункт в контекстном меню. Отправлять заметки можно с любые каналы чата!

После отправки заметки нужно подождать несколько секунд прежде чем вы сможете отправить еще одну.

Блокнот так же распознает заметки присланные другими игроками, что бы посмотреть их зайдите во вкладку “Отправ.” это сокращенно отправленные, из-за того что слово большое оно попросту не вместилось, по этому пришлось сократить.

Я надеюсь, вам понравится Блокнот, и найдете ее полезной!

-- Cirk - Doomhammer

(Перевод на Русский: Джоан - Подземье)]]