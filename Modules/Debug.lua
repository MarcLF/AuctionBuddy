--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local DebugModule = AuctionBuddy:NewModule("DebugModule")

function DebugModule:Log(...)

	--@debug@ 
	print(...)
	--@end-debug@

end
