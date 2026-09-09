local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CargoService = {}
CargoService.__index = CargoService

local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)

local playerCargo: { [number]: {
	GridWidth: number,
	GridHeight: number,
	Grid: { { string? } },
	Items: { {
		ItemId: string,
		SpeciesId: string?,
		Variant: string?,
		Weight: number,
		Width: number,
		Height: number,
		Freshness: number,
		FreshnessDecayRate: number,
		Value: number,
		PlacedAt: number,
	} },
	MaxCapacity: number,
	IceActive: boolean?,
	IceModifier: number?,
	IceExpiresAt: number?,
} } = {}

function CargoService.Init()
end

function CargoService.CreateCargoGrid(boatId: string)
	local boat = BoatDefinitions.GetBoat(boatId)
	if not boat then
		return nil
	end

	local grid = {}
	for y = 1, boat.BaseStats.CargoGridHeight do
		grid[y] = {}
		for x = 1, boat.BaseStats.CargoGridWidth do
			grid[y][x] = nil
		end
	end

	return {
		GridWidth = boat.BaseStats.CargoGridWidth,
		GridHeight = boat.BaseStats.CargoGridHeight,
		Grid = grid,
		Items = {},
		MaxCapacity = boat.BaseStats.CargoCapacity,
	}
end

function CargoService.InitPlayerCargo(player: Player, boatId: string)
	playerCargo[player.UserId] = CargoService.CreateCargoGrid(boatId)
end

function CargoService.GetCargo(player: Player)
	return playerCargo[player.UserId]
end

function CargoService.CanPlaceAt(player: Player, x: number, y: number, width: number, height: number): boolean
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return false
	end

	if x < 1 or x + width - 1 > cargo.GridWidth then
		return false
	end
	if y < 1 or y + height - 1 > cargo.GridHeight then
		return false
	end

	for dy = 0, height - 1 do
		for dx = 0, width - 1 do
			if cargo.Grid[y + dy][x + dx] ~= nil then
				return false
			end
		end
	end

	return true
end

function CargoService.PlaceItem(player: Player, itemId: string, speciesId: string?, variant: string?,
	width: number, height: number, weight: number, value: number, freshness: number, freshnessDecayRate: number?): boolean
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return false
	end

	-- Try to find a position
	for y = 1, cargo.GridHeight - height + 1 do
		for x = 1, cargo.GridWidth - width + 1 do
			if CargoService.CanPlaceAt(player, x, y, width, height) then
				local itemRef = itemId .. "_" .. tick() .. "_" .. math.random(10000)

				-- Mark grid
				for dy = 0, height - 1 do
					for dx = 0, width - 1 do
						cargo.Grid[y + dy][x + dx] = itemRef
					end
				end

				-- Add to items list
				table.insert(cargo.Items, {
					ItemId = itemId,
					SpeciesId = speciesId,
					Variant = variant,
					Weight = weight,
					Width = width,
					Height = height,
					Freshness = freshness,
					FreshnessDecayRate = freshnessDecayRate or 0.5,
					Value = value,
					PlacedAt = tick(),
					Ref = itemRef,
				})

				return true
			end
		end
	end

	return false
end

function CargoService.RemoveItem(player: Player, itemRef: string): boolean
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return false
	end

	-- Find and remove from grid
	for y = 1, cargo.GridHeight do
		for x = 1, cargo.GridWidth do
			if cargo.Grid[y][x] == itemRef then
				cargo.Grid[y][x] = nil
			end
		end
	end

	-- Remove from items list
	for i, item in cargo.Items do
		if item.Ref == itemRef then
			table.remove(cargo.Items, i)
			return true
		end
	end

	return false
end

function CargoService.GetUsedCapacity(player: Player): number
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return 0
	end

	local used = 0
	for _, item in cargo.Items do
		used = used + (item.Width * item.Height)
	end
	return used
end

function CargoService.GetFreeCapacity(player: Player): number
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return 0
	end

	return (cargo.GridWidth * cargo.GridHeight) - CargoService.GetUsedCapacity(player)
end

function CargoService.IsFull(player: Player): boolean
	return CargoService.GetFreeCapacity(player) <= 0
end

function CargoService.UpdateFreshness(player: Player, deltaTime: number)
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return
	end

	-- Check if ice has expired
	if cargo.IceActive and cargo.IceExpiresAt and tick() > cargo.IceExpiresAt then
		cargo.IceActive = false
		cargo.IceModifier = nil
		cargo.IceExpiresAt = nil
	end

	local iceMod = cargo.IceModifier or 1.0

	for i = #cargo.Items, 1, -1 do
		local item = cargo.Items[i]
		local decayRate = item.FreshnessDecayRate or 0.5
		item.Freshness = math.max(0, item.Freshness - (decayRate * iceMod) * (deltaTime / 60))
	end
end

function CargoService.ActivateIce(player: Player, itemId: string): boolean
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return false
	end

	local ItemDefinitions = require(ReplicatedStorage.Shared.Config.ItemDefinitions)
	local itemDef = ItemDefinitions.GetItem(itemId)
	if not itemDef or itemDef.Category ~= "Supply" or not itemDef.FreshnessModifier then
		return false
	end

	-- Apply ice effect
	cargo.IceActive = true
	cargo.IceModifier = itemDef.FreshnessModifier
	cargo.IceExpiresAt = tick() + (itemDef.Duration or 300)

	return true
end

function CargoService.ClearCargo(player: Player)
	playerCargo[player.UserId] = nil
end

function CargoService.GetSpoiledItems(player: Player): { string }
	local cargo = playerCargo[player.UserId]
	if not cargo then
		return {}
	end

	local spoiled = {}
	for _, item in cargo.Items do
		if item.Freshness <= 0.1 then
			table.insert(spoiled, item.Ref)
		end
	end
	return spoiled
end

return CargoService
