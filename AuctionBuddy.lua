-- Core Lua File for AuctionBuddy
local addonName, addonTable = ...

local AuctionBuddy = LibStub("AceAddon-3.0"):NewAddon(
	"AuctionBuddy", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0"
);

AuctionBuddy.Version = GetAddOnMetadata(addonName, "Version")
addonTable[1] = AuctionBuddy

_G[addonName] = AuctionBuddy

AuctionBuddy.auctionTabs = {}

local UtilsModule = nil
local ErrorModule = nil
local DatabaseModule = nil
local ScanModule = nil
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
	self:EnableModule("ScanModule")
	self:EnableModule("ContainerModule")
	self:EnableModule("SearchesModule")
	
	UtilsModule = self:GetModule("UtilsModule")
	DatabaseModule = self:GetModule("DatabaseModule")
	ScanModule = self:GetModule("ScanModule")
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