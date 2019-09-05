-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local SellInterfaceModule = AuctionBuddy:NewModule("SellInterfaceModule", "AceEvent-3.0")

local InterfaceFunctionsModule = nil
local ResultsTableModule = nil
local NavigationModule = nil
local BuyInterfaceModule = nil
local ItemsModule = nil
local ContainerModule = nil

SellInterfaceModule.itemPriceValue = nil
SellInterfaceModule.stackPriceValue = nil

function SellInterfaceModule:Enable()

	if self.interfaceCreated == true then
		return
	end
	
	SellInterfaceModule.itemPriceValue = 100
	SellInterfaceModule.stackPriceValue = 100
	
	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	ResultsTableModule = AuctionBuddy:GetModule("ResultsTableModule")
	NavigationModule = AuctionBuddy:GetModule("NavigationModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	ContainerModule = AuctionBuddy:GetModule("ContainerModule")
	
	self:CreateSellInterface()	
	self:CreateSellInterfaceButtons(self.mainFrame)
	self:CreateSellTab(self.mainFrame)
	self:CreateItemToSellParameters(self.mainFrame)
	
	ResultsTableModule:CreateResultsScrollFrameTable(self.mainFrame, 270, -135)
	
	self.interfaceCreated = true
	
end

function SellInterfaceModule:OnInitialize()

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	
end

function SellInterfaceModule:AUCTION_HOUSE_CLOSED()
	
	self:ResetData()

end

function SellInterfaceModule:CreateSellInterface()
	
	self.mainFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame", UIParent, "BasicFrameTemplate")
	self.mainFrame:SetMovable(true)
	self.mainFrame:EnableMouse(true)
	self.mainFrame:RegisterForDrag("LeftButton")
	InterfaceFunctionsModule:SetFrameParameters(self.mainFrame, 1250, 700, _, "CENTER")
	self.mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.mainFrame:SetScript("OnDragStart",  function() self.mainFrame:StartMoving() end)
	self.mainFrame:SetScript("OnDragStop", function() self.mainFrame:StopMovingOrSizing() end)
	self.mainFrame:SetScript("OnHide", function() InterfaceFunctionsModule:CloseAuctionHouseCustom() end)
	self.mainFrame.CloseButton:SetScript("OnClick", function() CloseAuctionHouse() end)
	tinsert(UISpecialFrames, "AB_SellInterface_MainFrame")
	
	self.mainFrame.title = self.mainFrame:CreateFontString("AB_SellInterface_MainFrame_Title_Text", "OVERLAY", "GameFontNormal")
	self.mainFrame.title:SetPoint("CENTER", 0, 339)
	self.mainFrame.title:SetJustifyH("CENTER")
	self.mainFrame.title:SetText("AuctionBuddy SELL")
	
	self.mainFrame.itemFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemFrame", self.mainFrame, "InsetFrameTemplate3")
	InterfaceFunctionsModule:SetFrameParameters(self.mainFrame.itemFrame, 285, 330, _, "LEFT", 10, 66, "BACKGROUND")
	
	self.mainFrame.resultsTableFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ResultsFrame", self.mainFrame, "InsetFrameTemplate3")
	InterfaceFunctionsModule:SetFrameParameters(self.mainFrame.resultsTableFrame, 668, 570, _, "CENTER", 277, -30, "BACKGROUND")
	
	self.mainFrame.containerFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ContainerFrame", self.mainFrame, "InsetFrameTemplate3")
	InterfaceFunctionsModule:SetFrameParameters(self.mainFrame.containerFrame, 265, 570, _, "CENTER", -193, -30, "BACKGROUND")
	
	self:HideSellInterface()
	
end

function SellInterfaceModule:CreateSellInterfaceButtons(parentFrame)
	
	parentFrame.DefaultAHButton = CreateFrame("Button", "AB_SellInterface_MainFrame_DefaultAH_Button", parentFrame, "UIPanelButtonTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.DefaultAHButton, 80, 24, "Default AH", "TOPRIGHT", -25, -30)
	parentFrame.DefaultAHButton:SetScript("OnClick", function() InterfaceFunctionsModule:ShowDefaultAH(parentFrame) AuctionFrame_Show() end)
	
	parentFrame.BuyFrameButton = CreateFrame("Button", "AB_SellInterface_MainFrame_BuyFrame_Button", parentFrame, "UIPanelButtonTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.BuyFrameButton, 80, 24, "Show Buy", "TOPRIGHT", -105, -30)
	parentFrame.BuyFrameButton:SetScript("OnClick", function() 
		BuyInterfaceModule.mainFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
		BuyInterfaceModule.mainFrame.currentPlayerGold:SetText(BuyInterfaceModule.mainFrame.currentPlayerGold.value)
		NavigationModule:CheckSearchActive(BuyInterfaceModule.mainFrame) 
		InterfaceFunctionsModule:ChangeCurrentDisplayingFrame(parentFrame) 
	end)

	parentFrame.nextPageButton = CreateFrame("Button", "AB_SellInterface_MainFrame_NextPage_Button", parentFrame, "UIPanelButtonTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.nextPageButton, 80, 24, "Next Page", "TOPRIGHT", -25, -60)
	parentFrame.nextPageButton:SetScript("OnClick", function() NavigationModule:MovePage(true, parentFrame) AuctionBuddy:AuctionHouseSearch() end)
	
	parentFrame.prevPageButton = CreateFrame("Button", "AB_SellInterface_MainFrame_PrevPage_Button", parentFrame, "UIPanelButtonTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.prevPageButton, 80, 24, "Prev Page", "TOPRIGHT", -105, -60)
	parentFrame.prevPageButton:SetScript("OnClick", function() NavigationModule:MovePage(false, parentFrame) AuctionBuddy:AuctionHouseSearch() end)
	
	parentFrame.itemToSellButton = CreateFrame("Button", "AB_SellInterface_MainFrame_ItemToSell_Button", parentFrame)
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.itemToSellButton, 37, 37, nil, "TOPLEFT", 80, -140)
	parentFrame.itemToSellButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")	
	
	parentFrame.itemToSellButton:SetScript("OnClick", function() 
		if ItemsModule.itemInserted == true then
			PickupItem(ItemsModule.currentItemPostedLink) 
			ItemsModule:RemoveInsertedItem(self.mainFrame)
		end
	end)
	parentFrame.itemToSellButton:SetScript("OnLoad", function() 
		self.mainFrame.itemToSellButton:RegisterForDrag( "LeftButton" ) 
	end)
	parentFrame.itemToSellButton:SetScript("OnReceiveDrag", function() 
		local infoType, info1, info2 = GetCursorInfo()
		local bindType = select(14, GetItemInfo(info2))
		if bindType ~= 1 then
			ItemsModule:InsertSelectedItem(self.mainFrame)
		else
			print("AuctionBuddy: Can't auction Soulbound items")
		end
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
	
end

function SellInterfaceModule:CreateItemToSellParameters(parentFrame)

	parentFrame.itemPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_ItemPrice", parentFrame, "MoneyInputFrameTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.itemPrice, nil, nil, nil, "CENTER", 100, -70, nil, parentFrame.itemToSellButton)
	parentFrame.itemPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper( parentFrame.itemPrice, self.itemPriceValue ) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.itemPrice, function() InterfaceFunctionsModule:ItemPriceUpdated(parentFrame) end) 
	end)
	
	parentFrame.itemPrice.text = parentFrame.itemPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_ItemPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.itemPrice.text:SetJustifyH("CENTER")
	parentFrame.itemPrice.text:SetText("Item Price")
	
	parentFrame.stackPrice = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_StackPrice", parentFrame, "MoneyInputFrameTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.stackPrice, nil, nil, nil, "CENTER", 100, -95, nil, parentFrame.itemToSellButton)
	parentFrame.stackPrice:SetScript("OnShow", function() 
		MoneyInputFrame_SetCopper( parentFrame.stackPrice, self.stackPriceValue ) 
		MoneyInputFrame_SetOnValueChangedFunc(parentFrame.stackPrice, function() InterfaceFunctionsModule:StackPriceUpdated(parentFrame) end) 
	end)
	
	parentFrame.stackPrice.text = parentFrame.stackPrice:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackPrice_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackPrice.text:SetPoint("CENTER", -140, 0)
	parentFrame.stackPrice.text:SetJustifyH("CENTER")
	parentFrame.stackPrice.text:SetText("Stack Price")
	
	parentFrame.stackNumber = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackNumber", parentFrame, "InputBoxTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.stackNumber, 40, 40, nil, "CENTER", 100, -125, nil, parentFrame.itemToSellButton)
	parentFrame.stackNumber:SetAutoFocus(false)
	parentFrame.stackNumber:SetJustifyH("CENTER")
	parentFrame.stackNumber:SetText("1")
	parentFrame.stackNumber:SetScript("OnTextChanged", function() InterfaceFunctionsModule:StackPriceUpdated(parentFrame) end)
	parentFrame.stackNumber:SetScript("OnEscapePressed", function() parentFrame.stackNumber:ClearFocus() end)
	
	parentFrame.stackNumber.text = parentFrame.stackNumber:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackQuantity_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackNumber.text:SetPoint("CENTER", -100, 0)
	parentFrame.stackNumber.text:SetJustifyH("CENTER")
	parentFrame.stackNumber.text:SetText("Stack Quantity")
	
	parentFrame.stackSize = CreateFrame("EditBox", "AB_SellInterface_MainFrame_ItemToSell_StackSize", parentFrame, "InputBoxTemplate")
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.stackSize, 40, 40, nil, "CENTER", 100, -150, nil, parentFrame.itemToSellButton)
	parentFrame.stackSize:SetAutoFocus(false)
	parentFrame.stackSize:SetJustifyH("CENTER")
	parentFrame.stackSize:SetText("1")
	parentFrame.stackSize:SetScript("OnTextChanged", function() InterfaceFunctionsModule:StackPriceUpdated(parentFrame) end)
	parentFrame.stackSize:SetScript("OnEscapePressed", function() parentFrame.stackSize:ClearFocus() end)
	
	parentFrame.stackSize.text = parentFrame.stackSize:CreateFontString("AB_SellInterface_MainFrame_ItemToSell_StackSize_Text", "OVERLAY", "GameFontNormal")
	parentFrame.stackSize.text:SetPoint("CENTER", -100, 0)
	parentFrame.stackSize.text:SetJustifyH("CENTER")
	parentFrame.stackSize.text:SetText("Stack Size")
	
	parentFrame.auctionDuration = CreateFrame("Frame", "AB_SellInterface_MainFrame_ItemToSell_AuctionDuration", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.auctionDuration:SetPoint("CENTER", parentFrame.itemToSellButton, "CENTER", 85, -220)
	parentFrame.auctionDuration.durationValue = 2
	parentFrame.auctionDuration.durationText = "24 Hours"
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
	InterfaceFunctionsModule:SetFrameParameters(parentFrame.createAuction, 160, 24, "Create Auction(s)", "CENTER", 60, -260, "HIGH", parentFrame.itemToSellButton)
	parentFrame.createAuction:SetScript("OnClick", function() 
		ItemsModule:SellSelectedItem(parentFrame) 
		SellInterfaceModule:ResetData()
	end)
	parentFrame.createAuction:SetScript("OnUpdate", function() ItemsModule:ItemInsertedOrSelected(parentFrame.createAuction, ItemsModule.itemInserted) end)
	
end

local function SelectAuctionDuration(self, arg1, checked, value)
	
	SellInterfaceModule.mainFrame.auctionDuration.durationValue = arg1

	if arg1 == 1 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "12 Hours"
		
	elseif arg1 == 2 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "24 Hours"
		
	elseif arg1 == 3 then
		SellInterfaceModule.mainFrame.auctionDuration.durationText = "48 Hours"
	end
	
	UIDropDownMenu_SetText(SellInterfaceModule.mainFrame.auctionDuration, SellInterfaceModule.mainFrame.auctionDuration.durationText) 
end

function SellInterfaceModule:AuctionDurationDropDown(frame, level, menuList)

	local info = UIDropDownMenu_CreateInfo()
	info.func = SelectAuctionDuration
	
	info.text = "12 Hours"
	info.arg1 = 1
	info.checked = SellInterfaceModule.mainFrame.auctionDuration.durationValue == 1
	UIDropDownMenu_AddButton(info)
	
	info.text = "24 Hours"
	info.arg1 = 2
	info.checked = SellInterfaceModule.mainFrame.auctionDuration.durationValue == 2
	UIDropDownMenu_AddButton(info)
	
	info.text = "48 Hours"
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

function SellInterfaceModule:ResetData()

	self.itemPriceValue = 100
	self.stackPriceValue = 100
	self.mainFrame.stackSize:SetText("1")
	self.mainFrame.stackNumber:SetText("1")
	self.mainFrame.scrollTable:SetData({}, true)
	self.mainFrame.itemToSellButton.text:SetText("<-- [Insert Item]")
	self.mainFrame.itemToSellButton.itemTexture:SetTexture(nil)
	
	if ItemsModule.itemInserted == true then
		PickupItem(ItemsModule.currentItemPostedLink) 
		ItemsModule:RemoveInsertedItem(self.mainFrame)
	end

end

function SellInterfaceModule:HideSellInterface()

	if self.mainFrame ~= nil then
		self.mainFrame:Hide()
	end

end