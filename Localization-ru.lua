--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2016 Phanx <addons@phanx.net>. All rights reserved.
	https://github.com/Phanx/Notebook
	https://mods.curse.com/addons/wow/notebook
	https://www.wowinterface.com/downloads/info4544-Notebook.html
----------------------------------------------------------------------]]
--	Перевод на Русский: Джоан-Подземье, Су-Гордунни

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
L.UPDATE_BUTTON_TOOLTIP = "Обновить существующую заметку этим текстом"
L.NEW_BUTTON = "Новая"
L.NEW_BUTTON_TOOLTIP = "Создать новую заметку"
L.CHECK_SEND_BUTTON = "Возможно отпр."
L.CHECK_CAN_SEND_TOOLTIP = "Эту заметку возможно отправить"
L.CHECK_NOT_SEND_TOOLTIP = "Эту заметку невозможно отправить"

L.DETAILS_DATE_KNOWN_SAVED_FORMAT = "Сохранено %s"
L.DETAILS_DATE_KNOWN_UPDATED_FORMAT = "%s от %s"
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
L.ENTER_PLAYER_NAME_TEXT = "Укажите имя игрока-получателя для отправки:"
L.ENTER_NEW_TITLE_TEXT = "Укажите название новой заметки:"
L.CONFIRM_REMOVE_FORMAT = "Вы действительно хотите удалить “%s”?"
L.CONFIRM_UPDATE_FORMAT = "Хоите заменить “%s” заметку от %s?"
L.CONFIRM_SERVER_CHANNEL_FORMAT = "Хотите отправить “%s” в канал %s ?"

-- Slash commands
L.CMD_HELP = "помощь"
L.CMD_LIST = "лист"
L.CMD_SHOW = "показать"
L.CMD_HIDE = "скрыть"
L.CMD_SEND = "послать"
L.CMD_OPTIONS = "опции"
L.CMD_DEBUGON = "debugon"
L.CMD_DEBUGOFF = "debugoff"
L.CMD_WELCOME = "welcome"
L.CMD_STATUS = "статус"

-- Slash command responses
L.CMD_DEBUGON_CONFIRM = "Отладка Блокнота Включена"
L.CMD_DEBUGOFF_CONFIRM = "Отладка Блокнота Выключена"
L.CMD_LIST_CONFIRM = "Блокнот содержит следующие заметки:"
L.CMD_LIST_FORMAT = "- %s (%d символов, от %s, %s)"
L.CMD_STATUS_FORMAT = "Блокнот содержит %d заметок и они занимают %.0fkB памяти"

-- Error messages
L.ERR_RENAME_NOT_UNIQUE_FORMAT = "Заметка с названием “%s” уже существует. Названия должны быть уникальны."
L.ERR_RENAME_EMPTY = "Название заметки не должно быть пустым."
L.ERR_SEND_COOLDOWN = "Пока невозможно отправить. Попробуйте позже."
L.ERR_SEND_INVALID = "Укажите корректные названия заметки и канала."
L.ERR_SEND_INVALID_NOTE = "Заметка с названием “%s” не найдена."
L.ERR_SEND_EDITING = "Невозможно отправить заметку с несохраненными изменениями."
L.ERR_SEND_RAID_LEADER = "Вы не являетесь лидером или ассистентом рейда."
L.ERR_SEND_NO_NAME = "Необходимо указать имя персонажа или BattleTag."
L.ERR_SEND_NO_CHANNEL = "Необходимо указать название канала."
L.ERR_SEND_INVALID_CHANNEL = "Канал “%s” не найден."
L.ERR_SEND_UNKNOWN_CHANNEL = "“%s” не является каналом поддерживаемого типа."

------------------------------------------------------------------------
-- Help text

Notebook.SLASH_COMMAND = "/блокнот"

Notebook.HELP_TEXT = {
	"Наберите /блокнот, /notebook или /note с этих команд:", -- needs check
	"- " .. L.CMD_SHOW    .. " - Показать окно Блокнота",
	"- " .. L.CMD_HIDE    .. " - Скрыть окно Блокнота",
	"- " .. L.CMD_LIST    .. " - Вывести лист названий заметок с данными о них",
	"- " .. L.CMD_WELCOME .. " - Восстановить заметку \"Добро Пожаловать в Блокнот!\"",
	"- " .. L.CMD_STATUS  .. " - Вевести статус Блокнота, количествозаметок и объем использованной памяти",
	"- " .. L.CMD_HELP    .. " - Показать это сообщение:",
	"Для вызова Блокнота наберите данную команду в чате или используйте ее для назначения кнопки вызова окна Блокнота.", 
}

------------------------------------------------------------------------
--	First timer's brief manual

L.WELCOME_NOTE_TITLE = "Добро Пожаловать в Блокнот!"
L.WELCOME_NOTE_DESCRIPTION = [[
Блокнот позволяет записывать, сохранять и упорядочивать ваши заметки на самые разные темы. Кроме этого вы так же можете отправить как саму заметку так и ее текст игроку или в любой из каналов. Например в общий канал, канал гильдии, канал офицеров канал группы или рейда!

Что бы создать новую заметку нажмите на кнопку “Новая” после укажите название. Название заметок может содержать до 60 абсолютно любых символов, но должно быть уникальным! Например вы не сможете создать две заметки с одинаковыми названиями “Развлечения” и “Развлечения”, используйте фантазию и назовите вторую заметку “Развлечения 2” или “Другие Развлечения”

После того как вы создали новую заметку вы можете внести в нее нужный текст. Есть один нюанс, если вы кликаете по окну где вводить заметку и ввод символов не возможен, совершите клик в верхней части этого окна примерно по середине. Всего любая заметка может содержать до 4096 символов.

Одна из особенностей Блокнота эта отправка ваших заметок, в каналы чата или другим обладателям Блокнота. Для этого Кликните по названию заметки в списке и выберите нужный пункт в контекстном меню. Отправлять заметки можно с любые каналы чата!

После отправки заметки нужно подождать несколько секунд прежде чем вы сможете отправить еще одну.

Блокнот так же распознает заметки присланные другими игроками, что бы посмотреть их зайдите во вкладку “Отправ.” это сокращенно отправленные, из-за того что слово большое оно попросту не вместилось, по этому пришлось сократить.

Я надеюсь, вам понравится Блокнот, и найдете ее полезной!

-- Cirk - Doomhammer

(Перевод на Русский: Джоан - Подземье)]]
