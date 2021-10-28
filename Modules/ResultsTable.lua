-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ResultsTableModule = AuctionBuddy:NewModule("ResultsTableModule", "AceEvent-3.0")

local UtilsModule = nil
local ItemsModule = nil
local DatabaseModule = nil

function ResultsTableModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")

end

function ResultsTableModule:CreateResultsScrollFrameTable(parentFrame, xPos, yPos)
	UtilsModule:Log(self, "CreateResultsScrollFrameTable", 2)
	
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
			width        = 110,
			align        = "LEFT",
			index        = "name",
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
			name         = 'Total Price',
			width        = 90,
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
			if button == "LeftButton" or button == "RightButton" then
				UtilsModule:Log(self, "OnLeftClickResultsTable", 2)
				parentFrame.scrollTable:SetSelection(rowIndex)
				ResultsTableModule:SendMessage("RESULTSTABLE_ITEM_SELECTED", parentFrame)	
			end
			return true
		end,
		
		OnDoubleClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
			if button == "LeftButton" and DatabaseModule.buyOptions.doubleClickToBuy == true then
				ResultsTableModule:SendMessage("ON_BUY_SELECTED_ITEM", parentFrame.scrollTable:GetSelection())
				parentFrame.scrollTable:ClearSelection()
			elseif button == "RightButton" and DatabaseModule.buyOptions.doubleClickToBid == true then
				ResultsTableModule:SendMessage("ON_BID_SELECTED_ITEM", parentFrame.scrollTable:GetSelection())
				parentFrame.scrollTable:ClearSelection()
			end
			return true
		end
	})
	
	parentFrame.scrollTableCreated = true
	
end