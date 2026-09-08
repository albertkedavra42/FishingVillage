local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingService = {}
FishingService.__index = FishingService

local FishDefinitions = require(ReplicatedStorage.Shared.Config.FishDefinitions)
local ZoneDefinitions = require(ReplicatedStorage.Shared.Config.ZoneDefinitions)

local zonePopulations: { [string]: { [string]: number } } = {}
local activeFishingPlayers: { [number]: {
	ZoneId: string,
	SpotId: string,
	Method: string,
	StartTime: number,
	IsFishing: boolean,
} } = {}

function FishingService.Init()
	for zoneId, zone in ZoneDefinitions.Zones do
		zonePopulations[zoneId] = {}
		local zoneSpecies = FishDefinitions.GetSpeciesByZone(zoneId)
		for _, species in zoneSpecies do
			zonePopulations[zoneId][species.SpeciesId] = species.Population
		end
	end
end

function FishingService.GetPopulation(zoneId: string, speciesId: string): number
	if not zonePopulations[zoneId] then
		return 0
	end
	return zonePopulations[zoneId][speciesId] or 0
end

function FishingService.SetPopulation(zoneId: string, speciesId: string, value: number)
	if not zonePopulations[zoneId] then
		zonePopulations[zoneId] = {}
	end
	zonePopulations[zoneId][speciesId] = math.clamp(value, 0, 100)
end

function FishingService.ReducePopulation(zoneId: string, speciesId: string, amount: number)
	local current = FishingService.GetPopulation(zoneId, speciesId)
	local newPop = math.max(0, current - amount)
	FishingService.SetPopulation(zoneId, speciesId, newPop)
end

function FishingService.GetPopulationState(zoneId: string, speciesId: string): string
	local pop = FishingService.GetPopulation(zoneId, speciesId)
	if pop >= 70 then
		return "Abundant"
	elseif pop >= 40 then
		return "Normal"
	elseif pop >= 20 then
		return "Scarce"
	else
		return "Depleted"
	end
end

function FishingService.RegeneratePopulations(deltaTime: number)
	for zoneId, populations in zonePopulations do
		for speciesId, currentPop in populations do
			local species = FishDefinitions.GetSpecies(speciesId)
			if species then
				local maxPop = species.Population
				local regenAmount = species.RegenerationRate * (deltaTime / 60)
				local newPop = math.min(maxPop, currentPop + regenAmount)
				populations[speciesId] = newPop
			end
		end
	end
end

function FishingService.SelectCatch(zoneId: string, timeOfDay: string, method: string): {
	SpeciesId: string,
	Variant: string,
	Weight: number,
	Size: { number },
}?
	local eligibleSpecies = FishDefinitions.GetSpeciesByTime(zoneId, timeOfDay)

	-- Filter by fishing method
	local methodFiltered = {}
	for _, species in eligibleSpecies do
		if table.find(species.FishingMethods, method) then
			table.insert(methodFiltered, species)
		end
	end

	if #methodFiltered == 0 then
		return nil
	end

	-- Weight by spawn weight and population
	local weightedList = {}
	local totalWeight = 0

	for _, species in methodFiltered do
		local pop = FishingService.GetPopulation(zoneId, species.SpeciesId)
		local popFactor = pop / 100
		local rarityMod = FishDefinitions.RarityTiers[species.Rarity].SpawnWeightMultiplier
		local weight = species.SpawnWeight * popFactor * rarityMod
		if weight > 0 then
			table.insert(weightedList, { Species = species, Weight = weight })
			totalWeight = totalWeight + weight
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	-- Pick random species
	local roll = math.random() * totalWeight
	local cumulative = 0
	local selectedSpecies = nil

	for _, entry in weightedList do
		cumulative = cumulative + entry.Weight
		if roll <= cumulative then
			selectedSpecies = entry.Species
			break
		end
	end

	if not selectedSpecies then
		selectedSpecies = weightedList[#weightedList].Species
	end

	-- Roll variant
	local variant = "Normal"
	local variantRoll = math.random()
	if variantRoll <= selectedSpecies.VariantRules.StrangeChance then
		variant = "Strange"
	elseif variantRoll <= selectedSpecies.VariantRules.GoldenChance then
		variant = "Golden"
	elseif variantRoll <= selectedSpecies.VariantRules.GiantChance then
		variant = "Giant"
	end

	-- Generate weight and size
	local weightRange = selectedSpecies.WeightRange
	local weight = weightRange[1] + math.random() * (weightRange[2] - weightRange[1])

	local variantMod = FishDefinitions.VariantModifiers[variant]
	weight = weight * variantMod.SizeMultiplier

	local sizeRange = selectedSpecies.SizeRange
	local width = sizeRange[1]
	local height = sizeRange[2]

	-- Giant variant doubles size
	if variant == "Giant" then
		width = math.ceil(width * 2)
		height = math.ceil(height * 2)
	end

	-- Reduce population
	FishingService.ReducePopulation(zoneId, selectedSpecies.SpeciesId, 2)

	return {
		SpeciesId = selectedSpecies.SpeciesId,
		Variant = variant,
		Weight = math.floor(weight * 100) / 100,
		Size = { width, height },
	}
end

function FishingService.StartFishing(player: Player, zoneId: string, spotId: string, method: string)
	activeFishingPlayers[player.UserId] = {
		ZoneId = zoneId,
		SpotId = spotId,
		Method = method,
		StartTime = tick(),
		IsFishing = true,
	}
end

function FishingService.StopFishing(player: Player)
	activeFishingPlayers[player.UserId] = nil
end

function FishingService.GetActiveFishing(player: Player)
	return activeFishingPlayers[player.UserId]
end

function FishingService.CalculateBiteTime(zoneId: string, timeOfDay: string, method: string): number
	-- Base bite time in seconds
	local baseTime = 3.0

	-- Night is slower but more valuable
	if timeOfDay == "Night" or timeOfDay == "LateNight" then
		baseTime = baseTime + 2.0
	end

	-- Net is faster than rod
	if method == "Net" then
		baseTime = baseTime * 0.7
	end

	-- Add some randomness
	local variance = baseTime * 0.3
	return baseTime + (math.random() * variance * 2 - variance)
end

return FishingService
