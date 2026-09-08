local VillageMap = {}

VillageMap.SpawnPoint = Vector3.new(0, 2, 0)

VillageMap.Dock = {
	Position = Vector3.new(30, 0.5, 30),
	Size = Vector3.new(20, 2, 30),
	BoatSpawnOffset = Vector3.new(0, 0, 25),
	BoardingRadius = 8,
	ExitRadius = 5,
}

VillageMap.Buildings = {
	Shipwright = {
		Position = Vector3.new(15, 0, 15),
		Size = Vector3.new(8, 6, 10),
		InteractionRadius = 6,
		Color = Color3.fromHex("#8B7355"),
	},
	FishMarket = {
		Position = Vector3.new(-15, 0, 15),
		Size = Vector3.new(10, 6, 8),
		InteractionRadius = 6,
		Color = Color3.fromHex("#CD853F"),
	},
	Smokehouse = {
		Position = Vector3.new(-15, 0, -10),
		Size = Vector3.new(8, 5, 8),
		InteractionRadius = 5,
		Color = Color3.fromHex("#A0522D"),
	},
	Museum = {
		Position = Vector3.new(15, 0, -15),
		Size = Vector3.new(12, 8, 12),
		InteractionRadius = 8,
		Color = Color3.fromHex("#708090"),
	},
	ProjectBoard = {
		Position = Vector3.new(0, 0, 10),
		Size = Vector3.new(3, 4, 1),
		InteractionRadius = 4,
		Color = Color3.fromHex("#DEB887"),
	},
	BaitShop = {
		Position = Vector3.new(25, 0, 10),
		Size = Vector3.new(6, 5, 6),
		InteractionRadius = 5,
		Color = Color3.fromHex("#D2B48C"),
	},
	Restaurant = {
		Position = Vector3.new(-25, 0, 5),
		Size = Vector3.new(8, 6, 8),
		InteractionRadius = 6,
		Color = Color3.fromHex("#BC8F8F"),
	},
}

VillageMap.PlayerStallArea = {
	Position = Vector3.new(0, 0, -5),
	Size = Vector3.new(30, 0, 15),
	StallSlots = {
		{ Position = Vector3.new(-10, 0, -5), Size = Vector3.new(4, 3, 3) },
		{ Position = Vector3.new(-5, 0, -5), Size = Vector3.new(4, 3, 3) },
		{ Position = Vector3.new(0, 0, -5), Size = Vector3.new(4, 3, 3) },
		{ Position = Vector3.new(5, 0, -5), Size = Vector3.new(4, 3, 3) },
		{ Position = Vector3.new(10, 0, -5), Size = Vector3.new(4, 3, 3) },
	},
}

VillageMap.Lighthouse = {
	Position = Vector3.new(-30, 0, -25),
	Height = 15,
	Radius = 3,
	RequiredProject = "Lighthouse",
}

VillageMap.WaterLevel = 0

VillageMap.NavigationZones = {
	Shallows = {
		EntryDirection = Vector3.new(0, 0, 1),
		Distance = 100,
	},
	Estuary = {
		EntryDirection = Vector3.new(1, 0, 0.5).Unit,
		Distance = 300,
	},
	OpenSea = {
		EntryDirection = Vector3.new(0.5, 0, 1).Unit,
		Distance = 600,
	},
}

function VillageMap.GetNearestBuilding(playerPosition: Vector3): (string?, number?)
	local nearest = nil
	local nearestDist = math.huge

	for name, building in VillageMap.Buildings do
		local dist = (playerPosition - building.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearest = name
		end
	end

	if nearest and nearestDist <= VillageMap.Buildings[nearest].InteractionRadius then
		return nearest, nearestDist
	end

	return nil, nil
end

function VillageMap.IsAtDock(playerPosition: Vector3): boolean
	local dock = VillageMap.Dock
	local dist = (playerPosition - dock.Position).Magnitude
	return dist <= dock.BoardingRadius
end

function VillageMap.GetBoatSpawnPosition(): Vector3
	local dock = VillageMap.Dock
	return dock.Position + dock.BoatSpawnOffset
end

function VillageMap.GetZoneEntryPosition(zoneId: string): Vector3?
	local zone = VillageMap.NavigationZones[zoneId]
	if not zone then
		return nil
	end

	local dockPos = VillageMap.Dock.Position
	return dockPos + zone.EntryDirection * zone.Distance
end

return VillageMap
