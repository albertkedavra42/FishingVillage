local BoatDefinitions = {}

export type BoatModule = {
	SlotId: string,
	DisplayName: string,
	Cost: number,
	RequiredProject: string?, -- village project required
}

export type BoatStats = {
	BoatId: string,
	DisplayName: string,
	Description: string,
	Cost: number,
	RequiredProject: string?,
	BaseStats: {
		HullHealth: number,
		EnginePower: number,
		Speed: number,
		FuelCapacity: number,
		CargoCapacity: number, -- total grid cells
		CargoGridWidth: number,
		CargoGridHeight: number,
		FishingSlots: number,
		NightCapability: number, -- 0-1, how well it handles night
		StormResistance: number, -- 0-1
	},
	Modules: { BoatModule },
	Visual: {
		Scale: number,
		CargoCrates: number,
		HasFloodlight: boolean,
		HasSonar: boolean,
	},
}

BoatDefinitions.Boats = {
	StarterBoat = {
		BoatId = "StarterBoat",
		DisplayName = "Starter Fishing Boat",
		Description = "A small wooden boat for beginners. Gets the job done.",
		Cost = 0,
		RequiredProject = nil,
		BaseStats = {
			HullHealth = 100,
			EnginePower = 30,
			Speed = 14,
			FuelCapacity = 100,
			CargoCapacity = 12,
			CargoGridWidth = 4,
			CargoGridHeight = 3,
			FishingSlots = 1,
			NightCapability = 0.1,
			StormResistance = 0.1,
		},
		Modules = {
			{
				SlotId = "Rod1",
				DisplayName = "Basic Rod",
				Cost = 0,
				RequiredProject = nil,
			},
		},
		Visual = {
			Scale = 1.0,
			CargoCrates = 2,
			HasFloodlight = false,
			HasSonar = false,
		},
	},

	CoastalBoat = {
		BoatId = "CoastalBoat",
		DisplayName = "Coastal Fishing Boat",
		Description = "A sturdier boat with net capability. Ready for the estuary.",
		Cost = 2500,
		RequiredProject = "Shipyard",
		BaseStats = {
			HullHealth = 150,
			EnginePower = 50,
			Speed = 18,
			FuelCapacity = 150,
			CargoCapacity = 24,
			CargoGridWidth = 6,
			CargoGridHeight = 4,
			FishingSlots = 2,
			NightCapability = 0.4,
			StormResistance = 0.3,
		},
		Modules = {
			{
				SlotId = "Rod1",
				DisplayName = "Improved Rod",
				Cost = 0,
				RequiredProject = nil,
			},
			{
				SlotId = "Net1",
				DisplayName = "Basic Net",
				Cost = 500,
				RequiredProject = nil,
			},
		},
		Visual = {
			Scale = 1.3,
			CargoCrates = 4,
			HasFloodlight = true,
			HasSonar = false,
		},
	},

	CommercialBoat = {
		BoatId = "CommercialBoat",
		DisplayName = "Commercial Fishing Boat",
		Description = "A serious vessel for serious fishermen. Open Sea ready.",
		Cost = 8000,
		RequiredProject = "HarborExpansion",
		BaseStats = {
			HullHealth = 220,
			EnginePower = 75,
			Speed = 22,
			FuelCapacity = 220,
			CargoCapacity = 40,
			CargoGridWidth = 8,
			CargoGridHeight = 5,
			FishingSlots = 3,
			NightCapability = 0.7,
			StormResistance = 0.5,
		},
		Modules = {
			{
				SlotId = "Rod1",
				DisplayName = "Heavy Rod",
				Cost = 0,
				RequiredProject = nil,
			},
			{
				SlotId = "Net1",
				DisplayName = "Commercial Net",
				Cost = 1200,
				RequiredProject = nil,
			},
			{
				SlotId = "Net2",
				DisplayName = "Trawl Net",
				Cost = 2000,
				RequiredProject = nil,
			},
		},
		Visual = {
			Scale = 1.6,
			CargoCrates = 8,
			HasFloodlight = true,
			HasSonar = true,
		},
	},
}

function BoatDefinitions.GetBoat(boatId: string): BoatStats?
	return BoatDefinitions.Boats[boatId]
end

function BoatDefinitions.GetStarterBoat(): BoatStats
	return BoatDefinitions.Boats.StarterBoat
end

return BoatDefinitions
