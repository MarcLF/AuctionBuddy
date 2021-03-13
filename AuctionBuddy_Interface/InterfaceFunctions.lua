-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local InterfaceFunctionsModule = AuctionBuddy:NewModule("InterfaceFunctionsModule", "AceEvent-3.0")

InterfaceFunctionsModule.switchingUI = false
InterfaceFunctionsModule.needToUpdateTotalCostText = false
InterfaceFunctionsModule.autoCompleteTextPos = 1

local DebugModule = nil
local DatabaseModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil

function InterfaceFunctionsModule:OnInitialize()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable")

	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")

end

function InterfaceFunctionsModule:AUCTION_ITEM_LIST_UPDATE()

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

function InterfaceFunctionsModule:CloseAuctionHouseCustom()

	if self.switchingUI == false and SellInterfaceModule.interfaceCreated == true and BuyInterfaceModule.interfaceCreated == true then
		CloseAuctionHouse()
	end

end

function InterfaceFunctionsModule:ChangeCurrentDisplayingFrame(currentFrame)

	self.switchingUI = true
	currentFrame:Hide()
	
	if currentFrame == SellInterfaceModule.mainFrame then
		BuyInterfaceModule.mainFrame:Show()
	else
		SellInterfaceModule.mainFrame:Show()
	end

	self.switchingUI = false

end

function InterfaceFunctionsModule:ShowDefaultAH(currentFrame)

	self.switchingUI = true
	currentFrame:Hide()
	self.switchingUI = false

end

function InterfaceFunctionsModule:UpdateDepositCost(parentFrame)
	
	local itemPrice = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	
	local stackSize = tonumber(parentFrame.stackSize:GetText())
	local stackNumber = tonumber(parentFrame.stackNumber:GetText())

	local depositCost = GetAuctionDeposit(SellInterfaceModule.mainFrame.auctionDuration.durationValue, itemPrice, stackPrice, stackSize, stackNumber)

	parentFrame.auctionDepositCost.value = GetCoinTextureString(depositCost, 15)
	parentFrame.auctionDepositCost:SetText(parentFrame.auctionDepositCost.value)

end

function InterfaceFunctionsModule:StackPriceUpdated(parentFrame)

	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	local stackSize = parentFrame.stackSize:GetNumber()
	
	if stackSize ~= nil then
		local newStackPrice = math.floor(stackPrice/stackSize)
	
		MoneyInputFrame_SetCopper(parentFrame.itemPrice, newStackPrice)
		SellInterfaceModule.stackPriceValue = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	end
	
	self:UpdateDepositCost(parentFrame)

end

function InterfaceFunctionsModule:ItemPriceUpdated(parentFrame)

	local itemPrice = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	local stackSize = parentFrame.stackSize:GetNumber()
	
	if stackSize ~= nil then
		local newItemPrice = math.floor(itemPrice*stackSize)
	
		MoneyInputFrame_SetCopper(parentFrame.stackPrice, newItemPrice)	
		SellInterfaceModule.itemPriceValue = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	end
	
	self:UpdateDepositCost(parentFrame)
	
end

function InterfaceFunctionsModule:UpdateTotalBuyoutOrBidCostBuy(selectedItemData, itemSelected)

	if itemSelected == true and self.needToUpdateTotalCostText == true then

		local minBid = select(8, GetAuctionItemInfo("list", selectedItemData))
		local minBidIncrement = select(9, GetAuctionItemInfo("list", selectedItemData))
		local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))
		local bidAmount = select(11, GetAuctionItemInfo("list", selectedItemData))
		local highBidder = select(12, GetAuctionItemInfo("list", selectedItemData))

		local totalAmountToBid = max(minBid, bidAmount) + minBidIncrement

		local bidValueGoldFormat = GetCoinTextureString(totalAmountToBid, 15)
		local buyValueGoldFormat = GetCoinTextureString(buyoutPrice, 15)

		if BuyInterfaceModule.mainFrame:IsShown() then
			BuyInterfaceModule.mainFrame.totalBidCost:SetText(bidValueGoldFormat)
			BuyInterfaceModule.mainFrame.totalBuyCost:SetText(buyValueGoldFormat)

			if highBidder then
				BuyInterfaceModule.mainFrame.alreadyBidText:Show()
			else
				BuyInterfaceModule.mainFrame.alreadyBidText:Hide()
			end

		elseif SellInterfaceModule.mainFrame:IsShown() then
			SellInterfaceModule.mainFrame.totalBidCost:SetText(bidValueGoldFormat)
			SellInterfaceModule.mainFrame.totalBuyCost:SetText(buyValueGoldFormat)

			if highBidder then
				SellInterfaceModule.mainFrame.alreadyBidText:Show()
			else
				SellInterfaceModule.mainFrame.alreadyBidText:Hide()
			end
		end	

	elseif self.needToUpdateTotalCostText == true then
		self:UpdateTotalBuyoutOrBidCostBuy(0)
	end

	self.needToUpdateTotalCostText = false

end

function InterfaceFunctionsModule:ReturnIndexGivenTableValue(tableValue, table)

	for key,value in pairs(table) do
		if table[key] == tableValue then
			return key	
		end
	end

end

function InterfaceFunctionsModule:AutoCompleteText(frame, text)

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