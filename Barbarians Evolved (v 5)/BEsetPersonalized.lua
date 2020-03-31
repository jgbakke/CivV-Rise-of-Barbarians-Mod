-- BarbariansEvolved
-- Author: Charsi
-- DateCreated: 01/28/2016 10:45:45 PM
--------------------------------------------------------------

print("Loading settings from file BEsetPersonalized...")

-- End-User Customizable Settings
-- Valid values for booleans are the strings "true" and "false", no quotes.

-- A number of mods (particularly DLL mods) can't handle Barbarians owning things like cities.
-- If you encounter crashes you can:
-- 1. Set an ALLY, so Barbarians don't own the spoils of war.
-- 2. Enable Conservative Mode.
-- 3. Disable SPAWN, EVOLUTION, CAPTURE and UPGRADE, so Barbarians don't own the spoils of war.
-- If you went with option 3, try turning stuff back on one at a time.
-- If neither option works, report the crash in Steam Workshop.

-- SHOULD THE MOD ACT CONSERVATIVELY?
--
-- What this means is, if the civ identified in sBarbMajorAlly isn't actually in the game, switch to
-- a conservative game mode.
-- If this option is TRUE, the following boolean values will all be overridden to false:
-- bDisableBarbSpawn, bDisableBarbEvolution, bDisableBarbCapture, bDisableGlobalUpgrade
-- 26-FEB-2016: DEPRECATED.  This value is now completely ignored.
bConservativeMode = false

-- HOW OFTEN DO BARBARIANS EVOLVE?
--
-- The number of turns between camp evolutions.  This is multiplied by gamespeed.
-- Quick = 1x, Standard = 2x, Epic/Marathon = 3x, other = 2x.  Doubled if bRagingBarbarians is true.
iBaseTurnsPerBarbEvolution = 20

-- RAGING BARBARIANS?
--
-- Because setup value detection wasn't working right, this option exists to emulate whether you play
-- with Raging Barbarians on or not. This option has two important effects.
-- If this option is TRUE, the evolution turn timer is HALVED.
-- If this option is TRUE, the spawn chance in cities is DOUBLED.
bRagingBarbarians = false

-- DO BARBARIANS HEAL IN CAMPS?
--
-- Barbarians (63) heal 10hp per turn in their own territory or a encampment.
-- If this option is TRUE, healing is disabled.  Some mods add their own healing.
bDisableBarbHealing = false

-- DO BARBARIANS SPAWN UNITS IN CITIES?
--
-- Barbarians (63) need a little help spawning units in cities they own.
-- If this option is TRUE, they won't.  Turn on when some DLL mod handles defensive spawns, like City-State Diplomacy.
bDisableBarbSpawn = false

-- Disable the Barbarian garrison spawn for Barbarian Major Civ, but not for cities owned by the Barbarian tribes (63).
bDisableBarbSpawnForAlly = false

-- This option controls whether garrisons spawn when the human player IS the Barbarian Major Civ.
-- If this option is TRUE, you have to look after yourself - no freebies.
bDisableBarbSpawnForMe = true

-- This option controls whether sponsored encampments spawn units.
-- If this option is TRUE, sponsored encampments can still be built, but will never spawn anything.
bDisableSponsoredSpawns = false

-- Spawn chance (1-10, each number = 10%).  Doubled if bRagingBarbarians is true.  Doubled again if city has taken damage.
-- Default = Game Difficulty (Settler = 0, and so on to Deity = 7).
iSpawnChance = 4

-- DO BARBARIANS SPAWN CITIES?
--
-- Barbarians evolve encampments into cities.
-- If this option is TRUE, Barbarian camps will NEVER evolve.  Some mods crash if Barbarians hold cities.
bDisableBarbEvolution = true

-- Barbarians either evolve cities instantly on a tile, or pop settlers on the tile with orders to found a city.
-- If this option is TRUE, Barbarians will pop settlers.  False means they pop cities instantly.  Some mods crash if cities are popped instantly.
bBarbEvolveSettlers = false

-- Barbarians can now (as of v5) evolve into City States.  Should they do this?
-- If you set this to true, you should probably disable city capture, make the ally invalid and do not play as Barbarians.
bBarbEvolveCityStates = false

-- DO BARBARIANS CAPTURE CITIES?
--
-- Barbarian priorities have been changed so they attack cities.
-- They're kinda dumb though and need code help to accomplish capture.
-- If this option is TRUE, the capture code is turned OFF.  Some mods crash if Barbarians capture cities.
bDisableBarbCapture = false

-- DO BARBARIANS REQUIRE A MELEE UNIT TO CAPTURE CITIES?
--
-- The capture routine works by checking if a COMBAT unit is nearby when the city is low on health.
-- Some people thought it was unfair that they could cap with ranged units.
-- If this option is TRUE, the check requires a MELEE unit instead.  Meaningless if bDisableBarbCapture is true.
bRequireMeleeCapture = true

-- DO BARBARIANS UPGRADE UNITS?
--
-- Every turn any two obsolete Barbarian (63) units in existence are deleted in favor of one technologically relevant one.
-- This could be an option your computer can't handle.  Or maybe you can't handle swarms of laggy outdated units.  Pick your poison.
-- If this option is TRUE, the upgrade pass is SKIPPED.
bDisableGlobalUpgrade = true

-- This option controls whether Barbarian units upgraed when the human player IS the Barbarian Major Civ.
-- If this option is TRUE, you have to look after yourself -- no freebies.
bDisableGlobalUpgradeForMe = true

-- DO BARBARIAN CITIES LIBERATE TO ANYONE?
--
-- When Barbarians evolve a city, they can optionally evolve the city to a civilization other than themselves and immediately annex it.
-- This allows the city to be "liberated" later, ostensibly back to the original civilization, so you can dodge the warmonger bonus.
-- The owner civ (or mod, if it's a mod civ) must handle what happens when the city is liberated back.
-- This parameter is a string whose owner MUST exist and be in your game.  If it does not, evolved camps will not be able to be liberated.
-- By default this is CIVILIZATION_BARBARIAN, which is the tribal barbarians.
sBarbLiberateTo = "CIVILIZATION_BARBARIAN"
-- Leave this alone unless you know what you want to change it to.
-- If you have defined a "Major Ally" (see below) this is more or less irrelevant, because that civ will be on everyone's hit list.

-- DISPERSE ALL LIBERATED CIV CITIES?
--
-- Each turn, any cities belonging to the Liberation civ are dispersed.  If you intend for them to play on, change this value.
-- If this option is FALSE, the dispersal loop is SKIPPED.  Meaningless if the civ named in sBarbLiberateTo is not valid.
bBarbDisperseOnLiberate = true

-- ARE THE BARBARIANS SUBSERVIENT TO A GREATER POWER?
--
-- When Barbarians evolve OR capture a city, they can optionally pledge that city to a civilization other than themselves.
-- This allows for some major civilization to benefit from the spoils of Barbarian conquests.
-- This also means the Barbarians (63) will never own cities, thus never trigger a game crash.  Hopefully.
-- This is best used if you want some other civilization to play the role of "Barbarian conquerers".
-- Examples might be the Mongols, the Huns, Hiram's Khanate mods (mod), The Bucaneers (mod), JFD's Germans (mod) or something else.
-- Note: if you do this, and have evolution on, the Barbarians will GIVE them a city every x turns!
--
-- This parameter is a string whose owner MUST exist and be in your game.  If it does not, Barbarians will keep spoils for themselves.
-- By default this is CIVILIZATION_BARBARIAN_MAJOR.
-- If you go with the default you MUST place this civ in a slot using the Advanced Setup Screen.  It won't random in for an AI.
-- Choosing the default (and only the default) will cause a permanent declaration of war on everyone on turn 1.
-- The Barbarians will make eternal peace with the specified civ on turn 1.  The mod civ must handle everything else.
sBarbMajorAlly = "CIVILIZATION_BARBARIAN_MAJOR"
-- Oh, and don't put more than one instance of the above civ in-game.  It won't work very well, if at all.

-- WHAT PROMOTIONS DO WE WANT BARBARIANS TO HAVE?
--
-- An array of strings listing promotions.  All LAND units owned by both the Barbs AND their ally will get these.
-- Some promotions may crash the game; use at your own risk.
-- If you give hovering you must give embarkation or you will have Jesus Barbarians that walk on water.
-- Example LAND promotions from White Walkers: PROMOTION_PRIZE_SHIPS, PROMOTION_FASTER_HEAL, PROMOTION_PARTIAL_HEAL_IF_DESTROY_ENEMY
-- Default promotions allow (respectively): Embarkation, Barbarians can enter Major Ally territory, Barbarians can cross Mountains, Ice and Ignores Terrain Cost.
-- Make this an empty array if you want to nerf them.
--
-- applied to units with DOMAIN_LAND
arrBarbLandUnitPromotions = {}

-- applied to units with DOMAIN_SEA
arrBarbSeaUnitPromotions = {}

-- applied to units with DOMAIN_AIR
arrBarbAirUnitPromotions = {}

-- DO BARBARIANS CHANGE NAMES AS THE ERAS PASS?
--
-- Barbarians can, and this is supported in the mod code.  Default is false because i've seen crashes around turn 100.
-- You might want to turn this off if you're using the White Walkers OR change the list to have a zombie theme.
-- If this option is FALSE, the name change code is SKIPPED and they keep whatever their initially configured strings are.
bBarbEraNameChange = false

-- DO WE DEFER UPDATING BARBARIAN NAMES?
--
-- For performance reasons you can defer the actual name change until the start of the Barbarians' turn.
-- If this option is TRUE, the name change code is DEFERRED.
-- Meaningless if bBarbEraNameChange is false.
bDeferNameChange = false

-- WHAT DO WE CALL BARBARIANS?
--
-- Used if bBarbEraNameChange is set to false
sBarbAdjDefault = "Barbarian"

sBarbDescrDefault = "Barbarian"

sBarbShortDefault = "Barbarians"

sBarbCampDefault = "Encampment"

-- WHAT DO WE CALL BARBARIANS AS THE ERAS PASS?
--
-- Barbarians can change names as the eras pass.  This is an array.  The format is:
-- ERA_NAME, ADJECTIVE, DESCRIPTION, SHORT_DESCRIPTION, CAMP_DESCRIPTION
-- You must define one row for EVERY era in the Eras table and they MUST be ordered chronologically.
-- Meaningless if bBarbEraNameChange is false.
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

-- DO WE ALLOW STATE SPONSORED BARBARIAN CAMPS?
--
-- State-Sponsored Encampments may be built which spawn barbarians.  Do we allow this to happen?
-- If TRUE, the building of such camps is disabled...
--
-- For everyone, including Barbarians:
bDisableBuildingEncampmentsForAll = false

-- For non-Barbarian players:
bDisableBuildingEncampmentsForOthers = true

-- change this to your language locale.  Your options are:
-- language_en_US, language_DE_DE, language_ES_ES, language_FR_FR, language_IT_IT, language_JA_JP, language_KO_KR, language_PL_PL, language_RU_RU, language_ZH_HANT_NK
sLanguageTable = "language_" .. Locale.GetCurrentLanguage().Type

-- WHAT LIMITS ARE PLACED ON WORKERS AND INFILTRATORS?
--
-- Make these really high numbers to effectively remove the limit.
-- Default is 2 and 4, respectively.
--
-- UNIT_DIRTY_BOMB
iBarbNukeLimit = 2

-- UNIT_BARBARIAN_WORKER
iBarbWorkerLimit = 4

-- DO WE OVERRIDE BARBARIAN COLORS?
--
-- Allows you to set icon/background colors without XML editing.
-- If you like you can change this to some other predefined PLAYERCOLOR_* string.

sMinorPlayerColor = "PLAYERCOLOR_BLACK"

sMajorPlayerColor = "PLAYERCOLOR_BLACK"

-- newer params
-- these are used in the setup screen only, except for bBarbEvolveCityStates.  You probably shouldn't mess with these, ever.
bBarbMajorAllyExists = true

bBarbMajorAllyAsMe = false

bBarbEvolveCityStates = false