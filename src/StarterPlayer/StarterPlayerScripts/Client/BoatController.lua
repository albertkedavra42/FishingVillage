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
local moveDirection = Vector3.new(0, 0, 0)

local BOAT_CONFIG = {
	TurnSpeed = 2,
	Acceleration = 10,
	MaxSpeed = 20,
	WaterLevel = 0.5,
	RockDamageCooldown = 2,
}

local lastRockDamageTime = 0

function BoatController.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)

	Remotes.GetServerToClient().BoatSpawned.OnClientEvent:Connect(function(boatData)
		BoatController.OnBoatSpawned(boatData)
	end)

	Remotes.GetServerToClient().BoatDamaged.OnClientEvent:Connect(function(damageData)
		BoatController.OnBoatDamaged(damageData)
	end)

	Remotes.GetServerToClient().BoatRepaired.OnClientEvent:Connect(function(boatData)
		BoatController.OnBoatRepaired(boatData)
	end)

	-- Handle keyboard input for boat movement
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isDriving then
			if input.KeyCode == Enum.KeyCode.W then
				moveDirection = Vector3.new(0, 0, -1)
			elseif input.KeyCode == Enum.KeyCode.S then
				moveDirection = Vector3.new(0, 0, 1)
			elseif input.KeyCode == Enum.KeyCode.A then
				moveDirection = Vector3.new(-1, 0, 0)
			elseif input.KeyCode == Enum.KeyCode.D then
				moveDirection = Vector3.new(1, 0, 0)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isDriving then
			if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S then
				moveDirection = Vector3.new(moveDirection.X, 0, 0)
			elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
				moveDirection = Vector3.new(0, 0, moveDirection.Z)
			end
		end
	end)

	-- Movement update loop
	RunService.Heartbeat:Connect(function(dt)
		if isDriving and boatModel then
			BoatController.UpdateMovement(dt)
		end
	end)

	print("[BoatController] Initialized")
end

function BoatController.SpawnBoat(boatId: string?)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local success, data = Remotes.GetClientToServer().SpawnBoat:InvokeServer(boatId)
	return success, data
end

function BoatController.DespawnBoat()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	return Remotes.GetClientToServer().DespawnBoat:InvokeServer()
end

function BoatController.EnterBoat()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local success = Remotes.GetClientToServer().EnterBoat:InvokeServer()
	if success then
		isDriving = true
		-- Attach camera to boat
		local CameraController = require(script.Parent.CameraController)
		CameraController.FocusOnBoat(boatModel)
	end
	return success
end

function BoatController.ExitBoat()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local success = Remotes.GetClientToServer().ExitBoat:InvokeServer()
	if success then
		isDriving = false
		moveDirection = Vector3.new(0, 0, 0)
		-- Reset camera
		local CameraController = require(script.Parent.CameraController)
		CameraController.ResetCamera()
	end
	return success
end

function BoatController.OnBoatSpawned(boatData)
	currentBoat = boatData
	-- Create boat model in workspace
	-- This would create the actual 3D model
	-- For now, just store the data
end

function BoatController.OnBoatDamaged(damageData)
	-- Visual feedback for damage
	if damageData.IsDisabled then
		isDriving = false
		local UIController = require(script.Parent.UIController)
		UIController.ShowNotification("Boat disabled! Must return for repairs.")
	end
end

function BoatController.OnBoatRepaired(boatData)
	currentBoat = boatData
	local UIController = require(script.Parent.UIController)
	UIController.ShowNotification("Boat fully repaired!")
end

function BoatController.UpdateMovement(dt)
	if not boatModel then
		return
	end

	-- Calculate speed based on hull health
	local speedMult = 1.0
	if currentBoat then
		local BoatService = require(ReplicatedStorage.Shared.Config.BoatDefinitions)
		local boatDef = BoatService.GetBoat(currentBoat.BoatId)
		if boatDef then
			speedMult = BoatController.GetSpeedMultiplier(currentBoat.HullHealth or 100)
		end
	end

	local speed = BOAT_CONFIG.MaxSpeed * speedMult
	local moveVector = moveDirection * speed * dt

	-- Apply movement to boat model
	boatModel.CFrame = boatModel.CFrame * CFrame.new(moveVector)

	-- Keep boat at water level
	local pos = boatModel.Position
	boatModel.Position = Vector3.new(pos.X, BOAT_CONFIG.WaterLevel, pos.Z)
end

function BoatController.GetSpeedMultiplier(hullHealth: number): number
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

function BoatController.RequestRepair()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local result = Remotes.GetClientToServer().RequestRepair:InvokeServer()
	return result
end

function BoatController.RequestUpgrade(boatId: string)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local result = Remotes.GetClientToServer().RequestUpgrade:InvokeServer(boatId)
	return result
end

function BoatController.TravelToZone(zoneId: string)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local result = Remotes.GetClientToServer().TravelToZone:InvokeServer(zoneId)
	return result
end

function BoatController.GetCurrentBoat()
	return currentBoat
end

function BoatController.IsDriving()
	return isDriving
end

function BoatController.CheckRockCollision()
	-- Simple collision check - would use raycasting in production
	local now = tick()
	if now - lastRockDamageTime < BOAT_CONFIG.RockDamageCooldown then
		return
	end

	-- Check nearby rocks
	-- This is a placeholder for actual collision detection
	lastRockDamageTime = now
	return true
end

return BoatController
