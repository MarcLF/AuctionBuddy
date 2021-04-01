--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local NavigationModule = AuctionBuddy:NewModule("NavigationModule", "AceEvent-3.0")

NavigationModule.searchActive = nil
NavigationModule.page = nil
NavigationModule.maxResultsPages = nil

local DebugModule = nil

function NavigationModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)
	
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterMessage("ON_CLICK_NEXT_PAGE", self.OnClickNextPage)
	self:RegisterMessage("ON_CLICK_PREV_PAGE", self.OnClickPrevPage)
	self:RegisterMessage("UPDATE_NAVIGATION_PAGES", self.OnUpdateNavigationPages)
	
	self.searchActive = false
	self.page = 0
	self.maxResultsPages = 0

end

function NavigationModule:AUCTION_HOUSE_CLOSED()
	DebugModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllMessages()
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
	
end

function NavigationModule:OnClickNextPage(parentFrame)
	DebugModule:Log(self, "OnClickNextPage", 2)

	NavigationModule.page = NavigationModule.page + 1
	parentFrame.prevPageButton:SetEnabled(true)

end

function NavigationModule:OnClickPrevPage(parentFrame)
	DebugModule:Log(self, "OnClickPrevPage", 2)

	if NavigationModule.page > 0 then
		NavigationModule.page = NavigationModule.page - 1
	else
		parentFrame.prevPageButton:SetEnabled(false)
	end

end

function NavigationModule:OnUpdateNavigationPages(parentFrame)
	DebugModule:Log(self, "OnUpdateNavigationPages", 2)
	
	if NavigationModule.searchActive then
		if NavigationModule.page < NavigationModule.maxResultsPages then
			parentFrame.nextPageButton:SetEnabled(true)
		else
			parentFrame.nextPageButton:SetEnabled(false)
		end
		
		if NavigationModule.page > 0 then
			parentFrame.prevPageButton:SetEnabled(true)
		else
			parentFrame.prevPageButton:SetEnabled(false)
		end
	else	
		parentFrame.nextPageButton:SetEnabled(false)
		parentFrame.prevPageButton:SetEnabled(false)	
	end
	
end

function NavigationModule:ResetData()

	self.shown = 0
	self.total = 0
	self.page = 0

end