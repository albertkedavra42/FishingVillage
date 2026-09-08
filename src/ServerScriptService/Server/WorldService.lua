local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldService = {}
WorldService.__index = WorldService

local TIME_PHASES = {
	{ Name = "Morning", Duration = 120 },   -- 2 minutes
	{ Name = "Day", Duration = 300 },        -- 5 minutes
	{ Name = "Evening", Duration = 120 },    -- 2 minutes
	{ Name = "Night", Duration = 240 },      -- 4 minutes
	{ Name = "LateNight", Duration = 120 },  -- 2 minutes
	{ Name = "Dawn", Duration = 60 },        -- 1 minute
}

local DISASTER_TYPES = {
	Typhoon = {
		Name = "Typhoon",
		WarningTime = 30,
		Duration = 120,
		DamagePerSecond = 2,
		FuelDrainMultiplier = 2.0,
		VisibilityMultiplier = 0.3,
		RareOpportunityChance = 0.15,
	},
	Whirlpool = {
		Name = "Whirlpool",
		WarningTime = 10,
		Duration = 30,
		DamagePerSecond = 5,
		PullForce = 50,
		DisplacesPlayer = true,
	},
}

local currentTimeIndex = 1
local timeElapsed = 0
local currentWeather = "Clear"
local activeDisaster: {
	Type: string,
	StartTime: number,
	Duration: number,
	Phase: string,
} | nil = nil
local disasterCooldown = 0

local WORLD_TICK_RATE = 1 -- seconds

function WorldService.Init()
	currentTimeIndex = 1
	timeElapsed = 0
	currentWeather = "Clear"
	activeDisaster = nil
	disasterCooldown = 60 -- first disaster after 60 seconds
end

function WorldService.GetCurrentTimePhase(): string
	return TIME_PHASES[currentTimeIndex].Name
end

function WorldService.GetTimeProgress(): number
	local phase = TIME_PHASES[currentTimeIndex]
	return timeElapsed / phase.Duration
end

function WorldService.GetWeather(): string
	return currentWeather
end

function WorldService.SetWeather(weather: string)
	currentWeather = weather
end

function WorldService.GetActiveDisaster()
	return activeDisaster
end

function WorldService.IsNight(): boolean
	local phase = WorldService.GetCurrentTimePhase()
	return phase == "Night" or phase == "LateNight"
end

function WorldService.IsStormy(): boolean
	return currentWeather == "Storm" or (activeDisaster and activeDisaster.Type == "Typhoon")
end

function WorldService.GetVisibilityMultiplier(): number
	local mult = 1.0

	-- Night reduction
	if WorldService.IsNight() then
		mult = mult * 0.5
	end

	-- Storm reduction
	if WorldService.IsStormy() then
		mult = mult * 0.3
	end

	-- Active disaster
	if activeDisaster then
		local disasterDef = DISASTER_TYPES[activeDisaster.Type]
		if disasterDef and disasterDef.VisibilityMultiplier then
			mult = mult * disasterDef.VisibilityMultiplier
		end
	end

	return math.clamp(mult, 0.1, 1.0)
end

function WorldService.GetDisasterDamage(): number
	if not activeDisaster then
		return 0
	end

	local disasterDef = DISASTER_TYPES[activeDisaster.Type]
	if not disasterDef then
		return 0
	end

	if activeDisaster.Phase == "Peak" then
		return disasterDef.DamagePerSecond * 1.5
	elseif activeDisaster.Phase == "Storm" then
		return disasterDef.DamagePerSecond
	else
		return 0
	end
end

function WorldService.GetFuelDrainMultiplier(): number
	local mult = 1.0

	if activeDisaster and activeDisaster.Type == "Typhoon" then
		local disasterDef = DISASTER_TYPES.Typhoon
		mult = mult * disasterDef.FuelDrainMultiplier
	end

	return mult
end

function WorldService.Update(deltaTime: number)
	-- Update time of day
	timeElapsed = timeElapsed + deltaTime
	local phase = TIME_PHASES[currentTimeIndex]

	if timeElapsed >= phase.Duration then
		timeElapsed = timeElapsed - phase.Duration
		currentTimeIndex = currentTimeIndex + 1

		if currentTimeIndex > #TIME_PHASES then
			currentTimeIndex = 1
		end

		return true -- Phase changed
	end

	-- Update weather randomly
	if math.random() < 0.001 * deltaTime then
		local weathers = { "Clear", "Clear", "Clear", "Overcast", "Overcast", "Rain", "Storm" }
		currentWeather = weathers[math.random(#weathers)]
	end

	-- Update disaster
	if activeDisaster then
		activeDisaster.StartTime = activeDisaster.StartTime + deltaTime
		local disasterDef = DISASTER_TYPES[activeDisaster.Type]

		if activeDisaster.StartTime < disasterDef.WarningTime then
			activeDisaster.Phase = "Warning"
		elseif activeDisaster.StartTime < disasterDef.WarningTime + disasterDef.Duration * 0.3 then
			activeDisaster.Phase = "Storm"
		elseif activeDisaster.StartTime < disasterDef.WarningTime + disasterDef.Duration * 0.7 then
			activeDisaster.Phase = "Peak"
		elseif activeDisaster.StartTime < disasterDef.WarningTime + disasterDef.Duration then
			activeDisaster.Phase = "Recovery"
		else
			-- Disaster ended
			activeDisaster = nil
			disasterCooldown = 180 -- 3 minutes between disasters
			return false
		end
	else
		-- Try to spawn disaster
		disasterCooldown = disasterCooldown - deltaTime
		if disasterCooldown <= 0 then
			WorldService.TrySpawnDisaster()
		end
	end

	return false
end

function WorldService.TrySpawnDisaster()
	-- Check zone risk levels
	local chance = 0.01 -- base chance per tick

	-- Higher chance at night
	if WorldService.IsNight() then
		chance = chance * 2
	end

	-- Higher chance during storm weather
	if currentWeather == "Storm" then
		chance = chance * 3
	end

	if math.random() < chance then
		-- Pick disaster type
		local types = { "Typhoon", "Whirlpool" }
		local disasterType = types[math.random(#types)]

		activeDisaster = {
			Type = disasterType,
			StartTime = 0,
			Duration = DISASTER_TYPES[disasterType].Duration,
			Phase = "Warning",
		}

		return true
	end

	return false
end

function WorldService.GetTimePhaseForFishing(): string
	return WorldService.GetCurrentTimePhase()
end

function WorldService.GetNightBonus(): number
	local phase = WorldService.GetCurrentTimePhase()
	if phase == "Night" then
		return 1.5
	elseif phase == "LateNight" then
		return 2.0
	elseif phase == "Evening" then
		return 1.2
	else
		return 1.0
	end
end

function WorldService.GetWorldState()
	return {
		TimeOfDay = WorldService.GetCurrentTimePhase(),
		TimeProgress = WorldService.GetTimeProgress(),
		Weather = currentWeather,
		Disaster = activeDisaster,
		IsNight = WorldService.IsNight(),
		Visibility = WorldService.GetVisibilityMultiplier(),
	}
end

return WorldService
