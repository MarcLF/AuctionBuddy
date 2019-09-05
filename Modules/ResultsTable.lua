-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ResultsTableModule = AuctionBuddy:NewModule("ResultsTableModule")

local ItemsModule = nil
local InterfaceFunctionsModule = nil
local DatabaseModule = nil

function ResultsTableModule:Enable()

	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	InterfaceFunctionsModule = AuctionBuddy:GetModule("InterfaceFunctionsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")

end

function ResultsTableModule:CreateResultsScrollFrameTable(parentFrame, xPos, yPos)
	
	if parentFrame.scrollTableCreated then
		return
	end
	
	local columnType = {
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
			name         = "Seller",
			width        = 80,
			align        = "LEFT",
			index        = "owner",
			format       = "string",
		},
		{
			name         = "Quantity",
			width        = 60,
			align        = "CENTER",
			index        = "count",
			format       = "number",
		},
		{
			name         = "Quality",
			width        = 60,
			align        = "CENTER",
			index        = "quality",
			format       = "string",
		},
		{
			name         = "Level",
			width        = 50,
			align        = "CENTER",
			index        = "itlvl",
			format       = "string",
		},
		{
			name         = "Bid / Item",
			width        = 80,
			align        = "RIGHT",
			index        = "bid",
			format       = "money",
		},
		{
			name         = "Buy / Item",
			width        = 80,
			align        = "RIGHT",
			index        = "buy",
			format       = "money",
		},
			{
			name         = 'Total Price',
			width        = 80,
			align        = 'RIGHT',
			index        = 'totalPrice',
			format       = 'money',
		},
	}
	
	parentFrame.scrollTable = StdUi:ScrollTable(parentFrame, columnType, 16, 32)
	StdUi:GlueTop(parentFrame.scrollTable, parentFrame, xPos,yPos, 0, 0)
	parentFrame.scrollTable:EnableSelection(true)
	parentFrame.scrollTable:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
			if button == "LeftButton" then
				ItemsModule.itemSelected = true
				InterfaceFunctionsModule.needToUpdateTotalCostText = true
				parentFrame.scrollTable:SetSelection(rowIndex)	
				InterfaceFunctionsModule:UpdateTotalBuyoutCostBuy(parentFrame.scrollTable:GetSelection(), ItemsModule.itemSelected)
			end
			return true
		end,
		
		OnDoubleClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == "LeftButton" and DatabaseModule.buyOptions.doubleClickToBuy == true then
				ItemsModule.BuySelectedItem(rowData, rowIndex, false)
			end
			return true
		end
	})
	
	parentFrame.scrollTableCreated = true
	
end