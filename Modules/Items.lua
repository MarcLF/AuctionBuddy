--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ItemsModule = AuctionBuddy:NewModule("ItemsModule")

ItemsModule.currentItemPostedLink = nil
ItemsModule.itemSelected = false
ItemsModule.itemInserted = false

local InterfaceFunctionsModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

function ItemsModule:OnInitialize()

	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	
end

function ItemsModule:CreateAuctionItemButtons(itemsShown, scrollTable)

	local tableData = {}
	
	for i = 1, itemsShown do
		local itemName, myTexture, aucCount, itemQuality, canUse, itemLevel, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);
		
		local buyOutPerItem = buyoutPrice/aucCount
		
		-- This data is compared to each index of columnType array from the CreateBuyScrollFrameTable function inside Buy.lua
		tinsert(tableData, 
		{
			texture = myTexture,
			itemLink = tostring(GetAuctionItemLink("list", i)),
			name = itemName,
			owner = tostring(aucOwner),
			count = aucCount,
			quality = itemQuality,
			itlvl = itemLevel,
			bid = bidAmount,
			buy = buyOutPerItem	,
			totalPrice = buyoutPrice
		})
	end
	
	scrollTable:Show()
	scrollTable:SetData(tableData, true)
	
end

function ItemsModule:UpdateSellItemPriceAfterSearch(numberList, shown, total)
	
	local buyoutPrice = select(10, GetAuctionItemInfo("list", numberList))
	local itemQuantity = select(3, GetAuctionItemInfo("list", numberList))

	if buyoutPrice == 0 and total > 1 and numberList < shown and SellInterfaceModule.mainFrame:IsShown() then
		numberList = numberList + 1
		self:UpdateSellItemPriceAfterSearch(numberList, shown, total)

	elseif SellInterfaceModule.mainFrame:IsShown() then
		MoneyInputFrame_SetCopper(SellInterfaceModule.mainFrame.itemPrice, buyoutPrice/itemQuantity)
	end
	
end

function ItemsModule:ItemInsertedOrSelected(button, insertedOrSelected)
	
	if insertedOrSelected == true then
		button:Enable()
	else
		button:Disable()
	end

end

function ItemsModule:BuySelectedItem(selectedItemData, isBid)
	
	local buyoutPrice = select(10, GetAuctionItemInfo("list", selectedItemData))
	local bidAmount = select(11, GetAuctionItemInfo("list", selectedItemData))
	
	bidAmount = bidAmount*1.05
	
	if isBid == true then
		PlaceAuctionBid('list', selectedItemData, bidAmount)
	else
		PlaceAuctionBid('list', selectedItemData, buyoutPrice)
	end
	
	self.itemSelected = false
	
end

function ItemsModule:SearchSelectedContainerItem()
	
	infoType, info1, info2 = GetCursorInfo()
	local itemName = GetItemInfo(info2) 
	ClearCursor()
	AuctionBuddy:AuctionHouseSearch(itemName)
	
end

function ItemsModule:InsertSelectedItem(parentFrame)
		
	infoType, info1, info2 = GetCursorInfo()
	
	self.currentItemPostedLink = info2
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
		
		self.itemInserted = true
		InterfaceFunctionsModule:UpdateDepositCost(SellInterfaceModule.mainFrame)
	end

	ClearCursor()	

end

function ItemsModule:RemoveInsertedItem(parentFrame)
	
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

	if show == true then
		GameTooltip:SetOwner(frame)
		GameTooltip:SetHyperlink(link)	
		GameTooltip:Show()	
	else
		GameTooltip:Hide()
	end
	
end