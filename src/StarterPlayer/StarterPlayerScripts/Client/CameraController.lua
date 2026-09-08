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
local followPosition = Vector3.new(0, 0, 0)
local followHeading = 0

local zoomLevel = 1.0

local CAMERA_CONFIG = {
	ThirdPersonOffset = Vector3.new(0, 12, 18),
	ThirdPersonLookAt = Vector3.new(0, 0, -4),
	BoatOffset = Vector3.new(0, 10, 16),
	BoatLookAt = Vector3.new(0, 2, -6),
	FishingOffset = Vector3.new(0, 8, 10),
	FishingLookAt = Vector3.new(0, 2, 0),
	VillageOffset = Vector3.new(0, 18, 22),
	VillageLookAt = Vector3.new(0, 0, 0),
	SmoothSpeed = 10,
	MinZoom = 0.5,
	MaxZoom = 2.5,
	BoatCamSmoothing = 6,
}

local rotationX = 0
local rotationY = 0
local isRightMouseDown = false
local lastMousePos = nil

function CameraController.Init()
	-- Zoom
	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			zoomLevel = math.clamp(
				zoomLevel - input.Position.Z * 0.15,
				CAMERA_CONFIG.MinZoom,
				CAMERA_CONFIG.MaxZoom
			)
		end
	end)

	-- Right mouse rotate
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRightMouseDown = true
			lastMousePos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if isRightMouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
			local cur = Vector2.new(input.Position.X, input.Position.Y)
			local delta = cur - (lastMousePos or cur)
			rotationX = rotationX + delta.X * 0.008
			rotationY = math.clamp(rotationY + delta.Y * 0.008, -0.6, 0.4)
			lastMousePos = cur
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isRightMouseDown = false
		end
	end)

	-- Camera update
	RunService.RenderStepped:Connect(function(dt)
		CameraController.Update(dt)
	end)

	print("[CameraController] Initialized")
end

function CameraController.Update(dt)
	local targetPos
	local targetLookAt
	local offset
	local lookAt

	if currentMode == "Boat" and followPosition then
		offset = CAMERA_CONFIG.BoatOffset * zoomLevel
		lookAt = CAMERA_CONFIG.BoatLookAt
		targetPos = followPosition
	elseif currentMode == "Fishing" and followPosition then
		offset = CAMERA_CONFIG.FishingOffset * zoomLevel
		lookAt = CAMERA_CONFIG.FishingLookAt
		targetPos = followPosition
	elseif currentMode == "Village" and followPosition then
		offset = CAMERA_CONFIG.VillageOffset * zoomLevel
		lookAt = CAMERA_CONFIG.VillageLookAt
		targetPos = followPosition
	else
		offset = CAMERA_CONFIG.ThirdPersonOffset * zoomLevel
		lookAt = CAMERA_CONFIG.ThirdPersonLookAt
		targetPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character.HumanoidRootPart.Position
			or Vector3.new(0, 5, 0)
	end

	if not targetPos then return end

	-- Apply rotation
	local rotatedOffset = CFrame.Angles(0, rotationX, 0) * CFrame.Angles(rotationY, 0, 0)
	local finalOffset = rotatedOffset * CFrame.new(offset)

	local desiredPos = targetPos + finalOffset.Position
	local desiredCF = CFrame.new(desiredPos, targetPos + lookAt)

	-- Smooth camera
	local smoothFactor = CAMERA_CONFIG.SmoothSpeed * dt
	if currentMode == "Boat" then
		smoothFactor = CAMERA_CONFIG.BoatCamSmoothing * dt
	end
	camera.CFrame = camera.CFrame:Lerp(desiredCF, math.clamp(smoothFactor, 0, 1))
end

function CameraController.FocusOnBoat(model)
	followTarget = model
	currentMode = "Boat"
	rotationX = 0
	rotationY = 0
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
	followTarget = nil
	currentMode = "ThirdPerson"
	rotationX = 0
	rotationY = 0
	zoomLevel = 1.0
end

function CameraController.UpdateBoatFollow(position: Vector3, heading: number)
	followPosition = position
	followHeading = heading
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
