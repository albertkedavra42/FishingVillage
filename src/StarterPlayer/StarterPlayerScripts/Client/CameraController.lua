local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}
CameraController.__index = CameraController

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local currentMode = "ThirdPerson"
local followTarget = nil
local cameraOffset = Vector3.new(0, 15, 20)
local lookAtOffset = Vector3.new(0, 0, -5)
local zoomLevel = 1.0
local minZoom = 0.5
local maxZoom = 2.0
local rotationX = 0
local rotationY = 0
local isRotating = false
local lastMousePosition = nil

local CAMERA_CONFIG = {
	ThirdPersonOffset = Vector3.new(0, 15, 20),
	ThirdPersonLookAt = Vector3.new(0, 0, -5),
	BoatOffset = Vector3.new(0, 12, 18),
	BoatLookAt = Vector3.new(0, 0, -8),
	FishingOffset = Vector3.new(0, 8, 12),
	FishingLookAt = Vector3.new(0, 2, 0),
	VillageOffset = Vector3.new(0, 20, 25),
	VillageLookAt = Vector3.new(0, 0, 0),
	SmoothSpeed = 8,
	MinZoom = 0.5,
	MaxZoom = 2.5,
}

function CameraController.Init()
	-- Handle mouse wheel for zoom
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local delta = input.Position.Z
			zoomLevel = math.clamp(zoomLevel - delta * 0.1, CAMERA_CONFIG.MinZoom, CAMERA_CONFIG.MaxZoom)
		end
	end)

	-- Handle right mouse drag for rotation
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRotating = true
			lastMousePosition = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if isRotating and input.UserInputType == Enum.UserInputType.MouseMovement then
			local currentPos = Vector2.new(input.Position.X, input.Position.Y)
			local delta = currentPos - lastMousePosition

			rotationX = rotationX + delta.X * 0.01
			rotationY = math.clamp(rotationY + delta.Y * 0.01, -0.5, 0.5)

			lastMousePosition = currentPos
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRotating = false
		end
	end)

	-- Camera update loop
	RunService.RenderStepped:Connect(function(dt)
		CameraController.Update(dt)
	end)

	print("[CameraController] Initialized")
end

function CameraController.Update(dt)
	if not followTarget then
		return
	end

	local targetPos = followTarget.Position
	local targetCF = followTarget.CFrame

	-- Calculate desired camera position
	local offset = CAMERA_CONFIG.ThirdPersonOffset * zoomLevel
	local lookAt = CAMERA_CONFIG.ThirdPersonLookAt

	if currentMode == "Boat" then
		offset = CAMERA_CONFIG.BoatOffset * zoomLevel
		lookAt = CAMERA_CONFIG.BoatLookAt
	elseif currentMode == "Fishing" then
		offset = CAMERA_CONFIG.FishingOffset * zoomLevel
		lookAt = CAMERA_CONFIG.FishingLookAt
	elseif currentMode == "Village" then
		offset = CAMERA_CONFIG.VillageOffset * zoomLevel
		lookAt = CAMERA_CONFIG.VillageLookAt
	end

	-- Apply rotation
	local rotatedOffset = CFrame.Angles(0, rotationX, 0) * CFrame.Angles(rotationY, 0, 0)
	local finalOffset = rotatedOffset * CFrame.new(offset)

	-- Smooth camera movement
	local desiredPos = targetPos + finalOffset.Position
	local desiredCF = CFrame.new(desiredPos, targetPos + lookAt)

	camera.CFrame = camera.CFrame:Lerp(desiredCF, CAMERA_CONFIG.SmoothSpeed * dt)
end

function CameraController.FocusOnBoat(boatModel)
	followTarget = boatModel
	currentMode = "Boat"
end

function CameraController.FocusOnFishing(target)
	followTarget = target
	currentMode = "Fishing"
end

function CameraController.FocusOnVillage(target)
	followTarget = target or player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	currentMode = "Village"
end

function CameraController.ResetCamera()
	followTarget = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	currentMode = "ThirdPerson"
	rotationX = 0
	rotationY = 0
	zoomLevel = 1.0
end

function CameraController.SetZoom(level: number)
	zoomLevel = math.clamp(level, CAMERA_CONFIG.MinZoom, CAMERA_CONFIG.MaxZoom)
end

function CameraController.GetZoom()
	return zoomLevel
end

function CameraController.GetCurrentMode()
	return currentMode
end

function CameraController.SetMode(mode: string)
	currentMode = mode
end

return CameraController
