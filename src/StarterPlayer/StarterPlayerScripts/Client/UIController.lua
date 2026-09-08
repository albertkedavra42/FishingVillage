local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local UIController = {}
UIController.__index = UIController

local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local currentScreen = nil
local screenStack = {}

local screens = {}

function UIController.Init()
	-- Wait for data load
	local Remotes = require(ReplicatedStorage.Shared.Remotes)
	Remotes.GetServerToClient().PlayerDataLoaded.OnClientEvent:Connect(function(profile)
		UIController.UpdateHUD(profile)
	end)

	Remotes.GetServerToClient().GoldChanged.OnClientEvent:Connect(function(newGold)
		UIController.UpdateGold(newGold)
	end)

	Remotes.GetServerToClient().SalvageChanged.OnClientEvent:Connect(function(newSalvage)
		UIController.UpdateSalvage(newSalvage)
	end)

	Remotes.GetServerToClient().ShowNotification.OnClientEvent:Connect(function(message)
		UIController.ShowNotification(message)
	end)

	Remotes.GetServerToClient().TimeOfDayChanged.OnClientEvent:Connect(function(worldState)
		UIController.UpdateTimeDisplay(worldState)
	end)

	Remotes.GetServerToClient().NewDiscovery.OnClientEvent:Connect(function(discoveryType, id)
		UIController.ShowDiscoveryPopup(discoveryType, id)
	end)

	Remotes.GetServerToClient().BoatDamaged.OnClientEvent:Connect(function(damageData)
		if damageData.StateChanged then
			UIController.ShowNotification("Boat status: " .. damageData.NewState)
		end
		UIController.UpdateHullDisplay(damageData.NewHealth)
	end)

	Remotes.GetServerToClient().FuelChanged.OnClientEvent:Connect(function(fuel)
		UIController.UpdateFuelDisplay(fuel)
	end)

	Remotes.GetServerToClient().HullChanged.OnClientEvent:Connect(function(hull)
		UIController.UpdateHullDisplay(hull)
	end)

	Remotes.GetServerToClient().CargoUpdated.OnClientEvent:Connect(function(cargoData)
		UIController.UpdateCargoDisplay(cargoData)
	end)

	Remotes.GetServerToClient().CargoFull.OnClientEvent:Connect(function()
		UIController.ShowNotification("Cargo is full! Return to sell or discard fish.")
	end)

	Remotes.GetServerToClient().SaleCompleted.OnClientEvent:Connect(function(saleData)
		UIController.ShowNotification("Sold for " .. saleData.TotalGold .. " Gold!")
	end)

	Remotes.GetServerToClient().DisasterWarning.OnClientEvent:Connect(function(disasterData)
		UIController.ShowDisasterWarning(disasterData)
	end)

	print("[UIController] Initialized")
end

function UIController.CreateScreen(name: string, config: {
	Size: UDim2?,
	Position: UDim2?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
})
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local frame = Instance.new("Frame")
	frame.Name = "Container"
	frame.Size = config.Size or UDim2.new(1, 0, 1, 0)
	frame.Position = config.Position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = config.BackgroundColor3 or UIConfig.Colors.Background
	frame.BackgroundTransparency = config.BackgroundTransparency or 0
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	screenGui.Parent = playerGui
	screens[name] = screenGui
	return screenGui, frame
end

function UIController.ShowScreen(name: string)
	local screen = screens[name]
	if screen then
		screen.Enabled = true
	end
end

function UIController.HideScreen(name: string)
	local screen = screens[name]
	if screen then
		screen.Enabled = false
	end
end

function UIController.UpdateHUD(profile)
	-- Create HUD if it doesn't exist
	if not screens.HUD then
		UIController.CreateHUD()
	end

	UIController.UpdateGold(profile.Gold)
	UIController.UpdateSalvage(profile.Salvage)
end

function UIController.CreateHUD()
	local screenGui, container = UIController.CreateHUD()
	return screenGui
end

function UIController.UpdateGold(amount: number)
	local goldLabel = playerGui:FindFirstChild("HUD")
	if goldLabel then
		local goldText = goldLabel:FindFirstChild("Container")
		if goldText then
			local goldValue = goldText:FindFirstChild("GoldValue")
			if goldValue then
				goldValue.Text = tostring(amount)
			end
		end
	end
end

function UIController.UpdateSalvage(amount: number)
	local salvageLabel = playerGui:FindFirstChild("HUD")
	if salvageLabel then
		local salvageText = salvageLabel:FindFirstChild("Container")
		if salvageText then
			local salvageValue = salvageText:FindFirstChild("SalvageValue")
			if salvageValue then
				salvageValue.Text = tostring(amount)
			end
		end
	end
end

function UIController.UpdateHullDisplay(health: number)
	local hullBar = playerGui:FindFirstChild("HUD")
	if hullBar then
		local hullContainer = hullBar:FindFirstChild("Container")
		if hullContainer then
			local hullValue = hullContainer:FindFirstChild("HullValue")
			if hullValue then
				hullValue.Text = tostring(math.floor(health)) .. "%"
			end
		end
	end
end

function UIController.UpdateFuelDisplay(fuel: number)
	local fuelBar = playerGui:FindFirstChild("HUD")
	if fuelBar then
		local fuelContainer = fuelBar:FindFirstChild("Container")
		if fuelContainer then
			local fuelValue = fuelContainer:FindFirstChild("FuelValue")
			if fuelValue then
				fuelValue.Text = tostring(math.floor(fuel))
			end
		end
	end
end

function UIController.UpdateTimeDisplay(worldState)
	local timeLabel = playerGui:FindFirstChild("HUD")
	if timeLabel then
		local timeContainer = timeLabel:FindFirstChild("Container")
		if timeContainer then
			local timeValue = timeContainer:FindFirstChild("TimeValue")
			if timeValue then
				timeValue.Text = worldState.TimeOfDay
			end
		end
	end
end

function UIController.UpdateCargoDisplay(cargoData)
	-- Update cargo grid UI
end

function UIController.ShowNotification(message: string)
	-- Create temporary notification
	local notifScreen = Instance.new("ScreenGui")
	notifScreen.Name = "Notification"
	notifScreen.ResetOnSpawn = false

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, 300, 0, 50)
	notifFrame.Position = UDim2.new(0.5, -150, 0, 50)
	notifFrame.BackgroundColor3 = UIConfig.Colors.Ocean
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notifScreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.MD)
	corner.Parent = notifFrame

	local notifText = Instance.new("TextLabel")
	notifText.Size = UDim2.new(1, -20, 1, 0)
	notifText.Position = UDim2.new(0, 10, 0, 0)
	notifText.BackgroundTransparency = 1
	notifText.Text = message
	notifText.TextColor3 = UIConfig.Colors.White
	notifText.TextSize = UIConfig.TextSizes.Body
	notifText.Font = UIConfig.Fonts.Body
	notifText.Parent = notifFrame

	notifScreen.Parent = playerGui

	-- Auto-remove after 3 seconds
	game:GetService("Debris"):AddItem(notifScreen, 3)
end

function UIController.ShowDiscoveryPopup(discoveryType: string, id: string)
	local popupScreen = Instance.new("ScreenGui")
	popupScreen.Name = "DiscoveryPopup"
	popupScreen.ResetOnSpawn = false

	local popupFrame = Instance.new("Frame")
	popupFrame.Size = UDim2.new(0, 400, 0, 200)
	popupFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
	popupFrame.BackgroundColor3 = UIConfig.Colors.Background
	popupFrame.BorderSizePixel = 0
	popupFrame.Parent = popupScreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = popupFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "New Discovery!"
	title.TextColor3 = UIConfig.Colors.Gold
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = popupFrame

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -40, 0, 60)
	desc.Position = UDim2.new(0, 20, 0, 70)
	desc.BackgroundTransparency = 1
	desc.Text = "You discovered: " .. id
	desc.TextColor3 = UIConfig.Colors.Text
	desc.TextSize = UIConfig.TextSizes.Subheader
	desc.Font = UIConfig.Fonts.Body
	desc.TextWrapped = true
	desc.Parent = popupFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 100, 0, 36)
	closeBtn.Position = UDim2.new(0.5, -50, 1, -50)
	closeBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	closeBtn.Text = "OK"
	closeBtn.TextColor3 = UIConfig.Colors.Text
	closeBtn.TextSize = UIConfig.TextSizes.Body
	closeBtn.Font = UIConfig.Fonts.Button
	closeBtn.Parent = popupFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	btnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		popupScreen:Destroy()
	end)

	popupScreen.Parent = playerGui

	-- Auto-close after 5 seconds
	game:GetService("Debris"):AddItem(popupScreen, 5)
end

function UIController.ShowDisasterWarning(disasterData)
	local warningScreen = Instance.new("ScreenGui")
	warningScreen.Name = "DisasterWarning"
	warningScreen.ResetOnSpawn = false

	local warningFrame = Instance.new("Frame")
	warningFrame.Size = UDim2.new(0, 500, 0, 100)
	warningFrame.Position = UDim2.new(0.5, -250, 0.1, 0)
	warningFrame.BackgroundColor3 = UIConfig.Colors.Danger
	warningFrame.BorderSizePixel = 0
	warningFrame.Parent = warningScreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.MD)
	corner.Parent = warningFrame

	local warningText = Instance.new("TextLabel")
	warningText.Size = UDim2.new(1, -20, 0.5, 0)
	warningText.Position = UDim2.new(0, 10, 0, 10)
	warningText.BackgroundTransparency = 1
	warningText.Text = "⚠ WARNING"
	warningText.TextColor3 = UIConfig.Colors.White
	warningText.TextSize = UIConfig.TextSizes.Header
	warningText.Font = UIConfig.Fonts.Header
	warningText.Parent = warningFrame

	local descText = Instance.new("TextLabel")
	descText.Size = UDim2.new(1, -20, 0.5, 0)
	descText.Position = UDim2.new(0, 10, 0.5, 0)
	descText.BackgroundTransparency = 1
	descText.Text = disasterData.Type .. " approaching! Seek shelter or return to port."
	descText.TextColor3 = UIConfig.Colors.White
	descText.TextSize = UIConfig.TextSizes.Subheader
	descText.Font = UIConfig.Fonts.Body
	descText.Parent = warningFrame

	warningScreen.Parent = playerGui

	game:GetService("Debris"):AddItem(warningScreen, 10)
end

return UIController
