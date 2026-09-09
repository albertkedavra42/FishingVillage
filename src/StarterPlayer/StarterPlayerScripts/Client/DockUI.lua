local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local DockUI = {}
DockUI.__index = DockUI

local player = Players.LocalPlayer
local UIConfig = require(ReplicatedStorage.Shared.Config.UIConfig)
local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)
local FishDefinitions = require(ReplicatedStorage.Shared.Config.FishDefinitions)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

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

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "Village"
	title.TextColor3 = UIConfig.Colors.Text
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = container

	local function CreateMenuButton(text: string, color: Color3, yOff: number, textColor: Color3?): TextButton
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.8, 0, 0, 44)
		btn.Position = UDim2.new(0.1, 0, 0, yOff)
		btn.BackgroundColor3 = color
		btn.Text = "  " .. text
		btn.TextColor3 = textColor or UIConfig.Colors.White
		btn.TextSize = UIConfig.TextSizes.Body
		btn.Font = UIConfig.Fonts.Button
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = container

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
		c.Parent = btn

		return btn
	end

	CreateMenuButton("Spawn Boat", UIConfig.Colors.Ocean, 70).MouseButton1Click:Connect(function()
		DockUI.Close()
		local BoatController = require(player.PlayerScripts.Client.BoatController)
		BoatController.SpawnBoat()
	end)

	CreateMenuButton("Board Boat", UIConfig.Colors.Seafoam, 124, UIConfig.Colors.Text).MouseButton1Click:Connect(function()
		DockUI.Close()
		local BoatController = require(player.PlayerScripts.Client.BoatController)
		BoatController.EnterBoat()
	end)

	CreateMenuButton("Fish Market", UIConfig.Colors.Gold, 178, UIConfig.Colors.Text).MouseButton1Click:Connect(function()
		DockUI.Close()
		DockUI.OpenMarketUI()
	end)

	CreateMenuButton("Shipwright (Repair/Upgrade)", Color3.fromHex("#8B7355"), 232).MouseButton1Click:Connect(function()
		DockUI.Close()
		DockUI.OpenShipwrightUI()
	end)

	local closeBtn = CreateMenuButton("Close", UIConfig.Colors.Muted, 340)
	closeBtn.TextXAlignment = Enum.TextXAlignment.Center
	closeBtn.MouseButton1Click:Connect(function()
		DockUI.Close()
	end)

	screenGui.Parent = player.PlayerGui
	currentScreen = screenGui
end

-- ==========================================
-- FISH MARKET UI
-- ==========================================

function DockUI.OpenMarketUI()
	isUIOpen = true

	local BoatController = require(player.PlayerScripts.Client.BoatController)
	local boat = BoatController.GetCurrentBoat()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MarketUI"
	screenGui.ResetOnSpawn = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 520, 0, 480)
	container.Position = UDim2.new(0.5, -260, 0.5, -240)
	container.BackgroundColor3 = UIConfig.Colors.Background
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.LG)
	corner.Parent = container

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "Fish Market"
	title.TextColor3 = UIConfig.Colors.Gold
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = container

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -40, 0, 24)
	subtitle.Position = UDim2.new(0, 20, 0, 48)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Sell your catch to the NPC market"
	subtitle.TextColor3 = UIConfig.Colors.Muted
	subtitle.TextSize = UIConfig.TextSizes.Small
	subtitle.Font = UIConfig.Fonts.Body
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = container

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 0, 300)
	scrollFrame.Position = UDim2.new(0, 10, 0, 80)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = UIConfig.Colors.Muted
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = scrollFrame

	local selectedItems = {}
	local totalGoldLabel

	local function RefreshCargoList()
		for _, child in scrollFrame:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		selectedItems = {}

		local cargoRemote = Remotes.GetClientToServer()
		-- We'll display placeholder until cargo data is fetched from server
		-- For now, read from local BoatController state

		local yOrder = 0

		-- Empty state
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 40)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No fish in cargo. Go fishing first!"
		emptyLabel.TextColor3 = UIConfig.Colors.Muted
		emptyLabel.TextSize = UIConfig.TextSizes.Body
		emptyLabel.Font = UIConfig.Fonts.Body
		emptyLabel.LayoutOrder = 9999
		emptyLabel.Parent = scrollFrame

		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOrder * 48 + 8)
	end

	-- Sell All button
	local sellAllBtn = Instance.new("TextButton")
	sellAllBtn.Size = UDim2.new(0.45, 0, 0, 44)
	sellAllBtn.Position = UDim2.new(0.025, 0, 0, 390)
	sellAllBtn.BackgroundColor3 = UIConfig.Colors.Seafoam
	sellAllBtn.Text = "Sell All Fish"
	sellAllBtn.TextColor3 = UIConfig.Colors.Text
	sellAllBtn.TextSize = UIConfig.TextSizes.Body
	sellAllBtn.Font = UIConfig.Fonts.Button
	sellAllBtn.Parent = container

	local sellAllCorner = Instance.new("UICorner")
	sellAllCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	sellAllCorner.Parent = sellAllBtn

	sellAllBtn.MouseButton1Click:Connect(function()
		-- Fetch current cargo from server and sell all
		DockUI.Close()
		local UIController = require(player.PlayerScripts.Client.UIController)
		UIController.ShowNotification("Returning to dock to sell...")
	end)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0.45, 0, 0, 44)
	closeBtn.Position = UDim2.new(0.525, 0, 0, 390)
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

	RefreshCargoList()

	screenGui.Parent = player.PlayerGui
	currentScreen = screenGui
end

-- ==========================================
-- SHIPWRIGHT UI (Repair + Upgrade)
-- ==========================================

function DockUI.OpenShipwrightUI()
	isUIOpen = true

	local BoatController = require(player.PlayerScripts.Client.BoatController)
	local boat = BoatController.GetCurrentBoat()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShipwrightUI"
	screenGui.ResetOnSpawn = false

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, 520, 0, 520)
	container.Position = UDim2.new(0.5, -260, 0.5, -260)
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
	title.Text = "Shipwright"
	title.TextColor3 = UIConfig.Colors.Text
	title.TextSize = UIConfig.TextSizes.HeaderLarge
	title.Font = UIConfig.Fonts.Header
	title.Parent = container

	-- ===== REPAIR SECTION =====
	local repairSection = Instance.new("Frame")
	repairSection.Size = UDim2.new(1, -40, 0, 140)
	repairSection.Position = UDim2.new(0, 20, 0, 60)
	repairSection.BackgroundColor3 = UIConfig.Colors.White
	repairSection.BorderSizePixel = 0
	repairSection.Parent = container

	local repairCorner = Instance.new("UICorner")
	repairCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	repairCorner.Parent = repairSection

	local repairTitle = Instance.new("TextLabel")
	repairTitle.Size = UDim2.new(1, -20, 0, 30)
	repairTitle.Position = UDim2.new(0, 10, 0, 5)
	repairTitle.BackgroundTransparency = 1
	repairTitle.Text = "Repair"
	repairTitle.TextColor3 = UIConfig.Colors.Text
	repairTitle.TextSize = UIConfig.TextSizes.Subheader
	repairTitle.Font = UIConfig.Fonts.Header
	repairTitle.TextXAlignment = Enum.TextXAlignment.Left
	repairTitle.Parent = repairSection

	local currentHull = boat and boat.HullHealth or 100
	local hullLabel = Instance.new("TextLabel")
	hullLabel.Size = UDim2.new(0.5, -15, 0, 22)
	hullLabel.Position = UDim2.new(0, 10, 0, 38)
	hullLabel.BackgroundTransparency = 1
	hullLabel.Text = "Hull: " .. math.floor(currentHull) .. "%"
	hullLabel.TextColor3 = UIConfig.Colors.Text
	hullLabel.TextSize = UIConfig.TextSizes.Body
	hullLabel.Font = UIConfig.Fonts.Body
	hullLabel.TextXAlignment = Enum.TextXAlignment.Left
	hullLabel.Parent = repairSection

	local hullBarBg = Instance.new("Frame")
	hullBarBg.Size = UDim2.new(0.5, -15, 0, 10)
	hullBarBg.Position = UDim2.new(0.5, 5, 0, 42)
	hullBarBg.BackgroundColor3 = Color3.fromHex("#333333")
	hullBarBg.BorderSizePixel = 0
	hullBarBg.Parent = repairSection

	local hullBarFill = Instance.new("Frame")
	hullBarFill.Size = UDim2.new(math.clamp(currentHull / 100, 0, 1), 0, 1, 0)
	hullBarFill.BorderSizePixel = 0
	hullBarFill.Parent = hullBarBg

	if currentHull > 70 then
		hullBarFill.BackgroundColor3 = UIConfig.Colors.Success
	elseif currentHull > 40 then
		hullBarFill.BackgroundColor3 = UIConfig.Colors.Gold
	else
		hullBarFill.BackgroundColor3 = UIConfig.Colors.Danger
	end

	local hullBarCorner = Instance.new("UICorner")
	hullBarCorner.CornerRadius = UDim.new(0, 4)
	hullBarCorner.Parent = hullBarBg

	local repairCost = 0
	if boat then
		repairCost = math.max(0, math.floor(50 + (100 - currentHull) * 2))
	end

	local costLabel = Instance.new("TextLabel")
	costLabel.Size = UDim2.new(1, -20, 0, 22)
	costLabel.Position = UDim2.new(0, 10, 0, 62)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Cost: " .. repairCost .. " Gold"
	costLabel.TextColor3 = UIConfig.Colors.Gold
	costLabel.TextSize = UIConfig.TextSizes.Body
	costLabel.Font = UIConfig.Fonts.Button
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = repairSection

	local repairBtn = Instance.new("TextButton")
	repairBtn.Size = UDim2.new(1, -20, 0, 36)
	repairBtn.Position = UDim2.new(0, 10, 0, 92)
	repairBtn.BackgroundColor3 = currentHull >= 100 and UIConfig.Colors.Muted or UIConfig.Colors.Seafoam
	repairBtn.Text = currentHull >= 100 and "Fully Repaired" or "Repair Boat"
	repairBtn.TextColor3 = UIConfig.Colors.White
	repairBtn.TextSize = UIConfig.TextSizes.Body
	repairBtn.Font = UIConfig.Fonts.Button
	repairBtn.AutoButtonColor = currentHull < 100
	repairBtn.Parent = repairSection

	local repairBtnCorner = Instance.new("UICorner")
	repairBtnCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	repairBtnCorner.Parent = repairBtn

	repairBtn.MouseButton1Click:Connect(function()
		if currentHull >= 100 then return end
		local result = BoatController.RequestRepair()
		if result and result.Success then
			DockUI.Close()
			local UIController = require(player.PlayerScripts.Client.UIController)
			UIController.ShowNotification("Boat repaired!")
		end
	end)

	-- ===== UPGRADE SECTION =====
	local upgradeSection = Instance.new("Frame")
	upgradeSection.Size = UDim2.new(1, -40, 0, 260)
	upgradeSection.Position = UDim2.new(0, 20, 0, 210)
	upgradeSection.BackgroundColor3 = UIConfig.Colors.White
	upgradeSection.BorderSizePixel = 0
	upgradeSection.Parent = container

	local upgradeCorner = Instance.new("UICorner")
	upgradeCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
	upgradeCorner.Parent = upgradeSection

	local upgradeTitle = Instance.new("TextLabel")
	upgradeTitle.Size = UDim2.new(1, -20, 0, 30)
	upgradeTitle.Position = UDim2.new(0, 10, 0, 5)
	upgradeTitle.BackgroundTransparency = 1
	upgradeTitle.Text = "Upgrade Boat"
	upgradeTitle.TextColor3 = UIConfig.Colors.Text
	upgradeTitle.TextSize = UIConfig.TextSizes.Subheader
	upgradeTitle.Font = UIConfig.Fonts.Header
	upgradeTitle.TextXAlignment = Enum.TextXAlignment.Left
	upgradeTitle.Parent = upgradeSection

	local currentBoatId = boat and boat.BoatId or "StarterBoat"
	local boatOrder = {"StarterBoat", "CoastalBoat", "CommercialBoat"}

	for i, boatId in boatOrder do
		local boatDef = BoatDefinitions.GetBoat(boatId)
		if boatDef then
			local isCurrent = boatId == currentBoatId
			local isUnlocked = false
			local canAfford = false

			-- Check if this is the current or already owned
			local currentIdx = table.find(boatOrder, currentBoatId) or 1
			isUnlocked = i <= currentIdx
			canAfford = player:GetAttribute("Gold") and player:GetAttribute("Gold") >= boatDef.Cost

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -20, 0, 70)
			card.Position = UDim2.new(0, 10, 0, 35 + (i - 1) * 75)
			card.BackgroundColor3 = isCurrent and Color3.fromHex("#E8F5E9") or UIConfig.Colors.Background
			card.BorderSizePixel = 0
			card.Parent = upgradeSection

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
			cardCorner.Parent = card

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 0, 22)
			nameLabel.Position = UDim2.new(0, 10, 0, 6)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = boatDef.DisplayName .. (isCurrent and " (Current)" or "")
			nameLabel.TextColor3 = UIConfig.Colors.Text
			nameLabel.TextSize = UIConfig.TextSizes.Body
			nameLabel.Font = UIConfig.Fonts.Header
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = card

			local statsLabel = Instance.new("TextLabel")
			statsLabel.Size = UDim2.new(0.6, 0, 0, 18)
			statsLabel.Position = UDim2.new(0, 10, 0, 28)
			statsLabel.BackgroundTransparency = 1
			statsLabel.Text = "Hull: " .. boatDef.BaseStats.HullHealth .. " | Speed: " .. boatDef.BaseStats.Speed .. " | Cargo: " .. boatDef.BaseStats.CargoCapacity
			statsLabel.TextColor3 = UIConfig.Colors.Muted
			statsLabel.TextSize = UIConfig.TextSizes.Small
			statsLabel.Font = UIConfig.Fonts.Body
			statsLabel.TextXAlignment = Enum.TextXAlignment.Left
			statsLabel.Parent = card

			local costText = boatDef.Cost == 0 and "Free" or boatDef.Cost .. " Gold"
			if boatDef.RequiredProject then
				costText = costText .. " | Requires: " .. boatDef.RequiredProject
			end

			local costInfo = Instance.new("TextLabel")
			costInfo.Size = UDim2.new(0.6, 0, 0, 18)
			costInfo.Position = UDim2.new(0, 10, 0, 48)
			costInfo.BackgroundTransparency = 1
			costInfo.Text = costText
			costInfo.TextColor3 = UIConfig.Colors.Gold
			costInfo.TextSize = UIConfig.TextSizes.Small
			costInfo.Font = UIConfig.Fonts.Body
			costInfo.TextXAlignment = Enum.TextXAlignment.Left
			costInfo.Parent = card

			if not isCurrent then
				local buyBtn = Instance.new("TextButton")
				buyBtn.Size = UDim2.new(0, 100, 0, 32)
				buyBtn.Position = UDim2.new(1, -110, 0.5, -16)
				buyBtn.BackgroundColor3 = isUnlocked and UIConfig.Colors.Seafoam or UIConfig.Colors.Muted
				buyBtn.Text = isUnlocked and "Equip" or "Locked"
				buyBtn.TextColor3 = UIConfig.Colors.White
				buyBtn.TextSize = UIConfig.TextSizes.Small
				buyBtn.Font = UIConfig.Fonts.Button
				buyBtn.AutoButtonColor = isUnlocked
				buyBtn.Parent = card

				local buyBtnCorner = Instance.new("UICorner")
				buyBtnCorner.CornerRadius = UDim.new(0, UIConfig.CornerRadii.SM)
				buyBtnCorner.Parent = buyBtn

				if isUnlocked then
					buyBtn.MouseButton1Click:Connect(function()
						local result = BoatController.RequestUpgrade(boatId)
						if result and result.Success then
							DockUI.Close()
							local UIController = require(player.PlayerScripts.Client.UIController)
							UIController.ShowNotification("Upgraded to " .. boatDef.DisplayName .. "!")
						end
					end)
				end
			end
		end
	end

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(1, -40, 0, 40)
	closeBtn.Position = UDim2.new(0, 20, 1, -50)
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
	DockUI.OpenShipwrightUI()
end

return DockUI
