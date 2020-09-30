-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local BuyInterfaceModule = AuctionBuddy:NewModule("BuyInterfaceModule", "AceEvent-3.0")

local InterfaceFunctionsModule = nil
local ResultsTableModule = nil
local NavigationModule = nil
local SellInterfaceModule = nil
local ContainerModule = nil

local DatabaseModule = nil
local SearchesModule = nil
local ItemsModule = nil
local OptionsPanelModule = nil

function BuyInterfaceModule:Enable()

	if self.interfaceCreated == true then
		return
	end

	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	ResultsTableModule = AuctionBuddy:GetModule("ResultsTableModule")
	NavigationModule = AuctionBuddy:GetModule("NavigationModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ContainerModule = AuctionBuddy:GetModule("ContainerModule")
	OptionsPanelModule = AuctionBuddy:GetModule("OptionsPanelModule")
	
	self:CreateBuyInterface()	
	self:CreateBuyTab(self.mainFrame)
	self:CreateBuyInterfaceButtons(self.mainFrame)
	self:CreateBuyInterfaceBuyOptions(self.mainFrame)
	self:CreateBuyInterfaceSearchTablesOptions(self.mainFrame)
	self:CreateSearchFilters(self.mainFrame)
	
	ResultsTableModule:CreateResultsScrollFrameTable(self.mainFrame, -280, -135)

	self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale)
	
	self.interfaceCreated = true
	
end

function BuyInterfaceModule:OnInitialize()

	SearchesModule = AuctionBuddy:GetModule("SearchesModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
end

function BuyInterfaceModule:AUCTION_HOUSE_CLOSED()

	self:ResetData()

end

function BuyInterfaceModule:CreateBuyInterface()
	
	self.mainFrame = CreateFrame("Frame", "AB_BuyInterface_MainFrame", UIParent, "BasicFrameTemplate")
	self.mainFrame:SetMovable(true)
	self.mainFrame:EnableMouse(true)
	self.mainFrame:RegisterForDrag("LeftButton")
	self.mainFrame:SetClampedToScreen(true)
	BuyInterfaceModule:SetFrameParameters(self.mainFrame, 1250, 700, nil, DatabaseModule.generalOptions.point, DatabaseModule.generalOptions.xPosOffset, DatabaseModule.generalOptions.yPosOffset)
	self.mainFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	self.mainFrame:SetScript("OnDragStart",  function() self.mainFrame:StartMoving() end)
	self.mainFrame:SetScript("OnDragStop", 
		function() self.mainFrame:StopMovingOrSizing() 
		local point, _, _, xPos, yPos = self.mainFrame:GetPoint()
		DatabaseModule.generalOptions.point = point
		DatabaseModule.generalOptions.xPosOffset = xPos
		DatabaseModule.generalOptions.yPosOffset = yPos
	end)
	self.mainFrame:SetScript("OnShow", function() self:OnShowInterface() end)
	self.mainFrame:SetScript("OnHide", function() InterfaceFunctionsModule:CloseAuctionHouseCustom() end)
	self.mainFrame.CloseButton:SetScript("OnClick", function() CloseAuctionHouse() end)
	tinsert(UISpecialFrames, "AB_BuyInterface_MainFrame")
	
	self.mainFrame.title = self.mainFrame:CreateFontString("AB_BuyInterface_MainFrame_Title_Text", "OVERLAY", "GameFontNormal")
	self.mainFrame.title:SetPoint("CENTER", 0, 339)
	self.mainFrame.title:SetJustifyH("CENTER")
	self.mainFrame.title:SetText("AuctionBuddy BUY")

	self.mainFrame.resultsTableFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ResultsFrame", self.mainFrame, "InsetFrameTemplate3")
	BuyInterfaceModule:SetFrameParameters(self.mainFrame.resultsTableFrame, 668, 570, nil, "CENTER", -277, -30, "BACKGROUND")
	
	self.mainFrame.containerFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_ContainerFrame", self.mainFrame, "InsetFrameTemplate3")
	BuyInterfaceModule:SetFrameParameters(self.mainFrame.containerFrame, 170, 570, nil, "CENTER", 150, -30, "BACKGROUND")
	
	self.mainFrame.recentSearchesFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_RecentSearchesFrame", self.mainFrame, "InsetFrameTemplate3")
	BuyInterfaceModule:SetFrameParameters(self.mainFrame.recentSearchesFrame, 320, 170, nil, "CENTER", 400, 170, "BACKGROUND")
	
	self.mainFrame.favoriteSearchesFrame = CreateFrame("Frame", "AB_SellInterface_MainFrame_FavoriteSearchesFrame", self.mainFrame, "InsetFrameTemplate3")
	BuyInterfaceModule:SetFrameParameters(self.mainFrame.favoriteSearchesFrame, 320, 170, nil, "CENTER", 400, -110, "BACKGROUND")
	
	self:HideBuyInterface()
	
end

function BuyInterfaceModule:CreateBuyInterfaceButtons(parentFrame)

	parentFrame.searchBar = CreateFrame("EditBox", "AB_BuyInterface_MainFrame_SearchBar", parentFrame, "InputBoxTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.searchBar, 200, 20, nil, "TOPLEFT", 25, -40)
	parentFrame.searchBar:SetAutoFocus(false)
	parentFrame.searchBar:SetJustifyH("LEFT")
	parentFrame.searchBar:SetScript("OnShow", function() parentFrame.searchBar:SetFocus() end)
	parentFrame.searchBar:SetScript("OnChar", function() 
		if parentFrame.searchBar:GetText() ~= "" then
			InterfaceFunctionsModule.autoCompleteTextPos = strlen(parentFrame.searchBar:GetText())
			InterfaceFunctionsModule:AutoCompleteText(parentFrame.searchBar, parentFrame.searchBar:GetText())
		end
	end)
	parentFrame.searchBar:SetScript("OnKeyDown", function(self, arg1)
		if arg1 == "BACKSPACE" and InterfaceFunctionsModule.autoCompleteTextPos > 1 and 
		strlen(parentFrame.searchBar:GetText()) == InterfaceFunctionsModule.autoCompleteTextPos - 1 then
			InterfaceFunctionsModule.autoCompleteTextPos = InterfaceFunctionsModule.autoCompleteTextPos - 1
		end
	end)
	parentFrame.searchBar:SetScript("OnEscapePressed", function() parentFrame.searchBar:ClearFocus() end)
	parentFrame.searchBar:SetScript("OnEnterPressed", function() AuctionBuddy:AuctionHouseSearch(parentFrame.searchBar:GetText()) end)
	
	parentFrame.searchButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_Search_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.searchButton, 80, 24, "Search", "TOPLEFT", 235, -38)
	parentFrame.searchButton:SetScript("OnClick", function() 
		AuctionBuddy:AuctionHouseSearch(parentFrame.searchBar:GetText()) 
		InterfaceFunctionsModule.autoCompleteTextPos = strlen(parentFrame.searchBar:GetText())
	end)

	parentFrame.exactMatch = CreateFrame("CheckButton", "AB_BuyInterface_MainFrame_ExactMatchCheck", parentFrame, "ChatConfigBaseCheckButtonTemplate")
	parentFrame.exactMatch:SetWidth(24)
	parentFrame.exactMatch:SetHeight(24)
	parentFrame.exactMatch:SetPoint("TOPLEFT", 20, -65)
	if DatabaseModule.buyOptions.exactMatch == true then
		parentFrame.exactMatch:SetChecked(true)
	end
	parentFrame.exactMatch:SetScript("OnClick", function() DatabaseModule.buyOptions.exactMatch = not DatabaseModule.buyOptions.exactMatch end)

	parentFrame.exactMatch.text = parentFrame.exactMatch:CreateFontString("AB_BuyInterface_MainFrame_ExactMatchCheck_Text", "OVERLAY", "GameFontNormal")
	parentFrame.exactMatch.text:SetWidth(80)
	parentFrame.exactMatch.text:SetPoint("CENTER", 50, 0)
	parentFrame.exactMatch.text:SetJustifyH("LEFT")
	parentFrame.exactMatch.text:SetText("Exact match")

	parentFrame.instaBuyCheckBox = CreateFrame("CheckButton", "AB_BuyInterface_MainFrame_InstaBuyCheck", parentFrame, "ChatConfigBaseCheckButtonTemplate")
	parentFrame.instaBuyCheckBox:SetWidth(24)
	parentFrame.instaBuyCheckBox:SetHeight(24)
	parentFrame.instaBuyCheckBox:SetPoint("TOPLEFT", 130, -65)
	if DatabaseModule.buyOptions.doubleClickToBuy == true then
		parentFrame.instaBuyCheckBox:SetChecked(true)
	end
	parentFrame.instaBuyCheckBox:SetScript("OnClick", function() DatabaseModule.buyOptions.doubleClickToBuy = not DatabaseModule.buyOptions.doubleClickToBuy end)

	parentFrame.instaBuyCheckBox.text = parentFrame.instaBuyCheckBox:CreateFontString("AB_BuyInterface_MainFrame_InstaBuyCheck_Text", "OVERLAY", "GameFontNormal")
	parentFrame.instaBuyCheckBox.text:SetWidth(250)
	parentFrame.instaBuyCheckBox.text:SetPoint("CENTER", 140, 0)
	parentFrame.instaBuyCheckBox.text:SetJustifyH("LEFT")
	parentFrame.instaBuyCheckBox.text:SetText("Double Click to buy an item")
	
	parentFrame.DefaultAHButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_DefaultAH_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.DefaultAHButton, 80, 24, "Default AH", "TOPRIGHT", -25, -30)
	parentFrame.DefaultAHButton:SetScript("OnClick", function() 
		self:ResetData()
		InterfaceFunctionsModule:ShowDefaultAH(parentFrame) 
		AuctionFrame_Show() 
	end)
	
	parentFrame.BuyFrameButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_BuyFrame_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.BuyFrameButton, 80, 24, "Show Sell", "TOPRIGHT", -105, -30)
	parentFrame.BuyFrameButton:SetScript("OnClick", function() 
		self:ResetData()
		InterfaceFunctionsModule:ChangeCurrentDisplayingFrame(parentFrame) 
	end)
	
	parentFrame.nextPageButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_NextPage_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.nextPageButton, 80, 24, "Next Page", "TOPRIGHT", -25, -60)
	parentFrame.nextPageButton:SetScript("OnClick", function()
		if CanSendAuctionQuery() then
			NavigationModule:MovePage(true, parentFrame)
		end
		AuctionBuddy:AuctionHouseSearch()
	end)
	
	parentFrame.prevPageButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_PrevPage_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.prevPageButton, 80, 24, "Prev Page", "TOPRIGHT", -105, -60)
	parentFrame.prevPageButton:SetScript("OnClick", function()
		if CanSendAuctionQuery() then
			NavigationModule:MovePage(false, parentFrame)
		end
		AuctionBuddy:AuctionHouseSearch() 
	end)
	
end

function BuyInterfaceModule:CreateBuyInterfaceBuyOptions(parentFrame)
	
	parentFrame.totalBidCost = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_TotalBidCost", "OVERLAY")
	parentFrame.totalBidCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBidCost:SetWidth(250)
	parentFrame.totalBidCost:SetPoint("BOTTOMRIGHT", 20, 92)
	parentFrame.totalBidCost:SetJustifyH("LEFT")
	parentFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBidCost:SetText(parentFrame.totalBidCost.value)

	parentFrame.totalBidCost.text = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_TotalBidCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBidCost.text:SetWidth(250)
	parentFrame.totalBidCost.text:SetPoint("BOTTOMRIGHT", -95, 95)
	parentFrame.totalBidCost.text:SetJustifyH("LEFT")
	parentFrame.totalBidCost.text:SetText("Total Bid Cost:")

	parentFrame.totalBuyCost = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_TotalBuyCost", "OVERLAY")
	parentFrame.totalBuyCost:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.totalBuyCost:SetWidth(250)
	parentFrame.totalBuyCost:SetPoint("BOTTOMRIGHT", 20, 67)
	parentFrame.totalBuyCost:SetJustifyH("LEFT")
	parentFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	parentFrame.totalBuyCost:SetText(parentFrame.totalBuyCost.value)

	parentFrame.totalBuyCost.text = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_TotalBuyCost_Text", "OVERLAY", "GameFontNormal")
	parentFrame.totalBuyCost.text:SetWidth(250)
	parentFrame.totalBuyCost.text:SetPoint("BOTTOMRIGHT", -95, 70)
	parentFrame.totalBuyCost.text:SetJustifyH("LEFT")
	parentFrame.totalBuyCost.text:SetText("Total Buyout Cost:")

	parentFrame.buySelectedItem = CreateFrame("Button", "AB_BuyInterface_MainFrame_BuySelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.buySelectedItem, 125, 24, "Buy Selected Item", "RIGHT", -90, -303)
	parentFrame.buySelectedItem:SetScript("OnClick", function() ItemsModule:BuySelectedItem(parentFrame.scrollTable:GetSelection(), false) parentFrame.scrollTable:ClearSelection() end)
	parentFrame.buySelectedItem:SetScript("OnUpdate", function() ItemsModule:ItemInsertedOrSelected(parentFrame.buySelectedItem, ItemsModule.itemSelected) end)
	parentFrame.buySelectedItem:Disable()
	
	parentFrame.bidSelectedItem = CreateFrame("Button", "AB_BuyInterface_MainFrame_BidSelectedItem_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.bidSelectedItem, 125, 24, "Bid Selected Item", "RIGHT", -230, -303)
	parentFrame.bidSelectedItem:SetScript("OnClick", function() ItemsModule:BuySelectedItem(parentFrame.scrollTable:GetSelection(), true) parentFrame.scrollTable:ClearSelection() end)
	parentFrame.bidSelectedItem:SetScript("OnUpdate", function() ItemsModule:ItemInsertedOrSelected(parentFrame.bidSelectedItem, ItemsModule.itemSelected) end)
	parentFrame.bidSelectedItem:Disable()
	
	parentFrame.currentPlayerGold = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_CurrentGold", "OVERLAY")
	parentFrame.currentPlayerGold:SetFont("Fonts\\ARIALN.ttf", 15, "OUTLINE")
	parentFrame.currentPlayerGold:SetWidth(250)
	parentFrame.currentPlayerGold:SetPoint("BOTTOMLEFT", 20, 12)
	parentFrame.currentPlayerGold:SetJustifyH("LEFT")
	parentFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
	parentFrame.currentPlayerGold:SetText(parentFrame.currentPlayerGold.value)

	parentFrame.uiScaleSlider = CreateFrame("Slider", "AB_BuyInterface_MainFrame_UISlider", parentFrame, "OptionsSliderTemplate")
	parentFrame.uiScaleSlider:SetPoint("TOP", 250, -50)
	parentFrame.uiScaleSlider:SetWidth(150)
	parentFrame.uiScaleSlider:SetHeight(20)
	parentFrame.uiScaleSlider:SetOrientation("HORIZONTAL")
	parentFrame.uiScaleSlider:SetMinMaxValues(0.5, 1.0)
	parentFrame.uiScaleSlider:SetValueStep(0.1)
	parentFrame.uiScaleSlider:SetValue(DatabaseModule.generalOptions.uiScale)
	parentFrame.uiScaleSlider:SetObeyStepOnDrag(true)
	parentFrame.uiScaleSlider:SetScript("OnShow", function() parentFrame.uiScaleSlider:SetValue(DatabaseModule.generalOptions.uiScale) end)

	parentFrame.uiScaleSlider.text = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_UISlider_Text", "OVERLAY", "GameFontNormal")
	parentFrame.uiScaleSlider.text:SetWidth(250)
	parentFrame.uiScaleSlider.text:SetPoint("TOP", 250, -35)
	parentFrame.uiScaleSlider.text:SetJustifyH("CENTER")
	parentFrame.uiScaleSlider.text:SetText("AB UI Scale")

	parentFrame.uiScaleSliderApplyButton = CreateFrame("Button", "AB_BuyInterface_MainFrame_UISlider_ApplyButton", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.uiScaleSliderApplyButton, 60, 24, "Apply", "TOP", 370, -50)
	parentFrame.uiScaleSliderApplyButton:SetScript("OnClick", function() 
		DatabaseModule.generalOptions.uiScale = parentFrame.uiScaleSlider:GetValue()
		self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale) 
	end)

end

function BuyInterfaceModule:CreateSearchFilters(parentFrame)

	parentFrame.iLvl = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_ItemLevel_Text", "OVERLAY", "GameFontNormal")
	parentFrame.iLvl:SetPoint("TOPLEFT", 380, -35)
	parentFrame.iLvl:SetJustifyH("CENTER")
	parentFrame.iLvl:SetText("Level Range")

	parentFrame.scoreSign = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_ItemLevel_ScoreSign", "OVERLAY", "GameFontNormal")
	parentFrame.scoreSign:SetPoint("TOPLEFT", 410, -55)
	parentFrame.scoreSign:SetJustifyH("CENTER")
	parentFrame.scoreSign:SetText("-")
	
	parentFrame.minILvl = CreateFrame("EditBox", "AB_BuyInterface_MainFrame_ItemLevel_MinItemLevel", parentFrame, "InputBoxTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.minILvl, 30, 20, nil, "CENTER", -28, -20, nil, parentFrame.iLvl)
	parentFrame.minILvl:SetAutoFocus(false)
	parentFrame.minILvl:SetJustifyH("CENTER")
	parentFrame.minILvl:SetScript("OnEscapePressed", function() parentFrame.minILvl:ClearFocus() end)
	parentFrame.minILvl:SetScript("OnEnterPressed", function() parentFrame.minILvl:ClearFocus() end)

	parentFrame.maxILvl = CreateFrame("EditBox", "AB_BuyInterface_MainFrame_ItemLevel_MaxItemLevel", parentFrame, "InputBoxTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.maxILvl, 30, 20, nil, "CENTER", 27, -20, nil, parentFrame.iLvl)
	parentFrame.maxILvl:SetAutoFocus(false)
	parentFrame.maxILvl:SetJustifyH("CENTER")
	parentFrame.maxILvl:SetScript("OnEscapePressed", function() parentFrame.maxILvl:ClearFocus() end)
	parentFrame.maxILvl:SetScript("OnEnterPressed", function() parentFrame.maxILvl:ClearFocus() end)

	parentFrame.itemTypeText = parentFrame.maxILvl:CreateFontString("AB_BuyInterface_MainFrame_SlotType_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemTypeText:SetPoint("CENTER", 99, 20)
	parentFrame.itemTypeText:SetJustifyH("CENTER")
	parentFrame.itemTypeText:SetText("Item Type")

	parentFrame.itemSubTypeText = parentFrame.maxILvl:CreateFontString("AB_BuyInterface_MainFrame_Rarity_Text", "OVERLAY", "GameFontNormal")
	parentFrame.itemSubTypeText:SetPoint("CENTER", 249, 20)
	parentFrame.itemSubTypeText:SetJustifyH("CENTER")
	parentFrame.itemSubTypeText:SetText("Rarity")

end

function BuyInterfaceModule:CreateBuyInterfaceSearchTablesOptions(parentFrame)

	parentFrame.resetDatabase = CreateFrame("Button", "AB_BuyInterface_MainFrame_ResetTableData_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.resetDatabase, 170, 24, "Reset Search History", "RIGHT", -215, 70)
	parentFrame.resetDatabase:SetScript("OnClick", function() 
		DatabaseModule:ResetDatabase("AB_RecentSearches") 
		DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.recentSearchesTable, DatabaseModule.recentSearches)
	end)
	
	parentFrame.manageFavoriteLists = CreateFrame("Button", "AB_BuyInterface_MainFrame_ManageFavoriteLists_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.manageFavoriteLists, 170, 24, "Manage Favorite Lists", "RIGHT", -215, -211)
	parentFrame.manageFavoriteLists:SetScript("OnClick", function() 
		parentFrame:Hide()
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.favoriteLists)
		InterfaceOptionsFrame_OpenToCategory(OptionsPanelModule.favoriteLists)
	end)
	
	parentFrame.addFavoriteBar = CreateFrame("EditBox", "AB_BuyInterface_MainFrame_SearchBar", parentFrame.favoriteSearchesFrame, "InputBoxTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.addFavoriteBar, 200, 20, nil, "TOPLEFT", 5, 25)
	parentFrame.addFavoriteBar:SetAutoFocus(false)
	parentFrame.addFavoriteBar:SetJustifyH("LEFT")
	parentFrame.addFavoriteBar:SetScript("OnEscapePressed", function() parentFrame.addFavoriteBar:ClearFocus() end)
	parentFrame.addFavoriteBar:SetScript("OnEnterPressed", function() 
		if parentFrame.addFavoriteBar:GetText() ~= "" and BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value ~= nil then
			DatabaseModule:InsertNewSearch(DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1], parentFrame.addFavoriteBar:GetText()) 
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1])
			parentFrame.addFavoriteBar:SetText("")
			parentFrame.addFavoriteBar:ClearFocus()
		else
			print("AuctionBuddy: Can't add an empty search.")
		end
	end)
	
	parentFrame.addFavorite = CreateFrame("Button", "AB_BuyInterface_MainFrame_AddFavorite_Button", parentFrame, "UIPanelButtonTemplate")
	BuyInterfaceModule:SetFrameParameters(parentFrame.addFavorite, 100, 24, "Add Favorite", "RIGHT", -75, -11)
	parentFrame.addFavorite:SetScript("OnClick", function()  
		if parentFrame.addFavoriteBar:GetText() ~= "" and BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value ~= nil then
			DatabaseModule:InsertNewSearch(DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1], parentFrame.addFavoriteBar:GetText()) 
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1])
			parentFrame.addFavoriteBar:SetText("")
			parentFrame.addFavoriteBar:ClearFocus()
		end
	end)

end

function BuyInterfaceModule:CreateBuyTab(parentFrame)

	if parentFrame.sellTabCreated == true then
		return
	end
	
	local auctionFrameNumTab = AuctionFrame.numTabs + 1
		
	parentFrame.buyTab = CreateFrame('Button', 'AuctionFrameTab' .. auctionFrameNumTab, AuctionFrame, 'AuctionTabTemplate')
	parentFrame.buyTab:SetID(auctionFrameNumTab)
	parentFrame.buyTab:SetText("AB Buy")
	parentFrame.buyTab:SetNormalFontObject(GameFontHighlightSmall)
	parentFrame.buyTab:SetPoint('LEFT', _G['AuctionFrameTab' .. auctionFrameNumTab - 1], 'RIGHT', -8, 0)
	parentFrame.buyTab:Show()
	
	self.mainFrame.buyTab.buyTabButton = parentFrame
	
	PanelTemplates_SetNumTabs(AuctionFrame, auctionFrameNumTab)
	PanelTemplates_EnableTab(AuctionFrame, auctionFrameNumTab)
	tinsert(AuctionBuddy.auctionTabs, parentFrame)
	
	parentFrame.sellTabCreated = true
	
end

function BuyInterfaceModule:SetFrameParameters(frame, width, height, text, point, xOffSet, yOffSet, strata, relativeTo)

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

function BuyInterfaceModule:ResetData()

	self.mainFrame.searchBar:SetText("")
	
	UIDropDownMenu_SetText(self.mainFrame.rarity, "Any") 
	self.mainFrame.rarity.value = 0

	UIDropDownMenu_SetText(self.mainFrame.itemClasses, "Any")
	self.mainFrame.itemClasses.value = 0
	self.mainFrame.itemClasses.valueSubList = nil
	self.mainFrame.itemClasses.valueSubSubList = nil

end

function BuyInterfaceModule:OnShowInterface()

	self.mainFrame:ClearAllPoints()
	self.mainFrame:SetPoint(DatabaseModule.generalOptions.point, DatabaseModule.generalOptions.xPosOffset, DatabaseModule.generalOptions.yPosOffset)
	self.mainFrame:SetScale(DatabaseModule.generalOptions.uiScale)
	self.mainFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
	self.mainFrame.currentPlayerGold:SetText(self.mainFrame.currentPlayerGold.value)
	self.mainFrame.totalBuyCost.value = GetCoinTextureString(0, 15)
	self.mainFrame.totalBuyCost:SetText(self.mainFrame.totalBuyCost.value)
	self.mainFrame.totalBidCost.value = GetCoinTextureString(0, 15)
	self.mainFrame.totalBidCost:SetText(self.mainFrame.totalBuyCost.value)
	ItemsModule.itemSelected = false
	self.mainFrame.scrollTable:ClearSelection()
	SellInterfaceModule.mainFrame.scrollTable:ClearSelection()
	NavigationModule:CheckSearchActive(BuyInterfaceModule.mainFrame)

end

function BuyInterfaceModule:HideBuyInterface()

	if self.mainFrame ~= nil then
		self.mainFrame:Hide()
	end

end