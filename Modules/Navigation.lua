--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local NavigationModule = AuctionBuddy:NewModule("NavigationModule", "AceEvent-3.0")

NavigationModule.searchActive = nil
NavigationModule.page = nil
NavigationModule.maxResultsPages = nil

local DebugModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

function NavigationModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)
	
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	
	self.searchActive = false
	self.page = 0
	self.maxResultsPages = 0

end

function NavigationModule:AUCTION_HOUSE_CLOSED()
	DebugModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllEvents()
	
end

function NavigationModule:AUCTION_ITEM_LIST_UPDATE()
	DebugModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 0)

	self.shown, self.total = GetNumAuctionItems("list")

	if self.total > 0 then
		NavigationModule.maxResultsPages = self.total / 50 - 1
	else
		NavigationModule.maxResultsPages = 0
	end

	NavigationModule:CheckSearchActive(BuyInterfaceModule.mainFrame)
	NavigationModule:CheckSearchActive(SellInterfaceModule.mainFrame)
	
end

function NavigationModule:CheckSearchActive(parentFrame)
	DebugModule:Log(self, "CheckSearchActive", 2)
	
	if self == nil then
		self = NavigationModule
	end
	
	if NavigationModule.searchActive then
		if self.page < self.maxResultsPages then
			parentFrame.nextPageButton:SetEnabled(true)
		else
			parentFrame.nextPageButton:SetEnabled(false)
		end
		
		if self.page > 0 then
			parentFrame.prevPageButton:SetEnabled(true)
		else
			parentFrame.prevPageButton:SetEnabled(false)
		end
	else	
		parentFrame.nextPageButton:SetEnabled(false)
		parentFrame.prevPageButton:SetEnabled(false)	
	end
	
end

function NavigationModule:MovePage(isNext, parentFrame)
	DebugModule:Log(self, "MovePage", 3)
	
	if isNext then
		self.page = self.page + 1
		parentFrame.prevPageButton:SetEnabled(true)
	else
		if self.page > 0 then
			self.page = self.page - 1
		else
			parentFrame.prevPageButton:SetEnabled(false)
		end
	end

end