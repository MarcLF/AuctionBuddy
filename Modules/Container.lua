--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ContainerModule = AuctionBuddy:NewModule("ContainerModule", "AceEvent-3.0")

local DebugModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil
local DatabaseModule = nil

local containerNumOfSlots = nil

ContainerModule.bagID = nil
ContainerModule.bagSlot = nil
ContainerModule.interfaceCreated = nil

function ContainerModule:Enable()

	DebugModule = AuctionBuddy:GetModule("DebugModule")
	DebugModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")

	if self.interfaceCreated == true then
		return
	end

	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	
	self:CreateBuyContainerScrollFrameTable(BuyInterfaceModule.mainFrame, 150, -135)
	self:CreateSellContainerScrollFrameTable(SellInterfaceModule.mainFrame, -192, -135)
	
	self:ScanContainer()
	
	self.interfaceCreated = true
	
end

function ContainerModule:AUCTION_HOUSE_CLOSED()
	DebugModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllEvents()
	
end

function ContainerModule:AUCTION_OWNED_LIST_UPDATE()
	DebugModule:Log(self, "AUCTION_OWNED_LIST_UPDATE", 2)

	C_Timer.After(1.0, self.ScanContainer)

end

function ContainerModule:ScanContainer()
	DebugModule:Log("ContainerModule", "ScanContainer", 2)

	local tableData = {}
	for i = 0, 4, 1 do
	
		containerNumOfSlots = GetContainerNumSlots(i)
		
		for j = 1, containerNumOfSlots, 1 do
			local myTexture, itemCount, locked, itemQuality, readable, lootable, itemLinkContainer = GetContainerItemInfo(i, j)
		
			if myTexture ~= nil then
				if not C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(i, j)) then
					tinsert(tableData, 
					{			
						texture = myTexture,
						itemLink = itemLinkContainer,
						count = tonumber(itemCount),
						quality = itemQuality,
						bagID = i,
						slot = j
					})
				end
			end
		end
	end
	
	if BuyInterfaceModule ~= nil then
		BuyInterfaceModule.mainFrame.scrollTableContainer:SetData(tableData, true)
	end

	if SellInterfaceModule ~= nil then
		SellInterfaceModule.mainFrame.scrollTableContainer:SetData(tableData, true)
	end
	
end

function ContainerModule:CreateBuyContainerScrollFrameTable(parentFrame, xPos, yPos)
	DebugModule:Log(self, "CreateBuyContainerScrollFrameTable", 2)
	
	local columnType = 
	{
		{
			name         = "Icon",
			width        = 48,
			align        = "LEFT",
			index        = "texture",
			format       = "icon",
			events		 = {
				OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
						ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, true)
						return false
				end,
				OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
						ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, false)
						return false
				end
			},
		},
		{
			name         = "Name",
			width        = 80,
			align        = "LEFT",
			index        = "itemLink",
			format       = "string",
		}
	}
		
	parentFrame.scrollTableContainer = StdUi:ScrollTable(parentFrame, columnType, 16, 32)
	StdUi:GlueTop(parentFrame.scrollTableContainer, parentFrame, xPos, yPos, 0, 0)
	parentFrame.scrollTableContainer:EnableSelection(false)
	parentFrame.scrollTableContainer:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == "LeftButton" then	
				local itemName = GetItemInfo(rowData.itemLink) 
				AuctionBuddy:AuctionHouseSearch(itemName, true)
			end
			if button == "RightButton" then	
				if BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value ~= nil then
					local itemName = GetItemInfo(rowData.itemLink) 	
					DatabaseModule:InsertNewSearch(DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1], itemName) 
					DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.favoriteSearchesTable, DatabaseModule.favoriteSearchesLists[BuyInterfaceModule.mainFrame.favoriteListsDropDownMenu.value][1])
				end
			end
		end
			
	})
	
end

function ContainerModule:CreateSellContainerScrollFrameTable(parentFrame, xPos, yPos)
	DebugModule:Log(self, "CreateSellContainerScrollFrameTable", 2)
	
	local columnType = 
	{
		{
			name         = "Icon",
			width        = 45,
			align        = "CENTER",
			index        = "texture",
			format       = "icon",
			events		 = {
				OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
						ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, true)
						return false
				end,
				OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
						ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, false)
						return false
				end
			},
		},
		{
			name         = "Name",
			width        = 75,
			align        = "LEFT",
			index        = "itemLink",
			format       = "string",
		},
		{
			name         = "Qty",
			width        = 40,
			align        = "CENTER",
			index        = "count",
			format       = "number",
		},
		{
			name         = "Quality",
			width        = 60,
			align        = "RIGHT",
			index        = "quality",
			format       = "string",
		}
	}
		
	parentFrame.scrollTableContainer = StdUi:ScrollTable(parentFrame, columnType, 16, 32)
	StdUi:GlueTop(parentFrame.scrollTableContainer, parentFrame, xPos, yPos, 0, 0)
	parentFrame.scrollTableContainer:EnableSelection(true)
	parentFrame.scrollTableContainer:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == "LeftButton" and ItemsModule.currentItemPostedLink ~= rowData.itemLink then
				PickupContainerItem(rowData.bagID, rowData.slot)
				ContainerModule.bagID = rowData.bagID
				ContainerModule.bagSlot = rowData.slot
					
				self:SendMessage("CONTAINER_ITEM_SELECTED", parentFrame, ContainerModule.bagID, ContainerModule.bagSlot)			

				parentFrame.scrollTableContainer:ClearSelection()
			end
			return true
		end
	})
	
end