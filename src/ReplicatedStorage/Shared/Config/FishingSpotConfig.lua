local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingSpotConfig = {}

export type SpotState = "Active" | "Scarce" | "Depleted" | "Inactive"

export type FishingSpotData = {
	SpotId: string,
	ZoneId: string,
	Position: Vector3,
	Radius: number,
	State: SpotState,
	ActiveSpecies: { string },
	SpawnTimer: number,
	LastCatchTime: number,
}

FishingSpotConfig.States = {
	Active = { SpawnRate = 1.0, CatchChance = 0.7 },
	Scarce = { SpawnRate = 0.4, CatchChance = 0.4 },
	Depleted = { SpawnRate = 0.1, CatchChance = 0.15 },
	Inactive = { SpawnRate = 0, CatchChance = 0 },
}

FishingSpotConfig.SpotTemplates = {
	Shallows = {
		{ SpotId = "Shallows_A", Offset = Vector3.new(100, 0, 50), Radius = 30 },
		{ SpotId = "Shallows_B", Offset = Vector3.new(150, 0, 80), Radius = 25 },
		{ SpotId = "Shallows_C", Offset = Vector3.new(80, 0, 120), Radius = 35 },
		{ SpotId = "Shallows_D", Offset = Vector3.new(130, 0, 150), Radius = 20 },
	},
	Estuary = {
		{ SpotId = "Estuary_A", Offset = Vector3.new(300, 0, 100), Radius = 30 },
		{ SpotId = "Estuary_B", Offset = Vector3.new(350, 0, 180), Radius = 25 },
		{ SpotId = "Estuary_C", Offset = Vector3.new(280, 0, 220), Radius = 35 },
		{ SpotId = "Estuary_D", Offset = Vector3.new(380, 0, 260), Radius = 20 },
		{ SpotId = "Estuary_E", Offset = Vector3.new(320, 0, 300), Radius = 28 },
	},
	OpenSea = {
		{ SpotId = "OpenSea_A", Offset = Vector3.new(600, 0, 200), Radius = 40 },
		{ SpotId = "OpenSea_B", Offset = Vector3.new(700, 0, 350), Radius = 35 },
		{ SpotId = "OpenSea_C", Offset = Vector3.new(650, 0, 450), Radius = 30 },
		{ SpotId = "OpenSea_D", Offset = Vector3.new(750, 0, 500), Radius = 25 },
		{ SpotId = "OpenSea_E", Offset = Vector3.new(800, 0, 400), Radius = 30 },
		{ SpotId = "OpenSea_F", Offset = Vector3.new(680, 0, 550), Radius = 35 },
	},
}

function FishingSpotConfig.CreateSpot(zoneId: string, templateIndex: number): FishingSpotData?
	local templates = FishingSpotConfig.SpotTemplates[zoneId]
	if not templates or not templates[templateIndex] then
		return nil
	end

	local template = templates[templateIndex]
	local FishDefinitions = require(ReplicatedStorage.Shared.Config.FishDefinitions)
	local zoneSpecies = FishDefinitions.GetSpeciesByZone(zoneId)
	local speciesIds = {}
	for _, species in zoneSpecies do
		table.insert(speciesIds, species.SpeciesId)
	end

	return {
		SpotId = template.SpotId,
		ZoneId = zoneId,
		Position = template.Offset,
		Radius = template.Radius,
		State = "Active",
		ActiveSpecies = speciesIds,
		SpawnTimer = 0,
		LastCatchTime = 0,
	}
end

function FishingSpotConfig.CreateAllSpots(zoneId: string): { FishingSpotData }
	local templates = FishingSpotConfig.SpotTemplates[zoneId]
	if not templates then
		return {}
	end

	local spots = {}
	for i = 1, #templates do
		local spot = FishingSpotConfig.CreateSpot(zoneId, i)
		if spot then
			table.insert(spots, spot)
		end
	end
	return spots
end

function FishingSpotConfig.UpdateSpotState(spot: FishingSpotData, populationAvg: number)
	if populationAvg >= 70 then
		spot.State = "Active"
	elseif populationAvg >= 40 then
		spot.State = "Active"
	elseif populationAvg >= 20 then
		spot.State = "Scarce"
	elseif populationAvg > 0 then
		spot.State = "Depleted"
	else
		spot.State = "Inactive"
	end
end

function FishingSpotConfig.GetCatchChance(spot: FishingSpotData): number
	local stateData = FishingSpotConfig.States[spot.State]
	return stateData and stateData.CatchChance or 0
end

function FishingSpotConfig.GetSpawnRate(spot: FishingSpotData): number
	local stateData = FishingSpotConfig.States[spot.State]
	return stateData and stateData.SpawnRate or 0
end

return FishingSpotConfig
