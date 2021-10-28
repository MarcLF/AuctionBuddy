--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local SearchesModule = AuctionBuddy:NewModule("SearchesModule", "AceEvent-3.0")

local UtilsModule = nil
local BuyInterfaceModule = nil
local DatabaseModule = nil

function SearchesModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")

	if self.tablesCreated == true then
		if BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value ~= nil then
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1])
		else
			DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, {})
		end
		return
	end
	
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")

	self:CreateRecentSearchesScrollFrameTable(BuyInterfaceModule.mainFrame, 400, -120, "Recent Searches")
	self:CreateFavoriteSearchesScrollFrameTable(BuyInterfaceModule.mainFrame, 400, -390, "Favorite Searches")

	self:CreateFavoriteSearchesDropDownMenu(BuyInterfaceModule.mainFrame, -50, 35)

	DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.recentSearchesTable, DatabaseModule.recentSearches)

	if BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value ~= nil then
		DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1])
	else
		DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, {})
	end
		
	self.tablesCreated = true
	
end

function SearchesModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:ResetData()
	self:UnregisterAllEvents()
	
end

function SearchesModule:CreateRecentSearchesScrollFrameTable(parentFrame, xPos, yPos, tableName)
	UtilsModule:Log(self, "CreateRecentSearchesScrollFrameTable", 2)

	local columnType = 
	{
		{
			name         = tableName,
			width        = 280,
			align        = "LEFT",
			index        = "searchName",
			format       = "string",
		}
	}
	
	parentFrame.recentSearchesTable = StdUi:ScrollTable(parentFrame, columnType, 8, 16)
	StdUi:GlueTop(parentFrame.recentSearchesTable, parentFrame, xPos,yPos, 0, 0)
	parentFrame.recentSearchesTable:EnableSelection(true)
	parentFrame.recentSearchesTable:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
			if button == "LeftButton" then
					AuctionBuddy:AuctionHouseSearch(rowData.searchName)	
			end
			return true
		end,
	})
	
end

function SearchesModule:CreateFavoriteSearchesScrollFrameTable(parentFrame, xPos, yPos, tableName)
	UtilsModule:Log(self, "CreateFavoriteSearchesScrollFrameTable", 2)

	local columnType = {
		{
			name         = tableName,
			width        = 280,
			align        = "LEFT",
			index        = "searchName",
			format       = "string",
		}
	}
	
	parentFrame.favoriteSearchesTable = StdUi:ScrollTable(parentFrame, columnType, 8, 16)
	StdUi:GlueTop(parentFrame.favoriteSearchesTable, parentFrame, xPos,yPos, 0, 0)
	parentFrame.favoriteSearchesTable:EnableSelection(true)
	parentFrame.favoriteSearchesTable:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
			if button == "LeftButton" then
					AuctionBuddy:AuctionHouseSearch(rowData.searchName)	
			end
			return true
		end,
	})
	
end

function SearchesModule:CreateFavoriteSearchesDropDownMenu(parentFrame, xPos, yPos)
	UtilsModule:Log(self, "CreateFavoriteSearchesDropDownMenu", 2)

	parentFrame.selectFavListText = parentFrame:CreateFontString("AB_BuyInterface_MainFrame_FavoriteLists_SelectFavListText", "OVERLAY", "GameFontWhite")
	parentFrame.selectFavListText:SetPoint("RIGHT", xPos - 195, yPos + 2)
	parentFrame.selectFavListText:SetJustifyH("CENTER")
	parentFrame.selectFavListText:SetText("Select a favorite list:")

	parentFrame.favoriteListsDropDownMenu = CreateFrame("Frame", "AB_BuyInterface_MainFrame_FavoriteLists_DropDownMenu", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.favoriteListsDropDownMenu:SetPoint("RIGHT", xPos, yPos)
	parentFrame.favoriteListsDropDownMenu.value = nil
	UIDropDownMenu_SetWidth(parentFrame.favoriteListsDropDownMenu, 150)
	UIDropDownMenu_Initialize(parentFrame.favoriteListsDropDownMenu, SearchesModule.FavoriteListsDropDown)

end

local function SelectList(self, arg1, arg2, checked)
	UtilsModule:Log("SearchesModule", "SelectList", 3)

	BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value = arg1
	UIDropDownMenu_SetText(BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu, DatabaseModule.favoriteSearchesLists[arg1][arg2])

	BuyInterfaceModule.mainFrame.favoriteSearchesTable:SetData(DatabaseModule.favoriteSearchesLists[arg1][1], true)

end

function SearchesModule:FavoriteListsDropDown(frame, level, menuList)
	UtilsModule:Log(self, "FavoriteListsDropDown", 2)

	local info = UIDropDownMenu_CreateInfo()
	info.func = SelectList

	for key, value in pairs(DatabaseModule.favoriteSearchesLists) do
		for nestedKey, nestedValue in pairs(DatabaseModule.favoriteSearchesLists[key]) do
			if(nestedKey == "name") then
				info.text = DatabaseModule.favoriteSearchesLists[key][nestedKey]
				info.arg1 = key
				info.arg2 = nestedKey
				info.checked = BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value == key
				UIDropDownMenu_AddButton(info)
			end
		end
	end
	
end

function SearchesModule:ResetData()
	UtilsModule:Log(self, "ResetData", 1)

	BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value = nil
	UIDropDownMenu_ClearAll(BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu)

end