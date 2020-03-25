-- BarbariansEvolved
-- Author: Charsi
-- DateCreated: 01/28/2016 10:45:45 PM
--------------------------------------------------------------

print("Loading settings from file BEsetVanilla...")

-- End-User Customizable Settings

bConservativeMode = false

iBaseTurnsPerBarbEvolution = 20

bRagingBarbarians = false

bDisableBarbHealing = false

bDisableBarbSpawn = false

bDisableBarbSpawnForAlly = false

bDisableBarbSpawnForMe = true

bDisableSponsoredSpawns = false

iSpawnChance = 4

bDisableBarbEvolution = false

bBarbEvolveSettlers = false

bBarbEvolveCityStates = false

bDisableBarbCapture = false

bRequireMeleeCapture = false

bDisableGlobalUpgrade = false

bDisableGlobalUpgradeForMe = true

sBarbLiberateTo = "CIVILIZATION_BARBARIAN"

bBarbDisperseOnLiberate = true

sBarbMajorAlly = "CIVILIZATION_BARBARIAN_MAJOR"

arrBarbLandUnitPromotions = {"PROMOTION_RIVAL_TERRITORY"}

arrBarbSeaUnitPromotions = {"PROMOTION_RIVAL_TERRITORY"}

arrBarbAirUnitPromotions = {}

bBarbEraNameChange = true

bDeferNameChange = false

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