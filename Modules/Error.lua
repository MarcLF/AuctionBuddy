--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ErrorModule = AuctionBuddy:NewModule("ErrorModule", "AceEvent-3.0")

function ErrorModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	self:RegisterMessage("ERROR_CAN_NOT_SEND_AH_QUERY", self.CannotSendAHQuery)
	self:RegisterMessage("ERROR_CAN_NOT_ADD_EMPTY_SEARCH", self.CannotAddEmptySearch)
	self:RegisterMessage("ERROR_CAN_NOT_AUCTION_SOULBOUND_ITEMS", self.CannotSellSoulboundItems)
	self:RegisterMessage("ERROR_INVALID_STACK_OR_SIZE_QUANTITY", self.InvalidStackOrSizeQuantity)

end

function ErrorModule:CannotSendAHQuery()

	print("AuctionBuddy: Can't send queries to the auction house right now, try again in few seconds.")

end

function ErrorModule:CannotAddEmptySearch()

	print("AuctionBuddy: Can't add an empty search.")

end

function ErrorModule:InvalidStackOrSizeQuantity()

	print("AuctionBuddy: Can't place auctions without a valid stack size and quantity.")

end

function ErrorModule:CannotSellSoulboundItems()

	print("AuctionBuddy: Can't auction Soulbound items")

end
