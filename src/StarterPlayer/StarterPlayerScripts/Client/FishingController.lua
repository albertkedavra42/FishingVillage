local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingController = {}
FishingController.__index = FishingController

local player = Players.LocalPlayer

local isFishing = false
local currentZone = nil
local currentSpot = nil
local fishingMethod = "Rod"

local biteTimer = nil
local tensionLevel = 0
local reelProgress = 0
local fishOnLine = false

local MINIGAME_CONFIG = {
	TensionDecayRate = 0.3,
	TensionGainRate = 0.5,
	ReelSpeed = 0.4,
	MaxTension = 100,
	BreakThreshold = 95,
	SuccessThreshold = 100,
}

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

	-- Connect input for minigame
	game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isFishing and fishOnLine then
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
				or input.KeyCode == Enum.KeyCode.Space then
				FishingController.StartReeling()
			end
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if isFishing and fishOnLine then
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
				or input.KeyCode == Enum.KeyCode.Space then
				FishingController.StopReeling()
			end
		end
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
		fishOnLine = false
		tensionLevel = 0
		reelProgress = 0

		-- Start bite timer
		biteTimer = task.delay(result.BiteTime, function()
			if isFishing and not fishOnLine then
				FishingController.TriggerBite()
			end
		end)

		return true
	end

	return false
end

function FishingController.TriggerBite()
	fishOnLine = true
	tensionLevel = 20

	-- Notify server
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	Remotes.GetServerToClient().FishBite:FireServer({
		ZoneId = currentZone,
		SpotId = currentSpot,
	})
end

function FishingController.OnFishBite(data)
	-- Visual/audio feedback for bite
	fishOnLine = true
	tensionLevel = 20

	-- Start minigame loop
	task.spawn(function()
		while isFishing and fishOnLine do
			task.wait(0.05)

			-- Update tension decay
			if not isReeling then
				tensionLevel = math.max(0, tensionLevel - MINIGAME_CONFIG.TensionDecayRate)
			end

			-- Check break condition
			if tensionLevel >= MINIGAME_CONFIG.BreakThreshold then
				FishingController.FishEscaped("Line snapped!")
				return
			end

			-- Check success
			if reelProgress >= MINIGAME_CONFIG.SuccessThreshold then
				FishingController.CatchFish()
				return
			end
		end
	end)
end

local isReeling = false

function FishingController.StartReeling()
	if not isFishing or not fishOnLine then
		return
	end

	isReeling = true

	-- Increase tension while reeling
	task.spawn(function()
		while isReeling and isFishing do
			tensionLevel = math.min(MINIGAME_CONFIG.MaxTension, tensionLevel + MINIGAME_CONFIG.TensionGainRate)
			reelProgress = reelProgress + MINIGAME_CONFIG.ReelSpeed
			task.wait(0.05)
		end
	end)
end

function FishingController.StopReeling()
	isReeling = false
end

function FishingController.CatchFish()
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	local result = Remotes.GetClientToServer().ReelIn:InvokeServer(true)

	isFishing = false
	fishOnLine = false
	tensionLevel = 0
	reelProgress = 0

	if result.Caught then
		-- Show catch UI
		FishingController.ShowCatchResult(result)
	end
end

function FishingController.FishEscaped(reason: string)
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	Remotes.GetClientToServer().ReelIn:InvokeServer(false)

	isFishing = false
	fishOnLine = false
	tensionLevel = 0
	reelProgress = 0

	-- Show escape message
	local UIController = require(script.Parent.UIController)
	UIController.ShowNotification("Fish escaped! " .. (reason or ""))
end

function FishingController.OnFishCaught(data)
	-- Server confirmed catch
end

function FishingController.OnFishEscaped(data)
	-- Server confirmed escape
end

function FishingController.OnSpotUpdate(data)
	-- Update spot visuals
end

function FishingController.ShowCatchResult(result)
	local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CatchResult"
	screenGui.ResetOnSpawn = false

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 350, 0, 250)
	frame.Position = UDim2.new(0.5, -175, 0.5, -125)
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

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = result.SpeciesId
	title.TextColor3 = rarityColor
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = frame

	local variantLabel = Instance.new("TextLabel")
	variantLabel.Size = UDim2.new(1, 0, 0, 25)
	variantLabel.Position = UDim2.new(0, 0, 0, 55)
	variantLabel.BackgroundTransparency = 1
	variantLabel.Text = result.Variant
	variantLabel.TextColor3 = UIConfig.Colors.Muted
	variantLabel.TextSize = UIConfig.TextSizes.Subheader
	variantLabel.Font = UIConfig.Fonts.Body
	variantLabel.Parent = frame

	local weightLabel = Instance.new("TextLabel")
	weightLabel.Size = UDim2.new(1, 0, 0, 25)
	weightLabel.Position = UDim2.new(0, 0, 0, 85)
	weightLabel.BackgroundTransparency = 1
	weightLabel.Text = "Weight: " .. string.format("%.1f", result.Weight) .. " kg"
	weightLabel.TextColor3 = UIConfig.Colors.Text
	weightLabel.TextSize = UIConfig.TextSizes.Body
	weightLabel.Font = UIConfig.Fonts.Body
	weightLabel.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, 0, 0, 25)
	valueLabel.Position = UDim2.new(0, 0, 0, 115)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "Value: " .. result.Value .. " Gold"
	valueLabel.TextColor3 = UIConfig.Colors.Gold
	valueLabel.TextSize = UIConfig.TextSizes.Body
	valueLabel.Font = UIConfig.Fonts.Body
	valueLabel.Parent = frame

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

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 120, 0, 40)
	closeBtn.Position = UDim2.new(0.5, -60, 1, -55)
	closeBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	closeBtn.Text = "Keep"
	closeBtn.TextColor3 = UIConfig.Colors.Text
	closeBtn.TextSize = UIConfig.TextSizes.Body
	closeBtn.Font = UIConfig.Fonts.Button
	closeBtn.Parent = frame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	btnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	screenGui.Parent = player.PlayerGui

	game:GetService("Debris"):AddItem(screenGui, 5)
end

function FishingController.IsFishing()
	return isFishing
end

function FishingController.GetTension()
	return tensionLevel
end

function FishingController.GetReelProgress()
	return reelProgress
end

function FishingController.CancelFishing()
	if isFishing then
		isFishing = false
		fishOnLine = false
		tensionLevel = 0
		reelProgress = 0
		if biteTimer then
			task.cancel(biteTimer)
			biteTimer = nil
		end
	end
end

return FishingController
