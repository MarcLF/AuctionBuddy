--
local AuctionBuddy = unpack(select(2, ...))

local NavigationModule = AuctionBuddy:NewModule("NavigationModule", "AceEvent-3.0")

NavigationModule.searchActive = nil
NavigationModule.page = nil
NavigationModule.maxResultsPages = nil

local UtilsModule = nil

function NavigationModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)
	
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterMessage("ON_CLICK_NEXT_PAGE", self.OnClickNextPage)
	self:RegisterMessage("ON_CLICK_PREV_PAGE", self.OnClickPrevPage)
	self:RegisterMessage("UPDATE_NAVIGATION_PAGES", self.OnUpdateNavigationPages)
	self:RegisterMessage("POSTING_ITEM_TO_AH", self.ResetData)
	
	self.searchActive = false
	self.page = 0
	self.maxResultsPages = 0

end

function NavigationModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	
end

function NavigationModule:OnClickNextPage(parentFrame)
	UtilsModule:Log(self, "OnClickNextPage", 2)

	NavigationModule.page = NavigationModule.page + 1

end

function NavigationModule:OnClickPrevPage(parentFrame)
	UtilsModule:Log(self, "OnClickPrevPage", 2)

	if NavigationModule.page > 0 then
		NavigationModule.page = NavigationModule.page - 1
	end

end

function NavigationModule:OnUpdateNavigationPages(parentFrame)
	UtilsModule:Log(self, "OnUpdateNavigationPages", 2)

	NavigationModule.shown, NavigationModule.total = GetNumAuctionItems("list")

	NavigationModule.maxResultsPages = math.ceil(math.max(NavigationModule.total, 1) / math.max(NavigationModule.shown, 1) - 1)

	NavigationModule:SendMessage("UPDATE_AVAILABLE_RESULTS_PAGES", NavigationModule.page, NavigationModule.maxResultsPages)
	
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

	NavigationModule.shown = 0
	NavigationModule.total = 0
	NavigationModule.page = 0

end