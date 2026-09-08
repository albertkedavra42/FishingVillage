local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local BoatService = require(ServerScriptService.Server.BoatService)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BoatDefinitions = require(ReplicatedStorage.Shared.Config.BoatDefinitions)

local DockInteraction = {}
DockInteraction.__index = DockInteraction

local playerStates: { [number]: {
	IsAtDock: boolean,
	IsInBoat: boolean,
	IsInVillage: boolean,
	CurrentZone: string?,
} } = {}

function DockInteraction.Init()
	Players.PlayerAdded:Connect(function(player)
		playerStates[player.UserId] = {
			IsAtDock = true,
			IsInBoat = false,
			IsInVillage = true,
			CurrentZone = nil,
		}
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerStates[player.UserId] = nil
	end)
end

function DockInteraction.GetState(player: Player)
	return playerStates[player.UserId]
end

function DockInteraction.SpawnPlayerAtDock(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local VillageMap = require(ReplicatedStorage.Shared.Config.VillageMap)
	rootPart.CFrame = CFrame.new(VillageMap.SpawnPoint)
end

function DockInteraction.SpawnBoatAtDock(player: Player): (boolean, string?)
	local state = playerStates[player.UserId]
	if not state then
		return false, "Invalid state"
	end

	if state.IsInBoat then
		return false, "Already in boat"
	end

	local VillageMap = require(ReplicatedStorage.Shared.Config.VillageMap)
	local profile = PlayerDataService.GetProfile(player)
	if not profile then
		return false, "No profile"
	end

	local boatDef = BoatDefinitions.GetBoat(profile.Boat.BoatId)
	if not boatDef then
		return false, "Invalid boat"
	end

	local spawnPos = VillageMap.GetBoatSpawnPosition()

	local success, boatData = BoatService.SpawnBoat(player, profile.Boat.BoatId)
	if success then
		-- Create the boat model in workspace
		DockInteraction.CreateBoatModel(player, spawnPos, boatData)
		state.IsAtDock = false
		return true, nil
	end

	return false, "Failed to spawn boat"
end

function DockInteraction.CreateBoatModel(player: Player, position: Vector3, boatData)
	local existingModel = workspace:FindFirstChild("Boat_" .. player.UserId)
	if existingModel then
		existingModel:Destroy()
	end

	local boatDef = BoatDefinitions.GetBoat(boatData.BoatId)
	local scale = boatDef and boatDef.Visual.Scale or 1.0

	local model = Instance.new("Model")
	model.Name = "Boat_" .. player.UserId

	-- Hull
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(6 * scale, 2, 12 * scale)
	hull.Position = position
	hull.Anchored = true
	hull.CanCollide = true
	hull.Color = Color3.fromHex("#8B4513")
	hull.Material = Enum.Material.Wood
	hull.Parent = model

	-- Deck
	local deck = Instance.new("Part")
	deck.Name = "Deck"
	deck.Size = Vector3.new(5 * scale, 0.5, 10 * scale)
	deck.Position = position + Vector3.new(0, 1.25, 0)
	deck.Anchored = true
	deck.CanCollide = true
	deck.Color = Color3.fromHex("#DEB887")
	deck.Material = Enum.Material.Wood
	deck.Parent = model

	-- Cabin
	local cabin = Instance.new("Part")
	cabin.Name = "Cabin"
	cabin.Size = Vector3.new(3 * scale, 2.5, 3 * scale)
	cabin.Position = position + Vector3.new(0, 2.5, -2 * scale)
	cabin.Anchored = true
	cabin.CanCollide = true
	cabin.Color = Color3.fromHex("#F5F5DC")
	cabin.Material = Enum.Material.SmoothPlastic
	cabin.Parent = model

	-- Cargo crates
	local crateCount = boatDef and boatDef.Visual.CargoCrates or 2
	for i = 1, math.min(crateCount, 4) do
		local crate = Instance.new("Part")
		crate.Name = "Crate_" .. i
		crate.Size = Vector3.new(1.5, 1.5, 1.5)
		crate.Position = position + Vector3.new(-1.5 + (i % 2) * 3, 1.75, 1 + math.floor(i / 2) * 2)
		crate.Anchored = true
		crate.CanCollide = true
		crate.Color = Color3.fromHex("#A0522D")
		crate.Material = Enum.Material.Wood
		crate.Parent = model
	end

	-- Floodlight (if boat has one)
	if boatDef and boatDef.Visual.HasFloodlight then
		local light = Instance.new("Part")
		light.Name = "Floodlight"
		light.Size = Vector3.new(1, 1, 1)
		light.Shape = Enum.PartType.Cylinder
		light.Position = position + Vector3.new(0, 4, -3 * scale)
		light.Anchored = true
		light.CanCollide = false
		light.Color = Color3.fromHex("#FFFF00")
		light.Material = Enum.Material.Neon
		light.Parent = model

		local pointLight = Instance.new("PointLight")
		pointLight.Brightness = 2
		pointLight.Range = 30 * scale
		pointLight.Parent = light
	end

	-- Seat for player
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.5, 2)
	seat.Position = position + Vector3.new(0, 1.75, -1 * scale)
	seat.Anchored = true
	seat.CanCollide = true
	seat.Parent = model

	-- Spawn platform (invisible)
	local platform = Instance.new("Part")
	platform.Name = "SpawnPlatform"
	platform.Size = Vector3.new(8 * scale, 0.5, 14 * scale)
	platform.Position = position + Vector3.new(0, -0.75, 0)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Transparency = 1
	platform.Parent = model

	model.PrimaryPart = hull
	model.Parent = workspace

	return model
end

function DockInteraction.EnterBoat(player: Player): boolean
	local state = playerStates[player.UserId]
	if not state or not state.IsAtDock then
		return false
	end

	local success = BoatService.EnterBoat(player)
	if success then
		state.IsInBoat = true
		state.IsAtDock = false
		state.IsInVillage = false

		-- Teleport player to boat
		local boatModel = workspace:FindFirstChild("Boat_" .. player.UserId)
		if boatModel then
			local seat = boatModel:FindFirstChild("DriverSeat")
			if seat then
				local character = player.Character
				if character then
					local rootPart = character:FindFirstChild("HumanoidRootPart")
					if rootPart then
						rootPart.CFrame = seat.CFrame + Vector3.new(0, 3, 0)
					end
				end
			end
		end

		-- Fire client to enter driving mode
		local s2c = Remotes.GetServerToClient()
		s2c.BoatSpawned:FireClient(player, BoatService.GetBoat(player))
	end

	return success
end

function DockInteraction.ExitBoat(player: Player): boolean
	local state = playerStates[player.UserId]
	if not state or not state.IsInBoat then
		return false
	end

	-- Despawn the boat model
	local boatModel = workspace:FindFirstChild("Boat_" .. player.UserId)
	if boatModel then
		boatModel:Destroy()
	end

	BoatService.DespawnBoat(player)
	BoatService.ExitBoat(player)

	state.IsInBoat = false
	state.IsAtDock = true
	state.IsInVillage = true

	-- Teleport player back to dock
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local VillageMap = require(ReplicatedStorage.Shared.Config.VillageMap)
			rootPart.CFrame = CFrame.new(VillageMap.Dock.Position + Vector3.new(0, 3, -5))
		end
	end

	return true
end

function DockInteraction.UpdateBoatPosition(player: Player, position: Vector3, orientation: Vector3)
	local boatModel = workspace:FindFirstChild("Boat_" .. player.UserId)
	if not boatModel then
		return
	end

	local hull = boatModel:FindFirstChild("Hull")
	if hull then
		hull.Position = position
		hull.Orientation = orientation
	end

	-- Update all child parts to follow
	for _, part in boatModel:GetChildren() do
		if part:IsA("BasePart") and part ~= hull then
			local offset = part.Position - hull.Position
			part.CFrame = CFrame.new(position + offset) * CFrame.Angles(
				math.rad(orientation.X),
				math.rad(orientation.Y),
				math.rad(orientation.Z)
			)
		end
	end
end

return DockInteraction
