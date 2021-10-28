--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local DatabaseModule = AuctionBuddy:NewModule("DatabaseModule")

local UtilsModule = nil

DatabaseModule.generalOptionsDefault = 
{
	uiScale = 1.0,
	point = "CENTER",
	xPosOffset = 0,
	yPosOffset = 0
}

DatabaseModule.buyOptionsDefault = 
{
	doubleClickToBuy = false,
	doubleClickToBid = false,
	exactMatch = false,
}

DatabaseModule.sellOptionsDefault = 
{
	stackPriceFixed = false
}

DatabaseModule.recentSearchesDefault = 
{

}

DatabaseModule.favoriteSearchesListsDefault =
{ 
	{
		name = "List #1",
		{

		}
	}
}

function DatabaseModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	if not AB_GeneralOptions or not AB_GeneralOptions.xPosOffset or not AB_GeneralOptions.yPosOffset  or not AB_GeneralOptions.point then 
		AB_GeneralOptions = self.generalOptionsDefault	
	end

	self.generalOptions = AB_GeneralOptions

	if not AB_BuyOptions or AB_BuyOptions.exactMatch == nil or AB_BuyOptions.doubleClickToBuy == nil or AB_BuyOptions.doubleClickToBid == nil then 
		AB_BuyOptions = self.buyOptionsDefault	
	end

	self.buyOptions = AB_BuyOptions

	if not AB_SellOptions then 
		AB_SellOptions = self.sellOptionsDefault	
	end

	self.sellOptions = AB_SellOptions

	if not AB_RecentSearches then 
		AB_RecentSearches = self.recentSearchesDefault	
	end
	
	self.recentSearches = AB_RecentSearches
	
	if not AB_FavoriteSearchesLists then 
		AB_FavoriteSearchesLists = self.favoriteSearchesListsDefault
	end

	self.favoriteSearchesLists = AB_FavoriteSearchesLists

end

function DatabaseModule:ResetDatabase(databaseToReset, dropDownToRefresh)
	UtilsModule:Log(self, "ResetDatabase", 1)

	if databaseToReset == "AB_RecentSearches" then
		AB_RecentSearches = {}
		self.recentSearches = {}
		print("AuctionBuddy: Recent Search History Reseted.")
	
	elseif databaseToReset == "AB_FavoriteSearchesLists" then
		AB_FavoriteSearchesLists = {}
		AB_FavoriteSearchesLists = 
		{ 
			{
				name = "List #1",
				{

				}
			}
		}
		self.favoriteSearchesLists = {}
		self.favoriteSearchesLists = 
		{ 
			{
				name = "List #1",
				{

				}
			}
		}

		CloseDropDownMenus()
		dropDownToRefresh.value = nil
		UIDropDownMenu_ClearAll(dropDownToRefresh)

		print("AuctionBuddy: All Favorite Lists have been reseted.")
	end

end

function DatabaseModule:InsertNewSearch(databaseTable, nameToInsert)
	UtilsModule:Log(self, "InsertNewSearch", 1)

	for key, value in pairs(databaseTable) do
		for nestedKey, nestedValue in pairs(value) do
			if nestedValue == nameToInsert then
				return
			end
		end
	end
	
	tinsert(databaseTable, 
	{			
		searchName = nameToInsert
	})
	
end

function DatabaseModule:InsertDataFromDatabase(scrollTable, databaseTable)
	UtilsModule:Log(self, "InsertDataFromDatabase", 1)

	scrollTable:SetData(databaseTable, true)

end