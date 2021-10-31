-- 
local AuctionBuddy = unpack(select(2, ...))

local StdUi = LibStub('StdUi')

local ResultsTableModule = AuctionBuddy:NewModule("ResultsTableModule", "AceEvent-3.0")

local UtilsModule = nil
local ItemsModule = nil
local DatabaseModule = nil
local ScanModule = nil

local containedInPageNumber = nil

function ResultsTableModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)

	ItemsModule = AuctionBuddy:GetModule("ItemsModule")
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	ScanModule = AuctionBuddy:GetModule("ScanModule")

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
	StdUi:GlueTop(parentFrame.scrollTable, parentFrame, xPos,yPos, 0, 0)
	parentFrame.scrollTable:EnableSelection(true)
	parentFrame.scrollTable:RegisterEvents({
		OnClick = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
			if button == "LeftButton" or button == "RightButton" then
				UtilsModule:Log(self, "OnClickResultsTable", 2)
				parentFrame.scrollTable:SetSelection(rowIndex)

				local prevContainedInPageNumber = containedInPageNumber or ScanModule.page
				containedInPageNumber = math.floor((parentFrame.scrollTable:GetSelection() - 1) / 50)
				print("prev page: ", prevContainedInPageNumber)
				print("current page: ", containedInPageNumber)

				local buyoutPrice = nil
				local bidPrice = nil
				local stackSize = nil

				for key, value in pairs(rowData) do
					if key == "totalPrice" then
						buyoutPrice = value
					elseif key == "bid" then
						bidPrice = value
					elseif key == "count" then
						stackSize = value
					end
				end

				if prevContainedInPageNumber ~= containedInPageNumber then
					ResultsTableModule:SendMessage("SCAN_SELECTED_ITEM_AH_PAGE", nil, nil, containedInPageNumber)
				end

				C_Timer.After(0.2, function() 	
					ResultsTableModule:SendMessage("RESULTSTABLE_ITEM_SELECTED", parentFrame, buyoutPrice, bidPrice, stackSize)
				end)
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