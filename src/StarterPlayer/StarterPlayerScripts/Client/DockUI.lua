local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local DockUI = {}
DockUI.__index = DockUI

local player = Players.LocalPlayer
local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

local currentScreen = nil
local isUIOpen = false

function DockUI.Init()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.E then
			if isUIOpen then
				DockUI.Close()
			else
				DockUI.OpenVillageMenu()
			end
		end
		if input.KeyCode == Enum.KeyCode.Escape and isUIOpen then
			DockUI.Close()
		end
	end)

	print("[DockUI] Initialized")
end

function DockUI.OpenVillageMenu()
	if isUIOpen then return end
	isUIOpen = true

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VillageMenu"
	screenGui.ResetOnSpawn = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 500, 0, 400)
	container.Position = UDim2.new(0.5, -250, 0.5, -200)
	container.BackgroundColor3 = UIConfig.Colors.Background
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = container

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "Village"
	title.TextColor3 = UIConfig.Colors.Text
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = container

	-- Boat button
	local boatBtn = Instance.new("TextButton")
	boatBtn.Size = UDim2.new(0.8, 0, 0, 44)
	boatBtn.Position = UDim2.new(0.1, 0, 0, 70)
	boatBtn.BackgroundColor3 = UIConfig.Colors.Ocean
	boatBtn.Text = "  Spawn Boat"
	boatBtn.TextColor3 = UIConfig.Colors.White
	boatBtn.TextSize = UIConfig.TextSizes.Body
	boatBtn.Font = UIConfig.Fonts.Button
	boatBtn.TextXAlignment = Enum.TextXAlignment.Left
	boatBtn.Parent = container

	local boatCorner = Instance.new("UICorner")
	boatCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	boatCorner.Parent = boatBtn

	boatBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
		local BoatController = require(player.PlayerScripts.Client.BoatController)
		BoatController.SpawnBoat()
	end)

	-- Enter Boat button
	local enterBtn = Instance.new("TextButton")
	enterBtn.Size = UDim2.new(0.8, 0, 0, 44)
	enterBtn.Position = UDim2.new(0.1, 0, 0, 124)
	enterBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	enterBtn.Text = "  Board Boat"
	enterBtn.TextColor3 = UIConfig.Colors.Text
	enterBtn.TextSize = UIConfig.TextSizes.Body
	enterBtn.Font = UIConfig.Fonts.Button
	enterBtn.TextXAlignment = Enum.TextXAlignment.Left
	enterBtn.Parent = container

	local enterCorner = Instance.new("UICorner")
	enterCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	enterCorner.Parent = enterBtn

	enterBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
		local BoatController = require(player.PlayerScripts.Client.BoatController)
		BoatController.EnterBoat()
	end)

	-- Market button
	local marketBtn = Instance.new("TextButton")
	marketBtn.Size = UDim2.new(0.8, 0, 0, 44)
	marketBtn.Position = UDim2.new(0.1, 0, 0, 178)
	marketBtn.BackgroundColor3 = UIConfig.Colors.Gold
	marketBtn.Text = "  Fish Market"
	marketBtn.TextColor3 = UIConfig.Colors.Text
	marketBtn.TextSize = UIConfig.TextSizes.Body
	marketBtn.Font = UIConfig.Fonts.Button
	marketBtn.TextXAlignment = Enum.TextXAlignment.Left
	marketBtn.Parent = container

	local marketCorner = Instance.new("UICorner")
	marketCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	marketCorner.Parent = marketBtn

	marketBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
		-- Market UI handled separately
	end)

	-- Shipwright button
	local shipBtn = Instance.new("TextButton")
	shipBtn.Size = UDim2.new(0.8, 0, 0, 44)
	shipBtn.Position = UDim2.new(0.1, 0, 0, 232)
	shipBtn.BackgroundColor3 = Color3.fromHex("#8B7355")
	shipBtn.Text = "  Shipwright (Repair/Upgrade)"
	shipBtn.TextColor3 = UIConfig.Colors.White
	shipBtn.TextSize = UIConfig.TextSizes.Body
	shipBtn.Font = UIConfig.Fonts.Button
	shipBtn.TextXAlignment = Enum.TextXAlignment.Left
	shipBtn.Parent = container

	local shipCorner = Instance.new("UICorner")
	shipCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	shipCorner.Parent = shipBtn

	shipBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
		-- Shipwright UI handled separately
	end)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 100, 0, 36)
	closeBtn.Position = UDim2.new(0.5, -50, 1, -50)
	closeBtn.BackgroundColor3 = UIConfig.Colors.Muted
	closeBtn.Text = "Close"
	closeBtn.TextColor3 = UIConfig.Colors.White
	closeBtn.TextSize = UIConfig.TextSizes.Body
	closeBtn.Font = UIConfig.Fonts.Button
	closeBtn.Parent = container

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
	end)

	screenGui.Parent = player.PlayerGui
	currentScreen = screenGui
end

function DockUI.OpenRepairUI()
	isUIOpen = true

	local BoatController = require(player.PlayerScripts.Client.BoatController)
	local boat = BoatController.GetCurrentBoat()
	if not boat then return end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RepairUI"
	screenGui.ResetOnSpawn = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 350, 0, 280)
	container.Position = UDim2.new(0.5, -175, 0.5, -140)
	container.BackgroundColor3 = UIConfig.Colors.Background
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = container

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "Boat Repair"
	title.TextColor3 = UIConfig.Colors.Text
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = container

	local hullLabel = Instance.new("TextLabel")
	hullLabel.Size = UDim2.new(1, -40, 0, 30)
	hullLabel.Position = UDim2.new(0, 20, 0, 60)
	hullLabel.BackgroundTransparency = 1
	hullLabel.Text = "Hull Health: " .. tostring(math.floor(boat.HullHealth)) .. "%"
	hullLabel.TextColor3 = UIConfig.Colors.Text
	hullLabel.TextSize = UIConfig.TextSizes.Subheader
	hullLabel.Font = UIConfig.Fonts.Body
	hullLabel.TextXAlignment = Enum.TextXAlignment.Left
	hullLabel.Parent = container

	-- Hull bar
	local hullBarBg = Instance.new("Frame")
	hullBarBg.Size = UDim2.new(1, -40, 0, 12)
	hullBarBg.Position = UDim2.new(0, 20, 0, 95)
	hullBarBg.BackgroundColor3 = Color3.fromHex("#333333")
	hullBarBg.BorderSizePixel = 0
	hullBarBg.Parent = container

	local hullBarFill = Instance.new("Frame")
	hullBarFill.Size = UDim2.new(boat.HullHealth / 100, 0, 1, 0)
	hullBarFill.BackgroundColor3 = UIConfig.Colors.Success
	hullBarFill.BorderSizePixel = 0
	hullBarFill.Parent = hullBarBg

	local hullBarCorner = Instance.new("UICorner")
	hullBarCorner.CornerRadius = UDim.new(0, 4)
	hullBarCorner.Parent = hullBarBg

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, -40, 0, 30)
	costLabel.Position = UDim2.new(0, 20, 0, 120)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Cost: -- Gold"
	costLabel.TextColor3 = UIConfig.Colors.Gold
	costLabel.TextSize = UIConfig.TextSizes.Subheader
	costLabel.Font = UIConfig.Fonts.Body
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = container

	local repairBtn = Instance.new("TextButton")
	repairBtn.Size = UDim2.new(0.8, 0, 0, 44)
	repairBtn.Position = UDim2.new(0.1, 0, 0, 170)
	repairBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	repairBtn.Text = "Repair"
	repairBtn.TextColor3 = UIConfig.Colors.Text
	repairBtn.TextSize = UIConfig.TextSizes.Body
	repairBtn.Font = UIConfig.Fonts.Button
	repairBtn.Parent = container

	local repairCorner = Instance.new("UICorner")
	repairCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	repairCorner.Parent = repairBtn

	repairBtn.MouseButton1Click:Connect(function()
		local result = BoatController.RequestRepair()
		if result.Success then
			DockUI.Close()
		end
	end)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 100, 0, 36)
	closeBtn.Position = UDim2.new(0.5, -50, 1, -50)
	closeBtn.BackgroundColor3 = UIConfig.Colors.Muted
	closeBtn.Text = "Close"
	closeBtn.TextColor3 = UIConfig.Colors.White
	closeBtn.TextSize = UIConfig.TextSizes.Body
	closeBtn.Font = UIConfig.Fonts.Button
	closeBtn.Parent = container

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
	end)

	screenGui.Parent = player.PlayerGui
	currentScreen = screenGui
end

function DockUI.Close()
	if currentScreen then
		currentScreen:Destroy()
		currentScreen = nil
	end
	isUIOpen = false
end

function DockUI.IsOpen()
	return isUIOpen
end

return DockUI
