--
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ContainerModule = AuctionBuddy:NewModule("ContainerModule", "AceEvent-3.0")

local BuyInterfaceModule = nil
local SellInterfaceModule = nil
local ItemsModule = nil
local DatabaseModule = nil
local SearchesModule = nil

local containerNumOfSlots = nil

ContainerModule.bagID = nil
ContainerModule.bagSlot = nil

function ContainerModule:Enable()

	if self.interfaceCreated == true then
		return
	end

	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")
	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	SearchesModule = AuctionBuddy:GetModule("SearchesModule")
	
	self:CreateContainerScrollFrameTable(BuyInterfaceModule.mainFrame, 145, -135)
	self:CreateContainerScrollFrameTable(SellInterfaceModule.mainFrame, -192, -135)
	
	self:ScanContainer()
	
	self.interfaceCreated = true
	
end

function ContainerModule:OnInitialize()

	self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")

end

function ContainerModule:AUCTION_OWNED_LIST_UPDATE()

	C_Timer.After(0.5, self.ScanContainer)

end

function ContainerModule:ScanContainer()

	local tableData = {}
	for i = 0, 4, 1 do
	
		containerNumOfSlots = GetContainerNumSlots(i)
		
		for j = 0, containerNumOfSlots, 1 do
			myTexture, itemCount, locked, itemQuality, readable, lootable, itemLinkContainer = GetContainerItemInfo(i, j)
		
			if myTexture ~= nil and not C_Item.IsBound(ItemLocation:CreateFromBagAndSlot(i, j)) then
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
	
	if BuyInterfaceModule ~= nil then
		BuyInterfaceModule.mainFrame.scrollTableContainer:SetData(tableData, true)
	end

	if BuyInterfaceModule ~= nil then
		SellInterfaceModule.mainFrame.scrollTableContainer:SetData(tableData, true)
	end
	
end

function ContainerModule:CreateContainerScrollFrameTable(parentFrame, xPos, yPos)
	
	if parentFrame == BuyInterfaceModule.mainFrame then
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
	
	else
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
			},
			{
				name         = "Qty",
				width        = 40,
				align        = "LEFT",
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
					
					ItemsModule:InsertSelectedItem(parentFrame)				

					parentFrame.scrollTableContainer:ClearSelection()
				end
				return true
			end
		})
	end
	
end