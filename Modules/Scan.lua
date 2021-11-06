--
local AuctionBuddy = unpack(select(2, ...))

local ScanModule = AuctionBuddy:NewModule("ScanModule", "AceEvent-3.0")

ScanModule.searchActive = nil
ScanModule.page = nil
ScanModule.searchText = nil
ScanModule.isSortedBuyout = false

local UtilsModule = nil
local DatabaseModule = nil
local BuyInterfaceModule = nil
local SellInterfaceModule = nil

local maxScanSizePerPage = 120
local isScanningRunning = false
local scanDataSent = false

local ScanResultsCoroutine = nil
local scanFrame = nil

local hasCurrentPageBeenAdded = false

local resultsTableData = {}

function ScanModule:Enable()

	UtilsModule = AuctionBuddy:GetModule("UtilsModule")
	UtilsModule:Log(self, "Enable", 0)
	
	DatabaseModule = AuctionBuddy:GetModule("DatabaseModule")
	BuyInterfaceModule = AuctionBuddy:GetModule("BuyInterfaceModule")
	SellInterfaceModule = AuctionBuddy:GetModule("SellInterfaceModule")

	self:RegisterEvent("AUCTION_HOUSE_CLOSED")

	self:RegisterMessage("ON_AUCTION_HOUSE_SEARCH", self.AuctionHouseSearchStart)
	self:RegisterMessage("ON_SCAN_NEXT_AH_PAGE", self.AuctionHouseSearch)
	self:RegisterMessage("SCAN_SELECTED_ITEM_AH_PAGE", self.AuctionHouseSearch)

	self:RegisterMessage("REMOVE_SELECTED_RESULTS_ROW", self.RemoveSelectedResultsRow)
	self:RegisterMessage("POSTING_ITEM_TO_AH", self.ResetData)
	
	ScanResultsCoroutine = coroutine.create(ScanModule.ScanResults)

	scanFrame = CreateFrame("Frame")
	scanFrame:SetScript("OnUpdate", function(self)
		if CanSendAuctionQuery() and coroutine.status(ScanResultsCoroutine) == "suspended" and isScanningRunning and hasCurrentPageBeenAdded then 
			coroutine.resume(ScanResultsCoroutine)
		elseif CanSendAuctionQuery() and coroutine.status(ScanResultsCoroutine) == "dead" and isScanningRunning then
			ScanResultsCoroutine = coroutine.create(ScanModule.ScanResults)
		end
	end)

	self.searchActive = false
	self.page = 0

end

function ScanModule:AUCTION_ITEM_LIST_UPDATE()
	UtilsModule:Log(self, "AUCTION_ITEM_LIST_UPDATE", 1)
	
	if not isScanningRunning then
		ScanModule.shownPerBlizzardPage, ScanModule.total = GetNumAuctionItems("list")
		maxScanSizePerPage = ScanModule.total;
		isScanningRunning = true
	end

	if isScanningRunning then
		ScanModule:InsertResultsPage()
	end

	scanFrame:Show()
		
end

function ScanModule:AUCTION_HOUSE_CLOSED()
	UtilsModule:Log(self, "AUCTION_HOUSE_CLOSED", 0)

	scanFrame:Hide()
	isScanningRunning = false

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()

	ScanModule.searchText = ""
	
end

function ScanModule:AuctionHouseSearchStart(textToSearch, exactMatch, pageToSearch)
	UtilsModule:Log(self, "AuctionHouseSearchStart", 0)

	resultsTableData = {}
	ScanModule:SendResultsTable()
	ScanModule.page = 0

	ScanModule:SendMessage("ON_AH_SCAN_RUNNING", true)

	ScanModule:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	ScanModule:AuctionHouseSearch(textToSearch, exactMatch, pageToSearch)

end

function ScanModule:AuctionHouseSearch(textToSearch, exactMatch, pageToSearch)
	UtilsModule:Log(self, "AuctionHouseSearch", 0)

	if textToSearch ~= nil and textToSearch ~= AuctionBuddy.searchText then
		ScanModule.page = 0
	end

	if textToSearch ~= nil then
		AuctionBuddy.searchText = textToSearch
	end
	
	if CanSendAuctionQuery() then
		ScanModule.searchActive = true

		local checkWhiteSpaces = string.gsub(AuctionBuddy.searchText, " ", "")

		if string.len(AuctionBuddy.searchText) > 0 and string.len(checkWhiteSpaces) > 0 then
			DatabaseModule:InsertNewSearch(DatabaseModule.recentSearches, AuctionBuddy.searchText)
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
		print("Searching Page: ", currentPageToSearch)

		QueryAuctionItems(	
			AuctionBuddy.searchText, 
			BuyInterfaceModule.mainFrame.minILvl:GetNumber(),
			BuyInterfaceModule.mainFrame.maxILvl:GetNumber(), 
			currentPageToSearch,
			false,
			BuyInterfaceModule.mainFrame.rarity.value,
			false,
			DatabaseModule.buyOptions.exactMatch or exactMatch,
			filterData
		)
	else
		AuctionBuddy:SendMessage("AUCTIONBUDDY_ERROR", "CannotSendAHQuery")
	end
	
end

function ScanModule:ScanResults()
	UtilsModule:Log("ScanModule", "ScanResults", 0)

	local interval = math.max(ScanModule.shownPerBlizzardPage - 1, 1)
	local maxScanSize = math.min(maxScanSizePerPage, ScanModule.total)

	for currentScanSize = 0, maxScanSize, interval do
		print("loop1")
		
		ScanModule.page = ScanModule.page + 1

		coroutine.yield()

		if currentScanSize + interval < maxScanSize then
			ScanModule:SendMessage("ON_SCAN_NEXT_AH_PAGE")
		end
	end

	ScanModule:SendResultsTable()
	
end

function ScanModule:InsertResultsPage()
	UtilsModule:Log("ScanModule", "InsertResultsPage", 0)

	hasCurrentPageBeenAdded = false
	print(ScanModule.shownPerBlizzardPage)
	if not ScanModule.shownPerBlizzardPage then
		return
	end

	for i = 1, math.min(maxScanSizePerPage, ScanModule.shownPerBlizzardPage) do
		if i + (ScanModule.page - 1) * ScanModule.shownPerBlizzardPage > maxScanSizePerPage then
			print("breaking")
			print(ScanModule.page)
			print(i + ScanModule.page * ScanModule.shownPerBlizzardPage)
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

		print("adding")
		print(i + ScanModule.page * ScanModule.shownPerBlizzardPage)
		print(itemName)
		print(buyoutPrice)
		-- This data is compared to each index of columnType array from the CreateResultsScrollFrameTable function inside ResultsTable.lua
		tinsert(resultsTableData, 
		{
			texture = myTexture,
			itemLink = tostring(GetAuctionItemLink("list", i)),
			name = itemName,
			owner = tostring(aucOwner),
			count = aucCount,
			itlvl = itemLevel,
			bid = totalBidItem,
			buy = buyOutPerItem,
			totalPrice = buyoutPrice
		})
	end
	hasCurrentPageBeenAdded = true

end

function ScanModule:RemoveSelectedResultsRow(rowToRemove)
	UtilsModule:Log("ScanModule", "RemoveSelectedResultsRow", 2)

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
	end
	
	ScanModule:SendMessage("ON_AH_SCAN_RUNNING", false)
	scrollTable:Show()
	scrollTable:SetData(resultsTableData, true)

	scanFrame:Hide()
	isScanningRunning = false

	ScanModule:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")

end

function ScanModule:ResetData()

	ScanModule.shown = 0
	ScanModule.total = 0
	ScanModule.page = 0

end