--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ItemsModule = AuctionBuddy:NewModule("ItemsModule", "AceEvent-3.0")

ItemsModule.currentItemPostedLink = nil

local DebugModule = nil
local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

function ItemsModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterMessage("CONTAINER_ITEM_SELECTED", self.OnContainerItemSelected)
	self:RegisterMessage("ON_CLICK_ITEM_TO_SELL", self.OnClickItemToSell)
	self:RegisterMessage("ON_BID_SELECTED_ITEM", self.OnBidSelectedItem)
	self:RegisterMessage("ON_BUY_SELECTED_ITEM", self.OnBuySelectedItem)
	self:RegisterMessage("ON_SELL_SELECTED_ITEM", self.OnSellSelectedItem)
	self:RegisterMessage("UPDATE_MAX_STACK_VALUES", self.UpdateMaxStackValues)
	self:RegisterMessage("ON_CLICK_MAX_STACK_SIZE", self.OnClickMaxStackSize)
	self:RegisterMessage("ON_CLICK_MAX_STACK_QUANTITY", self.OnClickMaxStackQuantity)
	self:RegisterMessage("SHOW_AB_BUY_FRAME", self.RemoveInsertedItem)
	
end

function ItemsModule:AUCTION_HOUSE_CLOSED()
	DebugModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	if ItemsModule.currentItemPostedLink ~= nil then
		PickupItem(ItemsModule.currentItemPostedLink) 
		ItemsModule:RemoveInsertedItem()
	end

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	
end

function ItemsModule:AUCTION_ITEM_LIST_UPDATE()
	DebugModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 1)

	self.shown, self.total = GetNumAuctionItems("list")

	if BuyInterfaceModule.mainFrame:IsShown() then
		ItemsModule:CreateAuctionItemButtons(self.shown, BuyInterfaceModule.mainFrame.scrollTable)
	elseif SellInterfaceModule.mainFrame:IsShown() then
		ItemsModule:CreateAuctionItemButtons(self.shown, SellInterfaceModule.mainFrame.scrollTable)
		if self.total > 0 then 
			ItemsModule:UpdateSellItemPriceAfterSearch(1,  self.shown, self.total)
		end
	end
	
end

function ItemsModule:OnContainerItemSelected(parentFrame, bagID, bagSlot)
	DebugModule:Log(self, "OnContainerItemSelected", 1)

	ItemsModule:InsertSelectedItem(parentFrame)
	ItemsModule:CalculateMaxStackValues(parentFrame, bagID, bagSlot)

end

function ItemsModule:OnClickItemToSell(frameClicked)
	DebugModule:Log("ItemsModule", "OnClickItemToSell", 1)

	if CursorHasItem() == false then
		PickupItem(ItemsModule.currentItemPostedLink) 
		ItemsModule:RemoveInsertedItem()
	else
		ItemsModule:AddCursorItem(frameClicked)
	end

end

function ItemsModule:OnBidSelectedItem(selectedItemData)
	DebugModule:Log("ItemsModule", "OnBidSelectedItem", 1)

	local bidAmount = select(11, GetAuctionItemInfo("list", selectedItemData))
	local minIncrement = select(9, GetAuctionItemInfo("list", selectedItemData))
	local minBid = select(8, GetAuctionItemInfo("list", selectedItemData))

	local totalAmountToBid = max(bidAmount, minBid) + minIncrement

	PlaceAuctionBid('list', selectedItemData, totalAmountToBid)
	--Refresh ResultsTable by doing a nil AH search
	if GetMoney() > totalAmountToBid then
		AuctionBuddy:AuctionHouseSearch(nil)
	end

end

function ItemsModule:OnBuySelectedItem(selectedItemData)
	DebugModule:Log(self, "BuySelectedItem", 2)
	
	local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))

	PlaceAuctionBid('list', selectedItemData, buyoutPrice)
	
end

function ItemsModule:OnSellSelectedItem(parentFrame)
	DebugModule:Log(self, "SellSelectedItem", 2)

	local stackPriceBid =  MoneyInputFrame_GetCopper(parentFrame.itemPriceBid)

	local itemPrice = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	
	local stackSize = parentFrame.stackSize:GetText()
	local stackNumber = parentFrame.stackQuantity:GetText()
	
	if (tonumber(stackSize) > 0 and tonumber(stackNumber) > 0) then
		PostAuction(stackPriceBid, stackPrice, parentFrame.auctionDuration.durationValue, stackSize, stackNumber)
	else
		print("AuctionBuddy: Can't place auctions without a valid stack size and quantity.")
	end

	PickupItem(ItemsModule.currentItemPostedLink) 
	ItemsModule:RemoveInsertedItem(parentFrame)
	
end

function ItemsModule:CreateAuctionItemButtons(itemsShown, scrollTable)
	DebugModule:Log(self, "CreateAuctionItemButtons", 2)

	local tableData = {}
	
	for i = 1, itemsShown do
		local itemName, myTexture, aucCount, itemQuality, canUse, itemLevel, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);
		
		local buyOutPerItem = buyoutPrice/aucCount
		local totalBidItem

		if bidAmount > 0 then
			totalBidItem = bidAmount
		else
			totalBidItem = minBid
		end

		-- This data is compared to each index of columnType array from the CreateResultsScrollFrameTable function inside ResultsTable.lua
		tinsert(tableData, 
		{
			texture = myTexture,
			itemLink = tostring(GetAuctionItemLink("list", i)),
			name = itemName,
			owner = tostring(aucOwner),
			count = aucCount,
			quality = itemQuality,
			itlvl = itemLevel,
			bid = totalBidItem,
			buy = buyOutPerItem,
			totalPrice = buyoutPrice
		})
	end
	
	scrollTable:Show()
	scrollTable:SetData(tableData, true)
	
end

function ItemsModule:UpdateSellItemPriceAfterSearch(numberList, shown, total)
	DebugModule:Log(self, "UpdateSellItemPriceAfterSearch", 2)
	
	local buyoutPrice = select(10, GetAuctionItemInfo("list", numberList))
	local itemQuantity = select(3, GetAuctionItemInfo("list", numberList))

	local priceToSell = math.floor(buyoutPrice/itemQuantity) - 1

	if buyoutPrice == 0 and total > 1 and numberList < shown then
		numberList = numberList + 1
		self:UpdateSellItemPriceAfterSearch(numberList, shown, total)
	else
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPrice, priceToSell)
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPriceBid, priceToSell)
	end
	
end

function ItemsModule:SearchSelectedContainerItem()
	DebugModule:Log(self, "SearchSelectedContainerItem", 2)
	
	infoType, info1, info2 = GetCursorInfo()
	local itemName = GetItemInfo(info2) 
	ClearCursor()
	AuctionBuddy:AuctionHouseSearch(itemName)
	
end

function ItemsModule:InsertSelectedItem(parentFrame)
	DebugModule:Log(self, "InsertSelectedItem", 2)
		
	infoType, info1, info2 = GetCursorInfo()
	
	ItemsModule.currentItemPostedLink = info2
	local buttonCurrentText = parentFrame.itemToSellButton.text:GetText()

	if infoType == "item" and buttonCurrentText ~= info2 then
		parentFrame.itemToSellButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetHyperlink(info2)
		end)
		parentFrame.itemToSellButton:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
		
		itemIcon = GetItemIcon(info1)
		parentFrame.itemToSellButton.itemTexture:SetWidth(37)
		parentFrame.itemToSellButton.itemTexture:SetHeight(37)
		parentFrame.itemToSellButton.itemTexture:SetTexture(itemIcon)
		parentFrame.itemToSellButton.text:SetText(info2)
		
		parentFrame.stackQuantity:SetText(1)
		parentFrame.stackSize:SetText(1)
		
		local itemName = GetItemInfo(info2) 
		AuctionBuddy:AuctionHouseSearch(itemName, true)		
					
		ClickAuctionSellItemButton()
		
		InterfaceFunctionsModule:UpdateDepositCost(SellInterfaceModule.mainFrame)

		parentFrame.createAuction:Enable()
	end

	ClearCursor()	

end

function ItemsModule:CalculateMaxStackValues(parentFrame, bagID, bagSlot)
	DebugModule:Log(self, "CalculateMaxStackValues", 0)

	local itemAmountInBag = 0
	local itemLink = select(7, GetContainerItemInfo(bagID, bagSlot))
	
	local itemStackCount = select(8, GetItemInfo(itemLink))

	itemAmountInBag = ItemsModule:GetTotalItemAmountInBag(parentFrame, itemLink)

	local maxStackSizeValue = math.min(itemAmountInBag, itemStackCount)
	local maxStackNumberValue = math.max(math.floor(itemAmountInBag / tonumber(parentFrame.stackSize:GetText())), 1)

	parentFrame.stackSize.maxStackValue:SetText(tostring(maxStackSizeValue))
	parentFrame.stackQuantity.maxStackValue:SetText(tostring(maxStackNumberValue))

	parentFrame.stackSize.maxStackBtn:Enable()
	parentFrame.stackQuantity.maxStackBtn:Enable()

end

function ItemsModule:UpdateMaxStackValues(parentFrame)
	DebugModule:Log(self, "CalculateMaxStackValues", 0)

	local itemLink = parentFrame.itemToSellButton.text:GetText()
	local itemAmountInBag = 0
	itemAmountInBag = ItemsModule:GetTotalItemAmountInBag(parentFrame, itemLink)

	local itemStackCount = select(8, GetItemInfo(itemLink)) or 1

	local stackSizeValue = 1
	local stackQuantityValue = 1

	if parentFrame.stackSize:GetText() ~= "" then
		stackSizeValue = tonumber(parentFrame.stackSize:GetText())
	end

	if parentFrame.stackQuantity:GetText() ~= "" then
		stackQuantityValue = tonumber(parentFrame.stackQuantity:GetText())
	end

	local maxStackSizeValue = math.max(math.floor(itemAmountInBag / stackQuantityValue), 1)
	local maxStackQuantityValue = itemAmountInBag

	maxStackSizeValue = math.min(maxStackSizeValue, itemStackCount)
	maxStackQuantityValue = math.floor(math.max(maxStackQuantityValue / stackSizeValue, 1))

	parentFrame.stackSize.maxStackValue:SetText(tostring(maxStackSizeValue))
	parentFrame.stackQuantity.maxStackValue:SetText(tostring(maxStackQuantityValue))

end

function ItemsModule:OnClickMaxStackSize(parentFrame)
	DebugModule:Log(self, "OnClickMaxStackSize", 0)

	parentFrame.stackSize:SetText(parentFrame.stackSize.maxStackValue:GetText())

end

function ItemsModule:OnClickMaxStackQuantity(parentFrame)
	DebugModule:Log(self, "OnClickMaxStackQuantity", 0)

	parentFrame.stackQuantity:SetText(parentFrame.stackQuantity.maxStackValue:GetText())

end

function ItemsModule:GetTotalItemAmountInBag(parentFrame, itemLink)
	
	local itemAmountInBag = 0

	for index, data in ipairs(parentFrame.scrollTableContainer.data) do
		local totalBagItemAmount = 0
		local bagItemName = nil
		for key, value in pairs(data) do
			if tostring(key) == "count" then
				totalBagItemAmount = totalBagItemAmount + value
			end
			if tostring(key) == "itemLink" then
				bagItemName = value
			end
		end

		if tostring(bagItemName) == itemLink then
			itemAmountInBag = itemAmountInBag + totalBagItemAmount
		end
	end

	return itemAmountInBag

end

function ItemsModule:RemoveInsertedItem()
	DebugModule:Log(self, "RemoveInsertedItem", 2)
	
	infoType, info1, info2 = GetCursorInfo()

	ItemsModule.currentItemPostedLink = nil
		
	ClickAuctionSellItemButton(false)
	ClearCursor()

end

function ItemsModule:ShowToolTip(frame, link, show)
	DebugModule:Log(self, "ShowToolTip", 3)

	if show == true then
		GameTooltip:SetOwner(frame)
		GameTooltip:SetHyperlink(link)	
		GameTooltip:Show()	
	else
		GameTooltip:Hide()
	end
	
end

function ItemsModule:AddCursorItem(frame)
	DebugModule:Log(self, "AddCursorItem", 2)

	local infoType, info1, info2 = GetCursorInfo()
	local bindType = select(14, GetItemInfo(info2))
	if bindType ~= 1 then
		ItemsModule:InsertSelectedItem(frame.mainFrame)
	else
		print("AuctionBuddy: Can't auction Soulbound items")
	end

end