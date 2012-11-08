------------------------------------------------------------------------
--	Notebook
--	Allows you to record and share notes in-game
--	Written by Cirk of Doomhammer, December 2005, last updated August 2009
--	Updated by Phanx with permission
--	http://www.wowinterface.com/downloads/info4544-CirksNotebook.html
------------------------------------------------------------------------

local frame = CreateFrame("Frame", "NotebookFrame", UIParent)
UIPanelWindows["NotebookFrame"] = { area = "left", pushable = 3, whileDead = 1, xoffset = -16, yoffset = 12 }
-- HideUIPanel(NotebookFrame)
-- frame:Hide()

frame:SetWidth(384)
frame:SetHeight(512)
frame:SetHitRectInsets(10, 34, 8, 72)
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:SetMovable(true)

frame:SetScript("OnShow", Notebook.Frame_OnShow)

--  BACKGROUND TEXTURES

local topLeftIcon = frame:CreateTexture(nil, "BACKGROUND")
topLeftIcon:SetPoint("TOPLEFT", 7, -6)
topLeftIcon:SetWidth(60)
topLeftIcon:SetHeight(60)
SetPortraitToTexture(topLeftIcon, "Interface\\FriendsFrame\\FriendsFrameScrollIcon")
frame.topLeftIcon = topLeftIcon

local topLeft = frame:CreateTexture(nil, "BORDER")
topLeft:SetPoint("TOPLEFT")
topLeft:SetWidth(256)
topLeft:SetHeight(256)
topLeft:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopLeft")
frame.topLeft = topLeft

local topRight = frame:CreateTexture(nil, "BORDER")
topRight:SetPoint("TOPRIGHT")
topRight:SetWidth(128)
topRight:SetHeight(256)
topRight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-General-TopRight")
frame.topRight = topRight

local bottomLeft = frame:CreateTexture(nil, "BORDER")
bottomLeft:SetPoint("BOTTOMLEFT")
bottomLeft:SetWidth(256)
bottomLeft:SetHeight(256)
bottomLeft:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotLeft")
frame.bottomLeft = bottomLeft

local bottomRight = frame:CreateTexture(nil, "BORDER")
bottomRight:SetPoint("BOTTOMRIGHT")
bottomRight:SetWidth(128)
bottomRight:SetHeight(256)
bottomRight:SetTexture("Interface\\PaperDollInfoFrame\\SkillFrame-BotRight")
frame.bottomRight = bottomRight

local barLeft = frame:CreateTexture(nil, "ARTWORK")
barLeft:SetPoint("TOPLEFT", 15, -186)
barLeft:SetWidth(256)
barLeft:SetHeight(16)
barLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
barLeft:SetTexCoord(0, 1, 0, 0.25)
frame.barLeft = barLeft

local barRight = frame:CreateTexture(nil, "ARTWORK")
barRight:SetPoint("LEFT", barLeft, "RIGHT")
barRight:SetWidth(75)
barRight:SetHeight(16)
barRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
barRight:SetTexCoord(0, 0.29296875, 0.25, 0.5)
frame.barRight = barRight

--  TITLE TEXT

local title = frame:CreateFontString("$parentTitleText", "ARTWORK", "GameFontNormal")
title:SetPoint("TOP", 0, -17)
frame.titleText = title

--  DRAG REGION

local drag = CreateFrame("Frame", "$parentDragFrame", frame)
drag:SetPoint("TOP", 8, -10)
drag:SetWidth(256)
drag:SetHeight(28)
frame.dragFrame = drag

drag:SetScript("OnMouseDown", function(self, button)
	if button == "LeftButton" then
		local frame = self:GetParent()
		frame.isMoving = true
		frame:StartMoving()
		CloseDropDownMenus()
		-- Clear editBox focus while moving because of problems with the empty
		-- editbox (editBox only updates the actual cursor position when there
		-- is text in the editBox.  Also, if the editbox was empty, then give
		-- it a temporary space character while we are moving it.
		if NotebookDescriptionEditBox.hasFocus then
			frame.editHadFocus = true
			NotebookDescriptionEditBox:ClearFocus()
		end
		if NotebookDescriptionEditBox:GetNumLetters() == 0 then
			frame.editWasEmpty = true
			NotebookDescriptionEditBox:SetText(" ")
		end
	end
end)

drag:SetScript("OnMouseUp", function(self, button)
	local frame = self:GetParent()
	if frame.isMoving then
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		frame.isMoving = nil
		-- Restore the editbox's focus and empty status if needed
		if frame.editWasEmpty then
			NotebookDescriptionEditBox:SetText("")
			frame.editWasEmpty = nil
		end
		if frame.editHadFocus then
			frame.editHadFocus = nil
			NotebookDescriptionEditBox:SetFocus()
		end
	end
end)

drag:SetScript("OnHide", function(self)
	local frame = self:GetParent()
	if frame.isMoving then
		frame:StopMovingOrSizing()
		frame:SetUserPlaced(false)
		frame.isMoving = nil
		-- Restore the editbox's empty status if needed
		if frame.editWasEmpty then
			NotebookDescriptionEditBox:SetText("")
			frame.editWasEmpty = nil
		end
		frame.editHadFocus = nil
	end
end)

--  CLOSE X BUTTON

local closeX = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeX:SetPoint("TOPRIGHT", -30, -8)
frame.closeXButton = closeX

--  CLOSE BUTTON

local close = CreateFrame("Button", "$parentCloseButton", frame, "UIPanelButtonTemplate")
close:SetPoint("BOTTOMRIGHT", -42, 80)
close:SetWidth(80)
close:SetHeight(22)
close:SetNormalFontObject(GameFontNormalSmall)
close:SetHighlightFontObject(GameFontHighlightSmall)
close:SetDisabledFontObject(GameFontDisableSmall)
close:SetScript("OnClick", HideParentPanel)
close:SetText(CLOSE)
frame.closeButton = close

--  SAVE BUTTON

local save = CreateFrame("Button", "$parentSaveButton", frame, "UIPanelButtonTemplate")
save:SetPoint("BOTTOMLEFT", 20, 80)
save:SetWidth(60)
save:SetHeight(22)
save:SetNormalFontObject(GameFontNormalSmall)
save:SetHighlightFontObject(GameFontHighlightSmall)
save:SetDisabledFontObject(GameFontDisableSmall)
save:SetScript("OnClick", Notebook.Frame_SaveButtonOnClick)
save:SetText(NOTEBOOK_TEXT.SAVE_BUTTON)
save.tooltipText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
save.newbieText = NOTEBOOK_TEXT.SAVE_BUTTON_TOOLTIP
frame.saveButton = save

--  CANCEL BUTTON

local cancel = CreateFrame("Button", "$parentCancelButton", frame, "UIPanelButtonTemplate")
cancel:SetPoint("BOTTOMLEFT", save, "BOTTOMRIGHT")
cancel:SetWidth(60)
cancel:SetHeight(22)
cancel:SetNormalFontObject(GameFontNormalSmall)
cancel:SetHighlightFontObject(GameFontHighlightSmall)
cancel:SetDisabledFontObject(GameFontDisableSmall)
cancel:SetScript("OnClick", Notebook.Frame_CancelButtonOnClick)
cancel:SetText(NOTEBOOK_TEXT.CANCEL_BUTTON)
cancel.tooltipText = NOTEBOOK_TEXT.CANCEL_BUTTON_TOOLTIP
cancel.newbieText = NOTEBOOK_TEXT.CANCEL_BUTTON_TOOLTIP
frame.cancelButton = cancel

--  NEW BUTTON

local new = CreateFrame("Button", "$parentNewButton", frame, "UIPanelButtonTemplate")
new:SetPoint("TOPRIGHT", -46, -49)
new:SetWidth(60)
new:SetHeight(22)
new:SetNormalFontObject(GameFontNormalSmall)
new:SetHighlightFontObject(GameFontHighlightSmall)
new:SetDisabledFontObject(GameFontDisableSmall)
new:SetScript("OnClick", Notebook.Frame_NewButtonOnClick)
new:SetText(NOTEBOOK_TEXT.NEW_BUTTON)
new.tooltipText = NOTEBOOK_TEXT.NEW_BUTTON_TOOLTIP
new.newbieText = NOTEBOOK_TEXT.NEW_BUTTON_TOOLTIP
frame.newButton = new

-- CAN SEND OPTION BUTTON

local canSend = CreateFrame("CheckButton", "$parentCanSendCheckButton", frame, "UICheckButtonTemplate")
canSend:SetPoint("LEFT", cancel, "RIGHT")
canSend:SetWidth(18)
canSend:SetHeight(18)
canSend:SetHitRectInsets(0, -70, 0, 0)

local text = canSend:CreateFontString("NotebookFrameCanSendText", "OVERLAY")
text:SetPoint("LEFT", canSend, "RIGHT", -1, 0)
canSend:SetFontString(text)
canSend:SetNormalFontObject(GameFontNormalSmall)
canSend:SetHighlightFontObject(GameFontHighlightSmall)
canSend:SetDisabledFontObject(GameFontDisableSmall)

canSend:SetText(NOTEBOOK_TEXT.CHECK_SEND_BUTTON)
canSend.tooltipOnText = NOTEBOOK_TEXT.CHECK_CAN_SEND_TOOLTIP
canSend.tooltipOffText = NOTEBOOK_TEXT.CHECK_NOT_SEND_TOOLTIP
frame.canSendCheckButton = canSend

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
	Notebook.Frame_CanSendCheckOnClick(self)
end)

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

local filterTab1 = CreateFrame("Button", "$parentFilterTab1", frame, "TabButtonTemplate")
filterTab1:SetPoint("TOPLEFT", 70, -39)
filterTab1:SetID(1)
filterTab1:SetScript("OnShow", tab_OnShow)
filterTab1:SetScript("OnEnter", tab_OnEnter)
filterTab1:SetScript("OnLeave", GameTooltip_Hide)
filterTab1:SetScript("OnClick", tab_OnClick)
filterTab1:SetText(NOTEBOOK_TEXT.ALL_TAB)
filterTab1.tooltipText = NOTEBOOK_TEXT.ALL_TAB_TOOLTIP
PanelTemplates_SelectTab(filterTab1)
frame.filterTab1 = filterTab1

local filterTab2 = CreateFrame("Button", "$parentFilterTab2", frame, "TabButtonTemplate")
filterTab2:SetPoint("TOPLEFT", filterTab1, "TOPRIGHT")
filterTab2:SetID(2)
filterTab2:SetScript("OnShow", tab_OnShow)
filterTab2:SetScript("OnEnter", tab_OnEnter)
filterTab2:SetScript("OnLeave", GameTooltip_Hide)
filterTab2:SetScript("OnClick", tab_OnClick)
filterTab2:SetText(NOTEBOOK_TEXT.MINE_TAB)
PanelTemplates_DeselectTab(filterTab2)
frame.filterTab2 = filterTab2

local filterTab3 = CreateFrame("Button", "$parentFilterTab3", frame, "TabButtonTemplate")
filterTab3:SetPoint("TOPLEFT", filterTab2, "TOPRIGHT")
filterTab3:SetID(3)
filterTab3:SetScript("OnShow", tab_OnShow)
filterTab3:SetScript("OnEnter", tab_OnEnter)
filterTab3:SetScript("OnLeave", GameTooltip_Hide)
filterTab3:SetScript("OnClick", tab_OnClick)
filterTab3:SetText(NOTEBOOK_TEXT.RECENT_TAB)
filterTab3.tooltipText = NOTEBOOK_TEXT.RECENT_TAB_TOOLTIP
PanelTemplates_DeselectTab(filterTab3)
frame.filterTab3 = filterTab3

--  LIST FRAME

local listFrame = CreateFrame("Frame", "$parentListFrame", frame)
listFrame:SetPoint("TOPLEFT", 20, -74)
listFrame:SetWidth(320)
listFrame:SetHeight(112)
frame.listFrame = listFrame

--  LIST BUTTONS

local function createListButton(id)
	local button = CreateFrame("Button", "NotebookListFrameButton" .. id, listFrame)
	button:SetWidth(298)
	button:SetHeight(NOTEBOOK_LIST_BUTTON_HEIGHT)
	button:SetID(id)

	local text = button:CreateFontString("$parentTitleText", "ARTWORK")
	text:SetPoint("LEFT", 10, -2)
	text:SetWidth(288)
	text:SetHeight(14)
	text:SetJustifyH("LEFT")
	button:SetFontString(text)
	button:SetNormalFontObject(GameFontNormalSmall)
	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)

	local highlight = button:CreateTexture("$parentHighlight", "HIGHLIGHT")
	highlight:SetPoint("LEFT", 2, -2)
	highlight:SetPoint("RIGHT", 2, -2)
	highlight:SetHeight(NOTEBOOK_LIST_BUTTON_HEIGHT)
	highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2", "ADD")
	button:SetHighlightTexture(highlight)

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
frame.listButtons = listButtons

for id = 1, NOTEBOOK_LIST_BUTTON_COUNT do
	local button = createListButton(id)
	if id == 1 then
		button:SetPoint("TOPLEFT")
	else
		button:SetPoint("TOPLEFT", listButtons[id - 1], "BOTTOMLEFT")
	end
	listButtons[id] = button
end

--  LIST SCROLL BAR

local scrollFrame = CreateFrame("ScrollFrame", "NotebookListFrameScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, -2)
scrollFrame:SetWidth(296)
scrollFrame:SetHeight(112)
frame.listScrollFrame = scrollFrame

scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, NOTEBOOK_LIST_BUTTON_HEIGHT, Notebook.Frame_UpdateList)
end)

local scrollChild = CreateFrame("Frame", "$parentScrollChildFrame", scrollFrame)
scrollChild:SetWidth(296)
scrollChild:SetHeight(112)
scrollFrame:SetScrollChild(scrollChild)
frame.listScrollChild = scrollChild

--  DESCRIPTION FRAME

local description = CreateFrame("Frame", "NotebookDescriptionFrame", frame)
description:SetPoint("TOPLEFT", 25, -202)
description:SetWidth(317)
description:SetHeight(204)
frame.descriptionFrame = description

--  EDIT SCROLL FRAME

local editScroll = CreateFrame("ScrollFrame", "NotebookFrameEditScrollFrame", description)
editScroll:SetPoint("TOPLEFT")
editScroll:SetWidth(314)
editScroll:SetHeight(204)
editScroll.scrollBarHideable = true
frame.editScrollFrame = editScroll

editScroll:SetScript("OnMouseWheel", ScrollFrameTemplate_OnMouseWheel)
editScroll:SetScript("OnVerticalScroll", Notebook.Frame_OnVerticalScroll)

editScroll:EnableMouse(true)
editScroll:SetScript("OnMouseUp", function(self, button)
	-- Focus the edit box when clicking anywhere in the description frame,
	-- since the edit box magically resizes itself based on the height of
	-- its contents since some patches ago.
	if button == "LeftButton" and NotebookDescriptionEditBox:IsShown()
	and not NotebookDescriptionEditBox:IsMouseOver() and not NotebookFrameEditScrollFrameScrollBar:IsMouseOver() then
		NotebookDescriptionEditBox:SetFocus()
	end
end)

local editBar = CreateFrame("Slider", "$parentScrollBar", editScroll, "UIPanelScrollBarTemplate")
editBar:SetPoint("TOPRIGHT", 0, -14)
editBar:SetPoint("BOTTOMRIGHT", 0, 14)
frame.editScrollBar = editBar

ScrollFrame_OnLoad(editScroll)
ScrollFrame_OnScrollRangeChanged(editScroll, 0)

local editBox = CreateFrame("EditBox", "NotebookDescriptionEditBox", editScroll)
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
frame.editBox = editBox

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
	-- A minor kludge to move to the top of the scroll-frame
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

--  TEXT SCROLL FRAME (for non-editable text)

local textScroll = CreateFrame("ScrollFrame", "NotebookFrameTextScrollFrame", description)
textScroll:SetPoint("TOPLEFT")
textScroll:SetWidth(306)
textScroll:SetHeight(204)
textScroll:Hide()
textScroll.scrollBarHideable = true
frame.textScrollFrame = textScroll

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
frame.textScrollBar = textBar

ScrollFrame_OnLoad(textScroll)
ScrollFrame_OnScrollRangeChanged(textScroll, 0)

local textChild = CreateFrame("Frame", "$parentScrollChild", textScroll)
textChild:SetPoint("TOPLEFT")
textChild:SetWidth(296)
textChild:SetHeight(204)
textChild:EnableMouse(true)
textScroll:SetScrollChild(textChild)
frame.textScrollChild = textChild

local textBox = textChild:CreateFontString("NotebookDescriptionTextBox", "OVERLAY", "GameFontNormal")
textBox:SetPoint("TOPLEFT", 10, -2)
textBox:SetWidth(286)
textBox:SetHeight(0)
textBox:SetJustifyH("LEFT")
textBox:SetIndentedWordWrap(false)
frame.textBox = textBox

--  DROPDOWN MENU

local dropdown = CreateFrame("Frame", "NotebookDropDown", frame, "UIDropDownMenuTemplate")
frame.dropdown = dropdown

------------------------------------------------------------------------
--	Addon
------------------------------------------------------------------------

frame:SetScript("OnEvent", Notebook.OnEvent)

Notebook.OnLoad(frame)
Notebook.Frame_OnLoad(frame)