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
AuctionBuddy.isSortedBuyout = false

local StdUi = LibStub("StdUi")

local UtilsModule = nil
local ErrorModule = nil
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
local ContainerModule = nil

function AuctionBuddy:OnInitialize()

	self:RegisterEvent("VARIABLES_LOADED")
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")

end

function AuctionBuddy:VARIABLES_LOADED()

	self:EnableModule("UtilsModule")
	self:EnableModule("ErrorModule")
	self:EnableModule("DatabaseModule")
	self:EnableModule("OptionsFunctionsModule")
	self:EnableModule("OptionsPanelModule")

end

function AuctionBuddy:AUCTION_HOUSE_SHOW()

	self:EnableModule("ItemsModule")
	self:EnableModule("ResultsTableModule")
	self:EnableModule("InterfaceFunctionsModule")
	self:EnableModule("BuyInterfaceModule")
	self:EnableModule("BuyInterfaceDropDownMenusModule")
	self:EnableModule("SellInterfaceModule")
	self:EnableModule("NavigationModule")
	self:EnableModule("ContainerModule")
	self:EnableModule("SearchesModule")
	
	UtilsModule = self:GetModule("UtilsModule")
	DatabaseModule = self:GetModule("DatabaseModule")
	NavigationModule = self:GetModule("NavigationModule")
	ItemsModule = self:GetModule("ItemsModule")
	ResultsTableModule = self:GetModule("ResultsTableModule")
	InterfaceFunctionsModule = self:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = self:GetModule("BuyInterfaceModule")
	SellInterfaceModule = self:GetModule("SellInterfaceModule")
	SearchesModule = self:GetModule("SearchesModule")
	ContainerModule = self:GetModule("ContainerModule")
	
	if not self.onTabClickHooked then
		self:Hook("AuctionFrameTab_OnClick", true)
		self.onTabClickHooked = true
	end

end

function AuctionBuddy:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log("AuctionBuddy", "AUCTION_HOUSE_CLOSED", 1)

	self.searchText = ""
	
end

function AuctionBuddy:TableCombine(keys, values)
	UtilsModule:Log(self, "TableCombine", 1)

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
	UtilsModule:Log(self, "AuctionFrameTab_OnClick", 1)

	if tab.buyTabButton then
		BuyInterfaceModule.mainFrame:Show()
			
		-- Disabling CloseAuctionHouse temporarily while we switch the current active tab
		local CloseAuctionHouseFunctional = CloseAuctionHouse
		CloseAuctionHouse = NoResponse
		AuctionFrame_Hide()
		CloseAuctionHouse = CloseAuctionHouseFunctional
	end
	
	if tab.sellTabButton then
		SellInterfaceModule.mainFrame:Show()
		
		-- Disabling CloseAuctionHouse temporarily while we switch the current active tab
		local CloseAuctionHouseFunctional = CloseAuctionHouse
		CloseAuctionHouse = NoResponse
		AuctionFrame_Hide()
		CloseAuctionHouse = CloseAuctionHouseFunctional
	end
	
end
		
function AuctionBuddy:AuctionHouseSearch(textToSearch, exactMatch)
	UtilsModule:Log(self, "AuctionHouseSearch", 0)

	if textToSearch ~= nil and textToSearch ~= AuctionBuddy.searchText then
		NavigationModule.page = 0
	end

	if textToSearch ~= nil then
		AuctionBuddy.searchText = textToSearch
	end
	
	if CanSendAuctionQuery() then
		ItemsModule.itemSelected = false
		NavigationModule.searchActive = true

		local checkWhiteSpaces = string.gsub(AuctionBuddy.searchText, " ", "")

		if string.len(AuctionBuddy.searchText) > 0 and string.len(checkWhiteSpaces) > 0 then
			DatabaseModule:InsertNewSearch(DatabaseModule.recentSearches, AuctionBuddy.searchText)
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.recentSearchesTable, DatabaseModule.recentSearches)
		end
		
		local filterData = nil
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

		if self.isSortedBuyout == false then
			SortAuctionItems("list", "buyout")
			AuctionBuddy.isSortedBuyout = true
		end

		QueryAuctionItems(	
			AuctionBuddy.searchText, 
			BuyInterfaceModule.mainFrame.minILvl:GetNumber(),
			BuyInterfaceModule.mainFrame.maxILvl:GetNumber(), 
			NavigationModule.page,
			false,
			BuyInterfaceModule.mainFrame.rarity.value,
			false,
			DatabaseModule.buyOptions.exactMatch or exactMatch,
			filterData
		)
	else
		AuctionBuddy:SendMessage("AUCTIONBUDDY_ERROR", "CannotSendAHQuery")
	end
	
end