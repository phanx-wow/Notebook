--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2015 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info4544-Notebook.html
	http://www.curse.com/addons/wow/notebook
	https://github.com/Phanx/Notebook
----------------------------------------------------------------------]]

local NOTEBOOK, Notebook = ...
local L = Notebook.L

local NotebookFrame = CreateFrame("Frame", "NotebookFrame", UIParent)

------------------------------------------------------------------------
-- Constants

local LIST_BUTTON_COUNT  = 7
local LIST_BUTTON_HEIGHT = 16

------------------------------------------------------------------------
-- State variables

local selectedNote

------------------------------------------------------------------------
-- Upvalues

local editBox, listButtons

------------------------------------------------------------------------
-- Update the frame

function Notebook:UpdateFrame(offset, autoScroll)
	-- Don't use self in here, as it can be Notebook or NotebookFrame
	-- depending on how this got called.
	if not NotebookFrame:IsShown() then return end
	Notebook:Print("UpdateFrame")

	-- TODO: filter stuff
	local numNotes = #Notebook.sortedTitles
	local currentOffset = FauxScrollFrame_GetOffset(NotebookFrame.listScrollFrame)
	if not offset then
		offset = currentOffset
	end
	if offset ~= currentOffset then
		FauxScrollFrame_SetOffset(NotebookFrame.listScrollFrame, offset)
		NotebookFrame.listScrollFrame.ScrollBar:SetValue(offset * LIST_BUTTON_HEIGHT)
	end

	for i = 1, LIST_BUTTON_COUNT do
		local button = listButtons[i]
		local title = Notebook.sortedTitles[i + offset]
		local note = title and Notebook.notes[title]
		if note then
			Notebook:Print("---", i + offset, title)
			button:SetText(title)
			-- TODO: asterisk if not saved
			-- TODO: color by known / unknown
			button:Show()
		else
			Notebook:Print("---", i)
			button:Hide()
			button:SetText(nil)
			button.tooltipText = nil
		end
	end

	FauxScrollFrame_Update(NotebookFrame.listScrollFrame, numNotes, LIST_BUTTON_COUNT, LIST_BUTTON_HEIGHT)
	NotebookFrame:ShowNote(selectedNote)
end

------------------------------------------------------------------------
-- Display a specific note

-- TODO: move to core
Notebook.state = {}

function NotebookFrame:ShowNote(title)
	Notebook:Print("ShowNote", title)
	local note = Notebook.notes[title]
	selectedNote = note or nil

	-- Update list buttons
	for i = 1, LIST_BUTTON_COUNT do
		local button = listButtons[i]
		if button:GetText() == selectedNote then
			button:LockHighlight()
		else
			button:UnlockHighlight()
		end
	end

	-- TODO: handle non-known notes

	-- Update "Can Send" checkbox (checked, enabled/known)
	self:UpdateCanSend(note and note.canSend, true)

	-- Update text area (text, known)
	self:SetText(note and note.text or "", true)
end

------------------------------------------------------------------------
-- Update various parts of the frame

function NotebookFrame:SetText(text, known)
	-- TODO: handle non-known notes
	-- For notes that are known (known is true) we use the scrolling editbox
	-- to show the text.  In order to get the scrolling editbox to play nicely
	-- when we reset its text contents (specifically to force the scrollbar to
	-- go to the top of the text rather than the bottom) we have to jump
	-- through a few hoops, which is done between this function and the
	-- editbox scripts in the XML file.  Basically the function here sets some
	-- flags to reset the cursor position when the actual text update occurs,
	-- or when a cursor update occurs (if the text didn't change), and in the
	-- case where neither the text or cursor position changed, we set a
	-- private variable that ScrollingEdit_OnUpdate uses (normally set by the
	-- ScrollingEdit_OnCursorChanged function) and trigger an OnUpdate call.
	-- The case where we are setting the editbox to the empty string has to be
	-- dealt with as a special case due to the way the editbox doesn't perform
	-- updates correctly if it is empty.  To avoid that we set instead a
	-- special character to force a text update, and set a flag to request the
	-- XML script code to reset the contents back to empty (which will occur
	-- after the editbox scrolling, etc., has been updated).
	-- For notes that are not known (known is nil or false) we instead use the
	-- scrolling textbox to display the text, which is a little simpler to
	-- reset to the top of the text when needed.
	-- This function also stores the id of the note being edited or displayed
	-- in NotebookFrame object itself, so that this can be checked for easily
	-- when changing between tabs or knowing when to start an edit.
	self.textScrollFrame:Hide()
	self.editScrollFrame:Show()
	self.editBox:ClearFocus()
	if text == "" then
		-- Set a fake string into the editbox, noting that it is important
		-- that this string doesn't match what the editbox has in it
		-- already (or else it won't generate a OnTextUpdate event) so we
		-- use a non-visible non-enterable character simply to avoid
		-- having to check the current contents.
		self.editBox.textResetToEmpty = true
		self.editBox:SetText("\032")
	else
		self.editBox:SetText(text)
		self.editBox:SetCursorPosition(0)
	end
	self.editBox.textReset = true
	self.editBox.cursorOffset = 0
	ScrollingEdit_OnUpdate(self.editBox, 0, self.editScrollFrame)
end

function NotebookFrame:SetCanSendCheckbox(checked, enabled)
	local check = self.canSendCheckButton
	check:SetEnabled(enabled)
	check:SetChecked(checked)
	if enabled and GameTooltip:IsOwned(check) then
		GameTooltip:SetText(checked and self.tooltipTextOn or self.tooltipTextOff)
	end
end		

------------------------------------------------------------------------
-- Initialize frame properties

UIPanelWindows["NotebookFrame"] = { area = "left", pushable = 3, whileDead = 1, xOffset = -16, yOffset = 12 }
tinsert(UISpecialFrames, "NotebookFrame")

NotebookFrame:SetSize(384, 512)
NotebookFrame:SetHitRectInsets(10, 34, 8, 72)
NotebookFrame:SetToplevel(true)
NotebookFrame:EnableMouse(true)
NotebookFrame:SetMovable(true)

NotebookFrame:SetScript("OnShow", function(self)
	Notebook:Print("Frame:OnShow")
	if self.Setup then
		self:Setup()
	end
	local name = UnitName("player")
	self.title:SetFormattedText(L["%s’s Notebook"], name)
	self.tabMine.tooltipText = format(L["Notes created by %s"], name)
	Notebook:UpdateFrame()
end)

------------------------------------------------------------------------
-- Create frame regions and children on first showing

function NotebookFrame:Setup()
	Notebook:Print("Frame:Setup")
	self.Setup = nil

	-- Custom dialog ----------------------------------------------------

	local dialog = CreateFrame("Frame", "NotebookDialog", UIParent)
	dialog:SetSize(320, 72)
	dialog:SetBackdrop({
	  bgFile = "Interface\\CharacterFrame\\UI-Party-Background", tile = true, tileSize = 32,
	  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
	  insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	dialog:Hide()

	dialog.text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	dialog.text:SetPoint("TOPLEFT", 15, -16)
	dialog.text:SetPoint("TOPRIGHT", -15, -16)

	dialog.editBox = CreateFrame("EditBox", "$parentEditBox", dialog)
	dialog.editBox:SetSize(130, 32)
	dialog.editBox:SetPoint("BOTTOM", 0, 45)

	dialog.editBox.bgLeft = dialog.editBox:CreateTexture(nil, "BACKGROUND")
	dialog.editBox.bgLeft:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Left2]])
	dialog.editBox.bgLeft:SetPoint("LEFT", -10, 0)
	dialog.editBox.bgLeft:SetSize(32, 32)

	dialog.editBox.bgRight = dialog.editBox:CreateTexture(nil, "BACKGROUND")
	dialog.editBox.bgRight:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Right2]])
	dialog.editBox.bgRight:SetPoint("RIGHT", 10, 0)
	dialog.editBox.bgRight:SetSize(32, 32)

	dialog.editBox.bgMiddle = dialog.editBox:CreateTexture(nil, "BACKGROUND")
	dialog.editBox.bgMiddle:SetTexture([[Interface\ChatFrame\UI-ChatInputBorder-Mid2]])
	dialog.editBox.bgMiddle:SetHorizTile(true)
	dialog.editBox.bgMiddle:SetPoint("LEFT", dialog.editBox.bgLeft, "RIGHT")
	dialog.editBox.bgMiddle:SetPoint("RIGHT", dialog.editBox.bgRight, "LEFT")
	dialog.editBox.bgMiddle:SetHeight(32)

	dialog.hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	dialog.hint:SetPoint("TOP", editBox, "BOTTOM")
	dialog.hint:SetWidth(130)

	dialog.editBox:HookScript("OnTextChanged", function(self, userInput)
		local text = strtrim(self:GetText() or "")
		if strlen(text) == 0 then
			dialog.hint:SetText("")
			dialog.accept:Disable()
		elseif self.mode == "ADD" then
			if Notebook.notes[text] then
				dialog.hint:SetText(L["You already have a note with that title!"])
				dialog.accept:Disable()
			else
				dialog.hint:SetText("")
				dialog.accept:Enable()
			end
		elseif self.mode == "RENAME" then
			if Notebook.notes[text] and text ~= self.note then
				dialog.hint:SetText(L["You already have a note with that title!"])
				dialog.accept:Disable()
			else
				dialog.hint:SetText("")
				dialog.accept:Enable()
			end
		end
		-- TODO: mode SEND has channel dropdown + target editbox
	end)
	dialog.editBox:SetScript("OnEnterPressed", function(self)
		self:GetParent().accept:Click()
	end)
	dialog.editBox:SetScript("OnEscapePressed", function(self)
		self:GetParent().cancel:Click()
	end)

	dialog.accept = CreateFrame("Button", "$parentAcceptButton", dialog, "StaticPopupButtonTemplate")
	dialog.accept:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -6, 16)
	dialog.accept:SetText(ACCEPT)
	dialog.accept:SetScript("OnClick", function(self)
		local text = strtrim(self:GetParent().editBox:GetText() or "")
		if strlen(text) > 0 then
			if dialog.mode == "ADD" then
				Notebook:AddNote(text)
			elseif dialog.mode == "RENAME" and text ~= dialog.note then
				Notebook:EditNote(dialog.note, text)
			end
			-- TODO: mode SEND has channel dropdown + target editbox
		end
		self:GetParent():Hide()
	end)

	dialog.cancel = CreateFrame("Button", "$parentCancelButton", dialog, "StaticPopupButtonTemplate")
	dialog.cancel:SetPoint("LEFT", dialog.accept, "RIGHT", 13, 0)
	dialog.cancel:SetText(CANCEL)
	dialog.cancel:SetScript("OnClick", function(self)
		self:GetParent():Hide()
	end)

	dialog:SetScript("OnShow", function(self)
		self.editBox:SetText("")
		self.editBox.autoCompleteParams = nil
		self.hint:SetText("")
		self.accept:Disable()
		if self.mode == "ADD" then
			self.text:SetText(L["Enter a title for your new note:"])
		elseif self.mode == "RENAME" then
			self.text:SetText(NORMAL_FONT_COLOR_CODE .. self.note .. "|r|n" .. L["Enter a new title for this note:"])
		end
		-- TODO: mode SEND has channel dropdown + target editbox
	end)
	dialog:SetScript("OnHide", function(self)
		self.mode, self.note, self.channel = nil, nil, nil
		self.text:SetText("")
		self.editBox:SetText("")
		self.hint:SetText("")
	end)

	self.dialog = dialog

	-- Background textures ----------------------------------------------

	local portrait = self:CreateTexture(nil, "BACKGROUND")
	portrait:SetPoint("TOPLEFT", 7, -6)
	portrait:SetWidth(60)
	portrait:SetHeight(60)
	SetPortraitToTexture(portrait, "Interface\\FriendsFrame\\FriendsFrameScrollIcon")
	self.portrait = portrait

	local topLeft = self:CreateTexture(nil, "BORDER")
	topLeft:SetPoint("TOPLEFT")
	topLeft:SetWidth(256)
	topLeft:SetHeight(256)
	topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
	self.bgTopLeft = topLeft

	local topRight = self:CreateTexture(nil, "BORDER")
	topRight:SetPoint("TOPRIGHT")
	topRight:SetWidth(128)
	topRight:SetHeight(256)
	topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
	self.bgTopRight = topRight

	local bottomLeft = self:CreateTexture(nil, "BORDER")
	bottomLeft:SetPoint("BOTTOMLEFT")
	bottomLeft:SetWidth(256)
	bottomLeft:SetHeight(256)
	bottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotLeft")
	self.bgBottomLeft = bottomLeft

	local bottomRight = self:CreateTexture(nil, "BORDER")
	bottomRight:SetPoint("BOTTOMRIGHT")
	bottomRight:SetWidth(128)
	bottomRight:SetHeight(256)
	bottomRight:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotRight")
	self.bgBottomRight = bottomRight

	local barLeft = self:CreateTexture(nil, "ARTWORK")
	barLeft:SetPoint("TOPLEFT", 15, -186)
	barLeft:SetWidth(256)
	barLeft:SetHeight(16)
	barLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barLeft:SetTexCoord(0, 1, 0, 0.25)
	self.barLeft = barLeft

	local barRight = self:CreateTexture(nil, "ARTWORK")
	barRight:SetPoint("LEFT", barLeft, "RIGHT")
	barRight:SetWidth(75)
	barRight:SetHeight(16)
	barRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	barRight:SetTexCoord(0, 0.29296875, 0.25, 0.5)
	self.barRight = barRight

	-- Title text -------------------------------------------------------

	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOP", 0, -17)
	self.title = title

	-- Drag handle ------------------------------------------------------

	local drag = CreateFrame("Frame", nil, self)
	drag:SetPoint("TOP", 8, -10)
	drag:SetWidth(256)
	drag:SetHeight(28)
	self.dragHandle = drag

	drag:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			NotebookFrame.isMoving = true
			NotebookFrame:StartMoving()
			CloseDropDownMenus()
			-- Clear editBox focus while moving because of problems with the empty
			-- editbox (editBox only updates the actual cursor position when there
			-- is text in the editBox.  Also, if the editbox was empty, then give
			-- it a temporary space character while we are moving it.
			if editBox.hasFocus then
				editBox.hadFocus = true
				editBox:ClearFocus()
			end
			if editBox:GetNumLetters() == 0 then
				editBox.wasEmpty = true
				editBox:SetText(" ")
			end
		end
	end)

	drag:SetScript("OnMouseUp", function(self, button)
		if NotebookFrame.isMoving then
			NotebookFrame:StopMovingOrSizing()
			NotebookFrame:SetUserPlaced(false)
			NotebookFrame.isMoving = nil
			-- Restore the editbox's focus and empty status if needed
			if editBox.wasEmpty then
				editBox:SetText("")
				editBox.wasEmpty = nil
			end
			if editBox.hadFocus then
				editBox.hadFocus = nil
				editBox:SetFocus()
			end
		end
	end)

	drag:SetScript("OnHide", function(self)
		if NotebookFrame.isMoving then
			NotebookFrame:StopMovingOrSizing()
			NotebookFrame:SetUserPlaced(false)
			NotebookFrame.isMoving = nil
			-- Restore the editbox's empty status if needed
			if editBox.wasEmpty then
				editBox:SetText("")
				editBox.wasEmpty = nil
			end
			editBox.hadFocus = nil
		end
	end)

	-- Close button -----------------------------------------------------

	local close = CreateFrame("Button", "$parentCloseButton", self, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -30, -8)
	self.closeButton = close

	-- Filter tabs ------------------------------------------------------

	local function tab_OnShow(self)
		PanelTemplates_TabResize(self, 0)
		_G[self:GetName() .. "HighlightTexture"]:SetWidth(self:GetTextWidth() + 31)
	end

	local function tab_OnClick(self)
		-- TODO: Notebook.Frame_TabButtonOnClick
	end

	local function tab_OnEnter(self)
		if self.tooltipText then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
			GameTooltip:Show()
		end
	end

	local function CreateTab(i, text, tooltipText)
		local tab = CreateFrame("Button", "$parentTab"..i, self, "TabButtonTemplate")
		if i > 1 then
			tab:SetPoint("TOPLEFT", _G[tab:GetParent():GetName().."Tab"..(i-1)], "TOPRIGHT")
			PanelTemplates_DeselectTab(tab)
		else
			tab:SetPoint("TOPLEFT", 70, -39)
			PanelTemplates_SelectTab(tab)
		end
		tab:SetID(i)
		tab:SetText(text)
		tab.tooltipText = tooltipText
		tab:SetScript("OnShow",  tab_OnShow)
		tab:SetScript("OnClick", tab_OnClick)
		tab:SetScript("OnEnter", tab_OnEnter)
		tab:SetScript("OnLeave", GameTooltip_OnHide)
		tab_OnShow(tab)
		return tab
	end
	self.tabAll    = CreateTab(1, L["All"])
	self.tabMine   = CreateTab(2, L["Mine"])
	self.tabRecent = CreateTab(3, L["Recent"]) -- TODO: remove this?

	-- New Note button --------------------------------------------------

	local new = CreateFrame("Button", "$parentNewNoteButton", self, "UIPanelButtonTemplate")
	new:SetPoint("TOPRIGHT", -40, -49)
	new:SetWidth(60)
	new:SetHeight(22)
	new:SetNormalFontObject(GameFontNormalSmall)
	new:SetHighlightFontObject(GameFontHighlightSmall)
	new:SetDisabledFontObject(GameFontDisableSmall)
	new:SetText(L["New"])
	new.tooltipText = L["Create a new note"]
	self.newNoteButton = new

	new:SetScript("OnClick", function(self)
		-- TODO: Notebook.Frame_NewButtonOnClick
		dialog.mode = "ADD"
		dialog:Show()
	end)

	-- Can Send checkbox ------------------------------------------------

	local canSend = CreateFrame("CheckButton", "$parentCanSendCheckButton", self, "InterfaceOptionsSmallCheckButtonTemplate")
	canSend:SetPoint("BOTTOMLEFT", 20, 81)
	canSend:SetSize(22, 22) -- default is 26
	canSend:SetHitRectInsets(0, -70, 0, 0)
	canSend:SetNormalFontObject(GameFontHighlightSmall)
	canSend:SetHighlightFontObject(GameFontNormalSmall)
	canSend:SetDisabledFontObject(GameFontDisableSmall)
	self.canSendCheckButton = canSend

	canSend.Text = _G[canSend:GetName().."Text"]
	canSend.Text:SetPoint("LEFT", canSend, "RIGHT", 0, 0) -- remove default 1px y-offset
	canSend:SetFontString(canSend.Text)
	canSend:SetText(L["Can be sent"])
	canSend.tooltipTextOn = L["This note |cff7fff7fcan|r be sent"]
	canSend.tooltipTextOff = L["This note |cffff7f7fcannot|r be sent"]

	canSend:SetScript("OnClick", function(self)
		local checked = self:GetChecked()
		PlaySound(checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		local text = checked and self.tooltipTextOn or self.tooltipTextOff
		if text and GameTooltip:IsOwned(self) then
			GameTooltip:SetText(text)
		end
		CloseDropDownMenus()

		local note = Notebook.notes[selectedNote]
		if note then
			note.canSend = checked
		end
	end)

	canSend:SetScript("OnEnter", function(self)
		local text = self:GetChecked() and self.tooltipTextOn or self.tooltipTextOff
		if text then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(text)
		end
	end)

	canSend:SetScript("OnLeave", GameTooltip_Hide)


	-- Save button ------------------------------------------------------

	local save = CreateFrame("Button", "$parentSaveButton", self, "UIPanelButtonTemplate")
	save:SetPoint("BOTTOMRIGHT", -42, 80)
	save:SetSize(86, 22)
	save:SetNormalFontObject(GameFontNormalSmall)
	save:SetHighlightFontObject(GameFontHighlightSmall)
	save:SetDisabledFontObject(GameFontDisableSmall)
	save:SetText(L["Save"])
	save.tooltipText = L["Save the changes to this note"]
	self.saveButton = save

	save:SetScript("OnClick", function(self)
		-- TODO: Notebook.Frame_SaveButtonOnClick
	end)

	-- Cancel button ----------------------------------------------------

	local cancel = CreateFrame("Button", "$parentCancelButton", self, "UIPanelButtonTemplate")
	cancel:SetPoint("BOTTOMRIGHT", save, "BOTTOMLEFT", -2, 0)
	cancel:SetSize(86, 22)
	cancel:SetNormalFontObject(GameFontNormalSmall)
	cancel:SetHighlightFontObject(GameFontHighlightSmall)
	cancel:SetDisabledFontObject(GameFontDisableSmall)
	cancel:SetText(L["Cancel"])
	cancel.tooltipText = L["Revert to the last saved version of this note"]
	self.cancelButton = cancel

	cancel:SetScript("OnClick", function(self)
		-- TODO: Notebook.Frame_CancelButtonOnClick
	end)

	-- List frame -------------------------------------------------------

	local listFrame = CreateFrame("Frame", "$parentListFrame", self)
	listFrame:SetPoint("TOPLEFT", 20, -74)
	listFrame:SetSize(320, 112)
	self.listFrame = listFrame

	-- List buttons -----------------------------------------------------

	local function listButton_OnClick(self, button)
		PlaySound("igMainMenuOptionCheckBoxOn")
		-- TODO: Notebook.Frame_ListButtonOnClick
		local thisNote = self:GetText()
		if thisNote ~= selectedNote then
			NotebookFrame:ShowNote(thisNote)
		end
	end

	local function ColorizeName(name, class) -- TODO: move this to core utilities?
		local color = class and (RAID_CLASS_COLORS or CUSTOM_CLASS_COLORS)[class]
		return color and "|c"..color.colorStr..name.."|r" or name
	end

	local function listButton_OnEnter(self)
		local note = Notebook.notes[self:GetText()]
		if note then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(format(L["%d characters"], strlenutf8(note.text)))
			if note.author == Notebook.player then
				GameTooltip:AddLine(format(L["Last updated %s"], note.date))
			else
				GameTooltip:AddLine(format(L["Last updated %s by %s"], note.date, ColorizeName(note.author, note.authorClass)), 1, 1, 1)
			end
			-- TODO: add not saved, last sent, etc
			GameTooltip:Show()
		end
	end

	listButtons = setmetatable({}, { __index = function(t, i)
		local button = CreateFrame("Button", "NotebookFrameListButton"..i, listFrame)
		button:SetSize(298, LIST_BUTTON_HEIGHT)

		if i > 1 then
			button:SetPoint("TOPLEFT", t[i-1], "BOTTOMLEFT")
		else
			button:SetPoint("TOPLEFT")
		end

		local title = button:CreateFontString(nil, "ARTWORK")
		button:SetFontString(title)
		button:SetNormalFontObject(GameFontNormalSmall)
		button:SetHighlightFontObject(GameFontHighlightSmall)
		button:SetDisabledFontObject(GameFontDisableSmall)
		title:ClearAllPoints()
		title:SetPoint("TOPLEFT", 10, -2)
		title:SetPoint("BOTTOMRIGHT", 0, -2)
		title:SetJustifyH("LEFT")
		title:SetJustifyV("CENTER")
		button.title = title

		local highlight = button:CreateTexture("$parentHighlight", "HIGHLIGHT")
		highlight:SetPoint("TOPLEFT", 2, -2)
		highlight:SetPoint("BOTTOMRIGHT", 2, -2)
		highlight:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue", "ADD")
		button:SetHighlightTexture(highlight)
		button.highlight = highlight

		button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		button:SetScript("OnClick", listButton_OnClick)
		button:SetScript("OnEnter", listButton_OnEnter)
		button:SetScript("OnLeave", GameTooltip_Hide)

		t[i] = button
		return button
	end })

	self.listButtons = listButtons

	-- List frame scroll bar --------------------------------------------

	local listScrollFrame = CreateFrame("ScrollFrame", "$parentScrollFrame", listFrame, "FauxScrollFrameTemplate")
	listScrollFrame:SetPoint("TOPLEFT", 0, -2)
	listScrollFrame:SetSize(296, 112)
	self.listScrollFrame = listScrollFrame

	self.listScrollChild = listScrollFrame:GetScrollChild()
	self.listScrollChild:SetSize(296, 112)

	listScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, LIST_BUTTON_HEIGHT, Notebook.UpdateFrame)
	end)

	-- Description frame ------------------------------------------------

	local description = CreateFrame("Frame", nil, self)
	description:SetPoint("TOPLEFT", 25, -202)
	description:SetSize(317, 204)
	self.descriptionFrame = description

	-- Edit scroll frame ------------------------------------------------

	local editScroll = CreateFrame("ScrollFrame", "NotebookFrameEditScrollFrame", description)
	editScroll:SetPoint("TOPLEFT")
	editScroll:SetWidth(314)
	editScroll:SetHeight(204)
	editScroll.scrollBarHideable = true
	self.editScrollFrame = editScroll

	local editScrollBar = CreateFrame("Slider", "$parentScrollBar", editScroll, "UIPanelScrollBarTemplate")
	editScrollBar:SetPoint("TOPRIGHT", 0, -14)
	editScrollBar:SetPoint("BOTTOMRIGHT", 0, 14)
	self.editScrollBar = editScrollBar

	editScroll:SetScript("OnMouseWheel", ScrollFrameTemplate_OnMouseWheel)
	-- TODO: editScroll:SetScript("OnVerticalScroll", Notebook.Frame_OnVerticalScroll)

	editScroll:EnableMouse(true)
	editScroll:SetScript("OnMouseUp", function(self, button)
		-- Focus the edit box when clicking anywhere in the description frame,
		-- since the edit box magically resizes itself based on the height of
		-- its contents since some patches ago.
		if button == "LeftButton" and editBox:IsShown() and not editBox:IsMouseOver() and not editScrollBar:IsMouseOver() then
			editBox:SetFocus()
		end
	end)

	ScrollFrame_OnLoad(editScroll)
	ScrollFrame_OnScrollRangeChanged(editScroll, 0)

	-- Edit box ---------------------------------------------------------

	editBox = CreateFrame("EditBox", "NotebookEditBox", editScroll)
	editBox:SetPoint("TOPLEFT")
	editBox:SetSize(292, 204)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(GameFontNormal)
	editBox:SetIndentedWordWrap(false)
	editBox:SetJustifyH("LEFT")
	editBox:SetMaxLetters(4096)
	editBox:SetMultiLine(true)
	editBox:SetTextInsets(0, -2, 0, 2) -- avoid clipping descenders
	editBox.cursorOffset = 0 -- TODO: what is this?
	self.editBox = editBox

	editScroll:SetScrollChild(editBox)
	editScroll:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset)
		ScrollFrame_OnScrollRangeChanged(self, xOffset, yOffset)
		if floor(yOffset) == 0 then
			editBox:SetWidth(292 + 18)
		else
			editBox:SetWidth(292)
		end
	end)

	editBox:SetScript("OnCursorChanged", function(self, x, y, width, height)
		ScrollingEdit_OnCursorChanged(self, x, y - 2, width, height)
		ScrollingEdit_OnUpdate(self, 0, self:GetParent())
	end)

	editBox:SetScript("OnTextChanged", function(self, isUserInput)
		-- A minor kludge to move to the top of the scroll-self
		-- when resetting the text in the edit box
		if self.textReset then
			if self.textResetToEmpty then
				self:SetText("")
				self.textResetToEmpty = nil
			else
				self.textReset = nil
			end
		else
			if self.textResetToEmpty then
				self:SetText("")
				self.textResetToEmpty = nil
			else
				-- TODO
				-- Notebook.Frame_TextChanged(self)
			end
		end
		ScrollingEdit_OnTextChanged(self, self:GetParent())
	end)

	editBox:SetScript("OnEditFocusGained", function(self)
		if not selectedNote then
			return self:ClearFocus()
		end
		self.textReset = nil
		self.hasFocus = true
	end)
	editBox:SetScript("OnEditFocusLost", function(self)
		self.hasFocus = nil
	end)
	editBox:SetScript("OnEscapePressed", editBox.ClearFocus)

	-- Text scroll frame, for non-editable text -------------------------

	local textScroll = CreateFrame("ScrollFrame", "NotebookFrameTextScrollFrame", description)
	textScroll:SetPoint("TOPLEFT")
	textScroll:SetSize(306, 204)
	textScroll:Hide()
	textScroll.scrollBarHideable = true
	self.textScrollFrame = textScroll

	textScroll:SetScript("OnMouseWheel", ScrollFrameTemplate_OnMouseWheel)
	-- TODO: textScroll:SetScript("OnVerticalScroll", Notebook.Frame_OnVerticalScroll)

	textScroll:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset)
		-- Scroll range will only change when we put new text into the
		-- textbox, so when this happens we also set the scrollbar
		-- position to zero to show the top of the text always.
		ScrollFrame_OnScrollRangeChanged(self, yOffset)
		selfTextScrollFrameScrollBar:SetValue(0)
	end)

	local textScrollBar = CreateFrame("Slider", "$parentScrollBar", textScroll, "UIPanelScrollBarTemplate")
	textScrollBar:SetPoint("TOPLEFT", textScroll, "TOPRIGHT", -4, -14)
	textScrollBar:SetPoint("BOTTOMLEFT", textScroll, "BOTTOMRIGHT", -4, 14)
	self.textScrollBar = textScrollBar

	ScrollFrame_OnLoad(textScroll)
	ScrollFrame_OnScrollRangeChanged(textScroll, 0)

	local textScrollChild = CreateFrame("Frame", "$parentScrollChild", textScroll)
	textScrollChild:SetPoint("TOPLEFT")
	textScrollChild:SetWidth(296)
	textScrollChild:SetHeight(204)
	textScrollChild:EnableMouse(true)
	textScroll:SetScrollChild(textScrollChild)
	self.textScrollChild = textScrollChild

	local textBox = textScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	textBox:SetPoint("TOPLEFT", 10, -2)
	textBox:SetWidth(286)
	textBox:SetJustifyH("LEFT")
	textBox:SetIndentedWordWrap(false)
	self.textBox = textBox

	-- Dropdown menu ----------------------------------------------------
	-- TODO: replace with custom frame to avoid taint

	local dropdown = CreateFrame("Frame", "NotebookDropDown", self, "UIDropDownMenuTemplate")
	self.dropdown = dropdown
end
