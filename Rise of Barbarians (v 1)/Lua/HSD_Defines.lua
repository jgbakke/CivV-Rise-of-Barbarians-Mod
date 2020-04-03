-- Historical Spawn Dates Defines
-- Author: Gedemon
-- DateCreated: 1/29/2011 4:22:38 PM
--------------------------------------------------------------

print("Loading Historical Spawn Dates Defines...")
print("-------------------------------------")

-------------------------------------------------------------------------------------------------------
-- DEBUG Output
-------------------------------------------------------------------------------------------------------
PRINT_DEBUG =			true	-- Dprint Lua output to firetuner ON/OFF
DEBUG_DB_UTILS =		false	-- Dprint Lua output for "get civ for player" functions
DEBUG_PERFORMANCE =		false	-- always show loading/save time of tables

-------------------------------------------------------------------------------------------------------
-- Initialize for SaveUtils
-------------------------------------------------------------------------------------------------------
WARN_NOT_SHARED = false
include( "ShareData.lua" )
include( "SaveUtils" )
MY_MOD_NAME = "684731c5-4837-427d-9378-0c58e1201325"

DEFAULT_SAVE_KEY =			"0,0"	-- default plot for saveutils




--------------------------------------------------------------
-- player ID
--------------------------------------------------------------

LOCAL_PLAYER = Game.GetActivePlayer()
BARBARIAN_PLAYER = GameDefines.MAX_PLAYERS-1

--------------------------------------------------------------
-- Units
--------------------------------------------------------------

WAIT =			GameInfo.Units.UNIT_WAIT.ID
SETTLER =		GameInfo.Units.UNIT_SETTLER.ID
ENGINEER =		GameInfo.Units.UNIT_ENGINEER.ID
WORKER =		GameInfo.Units.UNIT_WORKER.ID
WARRIOR =		GameInfo.Units.UNIT_WARRIOR.ID
ARCHER =		GameInfo.Units.UNIT_ARCHER.ID
SPEARMAN =		GameInfo.Units.UNIT_SPEARMAN.ID
BOWMAN =		GameInfo.Units.UNIT_COMPOSITE_BOWMAN.ID
PIKEMAN =		GameInfo.Units.UNIT_PIKEMAN.ID
MUSKETMAN =		GameInfo.Units.UNIT_MUSKETMAN.ID
RIFLEMAN =		GameInfo.Units.UNIT_RIFLEMAN.ID
INFANTRY =		GameInfo.Units.UNIT_INFANTRY.ID
PARATROOPER =	GameInfo.Units.UNIT_PARATROOPER.ID
MECHANIZED =	GameInfo.Units.UNIT_MECHANIZED_INFANTRY.ID

ANCIENT =		0
CLASSICAL =		1
MEDIEVAL =		2
RENAISSANCE =	3
INDUSTRIAL =	4
MODERN =		5
POST_MODERN =	6
FUTURE =		7

g_SpawnList = { 
	[ANCIENT] =		{ WARRIOR },
	[CLASSICAL] =	{ ARCHER, WARRIOR, SPEARMAN, WORKER},
	[MEDIEVAL] =	{ BOWMAN, SETTLER, PIKEMAN, PIKEMAN, WORKER},
	[RENAISSANCE] = { MUSKETMAN, MUSKETMAN, MUSKETMAN, SETTLER, WORKER},
	[INDUSTRIAL] =	{ RIFLEMAN, RIFLEMAN, SETTLER, SETTLER, WORKER, WORKER},
	[MODERN] =		{ INFANTRY, INFANTRY, SETTLER, SETTLER, WORKER, WORKER},
	[POST_MODERN] =	{ PARATROOPER, SETTLER, MECHANIZED, WORKER, WORKER, SETTLER, SETTLER},
	[FUTURE] =		{ MECHANIZED, MECHANIZED, MECHANIZED, WORKER, WORKER, SETTLER, SETTLER, SETTLER },
}

--------------------------------------------------------------
-- Globals
--------------------------------------------------------------

g_bPlayerHibernate = false

g_Techs =		0
g_Science =		0
g_Hammer =		0
g_Policies =	0
g_Culture =		0
g_Faith =		0
g_Gold =		0
g_GoldAge =		0
g_LandCulture =	0
g_Population =	0
g_Era =			0
g_KnownTech =	{}

g_PreviousOverflowResearch = {}


USE_ESTIMATED_BALANCE =			true -- will give bonus to new civ based on the advancement of other civs
USE_FIXED_BALANCE =				true -- will give bonus to new civ based on bonus table

HUMAN_USE_BONUS_TECHS =			false -- if true, the human player can chose all bonus techs at once (based on average number of techs of other civs), else he gets 1 tech per turn with bakers overflow (based on average bakers of all techs from other civs).
USE_FREE_POLICIES_BONUS =		false -- if true, the player can choose free policies based on the average number of policies per civilizations. That give a big advantage to late civilization, that will get new policies faster (next policy cost does not raise for free policies), else the player get a value of culture based on next policy cost for all civs.

MINIMUM_YEAR_FOR_CULTURE_VICTORY =		1500 -- No culture victory before this year 
MINIMUM_YEAR_FOR_DOMINATION_VICTORY =	1200 -- No domination victory before this year 
MINIMUM_YEAR_FOR_DIPLOMATIC_VICTORY =	1700 -- No diplomatic victory before this year 

ELAPSED_TURNS_FOR_BALANCE =			2 -- Before this number of turns ingame, no balance mechanism is applied
ALLOW_BARBARIAN_CONVERTION =		true -- Convert all barbarians units in range = CONVERT_BARBARIAN_RANGE * (era+1*CONVERT_ERA_RANGE_MOD/100)
CONVERT_BARBARIAN_RANGE =			4 
CONVERT_ERA_RANGE_MOD =				45 
ALLOW_CITY_STATES_CONVERTION =		true -- Convert all city-states units and remove city-states territory in range = CONVERT_CITY_STATES_RANGE
CONVERT_CITY_STATES_RANGE =			4
ALLOW_CITY_STATES_ALLY =			false -- Give allied influence on city-states in range = ALLY_CITY_STATES_RANGE
ALLY_CITY_STATES_RANGE =			8
CITY_STATES_INFLUENCE_BONUS =		25 -- Bonus added to the allied influence when using ALLOW_CITY_STATES_ALLY
MINOR_RANGE_PERCENT =				100 -- percentage of normal range used for new minor civilization balance

BALANCE_FAITH_FACTOR =			15 -- 
BALANCE_GOLD_FACTOR =			15 --
BALANCE_HAMMER_COST_PGP =		1000 -- hammer cost of each Great People
BALANCE_MAX_GP =				5 -- max Great people converted from hammer
MINIMUM_DISTANCE_FOR_CS =		2 -- Minimum distance of another player territory for a CS to spawn...
INITIAL_CITY_FOOD_PERCENT =		75 -- percentage of food stored in initial city

MINIMUM_DISTANCE_FOR_MAJOR =	2 -- Minimum distance of another player territory for a Major Civ to spawn it's initial city on the exact starting location

MAX_NUM_STARTING_UNITS =		6 -- num columns for starting units in Civilization_HistoricalSpawnDates table. /!\ You'll have to edit the table if you want to raise that number, else you'll get an error. /!\