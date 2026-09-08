local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyService = {}
EconomyService.__index = EconomyService

local FishDefinitions = require(ReplicatedStorage.Shared.Config.FishDefinitions)

local marketPrices: { [string]: number } = {}
local supplyCounts: { [string]: number } = {}
local DEMAND_MODIFIER = 1.0
local EVENT_MODIFIER = 1.0

local PRICE_FLOOR_RATIO = 0.4
local PRICE_CEILING_RATIO = 3.0
local SUPPLY_IMPACT_FACTOR = 0.005

function EconomyService.Init()
	for speciesId, species in FishDefinitions.Species do
		marketPrices[speciesId] = species.BaseValue
		supplyCounts[speciesId] = 0
	end
end

function EconomyService.GetPrice(speciesId: string): number
	local species = FishDefinitions.GetSpecies(speciesId)
	if not species then
		return 0
	end

	local supplyModifier = EconomyService.CalculateSupplyModifier(speciesId)
	local basePrice = species.BaseValue
	local finalPrice = math.floor(basePrice * supplyModifier * DEMAND_MODIFIER * EVENT_MODIFIER)

	local floor = math.floor(basePrice * PRICE_FLOOR_RATIO)
	local ceiling = math.floor(basePrice * PRICE_CEILING_RATIO)
	finalPrice = math.clamp(finalPrice, floor, ceiling)

	return math.max(1, finalPrice)
end

function EconomyService.CalculateSupplyModifier(speciesId: string): number
	local species = FishDefinitions.GetSpecies(speciesId)
	if not species then
		return 1.0
	end

	local supply = supplyCounts[speciesId] or 0
	local modifier = 1.0 - (supply * SUPPLY_IMPACT_FACTOR)
	return math.clamp(modifier, PRICE_FLOOR_RATIO, PRICE_CEILING_RATIO)
end

function EconomyService.RecordSale(speciesId: string, quantity: number)
	supplyCounts[speciesId] = (supplyCounts[speciesId] or 0) + quantity
end

function EconomyService.GetMarketPrices(): { [string]: number }
	local prices = {}
	for speciesId, _ in FishDefinitions.Species do
		prices[speciesId] = EconomyService.GetPrice(speciesId)
	end
	return prices
end

function EconomyService.GetSupplyCount(speciesId: string): number
	return supplyCounts[speciesId] or 0
end

function EconomyService.ResetSupply(speciesId: string)
	supplyCounts[speciesId] = 0
end

function EconomyService.SetDemandModifier(modifier: number)
	DEMAND_MODIFIER = math.clamp(modifier, 0.1, 5.0)
end

function EconomyService.SetEventModifier(modifier: number)
	EVENT_MODIFIER = math.clamp(modifier, 0.1, 5.0)
end

function EconomyService.CalculateFishValue(speciesId: string, variant: string, freshness: number): number
	local basePrice = EconomyService.GetPrice(speciesId)
	local variantMod = FishDefinitions.VariantModifiers[variant]
	if variantMod then
		basePrice = math.floor(basePrice * variantMod.ValueMultiplier)
	end

	local freshnessMod = 1.0
	if freshness >= 0.8 then
		freshnessMod = 1.0
	elseif freshness >= 0.5 then
		freshnessMod = 0.8
	elseif freshness >= 0.2 then
		freshnessMod = 0.5
	else
		freshnessMod = 0.2
	end

	return math.max(1, math.floor(basePrice * freshnessMod))
end

return EconomyService
