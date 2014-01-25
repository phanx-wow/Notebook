--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game
	Written by Cirk of Doomhammer, 2005-2009
	Updated by Phanx with permission, 2012-2013
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
T.UPDATE_BUTTON_TOOLTIP = "Update your previously saved note with this new text" -- needs check
T.NEW_BUTTON = "Новая"
T.NEW_BUTTON_TOOLTIP = "Создать новую заметку"
T.CHECK_SEND_BUTTON = "Возможно отпр."
T.CHECK_CAN_SEND_TOOLTIP = "Эту заметку возможно отправить"
T.CHECK_NOT_SEND_TOOLTIP = "Эту заметку невозможно отправить"

T.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Сохранено %s"
T.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s by %s" -- needs check
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
T.CONFIRM_REMOVE_FORMAT = "Вы действительно хотите удалить \"%s\"?"
T.CONFIRM_UPDATE_FORMAT = "Хоите заменить \"%s\" заметку от %s?"
T.CONFIRM_SERVER_CHANNEL_FORMAT = "Хотите отправить \"%s\" в канал %s ?"

T.NOTE_RECEIVED_FORMAT = NOTEBOOK_EM.ON .. "В Блокнот Добавлена Заметка \"" .. NOTEBOOK_EM.OFF .. "%s" .. NOTEBOOK_EM.ON .. "\" от " .. NOTEBOOK_EM.OFF .. "%s"

------------------------------------------------------------------------
-- Slash commands and responses
local C = Notebook.NOTEBOOK_COMMANDS

-- Slash commands
C.COMMAND_HELP = "помощь"
C.COMMAND_LIST = "Лист"
C.COMMAND_SHOW = "показать"
C.COMMAND_HIDE = "скрыть"
C.COMMAND_OPTIONS = "опции"
C.COMMAND_DEBUGON = "debugon" -- needs check
C.COMMAND_DEBUGOFF = "debugoff" -- needs check
C.COMMAND_WELCOME = "welcome" -- needs check
C.COMMAND_STATUS = "статус"

-- Slash command responses
C.COMMAND_DEBUGON_CONFIRM = "Отладка Блокнота Включена"
C.COMMAND_DEBUGOFF_CONFIRM = "Отладка Блокнота Выключена"
C.COMMAND_LIST_CONFIRM = NOTEBOOK_EM.ON .. "Notebook contains the following notes:" .. NOTEBOOK_EM.OFF -- needs check
C.COMMAND_LIST_FORMAT = NOTEBOOK_EM.ON .. "- " .. NOTEBOOK_EM.OFF .. "%s " .. NOTEBOOK_EM.ON .. "(%d characters, by %s, %s)" .. NOTEBOOK_EM.OFF -- needs check
C.COMMAND_STATUS_FORMAT = NOTEBOOK_EM.ON .. "Блокнот содержит %d заметок и они занимают %.0fkB памяти" .. NOTEBOOK_EM.OFF

-- Error messages
C.ERROR_RENAME_NOT_UNIQUE_FORMAT = NOTEBOOK_TEXT.ERROR .. NOTEBOOK_EM.ON .. "You already have a note titled \"" .. NOTEBOOK_EM.OFF .. "%s" .. NOTEBOOK_EM.ON .. "\" (titles must be unique)" .. NOTEBOOK_EM.OFF -- needs check
C.ERROR_RENAME_EMPTY = NOTEBOOK_TEXT.ERROR .. NOTEBOOK_EM.ON .. "You cannot have an empty title" .. NOTEBOOK_EM.OFF -- needs check

------------------------------------------------------------------------
-- Help text

Notebook.NOTEBOOK_SLASH = "/блокнот"

Notebook.NOTEBOOK_HELP = {
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_HELP .. NOTEBOOK_EM.OFF .. " Показывает это сообщение, с командами.",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_EM.OFF .. "Показывает окно Блокнота",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_SHOW .. NOTEBOOK_EM.OFF .. " Показывает окно Блокнота",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_HIDE .. NOTEBOOK_EM.OFF .. " Уберает окно Блокнота",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_LIST .. NOTEBOOK_EM.OFF .. " Выводит лист названий заметок и данными о них",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_WELCOME .. NOTEBOOK_EM.OFF .. " restores the Welcome note",
	NOTEBOOK_EM.ON .. "/notebook " .. NOTEBOOK_COMMANDS.COMMAND_STATUS .. NOTEBOOK_EM.OFF .. " Выводит статус Блокнота, кол-во заметок и кол-во исп. памяти",
	"",
	"Для вызова Блокнота наберите в чате " .. NOTEBOOK_EM.ON .. "/note" .. NOTEBOOK_EM.OFF .. " или " .. NOTEBOOK_EM.ON .. "/notebook" .. NOTEBOOK_EM.OFF .. " используйте данную команду для кнопки вызова окна Блокнота.",
}

------------------------------------------------------------------------
--	First timer's brief manual

Notebook.NOTEBOOK_FIRST_TIME_NOTE["title"] = "Добро Пожаловать в Блокнот!"
Notebook.NOTEBOOK_FIRST_TIME_NOTE["description"] = [[Блокнот позволяет записывать, сохранять и упорядочивать ваши заметки на самые разные темы. Кроме этого вы так же можете отправить как саму заметку так и ее текст игроку или в любой из каналов. Например в общий канал, канал гильдии, канал офицеров канал группы или рейда!

Что бы создать новую заметку нажмите на кнопку “Новая” после введите название. Название заметок может содержать до 60 абсолютно любых символов, но должно быть уникальным! Например вы не сможете создать две заметки с одинаковыми названиями “Развлечения” и “Развлечения”, используйте фантазию и назовите вторую заметку “Развлечения 2” или “Другие Развлечения”

После того как вы создали новую заметку вы можете внести в нее нужный текст. Есть один нюанс, если вы кликаете по окну где вводить заметку и ввод символов не возможен, совершите клик в верхней части этого окна примерно по середине. Всего любая заметка может содержать до 4096 символов.

Одна из особенностей Блокнота эта отправка ваших заметок, в каналы чата или другим обладателям Блокнота. Для этого Кликните по названию заметки в списке и выберите нужный пункт в контекстном меню. Отправлять заметки можно с любые каналы чата!

После отправки заметки нужно подождать несколько секунд прежде чем вы сможете отправить еще одну.

Блокнот так же распознает заметки присланные другими игроками, что бы посмотреть их зайдите во вкладку “Отправ.” это сокращенно отправленные, из-за того что слово большое оно попросту не вместилось, по этому пришлось сократить.

Я надеюсь, вам понравится Блокнот, и найдете ее полезной!

-- Cirk - Doomhammer

(Перевод на Русский: Джоан - Подземье)]]