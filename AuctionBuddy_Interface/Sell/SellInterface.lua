-- 
local AuctionBuddy = unpack(select(2, ...))

local SellInterfaceModule = AuctionBuddy:NewModule("SellInterfaceModule", "AceEvent-3.0")

local UtilsModule = nil
local InterfaceFunctionsModule = nil
local ResultsTableModule = nil
local BuyInterfaceModule = nil
local ContainerModule = nil
local DatabaseModule = nil
local OptionsPanelModule = nil

SellInterfaceModule.itemPriceBidValue = nil
SellInterfaceModule.stackPriceBidValue = nil

SellInterfaceModule.itemPriceValue = nil
SellInterfaceModule.stackPriceValue = nil

function SellInterfaceModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterMessage("RESULTSTABLE_ITEM_SELECTED", self.OnResultsTableItemSelected)	
	self:RegisterMessage("SHOW_AB_SELL_FRAME", self.OnShowSellFrame)	
	self:RegisterMessage("ON_AH_SCAN_RUNNING", self.OnAHScanRunning)
	self:RegisterMessage("SCAN_SELECTED_ITEM_AH_PAGE", self.ResetSelectedItemData)
	self:RegisterMessage("REMOVE_SELECTED_RESULTS_ROW", self.ResetSelectedItemData)
	self:RegisterMessage("FAILED_TO_SELECT_RESULT_ITEM", self.ResetSelectedItemData)
	self:RegisterMessage("ON_AUCTION_HOUSE_SEARCH", self.OnAuctionHouseSearch)
	self:RegisterMessage("ON_ENABLE_SEARCH_MORE_BUTTON", self.OnEnableSearchMoreButton)
	self:RegisterMessage("ON_DISABLE_SEARCH_MORE_BUTTON", self.OnDisableSearchMoreButton)
	self:RegisterMessage("ON_ENABLE_CREATE_AUCTION_BUTTON", self.OnEnableCreateAuctionButton)
	
	if self.interfaceCreated == true then
		return
	end

	SellInterfaceModule.itemPriceBidValue = 0
	SellInterfaceModule.stackPriceBidValue = 0
	
	SellInterfaceModule.itemPriceValue = 0
	SellInterfaceModule.stackPriceValue = 0
	
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	ResultsTableModule = AuctionBuddy:GetModule("ResultsTableModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	ContainerModule = AuctionBuddy:GetModule("ContainerModule")
	OptionsPanelModule = AuctionBuddy:GetModule("OptionsPanelModule")

	self:CreateSellInterface()	
	self:CreateSellInterfaceButtons(self.mainFrame)
	self:CreateSellInterfaceOptions(self.mainFrame)
	self:CreateSellTab(self.mainFrame)
	self:CreateItemToSellEditBoxes(self.mainFrame)
	self:CreateItemToSellParameters(self.mainFrame)
	
	ResultsTableModule:CreateResultsScrollFrameTable(self.mainFrame, 277, -135)

	self.mainFrame.scrollTable.scanRunningText = self.mainFrame.scrollTable:CreateFontString("AB_BuyInterface_MainFrame_ScanRunning_Text", "OVERLAY")
	self.mainFrame.scrollTable.scanRunningText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	self.mainFrame.scrollTable.scanRunningText:SetWidth(100)
	self.mainFrame.scrollTable.scanRunningText:SetPoint("CENTER", 0, 0)
	self.mainFrame.scrollTable.scanRunningText:SetJustifyH("LEFT")
	self.mainFrame.scrollTable.scanRunningText:SetText("Scanning...")
	self.mainFrame.scrollTable.scanRunningText:Hide()
	
	self.interfaceCreated = true
	
end

function SellInterfaceModule:AUCTION_HOUSE_CLOSED()
	
	self:HideSellInterface()
	self:ResetData()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

end

function SellInterfaceModule:CreateSellInterface()
	
	self.mainFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame", UIParent, "BasicFrameTemplate")
	self.mainFrame:SetMovable(true)
	self.mainFrame:EnableMouse(true)
	self.mainFrame:RegisterForDrag("LeftButton")
	self.mainFrame:SetClampedToScreen(true)
	SellInterfaceModule:SetFrameParameters(self.mainFrame, 1250, 700, nil, DatabaseModule.generalOptions.point, DatabaseModule.generalOptions.xPosOffset, DatabaseModule.generalOptions.yPosOffset)
	self.mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.mainFrame:SetScript("OnDragStart",  function() self.mainFrame:StartMoving() end)
	self.mainFrame:SetScript("OnDragStop", function() 
		self.mainFrame:StopMovingOrSizing() 
		local point, _, _, xPos, yPos = self.mainFrame:GetPoint()
		DatabaseModule.generalOptions.point = point
		DatabaseModule.generalOptions.xPosOffset = xPos
		DatabaseModule.generalOptions.yPosOffset = yPos
	end)
	self.mainFrame:SetScript("OnShow", function() self:OnShowSellFrame() end)
	self.mainFrame:SetScript("OnHide", function() InterfaceFunctionsModule:CloseAuctionHouseCustom() end)
	self.mainFrame.CloseButton:SetScript("OnClick", function() CloseAuctionHouse() end)
	tinsert(UISpecialFrames, "AB_SellInterface_MainFrame")
	
	self.mainFrame.title = self.mainFrame:CreateFontString("AB_SellInterface_MainFrame_Title_Text", "OVERLAY", "GameFontNormal")
	self.mainFrame.title:SetPoint("CENTER", 0, 339)
	self.mainFrame.title:SetJustifyH("CENTER")
	self.mainFrame.title:SetText("AuctionBuddy SELL")
	
	self.mainFrame.itemFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.itemFrame, 285, 417, nil, "LEFT", 10, 46, "BACKGROUND")
	
	self.mainFrame.resultsTableFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ResultsFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.resultsTableFrame, 668, 570, nil, "CENTER", 277, -30, "BACKGROUND")

	self.mainFrame.resultsTableFrame.searchMore = CreateFrame("Button", "AB_SellInterface_MainFrame_ResultsFrame_SearchMore_Button", self.mainFrame.resultsTableFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(self.mainFrame.resultsTableFrame.searchMore, 170, 24, "Search higher prices", "CENTER", 0, -262)
	self.mainFrame.resultsTableFrame.searchMore:SetScript("OnClick", function()
		self:SendMessage("ON_SEARCH_MORE_RESULTS")
	end)
	self.mainFrame.resultsTableFrame.searchMore:Disable()
	
	self.mainFrame.containerFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ContainerFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.containerFrame, 265, 570, nil, "CENTER", -193, -30, "BACKGROUND")
	
	self:HideSellInterface()
	
end

function SellInterfaceModule:CreateSellInterfaceButtons(parentFrame)
	
	parentFrame.DefaultAHButton = CreateFrame("Button", "AB_SellInterface_MainFrame_DefaultAH_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.DefaultAHButton, 80, 24, "Default AH", "TOPRIGHT", -25, -45)
	parentFrame.DefaultAHButton:SetScript("OnClick", function() 
		InterfaceFunctionsModule.switchingUI = true
		parentFrame:Hide()
		self:ResetData()
		self:SendMessage("REMOVE_INSERTED_ITEM", parentFrame)
		AuctionFrame_Show()
		InterfaceFunctionsModule.switchingUI = false
	end)
	
	parentFrame.BuyFrameButton = CreateFrame("Button", "AB_SellInterface_MainFrame_SellFrame_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.BuyFrameButton, 80, 24, "Show Buy", "TOPRIGHT", -105, -45)
	parentFrame.BuyFrameButton:SetScript("OnClick", function()
		InterfaceFunctionsModule.switchingUI = true
		parentFrame:Hide()
		self:ResetData()
		self:SendMessage("REMOVE_INSERTED_ITEM", parentFrame)
		self:SendMessage("SHOW_AB_BUY_FRAME", parentFrame)
	end)
	
	parentFrame.doubleClickInfoText = parentFrame:CreateFontString("AB_SellInterface_MainFrame_InstaBuyCheck_Text", "OVERLAY", "GameFontNormal")
	parentFrame.doubleClickInfoText:SetWidth(250)
	parentFrame.doubleClickInfoText:SetPoint("TOPLEFT", 20, -55)
	parentFrame.doubleClickInfoText:SetJustifyH("LEFT")
	parentFrame.doubleClickInfoText:SetText("Double Click to:")

	parentFrame.instaBuyCheckBox = CreateFrame("CheckButton", "AB_SellInterface_MainFrame_InstaBuyCheck", parentFrame, "ChatConfigBaseCheckButtonTemplate")
	parentFrame.instaBuyCheckBox:SetWidth(24)
	parentFrame.instaBuyCheckBox:SetHeight(24)
	parentFrame.instaBuyCheckBox:SetPoint("TOPLEFT", 125, -35)
	parentFrame.instaBuyCheckBox:SetScript("OnClick", function() 
		DatabaseModule.buyOptions.doubleClickToBuy = not DatabaseModule.buyOptions.doubleClickToBuy 
	end)
	parentFrame.instaBuyCheckBox:SetScript("OnShow", function() 	
		parentFrame.instaBuyCheckBox:SetChecked(DatabaseModule.buyOptions.doubleClickToBuy)
	end)

	parentFrame.instaBuyCheckBox.text = parentFrame.instaBuyCheckBox:CreateFontString("AB_SellInterface_MainFrame_InstaBuyCheck_Text", "OVERLAY", "GameFontNormal")
	parentFrame.instaBuyCheckBox.text:SetWidth(250)
	parentFrame.instaBuyCheckBox.text:SetPoint("CENTER", 140, 0)
	parentFrame.instaBuyCheckBox.text:SetJustifyH("LEFT")
	parentFrame.instaBuyCheckBox.text:SetText("Buy an item")

	parentFrame.instaBidCheckBox = CreateFrame("CheckButton", "AB_SellInterface_MainFrame_InstaBidCheck", parentFrame, "ChatConfigBaseCheckButtonTemplate")
	parentFrame.instaBidCheckBox:SetWidth(24)
	parentFrame.instaBidCheckBox:SetHeight(24)
	parentFrame.instaBidCheckBox:SetPoint("TOPLEFT", 125, -65)
	parentFrame.instaBidCheckBox:SetScript("OnClick", function() 
		DatabaseModule.buyOptions.doubleClickToBid = not DatabaseModule.buyOptions.doubleClickToBid 
	end)
	parentFrame.instaBidCheckBox:SetScript("OnShow", function() 	
		parentFrame.instaBidCheckBox:SetChecked(DatabaseModule.buyOptions.doubleClickToBid)
	end)

	parentFrame.instaBidCheckBox.text = parentFrame.instaBidCheckBox:CreateFontString("AB_SellInterface_MainFrame_InstaBidCheck_Text", "OVERLAY", "GameFontNormal")
	parentFrame.instaBidCheckBox.text:SetWidth(250)
	parentFrame.instaBidCheckBox.text:SetPoint("CENTER", 140, 0)
	parentFrame.instaBidCheckBox.text:SetJustifyH("LEFT")
	parentFrame.instaBidCheckBox.text:SetText("Bid on an item")

	parentFrame.itemToSellButton = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_Button", parentFrame)
	SellInterfaceModule:SetFrameParameters(parentFrame.itemToSellButton, 37, 37, nil, "TOPLEFT", 80, -115)
	parentFrame.itemToSellButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")	
	parentFrame.itemToSellButton:SetScript("OnClick", function() 
		self:ResetData()
		self:SendMessage("ON_CLICK_ITEM_TO_SELL", self)
	end)
	parentFrame.itemToSellButton:SetScript("OnLoad", function() 
		self.mainFrame.itemToSellButton:RegisterForDrag("LeftButton") 
	end)
	parentFrame.itemToSellButton:SetScript("OnReceiveDrag", function() 
		self:SendMessage("ON_CLICK_ITEM_TO_SELL", self)
	end)

	parentFrame.itemToSellButton.bgTexture = self.mainFrame.itemToSellButton:CreateTexture(nil, "ARTWORK")
	parentFrame.itemToSellButton.bgTexture:SetPoint("CENTER")
	parentFrame.itemToSellButton.bgTexture:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
	
	parentFrame.itemToSellButton.itemTexture = self.mainFrame.itemToSellButton:CreateTexture(nil, "OVERLAY")
	parentFrame.itemToSellButton.itemTexture:SetWidth(37)
	parentFrame.itemToSellButton.itemTexture:SetHeight(37)
	parentFrame.itemToSellButton.itemTexture:SetPoint("CENTER")
	
	parentFrame.itemToSellButton.text = self.mainFrame.itemToSellButton:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_Text", "OVERLAY")
	parentFrame.itemToSellButton.text:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.itemToSellButton.text:SetWidth(125)
	parentFrame.itemToSellButton.text:SetPoint("CENTER", 90, 0)
	parentFrame.itemToSellButton.text:SetJustifyH("LEFT")
	parentFrame.itemToSellButton.text:SetText("<-- [Insert Item]")

	parentFrame.currentPlayerGold = parentFrame:CreateFontString("AB_SellInterface_MainFrame_CurrentGold", "OVERLAY")
	parentFrame.currentPlayerGold:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.currentPlayerGold:SetWidth(250)
	parentFrame.currentPlayerGold:SetPoint("BOTTOMLEFT", 110, 8)
	parentFrame.currentPlayerGold:SetJustifyH("LEFT")
	parentFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
	parentFrame.currentPlayerGold:SetText(parentFrame.currentPlayerGold.value)

	parentFrame.currentPlayerGold.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_CurrentGold_Text", "OVERLAY", "GameFontNormal")
	parentFrame.currentPlayerGold.text:SetWidth(250)
	parentFrame.currentPlayerGold.text:SetPoint("BOTTOMLEFT", 20, 12)
	parentFrame.currentPlayerGold.text:SetJustifyH("LEFT")
	parentFrame.currentPlayerGold.text:SetText("Player Gold:")

	parentFrame.uiScaleSlider = CreateFrame("Slider", "AB_SellInterface_MainFrame_UISlider", parentFrame, "OptionsSliderTemplate")
	parentFrame.uiScaleSlider:SetPoint("TOP", 210, -50)
	parentFrame.uiScaleSlider:SetWidth(150)
	parentFrame.uiScaleSlider:SetHeight(20)
	parentFrame.uiScaleSlider:SetOrientation("HORIZONTAL")
	parentFrame.uiScaleSlider:SetMinMaxValues(0.5, 1.0)
	parentFrame.uiScaleSlider:SetValueStep(0.1)
	parentFrame.uiScaleSlider:SetValue(DatabaseModule.generalOptions.uiScale)
	parentFrame.uiScaleSlider:SetObeyStepOnDrag(true)
	parentFrame.uiScaleSlider:SetScript("OnShow", function() parentFrame.uiScaleSlider:SetValue(DatabaseModule.generalOptions.uiScale) end)

	parentFrame.uiScaleSlider.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_UISlider_Text", "OVERLAY", "GameFontNormal")
	parentFrame.uiScaleSlider.text:SetWidth(250)
	parentFrame.uiScaleSlider.text:SetPoint("TOP", 210, -35)
	parentFrame.uiScaleSlider.text:SetJustifyH("CENTER")
	parentFrame.uiScaleSlider.text:SetText("AB UI Scale")

	parentFrame.uiScaleSliderApplyButton = CreateFrame("Button", "AB_SellInterface_MainFrame_UISlider_ApplyButton", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.uiScaleSliderApplyButton, 60, 24, "Apply", "TOP", 330, -48)
	parentFrame.uiScaleSliderApplyButton:SetScript("OnClick", function() 
		DatabaseModule.generalOptions.uiScale = parentFrame.uiScaleSlider:GetValue()
		self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale) 
	end)
	
end

function SellInterfaceModule:CreateSellInterfaceOptions(parentFrame)

	parentFrame.alreadyBidText = parentFrame:CreateFontString("AB_SellInterface_MainFrame_AlreadyBid_Text", "OVERLAY")
	parentFrame.alreadyBidText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.alreadyBidText:SetWidth(250)
	parentFrame.alreadyBidText:SetPoint("BOTTOMLEFT", 25, 170)
	parentFrame.alreadyBidText:SetJustifyH("LEFT")
	parentFrame.alreadyBidText:SetText("You already have a bid on this item.")
	parentFrame.alreadyBidText:Hide()

	parentFrame.totalBidCost = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBidCost", "OVERLAY")
	parentFrame.totalBidCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBidCost:SetWidth(250)
	parentFrame.totalBidCost:SetPoint("BOTTOMLEFT", 25, 142)
	parentFrame.totalBidCost:SetJustifyH("RIGHT")
	parentFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBidCost:SetText(parentFrame.totalBidCost.value)

	parentFrame.totalBidCost.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBidCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBidCost.text:SetWidth(250)
	parentFrame.totalBidCost.text:SetPoint("BOTTOMLEFT", 25, 145)
	parentFrame.totalBidCost.text:SetJustifyH("LEFT")
	parentFrame.totalBidCost.text:SetText("Total Bid Cost:")

	parentFrame.totalBuyCost = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBuyCost", "OVERLAY")
	parentFrame.totalBuyCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBuyCost:SetWidth(250)
	parentFrame.totalBuyCost:SetPoint("BOTTOMLEFT", 25, 117)
	parentFrame.totalBuyCost:SetJustifyH("RIGHT")
	parentFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBuyCost:SetText(parentFrame.totalBuyCost.value)

	parentFrame.totalBuyCost.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBuyCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBuyCost.text:SetWidth(250)
	parentFrame.totalBuyCost.text:SetPoint("BOTTOMLEFT", 25, 120)
	parentFrame.totalBuyCost.text:SetJustifyH("LEFT")
	parentFrame.totalBuyCost.text:SetText("Total Buyout Cost:")

	parentFrame.buySelectedItem = CreateFrame("Button", "AB_SellInterface_MainFrame_SellSelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.buySelectedItem, 125, 24, "Buy Selected Item", "LEFT", 160, -253)
	parentFrame.buySelectedItem:SetScript("OnClick", function() 
		self:SendMessage("ON_BUY_SELECTED_ITEM")
		SellInterfaceModule:DisableBuyBidButtons()
		parentFrame.scrollTable:ClearSelection()
	end)
	parentFrame.buySelectedItem:Disable()
	
	parentFrame.bidSelectedItem = CreateFrame("Button", "AB_SellInterface_MainFrame_BidSelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.bidSelectedItem, 125, 24, "Bid Selected Item", "LEFT", 20, -253)
	parentFrame.bidSelectedItem:SetScript("OnClick", function() 
		self:SendMessage("ON_BID_SELECTED_ITEM")
		self:DisableBuyBidButtons()
		parentFrame.alreadyBidText:Hide()
		parentFrame.scrollTable:ClearSelection() 
	end)
	parentFrame.bidSelectedItem:Disable()

	parentFrame.manageFavoriteLists = CreateFrame("Button", "AB_SellInterface_MainFrame_Options_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.manageFavoriteLists, 100, 24, "Options", "LEFT", 100, -290)
	parentFrame.manageFavoriteLists:SetScript("OnClick", function() 
		parentFrame:Hide()
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.sellParameters)
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.sellParameters)
	end)

end

function SellInterfaceModule:CreateItemToSellEditBoxes(parentFrame)

	parentFrame.itemToSellBidText = parentFrame.itemFrame:CreateFontString("AB_SellInterface_MainFrame_ItemToSellBid_Text", "OVERLAY")
	parentFrame.itemToSellBidText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.itemToSellBidText:SetPoint("LEFT", 105, 135)
	parentFrame.itemToSellBidText:SetJustifyH("CENTER")
	parentFrame.itemToSellBidText:SetText("- Auction Bid -")

	parentFrame.itemPriceBid = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_ItemPriceBid", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.itemPriceBid, nil, nil, nil, "CENTER", 100, -60, nil, parentFrame.itemToSellButton)
	parentFrame.itemPriceBid:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.itemPriceBid, self.itemPriceBidValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.itemPriceBid, function() 
			InterfaceFunctionsModule:ItemPriceUpdated(parentFrame.itemPriceBid, parentFrame.stackSize, parentFrame.stackPriceBid)
		end) 
	end)
	
	parentFrame.itemPriceBid.text = parentFrame.itemPriceBid:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_ItemPriceBid_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemPriceBid.text:SetPoint("CENTER", -140, 0)
	parentFrame.itemPriceBid.text:SetJustifyH("CENTER")
	parentFrame.itemPriceBid.text:SetText("Item Price")
	
	parentFrame.stackPriceBid = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_StackPriceBid", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackPriceBid, nil, nil, nil, "CENTER", 100, -85, nil, parentFrame.itemToSellButton)
	parentFrame.stackPriceBid:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.stackPriceBid, self.stackPriceBidValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.stackPriceBid, function() 
			InterfaceFunctionsModule:StackPriceUpdated(parentFrame.stackPriceBid, parentFrame.stackSize, parentFrame.itemPriceBid)
		end)
	end)
	
	parentFrame.stackPriceBid.text = parentFrame.stackPriceBid:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackPriceBid_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackPriceBid.text:SetPoint("CENTER", -140, 0)
	parentFrame.stackPriceBid.text:SetJustifyH("CENTER")
	parentFrame.stackPriceBid.text:SetText("Stack Price")

	parentFrame.itemToSellBidText = parentFrame.itemFrame:CreateFontString("AB_SellInterface_MainFrame_ItemToSellBid_Text", "OVERLAY")
	parentFrame.itemToSellBidText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.itemToSellBidText:SetPoint("LEFT", 90, 60)
	parentFrame.itemToSellBidText:SetJustifyH("CENTER")
	parentFrame.itemToSellBidText:SetText("- Auction Buyout -")

	parentFrame.itemPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_ItemPrice", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.itemPrice, nil, nil, nil, "CENTER", 100, -135, nil, parentFrame.itemToSellButton)
	parentFrame.itemPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.itemPrice, self.itemPriceValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.itemPrice, function() 
			InterfaceFunctionsModule:ItemPriceUpdated(parentFrame.itemPrice, parentFrame.stackSize, parentFrame.stackPrice)
		end) 
	end)
	
	parentFrame.itemPrice.text = parentFrame.itemPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_ItemPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.itemPrice.text:SetJustifyH("CENTER")
	parentFrame.itemPrice.text:SetText("Item Price")
	
	parentFrame.stackPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_StackPrice", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackPrice, nil, nil, nil, "CENTER", 100, -160, nil, parentFrame.itemToSellButton)
	parentFrame.stackPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.stackPrice, self.stackPriceValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.stackPrice, function() 
			InterfaceFunctionsModule:StackPriceUpdated(parentFrame.stackPrice, parentFrame.stackSize, parentFrame.itemPrice)
		end) 
	end)
	
	parentFrame.stackPrice.text = parentFrame.stackPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.stackPrice.text:SetJustifyH("CENTER")
	parentFrame.stackPrice.text:SetText("Stack Price")

	parentFrame.stackSize = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackSize", parentFrame, "InputBoxTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackSize, 40, 40, nil, "CENTER", 50, -200, nil, parentFrame.itemToSellButton)
	parentFrame.stackSize:SetAutoFocus(false)
	parentFrame.stackSize:SetJustifyH("CENTER")
	parentFrame.stackSize:SetMaxBytes(6)
	parentFrame.stackSize:SetText("1")
	parentFrame.stackSize:SetScript("OnTextChanged", function()
		self:SendMessage("ON_STACK_SIZE_TEXT_CHANGED", parentFrame.itemPrice, parentFrame.stackPrice, parentFrame.stackSize)
		self:SendMessage("ON_STACK_SIZE_TEXT_CHANGED", parentFrame.itemPriceBid, parentFrame.stackPriceBid, parentFrame.stackSize)
		self:SendMessage("UPDATE_MAX_STACK_VALUES", parentFrame)
		self:SendMessage("UPDATE_DEPOSIT_COST", parentFrame)
	end)
	parentFrame.stackSize:SetScript("OnEscapePressed", function() parentFrame.stackSize:ClearFocus() end)
	
	parentFrame.stackSize.textLeft = parentFrame.stackSize:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackSize_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackSize.textLeft:SetPoint("CENTER", -80, 0)
	parentFrame.stackSize.textLeft:SetJustifyH("CENTER")
	parentFrame.stackSize.textLeft:SetText("Stack Size")

	parentFrame.stackSize.textRight = parentFrame.stackSize:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackSize_Text", "OVERLAY")
	parentFrame.stackSize.textRight:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackSize.textRight:SetPoint("CENTER", 35, 0)
	parentFrame.stackSize.textRight:SetJustifyH("CENTER")
	parentFrame.stackSize.textRight:SetText("of")

	parentFrame.stackSize.maxStackValue = parentFrame.stackSize:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_MaxStackSize_Text", "OVERLAY")
	parentFrame.stackSize.maxStackValue:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackSize.maxStackValue:SetPoint("CENTER", 65, 0)
	parentFrame.stackSize.maxStackValue:SetJustifyH("CENTER")
	parentFrame.stackSize.maxStackValue:SetText("1")

	parentFrame.stackSize.maxStackBtn = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_MaxStackSize_Btn", parentFrame.stackSize, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackSize.maxStackBtn, 50, 24, "Max.", "CENTER", 110, 0, "HIGH", parentFrame.stackSize)
	parentFrame.stackSize.maxStackBtn:SetScript("OnClick", function() 
		self:SendMessage("ON_CLICK_MAX_STACK_SIZE", parentFrame)
	end)
	parentFrame.stackSize.maxStackBtn:Disable()
	
	parentFrame.stackQuantity = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackQuantity", parentFrame, "InputBoxTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackQuantity, 40, 40, nil, "CENTER", 50, -225, nil, parentFrame.itemToSellButton)
	parentFrame.stackQuantity:SetAutoFocus(false)
	parentFrame.stackQuantity:SetJustifyH("CENTER")
	parentFrame.stackQuantity:SetMaxBytes(6)
	parentFrame.stackQuantity:SetText("1")
	parentFrame.stackQuantity:SetScript("OnTextChanged", function()
		self:SendMessage("UPDATE_MAX_STACK_VALUES", parentFrame)
		self:SendMessage("UPDATE_DEPOSIT_COST", parentFrame)
	end)
	parentFrame.stackQuantity:SetScript("OnEscapePressed", function() 
		parentFrame.stackQuantity:ClearFocus() 
	end)
	
	parentFrame.stackQuantity.textLeft = parentFrame.stackQuantity:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackQuantity_TextLeft", "OVERLAY", "GameFontNormal")
	parentFrame.stackQuantity.textLeft:SetPoint("CENTER", -80, 0)
	parentFrame.stackQuantity.textLeft:SetJustifyH("CENTER")
	parentFrame.stackQuantity.textLeft:SetText("Stack Quantity")

	parentFrame.stackQuantity.textRight = parentFrame.stackQuantity:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackQuantity_Text", "OVERLAY")
	parentFrame.stackQuantity.textRight:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackQuantity.textRight:SetPoint("CENTER", 35, 0)
	parentFrame.stackQuantity.textRight:SetJustifyH("CENTER")
	parentFrame.stackQuantity.textRight:SetText("of")

	parentFrame.stackQuantity.maxStackValue = parentFrame.stackQuantity:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_MaxStackQuantity_Text", "OVERLAY")
	parentFrame.stackQuantity.maxStackValue:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackQuantity.maxStackValue:SetPoint("CENTER", 65, 0)
	parentFrame.stackQuantity.maxStackValue:SetJustifyH("CENTER")
	parentFrame.stackQuantity.maxStackValue:SetText("1")

	parentFrame.stackQuantity.maxStackBtn = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_MaxStackQuantity_Btn", parentFrame.stackQuantity, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackQuantity.maxStackBtn, 50, 24, "Max.", "CENTER", 110, 0, "HIGH", parentFrame.stackQuantity)
	parentFrame.stackQuantity.maxStackBtn:SetScript("OnClick", function() 
		self:SendMessage("ON_CLICK_MAX_STACK_QUANTITY", parentFrame)
	end)
	parentFrame.stackQuantity.maxStackBtn:Disable()

end

function SellInterfaceModule:CreateItemToSellParameters(parentFrame)

	parentFrame.auctionDuration = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_AuctionDuration", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.auctionDuration:SetPoint("CENTER", parentFrame.itemToSellButton, "CENTER", 95, -300)
	parentFrame.auctionDuration.durationValue = 2
	parentFrame.auctionDuration.durationText = "8 Hours"
	UIDropDownMenu_SetWidth(parentFrame.auctionDuration, 100)
	UIDropDownMenu_SetText(parentFrame.auctionDuration, parentFrame.auctionDuration.durationText) 
	UIDropDownMenu_Initialize(parentFrame.auctionDuration, SellInterfaceModule.AuctionDurationDropDown)
	
	parentFrame.auctionDuration.text = parentFrame.auctionDuration:CreateFontString("AB_SellInterface_MainFrame_AuctionDuration_Text", "OVERLAY")
	parentFrame.auctionDuration.text:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.auctionDuration.text:SetPoint("CENTER", -100, 2)
	parentFrame.auctionDuration.text:SetJustifyH("LEFT")
	parentFrame.auctionDuration.text:SetText("Duration:")
	
	parentFrame.auctionDepositText = parentFrame.itemFrame:CreateFontString("AB_SellInterface_MainFrame_AuctionDeposit_Text", "OVERLAY")
	parentFrame.auctionDepositText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.auctionDepositText:SetPoint("LEFT", 90, -93)
	parentFrame.auctionDepositText:SetJustifyH("CENTER")
	parentFrame.auctionDepositText:SetText("Deposit:")
	
	parentFrame.auctionDepositCost = parentFrame.itemFrame:CreateFontString("AB_SellInterface_MainFrame_AuctionDeposit_Cost", "OVERLAY")
	parentFrame.auctionDepositCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.auctionDepositCost:SetPoint("LEFT", 150, -93)
	parentFrame.auctionDepositCost.value = GetCoinTextureString(0, 15)
	parentFrame.auctionDepositCost:SetText(parentFrame.auctionDepositCost.value)
	
	parentFrame.createAuction = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_CreateAuction", parentFrame.itemFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.createAuction, 160, 24, "Create Auction(s)", "CENTER", 55, -340, "HIGH", parentFrame.itemToSellButton)
	parentFrame.createAuction:SetScript("OnClick", function() 
		self:SendMessage("ON_SELL_SELECTED_ITEM", parentFrame)
		SellInterfaceModule:ResetData()
	end)
	parentFrame.createAuction:Disable()

end

local function SelectAuctionDuration(self, arg1, checked, value)
	
	SellInterfaceModule.mainFrame.auctionDuration.durationValue = arg1

	if arg1 == 1 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "2 Hours"
		
	elseif arg1 == 2 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "8 Hours"
		
	elseif arg1 == 3 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "24 Hours"
	end

	SellInterfaceModule:SendMessage("UPDATE_DEPOSIT_COST", SellInterfaceModule.mainFrame)
	
	UIDropDownMenu_SetText(SellInterfaceModule.mainFrame.auctionDuration, SellInterfaceModule.mainFrame.auctionDuration.durationText) 
end

function SellInterfaceModule:AuctionDurationDropDown(frame, level, menuList)

	local info = UIDropDownMenu_CreateInfo()
	info.func = SelectAuctionDuration
	
	info.text = "2 Hours"
	info.arg1 = 1
	info.checked = SellInterfaceModule.mainFrame.auctionDuration.durationValue == 1
	UIDropDownMenu_AddButton(info)
	
	info.text = "8 Hours"
	info.arg1 = 2
	info.checked = SellInterfaceModule.mainFrame.auctionDuration.durationValue == 2
	UIDropDownMenu_AddButton(info)
	
	info.text = "24 Hours"
	info.arg1 = 3
	info.checked = SellInterfaceModule.mainFrame.auctionDuration.durationValue == 3
	UIDropDownMenu_AddButton(info)
	
end

function SellInterfaceModule:CreateSellTab(parentFrame)

	if parentFrame.sellTabCreated == true then
		return
	end
	
	local auctionFrameNumTab = AuctionFrame.numTabs + 1
		
	parentFrame.sellTab = CreateFrame('Button', 'AuctionFrameTab' .. auctionFrameNumTab, AuctionFrame, 'AuctionTabTemplate')
	parentFrame.sellTab:SetID(auctionFrameNumTab)
	parentFrame.sellTab:SetText("AB Sell")
	parentFrame.sellTab:SetNormalFontObject(GameFontHighlightSmall)
	parentFrame.sellTab:SetPoint('LEFT', _G['AuctionFrameTab' .. auctionFrameNumTab - 1], 'RIGHT', -8, 0)
	parentFrame.sellTab:Show()
	
	self.mainFrame.sellTab.sellTabButton = parentFrame
	
	PanelTemplates_SetNumTabs(AuctionFrame, auctionFrameNumTab)
	PanelTemplates_EnableTab(AuctionFrame, auctionFrameNumTab)
	tinsert(AuctionBuddy.auctionTabs, parentFrame)
	
	parentFrame.sellTabCreated = true
	
end

function SellInterfaceModule:SetFrameParameters(frame, width, height, text, point, xOffSet, yOffSet, strata, relativeTo)

	if frame ~= nil then
		if width ~= nil then 
			frame:SetWidth(width)
		end

		if height ~= nil then 
			frame:SetHeight(height)
		end

		if text ~= nil then 
			frame:SetText(text)
		end

		if relativeTo == nil then
			frame:SetPoint(point, xOffSet, yOffSet)
		else
			frame:SetPoint(point, relativeTo, "CENTER", xOffSet, yOffSet)
		end

		if strate ~= nil then 
			frame:SetFrameStrata(strata)
		end
	end

end

function SellInterfaceModule:OnResultsTableItemSelected()
	UtilsModule:Log("Sell_OnResultsTableItemSelected", "OnResultsTableItemSelected", 3)

	SellInterfaceModule:EnableBuyBidButtons()

end

function SellInterfaceModule:OnShowSellFrame()
	UtilsModule:Log("SellInterfaceModule", "OnShowSellFrame", 3)

	SellInterfaceModule.mainFrame:Show()
	SellInterfaceModule:DisableBuyBidButtons()

	SellInterfaceModule.mainFrame:ClearAllPoints()
	SellInterfaceModule.mainFrame:SetPoint(DatabaseModule.generalOptions.point, DatabaseModule.generalOptions.xPosOffset, DatabaseModule.generalOptions.yPosOffset)
	SellInterfaceModule.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale)
	SellInterfaceModule.mainFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
	SellInterfaceModule.mainFrame.currentPlayerGold:SetText(SellInterfaceModule.mainFrame.currentPlayerGold.value)
	SellInterfaceModule:ResetItemCosts()
	SellInterfaceModule.mainFrame.scrollTable:ClearSelection()
	SellInterfaceModule.mainFrame.alreadyBidText:Hide()
	SellInterfaceModule.mainFrame.scrollTable.scanRunningText:Hide()

	InterfaceFunctionsModule.switchingUI = false

end

function SellInterfaceModule:OnAHScanRunning(isAHScanRunning)
	UtilsModule:Log("SellInterfaceModule", "OnAHScanRunning", 3)

	SellInterfaceModule:DisableBuyBidButtons()

	if isAHScanRunning then
		SellInterfaceModule.mainFrame.scrollTable.scanRunningText:Show()
	else
		SellInterfaceModule.mainFrame.scrollTable.scanRunningText:Hide()
	end

end

function SellInterfaceModule:ResetSelectedItemData()

	SellInterfaceModule.mainFrame.alreadyBidText:Hide()
	SellInterfaceModule:ResetItemCosts()
	SellInterfaceModule:DisableBuyBidButtons()

end

function SellInterfaceModule:ResetItemCosts()

	SellInterfaceModule.mainFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	SellInterfaceModule.mainFrame.totalBuyCost:SetText(BuyInterfaceModule.mainFrame.totalBuyCost.value)
	SellInterfaceModule.mainFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	SellInterfaceModule.mainFrame.totalBidCost:SetText(BuyInterfaceModule.mainFrame.totalBuyCost.value)

end

function SellInterfaceModule:EnableBuyBidButtons()

	SellInterfaceModule.mainFrame.buySelectedItem:Enable()
	SellInterfaceModule.mainFrame.bidSelectedItem:Enable()

end

function SellInterfaceModule:DisableBuyBidButtons()

	SellInterfaceModule.mainFrame.buySelectedItem:Disable()
	SellInterfaceModule.mainFrame.bidSelectedItem:Disable()

end

function SellInterfaceModule:OnAuctionHouseSearch()

	SellInterfaceModule.mainFrame.scrollTable:ClearSelection()

end

function SellInterfaceModule:OnEnableSearchMoreButton()

	SellInterfaceModule.mainFrame.resultsTableFrame.searchMore:Enable()

end

function SellInterfaceModule:OnDisableSearchMoreButton()

	SellInterfaceModule.mainFrame.resultsTableFrame.searchMore:Disable()

end

function SellInterfaceModule:OnEnableCreateAuctionButton()
	UtilsModule:Log("SellInterfaceModule", "OnEnableCreateAuctionButton", 2)

	if CanSendAuctionQuery() then
		SellInterfaceModule.mainFrame.createAuction:Enable()
	else
		SellInterfaceModule.mainFrame.createAuction:Disable()
		C_Timer.After(0.5, SellInterfaceModule.OnEnableCreateAuctionButton)
	end

end

function SellInterfaceModule:ResetData()
	UtilsModule:Log("SellInterfaceModule", "ResetData", 1)

	self.itemPriceBidValue = 0
	self.stackPriceBidValue = 0

	self.itemPriceValue = 0
	self.stackPriceValue = 0

	MoneyInputFrame_SetCopper(self.mainFrame.itemPriceBid, self.itemPriceBidValue)
	MoneyInputFrame_SetCopper(self.mainFrame.stackPriceBid, self.stackPriceBidValue) 

	MoneyInputFrame_SetCopper(self.mainFrame.itemPrice, self.itemPriceValue)
	MoneyInputFrame_SetCopper(self.mainFrame.stackPrice, self.stackPriceValue)

	self.mainFrame.itemToSellButton:SetScript("OnEnter", function(self)
	end)
	self.mainFrame.itemToSellButton.itemTexture:SetTexture(nil)
	self.mainFrame.itemToSellButton.text:SetText("<-- [Insert Item]")

	self.mainFrame.stackSize:SetText("1")
	self.mainFrame.stackQuantity:SetText("1")
	self.mainFrame.stackSize.maxStackValue:SetText("1")
	self.mainFrame.stackQuantity.maxStackValue:SetText("1")
	self.mainFrame.stackQuantity:SetText(1)
	self.mainFrame.stackSize:SetText(1)

	self.mainFrame.stackSize.maxStackBtn:Disable()
	self.mainFrame.stackQuantity.maxStackBtn:Disable()

	self.mainFrame.auctionDepositCost.value = GetCoinTextureString(0, 15)
	self.mainFrame.auctionDepositCost:SetText(self.mainFrame.auctionDepositCost.value)

	self.mainFrame.createAuction:Disable()

	if SellInterfaceModule.mainFrame ~= nil then
		SellInterfaceModule.mainFrame.scrollTable:SetData({}, true)
	end

end

function SellInterfaceModule:HideSellInterface()
	UtilsModule:Log("SellInterfaceModule", "HideSellInterface", 2)

	if SellInterfaceModule.mainFrame ~= nil then
		SellInterfaceModule.mainFrame:Hide()
	end

end