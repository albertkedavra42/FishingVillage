local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function CreateRemoteFolder(name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	return folder
end

local function CreateRemoteEvent(parent: Folder, name: string): RemoteEvent
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = parent
	return event
end

local function CreateRemoteFunction(parent: Folder, name: string): RemoteFunction
	local func = Instance.new("RemoteFunction")
	func.Name = name
	func.Parent = parent
	return func
end

-- Initialize all remotes on server startup
function Remotes.Init()
	-- ==========================================
	-- FOLDER STRUCTURE
	-- ==========================================
	local remotesFolder = CreateRemoteFolder("Remotes")
	remotesFolder.Parent = ReplicatedStorage

	local serverToClient = CreateRemoteFolder("ServerToClient")
	serverToClient.Parent = remotesFolder

	local clientToServer = CreateRemoteFolder("ClientToServer")
	clientToServer.Parent = remotesFolder

	-- ==========================================
	-- SERVER → CLIENT EVENTS
	-- ==========================================
	local s2c = {}

	-- Player Data
	s2c.PlayerDataLoaded = CreateRemoteEvent(serverToClient, "PlayerDataLoaded")
	s2c.GoldChanged = CreateRemoteEvent(serverToClient, "GoldChanged")
	s2c.SalvageChanged = CreateRemoteEvent(serverToClient, "SalvageChanged")

	-- Boat
	s2c.BoatSpawned = CreateRemoteEvent(serverToClient, "BoatSpawned")
	s2c.BoatDamaged = CreateRemoteEvent(serverToClient, "BoatDamaged")
	s2c.BoatRepaired = CreateRemoteEvent(serverToClient, "BoatRepaired")
	s2c.FuelChanged = CreateRemoteEvent(serverToClient, "FuelChanged")
	s2c.HullChanged = CreateRemoteEvent(serverToClient, "HullChanged")

	-- Fishing
	s2c.FishBite = CreateRemoteEvent(serverToClient, "FishBite")
	s2c.FishCaught = CreateRemoteEvent(serverToClient, "FishCaught")
	s2c.FishEscaped = CreateRemoteEvent(serverToClient, "FishEscaped")
	s2c.FishingSpotUpdate = CreateRemoteEvent(serverToClient, "FishingSpotUpdate")

	-- Cargo
	s2c.CargoUpdated = CreateRemoteEvent(serverToClient, "CargoUpdated")
	s2c.CargoFull = CreateRemoteEvent(serverToClient, "CargoFull")

	-- Economy
	s2c.MarketPricesUpdated = CreateRemoteEvent(serverToClient, "MarketPricesUpdated")
	s2c.SaleCompleted = CreateRemoteEvent(serverToClient, "SaleCompleted")
	s2c.PurchaseCompleted = CreateRemoteEvent(serverToClient, "PurchaseCompleted")

	-- World
	s2c.TimeOfDayChanged = CreateRemoteEvent(serverToClient, "TimeOfDayChanged")
	s2c.WeatherChanged = CreateRemoteEvent(serverToClient, "WeatherChanged")
	s2c.DisasterWarning = CreateRemoteEvent(serverToClient, "DisasterWarning")
	s2c.DisasterStarted = CreateRemoteEvent(serverToClient, "DisasterStarted")
	s2c.DisasterEnded = CreateRemoteEvent(serverToClient, "DisasterEnded")

	-- Village
	s2c.VillageProjectUpdated = CreateRemoteEvent(serverToClient, "VillageProjectUpdated")
	s2c.VillageProjectCompleted = CreateRemoteEvent(serverToClient, "VillageProjectCompleted")

	-- Collection
	s2c.NewDiscovery = CreateRemoteEvent(serverToClient, "NewDiscovery")

	-- Notifications
	s2c.ShowNotification = CreateRemoteEvent(serverToClient, "ShowNotification")

	-- ==========================================
	-- CLIENT → SERVER FUNCTIONS
	-- ==========================================
	local c2s = {}

	-- Boat
	c2s.SpawnBoat = CreateRemoteFunction(clientToServer, "SpawnBoat")
	c2s.DespawnBoat = CreateRemoteFunction(clientToServer, "DespawnBoat")
	c2s.EnterBoat = CreateRemoteFunction(clientToServer, "EnterBoat")
	c2s.ExitBoat = CreateRemoteFunction(clientToServer, "ExitBoat")
	c2s.RequestRepair = CreateRemoteFunction(clientToServer, "RequestRepair")
	c2s.RequestUpgrade = CreateRemoteFunction(clientToServer, "RequestUpgrade")

	-- Fishing
	c2s.CastLine = CreateRemoteFunction(clientToServer, "CastLine")
	c2s.ReelIn = CreateRemoteFunction(clientToServer, "ReelIn")
	c2s.SetFishingMode = CreateRemoteFunction(clientToServer, "SetFishingMode") -- Rod/Net

	-- Cargo
	c2s.PlaceFishInCargo = CreateRemoteFunction(clientToServer, "PlaceFishInCargo")
	c2s.RemoveFishFromCargo = CreateRemoteFunction(clientToServer, "RemoveFishFromCargo")
	c2s.DiscardFish = CreateRemoteFunction(clientToServer, "DiscardFish")

	-- Economy
	c2s.SellFish = CreateRemoteFunction(clientToServer, "SellFish")
	c2s.BuyItem = CreateRemoteFunction(clientToServer, "BuyItem")
	c2s.ListPlayerStall = CreateRemoteFunction(clientToServer, "ListPlayerStall")
	c2s.RemoveStallListing = CreateRemoteFunction(clientToServer, "RemoveStallListing")
	c2s.BuyFromPlayerStall = CreateRemoteFunction(clientToServer, "BuyFromPlayerStall")

	-- Village
	c2s.ContributeToProject = CreateRemoteFunction(clientToServer, "ContributeToProject")

	-- Smokehouse
	c2s.ProcessFish = CreateRemoteFunction(clientToServer, "ProcessFish")
	c2s.CollectProcessed = CreateRemoteFunction(clientToServer, "CollectProcessed")

	-- Supplies
	c2s.ActivateIce = CreateRemoteFunction(clientToServer, "ActivateIce")

	-- Museum
	c2s.DonateToMuseum = CreateRemoteFunction(clientToServer, "DonateToMuseum")

	-- Navigation
	c2s.TravelToZone = CreateRemoteFunction(clientToServer, "TravelToZone")

	-- Orders
	c2s.GetOrders = CreateRemoteFunction(clientToServer, "GetOrders")
	c2s.AcceptOrder = CreateRemoteFunction(clientToServer, "AcceptOrder")
	c2s.FulfillOrder = CreateRemoteFunction(clientToServer, "FulfillOrder")

	-- ==========================================
	-- CLIENT → SERVER EVENTS (for fire-and-forget)
	-- ==========================================
	s2c.PlayerStallBrowse = CreateRemoteEvent(clientToServer, "PlayerStallBrowse")

	Remotes.ServerToClient = s2c
	Remotes.ClientToServer = c2s

	return remotesFolder
end

-- Get remote references (call after Init)
function Remotes.GetServerToClient()
	return Remotes.ServerToClient
end

function Remotes.GetClientToServer()
	return Remotes.ClientToServer
end

return Remotes
