--
local AuctionBuddy = unpack(select(2, ...))

local ItemsModule = AuctionBuddy:NewModule("ItemsModule", "AceEvent-3.0")

ItemsModule.currentItemPostedLink = nil

local UtilsModule = nil
local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

local selectedItemPos = nil
local selectedBuyoutPrice = nil
local selectedTotalAmountToBid = nil
local selectedStackSize = nil
local selectedItemName = nil
local scrollTableSelectedID = nil

function ItemsModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")

	self:RegisterMessage("CONTAINER_ITEM_SELECTED", self.OnContainerItemSelected)
	self:RegisterMessage("ON_CLICK_ITEM_TO_SELL", self.OnClickItemToSell)
	self:RegisterMessage("ON_BID_SELECTED_ITEM", self.OnBidSelectedItem)
	self:RegisterMessage("ON_BUY_SELECTED_ITEM", self.OnBuySelectedItem)
	self:RegisterMessage("ON_SELL_SELECTED_ITEM", self.OnSellSelectedItem)
	self:RegisterMessage("UPDATE_MAX_STACK_VALUES", self.UpdateMaxStackValues)
	self:RegisterMessage("ON_CLICK_MAX_STACK_SIZE", self.OnClickMaxStackSize)
	self:RegisterMessage("ON_CLICK_MAX_STACK_QUANTITY", self.OnClickMaxStackQuantity)
	self:RegisterMessage("REMOVE_INSERTED_ITEM", self.RemoveInsertedItem)
	self:RegisterMessage("UPDATE_SELL_ITEM_PRICE", self.UpdateSellItemPriceAfterSearch)
	self:RegisterMessage("ITEM_SELECTED_DATA", self.UpdateItemSelectedData)
	
end

function ItemsModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	if ItemsModule.currentItemPostedLink ~= nil then
		PickupItem(ItemsModule.currentItemPostedLink) 
		ItemsModule:RemoveInsertedItem()
	end

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	
end

function ItemsModule:OnContainerItemSelected(parentFrame, bagID, bagSlot)
	UtilsModule:Log(self, "OnContainerItemSelected", 1)

	ItemsModule:InsertSelectedItem(parentFrame)
	ItemsModule:CalculateMaxStackValues(parentFrame, bagID, bagSlot)

end

function ItemsModule:OnClickItemToSell(frameClicked)
	UtilsModule:Log("ItemsModule", "OnClickItemToSell", 1)

	if CursorHasItem() == false then
		PickupItem(ItemsModule.currentItemPostedLink) 
		ItemsModule:RemoveInsertedItem()
	else
		ItemsModule:AddCursorItem(frameClicked)
	end

end

function ItemsModule:OnBidSelectedItem()
	UtilsModule:Log(self, "OnBidSelectedItem", 0)

	if selectedItemPos == nil then
		return
	end

	local itemName, myTexture, stackSize, itemQuality, canUse, itemLevel, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", selectedItemPos);

	local itemsShownPerBlizzardPage = 50

	local totalAmountToBid = math.max(minBid, bidAmount) + minIncrement

	if buyoutPrice ~= selectedBuyoutPrice or totalAmountToBid ~= selectedTotalAmountToBid or stackSize ~= selectedStackSize or itemName ~= selectedItemName then
		local itemsShownPerBlizzardPage = 50
		for i = 1, itemsShownPerBlizzardPage do
			itemName, myTexture, stackSize, itemQuality, canUse, itemLevel, levelColHeader, minBid,
			minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
			ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);

			if buyoutPrice == selectedBuyoutPrice and totalAmountToBid == selectedTotalAmountToBid and stackSize == selectedStackSize and itemName == selectedItemName then
				selectedItemPos = i
				break
			end
		end
	end

	totalAmountToBid = max(bidAmount, minBid) + minIncrement

	if buyoutPrice ~= selectedBuyoutPrice or totalAmountToBid ~= selectedTotalAmountToBid or stackSize ~= selectedStackSize or itemName ~= selectedItemName then
		ItemsModule:SendMessage("AUCTIONBUDDY_ERROR", "FailedToBidAuction")
		return
	end

	PlaceAuctionBid('list', selectedItemPos, totalAmountToBid)
	ItemsModule:ResetSelectedItemData()

end

function ItemsModule:OnBuySelectedItem()
	UtilsModule:Log(self, "BuySelectedItem", 0)

	if selectedItemPos == nil then
		return
	end

	local itemName, myTexture, stackSize, itemQuality, canUse, itemLevel, levelColHeader, minBid,
	minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
	ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", selectedItemPos);

	local itemsShownPerBlizzardPage = 50

	if buyoutPrice ~= selectedBuyoutPrice or stackSize ~= selectedStackSize or itemName ~= selectedItemName then
		local itemsShownPerBlizzardPage = 50
		for i = 1, itemsShownPerBlizzardPage do
			itemName, myTexture, stackSize, itemQuality, canUse, itemLevel, levelColHeader, minBid,
			minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
			ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);

			if buyoutPrice == selectedBuyoutPrice and stackSize == selectedStackSize and itemName == selectedItemName then
				selectedItemPos = i
				break
			end
		end
	end

	if buyoutPrice ~= selectedBuyoutPrice or stackSize ~= selectedStackSize or itemName ~= selectedItemName then
		ItemsModule:SendMessage("AUCTIONBUDDY_ERROR", "FailedToBuyAuction")
		return
	end

	PlaceAuctionBid('list', selectedItemPos, buyoutPrice)

	if GetMoney() >= buyoutPrice then
		ItemsModule:SendMessage("REMOVE_SELECTED_RESULTS_ROW", scrollTableSelectedID)
	end
	ItemsModule:ResetSelectedItemData()
	
end

function ItemsModule:OnSellSelectedItem(parentFrame)
	UtilsModule:Log("ItemsModule", "SellSelectedItem", 2)

	local stackPriceBid =  MoneyInputFrame_GetCopper(parentFrame.stackPriceBid)
	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	
	local stackSize = parentFrame.stackSize:GetNumber()
	local stackNumber = parentFrame.stackQuantity:GetNumber()

	local checkPostingErrors = false

	if tonumber(stackSize) < 1 and tonumber(stackNumber) < 1 then
		checkPostingErrors = true
		ItemsModule:SendMessage("AUCTIONBUDDY_ERROR", "InvalidStackOrSizeQuantity")
	end

	if stackPriceBid < 1 or stackPrice < 0 then
		checkPostingErrors = true
		ItemsModule:SendMessage("AUCTIONBUDDY_ERROR", "InvalidAuctionPrice")
	end

	if checkPostingErrors == false then
		PostAuction(stackPriceBid, stackPrice, parentFrame.auctionDuration.durationValue, stackSize, stackNumber)
		ItemsModule:SendMessage("POSTING_ITEM_TO_AH")	
	end

	PickupItem(ItemsModule.currentItemPostedLink) 
	ItemsModule:RemoveInsertedItem(parentFrame)
	
end

function ItemsModule:UpdateSellItemPriceAfterSearch(resultsTable)
	UtilsModule:Log(self, "UpdateSellItemPriceAfterSearch", 2)

	if shown == 0 then
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPrice, 0)
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPriceBid, 0)
		return
	end

	local buyoutPrice = 0
	local prevBuyoutPrice = 0

	local bidPrice = 0
	local prevBidPrice = 0

	for key, value in pairs(resultsTable) do
		for nestedKey, nestedValue in pairs(value) do
			if nestedKey == "buy" and nestedValue > 0 then
				prevBuyoutPrice = nestedValue
			elseif nestedKey == "bid" and nestedValue > 0 then
				prevBidPrice = nestedValue
			end

			if prevBuyoutPrice <= buyoutPrice or buyoutPrice == 0 then
				buyoutPrice = prevBuyoutPrice
			end

			if prevBidPrice <= bidPrice or bidPrice == 0 then
				bidPrice = prevBidPrice
			end
		end
	end

	if bidPrice > 2 then
		bidPrice = bidPrice - 1
	end

	if bidPrice > buyoutPrice and buyoutPrice > 0 then
		bidPrice = buyoutPrice
	end

	MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPriceBid, math.floor(math.max(bidPrice, 0)))
	MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPrice, math.floor(math.max(buyoutPrice - 1, 0)))
	
end

function ItemsModule:UpdateItemSelectedData(itemPos, buyoutPrice, totalAmountToBid, stackSize, itemName, scrolltableID)
	UtilsModule:Log(self, "UpdateItemSelectedData", 2)

	selectedItemPos = itemPos
	selectedBuyoutPrice = buyoutPrice
	selectedTotalAmountToBid = totalAmountToBid
	selectedStackSize = stackSize
	selectedItemName = itemName
	scrollTableSelectedID = scrolltableID

end

function ItemsModule:InsertSelectedItem(parentFrame)
	UtilsModule:Log(self, "InsertSelectedItem", 2)
		
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
		ItemsModule:SendMessage("ON_AUCTION_HOUSE_SEARCH", itemName, nil, true)
					
		ClickAuctionSellItemButton()
		
		InterfaceFunctionsModule:UpdateDepositCost(SellInterfaceModule.mainFrame)

		parentFrame.createAuction:Enable()
	end

	ClearCursor()	

end

function ItemsModule:CalculateMaxStackValues(parentFrame, bagID, bagSlot)
	UtilsModule:Log(self, "CalculateMaxStackValues", 0)

	local itemAmountInBag = 0
	local itemLink = select(7, GetContainerItemInfo(bagID, bagSlot))
	
	local itemStackCount = select(8, GetItemInfo(itemLink))

	itemAmountInBag = ItemsModule:GetTotalItemAmountInBag(parentFrame, itemLink)

	local maxStackSizeValue = math.max(math.min(itemAmountInBag, itemStackCount), 1)
	local maxStackNumberValue = math.max(math.floor(itemAmountInBag / tonumber(parentFrame.stackSize:GetText())), 1)

	parentFrame.stackSize.maxStackValue:SetText(tostring(maxStackSizeValue))
	parentFrame.stackQuantity.maxStackValue:SetText(tostring(maxStackNumberValue))

	parentFrame.stackSize.maxStackBtn:Enable()
	parentFrame.stackQuantity.maxStackBtn:Enable()

end

function ItemsModule:UpdateMaxStackValues(parentFrame)
	UtilsModule:Log(self, "CalculateMaxStackValues", 0)

	local itemLink = parentFrame.itemToSellButton.text:GetText()
	local itemAmountInBag = 0
	itemAmountInBag = ItemsModule:GetTotalItemAmountInBag(parentFrame, itemLink)

	local itemStackCount = select(8, GetItemInfo(itemLink)) or 1

	local stackSizeValue = math.max(parentFrame.stackSize:GetNumber(), 1)
	local stackQuantityValue = math.max(parentFrame.stackQuantity:GetNumber(), 1)

	local maxStackSizeValue = math.max(math.floor(itemAmountInBag / stackQuantityValue), 1)
	local maxStackQuantityValue = itemAmountInBag

	maxStackSizeValue = math.min(maxStackSizeValue, itemStackCount)
	maxStackQuantityValue = math.floor(math.max(maxStackQuantityValue / stackSizeValue, 1))

	parentFrame.stackSize.maxStackValue:SetText(tostring(maxStackSizeValue))
	parentFrame.stackQuantity.maxStackValue:SetText(tostring(maxStackQuantityValue))

end

function ItemsModule:OnClickMaxStackSize(parentFrame)
	UtilsModule:Log(self, "OnClickMaxStackSize", 0)

	parentFrame.stackSize:SetText(parentFrame.stackSize.maxStackValue:GetText())

end

function ItemsModule:OnClickMaxStackQuantity(parentFrame)
	UtilsModule:Log(self, "OnClickMaxStackQuantity", 0)

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
	UtilsModule:Log(self, "RemoveInsertedItem", 2)
	
	infoType, info1, info2 = GetCursorInfo()

	ItemsModule.currentItemPostedLink = nil
		
	ClickAuctionSellItemButton(false)
	ClearCursor()

end

function ItemsModule:ShowToolTip(frame, link, show)
	UtilsModule:Log(self, "ShowToolTip", 3)

	if show == true then
		GameTooltip:SetOwner(frame)
		GameTooltip:SetHyperlink(link)	
		GameTooltip:Show()	
	else
		GameTooltip:Hide()
	end
	
end

function ItemsModule:AddCursorItem(frame)
	UtilsModule:Log(self, "AddCursorItem", 2)

	local infoType, info1, info2 = GetCursorInfo()
	local bindType = select(14, GetItemInfo(info2))
	if bindType ~= 1 then
		ItemsModule:InsertSelectedItem(frame.mainFrame)
	else
		ItemsModule:SendMessage("AUCTIONBUDDY_ERROR", "CannotSellSoulboundItems")
	end

end

function ItemsModule:ResetSelectedItemData()
	UtilsModule:Log(self, "ResetSelectedItemData", 2)

	selectedItemPos = nil
	selectedBuyoutPrice = nil
	selectedTotalAmountToBid = nil
	selectedStackSize = nil
	selectedItemName = nil
	scrollTableSelectedID = nil

end