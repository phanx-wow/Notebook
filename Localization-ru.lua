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

BINDING_NAME_NOTEBOOK_PANEL = "Отобразить Блокнот"

-- Miscellaneous text commands
local T = Notebook.NOTEBOOK_TEXT

T.FRAME_TITLE_FORMAT = "Личный Блокнот %s"
T.ALL_TAB = "Все"
T.ALL_TAB_TOOLTIP = "Все заметки"
T.MINE_TAB = "Личные"
T.MINE_TAB_TOOLTIP_FORMAT = "Личные заметки %s"
T.KNOWN_TAB = "Сохраненные"
T.KNOWN_TAB_TOOLTIP = "Только Сохранить"
T.RECENT_TAB = "Отправ."
T.RECENT_TAB_TOOLTIP = "Отправленные заметки"
T.SAVE_BUTTON = "Сохранить"
T.SAVE_BUTTON_TOOLTIP = "Сохранить изменения"
T.CANCEL_BUTTON = "Отмена"
T.CANCEL_BUTTON_TOOLTIP = "Откат изменений заметки"
T.ADD_BUTTON = "Добавить"
T.ADD_BUTTON_TOOLTIP = "Добавить эту заметку в блокнот"
T.UPDATE_BUTTON = "Обновить"
--T.UPDATE_BUTTON_TOOLTIP = "Update your previously saved note with this new text"
T.NEW_BUTTON = "Новая"
T.NEW_BUTTON_TOOLTIP = "Создать новую заметку"
T.CHECK_SEND_BUTTON = "Возможно отпр."
T.CHECK_CAN_SEND_TOOLTIP = "Эту заметку возможно отправить"
T.CHECK_NOT_SEND_TOOLTIP = "Эту заметку невозможно отправить"

T.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Сохранено %s"
--T.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s by %s"
T.DETAILS_DATE_UNSAVED_FORMAT = "%s для %s"
T.DETAILS_SIZE_FORMAT = "- %d символов"
T.DETAILS_NOT_KNOWN_TEXT = "- Не сохранено"
T.DETAILS_SENT_FORMAT = "- Отправить %s"
T.TITLE_CHANGE_NOT_SAVED = "*"

T.SAVE_OPTION = "Сохранить"
T.ADD_OPTION = "Добавить"
T.UPDATE_OPTION = "Обновить"
T.RENAME_OPTION = "Переименовать"
T.DELETE_OPTION = "Удалить"
T.SEND_OPTION = "Отправить"
T.SEND_TO_TARGET = "Цель"
T.SEND_TO_PLAYER = "Игрок"
T.SEND_TO_INSTANCE = "Образец"
T.SEND_TO_PARTY = "Группа"
T.SEND_TO_RAID = "Рейд"
T.SEND_TO_GUILD = "Гильдия"
T.SEND_TO_OFFICER = "Офицеры"
T.SEND_TO_CHANNEL = "Канал"
T.CHANNEL_NAME_FORMAT = "%d. %s"

T.ENTER_PLAYER_NAME_TEXT = "Введите имя игрока что бы отправить:"
T.ENTER_NEW_TITLE_TEXT = "Введите название новой заметки:"
T.CONFIRM_REMOVE_FORMAT = "Вы действительно хотите удалить %q?"
T.CONFIRM_UPDATE_FORMAT = "Хоите заменить %q заметку от %s?"
T.CONFIRM_SERVER_CHANNEL_FORMAT = "Хотите отправить %q в канал %s ?"

T.NOTE_RECEIVED_FORMAT = "В Блокнот Добавлена Заметка %q от %s"

------------------------------------------------------------------------
-- Slash commands and responses
local C = Notebook.NOTEBOOK_COMMANDS

-- Slash commands
C.COMMAND_HELP = "помощь"
C.COMMAND_LIST = "Лист"
C.COMMAND_SHOW = "показать"
C.COMMAND_HIDE = "скрыть"
C.COMMAND_OPTIONS = "опции"
--C.COMMAND_DEBUGON = "debugon"
--C.COMMAND_DEBUGOFF = "debugoff"
--C.COMMAND_WELCOME = "welcome"
C.COMMAND_STATUS = "статус"

-- Slash command responses
C.COMMAND_DEBUGON_CONFIRM = "Отладка Блокнота Включена"
C.COMMAND_DEBUGOFF_CONFIRM = "Отладка Блокнота Выключена"
--C.COMMAND_LIST_CONFIRM = "Notebook contains the following notes:"
--C.COMMAND_LIST_FORMAT = "- %s (%d characters, by %s, %s)"
C.COMMAND_STATUS_FORMAT = "Блокнот содержит %d заметок и они занимают %.0fkB памяти"

-- Error messages
--C.ERROR_RENAME_NOT_UNIQUE_FORMAT = "You already have a note titled %q. Titles must be unique."
--C.ERROR_RENAME_EMPTY = "You cannot have an empty title."
--C.ERROR_SEND_COOLDOWN = "You cannot send another note just yet."
--C.ERROR_SEND_INVALID = "You must provide a valid note title and channel."
--C.ERROR_SEND_INVALID_NOTE = "Could not find a note titled %q."
--C.ERROR_SEND_EDITING = "You cannot send a note with unsaved changes."
--C.ERROR_SEND_RAID_LEADER = "You are not the raid leader or assistant."
--C.ERROR_SEND_NO_NAME = "You must enter a character name or BattleTag."
--C.ERROR_SEND_NO_CHANNEL = "You must enter a channel name."
--C.ERROR_SEND_INVALID_CHANNEL = "Could not find a channel %s."
--C.ERROR_SEND_UNKNOWN_CHANNEL = "%q is not a supported channel type."

------------------------------------------------------------------------
-- Help text

Notebook.NOTEBOOK_SLASH = "/блокнот"

Notebook.NOTEBOOK_HELP = {
	"Введите " .. Notebook.NOTEBOOK_SLASH .. ", /notebook или /note с этих команд:", -- needs check
	"- " .. NOTEBOOK_COMMANDS.COMMAND_SHOW    .. " - Показывает окно Блокнота",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_HIDE    .. " - Уберает окно Блокнота",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_LIST    .. " - Выводит лист названий заметок и данными о них",
--	"- " .. NOTEBOOK_COMMANDS.COMMAND_WELCOME .. " - restores the Welcome note",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_STATUS  .. " - Выводит статус Блокнота, кол-во заметок и кол-во исп. памяти",
	"- " .. NOTEBOOK_COMMANDS.COMMAND_HELP .. " Показывает это сообщение:",
	"Для вызова Блокнота наберите в чате используйте данную команду для кнопки вызова окна Блокнота.", -- needs check
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.NOTEBOOK_FIRST_TIME_NOTE.title = "Добро Пожаловать в Блокнот!"
Notebook.NOTEBOOK_FIRST_TIME_NOTE.description = [[Блокнот позволяет записывать, сохранять и упорядочивать ваши заметки на самые разные темы. Кроме этого вы так же можете отправить как саму заметку так и ее текст игроку или в любой из каналов. Например в общий канал, канал гильдии, канал офицеров канал группы или рейда!

Что бы создать новую заметку нажмите на кнопку “Новая” после введите название. Название заметок может содержать до 60 абсолютно любых символов, но должно быть уникальным! Например вы не сможете создать две заметки с одинаковыми названиями “Развлечения” и “Развлечения”, используйте фантазию и назовите вторую заметку “Развлечения 2” или “Другие Развлечения”

После того как вы создали новую заметку вы можете внести в нее нужный текст. Есть один нюанс, если вы кликаете по окну где вводить заметку и ввод символов не возможен, совершите клик в верхней части этого окна примерно по середине. Всего любая заметка может содержать до 4096 символов.

Одна из особенностей Блокнота эта отправка ваших заметок, в каналы чата или другим обладателям Блокнота. Для этого Кликните по названию заметки в списке и выберите нужный пункт в контекстном меню. Отправлять заметки можно с любые каналы чата!

После отправки заметки нужно подождать несколько секунд прежде чем вы сможете отправить еще одну.

Блокнот так же распознает заметки присланные другими игроками, что бы посмотреть их зайдите во вкладку “Отправ.” это сокращенно отправленные, из-за того что слово большое оно попросту не вместилось, по этому пришлось сократить.

Я надеюсь, вам понравится Блокнот, и найдете ее полезной!

-- Cirk - Doomhammer

(Перевод на Русский: Джоан - Подземье)]]