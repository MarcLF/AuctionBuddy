-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local OptionsPanelModule = AuctionBuddy:NewModule("OptionsPanelModule", "AceEvent-3.0")

local DatabaseModule = nil
local OptionsFunctionsModule = nil


function OptionsPanelModule:OnEnable()

	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	OptionsFunctionsModule = AuctionBuddy:GetModule("OptionsFunctionsModule")

	if DatabaseModule.favoriteSearchesLists == nil then
		C_Timer.After(1, function() self:CreatingInterfaceOnEnable() end)
		print("AuctionBuddy encountered an error while loading the Options menu, trying again in 1 second...")
	else
		self:CreatingInterfaceOnEnable()
	end

end

function OptionsPanelModule:CreatingInterfaceOnEnable()

	self:CreateOptionsPanel()
	self:CreateOptionsPanelChildFavoriteLists()
	self:CreateOptionsPanelChildFavoriteListsButtons(self.manageListFrame)
	self:CreateFavoriteSearchesScrollFrameTable(self.manageListFrame, -120, -155)

end

function OptionsPanelModule:CreateOptionsPanel()

	self.panel = CreateFrame("Frame", "AuctionBuddy_OptionsPanel", UIParent)
	self.panel.name = "AuctionBuddy"

	InterfaceOptions_AddCategory(self.panel)

end

function OptionsPanelModule:CreateOptionsPanelChildFavoriteLists()

	self.favoriteLists = CreateFrame("Frame", "AuctionBuddy_OptionsPanel_FavoriteLists", self.panel)
	self.favoriteLists.name = "Favorite Lists"
	self.favoriteLists.parent = self.panel.name

	self.favoriteLists.text = self.favoriteLists:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_TitleText", "OVERLAY", "GameFontNormal")
	self.favoriteLists.text:SetWidth(250)
	self.favoriteLists.text:SetPoint("TOPLEFT", 15, -15)
	self.favoriteLists.text:SetJustifyH("LEFT")
	self.favoriteLists.text:SetText("Favorite Lists")

	self.createListFrame = CreateFrame("Frame", "AuctionBuddy_OptionsPanel_FavoriteLists_CreateList", self.favoriteLists, "InsetFrameTemplate3")
	self.createListFrame:SetPoint("CENTER", 0, 200)
	self.createListFrame:SetWidth(600)
	self.createListFrame:SetHeight(100)

	self.createListFrame.text = self.createListFrame:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_TitleText", "OVERLAY", "GameFontNormal")
	self.createListFrame.text:SetWidth(250)
	self.createListFrame.text:SetPoint("TOPLEFT", 15, -12)
	self.createListFrame.text:SetJustifyH("LEFT")
	self.createListFrame.text:SetText("Create a List")

	self.manageListFrame = CreateFrame("Frame", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList", self.favoriteLists, "InsetFrameTemplate3")
	self.manageListFrame:SetPoint("CENTER", 0, -63)
	self.manageListFrame:SetWidth(600)
	self.manageListFrame:SetHeight(410)

	self.createListName = CreateFrame("EditBox", "AuctionBuddy_OptionsPanel_FavoriteLists_CreateList_EditBox", self.createListFrame, "InputBoxTemplate")
	self.createListName:SetWidth(200)
	self.createListName:SetHeight(40)
	self.createListName:SetPoint("CENTER")
	self.createListName:SetAutoFocus(false)
	self.createListName:SetJustifyH("CENTER")
	self.createListName:SetScript("OnEnterPressed", function()  
		if self.createListName:GetText() ~= "" then
			OptionsFunctionsModule:CreateNewList(self.createListName:GetText())
			print("AuctionBuddy: New List '" .. self.createListName:GetText() .. " 'added to the favorite lists database.")
			self.createListName:SetText("")	
			self.createListName:ClearFocus()
			CloseDropDownMenus()
		end
	end)
	self.createListName:SetScript("OnEscapePressed", function() self.createListName:ClearFocus() end)
	
	self.createListName.text = self.createListName:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_CreateList_CreateText", "OVERLAY", "GameFontWhite")
	self.createListName.text:SetPoint("CENTER", -200, 0)
	self.createListName.text:SetJustifyH("CENTER")
	self.createListName.text:SetText("Name of the List:")

	self.createListName.button = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_CreateList_Button", self.createListFrame, "UIPanelButtonTemplate")
	self.createListName.button:SetPoint("CENTER", 190, 0)
	self.createListName.button:SetWidth(100)
	self.createListName.button:SetHeight(24)
	self.createListName.button:SetText("Create List")
	self.createListName.button:SetScript("OnClick", function()  
		if self.createListName:GetText() ~= "" then
			OptionsFunctionsModule:CreateNewList(self.createListName:GetText())
			self.createListName:SetText("")
			self.createListName:ClearFocus()
			CloseDropDownMenus()
		end
	end)

	self.favoriteLists.selectList = CreateFrame("Frame", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_SelectList", self.manageListFrame, "UIDropDownMenuTemplate")
	self.favoriteLists.selectList:SetPoint("CENTER", 130, 150)
	self.favoriteLists.selectList.value = nil
	UIDropDownMenu_SetWidth(self.favoriteLists.selectList, 250)
	UIDropDownMenu_Initialize(self.favoriteLists.selectList, self.FavoriteListsDropDown)

	self.manageListText = self.manageListFrame:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_SelectText", "OVERLAY", "GameFontNormal")
	self.manageListText:SetPoint("CENTER", -203, 185)
	self.manageListText:SetJustifyH("CENTER")
	self.manageListText:SetText("Manage your Favorite Lists")

	self.selectAListText = self.manageListFrame:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_SelectText", "OVERLAY", "GameFontWhite")
	self.selectAListText:SetPoint("CENTER", -170, 150)
	self.selectAListText:SetJustifyH("CENTER")
	self.selectAListText:SetText("Select an existing Favorite List:")

	self.setTextAsText = self.manageListFrame:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_SetTextAs", "OVERLAY", "GameFontWhite")
	self.setTextAsText:SetPoint("CENTER", 4, 100)
	self.setTextAsText:SetJustifyH("CENTER")
	self.setTextAsText:SetText("Set edit box text as:")

	InterfaceOptions_AddCategory(OptionsPanelModule.favoriteLists)

end

function OptionsPanelModule:CreateOptionsPanelChildFavoriteListsButtons(parentFrame)

	parentFrame.textInputEditList = CreateFrame("EditBox", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_EditBox", parentFrame, "InputBoxTemplate")
	parentFrame.textInputEditList:SetWidth(200)
	parentFrame.textInputEditList:SetHeight(40)
	parentFrame.textInputEditList:SetPoint("CENTER", -170, 100)
	parentFrame.textInputEditList:SetAutoFocus(false)
	parentFrame.textInputEditList:SetJustifyH("CENTER")
	parentFrame.textInputEditList:SetScript("OnEnterPressed", function()  end)
	parentFrame.textInputEditList:SetScript("OnEscapePressed", function() parentFrame.textInputEditList:ClearFocus() end)

	parentFrame.editName = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_EditName", parentFrame, "UIPanelButtonTemplate")
	parentFrame.editName:SetPoint("CENTER", 165, 100)
	parentFrame.editName:SetWidth(180)
	parentFrame.editName:SetHeight(24)
	parentFrame.editName:SetText("List new name")
	parentFrame.editName:SetScript("OnClick", function()  
		if parentFrame.textInputEditList:GetText() ~= "" and OptionsPanelModule.favoriteLists.selectList.value ~= nil then
			OptionsFunctionsModule:ChangeListName(DatabaseModule.favoriteSearchesLists[OptionsPanelModule.favoriteLists.selectList.value], parentFrame.textInputEditList:GetText(), self.favoriteLists.selectList)
			parentFrame.textInputEditList:SetText("")
			parentFrame.textInputEditList:ClearFocus()
		end
	end)

	parentFrame.addElement = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_AddElement", parentFrame, "UIPanelButtonTemplate")
	parentFrame.addElement:SetPoint("CENTER", 165, 65)
	parentFrame.addElement:SetWidth(180)
	parentFrame.addElement:SetHeight(24)
	parentFrame.addElement:SetText("New list element")
	parentFrame.addElement:SetScript("OnClick", function()  
		if parentFrame.textInputEditList:GetText() ~= "" and OptionsPanelModule.favoriteLists.selectList.value ~= nil then
			 DatabaseModule:InsertNewSearch(DatabaseModule.favoriteSearchesLists[OptionsPanelModule.favoriteLists.selectList.value][1], parentFrame.textInputEditList:GetText())
			 DatabaseModule:InsertDataFromDatabase(self.manageListFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[OptionsPanelModule.favoriteLists.selectList.value][1])
			 parentFrame.textInputEditList:SetText("")
			 parentFrame.textInputEditList:ClearFocus()
		end
	end)

	parentFrame.removeElement = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_RemoveElement", parentFrame, "UIPanelButtonTemplate")
	parentFrame.removeElement:SetPoint("CENTER", 165, 00)
	parentFrame.removeElement:SetWidth(180)
	parentFrame.removeElement:SetHeight(24)
	parentFrame.removeElement:SetText("Remove selected element")
	parentFrame.removeElement:SetScript("OnClick", function()  
		if self.manageListFrame.favoriteSearchesTable:GetSelection() ~= nil and OptionsPanelModule.favoriteLists.selectList.value ~= nil then
			OptionsFunctionsModule:RemoveSelectedElementFromCurrentList(DatabaseModule.favoriteSearchesLists[OptionsPanelModule.favoriteLists.selectList.value][1], self.manageListFrame.favoriteSearchesTable:GetSelection())
			DatabaseModule:InsertDataFromDatabase(self.manageListFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[OptionsPanelModule.favoriteLists.selectList.value][1])
		end
	end)

	parentFrame.deleteList = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_DeleteList", parentFrame, "UIPanelButtonTemplate")
	parentFrame.deleteList:SetPoint("CENTER", 165, -80)
	parentFrame.deleteList:SetWidth(180)
	parentFrame.deleteList:SetHeight(24)
	parentFrame.deleteList:SetText("Delete current list")
	parentFrame.deleteList:SetScript("OnClick", function()  
		OptionsFunctionsModule:RemoveSelectedList(UIDropDownMenu_GetText(OptionsPanelModule.favoriteLists.selectList), self.favoriteLists.selectList)
		DatabaseModule:InsertDataFromDatabase(self.manageListFrame.favoriteSearchesTable, {})
	end)

	parentFrame.deleteFavoriteLists = CreateFrame("Button", "AuctionBuddy_OptionsPanel_FavoriteLists_ManageList_DeleteList", parentFrame, "UIPanelButtonTemplate")
	parentFrame.deleteFavoriteLists:SetPoint("CENTER", 165, -160)
	parentFrame.deleteFavoriteLists:SetWidth(180)
	parentFrame.deleteFavoriteLists:SetHeight(24)
	parentFrame.deleteFavoriteLists:SetText("Delete All Favorite lists")
	parentFrame.deleteFavoriteLists:SetScript("OnClick", function()  
		DatabaseModule:ResetDatabase("AB_FavoriteSearchesLists", OptionsPanelModule.favoriteLists.selectList)
		DatabaseModule:InsertDataFromDatabase(self.manageListFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[1][1])
	end)


end

function OptionsPanelModule:CreateOptionsPanelChildSellParameters()

	OptionsPanelModule.sellParameters = CreateFrame("Frame", "AuctionBuddy_OptionsPanel_SellParameters", OptionsPanelModule.panel)
	OptionsPanelModule.sellParameters.name = "Sell Parameters"
	OptionsPanelModule.sellParameters.parent = OptionsPanelModule.panel.name

	OptionsPanelModule.sellParameters.text = OptionsPanelModule.sellParameters:CreateFontString("AuctionBuddy_OptionsPanel_FavoriteLists_TitleText", "OVERLAY", "GameFontNormal")
	OptionsPanelModule.sellParameters.text:SetWidth(250)
	OptionsPanelModule.sellParameters.text:SetPoint("TOPLEFT", 15, -15)
	OptionsPanelModule.sellParameters.text:SetJustifyH("LEFT")
	OptionsPanelModule.sellParameters.text:SetText("Sell Parameters")

	InterfaceOptions_AddCategory(OptionsPanelModule.sellParameters)

end

local function SelectList(self, arg1, arg2, checked)

	OptionsPanelModule.favoriteLists.selectList.value = arg1
	UIDropDownMenu_SetText(OptionsPanelModule.favoriteLists.selectList, DatabaseModule.favoriteSearchesLists[arg1][arg2])

	OptionsPanelModule.manageListFrame.favoriteSearchesTable:SetData(DatabaseModule.favoriteSearchesLists[arg1][1], true)

end

function OptionsPanelModule:FavoriteListsDropDown(frame, level, menuList)

	local info = UIDropDownMenu_CreateInfo()
	info.func = SelectList

	for key, value in pairs(DatabaseModule.favoriteSearchesLists) do
		for nestedKey, nestedValue in pairs(DatabaseModule.favoriteSearchesLists[key]) do
			if(nestedKey == "name") then
				info.text = DatabaseModule.favoriteSearchesLists[key][nestedKey]
				info.arg1 = key
				info.arg2 = nestedKey
				info.checked = OptionsPanelModule.favoriteLists.selectList.value == key
				UIDropDownMenu_AddButton(info)
			end
		end
	end
	
end

function OptionsPanelModule:CreateFavoriteSearchesScrollFrameTable(parentFrame, xPos, yPos)
	
	local columnType = {
		{
			name         = "List Elements",
			width        = 260,
			align        = "LEFT",
			index        = "searchName",
			format       = "string",
		}
	}
	
	parentFrame.favoriteSearchesTable = StdUi:ScrollTable(parentFrame, columnType, 8, 28)
	StdUi:GlueTop(parentFrame.favoriteSearchesTable, parentFrame, xPos,yPos, 0, 0)
	parentFrame.favoriteSearchesTable:EnableSelection(true)
	
end


