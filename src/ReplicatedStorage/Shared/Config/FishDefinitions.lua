local FishDefinitions = {}

export type FishVariant = "Normal" | "Giant" | "Golden" | "Strange"

export type FishRarity = "Common" | "Uncommon" | "Rare" | "Strange"

export type FishSpecies = {
	SpeciesId: string,
	DisplayName: string,
	BaseValue: number,
	WeightRange: { number }, -- {min, max}
	SizeRange: { number },   -- {min, max} in grid units (W, H)
	Rarity: FishRarity,
	PreferredZones: { string },
	PreferredTime: { string }, -- {"Day"}, {"Night"}, {"All"}
	PreferredWeather: { string },
	FishingMethods: { string }, -- {"Rod"}, {"Net"}, {"Rod", "Net"}
	Population: number,         -- 0-100 default
	RegenerationRate: number,   -- per minute
	SpawnWeight: number,        -- relative spawn chance
	FreshnessDecayRate: number, -- per minute
	VariantRules: {
		GiantChance: number,
		GoldenChance: number,
		StrangeChance: number,
	},
}

FishDefinitions.Species = {
	-- ==========================================
	-- SHALLOWS (Beginner Zone)
	-- ==========================================
	Cod = {
		SpeciesId = "Cod",
		DisplayName = "Cod",
		BaseValue = 15,
		WeightRange = { 1, 5 },
		SizeRange = { 2, 2 },
		Rarity = "Common",
		PreferredZones = { "Shallows", "Estuary" },
		PreferredTime = { "Day" },
		PreferredWeather = { "Clear", "Overcast" },
		FishingMethods = { "Rod", "Net" },
		Population = 85,
		RegenerationRate = 4,
		SpawnWeight = 30,
		FreshnessDecayRate = 0.5,
		VariantRules = {
			GiantChance = 0.02,
			GoldenChance = 0.01,
			StrangeChance = 0.005,
		},
	},

	Sardine = {
		SpeciesId = "Sardine",
		DisplayName = "Sardine",
		BaseValue = 8,
		WeightRange = { 0.2, 1 },
		SizeRange = { 1, 1 },
		Rarity = "Common",
		PreferredZones = { "Shallows", "Estuary" },
		PreferredTime = { "Day" },
		PreferredWeather = { "Clear", "Overcast", "Rain" },
		FishingMethods = { "Net" },
		Population = 90,
		RegenerationRate = 6,
		SpawnWeight = 40,
		FreshnessDecayRate = 0.8,
		VariantRules = {
			GiantChance = 0.01,
			GoldenChance = 0.005,
			StrangeChance = 0.002,
		},
	},

	Mackerel = {
		SpeciesId = "Mackerel",
		DisplayName = "Mackerel",
		BaseValue = 22,
		WeightRange = { 1, 4 },
		SizeRange = { 2, 1 },
		Rarity = "Common",
		PreferredZones = { "Shallows", "Estuary", "OpenSea" },
		PreferredTime = { "Day", "Evening" },
		PreferredWeather = { "Clear", "Overcast" },
		FishingMethods = { "Rod", "Net" },
		Population = 75,
		RegenerationRate = 5,
		SpawnWeight = 25,
		FreshnessDecayRate = 0.6,
		VariantRules = {
			GiantChance = 0.03,
			GoldenChance = 0.01,
			StrangeChance = 0.005,
		},
	},

	Flatfish = {
		SpeciesId = "Flatfish",
		DisplayName = "Flatfish",
		BaseValue = 18,
		WeightRange = { 0.5, 3 },
		SizeRange = { 2, 1 },
		Rarity = "Common",
		PreferredZones = { "Shallows" },
		PreferredTime = { "Day" },
		PreferredWeather = { "Clear" },
		FishingMethods = { "Rod" },
		Population = 70,
		RegenerationRate = 3,
		SpawnWeight = 20,
		FreshnessDecayRate = 0.5,
		VariantRules = {
			GiantChance = 0.02,
			GoldenChance = 0.008,
			StrangeChance = 0.003,
		},
	},

	-- ==========================================
	-- ESTUARY (Intermediate Zone)
	-- ==========================================
	Moonfin = {
		SpeciesId = "Moonfin",
		DisplayName = "Moonfin",
		BaseValue = 65,
		WeightRange = { 2, 8 },
		SizeRange = { 2, 3 },
		Rarity = "Uncommon",
		PreferredZones = { "Estuary" },
		PreferredTime = { "Evening", "Night" },
		PreferredWeather = { "Clear", "Overcast" },
		FishingMethods = { "Rod" },
		Population = 50,
		RegenerationRate = 2,
		SpawnWeight = 15,
		FreshnessDecayRate = 0.4,
		VariantRules = {
			GiantChance = 0.04,
			GoldenChance = 0.02,
			StrangeChance = 0.01,
		},
	},

	SeaBass = {
		SpeciesId = "SeaBass",
		DisplayName = "Sea Bass",
		BaseValue = 45,
		WeightRange = { 2, 10 },
		SizeRange = { 3, 2 },
		Rarity = "Uncommon",
		PreferredZones = { "Estuary", "OpenSea" },
		PreferredTime = { "Day", "Evening" },
		PreferredWeather = { "Clear" },
		FishingMethods = { "Rod" },
		Population = 55,
		RegenerationRate = 3,
		SpawnWeight = 18,
		FreshnessDecayRate = 0.5,
		VariantRules = {
			GiantChance = 0.03,
			GoldenChance = 0.015,
			StrangeChance = 0.008,
		},
	},

	Eel = {
		SpeciesId = "Eel",
		DisplayName = "Eel",
		BaseValue = 55,
		WeightRange = { 1, 6 },
		SizeRange = { 3, 1 },
		Rarity = "Uncommon",
		PreferredZones = { "Estuary" },
		PreferredTime = { "Night" },
		PreferredWeather = { "Overcast", "Rain" },
		FishingMethods = { "Rod" },
		Population = 40,
		RegenerationRate = 2,
		SpawnWeight = 12,
		FreshnessDecayRate = 0.3,
		VariantRules = {
			GiantChance = 0.03,
			GoldenChance = 0.01,
			StrangeChance = 0.015,
		},
	},

	Crab = {
		SpeciesId = "Crab",
		DisplayName = "Crab",
		BaseValue = 30,
		WeightRange = { 0.5, 3 },
		SizeRange = { 2, 2 },
		Rarity = "Uncommon",
		PreferredZones = { "Shallows", "Estuary" },
		PreferredTime = { "Day", "Evening", "Night" },
		PreferredWeather = { "Clear", "Overcast" },
		FishingMethods = { "Net" },
		Population = 60,
		RegenerationRate = 3,
		SpawnWeight = 14,
		FreshnessDecayRate = 0.4,
		VariantRules = {
			GiantChance = 0.05,
			GoldenChance = 0.01,
			StrangeChance = 0.01,
		},
	},

	-- ==========================================
	-- OPEN SEA (Advanced Zone)
	-- ==========================================
	Swordfish = {
		SpeciesId = "Swordfish",
		DisplayName = "Swordfish",
		BaseValue = 150,
		WeightRange = { 10, 50 },
		SizeRange = { 4, 3 },
		Rarity = "Rare",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "Night" },
		PreferredWeather = { "Clear" },
		FishingMethods = { "Rod" },
		Population = 30,
		RegenerationRate = 1,
		SpawnWeight = 8,
		FreshnessDecayRate = 0.3,
		VariantRules = {
			GiantChance = 0.05,
			GoldenChance = 0.02,
			StrangeChance = 0.01,
		},
	},

	Tuna = {
		SpeciesId = "Tuna",
		DisplayName = "Tuna",
		BaseValue = 120,
		WeightRange = { 8, 40 },
		SizeRange = { 3, 3 },
		Rarity = "Rare",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "Day", "Evening" },
		PreferredWeather = { "Clear", "Overcast" },
		FishingMethods = { "Net", "Rod" },
		Population = 35,
		RegenerationRate = 1.5,
		SpawnWeight = 10,
		FreshnessDecayRate = 0.4,
		VariantRules = {
			GiantChance = 0.04,
			GoldenChance = 0.015,
			StrangeChance = 0.008,
		},
	},

	Glowfin = {
		SpeciesId = "Glowfin",
		DisplayName = "Glowfin",
		BaseValue = 200,
		WeightRange = { 3, 12 },
		SizeRange = { 2, 2 },
		Rarity = "Rare",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "Night", "LateNight" },
		PreferredWeather = { "Clear" },
		FishingMethods = { "Rod" },
		Population = 20,
		RegenerationRate = 0.8,
		SpawnWeight = 5,
		FreshnessDecayRate = 0.6,
		VariantRules = {
			GiantChance = 0.03,
			GoldenChance = 0.03,
			StrangeChance = 0.02,
		},
	},

	StormMackerel = {
		SpeciesId = "StormMackerel",
		DisplayName = "Storm Mackerel",
		BaseValue = 90,
		WeightRange = { 3, 10 },
		SizeRange = { 2, 2 },
		Rarity = "Rare",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "All" },
		PreferredWeather = { "Storm" },
		FishingMethods = { "Rod", "Net" },
		Population = 15,
		RegenerationRate = 1,
		SpawnWeight = 6,
		FreshnessDecayRate = 0.5,
		VariantRules = {
			GiantChance = 0.04,
			GoldenChance = 0.02,
			StrangeChance = 0.015,
		},
	},

	-- ==========================================
	-- STRANGE RARITY (Special)
	-- ==========================================
	AbyssLurker = {
		SpeciesId = "AbyssLurker",
		DisplayName = "Abyss Lurker",
		BaseValue = 350,
		WeightRange = { 5, 20 },
		SizeRange = { 3, 3 },
		Rarity = "Strange",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "LateNight" },
		PreferredWeather = { "Storm" },
		FishingMethods = { "Rod" },
		Population = 8,
		RegenerationRate = 0.3,
		SpawnWeight = 2,
		FreshnessDecayRate = 0.2,
		VariantRules = {
			GiantChance = 0.06,
			GoldenChance = 0.03,
			StrangeChance = 0.025,
		},
	},

	PhantomRay = {
		SpeciesId = "PhantomRay",
		DisplayName = "Phantom Ray",
		BaseValue = 500,
		WeightRange = { 10, 30 },
		SizeRange = { 4, 4 },
		Rarity = "Strange",
		PreferredZones = { "OpenSea" },
		PreferredTime = { "Night", "LateNight" },
		PreferredWeather = { "Clear" },
		FishingMethods = { "Rod" },
		Population = 5,
		RegenerationRate = 0.2,
		SpawnWeight = 1,
		FreshnessDecayRate = 0.15,
		VariantRules = {
			GiantChance = 0.05,
			GoldenChance = 0.04,
			StrangeChance = 0.03,
		},
	},
}

FishDefinitions.RarityTiers = {
	Common = { SpawnWeightMultiplier = 1.0, ValueMultiplier = 1.0 },
	Uncommon = { SpawnWeightMultiplier = 0.5, ValueMultiplier = 1.5 },
	Rare = { SpawnWeightMultiplier = 0.2, ValueMultiplier = 2.5 },
	Strange = { SpawnWeightMultiplier = 0.05, ValueMultiplier = 4.0 },
}

FishDefinitions.VariantModifiers = {
	Normal = { SizeMultiplier = 1.0, ValueMultiplier = 1.0 },
	Giant = { SizeMultiplier = 2.0, ValueMultiplier = 2.5 },
	Golden = { SizeMultiplier = 1.0, ValueMultiplier = 5.0 },
	Strange = { SizeMultiplier = 0.8, ValueMultiplier = 3.0 },
}

function FishDefinitions.GetSpecies(speciesId: string): FishSpecies?
	return FishDefinitions.Species[speciesId]
end

function FishDefinitions.GetSpeciesByZone(zoneId: string): { FishSpecies }
	local result = {}
	for _, species in FishDefinitions.Species do
		if table.find(species.PreferredZones, zoneId) then
			table.insert(result, species)
		end
	end
	return result
end

function FishDefinitions.GetSpeciesByTime(zoneId: string, timeOfDay: string): { FishSpecies }
	local zoneSpecies = FishDefinitions.GetSpeciesByZone(zoneId)
	local result = {}
	for _, species in zoneSpecies do
		if table.find(species.PreferredTime, "All") or table.find(species.PreferredTime, timeOfDay) then
			table.insert(result, species)
		end
	end
	return result
end

return FishDefinitions
