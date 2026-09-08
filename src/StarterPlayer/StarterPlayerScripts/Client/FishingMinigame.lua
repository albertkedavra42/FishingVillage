local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingMinigame = {}
FishingMinigame.__index = FishingMinigame

local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

local MINIGAME = {
	BarWidth = 300,
	BarHeight = 30,
	TargetWidth = 40,
	FishSpeed = 2.0,
	FishWander = 1.5,
	TargetSpeed = 3.0,
	TensionMax = 100,
	TensionBreak = 95,
	TensionDecay = 15,
	TensionGainOnReel = 25,
	ReelProgressMax = 100,
	ReelProgressOnHold = 20,
	ReelProgressDecay = 8,
	ReelSweetSpotBonus = 1.5,
}

local activeMinigame = nil
local screenGui = nil
local fishPosition = 50
local fishVelocity = 0
local targetPosition = 50
local tensionLevel = 0
local reelProgress = 0
local isHolding = false
local gameTime = 0
local difficulty = 1.0

function FishingMinigame.Start(fishData, difficultyMod)
	if activeMinigame then
		return false
	end

	difficulty = difficultyMod or 1.0
	fishPosition = 50
	fishVelocity = 0
	targetPosition = 50
	tensionLevel = 20
	reelProgress = 0
	isHolding = false
	gameTime = 0
	activeMinigame = fishData

	-- Scale difficulty
	MINIGAME.FishSpeed = 2.0 * difficulty
	MINIGAME.FishWander = 1.5 * difficulty

	FishingMinigame.CreateUI()
	FishingMinigame.StartLoop()

	return true
end

function FishingMinigame.CreateUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FishingMinigame"
	screenGui.ResetOnSpawn = false

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 360, 0, 200)
	container.Position = UDim2.new(0.5, -180, 0.7, -100)
	container.BackgroundColor3 = Color3.fromHex("#000000")
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.MD)
	containerCorner.Parent = container

	-- Tension label
	local tensionLabel = Instance.new("TextLabel")
	tensionLabel.Name = "TensionLabel"
	tensionLabel.Size = UDim2.new(1, 0, 0, 20)
	tensionLabel.Position = UDim2.new(0, 0, 0, 5)
	tensionLabel.BackgroundTransparency = 1
	tensionLabel.Text = "TENSION"
	tensionLabel.TextColor3 = UIConfig.Colors.White
	tensionLabel.TextSize = UIConfig.TextSizes.Small
	tensionLabel.Font = UIConfig.Fonts.Mono
	tensionLabel.Parent = container

	-- Tension bar background
	local tensionBg = Instance.new("Frame")
	tensionBg.Name = "TensionBg"
	tensionBg.Size = UDim2.new(0, MINIGAME.BarWidth, 0, MINIGAME.BarHeight)
	tensionBg.Position = UDim2.new(0.5, -MINIGAME.BarWidth / 2, 0, 28)
	tensionBg.BackgroundColor3 = Color3.fromHex("#333333")
	tensionBg.BorderSizePixel = 0
	tensionBg.Parent = container

	local tensionBgCorner = Instance.new("UICorner")
	tensionBgCorner.CornerRadius = UDim.new(0, 4)
	tensionBgCorner.Parent = tensionBg

	-- Tension fill
	local tensionFill = Instance.new("Frame")
	tensionFill.Name = "TensionFill"
	tensionFill.Size = UDim2.new(0, 0, 1, 0)
	tensionFill.BackgroundColor3 = UIConfig.Colors.Danger
	tensionFill.BorderSizePixel = 0
	tensionFill.Parent = tensionBg

	local tensionFillCorner = Instance.new("UICorner")
	tensionFillCorner.CornerRadius = UDim.new(0, 4)
	tensionFillCorner.Parent = tensionFill

	-- Reel label
	local reelLabel = Instance.new("TextLabel")
	reelLabel.Name = "ReelLabel"
	reelLabel.Size = UDim2.new(1, 0, 0, 20)
	reelLabel.Position = UDim2.new(0, 0, 0, 65)
	reelLabel.BackgroundTransparency = 1
	reelLabel.Text = "REEL"
	reelLabel.TextColor3 = UIConfig.Colors.White
	reelLabel.TextSize = UIConfig.TextSizes.Small
	reelLabel.Font = UIConfig.Fonts.Mono
	reelLabel.Parent = container

	-- Reel bar background
	local reelBg = Instance.new("Frame")
	reelBg.Name = "ReelBg"
	reelBg.Size = UDim2.new(0, MINIGAME.BarWidth, 0, MINIGAME.BarHeight)
	reelBg.Position = UDim2.new(0.5, -MINIGAME.BarWidth / 2, 0, 88)
	reelBg.BackgroundColor3 = Color3.fromHex("#333333")
	reelBg.BorderSizePixel = 0
	reelBg.Parent = container

	local reelBgCorner = Instance.new("UICorner")
	reelBgCorner.CornerRadius = UDim.new(0, 4)
	reelBgCorner.Parent = reelBg

	-- Reel fill
	local reelFill = Instance.new("Frame")
	reelFill.Name = "ReelFill"
	reelFill.Size = UDim2.new(0, 0, 1, 0)
	reelFill.BackgroundColor3 = UIConfig.Colors.Success
	reelFill.BorderSizePixel = 0
	reelFill.Parent = reelBg

	local reelFillCorner = Instance.new("UICorner")
	reelFillCorner.CornerRadius = UDim.new(0, 4)
	reelFillCorner.Parent = reelFill

	-- Fish indicator
	local fishIndicator = Instance.new("Frame")
	fishIndicator.Name = "FishIndicator"
	fishIndicator.Size = UDim2.new(0, 12, 0, MINIGAME.BarHeight)
	fishIndicator.BackgroundColor3 = UIConfig.Colors.Ocean
	fishIndicator.BorderSizePixel = 0
	fishIndicator.Parent = tensionBg

	local fishCorner = Instance.new("UICorner")
	fishCorner.CornerRadius = UDim.new(0, 6)
	fishCorner.Parent = fishIndicator

	-- Target zone
	local targetZone = Instance.new("Frame")
	targetZone.Name = "TargetZone"
	targetZone.Size = UDim2.new(0, MINIGAME.TargetWidth, 0, MINIGAME.BarHeight)
	targetZone.BackgroundColor3 = UIConfig.Colors.Seafoam
	targetZone.BackgroundTransparency = 0.5
	targetZone.BorderSizePixel = 0
	targetZone.Parent = reelBg

	local targetCorner = Instance.new("UICorner")
	targetCorner.CornerRadius = UDim.new(0, 4)
	targetCorner.Parent = targetZone

	-- Instructions
	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.Size = UDim2.new(1, 0, 0, 25)
	instructions.Position = UDim2.new(0, 0, 1, -30)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Hold SPACE or CLICK to reel. Keep fish in the green zone!"
	instructions.TextColor3 = UIConfig.Colors.Muted
	instructions.TextSize = UIConfig.TextSizes.Small
	instructions.Font = UIConfig.Fonts.Body
	instructions.Parent = container

	-- Fish name display
	if activeMinigame then
		local fishName = Instance.new("TextLabel")
		fishName.Name = "FishName"
		fishName.Size = UDim2.new(1, 0, 0, 20)
		fishName.Position = UDim2.new(0, 0, 0, 0)
		fishName.BackgroundTransparency = 1
		fishName.Text = activeMinigame.SpeciesId or "Unknown Fish"
		fishName.TextColor3 = UIConfig.Colors.Gold
		fishName.TextSize = UIConfig.TextSizes.Subheader
		fishName.Font = UIConfig.Fonts.Header
		fishName.Parent = container
	end

	screenGui.Parent = player.PlayerGui
end

function FishingMinigame.StartLoop()
	-- Input handling
	local UserInputService = game:GetService("UserInputService")
	local inputConn1, inputConn2

	inputConn1 = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Space
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isHolding = true
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			FishingMinigame.Cancel()
			inputConn1:Disconnect()
			inputConn2:Disconnect()
		end
	end)

	inputConn2 = UserInputService.InputEnded:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.Space
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			isHolding = false
		end
	end)

	-- Game loop
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not activeMinigame then
			inputConn1:Disconnect()
			inputConn2:Disconnect()
			return
		end

		gameTime = gameTime + dt

		-- Fish AI movement
		local wanderTarget = 50 + math.sin(gameTime * MINIGAME.FishWander) * 30
			+ math.sin(gameTime * MINIGAME.FishWander * 2.3) * 15
		local fishAccel = (wanderTarget - fishPosition) * 0.5 - fishVelocity * 0.3
		fishVelocity = fishVelocity + fishAccel * dt * MINIGAME.FishSpeed
		fishPosition = fishPosition + fishVelocity * dt * 60
		fishPosition = math.clamp(fishPosition, 5, 95)

		-- Target zone follows fish
		targetPosition = targetPosition + (fishPosition - targetPosition) * dt * MINIGAME.TargetSpeed

		-- Tension logic
		if isHolding then
			-- Check if target is in sweet spot
			local distToFish = math.abs(targetPosition - fishPosition)
			local inSweetSpot = distToFish < MINIGAME.TargetWidth / 2

			if inSweetSpot then
				-- Good reel - progress faster, less tension
				reelProgress = reelProgress + MINIGAME.ReelProgressOnHold * MINIGAME.ReelSweetSpotBonus * dt
				tensionLevel = tensionLevel + MINIGAME.TensionGainOnReel * 0.5 * dt
			else
				-- Bad reel - more tension, less progress
				reelProgress = reelProgress + MINIGAME.ReelProgressOnHold * 0.3 * dt
				tensionLevel = tensionLevel + MINIGAME.TensionGainOnReel * dt
			end
		else
			-- No input - tension decays, reel decays
			tensionLevel = tensionLevel - MINIGAME.TensionDecay * dt
			reelProgress = reelProgress - MINIGAME.ReelProgressDecay * dt
		end

		tensionLevel = math.clamp(tensionLevel, 0, MINIGAME.TensionMax)
		reelProgress = math.clamp(reelProgress, 0, MINIGAME.ReelProgressMax)

		-- Update UI
		FishingMinigame.UpdateUI()

		-- Check win/lose
		if tensionLevel >= MINIGAME.TensionBreak then
			FishingMinigame.Lose("Line snapped!")
			inputConn1:Disconnect()
			inputConn2:Disconnect()
		elseif reelProgress >= MINIGAME.ReelProgressMax then
			FishingMinigame.Win()
			inputConn1:Disconnect()
			inputConn2:Disconnect()
		end
	end)
end

function FishingMinigame.UpdateUI()
	if not screenGui then return end

	local container = screenGui:FindFirstChild("Container")
	if not container then return end

	-- Tension bar
	local tensionBg = container:FindFirstChild("TensionBg")
	if tensionBg then
		local fill = tensionBg:FindFirstChild("TensionFill")
		if fill then
			fill.Size = UDim2.new(tensionLevel / MINIGAME.TensionMax, 0, 1, 0)
			-- Color changes based on tension
			if tensionLevel > 70 then
				fill.BackgroundColor3 = UIConfig.Colors.Danger
			elseif tensionLevel > 40 then
				fill.BackgroundColor3 = UIConfig.Colors.Gold
			else
				fill.BackgroundColor3 = UIConfig.Colors.Success
			end
		end

		-- Fish indicator position
		local fish = tensionBg:FindFirstChild("FishIndicator")
		if fish then
			fish.Position = UDim2.new(fishPosition / 100, -6, 0, 0)
		end
	end

	-- Reel bar
	local reelBg = container:FindFirstChild("ReelBg")
	if reelBg then
		local fill = reelBg:FindFirstChild("ReelFill")
		if fill then
			fill.Size = UDim2.new(reelProgress / MINIGAME.ReelProgressMax, 0, 1, 0)
		end

		-- Target zone position
		local target = reelBg:FindFirstChild("TargetZone")
		if target then
			target.Position = UDim2.new(targetPosition / 100 - MINIGAME.TargetWidth / MINIGAME.BarWidth / 2, 0, 0, 0)
		end
	end
end

function FishingMinigame.Win()
	local result = activeMinigame
	FishingMinigame.Cleanup()

	-- Notify server
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	Remotes.GetClientToServer().ReelIn:InvokeServer(true)

	return result
end

function FishingMinigame.Lose(reason: string)
	FishingMinigame.Cleanup()

	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	Remotes.GetClientToServer().ReelIn:InvokeServer(false)

	local UIController = require(script.Parent.UIController)
	UIController.ShowNotification("Fish escaped! " .. (reason or ""))
end

function FishingMinigame.Cancel()
	FishingMinigame.Cleanup()
end

function FishingMinigame.Cleanup()
	activeMinigame = nil
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

function FishingMinigame.IsActive()
	return activeMinigame ~= nil
end

return FishingMinigame
