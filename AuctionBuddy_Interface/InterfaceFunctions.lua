-- 
local AuctionBuddy = unpack(select(2, ...))

local InterfaceFunctionsModule = AuctionBuddy:NewModule("InterfaceFunctionsModule", "AceEvent-3.0")

InterfaceFunctionsModule.switchingUI = false
InterfaceFunctionsModule.needToUpdateTotalCostText = false
InterfaceFunctionsModule.autoCompleteTextPos = 1

local UtilsModule = nil
local DatabaseModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil

function InterfaceFunctionsModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterMessage("RESULTSTABLE_ITEM_SELECTED", self.OnResultsTableItemSelected)
	self:RegisterMessage("ON_STACK_SIZE_TEXT_CHANGED", self.OnStackSizeTextChanged)
	self:RegisterMessage("UPDATE_DEPOSIT_COST", self.UpdateDepositCost)

	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")

end

function InterfaceFunctionsModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	
end

function InterfaceFunctionsModule:AUCTION_ITEM_LIST_UPDATE()
	UtilsModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 2)

	C_Timer.After(0.5, function() 	
		BuyInterfaceModule.mainFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
		BuyInterfaceModule.mainFrame.currentPlayerGold:SetText(BuyInterfaceModule.mainFrame.currentPlayerGold.value)
	end)

	local valueGoldFormat = GetCoinTextureString(0, 15)
	BuyInterfaceModule.mainFrame.totalBidCost:SetText(valueGoldFormat)
	BuyInterfaceModule.mainFrame.totalBuyCost:SetText(valueGoldFormat)
	SellInterfaceModule.mainFrame.totalBidCost:SetText(valueGoldFormat)
	SellInterfaceModule.mainFrame.totalBuyCost:SetText(valueGoldFormat)
	
end

function InterfaceFunctionsModule:OnResultsTableItemSelected(parentFrame)
	UtilsModule:Log("InterfaceFunctionsModule", "OnResultsTableItemSelected", 2)

	InterfaceFunctionsModule:UpdateTotalBuyoutAndBidCostBuy(parentFrame)

end

function InterfaceFunctionsModule:OnStackSizeTextChanged(itemPriceFrame, stackPriceFrame, stackSizeFrame)
	UtilsModule:Log("InterfaceFunctionsModule", "OnStackSizeTextChanged", 2)

	if DatabaseModule.sellOptions.stackPriceFixed == true then
		InterfaceFunctionsModule:StackPriceUpdated(stackPriceFrame, stackSizeFrame, itemPriceFrame)
	else
		InterfaceFunctionsModule:ItemPriceUpdated(itemPriceFrame, stackSizeFrame, stackPriceFrame) 
	end

end

function InterfaceFunctionsModule:CloseAuctionHouseCustom()
	UtilsModule:Log(self, "CloseAuctionHouseCustom", 2)

	if self.switchingUI == false and SellInterfaceModule.interfaceCreated == true and BuyInterfaceModule.interfaceCreated == true then
		CloseAuctionHouse()
	end

end

function InterfaceFunctionsModule:UpdateDepositCost(parentFrame)
	UtilsModule:Log(self, "UpdateDepositCost", 2)
	
	local itemPrice = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)

	local stackSize = parentFrame.stackSize:GetNumber()
	local stackNumber = parentFrame.stackQuantity:GetNumber()

	local depositCost = GetAuctionDeposit(SellInterfaceModule.mainFrame.auctionDuration.durationValue, itemPrice, stackPrice, stackSize, stackNumber)

	parentFrame.auctionDepositCost.value = GetCoinTextureString(depositCost, 15)
	parentFrame.auctionDepositCost:SetText(parentFrame.auctionDepositCost.value)

end

function InterfaceFunctionsModule:StackPriceUpdated(stackPriceFrame, stackSizeFrame, itemPriceFrame)
	UtilsModule:Log(self, "StackPriceUpdated", 2)

	local stackPrice = MoneyInputFrame_GetCopper(stackPriceFrame)
	local stackSize = math.max(stackSizeFrame:GetNumber(), 1)
	
	if stackSize ~= nil then
		local newStackPrice = math.floor(stackPrice/stackSize)
		
		MoneyInputFrame_SetCopper(itemPriceFrame, newStackPrice)
	end

end

function InterfaceFunctionsModule:ItemPriceUpdated(itemPriceFrame, stackSizeFrame, stackPriceFrame)
	UtilsModule:Log(self, "ItemPriceUpdated", 2)

	local itemPrice = MoneyInputFrame_GetCopper(itemPriceFrame)
	local stackSize = math.max(stackSizeFrame:GetNumber(), 1)
	
	if stackSize ~= nil then
		local newItemPrice = math.floor(itemPrice*stackSize)
	
		MoneyInputFrame_SetCopper(stackPriceFrame, newItemPrice)	
	end
	
end

function InterfaceFunctionsModule:UpdateTotalBuyoutAndBidCostBuy(parentFrame)
	UtilsModule:Log(self, "UpdateTotalBuyoutAndBidCostBuy", 2)

	local selectedItemData = parentFrame.scrollTable:GetSelection()

	local minBid = select(8, GetAuctionItemInfo("list", selectedItemData))
	local minBidIncrement = select(9, GetAuctionItemInfo("list", selectedItemData))
	local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))
	local bidAmount = select(11, GetAuctionItemInfo("list", selectedItemData))
	local highBidder = select(12, GetAuctionItemInfo("list", selectedItemData))

	local totalAmountToBid = max(minBid, bidAmount) + minBidIncrement

	local bidValueGoldFormat = GetCoinTextureString(totalAmountToBid, 15)
	local buyValueGoldFormat = GetCoinTextureString(buyoutPrice, 15)

	parentFrame.totalBidCost:SetText(bidValueGoldFormat)
	parentFrame.totalBuyCost:SetText(buyValueGoldFormat)

	if highBidder then
		parentFrame.alreadyBidText:Show()
	else
		parentFrame.alreadyBidText:Hide()
	end

end

function InterfaceFunctionsModule:ReturnIndexGivenTableValue(tableValue, table)
	UtilsModule:Log(self, "ReturnIndexGivenTableValue", 2)

	for key,value in pairs(table) do
		if table[key] == tableValue then
			return key	
		end
	end

end

function InterfaceFunctionsModule:AutoCompleteText(frame, text)
	UtilsModule:Log(self, "AutoCompleteText", 3)

	for key,value in pairs(DatabaseModule.recentSearches) do
		for nestedKey, nestedValue in pairs(DatabaseModule.recentSearches[key]) do
			local modNestedValue = string.sub(nestedValue, 0, InterfaceFunctionsModule.autoCompleteTextPos)
			local modText = string.sub(text, 0, InterfaceFunctionsModule.autoCompleteTextPos)
			if (DatabaseModule.recentSearches[key][nestedKey] and string.match(strupper(modNestedValue), strupper(modText))) then
				frame:SetText(nestedValue)
				frame:HighlightText(InterfaceFunctionsModule.autoCompleteTextPos, -1)
				return
			end
		end
	end

end