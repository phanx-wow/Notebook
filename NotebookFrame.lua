--[[--------------------------------------------------------------------
	Notebook
	Allows you to record and share notes in-game.
	Copyright (c) 2005-2008 Cirk of Doomhammer EU. All rights reserved.
	Copyright (c) 2012-2014 Phanx <addons@phanx.net>. All rights reserved.
	http://www.wowinterface.com/downloads/info4544-Notebook.html
	http://www.curse.com/addons/wow/notebook
	https://github.com/Phanx/Notebook
----------------------------------------------------------------------]]

local NOTEBOOK, Notebook = ...
local L = Notebook.L

local NotebookFrame = CreateFrame("Frame", "NotebookFrame", UIParent)
UIPanelWindows["NotebookFrame"] = { area = "left", pushable = 3, whileDead = 1, xoffset = -16, yoffset = 12 }
tinsert(UISpecialFrames, "NotebookFrame")
Notebook.Frame = NotebookFrame
-- HideUIPanel(NotebookFrame)
-- NotebookFrame:Hide()

NotebookFrame:SetWidth(384)
NotebookFrame:SetHeight(512)
NotebookFrame:SetHitRectInsets(10, 34, 8, 72)
NotebookFrame:SetToplevel(true)
NotebookFrame:EnableMouse(true)
NotebookFrame:SetMovable(true)

NotebookFrame:SetScript("OnShow", function(self)
	-- Set the frame title and "mine" tab tooltip with the player's name
	local playerName = UnitName("player")
	NotebookFrame.TitleText:SetFormattedText(L.FRAME_TITLE_FORMAT, playerName)
	NotebookFrame.FilterTab2.tooltipText = format(L.MINE_TAB_TOOLTIP_FORMAT, playerName)
	Notebook.Frame_UpdateList()
end)

------------------------------------------------------------------------
--  BACKGROUND TEXTURES

local topLeftIcon = NotebookFrame:CreateTexture(nil, "BACKGROUND")
topLeftIcon:SetPoint("TOPLEFT", 7, -6)
topLeftIcon:SetWidth(60)
topLeftIcon:SetHeight(60)
SetPortraitToTexture(topLeftIcon, "Interface\\FriendsFrame\\FriendsFrameScrollIcon")
NotebookFrame.TopLeftIcon = topLeftIcon

local topLeft = NotebookFrame:CreateTexture(nil, "BORDER")
topLeft:SetPoint("TOPLEFT")
topLeft:SetWidth(256)
topLeft:SetHeight(256)
topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
NotebookFrame.TopLeft = topLeft

local topRight = NotebookFrame:CreateTexture(nil, "BORDER")
topRight:SetPoint("TOPRIGHT")
topRight:SetWidth(128)
topRight:SetHeight(256)
topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
NotebookFrame.BopRight = topRight

local bottomLeft = NotebookFrame:CreateTexture(nil, "BORDER")
bottomLeft:SetPoint("BOTTOMLEFT")
bottomLeft:SetWidth(256)
bottomLeft:SetHeight(256)
bottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotLeft")
NotebookFrame.BottomLeft = bottomLeft

local bottomRight = NotebookFrame:CreateTexture(nil, "BORDER")
bottomRight:SetPoint("BOTTOMRIGHT")
bottomRight:SetWidth(128)
bottomRight:SetHeight(256)
bottomRight:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotRight")
NotebookFrame.BottomRight = bottomRight

local barLeft = NotebookFrame:CreateTexture(nil, "ARTWORK")
barLeft:SetPoint("TOPLEFT", 15, -186)
barLeft:SetWidth(256)
barLeft:SetHeight(16)
barLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
barLeft:SetTexCoord(0, 1, 0, 0.25)
NotebookFrame.BarLeft = barLeft

local barRight = NotebookFrame:CreateTexture(nil, "ARTWORK")
barRight:SetPoint("LEFT", barLeft, "RIGHT")
barRight:SetWidth(75)
barRight:SetHeight(16)
barRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
barRight:SetTexCoord(0, 0.29296875, 0.25, 0.5)
NotebookFrame.BarRight = barRight

------------------------------------------------------------------------
--  TITLE TEXT

local title = NotebookFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
title:SetPoint("TOP", 0, -17)
NotebookFrame.TitleText = title

------------------------------------------------------------------------
--  DRAG REGION

local drag = CreateFrame("Frame", nil, NotebookFrame)
drag:SetPoint("TOP", 8, -10)
drag:SetWidth(256)
drag:SetHeight(28)
NotebookFrame.DragFrame = drag

drag:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		NotebookFrame.isMoving = true
		NotebookFrame:StartMoving()
		CloseDropDownMenus()
		-- Clear editBox focus while moving because of problems with the empty
		-- editbox (editBox only updates the actual cursor position when there
		-- is text in the editBox.  Also, if the editbox was empty, then give
		-- it a temporary space character while we are moving it.
		if NotebookFrame.EditBox.hasFocus then
			NotebookFrame.editHadFocus = true
			NotebookFrame.EditBox:ClearFocus()
		end
		if NotebookFrame.EditBox:GetNumLetters() == 0 then
			NotebookFrame.editWasEmpty = true
			NotebookFrame.EditBox:SetText(" ")
		end
	end
end)

drag:SetScript("OnMouseUp", function(self, button)
	if NotebookFrame.isMoving then
		NotebookFrame:StopMovingOrSizing()
		NotebookFrame:SetUserPlaced(false)
		NotebookFrame.isMoving = nil
		-- Restore the editbox's focus and empty status if needed
		if NotebookFrame.editWasEmpty then
			NotebookFrame.EditBox:SetText("")
			NotebookFrame.editWasEmpty = nil
		end
		if NotebookFrame.editHadFocus then
			NotebookFrame.editHadFocus = nil
			NotebookFrame.EditBox:SetFocus()
		end
	end
end)

drag:SetScript("OnHide", function(self)
	if NotebookFrame.isMoving then
		NotebookFrame:StopMovingOrSizing()
		NotebookFrame:SetUserPlaced(false)
		NotebookFrame.isMoving = nil
		-- Restore the editbox's empty status if needed
		if NotebookFrame.editWasEmpty then
			NotebookFrame.EditBox:SetText("")
			NotebookFrame.editWasEmpty = nil
		end
		NotebookFrame.editHadFocus = nil
	end
end)

------------------------------------------------------------------------
--  CLOSE X BUTTON

local closeX = CreateFrame("Button", nil, NotebookFrame, "UIPanelCloseButton")
closeX:SetPoint("TOPRIGHT", -30, -8)
NotebookFrame.CloseButtonX = closeX

------------------------------------------------------------------------
--[[  CLOSE BUTTON

local close = CreateFrame("Button", nil, NotebookFrame, "UIPanelButtonTemplate")
close:SetPoint("BOTTOMRIGHT", -42, 80)
close:SetSize(80, 22)
close:SetNormalFontObject(GameFontNormalSmall)
close:SetHighlightFontObject(GameFontHighlightSmall)
close:SetDisabledFontObject(GameFontDisableSmall)
close:SetScript("OnClick", HideParentPanel)
close:SetText(CLOSE)
NotebookFrame.CloseButton = close
]]
------------------------------------------------------------------------
--  SAVE BUTTON

local save = CreateFrame("Button", "$parentSave", NotebookFrame, "UIPanelButtonTemplate")
--save:SetPoint("BOTTOMLEFT", 20, 80)
--save:SetSize(60, 22)
save:SetPoint("BOTTOMRIGHT", -42, 80)
save:SetSize(86, 22)
save:SetNormalFontObject(GameFontNormalSmall)
save:SetHighlightFontObject(GameFontHighlightSmall)
save:SetDisabledFontObject(GameFontDisableSmall)
save:SetScript("OnClick", Notebook.Frame_SaveButtonOnClick)
save:SetText(L.SAVE_BUTTON)
save.tooltipText = L.SAVE_BUTTON_TOOLTIP
save.newbieText = L.SAVE_BUTTON_TOOLTIP
NotebookFrame.SaveButton = save

------------------------------------------------------------------------
--  CANCEL BUTTON

local cancel = CreateFrame("Button", "$parentCancel", NotebookFrame, "UIPanelButtonTemplate")
--cancel:SetPoint("BOTTOMLEFT", save, "BOTTOMRIGHT")
cancel:SetPoint("BOTTOMRIGHT", save, "BOTTOMLEFT", -2, 0)
cancel:SetSize(86, 22)
cancel:SetNormalFontObject(GameFontNormalSmall)
cancel:SetHighlightFontObject(GameFontHighlightSmall)
cancel:SetDisabledFontObject(GameFontDisableSmall)
cancel:SetScript("OnClick", Notebook.Frame_CancelButtonOnClick)
cancel:SetText(L.CANCEL_BUTTON)
cancel.tooltipText = L.CANCEL_BUTTON_TOOLTIP
cancel.newbieText = L.CANCEL_BUTTON_TOOLTIP
NotebookFrame.CancelButton = cancel

------------------------------------------------------------------------
--  NEW BUTTON

local new = CreateFrame("Button", "$parentNew", NotebookFrame, "UIPanelButtonTemplate")
NotebookFrame.NewButton = new

new:SetPoint("TOPRIGHT", -40, -49)
new:SetWidth(60)
new:SetHeight(22)
new:SetNormalFontObject(GameFontNormalSmall)
new:SetHighlightFontObject(GameFontHighlightSmall)
new:SetDisabledFontObject(GameFontDisableSmall)
new:SetScript("OnClick", Notebook.Frame_NewButtonOnClick)
new:SetText(L.NEW_BUTTON)
new.tooltipText = L.NEW_BUTTON_TOOLTIP
new.newbieText = L.NEW_BUTTON_TOOLTIP

------------------------------------------------------------------------
-- CAN SEND CHECKBOX

local canSend = CreateFrame("CheckButton", "$parentCanSend", NotebookFrame, "InterfaceOptionsSmallCheckButtonTemplate")
NotebookFrame.CanSendCheckButton = canSend

canSend.Text = _G[canSend:GetName().."Text"]
canSend.Text:SetPoint("LEFT", canSend, "RIGHT", 0, 0) -- remove default 1px y-offset
canSend:SetFontString(canSend.Text)
canSend:SetNormalFontObject(GameFontHighlightSmall)
canSend:SetHighlightFontObject(GameFontNormalSmall)
canSend:SetDisabledFontObject(GameFontDisableSmall)

canSend:SetPoint("BOTTOMLEFT", 20, 81)
canSend:SetSize(22, 22) -- default is 26
canSend:SetHitRectInsets(0, -70, 0, 0)

canSend:SetText(L.CHECK_SEND_BUTTON)
canSend.tooltipOnText = L.CHECK_CAN_SEND_TOOLTIP
canSend.tooltipOffText = L.CHECK_NOT_SEND_TOOLTIP

canSend:SetScript("OnEnter", function(self)
	local text
	if self:GetChecked() then
		text = self.tooltipOnText
	else
		text = self.tooltipOffText
	end
	if text then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	end
end)

canSend:SetScript("OnLeave", GameTooltip_Hide)

canSend:SetScript("OnClick", function(self, button)
	local text
	if self:GetChecked() then
		PlaySound("igMainMenuOptionCheckBoxOn")
		text = self.tooltipOnText
	else
		PlaySound("igMainMenuOptionCheckBoxOff")
		text = self.tooltipOffText
	end
	if text and GameTooltip:IsOwned(self) then
		GameTooltip:SetText(text)
	end

	CloseDropDownMenus()

	local ndata = Notebook:FindNoteByID(NotebookFrame.selectedID)
	if ndata then
		if ndata.send then
			ndata.send = nil
		else
			ndata.send = true
		end
	end
end)

------------------------------------------------------------------------
--  FILTER TAB BUTTONS

local function tab_OnShow(self)
	PanelTemplates_TabResize(self, 0)
	_G[self:GetName() .. "HighlightTexture"]:SetWidth(self:GetTextWidth() + 31)
end

local function tab_OnEnter(self)
	if self.tooltipText then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, 1)
		GameTooltip:Show()
	end
end

local function tab_OnClick(self)
	Notebook.Frame_TabButtonOnClick(self:GetID())
end

local filterTab1 = CreateFrame("Button", "$parentFilterTab1", NotebookFrame, "TabButtonTemplate")
filterTab1:SetPoint("TOPLEFT", 70, -39)
filterTab1:SetID(1)
filterTab1:SetScript("OnShow", tab_OnShow)
filterTab1:SetScript("OnEnter", tab_OnEnter)
filterTab1:SetScript("OnLeave", GameTooltip_Hide)
filterTab1:SetScript("OnClick", tab_OnClick)
filterTab1:SetText(L.ALL_TAB)
filterTab1.tooltipText = L.ALL_TAB_TOOLTIP
PanelTemplates_SelectTab(filterTab1)
NotebookFrame.FilterTab1 = filterTab1

local filterTab2 = CreateFrame("Button", "$parentFilterTab2", NotebookFrame, "TabButtonTemplate")
filterTab2:SetPoint("TOPLEFT", filterTab1, "TOPRIGHT")
filterTab2:SetID(2)
filterTab2:SetScript("OnShow", tab_OnShow)
filterTab2:SetScript("OnEnter", tab_OnEnter)
filterTab2:SetScript("OnLeave", GameTooltip_Hide)
filterTab2:SetScript("OnClick", tab_OnClick)
filterTab2:SetText(L.MINE_TAB)
PanelTemplates_DeselectTab(filterTab2)
NotebookFrame.FilterTab2 = filterTab2

local filterTab3 = CreateFrame("Button", "$parentFilterTab3", NotebookFrame, "TabButtonTemplate")
filterTab3:SetPoint("TOPLEFT", filterTab2, "TOPRIGHT")
filterTab3:SetID(3)
filterTab3:SetScript("OnShow", tab_OnShow)
filterTab3:SetScript("OnEnter", tab_OnEnter)
filterTab3:SetScript("OnLeave", GameTooltip_Hide)
filterTab3:SetScript("OnClick", tab_OnClick)
filterTab3:SetText(L.RECENT_TAB)
filterTab3.tooltipText = L.RECENT_TAB_TOOLTIP
PanelTemplates_DeselectTab(filterTab3)
NotebookFrame.FilterTab3 = filterTab3

------------------------------------------------------------------------
--  LIST FRAME

local listFrame = CreateFrame("Frame", "$parentListFrame", NotebookFrame)
listFrame:SetPoint("TOPLEFT", 20, -74)
listFrame:SetWidth(320)
listFrame:SetHeight(112)
NotebookFrame.ListFrame = listFrame

------------------------------------------------------------------------
--  LIST BUTTONS

local function createListButton(id)
	local button = CreateFrame("Button", "NotebookListButton"..id, listFrame)
	button:SetWidth(298)
	button:SetHeight(NOTEBOOK_LIST_BUTTON_HEIGHT)
	button:SetID(id)

	local text = button:CreateFontString(nil, "OVERLAY")
	button:SetFontString(text)
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)
	text:ClearAllPoints()
	text:SetPoint("LEFT", button, 10, -2)
	text:SetWidth(288)
	text:SetHeight(14)
	text:SetJustifyH("LEFT")
	button.TitleText = text

	local highlight = button:CreateTexture("$parentHighlight", "HIGHLIGHT")
	highlight:SetPoint("LEFT", 2, -2)
	highlight:SetPoint("RIGHT", 2, -2)
	highlight:SetHeight(NOTEBOOK_LIST_BUTTON_HEIGHT)
	highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
	button:SetHighlightTexture(highlight)
	button.TitleHighlight = highlight

	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnClick", function(self, button)
		PlaySound("igMainMenuOptionCheckBoxOn")
		Notebook.Frame_ListButtonOnClick(self, button)
	end)
	button:SetScript("OnEnter", function(self)
		if self.tooltipText then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.tooltipText, 1, 1, 1)
			GameTooltip:Show()
		end
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)

	return button
end

local listButtons = { }
for id = 1, NOTEBOOK_LIST_BUTTON_COUNT do
	local button = createListButton(id)
	if id == 1 then
		button:SetPoint("TOPLEFT")
	else
		button:SetPoint("TOPLEFT", listButtons[id - 1], "BOTTOMLEFT")
	end
	listButtons[id] = button
end

NotebookFrame.ListButtons = listButtons

------------------------------------------------------------------------
--  LIST SCROLL BAR

local scrollFrame = CreateFrame("ScrollFrame", "NotebookFrameListScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, -2)
scrollFrame:SetWidth(296)
scrollFrame:SetHeight(112)
NotebookFrame.ListScrollFrame = scrollFrame

scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, NOTEBOOK_LIST_BUTTON_HEIGHT, Notebook.Frame_UpdateList)
end)

local scrollChild = CreateFrame("Frame", "$parentScrollChildFrame", scrollFrame)
scrollChild:SetWidth(296)
scrollChild:SetHeight(112)
scrollFrame:SetScrollChild(scrollChild)
NotebookFrame.ListScrollChild = scrollChild

------------------------------------------------------------------------
--  DESCRIPTION FRAME

local description = CreateFrame("Frame", nil, NotebookFrame)
description:SetPoint("TOPLEFT", 25, -202)
description:SetWidth(317)
description:SetHeight(204)
NotebookFrame.DescriptionFrame = description

------------------------------------------------------------------------
--  EDIT SCROLL FRAME

local editScroll = CreateFrame("ScrollFrame", "$parentEditScrollFrame", description)
editScroll:SetPoint("TOPLEFT")
editScroll:SetWidth(314)
editScroll:SetHeight(204)
editScroll.scrollBarHideable = true
NotebookFrame.EditScrollFrame = editScroll

editScroll:SetScript("OnMouseWheel", ScrollFrameTemplate_OnMouseWheel)
editScroll:SetScript("OnVerticalScroll", Notebook.Frame_OnVerticalScroll)

editScroll:EnableMouse(true)
editScroll:SetScript("OnMouseUp", function(self, button)
	-- Focus the edit box when clicking anywhere in the description NotebookFrame,
	-- since the edit box magically resizes itself based on the height of
	-- its contents since some patches ago.
	if button == "LeftButton" and NotebookFrame.EditBox:IsShown()
	and not NotebookFrame.EditBox:IsMouseOver() and not NotebookFrame.EditScrollFrame.ScrollBar:IsMouseOver() then
		NotebookFrame.EditBox:SetFocus()
	end
end)

local editBar = CreateFrame("Slider", "$parentScrollBar", editScroll, "UIPanelScrollBarTemplate")
editBar:SetPoint("TOPRIGHT", 0, -14)
editBar:SetPoint("BOTTOMRIGHT", 0, 14)
NotebookFrame.EditScrollFrame.ScrollBar = editBar

ScrollFrame_OnLoad(editScroll)
ScrollFrame_OnScrollRangeChanged(editScroll, 0)

local editBox = CreateFrame("EditBox", "NotebookEditBox", editScroll)
editBox:SetPoint("TOPLEFT")
editBox:SetWidth(292)
editBox:SetHeight(204)
editBox:EnableMouse(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(GameFontNormal)
editBox:SetJustifyH("LEFT")
editBox:SetMaxLetters(4096)
editBox:SetMultiLine(true)
editBox:SetIndentedWordWrap(false)
-- Set the text insets to make sure the editbox doesn't
-- chop the bottom off letters which extend below the
-- baseline (e.g., p, y, q, etc.)
editBox:SetTextInsets(0, -2, 0, 2)
editScroll:SetScrollChild(editBox)
NotebookFrame.EditBox = editBox

editScroll:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset)
	ScrollFrame_OnScrollRangeChanged(self, xOffset, yOffset)
	if floor(yOffset) == 0 then
		editBox:SetWidth(292 + 18)
	else
		editBox:SetWidth(292)
	end
end)

editBox.cursorOffset = 0

editBox:SetScript("OnCursorChanged", function(self, x, y, width, height)
	ScrollingEdit_OnCursorChanged(self, x, y - 2, width, height)
	ScrollingEdit_OnUpdate(self, 0, self:GetParent())
end)

editBox:SetScript("OnTextChanged", function(self, isUserInput)
	-- A minor kludge to move to the top of the scroll-NotebookFrame
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
			Notebook.Frame_TextChanged(self)
		end
	end
	ScrollingEdit_OnTextChanged(self, self:GetParent())
end)

editBox:SetScript("OnEscapePressed", editBox.ClearFocus)

editBox:SetScript("OnEditFocusLost", function(self)
	self.hasFocus = nil
end)

editBox:SetScript("OnEditFocusGained", function(self)
	if not NotebookFrame.selectedID then
		return self:ClearFocus()
	end
	self.textReset = nil
	self.hasFocus = true
end)

------------------------------------------------------------------------
--  TEXT SCROLL FRAME (for non-editable text)

local textScroll = CreateFrame("ScrollFrame", "NotebookFrameTextScrollFrame", description)
textScroll:SetPoint("TOPLEFT")
textScroll:SetWidth(306)
textScroll:SetHeight(204)
textScroll:Hide()
textScroll.scrollBarHideable = true
NotebookFrame.TextScrollFrame = textScroll

textScroll:SetScript("OnMouseWheel", ScrollFrameTemplate_OnMouseWheel)
textScroll:SetScript("OnVerticalScroll", Notebook.Frame_OnVerticalScroll)
textScroll:SetScript("OnScrollRangeChanged", function(self, xOffset, yOffset)
	-- Scroll range will only change when we put new text into the
	-- textbox, so when this happens we also set the scrollbar
	-- position to zero to show the top of the text always.
	ScrollFrame_OnScrollRangeChanged(self, yOffset)
	NotebookFrameTextScrollFrameScrollBar:SetValue(0)
end)

local textBar = CreateFrame("Slider", "$parentScrollBar", textScroll, "UIPanelScrollBarTemplate")
textBar:SetPoint("TOPLEFT", textScroll, "TOPRIGHT", -4, -14)
textBar:SetPoint("BOTTOMLEFT", textScroll, "BOTTOMRIGHT", -4, 14)
NotebookFrame.TextScrollFrame.ScrollBar = textBar

ScrollFrame_OnLoad(textScroll)
ScrollFrame_OnScrollRangeChanged(textScroll, 0)

local textChild = CreateFrame("Frame", "$parentScrollChild", textScroll)
textChild:SetPoint("TOPLEFT")
textChild:SetWidth(296)
textChild:SetHeight(204)
textChild:EnableMouse(true)
textScroll:SetScrollChild(textChild)
NotebookFrame.TextScrollChild = textChild

local textBox = textChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textBox:SetPoint("TOPLEFT", 10, -2)
textBox:SetWidth(286)
textBox:SetHeight(0)
textBox:SetJustifyH("LEFT")
textBox:SetIndentedWordWrap(false)
NotebookFrame.TextBox = textBox

------------------------------------------------------------------------
--  DROPDOWN MENU

local dropdown = CreateFrame("Frame", "NotebookDropDown", NotebookFrame, "UIDropDownMenuTemplate")
NotebookFrame.DropDown = dropdown

------------------------------------------------------------------------
--	Addon
------------------------------------------------------------------------

NotebookFrame:SetScript("OnEvent", Notebook.OnEvent)

Notebook.OnLoad(NotebookFrame)
Notebook.Frame_OnLoad(NotebookFrame)