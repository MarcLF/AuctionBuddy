-- 
local AuctionBuddy = unpack(select(2, ...))

local BuyInterfaceDropDownMenusModule = AuctionBuddy:NewModule("BuyInterfaceDropDownMenusModule", "AceEvent-3.0")

local UtilsModule = nil
local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil

local itemTypeTable = 
{
	[0] = "Any",
	"Weapon (All)",
	"Armor (All)",
	"Container (All)",
	"Consumable (All)",
	"Glyphs (All)",
	"Trade Goods (All)",
	"Projectile (All)",
	"Quiver (All)",
	"Recipe (All)",
	"Gems",
	"Miscellaneous (All)",
	"Quest Items"
}

local weaponsTypeTable = 
{
	"O.H. Axes",
	"T.H Axes",
	"Bows",
	"Guns",
	"O.H. Maces",
	"T.H Maces",
	"Polearms",
	"O.H. Swords",	
	"T.H Swords",
	"Staves",
	"Fist Weapons",
	"Miscellaneous",
	"Daggers",
	"Thrown",
	"Crossbows",
	"Wands",
	"Fishing Pole"
}

-- Armor Tables
local armorTypeTable =
{
	"Miscellaneous",
	"Cloth",
	"Leather",
	"Mail",
	"Plate",
	"Shields",
	"Librams",
	"Idols",
	"Totems"
}

local armorSlotsTable =
{
	"Head",
	"Shoulder",
	"Chest",
	"Waist",
	"Legs",
	"Feet",
	"Wrist",
	"Hands",
	"Back"
}

local armorMiscellaneousSlotsTable =
{
	"Head",
	"Neck",
	"Shirt",
	"Finger",
	"Trinket",
	"Held In Off-hand"
}
--

local containersTypeTable = 
{
	"Bag",
	"Soul Bag",
	"Herb Bag",
	"Enchanting Bag",
	"Engineering Bag",
	"Gem Bag",
	"Mining Bag",
	"Leatherworking Bag",
	"Inscription Bag"
}

local consumableTypeTable = 
{
	"Food & Drink",
	"Potion",
	"Elixir",
	"Flask",
	"Bandage",
	"Item Enhancement",
	"Scroll",
	"Other"
}

local glyphsTypeTable = 
{
	"Warrior",
	"Paladin",
	"Hunter",
	"Rogue",
	"Priest",
	"Shaman",
	"Mage",
	"Warlock",
	"Druid",
	"Death Knight"
}

local tradeGoodsTypeTable = 
{
	"Elemental",
	"Cloth",
	"Leather",
	"Metal & Stone",
	"Meat",
	"Enchanting",
	"Jewelcrafting",
	"Parts",
	"Devices",
	"Explosives",
	"Materials",
	"Other",
	"Armor Enchantment",
	"Weapon Enchantment"
}

local projectileTable = 
{
	"Arrow",
	"Bullet"
}

local quiverTable = 
{
	"Quiver",
	"Ammo Pouch"
}

local recipesTypeTable =
{
	"Book",
	"Leatherworking",
	"Tailoring",
	"Engineering",
	"Blacksmithing",
	"Cooking",
	"Alchemy",
	"First Aid",
	"Enchanting",
	"Fishing",
	"Jewelcrafting",
	"Inscription"
}

local gemsTypeTable =
{
	"Red",
	"Blue",
	"Yellow",
	"Purple",
	"Green",
	"Orange",
	"Meta",
	"Simple",
	"Prismatic"
}

local miscellaneousTypeTable =
{
	"Junk",
	"Reagent",
	"Pet",
	"Holiday",
	"Other",
	"Mount"
}

local rarityTable = 
{
	[0] = "Any",
	"Common",
	"Uncommon",
	"Rare",
	"Epic"
}

function BuyInterfaceDropDownMenusModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")

	if self.dropDownMenusCreated == true then
		return
	end

	self:CreateItemClassDropDownMenu(BuyInterfaceModule.mainFrame)
	self:CreateRarityDropDownMenu(BuyInterfaceModule.mainFrame)

	self.dropDownMenusCreated = true

end

function BuyInterfaceDropDownMenusModule:CreateItemClassDropDownMenu(parentFrame)

	parentFrame.itemClasses = CreateFrame("Frame", "AB_BuyInterface_MainFrame_ItemClasses_DropDownMenu", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.itemClasses:SetPoint("CENTER", parentFrame.iLvl, "CENTER", 125, -27)
	parentFrame.itemClasses.value = 0
	parentFrame.itemClasses.valueSubList = nil
	parentFrame.itemClasses.valueSubSubList = nil
	parentFrame.itemClasses.text = "Any"
	UIDropDownMenu_SetWidth(parentFrame.itemClasses, 100)
	UIDropDownMenu_SetText(parentFrame.itemClasses, parentFrame.itemClasses.text) 
	UIDropDownMenu_Initialize(parentFrame.itemClasses, function(self, level, menuList)
	
		local info = UIDropDownMenu_CreateInfo()

		if (level or 1) == 1 then
			for key = 0, #itemTypeTable do
				info.func = BuyInterfaceDropDownMenusModule.SelectItemClassType
				info.text = itemTypeTable[key]
				info.arg1 = key		
				info.checked = BuyInterfaceModule.mainFrame.itemClasses.value == key

				if key ~= 0 and itemTypeTable[key] ~= "Quest Items" then
					info.menuList, info.hasArrow = key, true
				else
					info.hasArrow = false
				end

				UIDropDownMenu_AddButton(info)	
			end
		elseif level == 2 then
			local _, nestedTable = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE)

			for key = 1, #nestedTable do	
				info.func = BuyInterfaceDropDownMenusModule.SelectItemClassSubMenuType
				info.text = nestedTable[key]
				info.arg1 = key
				info.arg2 = InterfaceFunctionsModule:ReturnIndexGivenTableValue(UIDROPDOWNMENU_MENU_VALUE, itemTypeTable)
				info.checked = BuyInterfaceModule.mainFrame.itemClasses.valueSubList == key

					if nestedTable == armorTypeTable and nestedTable[key] ~= "Shields" 
					and nestedTable[key] ~= "Librams" and nestedTable[key] ~= "Idols" 
					and nestedTable[key] ~= "Totems" then
						info.menuList, info.hasArrow = key, true
					else
						info.hasArrow = false
					end

				UIDropDownMenu_AddButton(info, level)
			end
		else
			local _, parentOfNestedTableTable, nestedTable = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE)

			for key = 1, #nestedTable do	
				info.func = BuyInterfaceDropDownMenusModule.SelectItemClassSubSubMenuType
				info.text = nestedTable[key]
				info.arg1 = key
				info.arg2 = InterfaceFunctionsModule:ReturnIndexGivenTableValue(UIDROPDOWNMENU_MENU_VALUE, parentOfNestedTableTable)
				info.checked = BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList == key
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end)

end

function BuyInterfaceDropDownMenusModule:SelectItemClassType(arg1, checked)

	BuyInterfaceModule.mainFrame.itemClasses.value = arg1
	BuyInterfaceModule.mainFrame.itemClasses.valueSubList = nil
	BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList = nil

	UIDropDownMenu_SetText(BuyInterfaceModule.mainFrame.itemClasses, itemTypeTable[arg1])

end

function BuyInterfaceDropDownMenusModule:SelectItemClassSubMenuType(arg1, arg2, checked)

	BuyInterfaceModule.mainFrame.itemClasses.value = arg2
	BuyInterfaceModule.mainFrame.itemClasses.valueSubList = arg1
	BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList = nil

	local isSubList = true

	local _, table = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE, isSubList)

	UIDropDownMenu_SetText(BuyInterfaceModule.mainFrame.itemClasses, table[arg1])
	CloseDropDownMenus()

end

function BuyInterfaceDropDownMenusModule:SelectItemClassSubSubMenuType(arg1, arg2, checked)

	BuyInterfaceModule.mainFrame.itemClasses.value = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE)
	BuyInterfaceModule.mainFrame.itemClasses.valueSubList = arg2
	BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList = arg1

	local _, _,table = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE)

	UIDropDownMenu_SetText(BuyInterfaceModule.mainFrame.itemClasses, table[arg1])
	CloseDropDownMenus()

end

function BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(menuValue, level, isSubList)

	local itemTypeValue, nestedTable, nestedOfNestedTable = nil

	--TODO: Improve this code, i.e replace all these or = x for a loop
	if menuValue == "Weapon (All)" then
		itemTypeValue = 1
		nestedTable = weaponsTypeTable

	elseif menuValue == "Armor (All)" or menuValue == "Miscellaneous" or menuValue == "Plate" or menuValue == "Mail" or menuValue == "Leather" 
	or menuValue == "Cloth" or menuValue == "Idols" or menuValue == "Librams" or menuValue == "Totems" or menuValue == "Shields" then
		itemTypeValue = 2
		nestedTable = armorTypeTable
		
		if menuValue == "Cloth" or menuValue == "Leather" or menuValue == "Mail" or menuValue == "Plate" then
			nestedOfNestedTable = armorSlotsTable
		elseif menuValue == "Miscellaneous" then
			nestedOfNestedTable = armorMiscellaneousSlotsTable
		else
			nestedOfNestedTable = {}
		end	

	elseif menuValue == "Container (All)" then
		itemTypeValue = 3
		nestedTable = containersTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Consumable (All)" then
		itemTypeValue = 4
		nestedTable = consumableTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Glyphs (All)" then
		itemTypeValue = 5
		nestedTable = glyphsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Trade Goods (All)" then
		itemTypeValue = 6
		nestedTable = tradeGoodsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Projectile (All)" then
		itemTypeValue = 7
		nestedTable = projectileTable
		nestedOfNestedTable = {}

	elseif menuValue == "Quiver (All)" then
		itemTypeValue = 8
		nestedTable = quiverTable
		nestedOfNestedTable = {}

	elseif menuValue == "Recipe (All)" then
		itemTypeValue = 9
		nestedTable = recipesTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Gems" then
		itemTypeValue = 10
		nestedTable = gemsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Miscellaneous (All)" then
		itemTypeValue = 11
		nestedTable = miscellaneousTypeTable
		nestedOfNestedTable = {}
	end

	return itemTypeValue, nestedTable, nestedOfNestedTable

end

function BuyInterfaceDropDownMenusModule:CreateRarityDropDownMenu(parentFrame)

	parentFrame.rarity = CreateFrame("Frame", "AB_BuyInterface_MainFrame_SlotType_DropDownMenu", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.rarity:SetPoint("CENTER", parentFrame.iLvl, "CENTER", 271, -27)
	parentFrame.rarity.value = 0
	parentFrame.rarity.text = "Any"
	UIDropDownMenu_SetWidth(parentFrame.rarity, 100)
	UIDropDownMenu_SetText(parentFrame.rarity, parentFrame.rarity.text) 
	UIDropDownMenu_Initialize(parentFrame.rarity, BuyInterfaceDropDownMenusModule.RarityDropDown)

end

local function SelectRarity(self, arg1, checked)

	BuyInterfaceModule.mainFrame.rarity.value = arg1
	UIDropDownMenu_SetText(BuyInterfaceModule.mainFrame.rarity, rarityTable[arg1])

end

function BuyInterfaceDropDownMenusModule:RarityDropDown(frame, level, menuList)

	local info = UIDropDownMenu_CreateInfo()
	info.func = SelectRarity

	for key = 0, #rarityTable do
		info.text = rarityTable[key]
		info.arg1 = key
		info.checked = BuyInterfaceModule.mainFrame.rarity.value == key
		UIDropDownMenu_AddButton(info)
	end
	
end