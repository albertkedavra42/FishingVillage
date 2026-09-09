local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local TutorialController = {}
TutorialController.__index = TutorialController

local player = Players.LocalPlayer
local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local currentStep = 0
local tutorialActive = false
local tutorialScreen = nil

local Steps = {
	{
		Title = "Welcome to Fishing Village!",
		Text = "You are a fisherman in a growing village.\nYour goal: catch fish, sell your catch, and upgrade your boat.",
		Hint = "Press E near the dock to open the village menu.",
	},
	{
		Title = "Spawn Your Boat",
		Text = "Open the village menu and click 'Spawn Boat'.\nThen click 'Board Boat' to get in.",
		Hint = "Press E to open the menu, then click Spawn Boat.",
	},
	{
		Title = "Leave the Harbor",
		Text = "Use WASD to drive your boat out of the harbor.\nHead toward the Shallows fishing zone.",
		Hint = "W = forward, S = backward, A/D = turn.",
	},
	{
		Title = "Find a Fishing Spot",
		Text = "Look for glowing markers in the water.\nThese are fishing spots where fish can be found.",
		Hint = "Approach a spot and press E to start fishing.",
	},
	{
		Title = "Catch Fish",
		Text = "When a fish bites, a minigame will appear.\nHold Space or click to reel in the fish.\nKeep the tension in the green zone!",
		Hint = "Release if tension gets too high, reel when safe.",
	},
	{
		Title = "Manage Your Cargo",
		Text = "Caught fish go into your cargo grid.\nYou can only carry so much — choose wisely!",
		Hint = "Check your HUD to see cargo usage.",
	},
	{
		Title = "Return to Sell",
		Text = "When your cargo is full or you're done fishing,\ndrive back to the harbor and press E to open the menu.\nVisit the Fish Market to sell your catch!",
		Hint = "Don't run out of fuel! Keep an eye on your HUD.",
	},
	{
		Title = "Upgrade and Progress",
		Text = "Earn Gold to repair and upgrade your boat.\nContribute to village projects to unlock new zones.\nGood luck, fisherman!",
		Hint = "Visit the Shipwright for repairs and upgrades.",
	},
}

function TutorialController.Init()
	Remotes.GetServerToClient().PlayerDataLoaded.OnClientEvent:Connect(function(profile)
		-- Check if this is a new player (no trips yet)
		if profile.Stats and profile.Stats.TotalTrips == 0 then
			task.wait(2) -- Wait for everything to load
			TutorialController.Start()
		end
	end)

	print("[TutorialController] Initialized")
end

function TutorialController.Start()
	if tutorialActive then return end
	tutorialActive = true
	currentStep = 1
	TutorialController.ShowStep(currentStep)
end

function TutorialController.ShowStep(stepNum)
	local step = Steps[stepNum]
	if not step then
		TutorialController.Complete()
		return
	end

	-- Remove old screen
	if tutorialScreen then
		tutorialScreen:Destroy()
		tutorialScreen = nil
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Tutorial"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 420, 0, 200)
	container.Position = UDim2.new(0.5, -210, 1, -220)
	container.BackgroundColor3 = UIConfig.Colors.Ocean
	container.BackgroundTransparency = 0.1
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = container

	-- Step indicator
	local stepLabel = Instance.new("TextLabel")
	stepLabel.Size = UDim2.new(1, -20, 0, 20)
	stepLabel.Position = UDim2.new(0, 10, 0, 8)
	stepLabel.BackgroundTransparency = 1
	stepLabel.Text = "Step " .. stepNum .. " of " .. #Steps
	stepLabel.TextColor3 = UIConfig.Colors.Seafoam
	stepLabel.TextSize = UIConfig.TextSizes.Small
	stepLabel.Font = UIConfig.Fonts.Body
	stepLabel.TextXAlignment = Enum.TextXAlignment.Left
	stepLabel.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = step.Title
	title.TextColor3 = UIConfig.Colors.Gold
	title.TextSize = UIConfig.TextSizes.Header
	title.Font = UIConfig.Fonts.Header
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	-- Description
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 60)
	desc.Position = UDim2.new(0, 10, 0, 58)
	desc.BackgroundTransparency = 1
	desc.Text = step.Text
	desc.TextColor3 = UIConfig.Colors.White
	desc.TextSize = UIConfig.TextSizes.Body
	desc.Font = UIConfig.Fonts.Body
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextWrapped = true
	desc.Parent = container

	-- Hint
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, -20, 0, 30)
	hint.Position = UDim2.new(0, 10, 0, 118)
	hint.BackgroundTransparency = 1
	hint.Text = step.Hint
	hint.TextColor3 = UIConfig.Colors.Seafoam
	hint.TextSize = UIConfig.TextSizes.Small
	hint.Font = UIConfig.Fonts.Body
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextWrapped = true
	hint.Parent = container

	-- Next button
	local nextBtn = Instance.new("TextButton")
	nextBtn.Size = UDim2.new(0, 100, 0, 36)
	nextBtn.Position = UDim2.new(1, -115, 1, -48)
	nextBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	nextBtn.Text = stepNum < #Steps and "Next" or "Start Playing!"
	nextBtn.TextColor3 = UIConfig.Colors.Text
	nextBtn.TextSize = UIConfig.TextSizes.Body
	nextBtn.Font = UIConfig.Fonts.Button
	nextBtn.Parent = container

	local nextCorner = Instance.new("UICorner")
	nextCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	nextCorner.Parent = nextBtn

	nextBtn.MouseButton1Click:Connect(function()
		currentStep = currentStep + 1
		TutorialController.ShowStep(currentStep)
	end)

	-- Skip button
	local skipBtn = Instance.new("TextButton")
	skipBtn.Size = UDim2.new(0, 60, 0, 28)
	skipBtn.Position = UDim2.new(0, 10, 1, -44)
	skipBtn.BackgroundTransparency = 1
	skipBtn.Text = "Skip"
	skipBtn.TextColor3 = UIConfig.Colors.Muted
	skipBtn.TextSize = UIConfig.TextSizes.Small
	skipBtn.Font = UIConfig.Fonts.Body
	skipBtn.Parent = container

	skipBtn.MouseButton1Click:Connect(function()
		TutorialController.Complete()
	end)

	screenGui.Parent = player.PlayerGui
	tutorialScreen = screenGui
end

function TutorialController.Complete()
	tutorialActive = false
	currentStep = 0
	if tutorialScreen then
		tutorialScreen:Destroy()
		tutorialScreen = nil
	end
end

function TutorialController.IsActive()
	return tutorialActive
end

function TutorialController.Skip()
	TutorialController.Complete()
end

return TutorialController
