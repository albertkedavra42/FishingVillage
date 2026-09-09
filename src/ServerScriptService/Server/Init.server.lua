local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- ==========================================
-- INITIALIZATION ORDER MATTERS
-- ==========================================

-- 1. Initialize Remotes (must be first, other services reference them)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
Remotes.Init()

-- 2. Initialize World (time, weather, disasters)
local WorldService = require(ServerScriptService.Server.WorldService)
WorldService.Init()

-- 3. Initialize Economy (market prices)
local EconomyService = require(ServerScriptService.Server.EconomyService)
EconomyService.Init()

-- 4. Initialize Fishing (populations)
local FishingService = require(ServerScriptService.Server.FishingService)
FishingService.Init()

-- 5. Player Data, Boat, Cargo init on player join
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local BoatService = require(ServerScriptService.Server.BoatService)
local CargoService = require(ServerScriptService.Server.CargoService)
local DockInteraction = require(ServerScriptService.Server.DockInteraction)

PlayerDataService.Init()
BoatService.Init()
CargoService.Init()
DockInteraction.Init()

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

local s2c = Remotes.GetServerToClient()
local c2s = Remotes.GetClientToServer()

-- Boat Remotes
c2s.SpawnBoat.OnServerInvoke = function(player)
	local success, data = DockInteraction.SpawnBoatAtDock(player)
	if success then
		local profile = PlayerDataService.GetProfile(player)
		if profile then
			CargoService.InitPlayerCargo(player, profile.Boat.BoatId)
		end
		s2c.BoatSpawned:FireClient(player, BoatService.GetBoat(player))
	end
	return success, data
end

c2s.DespawnBoat.OnServerInvoke = function(player)
	return DockInteraction.ExitBoat(player)
end

c2s.EnterBoat.OnServerInvoke = function(player)
	return DockInteraction.EnterBoat(player)
end

c2s.ExitBoat.OnServerInvoke = function(player)
	return DockInteraction.ExitBoat(player)
end

c2s.RequestRepair.OnServerInvoke = function(player)
	local cost = BoatService.CalculateRepairCost(player)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false, Cost = 0 }
	end

	if profile.Gold < cost then
		return { Success = false, Cost = cost, Reason = "Not enough gold" }
	end

	PlayerDataService.UpdateGold(player, -cost)
	s2c.GoldChanged:FireClient(player, profile.Gold)

	local result = BoatService.RepairBoat(player, cost)
	if result.Success then
		s2c.BoatRepaired:FireClient(player, BoatService.GetBoat(player))
	end
	return result
end

c2s.RequestUpgrade.OnServerInvoke = function(player, newBoatId)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false }
	end

	local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)
	local newBoat = BoatDefinitions.GetBoat(newBoatId)
	if not newBoat then
		return { Success = false, Reason = "Invalid boat" }
	end

	if profile.Gold < newBoat.Cost then
		return { Success = false, Reason = "Not enough gold" }
	end

	if newBoat.RequiredProject then
		local projectDone = profile.Progression.VillageContributions[newBoat.RequiredProject]
		if not projectDone then
			return { Success = false, Reason = "Village project required" }
		end
	end

	PlayerDataService.UpdateGold(player, -newBoat.Cost)
	s2c.GoldChanged:FireClient(player, profile.Gold)

	BoatService.UpgradeBoat(player, newBoatId)
	CargoService.InitPlayerCargo(player, newBoatId)

	return { Success = true, Boat = BoatService.GetBoat(player) }
end

-- Fishing Remotes
c2s.CastLine.OnServerInvoke = function(player, zoneId, spotId, method)
	local boat = BoatService.GetBoat(player)
	if not boat or not boat.IsInBoat then
		return { Success = false, Reason = "Not in boat" }
	end

	if boat.Fuel <= 0 then
		return { Success = false, Reason = "No fuel" }
	end

	FishingService.StartFishing(player, zoneId, spotId, method)

	local biteTime = FishingService.CalculateBiteTime(zoneId, WorldService.GetCurrentTimePhase(), method)

	-- Fire FishBite event to client after delay
	task.delay(biteTime, function()
		-- Verify player is still fishing
		local active = FishingService.GetActiveFishing(player)
		if active then
			s2c.FishBite:FireClient(player, {
				ZoneId = zoneId,
				SpotId = spotId,
				Method = method,
			})
		end
	end)

	return {
		Success = true,
		BiteTime = biteTime,
		ZoneId = zoneId,
		SpotId = spotId,
	}
end

c2s.ReelIn.OnServerInvoke = function(player, success)
	-- Capture active fishing data BEFORE stopping
	local active = FishingService.GetActiveFishing(player)
	FishingService.StopFishing(player)

	if not success then
		return { Caught = false }
	end

	if not active then
		return { Caught = false, Reason = "Not fishing" }
	end

	local zoneId = active.ZoneId
	local timePhase = WorldService.GetCurrentTimePhase()
	local method = active.Method or "Rod"

	local catch = FishingService.SelectCatch(zoneId, timePhase, method)
	if not catch then
		return { Caught = false, Reason = "Nothing bit" }
	end

	-- Calculate value
	local FishDefs = require(ReplicatedStorage.Shared.Config.FishDefinitions)
	local variantMod = FishDefs.VariantModifiers[catch.Variant]
	local speciesDef = FishDefs.GetSpecies(catch.SpeciesId)
	local baseValue = speciesDef and speciesDef.BaseValue or 10
	local value = math.floor(baseValue * (variantMod and variantMod.ValueMultiplier or 1))
	local decayRate = speciesDef and speciesDef.FreshnessDecayRate or 0.5

	-- Try to place in cargo
	local placed = CargoService.PlaceItem(
		player,
		catch.SpeciesId,
		catch.SpeciesId,
		catch.Variant,
		catch.Size[1],
		catch.Size[2],
		catch.Weight,
		value,
		1.0,
		decayRate
	)

	if not placed then
		s2c.CargoFull:FireClient(player)
		return { Caught = false, Reason = "Cargo full" }
	end

	-- Track collection
	local isNewDiscovery = not PlayerDataService.HasDiscovery(player, "Species", catch.SpeciesId)
	PlayerDataService.AddDiscovery(player, "Species", catch.SpeciesId)
	PlayerDataService.AddDiscovery(player, "Variant", catch.SpeciesId .. "_" .. catch.Variant)
	PlayerDataService.IncrementStat(player, "TotalFishCaught")

	if isNewDiscovery then
		s2c.NewDiscovery:FireClient(player, "Species", catch.SpeciesId)
	end

	s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

	return {
		Caught = true,
		SpeciesId = catch.SpeciesId,
		Variant = catch.Variant,
		Weight = catch.Weight,
		Size = catch.Size,
		Value = value,
		IsNewDiscovery = isNewDiscovery,
	}
end

c2s.SetFishingMode.OnServerInvoke = function(player, mode)
	-- Rod or Net
	return { Success = true, Mode = mode }
end

-- Cargo Remotes
c2s.PlaceFishInCargo.OnServerInvoke = function(player, speciesId, variant, width, height, weight, value)
	local placed = CargoService.PlaceItem(player, speciesId, speciesId, variant, width, height, weight, value, 1.0)
	if placed then
		s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))
	end
	return { Success = placed }
end

c2s.RemoveFishFromCargo.OnServerInvoke = function(player, itemRef)
	local removed = CargoService.RemoveItem(player, itemRef)
	if removed then
		s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))
	end
	return { Success = removed }
end

c2s.DiscardFish.OnServerInvoke = function(player, itemRef)
	local removed = CargoService.RemoveItem(player, itemRef)
	if removed then
		s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))
	end
	return { Success = removed }
end

-- Economy Remotes
c2s.SellFish.OnServerInvoke = function(player, itemRefs)
	local cargo = CargoService.GetCargo(player)
	if not cargo then
		return { Success = false }
	end

	local totalGold = 0
	local soldItems = {}

	for _, ref in itemRefs do
		for _, item in cargo.Items do
			if item.Ref == ref then
				local value = EconomyService.CalculateFishValue(
					item.SpeciesId or item.ItemId,
					item.Variant or "Normal",
					item.Freshness
				)
				totalGold = totalGold + value
				table.insert(soldItems, { ItemId = item.ItemId, Value = value })
				CargoService.RemoveItem(player, ref)
				EconomyService.RecordSale(item.SpeciesId or item.ItemId, 1)
				break
			end
		end
	end

	if totalGold > 0 then
		PlayerDataService.UpdateGold(player, totalGold)
		s2c.GoldChanged:FireClient(player, PlayerDataService.GetProfile(player).Gold)
		s2c.SaleCompleted:FireClient(player, { TotalGold = totalGold, Items = soldItems })
		PlayerDataService.IncrementStat(player, "TotalGoldEarned", totalGold)
	end

	return { Success = totalGold > 0, TotalGold = totalGold, Items = soldItems }
end

c2s.BuyItem.OnServerInvoke = function(player, itemId, quantity)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false }
	end

	local ItemDefinitions = require(ReplicatedStorage.Shared.Config.ItemDefinitions)
	local itemDef = ItemDefinitions.GetItem(itemId)
	if not itemDef then
		return { Success = false, Reason = "Invalid item" }
	end

	local totalCost = itemDef.BaseValue * (quantity or 1)
	if profile.Gold < totalCost then
		return { Success = false, Reason = "Not enough gold" }
	end

	PlayerDataService.UpdateGold(player, -totalCost)
	s2c.GoldChanged:FireClient(player, profile.Gold)

	return { Success = true, Cost = totalCost }
end

-- ==========================================
-- PLAYER STALLS
-- ==========================================

local PlayerStalls = {} -- [sellerId] = { { ItemRef, SpeciesId, Variant, Weight, Width, Height, Freshness, Value, Price, SellerName } }

local function GetStallListings(sellerId)
	return PlayerStalls[sellerId] or {}
end

local function AddStallListing(sellerId, listing)
	if not PlayerStalls[sellerId] then
		PlayerStalls[sellerId] = {}
	end
	table.insert(PlayerStalls[sellerId], listing)
end

local function RemoveStallListing(sellerId, itemRef)
	local listings = PlayerStalls[sellerId]
	if not listings then return false end
	for i, listing in listings do
		if listing.ItemRef == itemRef then
			table.remove(listings, i)
			return true
		end
	end
	return false
end

-- Player Stall Remotes
c2s.ListPlayerStall.OnServerInvoke = function(player, itemRef, price)
	local cargo = CargoService.GetCargo(player)
	if not cargo then
		return { Success = false, Reason = "No cargo" }
	end

	if not price or price <= 0 then
		return { Success = false, Reason = "Invalid price" }
	end

	-- Find item in cargo
	for _, item in cargo.Items do
		if item.Ref == itemRef then
			CargoService.RemoveItem(player, itemRef)
			s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

			local listing = {
				ItemRef = itemRef,
				SpeciesId = item.SpeciesId,
				ItemId = item.ItemId,
				Variant = item.Variant or "Normal",
				Weight = item.Weight,
				Width = item.Width,
				Height = item.Height,
				Freshness = item.Freshness,
				Value = item.Value,
				Price = price,
				SellerId = player.UserId,
				SellerName = player.Name,
			}

			AddStallListing(player.UserId, listing)

			-- Notify all players of new listing
			for _, p in Players:GetPlayers() do
				s2c.ShowNotification:FireClient(p, player.Name .. " listed " .. (item.SpeciesId or item.ItemId) .. " for " .. price .. " Gold")
			end

			return { Success = true, Listing = listing }
		end
	end

	return { Success = false, Reason = "Item not found in cargo" }
end

c2s.RemoveStallListing.OnServerInvoke = function(player, itemRef)
	local removed = RemoveStallListing(player.UserId, itemRef)
	return { Success = removed }
end

c2s.BuyFromPlayerStall.OnServerInvoke = function(player, sellerId, itemRef, price)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false, Reason = "No profile" }
	end

	if profile.Gold < price then
		return { Success = false, Reason = "Not enough gold" }
	end

	-- Find the listing
	local listings = GetStallListings(sellerId)
	local listing = nil
	for _, l in listings do
		if l.ItemRef == itemRef then
			listing = l
			break
		end
	end

	if not listing then
		return { Success = false, Reason = "Listing not found" }
	end

	-- Deduct gold from buyer
	PlayerDataService.UpdateGold(player, -price)
	s2c.GoldChanged:FireClient(player, profile.Gold)

	-- Give gold to seller
	local sellerProfile = nil
	for _, p in Players:GetPlayers() do
		if p.UserId == sellerId then
			sellerProfile = PlayerDataService.GetProfile(p)
			if sellerProfile then
				PlayerDataService.UpdateGold(p, price)
				s2c.GoldChanged:FireClient(p, sellerProfile.Gold)
			end
			break
		end
	end

	-- Place fish in buyer's cargo
	local placed = CargoService.PlaceItem(
		player,
		listing.ItemId or listing.SpeciesId,
		listing.SpeciesId,
		listing.Variant,
		listing.Width,
		listing.Height,
		listing.Weight,
		listing.Value,
		listing.Freshness
	)

	if not placed then
		-- Refund buyer if cargo full
		PlayerDataService.UpdateGold(player, price)
		s2c.GoldChanged:FireClient(player, profile.Gold)
		if sellerProfile then
			PlayerDataService.UpdateGold(Players:GetPlayerById(sellerId), -price)
		end
		return { Success = false, Reason = "Your cargo is full" }
	end

	-- Remove listing
	RemoveStallListing(sellerId, itemRef)

	-- Update buyer's cargo display
	s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

	-- Notify both players
	s2c.ShowNotification:FireClient(player, "Purchased " .. (listing.SpeciesId or listing.ItemId) .. " for " .. price .. " Gold!")
	local sellerPlayer = Players:GetPlayerById(sellerId)
	if sellerPlayer then
		s2c.ShowNotification:FireClient(sellerPlayer, player.Name .. " bought your " .. (listing.SpeciesId or listing.ItemId) .. " for " .. price .. " Gold!")
	end

	return { Success = true }
end

-- ==========================================
-- VILLAGE PROJECTS
-- ==========================================

local VillageProjects = {
	Lighthouse = {
		ProjectId = "Lighthouse",
		DisplayName = "Lighthouse",
		Description = "Improves night fishing and navigation.",
		GoldRequired = 2000,
		SalvageRequired = 10,
		UnlocksZone = nil,
		Completed = false,
		TotalGold = 0,
		TotalSalvage = 0,
	},
	Shipyard = {
		ProjectId = "Shipyard",
		DisplayName = "Shipyard",
		Description = "Unlocks better repairs and the Coastal Fishing Boat.",
		GoldRequired = 3000,
		SalvageRequired = 20,
		UnlocksZone = "Estuary",
		Completed = false,
		TotalGold = 0,
		TotalSalvage = 0,
	},
	HarborExpansion = {
		ProjectId = "HarborExpansion",
		DisplayName = "Harbor Expansion",
		Description = "Unlocks the Open Sea and Commercial Fishing Boat.",
		GoldRequired = 5000,
		SalvageRequired = 30,
		UnlocksZone = "OpenSea",
		Completed = false,
		TotalGold = 0,
		TotalSalvage = 0,
	},
}

local function CheckProjectCompletion(projectId)
	local project = VillageProjects[projectId]
	if not project or project.Completed then
		return false
	end

	if project.TotalGold >= project.GoldRequired and project.TotalSalvage >= project.SalvageRequired then
		project.Completed = true

		-- Unlock zone for all players
		if project.UnlocksZone then
			for _, p in Players:GetPlayers() do
				PlayerDataService.UnlockZone(p, project.UnlocksZone)
			end
		end

		-- Notify all players
		for _, p in Players:GetPlayers() do
			s2c.VillageProjectCompleted:FireClient(p, {
				ProjectId = projectId,
				DisplayName = project.DisplayName,
				UnlocksZone = project.UnlocksZone,
			})
			s2c.ShowNotification:FireClient(p, project.DisplayName .. " has been completed!")
		end

		print("[VillageProjects] " .. project.DisplayName .. " completed!")
		return true
	end

	return false
end

-- Village Project Remotes
c2s.ContributeToProject.OnServerInvoke = function(player, projectId, goldAmount, salvageAmount)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false }
	end

	local project = VillageProjects[projectId]
	if not project then
		return { Success = false, Reason = "Invalid project" }
	end

	if project.Completed then
		return { Success = false, Reason = "Already completed" }
	end

	if goldAmount and goldAmount > 0 then
		if profile.Gold < goldAmount then
			return { Success = false, Reason = "Not enough gold" }
		end
		PlayerDataService.UpdateGold(player, -goldAmount)
		s2c.GoldChanged:FireClient(player, profile.Gold)
		project.TotalGold = project.TotalGold + goldAmount
	end

	if salvageAmount and salvageAmount > 0 then
		if profile.Salvage < salvageAmount then
			return { Success = false, Reason = "Not enough salvage" }
		end
		PlayerDataService.UpdateSalvage(player, -salvageAmount)
		s2c.SalvageChanged:FireClient(player, profile.Salvage)
		project.TotalSalvage = project.TotalSalvage + salvageAmount
	end

	-- Track personal contribution
	profile.Progression.VillageContributions[projectId] = (profile.Progression.VillageContributions[projectId] or 0) + (goldAmount or 0) + (salvageAmount or 0)

	-- Send progress update to contributing player
	s2c.VillageProjectUpdated:FireClient(player, {
		ProjectId = projectId,
		DisplayName = project.DisplayName,
		TotalGold = project.TotalGold,
		GoldRequired = project.GoldRequired,
		TotalSalvage = project.TotalSalvage,
		SalvageRequired = project.SalvageRequired,
		Completed = project.Completed,
	})

	-- Broadcast progress to all players
	for _, p in Players:GetPlayers() do
		if p ~= player then
			s2c.VillageProjectUpdated:FireClient(p, {
				ProjectId = projectId,
				DisplayName = project.DisplayName,
				TotalGold = project.TotalGold,
				GoldRequired = project.GoldRequired,
				TotalSalvage = project.TotalSalvage,
				SalvageRequired = project.SalvageRequired,
				Completed = project.Completed,
			})
		end
	end

	-- Check if project is now complete
	CheckProjectCompletion(projectId)

	return { Success = true }
end

-- Function to get project state (for UI)
local function GetProjectState(projectId)
	local project = VillageProjects[projectId]
	if not project then return nil end
	return {
		ProjectId = project.ProjectId,
		DisplayName = project.DisplayName,
		Description = project.Description,
		TotalGold = project.TotalGold,
		GoldRequired = project.GoldRequired,
		TotalSalvage = project.TotalSalvage,
		SalvageRequired = project.SalvageRequired,
		Completed = project.Completed,
		UnlocksZone = project.UnlocksZone,
	}
end

-- ==========================================
-- SMOKEHOUSE PROCESSING
-- ==========================================

local ItemDefinitions = require(ReplicatedStorage.Shared.Config.ItemDefinitions)

local ProcessingQueue = {} -- [userId] = { { InputRef, InputSpeciesId, OutputItemId, StartedAt, Duration, Ready } }

local PROCESSING_TIME = 30 -- seconds

local function GetSmokedOutput(speciesId)
	-- Map raw fish to smoked output
	local outputMap = {
		Cod = "SmokedCod",
		Mackerel = "SmokedMackerel",
		Moonfin = "SmokedMoonfin",
	}
	return outputMap[speciesId]
end

-- Smokehouse Remotes
c2s.ProcessFish.OnServerInvoke = function(player, itemRef)
	local cargo = CargoService.GetCargo(player)
	if not cargo then
		return { Success = false, Reason = "No cargo" }
	end

	-- Check if already processing
	local queue = ProcessingQueue[player.UserId]
	if queue and #queue > 0 then
		for _, entry in queue do
			if not entry.Ready then
				return { Success = false, Reason = "Already processing another fish" }
			end
		end
	end

	-- Find item in cargo
	for _, item in cargo.Items do
		if item.Ref == itemRef then
			-- Check if fish can be smoked
			local FishDefs = require(ReplicatedStorage.Shared.Config.FishDefinitions)
			local species = FishDefs.GetSpecies(item.SpeciesId)
			if not species then
				return { Success = false, Reason = "Cannot process this item" }
			end

			local outputItemId = GetSmokedOutput(item.SpeciesId)
			if not outputItemId then
				return { Success = false, Reason = "This fish cannot be smoked" }
			end

			local outputDef = ItemDefinitions.GetItem(outputItemId)
			if not outputDef then
				return { Success = false, Reason = "Output item not found" }
			end

			-- Remove raw fish from cargo
			CargoService.RemoveItem(player, itemRef)
			s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

			-- Start processing
			if not ProcessingQueue[player.UserId] then
				ProcessingQueue[player.UserId] = {}
			end

			local entry = {
				InputRef = itemRef,
				InputSpeciesId = item.SpeciesId,
				OutputItemId = outputItemId,
				OutputWidth = outputDef.GridWidth or 2,
				OutputHeight = outputDef.GridHeight or 2,
				Weight = item.Weight,
				StartedAt = tick(),
				Duration = PROCESSING_TIME,
				Ready = false,
			}

			table.insert(ProcessingQueue[player.UserId], entry)

			-- Notify client
			s2c.ShowNotification:FireClient(player, "Processing " .. item.SpeciesId .. "...")

			return {
				Success = true,
				ProcessingTime = PROCESSING_TIME,
				OutputItem = outputItemId,
			}
		end
	end

	return { Success = false, Reason = "Item not found in cargo" }
end

c2s.CollectProcessed.OnServerInvoke = function(player)
	local queue = ProcessingQueue[player.UserId]
	if not queue or #queue == 0 then
		return { Success = false, Reason = "Nothing being processed" }
	end

	-- Find first ready entry
	for i, entry in queue do
		if entry.Ready then
			-- Place smoked fish in cargo
			local placed = CargoService.PlaceItem(
				player,
				entry.OutputItemId,
				entry.InputSpeciesId,
				"Smoked",
				entry.OutputWidth,
				entry.OutputHeight,
				entry.Weight,
				0,
				1.0
			)

			if placed then
				table.remove(queue, i)
				s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))
				s2c.ShowNotification:FireClient(player, "Collected " .. entry.OutputItemId .. "!")
				return { Success = true, OutputItem = entry.OutputItemId }
			else
				return { Success = false, Reason = "Cargo full" }
			end
		end
	end

	return { Success = false, Reason = "Processing not complete yet" }
end

-- Ice/Supply Activation
c2s.ActivateIce.OnServerInvoke = function(player, itemId)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false, Reason = "No profile" }
	end

	local ItemDefinitions = require(ReplicatedStorage.Shared.Config.ItemDefinitions)
	local itemDef = ItemDefinitions.GetItem(itemId)
	if not itemDef or itemDef.Category ~= "Supply" then
		return { Success = false, Reason = "Invalid supply item" }
	end

	-- Check if player owns this item (simplified: deduct gold, apply effect)
	if profile.Gold < itemDef.BaseValue then
		return { Success = false, Reason = "Not enough gold" }
	end

	PlayerDataService.UpdateGold(player, -itemDef.BaseValue)
	s2c.GoldChanged:FireClient(player, profile.Gold)

	-- Activate ice effect on cargo
	local success = CargoService.ActivateIce(player, itemId)
	if success then
		s2c.ShowNotification:FireClient(player, itemDef.DisplayName .. " activated! Decay reduced for " .. tostring(math.floor(itemDef.Duration / 60)) .. " minutes.")
		return { Success = true, Duration = itemDef.Duration, Modifier = itemDef.FreshnessModifier }
	else
		-- Refund if activation failed
		PlayerDataService.UpdateGold(player, itemDef.BaseValue)
		s2c.GoldChanged:FireClient(player, profile.Gold)
		return { Success = false, Reason = "Could not activate" }
	end
end

-- Check processing timers (called from world update loop)
local function UpdateProcessing()
	for userId, queue in ProcessingQueue do
		for i = #queue, 1, -1 do
			local entry = queue[i]
			if not entry.Ready then
				if tick() - entry.StartedAt >= entry.Duration then
					entry.Ready = true
					-- Notify player
					local p = Players:GetPlayerById(userId)
					if p then
						s2c.ShowNotification:FireClient(p, entry.OutputItemId .. " is ready to collect!")
					end
				end
			end
		end
	end
end

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player)
	ProcessingQueue[player.UserId] = nil
	PlayerStalls[player.UserId] = nil
end)

-- ==========================================
-- MUSEUM / COLLECTION
-- ==========================================

local MuseumState = {
	DonatedSpecies = {}, -- [speciesId] = true
	DonatedVariants = {}, -- [speciesId_variant] = true
	DonationCount = 0,
}

c2s.DonateToMuseum.OnServerInvoke = function(player, itemRef)
	local cargo = CargoService.GetCargo(player)
	if not cargo then
		return { Success = false, Reason = "No cargo" }
	end

	-- Find matching fish in cargo
	for _, item in cargo.Items do
		if item.Ref == itemRef then
			local speciesId = item.SpeciesId
			local variant = item.Variant or "Normal"
			local variantKey = speciesId .. "_" .. variant

			-- Check if already donated
			local isNewSpecies = not MuseumState.DonatedSpecies[speciesId]
			local isNewVariant = not MuseumState.DonatedVariants[variantKey]

			-- Remove from cargo
			CargoService.RemoveItem(player, itemRef)
			s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

			-- Update museum state
			MuseumState.DonatedSpecies[speciesId] = true
			MuseumState.DonatedVariants[variantKey] = true
			MuseumState.DonationCount = MuseumState.DonationCount + 1

			-- Update player collection
			PlayerDataService.AddDiscovery(player, "Species", speciesId)
			PlayerDataService.AddDiscovery(player, "Variant", variantKey)

			-- Notify player
			if isNewSpecies or isNewVariant then
				s2c.NewDiscovery:FireClient(player, "MuseumDonation", speciesId)
				local msg = "New museum donation: " .. speciesId
				if variant ~= "Normal" then
					msg = msg .. " (" .. variant .. ")"
				end
				s2c.ShowNotification:FireClient(player, msg .. "!")
			else
				s2c.ShowNotification:FireClient(player, "Donated " .. speciesId .. " to the museum.")
			end

			-- Track stat
			PlayerDataService.IncrementStat(player, "MuseumDonations")

			return {
				Success = true,
				IsNewSpecies = isNewSpecies,
				IsNewVariant = isNewVariant,
				DonationCount = MuseumState.DonationCount,
			}
		end
	end

	return { Success = false, Reason = "Fish not found in cargo" }
end

-- ==========================================
-- NPC ORDER BOARD
-- ==========================================

local OrderBoard = {
	ActiveOrders = {}, -- [orderId] = order data
	AcceptedOrders = {}, -- [playerId] = { orderId, acceptedAt }
	OrderCounter = 0,
}

local ORDER_TEMPLATES = {
	{ SpeciesId = "Cod", MinQty = 5, MaxQty = 15, BaseReward = 80, TimeLimit = 600 },
	{ SpeciesId = "Sardine", MinQty = 8, MaxQty = 20, BaseReward = 60, TimeLimit = 600 },
	{ SpeciesId = "Mackerel", MinQty = 5, MaxQty = 12, BaseReward = 120, TimeLimit = 600 },
	{ SpeciesId = "Flatfish", MinQty = 3, MaxQty = 10, BaseReward = 100, TimeLimit = 600 },
	{ SpeciesId = "Moonfin", MinQty = 2, MaxQty = 5, BaseReward = 300, TimeLimit = 900 },
	{ SpeciesId = "Sea Bass", MinQty = 3, MaxQty = 8, BaseReward = 200, TimeLimit = 600 },
	{ SpeciesId = "Eel", MinQty = 2, MaxQty = 6, BaseReward = 250, TimeLimit = 600 },
	{ SpeciesId = "Crab", MinQty = 5, MaxQty = 15, BaseReward = 150, TimeLimit = 600 },
	{ SpeciesId = "Tuna", MinQty = 2, MaxQty = 5, BaseReward = 400, TimeLimit = 900 },
	{ SpeciesId = "Swordfish", MinQty = 1, MaxQty = 3, BaseReward = 500, TimeLimit = 900 },
}

local RESTAURANT_NAMES = {
	"The Salty Anchor", "Harbor View Diner", "Moonfin Kitchen", "The Fisherman's Rest",
	"Dockside Grill", "Deep Sea Bistro", "Coastal Catch Café", "Trawler's Table",
}

local function GenerateOrder()
	local template = ORDER_TEMPLATES[math.random(1, #ORDER_TEMPLATES)]
	local quantity = math.random(template.MinQty, template.MaxQty)
	local reward = math.floor(template.BaseReward * (quantity / template.MinQty))

	OrderBoard.OrderCounter += 1
	return {
		OrderId = "Order_" .. OrderBoard.OrderCounter,
		RestaurantName = RESTAURANT_NAMES[math.random(1, #RESTAURANT_NAMES)],
		SpeciesId = template.SpeciesId,
		Quantity = quantity,
		Reward = reward,
		TimeLimit = template.TimeLimit,
		CreatedAt = tick(),
		ExpiresAt = tick() + template.TimeLimit,
	}
end

local function RefreshOrders()
	-- Remove expired orders
	for orderId, order in OrderBoard.ActiveOrders do
		if tick() > order.ExpiresAt then
			OrderBoard.ActiveOrders[orderId] = nil
		end
	end

	-- Generate new orders if needed
	while #OrderBoard.ActiveOrders < 5 do
		local order = GenerateOrder()
		OrderBoard.ActiveOrders[order.OrderId] = order
	end
end

-- Generate initial orders
RefreshOrders()

-- Refresh orders periodically
task.spawn(function()
	while true do
		task.wait(60)
		RefreshOrders()
	end
end)

c2s.GetOrders.OnServerInvoke = function(player)
	RefreshOrders()
	local orders = {}
	for _, order in OrderBoard.ActiveOrders do
		table.insert(orders, order)
	end
	return { Success = true, Orders = orders }
end

c2s.AcceptOrder.OnServerInvoke = function(player, orderId)
	local order = OrderBoard.ActiveOrders[orderId]
	if not order then
		return { Success = false, Reason = "Order not found" }
	end

	if tick() > order.ExpiresAt then
		OrderBoard.ActiveOrders[orderId] = nil
		return { Success = false, Reason = "Order expired" }
	end

	-- Check if player already has an order
	if OrderBoard.AcceptedOrders[player.UserId] then
		return { Success = false, Reason = "You already have an active order" }
	end

	OrderBoard.AcceptedOrders[player.UserId] = {
		OrderId = orderId,
		AcceptedAt = tick(),
	}

	s2c.ShowNotification:FireClient(player, "Order accepted: " .. order.Quantity .. "x " .. order.SpeciesId .. " for " .. order.Reward .. " Gold")
	return { Success = true, Order = order }
end

c2s.FulfillOrder.OnServerInvoke = function(player)
	local accepted = OrderBoard.AcceptedOrders[player.UserId]
	if not accepted then
		return { Success = false, Reason = "No active order" }
	end

	local order = OrderBoard.ActiveOrders[accepted.OrderId]
	if not order then
		OrderBoard.AcceptedOrders[player.UserId] = nil
		return { Success = false, Reason = "Order no longer available" }
	end

	if tick() > order.ExpiresAt then
		OrderBoard.ActiveOrders[accepted.OrderId] = nil
		OrderBoard.AcceptedOrders[player.UserId] = nil
		return { Success = false, Reason = "Order expired" }
	end

	-- Count matching fish in cargo
	local cargo = CargoService.GetCargo(player)
	if not cargo then
		return { Success = false, Reason = "No cargo" }
	end

	local matchingFish = {}
	for _, item in cargo.Items do
		if item.SpeciesId == order.SpeciesId then
			table.insert(matchingFish, item)
		end
	end

	if #matchingFish < order.Quantity then
		return { Success = false, Reason = "Need " .. order.Quantity .. "x " .. order.SpeciesId .. " (have " .. #matchingFish .. ")" }
	end

	-- Remove fish from cargo (take the required amount)
	local removed = 0
	for i = #matchingFish, 1, -1 do
		if removed >= order.Quantity then
			break
		end
		CargoService.RemoveItem(player, matchingFish[i].Ref)
		removed += 1
	end

	-- Pay reward
	PlayerDataService.UpdateGold(player, order.Reward)
	s2c.GoldChanged:FireClient(player, PlayerDataService.GetProfile(player).Gold)
	s2c.CargoUpdated:FireClient(player, CargoService.GetCargo(player))

	-- Clear order
	OrderBoard.ActiveOrders[accepted.OrderId] = nil
	OrderBoard.AcceptedOrders[player.UserId] = nil

	-- Track stat
	PlayerDataService.IncrementStat(player, "OrdersCompleted")

	s2c.ShowNotification:FireClient(player, "Order fulfilled! Earned " .. order.Reward .. " Gold!")
	return { Success = true, Reward = order.Reward }
end

-- Clean up orders on player leave
Players.PlayerRemoving:Connect(function(player)
	OrderBoard.AcceptedOrders[player.UserId] = nil
end)

-- Navigation Remotes
c2s.TravelToZone.OnServerInvoke = function(player, zoneId)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return { Success = false }
	end

	if not PlayerDataService.HasZone(player, zoneId) then
		return { Success = false, Reason = "Zone not unlocked" }
	end

	local boat = BoatService.GetBoat(player)
	if not boat or not boat.IsSpawned then
		return { Success = false, Reason = "No boat" }
	end

	if boat.Fuel <= 0 then
		return { Success = false, Reason = "No fuel" }
	end

	boat.CurrentZone = zoneId
	return { Success = true, ZoneId = zoneId }
end

-- ==========================================
-- WORLD UPDATE LOOP
-- ==========================================

task.spawn(function()
	while true do
		task.wait(WORLD_TICK_RATE)

		local phaseChanged = WorldService.Update(WORLD_TICK_RATE)

		if phaseChanged then
			-- Notify all players of time change
			local worldState = WorldService.GetWorldState()
			for _, player in Players:GetPlayers() do
				s2c.TimeOfDayChanged:FireClient(player, worldState)
			end
		end

		-- Regenerate fish populations
		FishingService.RegeneratePopulations(WORLD_TICK_RATE)

		-- Update smokehouse processing timers
		UpdateProcessing()

		-- Update cargo freshness for all players
		for _, player in Players:GetPlayers() do
			CargoService.UpdateFreshness(player, WORLD_TICK_RATE)

			-- Apply fuel consumption for players in boats
			local boat = BoatService.GetBoat(player)
			if boat and boat.IsInBoat then
				local fuelDrain = BoatService.CalculateFuelConsumption(player, WORLD_TICK_RATE)
				fuelDrain = fuelDrain * WorldService.GetFuelDrainMultiplier()
				BoatService.ConsumeFuel(player, fuelDrain)

				if boat.Fuel <= 0 then
					s2c.FuelChanged:FireClient(player, 0)
				end
			end

			-- Apply disaster damage
			local disasterDamage = WorldService.GetDisasterDamage()
			if disasterDamage > 0 and boat and boat.IsInBoat then
				local damageResult = BoatService.DamageBoat(player, disasterDamage * WORLD_TICK_RATE)
				if damageResult.StateChanged then
					s2c.BoatDamaged:FireClient(player, damageResult)
				end
			end
		end
	end
end)

-- ==========================================
-- DEBUG COMMANDS
-- ==========================================

local DebugCommands = {
	"/setpopulation [zone] [species] [value] - Set fish population",
	"/getpopulation [zone] [species] - Get fish population",
	"/resetpopulation [zone] - Reset all populations in zone",
	"/settime [phase] - Set time of day",
	"/setweather [weather] - Set weather",
	"/damageboat [amount] - Damage your boat",
	"/repairboat - Repair your boat",
	"/addgold [amount] - Add gold",
	"/addsalvage [amount] - Add salvage",
	"/spawnboat [boatId] - Spawn a specific boat",
}

local function HandleDebugCommand(player: Player, message: string)
	if not string.match(message, "^/") then
		return false
	end

	local args = string.split(string.sub(message, 2), " ")
	local cmd = args[1]

	if cmd == "setpopulation" and #args >= 4 then
		local zoneId = args[2]
		local speciesId = args[3]
		local value = tonumber(args[4])
		if value then
			FishingService.SetPopulation(zoneId, speciesId, value)
			return true
		end
	elseif cmd == "getpopulation" and #args >= 3 then
		local pop = FishingService.GetPopulation(args[2], args[3])
		s2c.ShowNotification:FireClient(player, args[2] .. "/" .. args[3] .. ": " .. pop)
		return true
	elseif cmd == "resetpopulation" and #args >= 2 then
		local zoneSpecies = require(ReplicatedStorage.Shared.Config.FishDefinitions).GetSpeciesByZone(args[2])
		for _, species in zoneSpecies do
			FishingService.SetPopulation(args[2], species.SpeciesId, species.Population)
		end
		return true
	elseif cmd == "settime" and #args >= 2 then
		-- Would need to modify WorldService internals
		return true
	elseif cmd == "setweather" and #args >= 2 then
		WorldService.SetWeather(args[2])
		return true
	elseif cmd == "damageboat" and #args >= 2 then
		local amount = tonumber(args[2])
		if amount then
			BoatService.DamageBoat(player, amount)
			return true
		end
	elseif cmd == "repairboat" then
		BoatService.RepairBoat(player, 0)
		return true
	elseif cmd == "addgold" and #args >= 2 then
		local amount = tonumber(args[2])
		if amount then
			PlayerDataService.UpdateGold(player, amount)
			s2c.GoldChanged:FireClient(player, PlayerDataService.GetProfile(player).Gold)
			return true
		end
	elseif cmd == "addsalvage" and #args >= 2 then
		local amount = tonumber(args[2])
		if amount then
			PlayerDataService.UpdateSalvage(player, amount)
			s2c.SalvageChanged:FireClient(player, PlayerDataService.GetProfile(player).Salvage)
			return true
		end
	elseif cmd == "help" then
		for _, helpText in DebugCommands do
			s2c.ShowNotification:FireClient(player, helpText)
		end
		return true
	end

	return false
end

-- Chat command handler
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		HandleDebugCommand(player, message)
	end)
end)

print("[FishingVillage] Server initialized successfully")
