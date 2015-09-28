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

local selectedNoteIndex

------------------------------------------------------------------------
-- Update the frame

function Notebook:UpdateFrame()
	if not NotebookFrame:IsShown() then return end
	self:Print("UpdateFrame")

	-- TODO
	-- account for scroll offset
	-- update editbox/textarea
	-- filter tabs

	-- Temporary
	for i = 1, LIST_BUTTON_COUNT do
		local button = NotebookFrame.listButtons[i]
		local note = self:GetNote(i)
		if note then
			self:Print("---", i, note.title)
			button:SetID(i)
			button:SetText(note.title)
			button:Show()
		else
			self:Print("---")
			button:Hide()
			button:SetID(0)
			button:SetText("")
			button.tooltipText = nil
		end
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
			if NotebookFrame.editBox.hasFocus then
				NotebookFrame.editBox.hadFocus = true
				NotebookFrame.editBox:ClearFocus()
			end
			if NotebookFrame.EditBox:GetNumLetters() == 0 then
				NotebookFrame.editBox.wasEmpty = true
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
			local editBox = NotebookFrame.editBox
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
			local editBox = NotebookFrame.editBox
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

		local note, index = Notebook:GetNote(selectedNoteIndex)
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
	end

	local function ColorizeName(name, class) -- TODO: move this to core utilities?
		local color = class and (RAID_CLASS_COLORS or CUSTOM_CLASS_COLORS)[class]
		return color and "|c"..color.colorStr..name.."|r" or name
	end

	local function listButton_OnEnter(self)
		local note = NotebookNotes[self:GetID()]
		if note then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(format(L["%d characters"], strlenutf8(note.text)))
			GameTooltip:AddLine(format(L["Last changed %s by %s"], note.date, ColorizeName(note.author, note.authorClass)), 1, 1, 1)
			GameTooltip:Show()
		end
	end

	self.listButtons = setmetatable({}, { __index = function(t, i)
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

	-- List frame scroll bar --------------------------------------------

	local scrollFrame = CreateFrame("ScrollFrame", "NotebookFrameScrollFrame", listFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 0, -2)
	scrollFrame:SetSize(296, 112)
	self.scrollFrame = scrollFrame

	local scrollChild = CreateFrame("Frame", "NotebookFrameScrollChild", scrollFrame)
	scrollChild:SetSize(296, 112)
	scrollFrame:SetScrollChild(scrollChild)
	self.scrollChild = scrollChild

	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		-- TODO
		-- FauxScrollFrame_OnVerticalScroll(self, offset, NOTEBOOK_LIST_BUTTON_HEIGHT, Notebook.Frame_UpdateList)
	end)

	-- Description frame ------------------------------------------------

	local description = CreateFrame("Frame", nil, self)
	description:SetPoint("TOPLEFT", 25, -202)
	description:SetSize(317, 204)
	self.descriptionFrame = description

	-- Edit scroll frame ------------------------------------------------

	local editBox

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
		if not selectedNoteIndex then
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
