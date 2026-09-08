local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local DATA_STORE_NAME = "FishingVillage_v1"
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)

local DEFAULT_PROFILE = {
	Gold = 100,
	Salvage = 0,

	Boat = {
		BoatId = "StarterBoat",
		HullHealth = 100,
		Fuel = 100,
		Upgrades = {},
	},

	Inventory = {
		Fish = {},
		Items = {},
	},

	Collection = {
		Species = {},
		Variants = {},
		Records = {},
	},

	Dock = {
		Buildings = {},
		Decorations = {},
	},

	Progression = {
		UnlockedZones = {
			Shallows = true,
		},
		VillageContributions = {},
	},

	Stats = {
		TotalFishCaught = 0,
		TotalGoldEarned = 0,
		TotalTrips = 0,
		BiggestFish = nil,
		RarestFish = nil,
	},

	Settings = {
		MusicVolume = 0.5,
		SFXVolume = 0.7,
	},
}

local loadedProfiles: { [number]: typeof(DEFAULT_PROFILE) } = {}

function PlayerDataService.DeepClone(original)
	local clone = {}
	for key, value in original do
		if type(value) == "table" then
			clone[key] = PlayerDataService.DeepClone(value)
		else
			clone[key] = value
		end
	end
	return clone
end

function PlayerDataService.GetProfile(player: Player): typeof(DEFAULT_PROFILE)?
	return loadedProfiles[player.UserId]
end

function PlayerDataService.LoadProfile(player: Player): typeof(DEFAULT_PROFILE)
	local key = "Player_" .. player.UserId
	local success, result = pcall(function()
		return dataStore:GetAsync(key)
	end)

	local profile
	if success and result then
		profile = result
		-- Merge with defaults for any missing fields
		for key, value in DEFAULT_PROFILE do
			if profile[key] == nil then
				profile[key] = PlayerDataService.DeepClone(value)
			end
		end
	else
		profile = PlayerDataService.DeepClone(DEFAULT_PROFILE)
		warn("[PlayerDataService] Loaded default profile for " .. player.Name)
	end

	loadedProfiles[player.UserId] = profile
	return profile
end

function PlayerDataService.SaveProfile(player: Player): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		warn("[PlayerDataService] No profile to save for " .. player.Name)
		return false
	end

	local key = "Player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, profile)
	end)

	if not success then
		warn("[PlayerDataService] Failed to save profile for " .. player.Name .. ": " .. tostring(err))
	end

	return success
end

function PlayerDataService.UpdateGold(player: Player, amount: number): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	profile.Gold = profile.Gold + amount
	if profile.Gold < 0 then
		profile.Gold = 0
	end

	return true
end

function PlayerDataService.SetGold(player: Player, amount: number): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	profile.Gold = math.max(0, amount)
	return true
end

function PlayerDataService.UpdateSalvage(player: Player, amount: number): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	profile.Salvage = profile.Salvage + amount
	if profile.Salvage < 0 then
		profile.Salvage = 0
	end

	return true
end

function PlayerDataService.UpdateBoat(player: Player, boatData: {
	BoatId: string?,
	HullHealth: number?,
	Fuel: number?,
	Upgrades: { string }?,
})
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	if boatData.BoatId then
		profile.Boat.BoatId = boatData.BoatId
	end
	if boatData.HullHealth then
		profile.Boat.HullHealth = math.clamp(boatData.HullHealth, 0, 100)
	end
	if boatData.Fuel then
		profile.Boat.Fuel = math.clamp(boatData.Fuel, 0, BoatDefinitions.GetBoat(profile.Boat.BoatId).BaseStats.FuelCapacity)
	end
	if boatData.Upgrades then
		profile.Boat.Upgrades = boatData.Upgrades
	end

	return true
end

function PlayerDataService.UnlockZone(player: Player, zoneId: string): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	profile.Progression.UnlockedZones[zoneId] = true
	return true
end

function PlayerDataService.HasZone(player: Player, zoneId: string): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	return profile.Progression.UnlockedZones[zoneId] == true
end

function PlayerDataService.AddDiscovery(player: Player, discoveryType: string, id: string)
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return
	end

	if discoveryType == "Species" then
		profile.Collection.Species[id] = true
	elseif discoveryType == "Variant" then
		profile.Collection.Variants[id] = true
	end
end

function PlayerDataService.HasDiscovery(player: Player, discoveryType: string, id: string): boolean
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return false
	end

	if discoveryType == "Species" then
		return profile.Collection.Species[id] == true
	elseif discoveryType == "Variant" then
		return profile.Collection.Variants[id] == true
	end

	return false
end

function PlayerDataService.IncrementStat(player: Player, statName: string, amount: number?)
	local profile = loadedProfiles[player.UserId]
	if not profile then
		return
	end

	local amt = amount or 1
	if profile.Stats[statName] then
		profile.Stats[statName] = profile.Stats[statName] + amt
	end
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(function(player)
		local profile = PlayerDataService.LoadProfile(player)

		local Remotes = require(ReplicatedStorage.Shared.Remotes)
		Remotes.GetServerToClient().PlayerDataLoaded:FireClient(player, profile)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.SaveProfile(player)
		loadedProfiles[player.UserId] = nil
	end)

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			PlayerDataService.SaveProfile(player)
		end
	end)

	-- Auto-save every 60 seconds
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				PlayerDataService.SaveProfile(player)
			end
		end
	end)
end

return PlayerDataService
