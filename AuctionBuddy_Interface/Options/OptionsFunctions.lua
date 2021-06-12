-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local OptionsFunctionsModule = AuctionBuddy:NewModule("OptionsFunctionsModule", "AceEvent-3.0")

local DebugModule = nil
local DatabaseModule = nil

function OptionsFunctionsModule:Enable()
	
	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")

end

function OptionsFunctionsModule:CreateNewList(listName)
	DebugModule:Log(self, "CreateNewList", 1)

	local totalListNumber = 1
	local favList = 
	{
		name = listName,
		{
		
		}
	}

	for i in pairs(DatabaseModule.favoriteSearchesLists) do
		totalListNumber = totalListNumber + 1
	end

	tinsert(DatabaseModule.favoriteSearchesLists, totalListNumber, favList)

	AB_FavoriteSearchesLists = DatabaseModule.favoriteSearchesLists

end

function OptionsFunctionsModule:RemoveSelectedList(selectedListName, dropDownMenu)
	DebugModule:Log(self, "RemoveSelectedList", 1)

	local listSize = 0

	if selectedListName == nil then
		return
	end

	for key in pairs(DatabaseModule.favoriteSearchesLists) do
		listSize = listSize + 1
	end

	if listSize == 1 then
		DatabaseModule.favoriteSearchesLists = DatabaseModule.favoriteSearchesListsDefault
	else
		for key in pairs(DatabaseModule.favoriteSearchesLists) do
			if DatabaseModule.favoriteSearchesLists[key]["name"] == selectedListName then
				tremove(DatabaseModule.favoriteSearchesLists, key)
				AB_FavoriteSearchesLists = DatabaseModule.favoriteSearchesLists
			end
		end
	end

	print("AuctionBuddy: ".. selectedListName .. " have been removed from the favorite list database.")

	CloseDropDownMenus()
	dropDownMenu.value = nil
	UIDropDownMenu_ClearAll(dropDownMenu)

end

function OptionsFunctionsModule:ChangeListName(list, newName, dropDownMenu)
	DebugModule:Log(self, "ChangeListName", 1)

	list["name"] = newName

	if dropDownMenu ~= nil then
		CloseDropDownMenus()
		UIDropDownMenu_Refresh(dropDownMenu)
		UIDropDownMenu_SetText(dropDownMenu, newName)
	end

end

function OptionsFunctionsModule:RemoveSelectedElementFromCurrentList(list, selectedElementName)
	DebugModule:Log(self, "RemoveSelectedElementFromCurrentList", 1)

	for key, value in pairs(list) do
		if key == selectedElementName then
			tremove(list, key)
		end
	end

end