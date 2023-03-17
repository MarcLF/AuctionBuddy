--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ContainerModule = AuctionBuddy:NewModule("ContainerModule", "AceEvent-3.0")

local UtilsModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil
local DatabaseModule = nil

local containerNumOfSlots = nil

ContainerModule.interfaceCreated = nil
ContainerModule.isPostingItemToAH = false
ContainerModule.isMultisellingItemsToAH = false

function ContainerModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("AUCTION_MULTISELL_START")
	self:RegisterEvent("AUCTION_MULTISELL_UPDATE")
	self:RegisterEvent("AUCTION_MULTISELL_FAILURE")
	self:RegisterMessage("SHOW_AB_BUY_FRAME", self.ScanContainer)
	self:RegisterMessage("SHOW_AB_SELL_FRAME", self.ScanContainer)
	self:RegisterMessage("POSTING_ITEM_TO_AH", self.OnPostingItemToAH)

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
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	self:UnregisterAllEvents()
	ContainerModule.isPostingItemToAH = false
	
end

function ContainerModule:BAG_UPDATE_DELAYED()
	UtilsModule:Log(self, "BAG_UPDATE_DELAYED", 0)

	ContainerModule:ScanContainer()

	ContainerModule.isPostingItemToAH = false

end

function ContainerModule:AUCTION_MULTISELL_START()
	UtilsModule:Log(self, "AUCTION_MULTISELL_START", 0)

	ContainerModule.isMultisellingItemsToAH = true

end

function ContainerModule:AUCTION_MULTISELL_UPDATE(...)
	UtilsModule:Log(self, "AUCTION_MULTISELL_UPDATE", 0)

	local createdCount = select(2, ...)
	local totalToCreate = select(3, ...)

	if (createdCount == totalToCreate) then 
		ContainerModule.isMultisellingItemsToAH = false
	end
		

end

function ContainerModule:AUCTION_MULTISELL_FAILURE()
	UtilsModule:Log(self, "AUCTION_MULTISELL_FAILURE", 0)

	ContainerModule.isMultisellingItemsToAH = false

end

function ContainerModule:OnPostingItemToAH()
	UtilsModule:Log(ContainerModule, "OnPostingItemToAH", 2)

	ContainerModule.isPostingItemToAH = true

end

function ContainerModule:CanSelectContainerItem()

	local canSelectContainerItem = true

	if not CanSendAuctionQuery() or ContainerModule.isPostingItemToAH or ContainerModule.isMultisellingItemsToAH then
		canSelectContainerItem = false
	end

	if not canSelectContainerItem then
		ContainerModule:SendMessage("AUCTIONBUDDY_ERROR", "TimeoutPostItem")
	end

	return canSelectContainerItem

end

function ContainerModule:ScanContainer()
	UtilsModule:Log("ContainerModule", "ScanContainer", 2)

	local tableData = {}

	if C_Container and C_Container.GetContainerItemInfo then
		for i = 0, 4, 1 do
			containerNumOfSlots = C_Container.GetContainerNumSlots(i)

			for j = 1, containerNumOfSlots, 1 do
				local containerInfo = C_Container.GetContainerItemInfo(i, j)
				local myTexture, itemCount, itemQuality, lootable, itemLinkContainer

				if containerInfo ~= nil then

					myTexture = containerInfo.iconFileID
					itemCount = containerInfo.stackCount
					itemQuality = containerInfo.quality
					lootable = containerInfo.hasLoot
					itemLinkContainer = containerInfo.hyperlink

					if myTexture ~= nil and not lootable then
						if not C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(i, j)) then
							tinsert(tableData, 
							{			
								texture = myTexture,
								itemName = UtilsModule:RemoveCharacterFromString(itemLinkContainer, "%[", "%]"),
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
	UtilsModule:Log(self, "CreateBuyContainerScrollFrameTable", 2)
	
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
			index        = "itemName",
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
				ContainerModule:SendMessage("ON_AUCTION_HOUSE_SEARCH", itemName, nil, true)
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
	UtilsModule:Log(self, "CreateSellContainerScrollFrameTable", 2)
	
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
						if rowData ~= nil then
							ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, true)
						end
						return false
				end,
				OnLeave = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
						if rowData ~= nil then
							ItemsModule:ShowToolTip(cellFrame, rowData.itemLink, false)
						end
						return false
				end
			},
		},
		{
			name         = "Name",
			width        = 75,
			align        = "LEFT",
			index        = "itemName",
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
			if ContainerModule:CanSelectContainerItem() then
				if button == "LeftButton" and ItemsModule.currentItemPostedLink ~= rowData.itemLink then
					C_Container.PickupContainerItem(rowData.bagID, rowData.slot)
					
					ContainerModule:SendMessage("CONTAINER_ITEM_SELECTED", parentFrame, rowData.bagID, rowData.slot)			

					parentFrame.scrollTableContainer:ClearSelection()
				end
			end
			return true
		end
	})
	
end