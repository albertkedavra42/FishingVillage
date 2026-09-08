local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoatService = {}
BoatService.__index = BoatService

local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)

local playerBoats: { [number]: {
	BoatId: string,
	HullHealth: number,
	Fuel: number,
	CurrentZone: string?,
	Position: Vector3?,
	IsSpawned: boolean,
	IsInBoat: boolean,
} } = {}

function BoatService.Init()
end

function BoatService.SpawnBoat(player: Player, boatId: string?)
	local profile = playerBoats[player.UserId]
	if profile and profile.IsSpawned then
		return false, "Boat already spawned"
	end

	local targetBoatId = boatId or "StarterBoat"
	local boatDef = BoatDefinitions.GetBoat(targetBoatId)
	if not boatDef then
		return false, "Invalid boat type"
	end

	playerBoats[player.UserId] = {
		BoatId = targetBoatId,
		HullHealth = 100,
		Fuel = boatDef.BaseStats.FuelCapacity,
		CurrentZone = "Shallows",
		Position = Vector3.new(50, 2, 50),
		IsSpawned = true,
		IsInBoat = false,
	}

	return true, playerBoats[player.UserId]
end

function BoatService.DespawnBoat(player: Player)
	if not playerBoats[player.UserId] then
		return false
	end

	playerBoats[player.UserId].IsSpawned = false
	playerBoats[player.UserId].IsInBoat = false
	return true
end

function BoatService.EnterBoat(player: Player): boolean
	local boat = playerBoats[player.UserId]
	if not boat or not boat.IsSpawned then
		return false
	end

	boat.IsInBoat = true
	return true
end

function BoatService.ExitBoat(player: Player): boolean
	local boat = playerBoats[player.UserId]
	if not boat then
		return false
	end

	boat.IsInBoat = false
	return true
end

function BoatService.GetBoat(player: Player)
	return playerBoats[player.UserId]
end

function BoatService.DamageBoat(player: Player, damage: number): {
	NewHealth: number,
	StateChanged: boolean,
	PreviousState: string,
	NewState: string,
	IsDisabled: boolean,
}
	local boat = playerBoats[player.UserId]
	if not boat then
		return { NewHealth = 0, StateChanged = false, PreviousState = "Unknown", NewState = "Unknown", IsDisabled = false }
	end

	local previousState = BoatService.GetHealthState(boat.HullHealth)
	boat.HullHealth = math.max(0, boat.HullHealth - damage)
	local newState = BoatService.GetHealthState(boat.HullHealth)

	return {
		NewHealth = boat.HullHealth,
		StateChanged = previousState ~= newState,
		PreviousState = previousState,
		NewState = newState,
		IsDisabled = boat.HullHealth <= 0,
	}
end

function BoatService.GetHealthState(hullHealth: number): string
	if hullHealth > 70 then
		return "Healthy"
	elseif hullHealth > 40 then
		return "Damaged"
	elseif hullHealth > 15 then
		return "Serious"
	elseif hullHealth > 0 then
		return "Critical"
	else
		return "Disabled"
	end
end

function BoatService.GetSpeedMultiplier(hullHealth: number): number
	if hullHealth > 70 then
		return 1.0
	elseif hullHealth > 40 then
		return 0.8
	elseif hullHealth > 15 then
		return 0.5
	else
		return 0.2
	end
end

function BoatService.ConsumeFuel(player: Player, amount: number): boolean
	local boat = playerBoats[player.UserId]
	if not boat then
		return false
	end

	boat.Fuel = math.max(0, boat.Fuel - amount)
	return boat.Fuel > 0
end

function BoatService.Refuel(player: Player, amount: number)
	local boat = playerBoats[player.UserId]
	if not boat then
		return
	end

	local boatDef = BoatDefinitions.GetBoat(boat.BoatId)
	if not boatDef then
		return
	end

	boat.Fuel = math.min(boatDef.BaseStats.FuelCapacity, boat.Fuel + amount)
end

function BoatService.RepairBoat(player: Player, cost: number): { Success: boolean, Cost: number }
	local boat = playerBoats[player.UserId]
	if not boat then
		return { Success = false, Cost = 0 }
	end

	if boat.HullHealth >= 100 then
		return { Success = false, Cost = 0 }
	end

	boat.HullHealth = 100
	return { Success = true, Cost = cost }
end

function BoatService.CalculateRepairCost(player: Player): number
	local boat = playerBoats[player.UserId]
	if not boat then
		return 0
	end

	local damage = 100 - boat.HullHealth
	if damage <= 0 then
		return 0
	end

	-- Base cost scales with damage
	local baseCost = 50
	local costPerDamage = 2
	return math.floor(baseCost + (damage * costPerDamage))
end

function BoatService.UpgradeBoat(player: Player, newBoatId: string): boolean
	local boat = playerBoats[player.UserId]
	if not boat then
		return false
	end

	local newBoat = BoatDefinitions.GetBoat(newBoatId)
	if not newBoat then
		return false
	end

	boat.BoatId = newBoatId
	boat.HullHealth = 100
	boat.Fuel = newBoat.BaseStats.FuelCapacity

	return true
end

function BoatService.CalculateFuelConsumption(player: Player, deltaTime: number): number
	local boat = playerBoats[player.UserId]
	if not boat or not boat.IsInBoat then
		return 0
	end

	local boatDef = BoatDefinitions.GetBoat(boat.BoatId)
	if not boatDef then
		return 0
	end

	-- Base consumption per second, scales with engine power
	local baseConsumption = 0.5
	local engineScale = boatDef.BaseStats.EnginePower / 100
	return baseConsumption * engineScale * deltaTime
end

return BoatService
