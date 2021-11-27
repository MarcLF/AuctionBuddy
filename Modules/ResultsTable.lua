-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ResultsTableModule = AuctionBuddy:NewModule("ResultsTableModule", "AceEvent-3.0")

local UtilsModule = nil
local ItemsModule = nil
local DatabaseModule = nil
local ScanModule = nil

local containedInPageNumber = nil
local prevContainedInPageNumber = nil

local buyoutPrice = nil
local bidPrice = nil
local stackSize = nil
local itemPos = nil
local itemName = nil
local selectedItemParentFrame = nil

function ResultsTableModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	ScanModule = AuctionBuddy:GetModule("ScanModule")

end

function ResultsTableModule:AUCTION_ITEM_LIST_UPDATE()
	UtilsModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 0)

	ResultsTableModule:SendMessage("RESULTSTABLE_ITEM_SELECTED", selectedItemParentFrame, buyoutPrice, bidPrice, stackSize, itemPos, itemName)

	ResultsTableModule:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")

end

function ResultsTableModule:CreateResultsScrollFrameTable(parentFrame, xPos, yPos)
	UtilsModule:Log(self, "CreateResultsScrollFrameTable", 2)
	
	if parentFrame.scrollTableCreated then
		return
	end
	
	local columnType = {
		{
			name         = "Icon",
			width        = 36,
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
			width        = 150,
			align        = "LEFT",
			index        = "itemLink", -- Item link so it shows it's name with rarity matching colors.
			format       = "string",
		},
		{
			name         = "Seller",
			width        = 80,
			align        = "LEFT",
			index        = "owner",
			format       = "string",
		},
		{
			name         = "Size",
			width        = 50,
			align        = "LEFT",
			index        = "count",
			format       = "string",
		},
		{
			name         = " Lvl",
			width        = 45,
			align        = "CENTER",
			index        = "itlvl",
			format       = "string",
		},
		{
			name         = "Bid / Total",
			width        = 90,
			align        = "RIGHT",
			index        = "bid",
			format       = "money",
		},
		{
			name         = "Buy / Item",
			width        = 90,
			align        = "RIGHT",
			index        = "buy",
			format       = "money",
		},
			{
			name         = "Buy / Total",
			width        = 90,
			align        = 'RIGHT',
			index        = 'totalPrice',
			format       = 'money',
		},
	}
	
	parentFrame.scrollTable = StdUi:ScrollTable(parentFrame, columnType, 18, 28)
	StdUi:GlueTop(parentFrame.scrollTable, parentFrame, xPos, yPos, 0, 0)
	parentFrame.scrollTable:EnableSelection(true)
	parentFrame.scrollTable:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
			if (button == "LeftButton" or button == "RightButton") and CanSendAuctionQuery() then
				UtilsModule:Log(self, "OnClickResultsTable", 2)
				parentFrame.scrollTable:SetSelection(rowIndex)

				for key, value in pairs(rowData) do
					if key == "totalPrice" then
						buyoutPrice = value
					elseif key == "bid" then
						bidPrice = value
					elseif key == "count" then
						stackSize = value
					elseif key == "name" then
						itemName = value
					end
				end

				local blizzardPageSize = 50
				local itemPage = math.floor((parentFrame.scrollTable:GetSelection() - 1) / blizzardPageSize)
				itemPos = parentFrame.scrollTable:GetSelection() - itemPage * blizzardPageSize

				selectedItemParentFrame = parentFrame

				prevContainedInPageNumber = ScanModule.page
				containedInPageNumber = itemPage

				UtilsModule:Log("Selected item page number", itemPage, 0)
				UtilsModule:Log("Prev page number", prevContainedInPageNumber, 0)

				if prevContainedInPageNumber ~= containedInPageNumber then
					ResultsTableModule:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
					ResultsTableModule:SendMessage("SCAN_SELECTED_ITEM_AH_PAGE", nil, containedInPageNumber)
				else 
					ResultsTableModule:SendMessage("RESULTSTABLE_ITEM_SELECTED", parentFrame, buyoutPrice, bidPrice, stackSize, itemPos, itemName)
				end
			else
				ResultsTableModule:SendMessage("AUCTIONBUDDY_ERROR", "FailedToSelectItem")
			end
			return true
		end,
		
		OnDoubleClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if parentFrame.scrollTable:GetSelection() == nil then
				return
			end
			local buyoutPrice = nil
			local bidPrice = nil

			for key, value in pairs(rowData) do
				if key == "totalPrice" then
					buyoutPrice = value
				elseif key == "bid" then
					bidPrice = value
				end
			end
			
			local blizzardPageSize = 50
			local itemPage = math.floor((parentFrame.scrollTable:GetSelection() - 1) / blizzardPageSize)

			UtilsModule:Log("Selected item page number", itemPage, 0)
			UtilsModule:Log("Prev page number", prevContainedInPageNumber, 0)

			if prevContainedInPageNumber ~= itemPage then
				ResultsTableModule:SendMessage("AUCTIONBUDDY_ERROR", "FailedToDoubleClick")
				return true
			end

			if button == "LeftButton" and DatabaseModule.buyOptions.doubleClickToBuy == true then
				ResultsTableModule:SendMessage("ON_BUY_SELECTED_ITEM")
				parentFrame.scrollTable:ClearSelection()
			elseif button == "RightButton" and DatabaseModule.buyOptions.doubleClickToBid == true then
				ResultsTableModule:SendMessage("ON_BID_SELECTED_ITEM")
				parentFrame.scrollTable:ClearSelection()
			end
			return true
		end
	})
	
	parentFrame.scrollTableCreated = true
	
end