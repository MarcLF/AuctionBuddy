--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local DatabaseModule = AuctionBuddy:NewModule("DatabaseModule")

DatabaseModule.buyOptionsDefault = 
{
	doubleClickToBuy = false,
	exactMatch = false
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

	if not AB_BuyOptions or not AB_BuyOptions.exactMatch then 
		AB_BuyOptions = self.buyOptionsDefault	
	end

	self.buyOptions = AB_BuyOptions

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

	scrollTable:SetData(databaseTable, true)

end