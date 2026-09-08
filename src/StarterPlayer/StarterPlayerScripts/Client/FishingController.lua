local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingController = {}
FishingController.__index = FishingController

local player = Players.LocalPlayer

local isFishing = false
local currentZone = nil
local currentSpot = nil
local fishingMethod = "Rod"

function FishingController.Init()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)

	Remotes.GetServerToClient().FishBite.OnClientEvent:Connect(function(data)
		FishingController.OnFishBite(data)
	end)

	Remotes.GetServerToClient().FishCaught.OnClientEvent:Connect(function(data)
		FishingController.OnFishCaught(data)
	end)

	Remotes.GetServerToClient().FishEscaped.OnClientEvent:Connect(function(data)
		FishingController.OnFishEscaped(data)
	end)

	Remotes.GetServerToClient().FishingSpotUpdate.OnClientEvent:Connect(function(data)
		FishingController.OnSpotUpdate(data)
	end)

	print("[FishingController] Initialized")
end

function FishingController.CastLine(zoneId: string, spotId: string, method: string?)
	currentZone = zoneId
	currentSpot = spotId
	fishingMethod = method or "Rod"

	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local result = Remotes.GetClientToServer().CastLine:InvokeServer(zoneId, spotId, fishingMethod)

	if result.Success then
		isFishing = true

		-- Show waiting UI
		FishingController.ShowWaitingUI(result.BiteTime)

		-- Start bite timer
		task.delay(result.BiteTime, function()
			if isFishing then
				-- Bite happens, server will fire FishBite
			end
		end)

		return true
	end

	return false
end

function FishingController.OnFishBite(data)
	if not isFishing then return end

	-- Hide waiting UI, start minigame
	FishingController.HideWaitingUI()

	local FishingMinigame = require(script.Parent.FishingMinigame)
	local difficulty = 1.0

	-- Increase difficulty at night
	local WorldService = require(ReplicatedStorage):FindFirstChild("Shared")
	-- Simple difficulty scaling
	if data.TimeOfDay == "Night" or data.TimeOfDay == "LateNight" then
		difficulty = 1.3
	end

	FishingMinigame.Start({
		SpeciesId = data.SpeciesId,
		ZoneId = currentZone,
		SpotId = currentSpot,
		Method = fishingMethod,
	}, difficulty)
end

function FishingController.OnFishCaught(data)
	isFishing = false

	-- Show catch result
	FishingController.ShowCatchResult(data)
end

function FishingController.OnFishEscaped(data)
	isFishing = false
end

function FishingController.OnSpotUpdate(data)
	-- Update spot visuals
end

function FishingController.ShowWaitingUI(biteTime: number)
	local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FishingWaiting"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 60)
	frame.Position = UDim2.new(0.5, -100, 0.7, 0)
	frame.BackgroundColor3 = Color3.fromHex("#000000")
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	corner.Parent = frame

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.Text = "Waiting for a bite..."
	text.TextColor3 = UIConfig.Colors.White
	text.TextSize = UIConfig.TextSizes.Subheader
	text.Font = UIConfig.Fonts.Body
	text.Parent = frame

	screenGui.Parent = player.PlayerGui

	-- Animate dots
	task.spawn(function()
		local dots = 0
		while screenGui and screenGui.Parent do
			dots = (dots + 1) % 4
			text.Text = "Waiting for a bite" .. string.rep(".", dots)
			task.wait(0.5)
		end
	end)
end

function FishingController.HideWaitingUI()
	local gui = player.PlayerGui:FindFirstChild("FishingWaiting")
	if gui then
		gui:Destroy()
	end
end

function FishingController.ShowCatchResult(result)
	local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CatchResult"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 350, 0, 280)
	frame.Position = UDim2.new(0.5, -175, 0.5, -140)
	frame.BackgroundColor3 = UIConfig.Colors.Background
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = frame

	-- Rarity color
	local rarityColor = UIConfig.RarityColors.Common
	local FishDefinitions = require(ReplicatedStorage.Shared.Config.FishDefinitions)
	local species = FishDefinitions.GetSpecies(result.SpeciesId)
	if species then
		rarityColor = UIConfig.RarityColors[species.Rarity] or rarityColor
	end

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = result.SpeciesId or "Unknown"
	title.TextColor3 = rarityColor
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = frame

	-- Variant
	local variantLabel = Instance.new("TextLabel")
	variantLabel.Size = UDim2.new(1, 0, 0, 25)
	variantLabel.Position = UDim2.new(0, 0, 0, 55)
	variantLabel.BackgroundTransparency = 1
	variantLabel.Text = result.Variant or "Normal"
	variantLabel.TextColor3 = UIConfig.Colors.Muted
	variantLabel.TextSize = UIConfig.TextSizes.Subheader
	variantLabel.Font = UIConfig.Fonts.Body
	variantLabel.Parent = frame

	-- Weight
	local weightLabel = Instance.new("TextLabel")
	weightLabel.Size = UDim2.new(1, 0, 0, 25)
	weightLabel.Position = UDim2.new(0, 0, 0, 85)
	weightLabel.BackgroundTransparency = 1
	weightLabel.Text = "Weight: " .. string.format("%.1f", result.Weight or 0) .. " kg"
	weightLabel.TextColor3 = UIConfig.Colors.Text
	weightLabel.TextSize = UIConfig.TextSizes.Body
	weightLabel.Font = UIConfig.Fonts.Body
	weightLabel.Parent = frame

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 0, 25)
	valueLabel.Position = UDim2.new(0, 0, 0, 115)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "Value: " .. tostring(result.Value or 0) .. " Gold"
	valueLabel.TextColor3 = UIConfig.Colors.Gold
	valueLabel.TextSize = UIConfig.TextSizes.Body
	valueLabel.Font = UIConfig.Fonts.Body
	valueLabel.Parent = frame

	-- New discovery
	if result.IsNewDiscovery then
		local discoveryLabel = Instance.new("TextLabel")
		discoveryLabel.Size = UDim2.new(1, 0, 0, 25)
		discoveryLabel.Position = UDim2.new(0, 0, 0, 145)
		discoveryLabel.BackgroundTransparency = 1
		discoveryLabel.Text = "NEW SPECIES DISCOVERED!"
		discoveryLabel.TextColor3 = UIConfig.Colors.Gold
		discoveryLabel.TextSize = UIConfig.TextSizes.Subheader
		discoveryLabel.Font = UIConfig.Fonts.Header
		discoveryLabel.Parent = frame
	end

	-- Keep button
	local keepBtn = Instance.new("TextButton")
	keepBtn.Size = UDim2.new(0, 120, 0, 40)
	keepBtn.Position = UDim2.new(0.5, -130, 1, -55)
	keepBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	keepBtn.Text = "Keep"
	keepBtn.TextColor3 = UIConfig.Colors.Text
	keepBtn.TextSize = UIConfig.TextSizes.Body
	keepBtn.Font = UIConfig.Fonts.Button
	keepBtn.Parent = frame

	local keepCorner = Instance.new("UICorner")
	keepCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	keepCorner.Parent = keepBtn

	keepBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	-- Discard button
	local discardBtn = Instance.new("TextButton")
	discardBtn.Size = UDim2.new(0, 120, 0, 40)
	discardBtn.Position = UDim2.new(0.5, 10, 1, -55)
	discardBtn.BackgroundColor3 = UIConfig.Colors.Muted
	discardBtn.Text = "Discard"
	discardBtn.TextColor3 = UIConfig.Colors.White
	discardBtn.TextSize = UIConfig.TextSizes.Body
	discardBtn.Font = UIConfig.Fonts.Button
	discardBtn.Parent = frame

	local discardCorner = Instance.new("UICorner")
	discardCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	discardCorner.Parent = discardBtn

	discardBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	screenGui.Parent = player.PlayerGui

	-- Auto-close after 8 seconds
	game:GetService("Debris"):AddItem(screenGui, 8)
end

function FishingController.IsFishing()
	return isFishing
end

function FishingController.CancelFishing()
	if isFishing then
		isFishing = false
		FishingController.HideWaitingUI()
		local FishingMinigame = require(script.Parent.FishingMinigame)
		if FishingMinigame.IsActive() then
			FishingMinigame.Cancel()
		end
	end
end

function FishingController.GetCurrentZone()
	return currentZone
end

function FishingController.GetCurrentSpot()
	return currentSpot
end

function FishingController.GetMethod()
	return fishingMethod
end

return FishingController
