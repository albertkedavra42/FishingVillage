local ZoneDefinitions = {}

export type FishingSpot = {
	SpotId: string,
	Position: Vector3,
	Radius: number,
	IsActive: boolean,
}

export type ZoneConfig = {
	ZoneId: string,
	DisplayName: string,
	Description: string,
	RequiredProject: string?,
	RequiredBoatTier: number, -- 1=starter, 2=coastal, 3=commercial
	DistanceFromHarbor: number, -- affects fuel
	RiskLevel: number, -- 0-1, affects damage chance
	DisasterChance: number, -- chance per minute of disaster
	NightBonus: number, -- multiplier for night fishing value
	Spots: { FishingSpot },
	NavigationHazards: { string }, -- {"Rocks"}, {"Whirlpool"}, etc
}

ZoneDefinitions.Zones = {
	Shallows = {
		ZoneId = "Shallows",
		Description = "Calm shallow waters. Perfect for beginners.",
		RequiredProject = nil,
		RequiredBoatTier = 1,
		DistanceFromHarbor = 1,
		RiskLevel = 0.05,
		DisasterChance = 0.005,
		NightBonus = 1.2,
		Spots = {
			{ SpotId = "Shallows_A", Position = Vector3.new(100, 0, 50), Radius = 30, IsActive = true },
			{ SpotId = "Shallows_B", Position = Vector3.new(150, 0, 80), Radius = 25, IsActive = true },
			{ SpotId = "Shallows_C", Position = Vector3.new(80, 0, 120), Radius = 35, IsActive = true },
			{ SpotId = "Shallows_D", Position = Vector3.new(130, 0, 150), Radius = 20, IsActive = false },
		},
		NavigationHazards = {},
	},

	Estuary = {
		ZoneId = "Estuary",
		Description = "Brackish waters where river meets sea. More variety, more risk.",
		RequiredProject = nil,
		RequiredBoatTier = 2,
		DistanceFromHarbor = 2,
		RiskLevel = 0.15,
		DisasterChance = 0.01,
		NightBonus = 1.5,
		Spots = {
			{ SpotId = "Estuary_A", Position = Vector3.new(300, 0, 100), Radius = 30, IsActive = true },
			{ SpotId = "Estuary_B", Position = Vector3.new(350, 0, 180), Radius = 25, IsActive = true },
			{ SpotId = "Estuary_C", Position = Vector3.new(280, 0, 220), Radius = 35, IsActive = true },
			{ SpotId = "Estuary_D", Position = Vector3.new(380, 0, 260), Radius = 20, IsActive = false },
			{ SpotId = "Estuary_E", Position = Vector3.new(320, 0, 300), Radius = 28, IsActive = false },
		},
		NavigationHazards = { "Rocks" },
	},

	OpenSea = {
		ZoneId = "OpenSea",
		Description = "Deep open waters. Rare fish, high rewards, real danger.",
		RequiredProject = "HarborExpansion",
		RequiredBoatTier = 3,
		DistanceFromHarbor = 3,
		RiskLevel = 0.3,
		DisasterChance = 0.02,
		NightBonus = 2.0,
		Spots = {
			{ SpotId = "OpenSea_A", Position = Vector3.new(600, 0, 200), Radius = 40, IsActive = true },
			{ SpotId = "OpenSea_B", Position = Vector3.new(700, 0, 350), Radius = 35, IsActive = true },
			{ SpotId = "OpenSea_C", Position = Vector3.new(650, 0, 450), Radius = 30, IsActive = true },
			{ SpotId = "OpenSea_D", Position = Vector3.new(750, 0, 500), Radius = 25, IsActive = false },
			{ SpotId = "OpenSea_E", Position = Vector3.new(800, 0, 400), Radius = 30, IsActive = false },
			{ SpotId = "OpenSea_F", Position = Vector3.new(680, 0, 550), Radius = 35, IsActive = false },
		},
		NavigationHazards = { "Rocks", "Whirlpool" },
	},
}

function ZoneDefinitions.GetZone(zoneId: string): ZoneConfig?
	return ZoneDefinitions.Zones[zoneId]
end

function ZoneDefinitions.GetActiveSpots(zoneId: string): { FishingSpot }
	local zone = ZoneDefinitions.Zones[zoneId]
	if not zone then
		return {}
	end
	local active = {}
	for _, spot in zone.Spots do
		if spot.IsActive then
			table.insert(active, spot)
		end
	end
	return active
end

function ZoneDefinitions.SetSpotActive(zoneId: string, spotId: string, active: boolean)
	local zone = ZoneDefinitions.Zones[zoneId]
	if not zone then
		return
	end
	for _, spot in zone.Spots do
		if spot.SpotId == spotId then
			spot.IsActive = active
			return
		end
	end
end

return ZoneDefinitions
