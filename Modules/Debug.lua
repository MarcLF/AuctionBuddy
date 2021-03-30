--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local DebugModule = AuctionBuddy:NewModule("DebugModule")

-- Debug Verbose Levels
-- 3 = VERY HIGH
-- 2 = HIGH
-- 1 = MEDIUM
-- 0 = LOW

DebugModule.verbose = 3

function DebugModule:Log(...)

	--@debug@ 
	local verbose = select(3, ...)

	if tonumber(verbose) <= DebugModule.verbose then	
		print(...)
	end
	--@end-debug@

end
