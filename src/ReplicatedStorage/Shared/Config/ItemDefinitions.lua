local ItemDefinitions = {}

export type ItemCategory = "Fish" | "Processed" | "Salvage" | "Bait" | "Tool" | "Material" | "Supply"

export type ItemDef = {
	ItemId: string,
	DisplayName: string,
	Description: string,
	Category: ItemCategory,
	BaseValue: number,
	Stackable: boolean,
	MaxStack: number,
	GridWidth: number,
	GridHeight: number,
	FreshnessDecayRate: number?,
	ProcessResult: string?, -- ItemId of processed output
	ProcessTime: number?,  -- seconds
}

ItemDefinitions.Items = {
	-- ==========================================
	-- PROCESSED GOODS
	-- ==========================================
	SmokedCod = {
		ItemId = "SmokedCod",
		DisplayName = "Smoked Cod",
		Description = "Cod preserved through smoking. Lasts longer.",
		Category = "Processed",
		BaseValue = 30,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 2,
		GridHeight = 2,
		FreshnessDecayRate = 0.1,
	},

	SmokedMackerel = {
		ItemId = "SmokedMackerel",
		DisplayName = "Smoked Mackerel",
		Description = "Mackerel preserved through smoking.",
		Category = "Processed",
		BaseValue = 44,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 2,
		GridHeight = 1,
		FreshnessDecayRate = 0.1,
	},

	SmokedMoonfin = {
		ItemId = "SmokedMoonfin",
		DisplayName = "Smoked Moonfin",
		Description = "Moonfin preserved through smoking. Delicate flavor.",
		Category = "Processed",
		BaseValue = 130,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 2,
		GridHeight = 3,
		FreshnessDecayRate = 0.08,
	},

	-- ==========================================
	-- SALVAGE
	-- ==========================================
	ScrapMetal = {
		ItemId = "ScrapMetal",
		DisplayName = "Scrap Metal",
		Description = "Salvaged metal from wrecks. Used for village projects.",
		Category = "Salvage",
		BaseValue = 0,
		Stackable = true,
		MaxStack = 50,
		GridWidth = 1,
		GridHeight = 1,
	},

	OldPlank = {
		ItemId = "OldPlank",
		DisplayName = "Old Plank",
		Description = "Weathered wood from shipwrecks.",
		Category = "Salvage",
		BaseValue = 0,
		Stackable = true,
		MaxStack = 50,
		GridWidth = 1,
		GridHeight = 1,
	},

	RustedGear = {
		ItemId = "RustedGear",
		DisplayName = "Rusted Gear",
		Description = "A corroded mechanical part. Could be useful.",
		Category = "Salvage",
		BaseValue = 0,
		Stackable = true,
		MaxStack = 30,
		GridWidth = 1,
		GridHeight = 1,
	},

	-- ==========================================
	-- BAIT
	-- ==========================================
	WormBait = {
		ItemId = "WormBait",
		DisplayName = "Worm Bait",
		Description = "Basic bait. Attracts common fish.",
		Category = "Bait",
		BaseValue = 5,
		Stackable = true,
		MaxStack = 20,
		GridWidth = 1,
		GridHeight = 1,
	},

	SquidBait = {
		ItemId = "SquidBait",
		DisplayName = "Squid Bait",
		Description = "Attracts uncommon fish. Better than worms.",
		Category = "Bait",
		BaseValue = 15,
		Stackable = true,
		MaxStack = 20,
		GridWidth = 1,
		GridHeight = 1,
	},

	GlowBait = {
		ItemId = "GlowBait",
		DisplayName = "Glow Bait",
		Description = "Bioluminescent bait. Attracts rare night fish.",
		Category = "Bait",
		BaseValue = 40,
		Stackable = true,
		MaxStack = 10,
		GridWidth = 1,
		GridHeight = 1,
	},

	-- ==========================================
	-- MATERIALS
	-- ==========================================
	BasicNet = {
		ItemId = "BasicNet",
		DisplayName = "Basic Net",
		Description = "A simple fishing net. Allows net fishing.",
		Category = "Material",
		BaseValue = 100,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 2,
		GridHeight = 2,
	},

	StrongLine = {
		ItemId = "StrongLine",
		DisplayName = "Strong Line",
		Description = "Reinforced fishing line. Reduces break chance.",
		Category = "Material",
		BaseValue = 200,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 1,
		GridHeight = 2,
	},

	EnginePart = {
		ItemId = "EnginePart",
		DisplayName = "Engine Part",
		Description = "A replacement engine component.",
		Category = "Material",
		BaseValue = 300,
		Stackable = false,
		MaxStack = 1,
		GridWidth = 2,
		GridHeight = 2,
	},

	-- ==========================================
	-- SUPPLIES
	-- ==========================================
	BasicIce = {
		ItemId = "BasicIce",
		DisplayName = "Ice Pack",
		Description = "Keeps fish fresh longer. Reduces decay by 50% for 5 minutes.",
		Category = "Supply",
		BaseValue = 25,
		Stackable = true,
		MaxStack = 10,
		GridWidth = 1,
		GridHeight = 1,
		FreshnessModifier = 0.5,
		Duration = 300,
	},

	PremiumIce = {
		ItemId = "PremiumIce",
		DisplayName = "Premium Ice",
		Description = "High-quality ice. Reduces decay by 75% for 8 minutes.",
		Category = "Supply",
		BaseValue = 60,
		Stackable = true,
		MaxStack = 5,
		GridWidth = 1,
		GridHeight = 1,
		FreshnessModifier = 0.25,
		Duration = 480,
	},

	SaltBox = {
		ItemId = "SaltBox",
		DisplayName = "Salt Box",
		Description = "Salt preservation. Halts decay completely for 3 minutes.",
		Category = "Supply",
		BaseValue = 100,
		Stackable = true,
		MaxStack = 3,
		GridWidth = 1,
		GridHeight = 1,
		FreshnessModifier = 0,
		Duration = 180,
	},
}

function ItemDefinitions.GetItem(itemId: string): ItemDef?
	return ItemDefinitions.Items[itemId]
end

function ItemDefinitions.GetItemsByCategory(category: ItemCategory): { ItemDef }
	local result = {}
	for _, item in ItemDefinitions.Items do
		if item.Category == category then
			table.insert(result, item)
		end
	end
	return result
end

return ItemDefinitions
