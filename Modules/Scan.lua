--
local AuctionBuddy = unpack(select(2, ...))

local ScanModule = AuctionBuddy:NewModule("ScanModule", "AceEvent-3.0")

ScanModule.page = nil
ScanModule.searchText = nil

ScanModule.shownPerBlizzardPage = 0
ScanModule.total = 0

local UtilsModule = nil
local DatabaseModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

local isScanningRunning = false
local isExactMatchScan = false

local ScanResultsCoroutine = nil
local scanFrame = nil

local hasCurrentPageBeenAdded = false
local gettingDataFromPageNum = 0

local resultsTableData = {}


function ScanModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)
	
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")

	self:RegisterMessage("ON_AUCTION_HOUSE_SEARCH", self.AuctionHouseSearchStart)
	self:RegisterMessage("SCAN_SELECTED_ITEM_AH_PAGE", self.AuctionHouseSearch)

	self:RegisterMessage("REMOVE_SELECTED_RESULTS_ROW", self.RemoveSelectedResultsRow)
	self:RegisterMessage("POSTING_ITEM_TO_AH", self.ResetData)
	self:RegisterMessage("ON_SEARCH_MORE_RESULTS", self.ScanResults)

	ScanModule.page = 0

end

function ScanModule:AUCTION_ITEM_LIST_UPDATE()
	UtilsModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 1)

	if not isScanningRunning then
		ScanModule.shownPerBlizzardPage, ScanModule.total = GetNumAuctionItems("list")
		UtilsModule:Log("shownPerBlizzardPage: ", ScanModule.shownPerBlizzardPage, 0)
		UtilsModule:Log("Total items: ", ScanModule.total, 0)
		isScanningRunning = true
	end

	if isScanningRunning and gettingDataFromPageNum == ScanModule.page then
		ScanModule:InsertResultsPage()
	end
		
end

function ScanModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	isScanningRunning = false
	hasCurrentPageBeenAdded = false
	gettingDataFromPageNum = 0

	ScanModule:ResetData()

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	
end

function ScanModule:AuctionHouseSearchStart(textToSearch, pageToSearch, exactMatch)
	UtilsModule:Log(self, "AuctionHouseSearchStart", 0)

	if CanSendAuctionQuery() then
		ScanModule:SendMessage("ON_DISABLE_SEARCH_MORE_BUTTON")

		resultsTableData = {}
		ScanModule:SendResultsTable()
		ScanModule.page = 0
		gettingDataFromPageNum = 0
		isExactMatchScan = exactMatch

		ScanModule:SendMessage("ON_AH_SCAN_RUNNING", true)

		ScanModule:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
		ScanModule:AuctionHouseSearch(textToSearch, pageToSearch)
	else
		ScanModule:SendMessage("AUCTIONBUDDY_ERROR", "CannotSendAHQuery")
	end

end

function ScanModule:AuctionHouseSearch(textToSearch, pageToSearch)
	UtilsModule:Log(self, "AuctionHouseSearch", 0)

	if textToSearch ~= nil then
		ScanModule.searchText = textToSearch
	end

	local checkWhiteSpaces = string.gsub(ScanModule.searchText, " ", "")

	if string.len(ScanModule.searchText) > 0 and string.len(checkWhiteSpaces) > 0 then
		DatabaseModule:InsertNewSearch(DatabaseModule.recentSearches, ScanModule.searchText)
		DatabaseModule:InsertDataFromDatabase(BuyInterfaceModule.mainFrame.recentSearchesTable, DatabaseModule.recentSearches)
	end
		
	local filterData = nil
	local itemType = BuyInterfaceModule.mainFrame.itemClasses.value
	local itemSubType = BuyInterfaceModule.mainFrame.itemClasses.valueSubList
	local itemSubSubType = BuyInterfaceModule.mainFrame.itemClasses.valueSubSubList

	if itemType ~= nil and itemSubType ~= nil and itemSubSubType ~= nil then
		filterData = AuctionCategories[itemType].subCategories[itemSubType].subCategories[itemSubSubType].filters
	elseif itemType ~= nil and itemSubType ~= nil then
		filterData = AuctionCategories[itemType].subCategories[itemSubType].filters
	elseif itemType ~= 0 then
		filterData = AuctionCategories[itemType].filters
	else
		filterData = 0
    end

	local currentPageToSearch = pageToSearch or ScanModule.page
	ScanModule.page = currentPageToSearch

	QueryAuctionItems(	
		ScanModule.searchText, 
		BuyInterfaceModule.mainFrame.minILvl:GetNumber(),
		BuyInterfaceModule.mainFrame.maxILvl:GetNumber(), 
		currentPageToSearch,
		false,
		BuyInterfaceModule.mainFrame.rarity.value,
		false,
		DatabaseModule.buyOptions.exactMatch or isExactMatchScan,
		filterData
	)
	
end

function ScanModule:ScanResults()
	UtilsModule:Log("ScanModule", "ScanResults", 0)

	if CanSendAuctionQuery() then
		ScanModule:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")

		ScanModule.page = ScanModule.page + 1
		gettingDataFromPageNum = gettingDataFromPageNum + 1

		ScanModule:AuctionHouseSearch()
	else
		ScanModule:SendMessage("AUCTIONBUDDY_ERROR", "CannotSendAHQuery")
	end

	
end

function ScanModule:InsertResultsPage()
	UtilsModule:Log("ScanModule", "InsertResultsPage", 0)

	hasCurrentPageBeenAdded = false

	if not ScanModule.shownPerBlizzardPage then
		return
	end

	for i = 1, ScanModule.shownPerBlizzardPage do
		local currentScanSize = i + ScanModule.page * ScanModule.shownPerBlizzardPage
		if  currentScanSize > ScanModule.total or GetAuctionItemInfo("list", i) == nil then
			UtilsModule:Log("Breaking Insert Result Loop", ScanModule.page, i, 0)
			UtilsModule:Log("Total items: ", ScanModule.total, "Items per page: ", ScanModule.shownPerBlizzardPage, 0)
			break
		end

		local itemName, myTexture, aucCount, itemQuality, canUse, itemLevel, levelColHeader, minBid,
		minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, aucOwner,
		ownerFullName, saleStatus, itemId, hasAllInfo = GetAuctionItemInfo("list", i);

		local buyOutPerItem = buyoutPrice/aucCount
		local totalBidItem

		if bidAmount > 0 then
			totalBidItem = bidAmount
		else
			totalBidItem = minBid
		end

		-- This data is compared to each index of columnType array from the CreateResultsScrollFrameTable function inside ResultsTable.lua
		if tostring(GetAuctionItemLink("list", i)) ~= nil then
			itemLinkString = tostring(GetAuctionItemLink("list", i))
			tinsert(resultsTableData, 
			{
				texture = myTexture,
				itemLink = UtilsModule:RemoveCharacterFromString(itemLinkString, "%[", "%]"),
				name = itemName,
				owner = tostring(aucOwner),
				count = aucCount,
				itlvl = itemLevel,
				bid = totalBidItem,
				buy = buyOutPerItem,
				totalPrice = buyoutPrice
			})
		end

	end

	ScanModule:SendResultsTable()

end

function ScanModule:RemoveSelectedResultsRow(rowToRemove)
	UtilsModule:Log("ScanModule", "RemoveSelectedResultsRow", 0)

	table.remove(resultsTableData, rowToRemove)
	ScanModule:SendResultsTable()

end

function ScanModule:SendResultsTable()
	UtilsModule:Log("ScanModule", "SendResultsTable", 2)

	local scrollTable = nil

	if BuyInterfaceModule.mainFrame:IsShown() then
		scrollTable = BuyInterfaceModule.mainFrame.scrollTable
	elseif SellInterfaceModule.mainFrame:IsShown() then
		scrollTable = SellInterfaceModule.mainFrame.scrollTable
		ScanModule:SendMessage("UPDATE_SELL_ITEM_PRICE", resultsTableData)
	end
	
	ScanModule:SendMessage("ON_AH_SCAN_RUNNING", false)
	scrollTable:Show()
	scrollTable:SetData(resultsTableData, true)

	isScanningRunning = false

	ScanModule:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")

	if #resultsTableData < ScanModule.total then
		ScanModule:SendMessage("ON_ENABLE_SEARCH_MORE_BUTTON")
	else
		ScanModule:SendMessage("ON_DISABLE_SEARCH_MORE_BUTTON")
	end

end

function ScanModule:ResetData()

	ScanModule.shownPerBlizzardPage = 0
	ScanModule.total = 0
	ScanModule.page = 0
	ScanModule.searchText = ""

end