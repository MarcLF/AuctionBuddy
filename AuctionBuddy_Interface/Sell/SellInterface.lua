-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local SellInterfaceModule = AuctionBuddy:NewModule("SellInterfaceModule", "AceEvent-3.0")

local DebugModule = nil
local InterfaceFunctionsModule = nil
local ResultsTableModule = nil
local BuyInterfaceModule = nil
local ContainerModule = nil
local DatabaseModule = nil
local OptionsPanelModule = nil

SellInterfaceModule.itemPriceValue = nil
SellInterfaceModule.stackPriceValue = nil

function SellInterfaceModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterMessage("RESULTSTABLE_ITEM_SELECTED", self.OnResultsTableItemSelected)	
	self:RegisterMessage("SHOW_AB_SELL_FRAME", self.OnShowSellFrame)	

	if self.interfaceCreated == true then
		return
	end
	
	SellInterfaceModule.itemPriceValue = 100
	SellInterfaceModule.stackPriceValue = 100
	
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
	self:CreateItemToSellParameters(self.mainFrame)
	
	ResultsTableModule:CreateResultsScrollFrameTable(self.mainFrame, 270, -135)
	
	self.interfaceCreated = true
	
end

function SellInterfaceModule:AUCTION_HOUSE_CLOSED()
	
	self:HideSellInterface()
	self:ResetData()
	self:UnregisterAllEvents()
	self:UnregisterAllMessages()

end

function SellInterfaceModule:AUCTION_ITEM_LIST_UPDATE()
	
	self:SendMessage("UPDATE_NAVIGATION_PAGES", self.mainFrame)

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
	self.mainFrame:SetScript("OnShow", function() self:OnShowInterface() end)
	self.mainFrame:SetScript("OnHide", function() InterfaceFunctionsModule:CloseAuctionHouseCustom() end)
	self.mainFrame.CloseButton:SetScript("OnClick", function() CloseAuctionHouse() end)
	tinsert(UISpecialFrames, "AB_SellInterface_MainFrame")
	
	self.mainFrame.title = self.mainFrame:CreateFontString("AB_SellInterface_MainFrame_Title_Text", "OVERLAY", "GameFontNormal")
	self.mainFrame.title:SetPoint("CENTER", 0, 339)
	self.mainFrame.title:SetJustifyH("CENTER")
	self.mainFrame.title:SetText("AuctionBuddy SELL")
	
	self.mainFrame.itemFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.itemFrame, 285, 330, nil, "LEFT", 10, 66, "BACKGROUND")
	
	self.mainFrame.resultsTableFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ResultsFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.resultsTableFrame, 668, 570, nil, "CENTER", 277, -30, "BACKGROUND")
	
	self.mainFrame.containerFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ContainerFrame", self.mainFrame, "InsetFrameTemplate3")
	SellInterfaceModule:SetFrameParameters(self.mainFrame.containerFrame, 265, 570, nil, "CENTER", -193, -30, "BACKGROUND")
	
	self:HideSellInterface()
	
end

function SellInterfaceModule:CreateSellInterfaceButtons(parentFrame)
	
	parentFrame.DefaultAHButton = CreateFrame("Button", "AB_SellInterface_MainFrame_DefaultAH_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.DefaultAHButton, 80, 24, "Default AH", "TOPRIGHT", -25, -30)
	parentFrame.DefaultAHButton:SetScript("OnClick", function() 
		InterfaceFunctionsModule.switchingUI = true
		parentFrame:Hide()
		AuctionFrame_Show()
		InterfaceFunctionsModule.switchingUI = false
	end)
	
	parentFrame.BuyFrameButton = CreateFrame("Button", "AB_SellInterface_MainFrame_BuyFrame_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.BuyFrameButton, 80, 24, "Show Buy", "TOPRIGHT", -105, -30)
	parentFrame.BuyFrameButton:SetScript("OnClick", function()
		InterfaceFunctionsModule.switchingUI = true
		parentFrame:Hide()
		self:SendMessage("SHOW_AB_BUY_FRAME")
	end)

	parentFrame.nextPageButton = CreateFrame("Button", "AB_SellInterface_MainFrame_NextPage_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.nextPageButton, 80, 24, "Next Page", "TOPRIGHT", -25, -60)
	parentFrame.nextPageButton:SetScript("OnClick", function()
		if CanSendAuctionQuery() then
			self:SendMessage("ON_CLICK_NEXT_PAGE", parentFrame)
		end
		AuctionBuddy:AuctionHouseSearch() 
	end)
	
	parentFrame.prevPageButton = CreateFrame("Button", "AB_SellInterface_MainFrame_PrevPage_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.prevPageButton, 80, 24, "Prev Page", "TOPRIGHT", -105, -60)
	parentFrame.prevPageButton:SetScript("OnClick", function()
		if CanSendAuctionQuery() then
			self:SendMessage("ON_CLICK_PREV_PAGE", parentFrame)
		end
		AuctionBuddy:AuctionHouseSearch() 
	end)
	
	parentFrame.instaBuyCheckBox = CreateFrame("CheckButton", "AB_SellInterface_MainFrame_InstaBuyCheck", parentFrame, "ChatConfigBaseCheckButtonTemplate")
	parentFrame.instaBuyCheckBox:SetWidth(24)
	parentFrame.instaBuyCheckBox:SetHeight(24)
	parentFrame.instaBuyCheckBox:SetPoint("TOPLEFT", 50, -65)
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
	parentFrame.instaBuyCheckBox.text:SetText("Double Click to buy an item")

	parentFrame.itemToSellButton = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_Button", parentFrame)
	SellInterfaceModule:SetFrameParameters(parentFrame.itemToSellButton, 37, 37, nil, "TOPLEFT", 80, -140)
	parentFrame.itemToSellButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")	
	
	parentFrame.itemToSellButton:SetScript("OnClick", function() 
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
	parentFrame.uiScaleSlider:SetPoint("TOP", 250, -50)
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
	parentFrame.uiScaleSlider.text:SetPoint("TOP", 250, -35)
	parentFrame.uiScaleSlider.text:SetJustifyH("CENTER")
	parentFrame.uiScaleSlider.text:SetText("AB UI Scale")

	parentFrame.uiScaleSliderApplyButton = CreateFrame("Button", "AB_SellInterface_MainFrame_UISlider_ApplyButton", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.uiScaleSliderApplyButton, 60, 24, "Apply", "TOP", 370, -50)
	parentFrame.uiScaleSliderApplyButton:SetScript("OnClick", function() 
		DatabaseModule.generalOptions.uiScale = parentFrame.uiScaleSlider:GetValue()
		self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale) 
	end)
	
end

function SellInterfaceModule:CreateSellInterfaceOptions(parentFrame)

	parentFrame.alreadyBidText = parentFrame:CreateFontString("AB_SellInterface_MainFrame_AlreadyBid_Text", "OVERLAY")
	parentFrame.alreadyBidText:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.alreadyBidText:SetWidth(250)
	parentFrame.alreadyBidText:SetPoint("BOTTOMLEFT", 35, 220)
	parentFrame.alreadyBidText:SetJustifyH("LEFT")
	parentFrame.alreadyBidText:SetText("You already have a bid on this item.")
	parentFrame.alreadyBidText:Hide()

	parentFrame.totalBidCost = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBidCost", "OVERLAY")
	parentFrame.totalBidCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBidCost:SetWidth(250)
	parentFrame.totalBidCost:SetPoint("BOTTOMLEFT", 150, 192)
	parentFrame.totalBidCost:SetJustifyH("LEFT")
	parentFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBidCost:SetText(parentFrame.totalBidCost.value)

	parentFrame.totalBidCost.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBidCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBidCost.text:SetWidth(250)
	parentFrame.totalBidCost.text:SetPoint("BOTTOMLEFT", 35, 195)
	parentFrame.totalBidCost.text:SetJustifyH("LEFT")
	parentFrame.totalBidCost.text:SetText("Total Bid Cost:")

	parentFrame.totalBuyCost = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBuyCost", "OVERLAY")
	parentFrame.totalBuyCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBuyCost:SetWidth(250)
	parentFrame.totalBuyCost:SetPoint("BOTTOMLEFT", 150, 167)
	parentFrame.totalBuyCost:SetJustifyH("LEFT")
	parentFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBuyCost:SetText(parentFrame.totalBuyCost.value)

	parentFrame.totalBuyCost.text = parentFrame:CreateFontString("AB_SellInterface_MainFrame_TotalBuyCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBuyCost.text:SetWidth(250)
	parentFrame.totalBuyCost.text:SetPoint("BOTTOMLEFT", 35, 170)
	parentFrame.totalBuyCost.text:SetJustifyH("LEFT")
	parentFrame.totalBuyCost.text:SetText("Total Buyout Cost:")

	parentFrame.buySelectedItem = CreateFrame("Button", "AB_SellInterface_MainFrame_BuySelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.buySelectedItem, 125, 24, "Buy Selected Item", "LEFT", 160, -203)
	parentFrame.buySelectedItem:SetScript("OnClick", function() 
		self:SendMessage("ON_BUY_SELECTED_ITEM", parentFrame.scrollTable:GetSelection())
		SellInterfaceModule:DisableBuyBidButtons()
		parentFrame.scrollTable:ClearSelection()
	end)
	parentFrame.buySelectedItem:Disable()
	
	parentFrame.bidSelectedItem = CreateFrame("Button", "AB_SellInterface_MainFrame_BidSelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.bidSelectedItem, 125, 24, "Bid Selected Item", "LEFT", 20, -203)
	parentFrame.bidSelectedItem:SetScript("OnClick", function() 
		self:SendMessage("ON_BID_SELECTED_ITEM", parentFrame.scrollTable:GetSelection())
		self:DisableBuyBidButtons()
		parentFrame.alreadyBidText:Hide()
		parentFrame.scrollTable:ClearSelection() 
	end)
	parentFrame.bidSelectedItem:Disable()

	parentFrame.manageFavoriteLists = CreateFrame("Button", "AB_SellInterface_MainFrame_Options_Button", parentFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.manageFavoriteLists, 100, 24, "Options", "LEFT", 100, -250)
	parentFrame.manageFavoriteLists:SetScript("OnClick", function() 
		parentFrame:Hide()
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.sellParameters)
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.sellParameters)
	end)

end

function SellInterfaceModule:CreateItemToSellParameters(parentFrame)

	parentFrame.itemPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_ItemPrice", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.itemPrice, nil, nil, nil, "CENTER", 100, -70, nil, parentFrame.itemToSellButton)
	parentFrame.itemPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.itemPrice, self.itemPriceValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.itemPrice, function() 
			InterfaceFunctionsModule:ItemPriceUpdated(parentFrame) 
		end) 
	end)
	
	parentFrame.itemPrice.text = parentFrame.itemPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_ItemPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.itemPrice.text:SetJustifyH("CENTER")
	parentFrame.itemPrice.text:SetText("Item Price")
	
	parentFrame.stackPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_StackPrice", parentFrame, "MoneyInputFrameTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackPrice, nil, nil, nil, "CENTER", 100, -95, nil, parentFrame.itemToSellButton)
	parentFrame.stackPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper(parentFrame.stackPrice, self.stackPriceValue) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.stackPrice, function() 
			InterfaceFunctionsModule:StackPriceUpdated(parentFrame) 
		end) 
	end)
	
	parentFrame.stackPrice.text = parentFrame.stackPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.stackPrice.text:SetJustifyH("CENTER")
	parentFrame.stackPrice.text:SetText("Stack Price")

	parentFrame.stackSize = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackSize", parentFrame, "InputBoxTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackSize, 40, 40, nil, "CENTER", 50, -125, nil, parentFrame.itemToSellButton)
	parentFrame.stackSize:SetAutoFocus(false)
	parentFrame.stackSize:SetJustifyH("CENTER")
	parentFrame.stackSize:SetText("1")
	parentFrame.stackSize:SetScript("OnTextChanged", function()
		self:SendMessage("ON_STACK_SIZE_TEXT_CHANGED", parentFrame)
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
	SellInterfaceModule:SetFrameParameters(parentFrame.stackSize.maxStackBtn, 50, 24, "Max.", "CENTER", 160, -125, "HIGH", parentFrame.itemToSellButton)
	parentFrame.stackSize.maxStackBtn:SetScript("OnClick", function() 
		self:SendMessage("ON_CLICK_MAX_STACK_SIZE", parentFrame)
	end)
	parentFrame.stackSize.maxStackBtn:Disable()
	
	parentFrame.stackNumber = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackNumber", parentFrame, "InputBoxTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackNumber, 40, 40, nil, "CENTER", 50, -150, nil, parentFrame.itemToSellButton)
	parentFrame.stackNumber:SetAutoFocus(false)
	parentFrame.stackNumber:SetJustifyH("CENTER")
	parentFrame.stackNumber:SetText("1")
	parentFrame.stackNumber:SetScript("OnTextChanged", function() 
		self:SendMessage("UPDATE_DEPOSIT_COST", parentFrame)
	end)
	parentFrame.stackNumber:SetScript("OnEscapePressed", function() 
		parentFrame.stackNumber:ClearFocus() 
	end)
	
	parentFrame.stackNumber.textLeft = parentFrame.stackNumber:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackQuantity_TextLeft", "OVERLAY", "GameFontNormal")
	parentFrame.stackNumber.textLeft:SetPoint("CENTER", -80, 0)
	parentFrame.stackNumber.textLeft:SetJustifyH("CENTER")
	parentFrame.stackNumber.textLeft:SetText("Stack Quantity")

	parentFrame.stackNumber.textRight = parentFrame.stackNumber:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackQuantity_Text", "OVERLAY")
	parentFrame.stackNumber.textRight:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackNumber.textRight:SetPoint("CENTER", 35, 0)
	parentFrame.stackNumber.textRight:SetJustifyH("CENTER")
	parentFrame.stackNumber.textRight:SetText("of")

	parentFrame.stackNumber.maxStackValue = parentFrame.stackNumber:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_MaxStackQuantity_Text", "OVERLAY")
	parentFrame.stackNumber.maxStackValue:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.stackNumber.maxStackValue:SetPoint("CENTER", 65, 0)
	parentFrame.stackNumber.maxStackValue:SetJustifyH("CENTER")
	parentFrame.stackNumber.maxStackValue:SetText("1")

	parentFrame.stackNumber.maxStackBtn = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_MaxStackQuantity_Btn", parentFrame.stackNumber, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.stackNumber.maxStackBtn, 50, 24, "Max.", "CENTER", 160, -150, "HIGH", parentFrame.itemToSellButton)
	parentFrame.stackNumber.maxStackBtn:SetScript("OnClick", function() 
		self:SendMessage("ON_CLICK_MAX_STACK_QUANTITY", parentFrame)
	end)
	parentFrame.stackNumber.maxStackBtn:Disable()
	
	parentFrame.auctionDuration = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_AuctionDuration", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.auctionDuration:SetPoint("CENTER", parentFrame.itemToSellButton, "CENTER", 85, -220)
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
	parentFrame.auctionDepositText:SetPoint("LEFT", 60, -58)
	parentFrame.auctionDepositText:SetJustifyH("CENTER")
	parentFrame.auctionDepositText:SetText("Deposit:")
	
	parentFrame.auctionDepositCost = parentFrame.itemFrame:CreateFontString("AB_SellInterface_MainFrame_AuctionDeposit_Cost", "OVERLAY")
	parentFrame.auctionDepositCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.auctionDepositCost:SetPoint("LEFT", 120, -58)
	parentFrame.auctionDepositCost.value = GetCoinTextureString(0, 15)
	parentFrame.auctionDepositCost:SetText(parentFrame.auctionDepositCost.value)
	
	parentFrame.createAuction = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_CreateAuction", parentFrame.itemFrame, "UIPanelButtonTemplate")
	SellInterfaceModule:SetFrameParameters(parentFrame.createAuction, 160, 24, "Create Auction(s)", "CENTER", 60, -260, "HIGH", parentFrame.itemToSellButton)
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

function SellInterfaceModule:OnShowInterface()

	self.mainFrame:ClearAllPoints()
	self.mainFrame:SetPoint(DatabaseModule.generalOptions.point, DatabaseModule.generalOptions.xPosOffset, DatabaseModule.generalOptions.yPosOffset)
	self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale)
	self.mainFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	self.mainFrame.totalBuyCost:SetText(self.mainFrame.totalBuyCost.value)
	self.mainFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	self.mainFrame.totalBidCost:SetText(self.mainFrame.totalBuyCost.value)
	self.mainFrame.scrollTable:ClearSelection()
	ContainerModule:ScanContainer()

end

function SellInterfaceModule:OnResultsTableItemSelected()
	DebugModule:Log("Sell_OnResultsTableItemSelected", "OnResultsTableItemSelected", 3)

	SellInterfaceModule:EnableBuyBidButtons()

end

function SellInterfaceModule:OnShowSellFrame()
	DebugModule:Log("SellInterfaceModule", "OnShowSellFrame", 3)

	SellInterfaceModule.mainFrame:Show()
	SellInterfaceModule:DisableBuyBidButtons()
	InterfaceFunctionsModule.switchingUI = false

end

function SellInterfaceModule:EnableBuyBidButtons()

	SellInterfaceModule.mainFrame.buySelectedItem:Enable()
	SellInterfaceModule.mainFrame.bidSelectedItem:Enable()

end

function SellInterfaceModule:DisableBuyBidButtons()

	SellInterfaceModule.mainFrame.buySelectedItem:Disable()
	SellInterfaceModule.mainFrame.bidSelectedItem:Disable()

end

function SellInterfaceModule:ResetData()

	self.itemPriceValue = 100
	self.stackPriceValue = 100
	self.mainFrame.stackSize:SetText("1")
	self.mainFrame.stackNumber:SetText("1")
	self.mainFrame.scrollTable:SetData({}, true)
	self.mainFrame.itemToSellButton.itemTexture:SetTexture(nil)
	self.mainFrame.itemToSellButton.text:SetText("<-- [Insert Item]")
	self.mainFrame.alreadyBidText:Hide()
	self.mainFrame.stackSize.maxStackValue:SetText("1")
	self.mainFrame.stackNumber.maxStackValue:SetText("1")
	self.mainFrame.stackSize.maxStackBtn:Disable()
	self.mainFrame.stackNumber.maxStackBtn:Disable()

	if SellInterfaceModule.mainFrame ~= nil then
		SellInterfaceModule.mainFrame.scrollTable:SetData({}, true)
	end

end

function SellInterfaceModule:HideSellInterface()

	if SellInterfaceModule.mainFrame ~= nil then
		SellInterfaceModule.mainFrame:Hide()
	end

end