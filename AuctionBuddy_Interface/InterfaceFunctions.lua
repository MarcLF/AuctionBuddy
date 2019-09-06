-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local InterfaceFunctionsModule = AuctionBuddy:NewModule("InterfaceFunctionsModule", "AceEvent-3.0")

InterfaceFunctionsModule.switchingUI = false
InterfaceFunctionsModule.needToUpdateTotalCostText = false

local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil

function InterfaceFunctionsModule:OnInitialize()

	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")

end

function InterfaceFunctionsModule:AUCTION_ITEM_LIST_UPDATE()

	BuyInterfaceModule.mainFrame.currentPlayerGold.value = GetCoinTextureString(GetMoney(), 15)
	BuyInterfaceModule.mainFrame.currentPlayerGold:SetText(BuyInterfaceModule.mainFrame.currentPlayerGold.value)

	local valueGoldFormat = GetCoinTextureString(0, 15)
	BuyInterfaceModule.mainFrame.totalBuyCost:SetText(valueGoldFormat)
	
end

function InterfaceFunctionsModule:SetFrameParameters(frame, width, height, text, point, xOffSet, yOffSet, strata, relativeTo)

	if width ~= nil then 
		frame:SetWidth(width)
	end
	if height ~= nil then 
		frame:SetHeight(height)
	end
	if text ~= nil then 
		frame:SetText(text)
	end

	if relativeTo == nil then
		frame:SetPoint(point, xOffSet, yOffSet)
	else
		frame:SetPoint(point, relativeTo, "CENTER", xOffSet, yOffSet)
	end

	if strate ~= nil then 
		frame:SetFrameStrata(strata)
	end
	
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
	
	local stackSize = parentFrame.stackSize:GetText()
	local stackNumber = parentFrame.stackNumber:GetText()
	
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

function InterfaceFunctionsModule:UpdateTotalBuyoutCostBuy(selectedItemData, itemSelected)

	if itemSelected == true and self.needToUpdateTotalCostText == true then
		local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))
		
		local valueGoldFormat = GetCoinTextureString(buyoutPrice, 15)

		BuyInterfaceModule.mainFrame.totalBuyCost:SetText(valueGoldFormat)

	elseif self.needToUpdateTotalCostText == true then
		self:UpdateTotalBuyoutCostBuy(0)
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