--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ErrorModule = AuctionBuddy:NewModule("ErrorModule", "AceEvent-3.0")

local auctionBuddyErrors = {
	CannotSendAHQuery = "AuctionBuddy: Can't send queries to the auction house right now, try again in few seconds.",
	CannotAddEmptySearch = "AuctionBuddy: Can't add an empty search.",
	InvalidStackOrSizeQuantity = "AuctionBuddy: Can't place auctions without a valid stack size and quantity.",
	CannotSellSoulboundItems = "AuctionBuddy: Can't auction Soulbound items.",
	TimeoutPostItem = "AuctionBuddy: Can't post new items at this moment, try again in few seconds.",
	InvalidAuctionPrice = "AuctionBuddy: Can't post this item. Please insert a valid auction price."
}


function ErrorModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	self:RegisterMessage("AUCTIONBUDDY_ERROR", self.ProcessAuctionBuddyError)
	
end

function ErrorModule:ProcessAuctionBuddyError(errorCode)

	for code, msg in pairs(auctionBuddyErrors) do
		if code == errorCode then
			print(msg)
		end
	end

end
