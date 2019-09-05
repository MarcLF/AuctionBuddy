-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local BuyInterfaceDropDownMenusModule = AuctionBuddy:NewModule("BuyInterfaceDropDownMenusModule", "AceEvent-3.0")

local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil

local itemTypeTable = 
{
	[0] = "Any",
	"Weapon (All)",
	"Armor (All)",
	"Container (All)",
	"Gem (All)",
	"Item Enhancement (All)",
	"Consumable (All)",
	"Glyph (All)",
	"Trade Goods (All)",
	"Recipe (All)",
	"Battle Pet (All)",
	"Quest Item (All)",
	"Miscellaneous (All)"
}

-- Weapons Tables
local weaponsTypeTable =
{
	"One-Handed",
	"Two-Handed",
	"Ranged",
	"Misc Weapon"
}

local oneHandedWeaponsTable = 
{
	"O.H. Axes",
	"O.H. Maces",
	"O.H. Swords",	
	"Warglaives",
	"Daggers",
	"Fist Weapons",
	"Wands"
}

local twoHandedWeaponsTable = 
{
	"T.H Axes",
	"T.H Maces",
	"T.H Swords",	
	"Polearms",
	"Staves"
}

local rangedWeaponsTable = 
{
	"Bows",
	"Crossbows",
	"Guns",	
	"Thrown"
}

local miscellaneousWeaponsTable = 
{
	"Fishing Poles",
	"Other",
}
--

-- Armor Tables
local armorTypeTable =
{
	"Plate",
	"Mail",
	"Leather",
	"Cloth",
	"Misc Armor",
	"Cosmetic"
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
	"Hands"
}

local armorMiscTable = 
{
	"Neck",
	"Cloak",
	"Finger",
	"Trinket",
	"Held in Off-Hand",
	"Shield",
	"Shirt",
	"Head"
}
--

local containersTypeTable = 
{
	"Bag",
	"Herb Bag",
	"Enchanting Bag",
	"Engineering Bag",
	"Gem Bag",
	"Mining Bag",
	"Leatherworking Bag",
	"Inscription Bag",
	"Tackle Box",
	"Cooking Bag"
}

local gemsTypeTable =
{
	"Artifact Relic",
	"Intellect",
	"Agility",
	"Strength",
	"Stamina",
	"Critical Strike",
	"Mastery",
	"Haste",
	"Versatility",
	"Other",
	"Multiple Stats"
}

local itemEnhancementsTypeTable =
{
	"Head",
	"Neck",
	"Shoulder",
	"Cloak",
	"Chest",
	"Wrist",
	"Hands",
	"Waist",
	"Legs",
	"Feet",
	"Finger",
	"Weapon",
	"Two-Handed Weapon",
	"Shield/Off-hand",
	"Misc Enhance"
}

local consumablesTypeTable =
{
	"Explosives and Devices",
	"Potion",
	"Elixir",
	"Flask",
	"Food & Drink",
	"Bandage",
	"Vantus Runes",
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
	"Death Knight",
	"Monk",
	"Demon Hunter"
}

local tradeGoodsTypeTable =
{
	"Cloth Reagent",
	"Leather Reagent",
	"Metal & Stone",
	"Cooking Reagent",
	"Herb",
	"Enchanting Reagent",
	"Inscription",
	"Jewelcrafting",
	"Parts",
	"Elemental Reagent",
	"Other"
}

local recipesTypeTable =
{
	"Leatherworking",
	"Tailoring",
	"Engineering",
	"Blacksmithing",
	"Alchemy",
	"Enchanting",
	"Jewelcrafting",
	"Inscription",
	"Cooking",
	"First Aid",
	"Fishing",
	"Book"
}

local battlePetsTypeTable =
{
	"Humanoid",
	"Dragonkin",
	"Flying",
	"Undead",
	"Critter",
	"Magic",
	"Elemental",
	"Beast",
	"Aquatic",
	"Mechanical",
	"Companion Pets"
}

local miscTypeTable =
{
	"Junk",
	"Reagent",
	"Holiday",
	"Other",
	"Mount",
	"Mount Equipment"
}

local rarityTable = 
{
	[0] = "Any",
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Artifact"
}

function BuyInterfaceDropDownMenusModule:Enable()

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

				if key ~= 0 and itemTypeTable[key] ~= "Quest Item (All)" then
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

					if nestedTable == armorTypeTable or nestedTable == weaponsTypeTable then
					info.menuList, info.hasArrow = key, true
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

	local _, table = BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(UIDROPDOWNMENU_MENU_VALUE)

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

function BuyInterfaceDropDownMenusModule:GetNestedTableInfoFromMenuValue(menuValue)

	local itemTypeValue, nestedTable, nestedOfNestedTable = nil

	if menuValue == "Weapon (All)" or menuValue == "One-Handed" or menuValue == "Two-Handed" or menuValue == "Ranged" or menuValue == "Misc Weapon" then
		itemTypeValue = 1
		nestedTable = weaponsTypeTable
		
		if menuValue == "One-Handed" then
			nestedOfNestedTable = oneHandedWeaponsTable
		elseif menuValue == "Two-Handed" then
			nestedOfNestedTable = twoHandedWeaponsTable
		elseif menuValue == "Ranged" then
			nestedOfNestedTable = rangedWeaponsTable
		elseif menuValue == "Misc Weapon" then
			nestedOfNestedTable = miscellaneousWeaponsTable
		end	

	elseif menuValue == "Armor (All)" or menuValue == "Plate" or menuValue == "Mail" or menuValue == "Leather" or menuValue == "Cloth" or menuValue == "Misc Armor" or menuValue == "Cosmetic" then
		itemTypeValue = 2
		nestedTable = armorTypeTable
		
		if menuValue == "Plate" then
			nestedOfNestedTable = armorSlotsTable
		elseif menuValue == "Mail" then
			nestedOfNestedTable = armorSlotsTable
		elseif menuValue == "Leather" then
			nestedOfNestedTable = armorSlotsTable
		elseif menuValue == "Cloth" then
			nestedOfNestedTable = armorSlotsTable
		elseif menuValue == "Misc Armor" then
			nestedOfNestedTable = armorMiscTable
		elseif menuValue == "Cosmetic" then
			nestedOfNestedTable = {}
		end	

	elseif menuValue == "Container (All)" then

		itemTypeValue = 3
		nestedTable = containersTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Gem (All)" then
		itemTypeValue = 4
		nestedTable = gemsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Item Enhancement (All)" then
		itemTypeValue = 5
		nestedTable = itemEnhancementsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Consumable (All)" then
		itemTypeValue = 6
		nestedTable = consumablesTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Glyph (All)" then
		itemTypeValue = 7
		nestedTable = glyphsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Trade Goods (All)" then
		itemTypeValue = 8
		nestedTable = tradeGoodsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Recipe (All)" then
		itemTypeValue = 9
		nestedTable = recipesTypeTable
		nestedOfNestedTable = {}
	
	elseif menuValue == "Battle Pet (All)" then
		itemTypeValue = 10
		nestedTable = battlePetsTypeTable
		nestedOfNestedTable = {}

	elseif menuValue == "Miscellaneous (All)" then
		itemTypeValue = 12
		nestedTable = miscTypeTable
		nestedOfNestedTable = {}
	end

	return itemTypeValue, nestedTable, nestedOfNestedTable

end

function BuyInterfaceDropDownMenusModule:CreateRarityDropDownMenu(parentFrame)

	parentFrame.rarity = CreateFrame("Frame", "AB_BuyInterface_MainFrame_SlotType_DropDownMenu", parentFrame, "UIDropDownMenuTemplate")
	parentFrame.rarity:SetPoint("CENTER", parentFrame.iLvl, "CENTER", 275, -27)
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