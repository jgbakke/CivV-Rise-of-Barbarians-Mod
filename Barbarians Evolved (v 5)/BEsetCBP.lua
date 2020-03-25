-- BarbariansEvolved
-- Author: Charsi
-- DateCreated: 01/28/2016 10:45:45 PM
--------------------------------------------------------------

print("Loading settings from file BEsetCBP...")

-- End-User Customizable Settings

bConservativeMode = false

iBaseTurnsPerBarbEvolution = 20

bRagingBarbarians = false

-- CBP heals Barbs, so disable
bDisableBarbHealing = true

bDisableBarbSpawn = false

-- CBP damages cities if Tribal Barbs are nearby, so disable
bDisableBarbSpawnForAlly = true

bDisableBarbSpawnForMe = true

bDisableSponsoredSpawns = false

iSpawnChance = 4

bDisableBarbEvolution = false

-- CBP does not like the player:Found() method
bBarbEvolveSettlers = false

bBarbEvolveCityStates = false

-- CBP changes allow Barbarians to capture cities properly, so disable
bDisableBarbCapture = true

bRequireMeleeCapture = false

bDisableGlobalUpgrade = false

bDisableGlobalUpgradeForMe = true

-- in CBP, the tribal Barbarians can capture cities; to avoid mass confusion dont make them the liberation civ
sBarbLiberateTo = "CIVILIZATION_INTENTIONALLY_INVALID"

bBarbDisperseOnLiberate = true

sBarbMajorAlly = "CIVILIZATION_BARBARIAN_MAJOR"

arrBarbLandUnitPromotions = {"PROMOTION_RIVAL_TERRITORY"}

arrBarbSeaUnitPromotions = {"PROMOTION_RIVAL_TERRITORY"}

arrBarbAirUnitPromotions = {}

bBarbEraNameChange = true

-- reduce workload of CBP turns by deferring name change
bDeferNameChange = true

sBarbAdjDefault = "Barbarian"

sBarbDescrDefault = "Barbarian"

sBarbShortDefault = "Barbarians"

sBarbCampDefault = "Encampment"

arrBarbNames = {}

arrEra = {"ERA_ANCIENT", "Barbarian", "Barbarism", "Barbarians", "Encampment"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_CLASSICAL", "Raider", "Barbarism", "Raiders", "Encampment"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_MEDIEVAL", "Criminal", "the Lawless", "Criminals", "Hideout"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_RENAISSANCE", "Pirate", "the Lawless", "Pirates", "Hideout"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_INDUSTRIAL", "Rebel", "the Rebellion", "Rebels", "Base"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_MODERN", "Insurgent", "the Insurgency", "Insurgents", "Base"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_POSTMODERN", "Terrorist", "Anarchy", "Terrorists", "Training Camp"}
table.insert(arrBarbNames, arrEra)

arrEra = {"ERA_FUTURE", "Terrorist", "Anarchy", "Terrorists", "Training Camp"}
table.insert(arrBarbNames, arrEra)

bDisableBuildingEncampmentsForAll = false

bDisableBuildingEncampmentsForOthers = false

sLanguageTable = "language_" .. Locale.GetCurrentLanguage().Type

iBarbNukeLimit = 2

iBarbWorkerLimit = 4

sMinorPlayerColor = "PLAYERCOLOR_BARBARIAN"

sMajorPlayerColor = "PLAYERCOLOR_BARBARIAN_MAJOR"

-- newer params
bBarbMajorAllyExists = true

bBarbMajorAllyAsMe = false

bBarbEvolveCityStates = false