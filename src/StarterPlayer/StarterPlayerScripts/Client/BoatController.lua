local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BoatController = {}
BoatController.__index = BoatController

local player = Players.LocalPlayer

local currentBoat = nil
local boatModel = nil
local isDriving = false
local moveInput = Vector2.new(0, 0)
local currentSpeed = 0
local currentHeading = 0

local BOAT_CONFIG = {
	MaxSpeed = 22,
	Acceleration = 8,
	Deceleration = 5,
	TurnSpeed = 60,
	WaterLevel = 0.5,
	FuelConsumptionRate = 0.5,
	CameraFollowDistance = 18,
	CameraFollowHeight = 12,
	CameraLookAhead = 8,
}

local lastFuelTick = tick()

function BoatController.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)

	Remotes.GetServerToClient().BoatSpawned.OnClientEvent:Connect(function(boatData)
		BoatController.OnBoatSpawned(boatData)
	end)

	Remotes.GetServerToClient().BoatDamaged.OnClientEvent:Connect(function(damageData)
		BoatController.OnBoatDamaged(damageData)
	end)

	Remotes.GetServerToClient().BoatRepaired.OnClientEvent:Connect(function(boatData)
		currentBoat = boatData
	end)

	Remotes.GetServerToClient().FuelChanged.OnClientEvent:Connect(function(fuel)
		if currentBoat then
			currentBoat.Fuel = fuel
		end
	end)

	Remotes.GetServerToClient().HullChanged.OnClientEvent:Connect(function(hull)
		if currentBoat then
			currentBoat.HullHealth = hull
		end
	end)

	-- Keyboard input
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not isDriving then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W then
				moveInput = Vector2.new(moveInput.X, 1)
			elseif input.KeyCode == Enum.KeyCode.S then
				moveInput = Vector2.new(moveInput.X, -1)
			elseif input.KeyCode == Enum.KeyCode.A then
				moveInput = Vector2.new(-1, moveInput.Y)
			elseif input.KeyCode == Enum.KeyCode.D then
				moveInput = Vector2.new(1, moveInput.Y)
			elseif input.KeyCode == Enum.KeyCode.F then
				BoatController.ExitBoat()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed or not isDriving then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
				moveInput = Vector2.new(moveInput.X, 0)
			elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
				moveInput = Vector2.new(0, moveInput.Y)
			end
		end
	end)

	-- Movement loop
	RunService.Heartbeat:Connect(function(dt)
		if isDriving and boatModel then
			BoatController.UpdateMovement(dt)
		end
	end)

	print("[BoatController] Initialized")
end

function BoatController.SpawnBoat(boatId: string?)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	return Remotes.GetClientToServer().SpawnBoat:InvokeServer(boatId)
end

function BoatController.EnterBoat()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local success = Remotes.GetClientToServer().EnterBoat:InvokeServer()
	if success then
		isDriving = true
		currentSpeed = 0
		lastFuelTick = tick()

		-- Find the boat model
		boatModel = workspace:FindFirstChild("Boat_" .. player.UserId)
		if boatModel then
			local hull = boatModel:FindFirstChild("Hull")
			if hull then
				currentHeading = hull.Orientation.Y
			end
		end

		-- Set camera to follow boat
		local CameraController = require(script.Parent.CameraController)
		CameraController.FocusOnBoat(boatModel)
	end
	return success
end

function BoatController.ExitBoat()
	if not isDriving then return false end

	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local success = Remotes.GetClientToServer().ExitBoat:InvokeServer()
	if success then
		isDriving = false
		moveInput = Vector2.new(0, 0)
		currentSpeed = 0

		local CameraController = require(script.Parent.CameraController)
		CameraController.ResetCamera()
	end
	return success
end

function BoatController.UpdateMovement(dt)
	if not boatModel then return end

	local hull = boatModel:FindFirstChild("Hull")
	if not hull then return end

	-- Calculate speed multiplier from hull health
	local speedMult = 1.0
	if currentBoat then
		speedMult = BoatController.GetSpeedMultiplier(currentBoat.HullHealth or 100)
	end

	-- Check fuel
	if currentBoat and currentBoat.Fuel <= 0 then
		speedMult = 0
	end

	-- Forward/backward movement
	local targetSpeed = moveInput.Y * BOAT_CONFIG.MaxSpeed * speedMult
	if targetSpeed ~= 0 then
		currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * BOAT_CONFIG.Acceleration * dt
	else
		currentSpeed = currentSpeed * (1 - BOAT_CONFIG.Deceleration * dt)
		if math.abs(currentSpeed) < 0.1 then
			currentSpeed = 0
		end
	end

	-- Turning
	local turnInput = moveInput.X
	if turnInput ~= 0 and math.abs(currentSpeed) > 0.5 then
		currentHeading = currentHeading + turnInput * BOAT_CONFIG.TurnSpeed * dt
	end

	-- Calculate new position
	local forward = Vector3.new(
		math.sin(math.rad(currentHeading)),
		0,
		math.cos(math.rad(currentHeading))
	)

	local newPos = hull.Position + forward * currentSpeed * dt

	-- Keep at water level with slight bob
	local bobOffset = math.sin(tick() * 2) * 0.1
	newPos = Vector3.new(newPos.X, BOAT_CONFIG.WaterLevel + bobOffset, newPos.Z)

	-- Update hull position
	hull.CFrame = CFrame.new(newPos) * CFrame.Angles(0, math.rad(currentHeading), 0)

	-- Update all boat parts to follow hull
	for _, part in boatModel:GetChildren() do
		if part:IsA("BasePart") and part ~= hull then
			local offset = part.Position - hull.Position
			part.CFrame = CFrame.new(newPos + offset) * CFrame.Angles(0, math.rad(currentHeading), 0)
		end
	end

	-- Consume fuel
	local now = tick()
	local fuelDt = now - lastFuelTick
	if fuelDt >= 1 then
		lastFuelTick = now
		local fuelDrain = BOAT_CONFIG.FuelConsumptionRate * (math.abs(currentSpeed) / BOAT_CONFIG.MaxSpeed) * fuelDt
		if currentBoat then
			currentBoat.Fuel = math.max(0, currentBoat.Fuel - fuelDrain)
			-- Server handles actual fuel consumption
		end
	end

	-- Update camera
	local CameraController = require(script.Parent.CameraController)
	CameraController.UpdateBoatFollow(newPos, currentHeading)
end

function BoatController.GetSpeedMultiplier(hullHealth: number): number
	if hullHealth > 70 then return 1.0
	elseif hullHealth > 40 then return 0.8
	elseif hullHealth > 15 then return 0.5
	else return 0.2 end
end

function BoatController.OnBoatSpawned(boatData)
	currentBoat = boatData
	boatModel = workspace:FindFirstChild("Boat_" .. player.UserId)
end

function BoatController.OnBoatDamaged(damageData)
	if damageData.IsDisabled then
		isDriving = false
		currentSpeed = 0
		local UIController = require(script.Parent.UIController)
		UIController.ShowNotification("Boat disabled! Return to dock for repairs.")
	end
end

function BoatController.RequestRepair()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	return Remotes.GetClientToServer().RequestRepair:InvokeServer()
end

function BoatController.RequestUpgrade(boatId: string)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	return Remotes.GetClientToServer().RequestUpgrade:InvokeServer(boatId)
end

function BoatController.TravelToZone(zoneId: string)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	return Remotes.GetClientToServer().TravelToZone:InvokeServer(zoneId)
end

function BoatController.GetCurrentBoat()
	return currentBoat
end

function BoatController.IsDriving()
	return isDriving
end

function BoatController.GetSpeed()
	return currentSpeed
end

function BoatController.GetHeading()
	return currentHeading
end

return BoatController
