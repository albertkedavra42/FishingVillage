# Multiplayer Fishing Village

A multiplayer fishing village game built on Roblox.

## Project Structure

```
FishingVillage/
├── src/
│   ├── ReplicatedStorage/Shared/
│   │   ├── Config/           # Data definitions
│   │   │   ├── FishDefinitions.lua
│   │   │   ├── BoatDefinitions.lua
│   │   │   ├── ZoneDefinitions.lua
│   │   │   ├── ItemDefinitions.lua
│   │   │   └── UIConfig.lua
│   │   └── Remotes.lua       # RemoteEvent/Function registry
│   ├── ServerScriptService/Server/
│   │   ├── Init.server.lua   # Server entry point
│   │   ├── PlayerDataService.lua
│   │   ├── EconomyService.lua
│   │   ├── FishingService.lua
│   │   ├── CargoService.lua
│   │   ├── BoatService.lua
│   │   └── WorldService.lua
│   └── StarterPlayer/StarterPlayerScripts/Client/
│       ├── UIController.lua
│       ├── FishingController.lua
│       ├── BoatController.lua
│       └── CameraController.lua
└── default.project.json      # Rojo project file
```

## Development

### Prerequisites

- [Rojo](https://rojo.space/) for syncing code to Roblox Studio
- Roblox Studio

### Setup

1. Install Rojo
2. Run `rojo serve` in the project directory
3. Connect from Roblox Studio using the Rojo plugin

### Debug Commands

Use chat commands in-game for debugging:

- `/setpopulation [zone] [species] [value]`
- `/getpopulation [zone] [species]`
- `/resetpopulation [zone]`
- `/setweather [weather]`
- `/damageboat [amount]`
- `/repairboat`
- `/addgold [amount]`
- `/addsalvage [amount]`

## MVP Systems

- 3 boats (Starter, Coastal, Commercial)
- 3 zones (Shallows, Estuary, Open Sea)
- 14 fish species across 4 rarity tiers
- Rod and Net fishing methods
- Grid-based cargo system
- Dynamic fish populations
- Day/night cycle
- NPC market with dynamic pricing
- Boat damage and repair
- Village projects (Lighthouse, Shipyard, Harbor Expansion)
- Player fish stalls
- Smokehouse processing
- Museum collection
- Typhoon and Whirlpool disasters
