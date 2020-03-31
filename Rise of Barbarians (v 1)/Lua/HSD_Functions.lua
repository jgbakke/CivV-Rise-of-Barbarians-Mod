-- Historical Spawn Dates  Functions
-- Author: Gedemon
-- DateCreated: 3/11/2012 2:02:42 AM
--------------------------------------------------------------
include("HSD_Debug")
include ("PlotIterators") -- by whoward69
print("Loading Historical Spawn Dates Functions...")
print("-------------------------------------")

-----------------------------------------
-- Civilisations functions
-----------------------------------------
function CreateCivHibernatingTable()
	local civHibernating = {}
	for i = 0, GameDefines.MAX_PLAYERS-1 do
		civHibernating[i] = false
	end
	return civHibernating
end
function LoadCivHibernating()
	--local pPlayer = Players[LOCAL_PLAYER]
	local civHibernating = LoadData("CivHibernating", CreateCivHibernatingTable() )
	return civHibernating
end
function SaveCivHibernating( civHibernating )
	--local pPlayer = Players[LOCAL_PLAYER]
	SaveData( "CivHibernating", civHibernating )
end
 

-- remove units of civs starting after turn 0, and set auto-turn on for the player if needed
function Hibernate ()

	Dprint("-------------------------------------")
	Dprint ("Who need to sleep ?") 	

	local civHibernating = LoadCivHibernating()

	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do	
		local player = Players[iPlayer] 
		local civType = GetCivTypeFromiPlayer (iPlayer)
		
		-- need to check if the table entry exist before comparing, else the script will crash
		if civType and player:GetNumUnits() > 0 and GameInfo.Civilization_HistoricalSpawnDates[civType] and ( GameInfo.Civilization_HistoricalSpawnDates[civType].StartYear > Game.GetGameTurnYear() ) then 
			if ( player:IsHuman() ) then
				-- create a waiting unit
				local WaitPlot = GetPlot(0,0) -- need to change that...
				local unit = player:InitUnit(WAIT, WaitPlot.X, WaitPlot.Y)

				-- kill all units except the waiting unit
				for v in player:Units() do
					if not (v:GetUnitType() == WAIT) then
						v:Kill(true, -1)
					end
				end

				-- set auto-turn ON
				SetHibernateState()

			else
				-- kill all units for an AI civ
				for v in player:Units() do
					v:Kill(true, -1)
				end
			end
			Dprint ("- Set hibernation for " .. civType) 
			civHibernating[iPlayer] = true
		elseif civType then	
			Dprint ("- No hibernation for " .. civType)  
		else
			Dprint ("WARNING : can't find CivType for iPlayer = " .. iPlayer) 		
		end

	end

	-- Minor Civs
	for iPlayer = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do	
		local player = Players[iPlayer] 
		local civType = GetCivTypeFromiPlayer (iPlayer)
		
		-- need to check if the table entry exist before comparing, else the script will crash
		if civType and player:GetNumUnits() > 0  and GameInfo.Civilization_HistoricalSpawnDates[civType] and ( GameInfo.Civilization_HistoricalSpawnDates[civType].StartYear > Game.GetGameTurnYear() ) then 
			-- kill all units for this CS
			for v in player:Units() do
				v:Kill(true, -1)
			end
			Dprint ("- Set hibernation for " .. civType) 
			civHibernating[iPlayer] = true
		elseif civType then	
			Dprint ("- No hibernation for " .. civType) 
		else
			Dprint ("WARNING : can't find CivType for (minor) iPlayer = " .. iPlayer) 		
		end
	end

	SaveCivHibernating( civHibernating )
end

-- check if the game need to go on auto-turn when re-loading
function HibernateOnLoading ()
	local civType = GetCivTypeFromiPlayer ( Game.GetActivePlayer() )
	if GameInfo.Civilization_HistoricalSpawnDates[civType] and ( GameInfo.Civilization_HistoricalSpawnDates[civType].StartYear > Game.GetGameTurnYear() ) then 
		SetHibernateState()
	end
end

function SetHibernateState()
	g_bPlayerHibernate = true
	local initialAutoEndTurnOption = "true" -- no boolean for save modding data, use string
	if not OptionsManager.GetSinglePlayerAutoEndTurnEnabled_Cached() then
		OptionsManager.SetSinglePlayerAutoEndTurnEnabled_Cached(true)
		initialAutoEndTurnOption = "false"
	end
				
	local advisorLevel = OptionsManager.GetTutorialLevel_Cached()
	OptionsManager.SetTutorialLevel_Cached(0)

	SaveModdingData( "InitialAutoEndTurnOption", initialAutoEndTurnOption )
	SaveModdingData( "InitialAdvisorLevel", advisorLevel )
end

-- initialize civilizations
function WakeUp ()

	Dprint("-------------------------------------")
	Dprint ("Looking for civs to wake up...") 	
	local civHibernating = LoadCivHibernating()

	-- Major civs
	for i = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do	
		local player = Players[i] 
		local iPlayer = i
		local civType = GetCivTypeFromiPlayer (iPlayer)

		if civType and GameInfo.Civilization_HistoricalSpawnDates[civType] and ( GameInfo.Civilization_HistoricalSpawnDates[civType].StartYear <= Game.GetGameTurnYear() ) then
			
			if ( civHibernating[iPlayer] ) then -- wakup now Sleeping Beauty !
				Dprint ("- trying to wake up " .. tostring(civType))
				Players[Game.GetActivePlayer()]:AddNotification(NotificationTypes.NOTIFICATION_CITY_GROWTH, "The " .. Players[iPlayer]:GetCivilizationAdjective() .. " peoples have developed into a civilization!", "A new civilization is born")
				local startPlot = player:GetStartingPlot()
				local startX = startPlot:GetX()
				local startY = startPlot:GetY()
				local initialSettler = player:InitUnit(SETTLER, startX, startY)

				SpawnInitialUnits(iPlayer, startX, startY) -- Balance starting units
				ConvertNearbyBarbarians(iPlayer, startX, startY) -- Get nearby barbarian units
				ConvertNearbyCS(iPlayer, startX, startY) -- Get nearby CS units
				InfluenceNearbyCS(iPlayer, startX, startY) -- Get influence on nearby CS

				if ( player:IsHuman() ) then
					-- remove the waiting unit
					for v in player:Units() do
						if (v:GetUnitType() == WAIT) then
							v:SetDamage( v:GetMaxHitPoints() )
						end
					end
					-- cover revealed plots
					CoverPlots(iPlayer)

					-- remove auto turn
					g_bPlayerHibernate = false					
					local initialAutoEndTurnOption = LoadModdingData("InitialAutoEndTurnOption")
					if initialAutoEndTurnOption == "false" then
						OptionsManager.SetSinglePlayerAutoEndTurnEnabled_Cached(false)
					end	
					
					local advisorLevel = LoadModdingData("InitialAdvisorLevel")
					OptionsManager.SetTutorialLevel_Cached(advisorLevel)

				else
					-- check if the AI can settle it's first city right here
					if CanSettleImmediatly(startPlot) then
						player:InitCity(startX, startY)
						initialSettler:Kill(true, -1)
						OnFirstCity(iPlayer, startX, startY) -- GameEvents.PlayerCityFounded is not called when using player:InitCity ?
					end 
				end

				civHibernating[iPlayer] = false
			end
		end
	end
	
	-- Minor civs
	for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do	
		local player = Players[i] 
		local iPlayer = i
		local civType = GetCivTypeFromiPlayer (iPlayer)

		if civType and GameInfo.Civilization_HistoricalSpawnDates[civType] and ( GameInfo.Civilization_HistoricalSpawnDates[civType].StartYear <= Game.GetGameTurnYear() ) then
			if ( civHibernating[iPlayer] ) then -- wakup now Sleeping Beauty !
				Players[Game.GetActivePlayer()]:AddNotification(NotificationTypes.NOTIFICATION_MINOR, "The city-state of " .. Players[iPlayer]:GetCivilizationDescription() .. " has been founded!", "A new civilization is born")
				Dprint ("- trying to wake up " .. tostring(civType)) 	
				local startPlot = player:GetStartingPlot()
				local startX = startPlot:GetX()
				local startY = startPlot:GetY()
					
				if CanSpawnMinor(startPlot) then
					Dprint ("  - far enough from other civs to spawn !") 	
					player:InitCity(startX, startY)
					SpawnInitialUnits(iPlayer, startX, startY) -- Balance starting units
					ConvertNearbyBarbarians(iPlayer, startX, startY) -- Get nearby barbarian units		
					civHibernating[iPlayer] = false
				else 
					Dprint ("  - not enough room to spawn !") 	
				end
			end
		end
	end

	SaveCivHibernating( civHibernating )
end


function OnFirstCity(iPlayer, x, y)
	Dprint ("-------------------------------------")
	Dprint ("New city founded...")
	local player = Players[iPlayer]
	local city = GetPlot(x,y):GetPlotCity()
	if (player:GetNumCities() == 1 and not player:IsMinorCiv()) then	
		Dprint ("-------------------------------------")
		Dprint ("Initializing first city for " .. tostring(player:GetName()))
		if Game.GetElapsedGameTurns() > ELAPSED_TURNS_FOR_BALANCE then
			SpawnInitialCity(city)
		end
	end
end
-- GameEvents.PlayerCityFounded.Add(OnFirstCity) -- in main Lua

-----------------------------------------
-- auto-turn functions
-----------------------------------------

-- reset golden age progression for hibernating civ
function ResetGoldenAgeMeter ()
	Dprint ("-------------------------------------")
	Dprint ("ResetGoldenAgeMeter...")
	local civHibernating = LoadCivHibernating()
	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		if ( civHibernating[iPlayer] ) then
			Players[iPlayer]:SetGoldenAgeProgressMeter(0)
		end
	end
end

-- auto-turn (deprecated)
function AutoEndTurn()
	local player = Players[LOCAL_PLAYER]
	if ( g_bPlayerHibernate and player:IsTurnActive() ) then
		local iEndTurnControl = GameInfoTypes.CONTROL_ENDTURN
		Game.DoControl(iEndTurnControl)
	end
end
--ContextPtr:SetUpdate( AutoEndTurn )


-----------------------------------------
-- Balanced starting  functions
-----------------------------------------


function SpawnInitialUnits(iPlayer, startX, startY)
	if not USE_FIXED_BALANCE then 
		return
	end
	Dprint ("  - Spawning initial units for " .. tostring(Players[iPlayer]:GetName()))
	
	local civType = GetCivTypeFromiPlayer (iPlayer)
	local spawnList = {}
	local bCivList = false

	if	civType and GameInfo.Civilization_HistoricalSpawnDates[civType] then
		Dprint ("    - Check fo Civ specific list..." )
		local spawnData = GameInfo.Civilization_HistoricalSpawnDates[civType]
		for i = 1, MAX_NUM_STARTING_UNITS do
			local column = "UnitType" .. tostring(i)
			local unitType = spawnData[column] -- "real" type, not table ID...
			if unitType then
				Dprint ("    - column " .. tostring(i) .." unitType = " .. tostring(unitType) )
				bCivList = true
				table.insert( spawnList, GameInfo.Units[unitType].ID )
			end
		end
	end

	if not bCivList then	
		Dprint ("    - Can't find Civ specific list, using Era spawn list..." )
		spawnList = g_SpawnList[g_Era]
	end
	
	for i, unitType in pairs(spawnList) do
		Players[iPlayer]:InitUnit(unitType, startX, startY)
	end
end

function SetStartingBonus()
	if not USE_ESTIMATED_BALANCE then 
		return
	end
	Dprint ("-------------------------------------")
	Dprint ("Set starting bonus for current turn...")
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
	numMajorAlive = 0
	g_KnownTech =	{}

	InitializeKnownTechTable()

	-- First pass: Update the g_KnownTech table
	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do	
		local player = Players[iPlayer]
		if player:IsAlive() and player:GetNumCities() > 0 then -- pick only civs that have founded at least one city
			local team = Teams[player:GetTeam()]
			for tech in GameInfo.Technologies() do
				if not team:IsHasTech(tech.ID) then
					g_KnownTech[tech.ID] = false
				end
			end
			g_PreviousOverflowResearch[iPlayer] = player:GetOverflowResearch()
		end
	end

	-- Second Pass: set the bonuses
	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do

		local player = Players[iPlayer]

		if player:IsAlive() and player:GetNumCities() > 0 then -- pick only civs that have founded at least one city
			numMajorAlive = numMajorAlive + 1
			local team = Teams[player:GetTeam()]

			if player:CalculateGoldRate() > 0 then
				g_Gold = g_Gold + player:CalculateGoldRate() 
			end
			g_Faith = g_Faith + player:GetTotalFaithPerTurn()
			g_GoldAge = g_GoldAge + (player:GetNumGoldenAges() * player:GetGoldenAgeLength())

			--[[
			for policy in GameInfo.Policies() do
				if player:HasPolicy(policy.ID) then
					g_Policies = g_Policies + 1
				end
			end
			--]]
			g_Policies = g_Policies + player:GetNumPolicies()
			g_Culture = g_Culture + player:GetNextPolicyCost()

			for tech in GameInfo.Technologies() do
				if team:IsHasTech(tech.ID) and not g_KnownTech[tech.ID] then -- Count only techs that are not universally known
					g_Techs = g_Techs + 1
					g_Science = g_Science + player:GetResearchCost(tech.ID)
				end
			end

			for city in player:Cities() do			
				for building in GameInfo.Buildings() do
					if (city:IsHasBuilding(building.ID)) then
						g_Hammer = g_Hammer + player:GetBuildingProductionNeeded(building.ID)
					end
				end
				g_LandCulture = g_LandCulture + city:GetJONSCulturePerTurn()
			end

			local numCities = player:GetNumCities() -- we already know that numCities > 0
			g_Population = g_Population + (player:GetTotalPopulation() / numCities)

			local era = player:GetCurrentEra()
			if era > g_Era then
				g_Era = era
			end
		end
	end
	
	if g_bPlayerHibernate then -- don't count the sleeping (but "alive") human player
		numMajorAlive = numMajorAlive - 1
	end

	if numMajorAlive == 0 then -- in that case the g_KnownTech is filled with true, and we don't want that (would give all techs to the first alive civilization)
		for tech in GameInfo.Technologies() do
			g_KnownTech[tech.ID] = false
		end
	end


	if numMajorAlive <= 0 then numMajorAlive = 1 end-- remember kids, sometime one line of code can save the universe.

	g_Techs =		Round(g_Techs / numMajorAlive)
	g_Science =		Round(g_Science / numMajorAlive)
	g_Hammer =		Round(g_Hammer / numMajorAlive)
	g_Policies =	Round(g_Policies / numMajorAlive)
	g_Culture =		Round(g_Culture / numMajorAlive)
	g_Faith =		Round(g_Faith * BALANCE_FAITH_FACTOR / numMajorAlive)
	g_Gold =		Round(g_Gold * BALANCE_GOLD_FACTOR / numMajorAlive)
	g_GoldAge =		Round(g_GoldAge / numMajorAlive)
	g_LandCulture =	Round(g_LandCulture / numMajorAlive)
	g_Population =	math.max (Round(g_Population / numMajorAlive), 1)

end

function InitializeKnownTechTable()
	for tech in GameInfo.Technologies() do
		g_KnownTech[tech.ID] = true
	end
end

function SpawnInitialCity(city)
	if not USE_ESTIMATED_BALANCE then 
		return
	end
	Dprint ("-------------------------------------")
	Dprint ("Set player bonus on foundation of " .. tostring(city:GetName()))
	Dprint ("- Faith    = ".. tostring(g_Faith) )
	Dprint ("- Tech     = ".. tostring(g_Techs) )
	Dprint ("- Science  = ".. tostring(g_Science) )
	Dprint ("- Policies = ".. tostring(g_Policies) )
	Dprint ("- Culture = ".. tostring(g_Culture) )
	Dprint ("- Hammer   = ".. tostring(g_Hammer) )
	Dprint ("- Gold     = ".. tostring(g_Gold) )
	Dprint ("- GA turns = ".. tostring(g_GoldAge) )
	Dprint ("- LCulture = ".. tostring(g_LandCulture) )
	Dprint ("- Population = ".. tostring(g_Population) )

	local iPlayer = city:GetOwner()
	local player = Players[iPlayer]
	player:ChangeFaith(g_Faith)
	if USE_FREE_POLICIES_BONUS then
		player:ChangeNumFreePolicies(g_Policies)
	else
		player:ChangeJONSCulture(g_Culture)
	end
	player:ChangeGold(g_Gold)
	player:ChangeGoldenAgeTurns(g_GoldAge)
	city:ChangeJONSCultureStored(g_LandCulture)
	city:SetPopulation(g_Population, true)
	city:SetFood(Round(city:GrowthThreshold()*INITIAL_CITY_FOOD_PERCENT/100)) 
	player:ChangeNumFreeGreatPeople(math.min( Round( g_Hammer / BALANCE_HAMMER_COST_PGP ), BALANCE_MAX_GP))
	local team = Teams[player:GetTeam()]
	local teamTechs = team:GetTeamTechs()

	
	local bFreeTech = true
	local civType = GetCivTypeFromiPlayer (iPlayer)
	if	civType and GameInfo.Civilization_HistoricalSpawnDates[civType] then
		bFreeTech = (GameInfo.Civilization_HistoricalSpawnDates[civType].NoFreeTech == 0)
		Dprint ("- FreeTech = ".. tostring(bFreeTech) )
	end

	if player:IsHuman() and HUMAN_USE_BONUS_TECHS then
		if bFreeTech then
			GiveUniversalTechs(team)
		end
		player:ChooseTech(g_Techs, Locale.ConvertTextKey("TXT_KEY_HSD_FREE_TECH", g_Techs), -1)
	else			
		local initialTech = GameInfo.Technologies.TECH_AGRICULTURE.ID
		team:SetHasTech(initialTech, false)
		player:PushResearch(initialTech, true)
		local initialTechCost = player:GetResearchCost(initialTech)

		-- Detailled reports below because of a bug with overflowing research...

		--local initialTechAbsoluteCost = GameInfo.Technologies.TECH_AGRICULTURE.Cost
		Dprint ("- Initial Tech Cost = ".. tostring(initialTechCost) )
		local addedTech = g_Science + initialTechCost
		Dprint ("- Research boost = ".. tostring(addedTech) )
		Dprint ("- Research progress = ".. tostring(teamTechs:GetResearchProgress(initialTech)) )
		Dprint ("- Overflow Research before boost = ".. tostring(player:GetOverflowResearch()) )
		
		teamTechs:SetResearchProgress(initialTech, g_Science + player:GetResearchCost(initialTech), player:GetID())
		
		player:PopResearch(initialTech)		-- |
		team:SetHasTech(initialTech, true)	-- } seems to fix the overflowing research bug, but are all needed ?
		player:ClearResearchQueue()			-- |

		Dprint ("- Overflow Research after boost = ".. tostring(player:GetOverflowResearch()) )
		if bFreeTech then
			GiveUniversalTechs(team)
		end
		Dprint ("- Overflow Research after free techs = ".. tostring(player:GetOverflowResearch()) )
		Dprint ("- Current Research ID = ".. tostring(player:GetCurrentResearch()) )
		if player:GetCurrentResearch() >= 0 then
			print ("- Current Research = ".. tostring(Locale.ConvertTextKey(GameInfo.Technologies[player:GetCurrentResearch()].Description)) )
		end
	end
	Dprint ("-------------------------------------")
end

function GiveUniversalTechs(team)
	for tech in GameInfo.Technologies() do
		if g_KnownTech[tech.ID] and not team:IsHasTech(tech.ID) then 
			team:SetHasTech(tech.ID, true)
		end
	end
end

function ConvertNearbyBarbarians(iPlayer, startX, startY)
	if not ALLOW_BARBARIAN_CONVERTION then 
		return
	end
	Dprint ("  - search for nearby Barbarians to convert for " .. tostring(Players[iPlayer]:GetName()))
	local plot = GetPlot(startX, startY)
	local bIncludeCenter = true
	local range = Round(CONVERT_BARBARIAN_RANGE * math.max(((g_Era + 1) * CONVERT_ERA_RANGE_MOD / 100), 1) * GetConvertionRangePercent(iPlayer) / 100)
	for pAreaPlot in PlotAreaSpiralIterator(plot, range, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, bIncludeCenter) do
    	-- TODO: If there is a city, convert it
		for i = 0, pAreaPlot:GetNumUnits() - 1, 1 do
    		local unit = pAreaPlot:GetUnit(i);
			if unit and (unit:GetOwner() == BARBARIAN_PLAYER) then
				ChangeUnitOwner (unit, iPlayer)
			elseif not unit then			
				Dprint ("  - WARNING: unit = nil using pAreaPlot:GetUnit(i) with i = " .. tostring(i) .. " and pAreaPlot:GetNumUnits() = ".. tostring(pAreaPlot:GetNumUnits()) .. " at plot " .. tostring(pAreaPlot:GetX()) .. " , " .. tostring(pAreaPlot:GetY()))
			end
		end

    end
end

function GetConvertionRangePercent(iPlayer)
	local player = Players[iPlayer]
	local rangePercent = 100
	if player:IsMinorCiv() then
		rangePercent = MINOR_RANGE_PERCENT
	end
	return rangePercent
end

function ConvertNearbyCS(iPlayer, startX, startY)
	if not ALLOW_CITY_STATES_CONVERTION then 
		return
	end
	Dprint ("  - search for nearby City State to convert for " .. tostring(Players[iPlayer]:GetName()))
	local plot = GetPlot(startX, startY)
	local bIncludeCenter = true
	for pAreaPlot in PlotAreaSpiralIterator(plot, CONVERT_CITY_STATES_RANGE, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, bIncludeCenter) do

		for i = 0, pAreaPlot:GetNumUnits() - 1, 1 do
    		local unit = pAreaPlot:GetUnit(i);
			if unit and (Players[unit:GetOwner()]:IsMinorCiv()) then
				ChangeUnitOwner (unit, iPlayer)				
			elseif not unit then			
				Dprint ("  - WARNING: unit = nil using pAreaPlot:GetUnit(i) with i = " .. tostring(i) .. " and pAreaPlot:GetNumUnits() = ".. tostring(pAreaPlot:GetNumUnits()) .. " at plot " .. tostring(pAreaPlot:GetX()) .. " , " .. tostring(pAreaPlot:GetY()))
			end
		end
		

		local player = Players[iPlayer]

		if pAreaPlot:IsCity() then
			local city = pAreaPlot:GetPlotCity()
			local owner = Players[city:GetOwner()]
			if owner:IsMinorCiv() then
				owner:Disband(city)	-- better than kill (update graphic...)
				player:InitUnit(SETTLER, pAreaPlot:GetX(), pAreaPlot:GetY())
				-- give all other units of this CS if it had only one City
				if (owner:GetNumCities() == 0) then
					for u in owner:Units() do
						ChangeUnitOwner (u, iPlayer)
					end
				end				 
			end
		end

		local ownerID = pAreaPlot:GetOwner()
		if (ownerID ~= -1) then
			if Players[ownerID]:IsMinorCiv() then
				pAreaPlot:SetOwner(-1,-1)
			end
		end

    end
end


function InfluenceNearbyCS(iPlayer, startX, startY)
	if not ALLOW_CITY_STATES_ALLY then 
		return
	end
	Dprint ("  - search for nearby City State to influence for " .. tostring(Players[iPlayer]:GetName()))
	local plot = GetPlot(startX, startY)
	local bIncludeCenter = true
	for pAreaPlot in PlotAreaSpiralIterator(plot, ALLY_CITY_STATES_RANGE, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, bIncludeCenter) do
		
		if pAreaPlot:IsCity() then
			local city = pAreaPlot:GetPlotCity()
			if Players[city:GetOwner()]:IsMinorCiv() then -- to do : make clear who is who here...
				Players[city:GetOwner()]:ChangeMinorCivFriendshipWithMajor(iPlayer, GameDefines["FRIENDSHP_THRESHOLD_ALLIES"] + CITY_STATES_INFLUENCE_BONUS)
			end
		end

    end
end

function CanSpawnMinor(startPlot)
	Dprint ("  - check if City State can spawn at " .. tostring(startPlot:GetX()) .. "," .. tostring(startPlot:GetY()))
	local bIncludeCenter = true
	for pAreaPlot in PlotAreaSpiralIterator(startPlot, MINIMUM_DISTANCE_FOR_CS, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, bIncludeCenter) do
		if pAreaPlot:GetOwner() ~= -1 then
			return false
		end
    end
	return true
end


function CanSettleImmediatly(startPlot)
	Dprint ("  - check if Civilization can settle immediatly at " .. tostring(startPlot:GetX()) .. "," .. tostring(startPlot:GetY()))
	local bIncludeCenter = true
	for pAreaPlot in PlotAreaSpiralIterator(startPlot, MINIMUM_DISTANCE_FOR_MAJOR, SECTOR_NORTH, DIRECTION_CLOCKWISE, DIRECTION_OUTWARDS, bIncludeCenter) do
		if pAreaPlot:GetOwner() ~= -1 then
			if not Players[pAreaPlot:GetOwner()]:IsMinorCiv() then 
				return false
			end
		end
    end
	return true
end


-----------------------------------------
-- UI functions
-----------------------------------------

function OnEventReceived( popupInfo )
	
	local civHibernating = LoadCivHibernating()
	if not civHibernating[LOCAL_PLAYER] and Game.GetElapsedGameTurns() > 0 then
		return -- civilization is awake, and first turn passed, no need to hide/close anything.
	end

	-- remove the "best civs" pop-up
	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_WHOS_WINNING ) then
		UIManager:DequeuePopup( ContextPtr:LookUpControl("/InGame/WhosWinningPopup") )
	end

	-- remove the Natural Wonder pop-up
	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_NATURAL_WONDER_REWARD ) then
		UIManager:DequeuePopup( ContextPtr:LookUpControl("/InGame/NaturalWonderPopup") )
	end

	-- remove the City States pop-up
	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_CITY_STATE_DIPLO ) then
		UIManager:DequeuePopup( ContextPtr:LookUpControl("/InGame/CityStateDiploPopup") )
	end	

end
--Events.SerialEventGameMessagePopup.Add( OnEventReceived ) -- in main lua


-----------------------------------------
-- Victory Condition functions
-----------------------------------------

function SetValidVictories()
	Dprint ("-------------------------------------")
	Dprint ("Setting Valid Victories... ")
	Dprint ("-------------------------------------")
	
	if not LoadModdingData("VICTORY_CULTURAL") then -- Not initialized...
		Dprint ("- Setting initial values...")
		Dprint ("- Pregame Culture Victory		=" .. tostring(PreGame.IsVictory("VICTORY_CULTURAL")))
		if PreGame.IsVictory("VICTORY_CULTURAL") then
			SaveModdingData("VICTORY_CULTURAL", 1)
		else
			SaveModdingData("VICTORY_CULTURAL", 0)
		end

		Dprint ("- Pregame Domination Victory		=" .. tostring(PreGame.IsVictory("VICTORY_DOMINATION")))
		if PreGame.IsVictory("VICTORY_DOMINATION") then
			SaveModdingData("VICTORY_DOMINATION", 1)
		else
			SaveModdingData("VICTORY_DOMINATION", 0)
		end

		Dprint ("- Pregame Diplomatic Victory		=" .. tostring(PreGame.IsVictory("VICTORY_DIPLOMATIC")))
		if PreGame.IsVictory("VICTORY_DIPLOMATIC") then
			SaveModdingData("VICTORY_DIPLOMATIC", 1)
		else
			SaveModdingData("VICTORY_DIPLOMATIC", 0)
		end
		Dprint ("-------------------------------------")
	end

	local	bCultural =		(LoadModdingData("VICTORY_CULTURAL") == 1)
	local	bDomination =	(LoadModdingData("VICTORY_DOMINATION") == 1)
	local	bDiplomatic =	(LoadModdingData("VICTORY_DIPLOMATIC") == 1)
	
	local year = Game.GetGameTurnYear()

	if bCultural then
		local year = Game.GetGameTurnYear()
		if year >= MINIMUM_YEAR_FOR_CULTURE_VICTORY then
			Dprint ("- Activating Culture Victory...")			
			PreGame.SetVictory(GameInfo.Victories["VICTORY_CULTURAL"].ID, true)
		else
			Dprint ("- Deactivating Culture Victory...")
			PreGame.SetVictory(GameInfo.Victories["VICTORY_CULTURAL"].ID, false)
		end
	end
	
	if bDomination then
		if year >= MINIMUM_YEAR_FOR_DOMINATION_VICTORY then
			Dprint ("- Activating Domination Victory...")
			PreGame.SetVictory(GameInfo.Victories["VICTORY_DOMINATION"].ID, true)
		else
			Dprint ("- Deactivating Domination Victory...")
			PreGame.SetVictory(GameInfo.Victories["VICTORY_DOMINATION"].ID, false)
		end
	end
	
	if bDiplomatic then
		if year >= MINIMUM_YEAR_FOR_DIPLOMATIC_VICTORY then
			Dprint ("- Activating Diplomatic Victory...")
			PreGame.SetVictory(GameInfo.Victories["VICTORY_DIPLOMATIC"].ID, true)
		else
			Dprint ("- Deactivating Diplomatic Victory...")
			PreGame.SetVictory(GameInfo.Victories["VICTORY_DIPLOMATIC"].ID, false)
		end
	end

	Dprint ("-------------------------------------")
end