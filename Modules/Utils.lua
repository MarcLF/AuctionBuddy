--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local UtilsModule = AuctionBuddy:NewModule("UtilsModule")

-- Log Verbose Levels
-- 3 = VERY HIGH
-- 2 = HIGH
-- 1 = MEDIUM
-- 0 = LOW
-- -1 = NONE

UtilsModule.verbose = 0

function UtilsModule:Log(...)

	--@debug@ 
	local verbose = select(3, ...)

	if tonumber(verbose) <= UtilsModule.verbose then	
		print(...)
	end
	--@end-debug@

end

function UtilsModule:RemoveCharacterFromString(stringToFilter, ...)

	local filteredItemLink = stringToFilter

	for key,value in pairs{...} do

		filteredItemLink = string.gsub(filteredItemLink,value,'')

	end

	return filteredItemLink

end
