-- Core Lua File for AuctionBuddy
local addonName, addonTable = ...

local AuctionBuddy = LibStub("AceAddon-3.0"):NewAddon(
	"AuctionBuddy", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0"
);

AuctionBuddy.Version = GetAddOnMetadata(addonName, "Version")
addonTable[1] = AuctionBuddy

_G[addonName] = AuctionBuddy

AuctionBuddy.auctionTabs = {}

AuctionBuddy.searchText = nil
AuctionBuddy.shown = nil
AuctionBuddy.total = nil

local StdUi = LibStub("StdUi")

local DatabaseModule = nil
local NavigationModule = nil
local ItemsModule = nil
local ResultsTableModule = nil
local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil
local BuyInterfaceDropDownMenusModule = nil
local SellInterfaceModule = nil
local SearchesModule = nil
local OptionsPanelModule = nil
local OptionsFunctionsModule = nil

function AuctionBuddy:OnInitialize()

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	
end

function AuctionBuddy:VARIABLES_LOADED()

	self:EnableModule("DatabaseModule")
	self:EnableModule("OptionsFunctionsModule")
	self:EnableModule("OptionsPanelModule")

end

function AuctionBuddy:AUCTION_HOUSE_SHOW()

	self:EnableModule("ResultsTableModule")
	self:EnableModule("BuyInterfaceModule")
	self:EnableModule("BuyInterfaceDropDownMenusModule")
	self:EnableModule("SellInterfaceModule")
	self:EnableModule("ItemsModule")
	self:EnableModule("NavigationModule")
	self:EnableModule("ContainerModule")
	self:EnableModule("InterfaceFunctionsModule")
	self:EnableModule("SearchesModule")
	
	DatabaseModule = self:GetModule("DatabaseModule")
	NavigationModule = self:GetModule("NavigationModule")
	ItemsModule = self:GetModule("ItemsModule")
	ResultsTableModule = self:GetModule("ResultsTableModule")
	InterfaceFunctionsModule = self:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = self:GetModule("BuyInterfaceModule")
	SellInterfaceModule = self:GetModule("SellInterfaceModule")
	SearchesModule = self:GetModule("SearchesModule")
	
	if not self.onTabClickHooked then
			self:Hook("AuctionFrameTab_OnClick", true)
			self.onTabClickHooked = true
	end
		
end

function AuctionBuddy:AUCTION_HOUSE_CLOSED()

	self:ResetCurrentData()
	self:HideWindows()
	
end

function AuctionBuddy:AUCTION_ITEM_LIST_UPDATE()

	self.shown, self.total = GetNumAuctionItems("list")

	if self.total > 0 then
		NavigationModule.maxResultsPages = self.total / 50 - 1
	else
		NavigationModule.maxResultsPages = 0
	end

	ItemsModule:CreateAuctionItemButtons(self.shown, BuyInterfaceModule.mainFrame.scrollTable)
	ItemsModule:CreateAuctionItemButtons(self.shown, SellInterfaceModule.mainFrame.scrollTable)

	NavigationModule:CheckSearchActive(BuyInterfaceModule.mainFrame)
	NavigationModule:CheckSearchActive(SellInterfaceModule.mainFrame)
	
	if self.total > 1 then 
		ItemsModule:UpdateSellItemPriceAfterSearch(1)
	end
	
end

function AuctionBuddy:ResetCurrentData()

	if BuyInterfaceModule.mainFrame ~= nil then
		BuyInterfaceModule.mainFrame.scrollTable:SetData({}, true)
	end
	self.searchText = ""
	self.shown = 0
	self.total = 0
	NavigationModule.page = 0

end

function AuctionBuddy:TableCombine(keys, values)

	local result = {}
	
	for i = 1, #keys do
		result[keys[i]] = values[i];
	end

	return result
	
end

local function NoResponse()
	-- Do Nothing
end

function AuctionBuddy:AuctionFrameTab_OnClick(tab)

	if tab.buyTabButton then
		NavigationModule:CheckSearchActive(BuyInterfaceModule.mainFrame)
		BuyInterfaceModule.mainFrame:Show()
			
		-- Disabling CloseAuctionHouse temporarily
		local CloseAuctionHouseFunctional = CloseAuctionHouse
		CloseAuctionHouse = NoResponse
		AuctionFrame_Hide()
		CloseAuctionHouse = CloseAuctionHouseFunctional
	end
	
	if tab.sellTabButton then
		NavigationModule:CheckSearchActive(SellInterfaceModule.mainFrame)
		SellInterfaceModule.mainFrame:Show()
		
		-- Disabling CloseAuctionHouse temporarily
		local CloseAuctionHouseFunctional = CloseAuctionHouse
		CloseAuctionHouse = NoResponse
		AuctionFrame_Hide()
		CloseAuctionHouse = CloseAuctionHouseFunctional
	end
	
end
		
function AuctionBuddy:AuctionHouseSearch(textToSearch, exactMatch)
		
	if textToSearch ~= self.searchText and textToSearch ~= nil then
		NavigationModule.page = 0
	end

	if textToSearch ~= nil then
		self.searchText = textToSearch
	end
	
	if CanSendAuctionQuery() then
		NavigationModule.searchActive = true

		if self.searchText ~= "" then
			DatabaseModule:InsertNewSearch(DatabaseModule.recentSearches, self.searchText)
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.recentSearchesTable, DatabaseModule.recentSearches)
		end
		
		local filterData
		local itemType = BuyInterfaceModule.mainFrame.itemClasses.value
		local itemSubType = BuyInterfaceModule.mainFrame.itemClasses.valueSubList
		local itemSubSubType = BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList
		
		if itemType ~= nil and itemSubType ~= nil and itemSubSubType ~= nil then
			filterData = AuctionCategories[itemType].subCategories[itemSubType].subCategories[itemSubSubType].filters
		elseif itemType ~= nil and itemSubType ~= nil then
			filterData = AuctionCategories[itemType].subCategories[itemSubType].filters
		elseif itemType ~= 0 then
			filterData = AuctionCategories[itemType].filters
		else
			filterData = 0
        end

		QueryAuctionItems(	
			self.searchText, 
			BuyInterfaceModule.mainFrame.minILvl:GetNumber(),
			BuyInterfaceModule.mainFrame.maxILvl:GetNumber(), 
			NavigationModule.page,
			_,
			BuyInterfaceModule.mainFrame.rarity.value,
			_,
			DatabaseModule.buyOptions.exactMatch,
			filterData
		)
	end
	
end

function AuctionBuddy:HideWindows()

	BuyInterfaceModule:HideBuyInterface()
	SellInterfaceModule:HideSellInterface()

end