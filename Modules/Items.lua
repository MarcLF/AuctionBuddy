--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ItemsModule = AuctionBuddy:NewModule("ItemsModule", "AceEvent-3.0")

ItemsModule.currentItemPostedLink = nil
ItemsModule.itemSelected = false
ItemsModule.itemInserted = false

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

	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterMessage("CONTAINER_ITEM_SELECTED", self.InsertSelectedItem)
	
end

function ItemsModule:AUCTION_HOUSE_CLOSED()
	DebugModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	
end

function ItemsModule:AUCTION_ITEM_LIST_UPDATE()
	DebugModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 1)

	self.shown, self.total = GetNumAuctionItems("list")

	ItemsModule:CreateAuctionItemButtons(self.shown, BuyInterfaceModule.mainFrame.scrollTable)
	ItemsModule:CreateAuctionItemButtons(self.shown, SellInterfaceModule.mainFrame.scrollTable)

	if self.total > 0 then 
		ItemsModule:UpdateSellItemPriceAfterSearch(1,  self.shown, self.total)
	end
	
end

function ItemsModule:CreateAuctionItemButtons(itemsShown, scrollTable)
	DebugModule:Log(self, "CreateAuctionItemButtons", 2)

	local tableData = {}
	
	for i = 1, itemsShown do
		local itemName, myTexture, aucCount, itemQuality, canUse, itemLevel, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);
		
		local buyOutPerItem = buyoutPrice/aucCount

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
			--Lua lacks ternary operators explicitly, this is the standard solution to use them.
			bid = (bidAmount and minBid or bidAmount),
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

	local priceToSell = math.floor(buyoutPrice/itemQuantity)

	if buyoutPrice == 0 and total > 1 and numberList < shown and SellInterfaceModule.mainFrame:IsShown() then
		numberList = numberList + 1
		self:UpdateSellItemPriceAfterSearch(numberList, shown, total)

	elseif SellInterfaceModule.mainFrame:IsShown() then
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPrice, priceToSell)
	end
	
end

function ItemsModule:ItemInsertedOrSelected(button, insertedOrSelected)
	DebugModule:Log(self, "ItemInsertedOrSelected", 3)
	
	if insertedOrSelected == true then
		button:Enable()
	else
		button:Disable()
	end

end

function ItemsModule:BuySelectedItem(selectedItemData, isBid)
	DebugModule:Log(self, "BuySelectedItem", 2)
	
	local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))
	local bidAmount = select(11, GetAuctionItemInfo("list", selectedItemData))
	local minIncrement = select(9, GetAuctionItemInfo("list", selectedItemData))
	local minBid = select(8, GetAuctionItemInfo("list", selectedItemData))

	local totalAmountToBid = max(bidAmount, minBid) + minIncrement

	if isBid == true then
		PlaceAuctionBid('list', selectedItemData, totalAmountToBid)
		if GetMoney() > totalAmountToBid then
			AuctionBuddy:AuctionHouseSearch(nil)
		end
	else
		PlaceAuctionBid('list', selectedItemData, buyoutPrice)
	end
	
	self.itemSelected = false
	
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
		
		parentFrame.stackNumber:SetText(1)
		parentFrame.stackSize:SetText(1)
		
		local itemName = GetItemInfo(info2) 
		AuctionBuddy:AuctionHouseSearch(itemName, true)		
					
		ClickAuctionSellItemButton()
		
		ItemsModule.itemInserted = true
		InterfaceFunctionsModule:UpdateDepositCost(SellInterfaceModule.mainFrame)
	end

	ClearCursor()	

end

function ItemsModule:RemoveInsertedItem(parentFrame)
	DebugModule:Log(self, "RemoveInsertedItem", 2)
	
	infoType, info1, info2 = GetCursorInfo()
	
	if infoType == "item" then
		parentFrame.itemToSellButton:SetScript("OnEnter", function(self)
		end)

		parentFrame.itemToSellButton.itemTexture:SetTexture(nil)
		parentFrame.itemToSellButton.text:SetText("<-- [Insert Item]")
		
		parentFrame.stackNumber:SetText(1)
		parentFrame.stackSize:SetText(1)
		
		self.itemInserted = false
		self.currentItemPostedLink = nil
		
		ClickAuctionSellItemButton(false)
		ClearCursor()
	end

end

function ItemsModule:SellSelectedItem(parentFrame)
	DebugModule:Log(self, "SellSelectedItem", 2)

	local itemPrice = MoneyInputFrame_GetCopper(parentFrame.itemPrice)
	local stackPrice = MoneyInputFrame_GetCopper(parentFrame.stackPrice)
	
	local stackSize = parentFrame.stackSize:GetText()
	local stackNumber = parentFrame.stackNumber:GetText()
	
	if itemPrice > 2 then
		PostAuction(stackPrice - 1, stackPrice, parentFrame.auctionDuration.durationValue, stackSize, stackNumber)
	else
		print("AuctionBuddy: Can't place auctions with an item price below 2 Coppers.")
	end
	
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