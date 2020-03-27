-- BarbariansEvolved
-- Author: Charsi
-- DateCreated: 07/18/2015 7:46:51 PM
--------------------------------------------------------------

include( "BarbariansEvolvedSharedFunctions" );

--########################################################################
-- SQL fetch best-in-class (ranged)
function GetBestRangedCombat(pPlayer, cachetype, sql)
	local bestID = "-1"
	local bestType = "TYPE_NONE"
	local bestSTR = -1

	for row in DB.Query(sql) do
		if (pPlayer:CanTrain(row.ID, true, true, true, false) and (tonumber(row.RangedCombat) > bestSTR)) then
			bestSTR = tonumber(row.RangedCombat)
			bestType = row.Type
			bestID = row.ID
		end
	end

	print("PreCacheBestInClass: Tech has advanced, updating " .. cachetype .. " choice to [" .. bestType .. "]")
	return bestID
end

--########################################################################
-- SQL fetch best-in-class (melee)
function GetBestCombat(pPlayer, cachetype, sql)
	local bestID = "-1"
	local bestType = "TYPE_NONE"
	local bestSTR = -1
	for row in DB.Query(sql) do
		if (pPlayer:CanTrain(row.ID, true, true, true, false) and (tonumber(row.Combat) > bestSTR)) then
			bestSTR = tonumber(row.Combat)
			bestType = row.Type
			bestID = row.ID
		end
	end

	print("PreCacheBestInClass: Tech has advanced, updating " .. cachetype .. " choice to [" .. bestType .. "]")
	return bestID
end

--########################################################################
-- Pre-Cache all the best-in-class, once per turn, the first time it's needed
function PreCacheBestInClass(pPlayer, cachetype)
	local dcc
	local acc
	local sql

	if (cachetype == "Ranged") then
		sql = "SELECT ID, Type, RangedCombat FROM Units WHERE CombatClass = \"UNITCOMBAT_ARCHER\""
		iBICRanged = GetBestRangedCombat(pPlayer, cachetype, sql)
	end

	if (cachetype == "Mounted/Armor") then
		sql = "SELECT ID, Type, Combat FROM Units WHERE CombatClass IN (\"UNITCOMBAT_MOUNTED\", \"UNITCOMBAT_ARMOR\")"
		iBICMountedArmor = GetBestCombat(pPlayer, cachetype, sql)
	end

	if (cachetype == "Naval Melee") then
		sql = "SELECT ID, Type, Combat FROM Units WHERE CombatClass = \"UNITCOMBAT_NAVALMELEE\""
		iBICNavalMelee = GetBestCombat(pPlayer, cachetype, sql)
	end

	if (cachetype == "Naval Ranged") then
		sql = "SELECT ID, Type, RangedCombat FROM Units WHERE CombatClass = \"UNITCOMBAT_NAVALRANGED\""
		iBICNavalRanged = GetBestRangedCombat(pPlayer, cachetype, sql)
	end

	if (cachetype == "Siege") then
		sql = "SELECT ID, Type, RangedCombat FROM Units WHERE CombatClass = \"UNITCOMBAT_SIEGE\""
		iBICSiege = GetBestRangedCombat(pPlayer, cachetype, sql)
	end

	if (cachetype == "Melee/Gun") then
		sql = "SELECT ID, Type, Combat FROM Units WHERE CombatClass IN (\"UNITCOMBAT_MELEE\", \"UNITCOMBAT_GUN\")"
		iBICMeleeGun = GetBestCombat(pPlayer, cachetype, sql)
	end
end

--########################################################################
-- Check if unit should be spawned on this plot
function BarbEvolvedPlotCheck(pPlayer, pPlot, iNumTechs)
	local spawnchance = math.random(10)
	local spawnlimit = iSpawnChance

	-- if disabled, don't bother
	if bDisableSponsoredSpawns then
		-- print("BarbEvolvedPlotCheck: Spawning disabled due to settings.")
		return
	end

	-- double chance if barbarians are raging
	--[[
	if bRagingBarbarians then
		spawnlimit = spawnlimit * 2
	end
	]]--

	-- do we spawn?
	-- if (Game.GetElapsedGameTurns() == 0) and pPlot:IsStartingPlot() then
	if pPlot:IsStartingPlot() then
		-- spawn a occupying settler if required
		-- whose plot is this? iterate all minors to discover
		for iCityState = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
			local pCityState = Players[iCityState]
			local pCSPlot = pCityState:GetStartingPlot()
			if pCSPlot == pPlot then
				-- has the plot been vacated for some reason?
				if (pPlot:GetUnit(0) == nil) then
					-- if so... spawn the barb settler
					print("BarbEvolvedPlotCheck: (Re)Spawning a Barbarian Settler on plot [" .. pPlot:GetX() .. "," .. pPlot:GetY() .. "] for [" .. pCityState:GetName() .. "]")
					newbarb = Players[iBarbNPCs]:InitUnit(GameInfoTypes.UNIT_IMMOBILE_SETTLER, pPlot:GetX(), pPlot:GetY(), UNITAI_DEFENSE)
					if (newbarb ~= nil) then
						-- rename the settler
						newbarb:SetName(pCityState:GetCivilizationAdjective() .. " " .. newbarb:GetName())
					end
				end
			end
		end
	else
		-- normal logic
		if (spawnchance < spawnlimit) then
			print("BarbEvolvedPlotCheck: Spawning unit on plot [" .. pPlot:GetX() .. "," .. pPlot:GetY() .. "]")

			local retID = BarbUnitHeirarchy(pPlayer, pPlot, iNumTechs)

			if retID ~= "-1" then
				-- always spawn the unit under the ownership of the MINOR barbarians
				Players[iBarbNPCs]:InitUnit(retID, pPlot:GetX(), pPlot:GetY(), GameInfo.UnitAIInfos[GameInfo.Units[retID].DefaultUnitAI].ID)
			else
				print("BarbEvolvedPlotCheck: No unit of that type can be trained. Spawn aborted.")
			end
		else
			print("BarbEvolvedPlotCheck: Chose not to spawn unit on plot [" .. pPlot:GetX() .. "," .. pPlot:GetY() .. "]")
		end
	end
end

--########################################################################
-- Check if garrison unit should be spawned in city
function BarbEvolvedGarrisonCheck(pPlayer, pCity, iNumTechs)
	local spawnchance = math.random(10)
	local spawnlimit = iSpawnChance

	-- if disabled, don't bother
	if bDisableBarbSpawn then
		-- print("BarbEvolvedGarrisonCheck: Spawning disabled due to settings.")
		return
	end

	if (iBarbMajorCiv == pPlayer:GetID()) and bDisableBarbSpawnForAlly then
		-- print("BarbEvolvedGarrisonCheck: Spawning disabled for the Barbarian Major civ.")
		return
	end

	-- if disabled when the Barb is the active player, don't bother
	if (Game.GetActivePlayer() == pPlayer:GetID()) and bDisableBarbSpawnForMe then
		-- print("BarbEvolvedGarrisonCheck: Spawning disabled when the human player is Barbarian.")
		return
	end

	-- double chance if barbarians are raging
	--[[
	if bRagingBarbarians then
		spawnlimit = spawnlimit * 2
	end
	]]--

	-- double chance again if city damaged
	if (pCity:GetDamage() > 0) then
		spawnlimit = spawnlimit * 2
	end

	-- do we spawn?
	if (spawnchance < spawnlimit) then
		print("BarbEvolvedGarrisonCheck: Spawning unit in: " .. pCity:GetName())
		-- BarbUnitHeirarchy(pPlayer, pCity, iNumTechs)

		if (pCity:GetGarrisonedUnit() == nil) then
			local pCityPlot = pCity:Plot()
			local retID = BarbUnitHeirarchy(pPlayer, pCityPlot, iNumTechs)

			if retID ~= "-1" then
				if pCity:CanTrain(retID) then
					-- always spawn the unit under the ownership of the MINOR barbarians
					Players[iBarbNPCs]:InitUnit(retID, pCity:GetX(), pCity:GetY(), GameInfo.UnitAIInfos[GameInfo.Units[retID].DefaultUnitAI].ID)
				else
					print("BarbEvolvedGarrisonCheck: Unit selection deemed invalid in this city. Spawn aborted.")
				end
			else
				print("BarbEvolvedGarrisonCheck: No unit of that type can be trained. Spawn aborted.")
			end
		else
			print("BarbEvolvedGarrisonCheck: City has a garrisoned unit. Spawn aborted.")
		end
	else
		print("BarbEvolvedGarrisonCheck: Chose not to spawn unit in: " .. pCity:GetName())
	end
end

--########################################################################
-- Check possible spawns in a heirarchial order
-- Changed so that it's now plot specific, not city specific.
function BarbUnitHeirarchy(pPlayer, pPlot, iNumTechs)
	-- TODO: Check pPlot to spawn aztec units
	-- print("BarbUnitHeirarchy called")

	local chance = math.random(12)
	local fiftyfifty = math.random(10)
	local bestID = "-1"

	if chance < 4 then -- 30% archer
		print("BarbUnitHeirarchy: Selected Ranged!")
		if (iLastTechsRanged < iNumTechs ) then
			PreCacheBestInClass(pPlayer, "Ranged")
			iLastTechsRanged = iNumTechs
		end
		bestID = iBICRanged
	elseif chance < 7 then -- 30% siege
		print("BarbUnitHeirarchy: Selected Mounted/Armor!")
		if (iLastTechsMountedArmor < iNumTechs) then
			PreCacheBestInClass(pPlayer, "Mounted/Armor")
			iLastTechsMountedArmor = iNumTechs
		end
		bestID = iBICMountedArmor
	elseif chance < 10 then -- 30% naval or mobile
		-- if pCity:IsCoastal(14) then
		if pPlot:IsCoastalLand() then
			if fiftyfifty < 6 then
				print("BarbUnitHeirarchy: Selected Naval Melee!")
				if (iLastTechsNavalMelee < iNumTechs) then
					PreCacheBestInClass(pPlayer, "Naval Melee")
					iLastTechsNavalMelee = iNumTechs
				end
				bestID = iBICNavalMelee
			else
				print("BarbUnitHeirarchy: Selected Naval Ranged!")
				if (iLastTechsNavalRanged < iNumTechs) then
					PreCacheBestInClass(pPlayer, "Naval Ranged")
					iLastTechsNavalRanged = iNumTechs
				end
				bestID = iBICNavalRanged
			end
		else
			print("BarbUnitHeirarchy: Selected Siege!")
			if (iLastTechsSiege < iNumTechs) then
				PreCacheBestInClass(pPlayer, "Siege")
				iLastTechsSiege = iNumTechs
			end
			bestID = iBICSiege
		end
	else -- 30% melee
		print("BarbUnitHeirarchy: Selected Melee/Gun!")
		if (iLastTechsMeleeGun < iNumTechs) then
			PreCacheBestInClass(pPlayer, "Melee/Gun")
			iLastTechsMeleeGun = iNumTechs
		end
		bestID = iBICMeleeGun
	end

	return bestID

	-- print("BarbUnitHeirarchy exit")
end

--########################################################################
-- Notification routine for barb city capture
function BarbEvolvedCityCapture(vHexPos, oldOwner, cityID, newOwner)
	local pOldOwner = Players[oldOwner]
	local pNewOwner = Players[newOwner]

	if (pOldOwner == nil) or (pNewOwner == nil) then
		return
	end

	local iX, iY = ToGridFromHex( vHexPos.x, vHexPos.y )
	local pCityPlot = Map.GetPlot(iX, iY)
	local pCity = pCityPlot:GetPlotCity()

	-- local pCity = pOldOwner:GetCityByID(cityID)

	if (pCity == nil) then
		print("BarbEvolvedCityCapture: City object is null, exiting.")
		return
	end

	local sCityName = pCity:GetName()

	-- If the city wasn't ever Barbarian, and is now...
	if IsBarbaricCiv(newOwner) and not IsBarbaricCiv(oldOwner) and not IsBarbaricCiv(Game.GetActivePlayer()) then
		-- If the new owner is:
		-- a) Barbarian Civilization, or
		-- b) there is no Barbarian Civilization in-game
		-- ... send out a notification (this prevents erroneous notification when a Civilized power "liberates" a Barbarian Civilization city to Tribal Barbarians)
		if IsBarbMajorCiv(newOwner) or not isUsingBarbarianCiv then
			local pActivePlayer = Players[Game.GetActivePlayer()]
			local sTitle = sCityName .. " has fallen into the hands of " .. sBarbShortDefault .. "!"
			local sText = "Travellers report that the city of " .. sCityName .. " has fallen into the hands of " .. sBarbShortDefault .. "!  With each fallen city, the light of Civilization grows dimmer!"

			-- override if we are using renaming and have reached at least the first period-appropriate array element
			if bBarbEraNameChange and (iMinEraId > -1) then
				sTitle = sCityName .. " has fallen into the hands of " .. arrBarbNames[iMinEraId][4] .. "!"
				sText = "Travellers report that the city of " .. sCityName .. " has fallen into the hands of " .. arrBarbNames[iMinEraId][4] .. "!  With each fallen city, the light of Civilization grows dimmer!"
			end

			print("BarbEvolvedCityCapture: sending out notification")
			pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, pCity:GetX(), pCity:GetY())
		end
	end

	print("BarbEvolvedCityCapture: City [" .. sCityName .. "] changes hands: from [" .. oldOwner .. "] to [" .. newOwner .. "]")

	if IsBarbNPCs(newOwner) and not IsBarbaricCiv(oldOwner) then
		-- A city can flip to the Barb NPC civ (63) one of two ways:
		-- 1) They're running CBP and the Barbarians legitimately captured it
		-- 2) It was Liberated to the Barbarians
		-- Therefore we check if the Barbarian Major civ is in the game, we're using a Liberation civ and and that the Barbarian Minor (63) is NOT it.  If all are true option 1) must have occured.
		if isUsingBarbarianCiv and (iDummyCiv ~= iBarbNPCs) then
			print("BarbEvolvedCityCapture: Flipping Barbarian city (63) to ally...")

			-- flip city to major
			local pBarbAlly = Players[iBarbMajorCiv]

			-- note... this call should trigger BarbEvolvedCityCapture again!
			pBarbAlly:AcquireCity(pCity, true, false)
		end
	end
end

--########################################################################
-- resuable "Are State-Sponsored Encampments allowed" check
function StateSponsoredEncampmentDisabled()
	local bDisableEncampments = false

	if (Game.GetActivePlayer() ~= iBarbCivID) and bDisableBuildingEncampmentsForOthers then
		bDisableEncampments = true
	end

	if bDisableBuildingEncampmentsForAll then
		bDisableEncampments = true
	end

	return bDisableEncampments
end

--########################################################################
-- disable State-Sponsored Encampments
function StateSponsoredEncampmentCheck()
	local camptextsql = ""

	print("Checking if we should disable State-Sponsored Encampments...")
	if StateSponsoredEncampmentDisabled() then
		print("StateSponsoredEncampmentCheck: State-Sponsored Encampments are Disabled; updating encampment tooltip.")
		camptextsql = "UPDATE " .. sLanguageTable .. " SET Text = (SELECT Text FROM " .. sLanguageTable .. " WHERE Tag = 'TXT_KEY_BUILD_ENCAMPMENT_DISABLED') WHERE Tag = 'TXT_KEY_BUILD_ENCAMPMENT_HELP'"
	else
		print("StateSponsoredEncampmentCheck: State-Sponsored Encampments are Enabled; updating encampment tooltip.")
		camptextsql = "UPDATE " .. sLanguageTable .. " SET Text = (SELECT Text FROM " .. sLanguageTable .. " WHERE Tag = 'TXT_KEY_BUILD_ENCAMPMENT_ENABLED') WHERE Tag = 'TXT_KEY_BUILD_ENCAMPMENT_HELP'"
	end

	for camprow in DB.Query(camptextsql) do
	end

	-- refresh text
	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
end

--########################################################################
-- disable/short-circuit Encampments if Encampment construction is disabled
function BarbEvolvedStateSponsorBuildCheck(iHexX, iHexY, iContinent1, iContinent2, player, createImp, createImpRR)
	local pPlot = Map.GetPlot(ToGridFromHex(iHexX, iHexY))
	local iImprovement = pPlot:GetImprovementType()
	local sImprovement = iImprovement > -1 and GameInfo.Improvements[iImprovement].Type or "Improvement in progress"
	local iPlayerID = pPlot:GetOwner()
	local plotOwner = iPlayerID > -1 and Players[iPlayerID]:GetName() or "nobody"

	-- print(string.format("%s (%s,%s) built on tile %d, %d by player %d. Plot owned by %s", sImprovement, createImp, createImpRR, pPlot:GetX(), pPlot:GetY(), iPlayerID, plotOwner))

	if (sImprovement == "IMPROVEMENT_EVOLVED_CAMP") then
		if StateSponsoredEncampmentDisabled() then
			if bBarbEvolveCityStates and pPlot:IsStartingPlot() then
				print("BarbEvolvedStateSponsorBuildCheck: Sponsored camp at (" .. pPlot:GetX() .. ", " .. pPlot:GetY() .. ") overlooked because it rests on a starting plot.")
			else
				print("BarbEvolvedStateSponsorBuildCheck: Detected finished construction of a disabled State-Sponsored camp at (" .. pPlot:GetX() .. ", " .. pPlot:GetY() .. "); converting it immediately to a fort.")
				pPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_FORT)
			end
		end
	end
end

--########################################################################
-- Detect attacks on non-barb cities
function BarbEvolvedCityUpdate(player, cityID, updateType)
	-- print("BarbEvolvedCityUpdate called - player [" .. player .. "] cityID [" .. cityID .. "] updateType [" .. updateType .. "]")

	if (bDisableBarbCapture) then
		-- Capture is disabled.
		return
	end

	if IsBarbaricCiv(player) then
		-- Never check Barbarian cities or their ally for capture.
		return
	end

	if (updateType == iCityUpdateTypeBanner) then
		local pPlayer = Players[player]

		if (pPlayer == nil) then
			return
		end

		local pCity = pPlayer:GetCityByID(cityID)

		if (pCity == nil) then
			return
		end

		local sCityName = pCity:GetName()

		local iCityMaxHP
		local iCityHPDivisor

		if (not isUsingBNW and not isUsingGNK) then
			iCityMaxHP = GameDefines.MAX_CITY_HIT_POINTS
			iCityHPDivisor = 4
		else
			iCityMaxHP = pCity:GetMaxHitPoints()
			iCityHPDivisor = 8
		end

		local iCityBarbUnits = 0 -- is there a barb on any city plot
		local iCityNonBarbUnits = 0 -- is the barb plot check valid
		if (pCity:GetDamage() >= 1) then
			print("BarbEvolvedCityUpdate: [" .. sCityName .. "] is hurt, down [" .. pCity:GetDamage() .. "] of [" .. iCityMaxHP .. "] max hp.")

			-- cities heal every turn; so if they're below 12.5% hp (BNW/GNK) or 25% hp (vanilla) they must have 'died' last turn
			if ((iCityMaxHP - pCity:GetDamage()) <= (iCityMaxHP / iCityHPDivisor)) then
				print("BarbEvolvedCityUpdate: The city of [" .. sCityName .. "] has dropped below 12.5% hp!  Iterating [" .. pCity:GetNumCityPlots() .. "] plots for Barbarians...")

				for plotNbr = 0, pCity:GetNumCityPlots() - 1, 1 do
					local pPlot	= pCity:GetCityIndexPlot(plotNbr)

					if (pPlot ~= nil) then
						local pPlotUnit = pPlot:GetUnit(0)

						if (pPlotUnit ~= nil) then
							local iUnitOwner = pPlotUnit:GetOwner()
							local iUnitType = pPlotUnit:GetUnitType()
							-- local pUnitOwnerTeam = Players[iUnitOwner]:GetTeam()
							-- local pCityOwnerTeam = pPlayer:GetTeam()

							-- if the unit on this tile is:
							-- 1. not owned by the barbs (or their ally)
							-- 2. not owned by the city owner, and
							-- 3. isn't a civilian or scout
							-- ... the city cannot be awarded to barbarians
							if not IsBarbaricCiv(iUnitOwner) and (iUnitOwner ~= player) and pPlotUnit:IsCombatUnit() and ((pPlotUnit:IsRanged() and bRequireMeleeCapture == true) or (bRequireMeleeCapture == false)) and (iUnitType ~= GameInfoTypes.UNIT_SCOUT) then
								iCityNonBarbUnits = iCityNonBarbUnits + 1
							end
							if IsBarbaricCiv(iUnitOwner) and pPlotUnit:IsCombatUnit() then
								-- we found at least one barb somewhere in the city plots
								iCityBarbUnits = iCityBarbUnits + 1
							end
						end
					end
				end
				-- debug print final counts
				if bRequireMeleeCapture then
					print("BarbEvolvedCityUpdate: [" .. iCityBarbUnits .. "] Barbarian melee units in proximity.")
				else
					print("BarbEvolvedCityUpdate: [" .. iCityBarbUnits .. "] Barbarian combat units in proximity.")
				end
				print("BarbEvolvedCityUpdate: [" .. iCityNonBarbUnits .. "] combat units from other civs in proximity (not scouts).")
				-- at least one barb and non non-barb hostiles in vicinity - flip city
				if (iCityBarbUnits > 0) and (iCityBarbUnits > iCityNonBarbUnits) then
					print("BarbEvolvedCityUpdate: [" .. sCityName .. "] has been damaged below 12.5% and there are more Barbarian units nearby than anyone else; flipping city...")
					-- take the city
					local pNewCityOwner = Players[iBarbNPCs]

					if isUsingBarbarianCiv then
						-- Spoils go to the major civ!
						pNewCityOwner = Players[iBarbMajorCiv]
					end

					if (pNewCityOwner ~= nil) then
						ClearCityPlot(pCity)

						pNewCityOwner:AcquireCity(pCity, true, false)
					end
				end
				if (iCityBarbUnits == 0) and(iCityNonBarbUnits > 0) then
					print("BarbEvolvedCityUpdate: [" .. sCityName .. "] is besieged by non-Barbarian sources; we won't hand the city to barbs...")
				end
				-- at least one hostile non-barb unit in vicinity, the city cannot be awarded to barbarians
				if (iCityBarbUnits > 0) and(iCityNonBarbUnits > 0) then
					print("BarbEvolvedCityUpdate: [" .. sCityName .. "] territory contains more non-Barbarians than Barbarians; we won't hand the city to barbs...")
				end
				-- no barbs in vicinity AND no hostile units in vicinity - aircraft? nuke? heal?
				if (iCityBarbUnits == 0) and (iCityNonBarbUnits == 0) then
					print("BarbEvolvedCityUpdate: [" .. sCityName .. "] has been damaged below 12.5% but something went wrong?")
				end
			end
		end
	end
	-- print("BarbEvolvedCityUpdate exit")
end

--########################################################################
-- Hook for Events.SequenceGameInitComplete
function BarbEvolvedNPCUnitUpgradePass()
	BarbEvolvedUnitUpgradePass(iBarbNPCs)
end

--########################################################################
-- Cycle through the given civ's units, upgrading obsolete units (but halving their numbers)
function BarbEvolvedUnitUpgradePass(iBarbCivID)
	local pPlayer = Players[iBarbCivID]

	-- barb upgrade related
	local arrBarbUnitTypeSeen = {}
	local iUnitDelCnt = 0
	local iUnitUpgCnt = 0

	if (pPlayer == nil) then
		print("BarbEvolvedUnitUpgradePass: aborting for [" .. iBarbCivID .. "] because player object is null.")
		return
	end

	if bDisableGlobalUpgrade then
		print("BarbEvolvedUnitUpgradePass: skipping for [" .. iBarbCivID .. "] due to settings.")
		return
	end

	if (Game.GetActivePlayer() == iBarbCivID) and bDisableGlobalUpgradeForMe then
		print("BarbEvolvedUnitUpgradePass: skipping for [" .. iBarbCivID .. "] when the human player is Barbarian.")
		return
	end

	print("BarbEvolvedUnitUpgradePass: Iterating [" .. pPlayer:GetNumUnits() .. "] units...")

	for pUnit in pPlayer:Units() do
		if pUnit ~= nil then
			local iUnitType = pUnit:GetUnitType()
			local pPlot = pUnit:GetPlot()
			local iPlotOwner = pPlot:GetOwner()
			local bSeenType = false

			-- iterate the seen units
			-- delete pairs of units that can be upgraded (replacing two obsolete units with one shiny new unit)
			-- should keep barb numbers down a bit!
			for ptr, row in pairs(arrBarbUnitTypeSeen) do
				if (row.type == pUnit:GetUnitType()) then
					-- found a match (which we've already upgraded) so we can delete this dupe
					bSeenType = true
					-- don't delete units in enemy territory
					iPlotOwner = pUnit:GetPlot():GetOwner()
					if row.canupgrade and ((iPlotOwner == -1) or (iPlotOwner == iBarbCivID)) then
						-- delete the dupe instance (effectively halving their numbers)
						iUnitDelCnt = iUnitDelCnt + 1
						pUnit:Kill()
					end
					-- delete the row (we've purged the pair)
					table.remove(arrBarbUnitTypeSeen, ptr)
				end
			end

			local unitRow = {}

			-- if we haven't seen one of this unit, save it
			if (bSeenType == false) then
				local iUnitType = pUnit:GetUnitType()
				local iUnitID = pUnit:GetID()
				local iUpgradeType = pUnit:GetUpgradeUnitType()
				local bCanUpgrade = pPlayer:CanTrain(iUpgradeType, true, true, true, false)

				if (iUpgradeType ~= -1) then
					if bCanUpgrade then
						-- print("BarbEvolvedUnitUpgradePass: Storing [" .. GameInfo.Units[iUnitType].Description .. "] canUpgrade = TRUE")
					else
						-- print("BarbEvolvedUnitUpgradePass: Storing [" .. GameInfo.Units[iUnitType].Description .. "] canUpgrade = false")
					end

					unitRow.type = iUnitType
					unitRow.unitid = iUnitID
					unitRow.upgradetype = iUpgradeType
					unitRow.canupgrade = bCanUpgrade

					table.insert(arrBarbUnitTypeSeen, unitRow)

					-- don't upgrade units in enemy territory
					iPlotOwner = pUnit:GetPlot():GetOwner()
					if bCanUpgrade and ((iPlotOwner == -1) or (iPlotOwner == iBarbNPCs)) then
						-- upgrade the first instance always
						iUnitUpgCnt = iUnitUpgCnt + 1
						iNewX = pUnit:GetX()
						iNewY = pUnit:GetY()
						pUnit:Kill()
						-- create the new
						-- print("BarbEvolvedUnitUpgradePass: Obsolete unit [" .. GameInfo.Units[iUnitType].Description .. "] - deleting and creating new upgraded version [" .. GameInfo.Units[iUpgradeType].Description .. "].")
						pPlayer:InitUnit(iUpgradeType, iNewX, iNewY, GameInfo.UnitAIInfos[GameInfo.Units[iUpgradeType].DefaultUnitAI].ID)
					end
				end
			end
		end
	end
	print("BarbEvolvedUnitUpgradePass: Upgraded [" .. iUnitUpgCnt .. "] units, Deleted [" .. iUnitDelCnt .. "] duplicates without upgrading them.")
end

--########################################################################
-- Cycle through the configured promotions, applying as needed to this unit
function BarbEvolvedUnitPromotions(unit)
	-- all Minor Barbarians automatically get rival territory promotion (hardcode)
	if IsBarbNPCs(unit:GetOwner()) then
		if not unit:IsHasPromotion(GameInfoTypes["PROMOTION_RIVAL_TERRITORY"]) then
			-- print("Applying hardcoded promotion [PROMOTION_RIVAL_TERRITORY] to Barbarian NPC (63) DOMAIN_LAND unit [" .. unit:GetName() .. "]")
			unit:SetHasPromotion(GameInfoTypes[promo], true)
		end
	end

	if(unit:GetDomainType() == DomainTypes.DOMAIN_LAND) then
		for _, promo in pairs(arrBarbLandUnitPromotions) do
			if not unit:IsHasPromotion(GameInfoTypes[promo]) then
				-- print("Applying promotion [" .. promo .. "] to DOMAIN_LAND unit [" .. unit:GetName() .. "]")
				unit:SetHasPromotion(GameInfoTypes[promo], true)
			end
		end
	end

	if(unit:GetDomainType() == DomainTypes.DOMAIN_SEA) then
		for _, promo in pairs(arrBarbSeaUnitPromotions) do
			if not unit:IsHasPromotion(GameInfoTypes[promo]) then
				-- print("Applying promotion [" .. promo .. "] to DOMAIN_SEA unit [" .. unit:GetName() .. "]")
				unit:SetHasPromotion(GameInfoTypes[promo], true)
			end
		end
	end

	if(unit:GetDomainType() == DomainTypes.DOMAIN_AIR) then
		for _, promo in pairs(arrBarbAirUnitPromotions) do
			if not unit:IsHasPromotion(GameInfoTypes[promo]) then
				-- print("Applying promotion [" .. promo .. "] to DOMAIN_AIR unit [" .. unit:GetName() .. "]")
				unit:SetHasPromotion(GameInfoTypes[promo], true)
			end
		end
	end
end

--########################################################################
-- Trigger things that must occur at the start of a Human Barbarian player's turn
function BarbEvolvedActivePlayerStartTurn()
	-- print("BarbEvolvedActivePlayerStartTurn called.")

	-- remove blocking notifications if playing AS barbs
	if IsBarbMajorCiv(Game.GetActivePlayer()) and IsDefaultBarbMajorCiv() then
		-- remove notifications
		-- UI.RemoveNotification(EndTurnBlockingTypes.ENDTURN_BLOCKING_POLICY)
		-- UI.RemoveNotification(EndTurnBlockingTypes.ENDTURN_BLOCKING_FOUND_PANTHEON)
	end
end

--########################################################################
-- Cycle through barbarian cities, spawning units in undefended ones
-- Cycle through barbarian units healing each one for 10hp if it's in a camp or in barb territory
function BarbEvolvedCivStartTurn(iPlayer)
	-- print("BarbEvolvedCivStartTurn called for [" .. iPlayer .. "]")

	local pPlayer = Players[iPlayer]

	if (pPlayer == nil) then
		print("BarbEvolvedCivStartTurn: aborting for [" .. iPlayer .. "] because player object is null.")
		return
	end

	if Teams[pPlayer:GetTeam()] == nil then
		print("BarbEvolvedCivStartTurn: aborting for [" .. iPlayer .. "] because team object is null.")
		return
	end

	if not Teams[pPlayer:GetTeam()]:IsAlive() then
		print("BarbEvolvedCivStartTurn: aborting for [" .. iPlayer .. "] because team is not alive.")
		return
	end

--	print("-------------------- " .. pPlayer:GetName() .. " [" .. iPlayer .. "] Turn [" .. Game.GetElapsedGameTurns() .. "] BEGIN --------------------")

	local iTeamTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs():GetNumTechsKnown()

--	print("Units [" .. pPlayer:GetNumUnits() .. "]")
--	print("Cities [" .. pPlayer:GetNumCities() .. "]")
--	print("Techs Known [" .. iTeamTechs .. "]")
--	print("Happiness [" .. pPlayer:GetHappiness() .. "]")
--	print("Gold [" .. pPlayer:CalculateGrossGold() .. "] Gold Per Turn [" .. pPlayer:CalculateGoldRate() .. "]")
--	print("Culture [" .. pPlayer:GetJONSCulture() .."] Culture Per Turn [" .. pPlayer:GetTotalJONSCulturePerTurn() .. "]")
--	print("Policies [" .. pPlayer:GetNumPolicies() .. "] Branches [" .. pPlayer:GetNumPolicyBranchesUnlocked() .. "] Complete [" .. pPlayer:GetNumPolicyBranchesFinished() .. "]")
--	if isUsingBNW or isUsingGNK then
--		print("Faith [" .. pPlayer:GetFaith() .. "] Faith Per Turn [" .. pPlayer:GetTotalFaithPerTurn() .. "]")
--	end
--	if isUsingBNW then
--		print("Tourism [" .. pPlayer:GetTourism() .. "]")
--	end

	-- CALLED ON EACH PLAYER'S TURN - zero Barbarian faith in case the Barbarians somehow get faith on turn 0 by spawning on top of a ruin
	if isUsingBarbarianCiv and IsDefaultBarbMajorCiv() then
		local pPlayer = Players[iBarbMajorCiv]

		if (pPlayer:GetNumCities() == 0) and (pPlayer:GetFaith() > 0) then
			print("BarbEvolvedCivStartTurn: Barbarian major civ has nonzero faith but zero cities.  Fixing...")
			pPlayer:SetFaith(0)
		end
	end

	-- If the major (default) barbarian is in play and is not the human player
	-- If an Infiltrator unit (not owned by the active player) is within range of a city, explode
	-- but I am le tired
	if (Game.GetActivePlayer() ~= iPlayer) and IsBarbMajorCiv(iPlayer) and IsDefaultBarbMajorCiv() then
		-- zen have a nap
		for pUnit in pPlayer:Units() do
			-- zen fire ze missiles! (if the Major Barbarian is not human)
			if (pUnit:GetUnitType() == GameInfoTypes.UNIT_DIRTY_BOMB) then
				-- this sucks; loop every civ's cities to see if ANY of them are in range of this unit; can't think of a better way to do this that is accurate
				for iNukeVictim = 0, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
					pNukeVictim = Players[iNukeVictim]
					if pNukeVictim ~= nil then
						-- if Teams[pPlayer:GetTeam()]:IsAtWar(pNukeVictim:GetTeam()) and (iPlayer ~= iNukeVictim) then
						if (iPlayer ~= iNukeVictim) then
							-- we're at war; loop all of this civ's cities
							for pNukeCity in pNukeVictim:Cities() do
								local pUnitPlot = pUnit:GetPlot()
								local pNukePlot = pNukeCity:Plot()

								-- is this city a valid nuke target?
								if pUnit:CanNuke(pNukePlot) and (Map.PlotDistance(pUnitPlot:GetX(), pUnitPlot:GetY(), pNukePlot:GetX(), pNukePlot:GetY()) <= 2) then
									-- YES! AAAAA MOTHERLAND!!!
									print("BarbEvolvedCivStartTurn: AAAAA MOTHERLAND!!! carried out on [" .. pNukeCity:GetName() .. "]")
									pUnit:PushMission(MissionTypes.MISSION_NUKE, pNukePlot:GetX(), pNukePlot:GetY(), 0, 0, 1)
								end
							end
						end
					end
				end
			end
		end
	end

	-- Barbarian Major Civ turn (default only)
	if IsBarbMajorCiv(iPlayer) and IsDefaultBarbMajorCiv() then
		local iSettlerCount = 0

		-- WAR LOOP
		AssertBarbarianStateOfWar()

		-- units, pass 1
		BarbEvolvedUnitUpgradePass(iPlayer)

		-- units, pass 2
		print("BarbEvolvedCivStartTurn: Iterating [" .. pPlayer:GetNumUnits() .. "] Barbarian MAJOR units...")
		for pUnit in pPlayer:Units() do
			-- apply promotions
			if pUnit ~= nil then
				BarbEvolvedUnitPromotions(pUnit)

				if (pUnit:GetUnitType() == GameInfoTypes.UNIT_SETTLER) then
					iSettlerCount = iSettlerCount + 1
				end
			end
		end

		-- technology inheritance
		BarbInheritTech(iPlayer)

		-- If the camps have spawned and the major civ is in game, give them a starter city (because they don't start with a settler)
		if (Game.GetElapsedGameTurns() > 0) and (Game.GetElapsedGameTurns() < 10) then
			-- try evolving a camp
			if (pPlayer:GetNumCities() == 0) then
				local halfera = math.floor(Game.GetCurrentEra() / 2)

				-- ancient/classical = 1, med/ren = 2, industrial/modern 3, etc 4 initial evolutions
				print("BarbEvolvedCivStartTurn: Spawning [" .. (halfera + 1) .. "] starting cities for Barbarian MAJOR civ...")

				for i = 0, halfera, 1 do
					Evolve()
				end
			end
			-- did evolution fail (ie. are Barbarians turned off?) if so "evolve" at starting plot
			if (pPlayer:GetNumCities() == 0) then
				print("BarbEvolvedCivStartTurn: No encampments?  Creating a city at starting plot...")
				-- pPlayer:Found(pPlayer:GetStartingPlot():GetX(), pPlayer:GetStartingPlot():GetY())
				FoundCity(pPlayer, pPlayer:GetStartingPlot():GetX(), pPlayer:GetStartingPlot():GetY())

				local pActivePlayer = Players[Game.GetActivePlayer()]
				local sTitle = "An " .. sBarbCampDefault .. " has evolved!"
				local sText = "A " .. sBarbAdjDefault .. " " .. sBarbCampDefault .. " has evolved into a city, adding to the ranks of " .. pPlayer:GetCivilizationDescription() .. "!"

				-- override if we are using renaming and have reached at least the first period-appropriate array element
				if bBarbEraNameChange and (iMinEraId > -1) then
					sTitle = "A " .. arrBarbNames[iMinEraId][5] .. " has evolved!"
					sText = "A " .. arrBarbNames[iMinEraId][2] .. " " .. arrBarbNames[iMinEraId][5] .. " has evolved into a city, adding to the ranks of " .. arrBarbNames[iMinEraId][3] .. "!"
				end

				print("BarbEvolvedCivStartTurn: sending out notification")
				pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, thisx, thisy)
			end
		end

		-- policies
		BarbEvolvedPolicyWindback(iPlayer)

		-- force them to have enough gold to pay the bills (after garrison spawns)
		if (pPlayer:CalculateGoldRate() < 0) and ((pPlayer:CalculateGrossGold() + pPlayer:CalculateGoldRate()) < 0) then
			local iGoldVal = -(pPlayer:CalculateGoldRate()) + 1
			-- force them to have enough gold to pay the bills (after garrison spawns)
			print("BarbEvolvedCivStartTurn: Setting gold to [" .. iGoldVal .. "]")
			pPlayer:SetGold(iGoldVal)
		end

		-- cities
		print("BarbEvolvedCivStartTurn: Iterating [" .. pPlayer:GetNumCities() .. "] Barbarian MAJOR cities...")
		for pCity in pPlayer:Cities() do

			if pCity ~= nil then
				BarbEvolvedGarrisonCheck(pPlayer, pCity, iTeamTechs)

				-- Auto-build a Courthouse in all major barb cities
				if not pCity:IsHasBuilding(GameInfoTypes.BUILDING_BARBARIAN_PRESENCE) then
					pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_BARBARIAN_PRESENCE, 1)
				end
			end
		end

		-- 'water walking' unit rendering fix
		-- thanks /u/ModularDoktor
		Teams[pPlayer:GetTeam()]:UpdateEmbarkGraphics()
	end

	-- Barbarian Minor Civ (63)
	if IsBarbNPCs(iPlayer) then
		-- strings
		print("BarbEvolvedCivStartTurn: Checking if deferred text refresh is pending...")

		CompleteBarbarianNameChange()

		-- units, pass 1
		BarbEvolvedUnitUpgradePass(iPlayer)

		-- units, pass 2
		print("BarbEvolvedCivStartTurn: Iterating [" .. pPlayer:GetNumUnits() .. "] Barbarian NPC units...")
		for pUnit in pPlayer:Units() do
			if pUnit ~= nil then
				local pPlot = pUnit:GetPlot()
				local iPlotOwner = pPlot:GetOwner()

				BarbEvolvedUnitPromotions(pUnit)

				-- Heal if in their own lands, their ally's lands, or an encampment (if settings allow)
				if (IsBarbaricCiv(iPlotOwner) or (pPlot:GetImprovementType() == GameInfoTypes.IMPROVEMENT_BARBARIAN_CAMP)) then
					if not bDisableBarbHealing then
						-- print("Barbarian unit in camp or Barbarian lands; healing for 10 hp...")
						pUnit:ChangeDamage(-(GameDefines.MAX_HIT_POINTS / 10), iBarbNPCs)
					end
				end

				-- Change ownership if unit is in city state lands and Barbarians evolve into City States
				if (iPlotOwner ~= -1) then
					if bBarbEvolveCityStates and Players[iPlotOwner]:IsMinorCiv() then
						-- save and delete the old
						iNewX = pUnit:GetX()
						iNewY = pUnit:GetY()
						iNewType = pUnit:GetUnitType()
						pUnit:Kill()
						-- create the new
						Players[iPlotOwner]:InitUnit(iNewType, iNewX, iNewY, GameInfo.UnitAIInfos[GameInfo.Units[iNewType].DefaultUnitAI].ID)
					end
				end
			end
		end

		-- cities
		print("BarbEvolvedCivStartTurn: Iterating [" .. pPlayer:GetNumCities() .. "] Barbarian NPC cities...")
		for pCity in pPlayer:Cities() do

			if pCity ~= nil then
				BarbEvolvedGarrisonCheck(pPlayer, pCity, iTeamTechs)

				-- Auto-build a Courthouse in all minor barb cities
				if not pCity:IsHasBuilding(GameInfoTypes.BUILDING_BARBARIAN_PRESENCE) then
					pCity:SetNumRealBuilding(GameInfoTypes.BUILDING_BARBARIAN_PRESENCE, 1)
				end
			end
		end

		-- plots
		if not bDisableSponsoredSpawns then
			print("BarbEvolvedCivStartTurn: Iterating [" .. Map.GetNumPlots()-1 .. "] plots for Encampments...")
			for iPlotLoop = 0, Map.GetNumPlots()-1, 1 do
				local pPlot = Map.GetPlotByIndex(iPlotLoop)

				if (pPlot:GetImprovementType() == GameInfoTypes.IMPROVEMENT_EVOLVED_CAMP) then
					if (pPlot:GetWorkingCity() == nil) then
						-- valid camp, check if can spawn
						if (pPlot:GetUnit(0) == nil) then
							-- camp empty
							BarbEvolvedPlotCheck(pPlayer, pPlot, iTeamTechs)
						else
							if IsBarbaricCiv(pPlot:GetUnit(0):GetOwner()) then
								-- camp occupied by Barbarians
								BarbEvolvedPlotCheck(pPlayer, pPlot, iTeamTechs)
							end
						end
					else
						-- don't convert evolved camps placed on starting plots (for CS evolved) unless the plot is owned
						if bBarbEvolveCityStates and pPlot:IsStartingPlot() and (pPlot:GetOwner() == -1) then
							print("BarbEvolvedCivStartTurn: Invalid sponsored camp at (" .. pPlot:GetX() .. ", " .. pPlot:GetY() .. ") overlooked because it rests on an unowned starting plot.")
						else
							-- invalid camp, convert
							print("BarbEvolvedCivStartTurn: Sponsored camp at (" .. pPlot:GetX() .. ", " .. pPlot:GetY() .. ") is too close to a city and/or the plot has an owner; converting it to a fort.")
							pPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_FORT)

							-- notify the active player of the conversion if the active player owns the nearby city
							if (Game.GetActivePlayer() == pPlot:GetWorkingCity():GetOwner()) then
								local pActivePlayer = Players[Game.GetActivePlayer()]
								local sTitle = "State-Sponsored " .. sBarbCampDefault .. " shuts down!"
								local sText = "The encroachment of civilization has caused a State-Sponsored " .. sBarbCampDefault .. " of " .. sBarbShortDefault .. " to shut down!  The fortification is converted and will no longer spawn Barbarians."

								-- override if we are using renaming and have reached at least the first period-appropriate array element
								if bBarbEraNameChange and (iMinEraId > -1) then
									sTitle = "State-Sponsored " .. arrBarbNames[iMinEraId][5] .. " shuts down!"
									sText = "The encroachment of civilization has caused a State-Sponsored " .. arrBarbNames[iMinEraId][5] .. " of " .. arrBarbNames[iMinEraId][4] .. " to shut down!  The fortification is converted and will no longer spawn " .. arrBarbNames[iMinEraId][4] .. "!"
								end

								print("BarbEvolvedCivStartTurn: sending out notification")
								pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, pPlot:GetX(), pPlot:GetY())
							end
						end
					end
				end
			end
		else
			print("BarbEvolvedCivStartTurn: Skipping map plot iteration...")
		end

		-- faith (fixes pantheon crash bug)
		if isUsingBNW or isUsingGNK then
			if (pPlayer:GetFaith() > 0) then
				print("BarbEvolvedCivStartTurn: Setting faith to zero.")
				pPlayer:SetFaith(0)
			end
		end

		-- culture
		if (pPlayer:GetJONSCulture() > 0) then
			pPlayer:ChangeJONSCulture(-(pPlayer:GetJONSCulture()))
			print("BarbEvolvedCivStartTurn: Setting culture to zero.")
		end

		-- policies
		BarbEvolvedPolicyWindback(iPlayer)

		-- force them to have enough gold to pay the bills (after garrison spawns)
		if (pPlayer:CalculateGoldRate() < 0) and ((pPlayer:CalculateGrossGold() + pPlayer:CalculateGoldRate()) < 0) then
			local iGoldVal = -(pPlayer:CalculateGoldRate()) + 1
			print("BarbEvolvedCivStartTurn: Setting gold to [" .. iGoldVal .. "]")
			pPlayer:SetGold(iGoldVal)
		end

		-- If the turn number is evenly divisible by iTurnsPerBarbEvolution, give them a city
		if (math.fmod(Game.GetElapsedGameTurns(), iTurnsPerBarbEvolution) == 0) and (Game.GetElapsedGameTurns() > 5) and not bDisableBarbEvolution then
			print("BarbEvolvedCivStartTurn: Time to spawn a free Barbarian city!")
			Evolve()
		end

		-- 'water walking' unit rendering fix
		-- thanks /u/ModularDoktor
		Teams[pPlayer:GetTeam()]:UpdateEmbarkGraphics()
	end

	-- Delete any dummy civ cities as soon as they are liberated to their original owners, regardless of size
	if isUsingDummyCiv then
		if (iPlayer == iDummyCiv) then
			if bBarbDisperseOnLiberate then
				for pCity in pPlayer:Cities() do
					print("BarbEvolvedCivStartTurn: Disbanding Liberation civ city [" .. pCity:GetName() .. "] due to settings.")
					pPlayer:Disband(pCity)
				end
			end
		end
	end

--	print("-------------------- " .. pPlayer:GetName() .. " [" .. iPlayer .. "] Turn [" .. Game.GetElapsedGameTurns() .. "] END --------------------")
	-- print("BarbEvolvedCivStartTurn exit")
end

--########################################################################
-- Wrapper for pPlayer:Found that alternatively pops a settler
-- params: playerobj, x-coord, y-coord, t/f boolean; returns settler unit or nil
function FoundCity(owner, x, y)
	if bBarbEvolveSettlers then
		print("FoundCity: spawning settler at [" .. x .. "], [" .. y .. "]")
		newsettler = owner:InitUnit(GameInfoTypes.UNIT_SETTLER, x, y, UNITAI_SETTLE)
		if (newsettler ~= nil) then
			print("FoundCity: pushing found city mission to settler...")
			newsettler:PushMission(MissionTypes.MISSION_FOUND, x, y, 0, 0, 1)
		else
			print("FoundCity: settler object nil after spawning!")
		end
	else
		print("FoundCity: instantly founding city at [" .. x .. "], [" .. y .. "]")
		-- owner:Found(x, y)
		newcity = owner:InitCity(x, y)
	end

	if (Game.GetActivePlayer() == owner:GetID()) then
		UI.LookAt(Map.GetPlot(x, y))
	end
end

--########################################################################
-- Evolution
function Evolve()
	-- evolve a city state
	if bBarbEvolveCityStates then
		if EvolveCityState() then
			return
		else
			print("Evolve: Failed to evolve any City State - evolving Barbarian city.")
		end
	end

	-- evolve a Barbarian city
	if isUsingBarbarianCiv then
		EvolveDistantEncampment(iBarbMajorCiv, nil)
	else
		EvolveDistantEncampment(iBarbNPCs, nil)
	end
end

--########################################################################
-- Clear the city plot of all life
function ClearCityPlot(pCleanse)
	print("ClearCityPlot: Clearing city plot.")
	local pCleansePlot = pCleanse:Plot()
					
	for plotUnit = 0, pCleansePlot:GetNumUnits(), 1 do
		local pCleansePlotUnit = pCleansePlot:GetUnit(plotUnit)
		if pCleansePlotUnit ~= nil then
			pCleansePlotUnit:Kill()
		end
	end
end

--########################################################################
-- Creates a size/territory template based on major civilization capitals
-- Returns two variables (must be declared prior to call)
-- iLowestCapSize		- the size of the smallest capital
-- iLowestCultureLevel	- the cultural tier of the smallest capital
function GetTemplateCityValues(iForCiv)
	local iLCS = 1
	local iLCL = 1

	print("GetTemplateCapValues: Templating for civ ID [" .. iForCiv .. "].")

	-- iterate all majors
	for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
		-- if we're templating for a Barbarian city consider every capital otherwise skip the Barbarian capital
		if IsBarbaricCiv(iForCiv) or not IsBarbaricCiv(i) then
			local pMajorCiv = Players[i]
			-- does it have a capital city
			if (pMajorCiv ~= nil) then
				-- gather stats on weakest capital
				if (pMajorCiv:GetCapitalCity() ~= nil) then
					local iThisCapSize = pMajorCiv:GetCapitalCity():GetPopulation()
					local iThisCultureLevel = pMajorCiv:GetCapitalCity():GetJONSCultureLevel()

					if (iThisCapSize < iLCS) or (iLCS == 1) then
						iLCS = iThisCapSize
					end
					if (iThisCultureLevel < iLCL) or (iLCL == 1) then
						iLCL = iThisCultureLevel
					end
				end
			end
		end
		-- if we're templating for a Barbarian city consider the Tribal Barbarian capital too just in case
		if IsBarbaricCiv(iForCiv) then
			local pMajorCiv = Players[iBarbNPCs]

			-- does it have a capital city
			if (pMajorCiv ~= nil) then
				-- gather stats on weakest capital
				if (pMajorCiv:GetCapitalCity() ~= nil) then
					local iThisCapSize = pMajorCiv:GetCapitalCity():GetPopulation()
					local iThisCultureLevel = pMajorCiv:GetCapitalCity():GetJONSCultureLevel()

					if (iThisCapSize < iLCS) or (iLCS == 1) then
						iLCS = iThisCapSize
					end
					if (iThisCultureLevel < iLCL) or (iLCL == 1) then
						iLCL = iThisCultureLevel
					end
				end
			end
		end
	end

	-- iterate Tribal Barbarians just in case they have a capital

	print("GetTemplateCapValues: Determined template values --> lowest size [" .. iLCS .."] and lowest culture level [" .. iLCL .. "].")
	return iLCS, iLCL
end

--########################################################################
-- Jumpstart a city by setting its...
-- 1. Size
-- 2. Territory
-- 3. Food (to prevent starvation)
-- 4. Spawn a worker
-- 5. Spawn a garrison
function JumpstartCity(pJumpOwner, pJumpCity)

	if (pJumpOwner == nil) then
		print("JumpstartCity: pJumpOwner is nil.")
		return
	end

	if (pJumpCity == nil) then
		print("JumpstartCity: pJumpCity is nil.")
		return
	end

	local iJumpOwner = pJumpOwner:GetID()
	local pJumpPlot = pJumpCity:Plot()
	local jumpx = pJumpPlot:GetX()
	local jumpy = pJumpPlot:GetY()

	print("JumpstartCity: Jump starting [" .. pJumpCity:GetName() .. "]")

	local iCurrentCultureLevel = pJumpCity:GetJONSCultureLevel()
	print("JumpstartCity: Current size [" .. pJumpCity:GetPopulation() .. "] and culture level [" .. iCurrentCultureLevel .. "].")

	local iLowestCapSize, iLowestCultureLevel = GetTemplateCityValues(iJumpOwner)
	print("JumpstartCity: Jumpstarting city to size [" .. iLowestCapSize .."] and culture level [" .. iLowestCultureLevel .. "].")

	-- set size
	pJumpCity:SetPopulation(iLowestCapSize, true)

	-- buy up land
	for i = iCurrentCultureLevel, iLowestCultureLevel - 1, 1 do
		pJumpCity:DoJONSCultureLevelIncrease()
	end

	-- set food (to stave off instant starvation)
	print("JumpstartCity: Setting food to GrowthThreshold - 1 ...")
	pJumpCity:SetFood(pJumpCity:GrowthThreshold() - 1)

	if IsBarbaricCiv(iJumpOwner) then
		-- barbarians don't get any perks
		print("JumpstartCity: Skipped worker/defensive unit spawn because city is Barbaric.")
	else
		-- spawn a free worker
		print("JumpstartCity: Attempting to spawn worker...")
		pJumpOwner:InitUnit(GameInfoTypes.UNIT_WORKER, jumpx, jumpy, UNITAI_WORKER)

		-- spawn free garrison units
		local iJCTechs = Teams[pJumpOwner:GetTeam()]:GetTeamTechs():GetNumTechsKnown()
		print("JumpstartCity: Attempting to spawn [" .. iLowestCultureLevel - iCurrentCultureLevel .. "] defensive units, using Barbarian unit selection methodology...")
		for j = iCurrentCultureLevel, iLowestCultureLevel - 1, 1 do
			local retID = BarbUnitHeirarchy(pJumpOwner, pJumpPlot, iJCTechs)

			if retID ~= "-1" then
				pJumpOwner:InitUnit(retID, jumpx, jumpy, GameInfo.UnitAIInfos[GameInfo.Units[retID].DefaultUnitAI].ID)
			else
				print("JumpstartCity: A garrison unit of that type can be trained. Spawn aborted.")
			end
		end
	end

	print("JumpstartCity: Jump start complete.")
end

--########################################################################
-- Create a city state.
function EvolveCityState()
	local bFoundCamp = false
	local pActivePlayer = Players[Game.GetActivePlayer()]

	-- loop all city states and spawn in sequence
	for iCityState = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
		local pCityState = Players[iCityState]
		local pPlot = pCityState:GetStartingPlot()

		if (pPlot ~= nil) then
			local thisx = pPlot:GetX()
			local thisy = pPlot:GetY()

			if not bFoundCamp then
				if pCityState:IsMinorCiv() and (pCityState:GetNumCities() == 0) then
					-- check for state-sponsored Encampment on their starting plot
					-- don't bother trying to evolve on a plot that is owned by any civ
					print("EvolveCityState: Evaluating (" .. thisx .. "," .. thisy .. "), the starting plot of [" .. pCityState:GetName() .. "]")
					if (pPlot:GetImprovementType() == GameInfoTypes.IMPROVEMENT_EVOLVED_CAMP) and (pPlot:GetOwner() == -1) and pCityState:CanFound(thisx, thisy) then
						print("EvolveCityState: Found an encampment on the unowned starting plot of [" .. pCityState:GetName() .. "] - pillaging improvement and evolving here...")
						bFoundCamp = true
						-- pillaging should remove it
						pPlot:SetImprovementPillaged(true)
						FoundCity(pCityState, thisx, thisy)
					else
						print("EvolveCityState: Invalid site - no encampment, plot is owned, or CanFound returned false.  Moving on...")
					end
				end
				-- inherit technologies and perform notification
				if bFoundCamp then
					-- print("EvolveCityState: disabling BarbEvolvedCantReachEra event hook.")
					-- GameEvents.TeamSetHasTech.Remove(BarbEvolvedCantReachEra);
					print("EvolveCityState: inheriting technologies from Tribal Barbarians.")
					BarbInheritTech(iCityState)
					-- print("EvolveCityState: re-enabling BarbEvolvedCantReachEra event hook.")
					-- GameEvents.TeamSetHasTech.Add(BarbEvolvedCantReachEra);

					-- did we successfully evolve a city?
					if (pCityState:GetNumCities() > 0) then
						local pCity = pCityState:GetCapitalCity()
						ClearCityPlot(pCity)
						JumpstartCity(pCityState, pCity)

						-- notify
						local sTitle = "An " .. sBarbCampDefault .. " has evolved!"
						local sText = "A " .. sBarbAdjDefault .. " " .. sBarbCampDefault .. " has evolved into the city of " .. pCity:GetName() .. "!"

						-- override if we are using renaming and have reached at least the first period-appropriate array element
						if bBarbEraNameChange and (iMinEraId > -1) then
							sTitle = "A " .. arrBarbNames[iMinEraId][5] .. " has evolved!"
							sText = "A " .. arrBarbNames[iMinEraId][2] .. " " .. arrBarbNames[iMinEraId][5] .. " has evolved into the city of " .. pCity:GetName() .. "!"
						end

						print("EvolveCityState: sending out notification")
						pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, thisx, thisy)

						print("EvolveCityState exiting true")
						return true
					else
						print("EvolveCityState: bFoundCamp is true but no city was founded.  What just happened?")
					end
				end
			end
		end
	end

	print("EvolveCityState exiting false")
	return false
end

--########################################################################
-- Create a city for a given player id.  Pop it on the Encampment furthest away from all capital cities.
function EvolveDistantEncampment(inplayer, inunit)
	local pBarbNPC = Players[iBarbNPCs]
	local pRecipient = Players[inplayer]
	local iCapitalsFound = 0

	print("EvolveDistantEncampment called for [" .. inplayer .. "]")

	if (pBarbNPC ~= nil) then
		-- build array of major civ capital cities
		local arrCapitals = {}
		print("EvolveDistantEncampment: Using major capitals...")
		for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
			local pPlayer = Players[i]
			-- print("EvolveDistantEncampment: Iterating Players[" .. i .. "]")
			if (pPlayer ~= nil) then
				if pPlayer:IsAlive() then
					if (pPlayer:GetNumCities() ~= 0) then
						table.insert(arrCapitals, pPlayer:GetCapitalCity():Plot():GetX(), pPlayer:GetCapitalCity():Plot():GetY())
						iCapitalsFound = iCapitalsFound + 1
					else
						-- print("EvolveDistantEncampment: Detected living civilization with no cities?")
					end
				else
					-- print("EvolveDistantEncampment: Civilization is dead or major Barbs?")
				end
			else
				-- print("EvolveDistantEncampment: Civilization pointer is nil for player?")
			end
		end
		-- what if no majors are found? niche case, I know.. then use city state capitals
		if (iCapitalsFound == 0) then
			print("EvolveDistantEncampment: No major capitals?  Using city states...")
			for i = 0, iBarbNPCs - 1, 1 do
				local pPlayer = Players[i]
				-- print("EvolveDistantEncampment: Iterating Players[" .. i .. "]")
				if (pPlayer ~= nil) then
					if pPlayer:IsAlive() then
						if (pPlayer:GetNumCities() ~= 0) then
							table.insert(arrCapitals, pPlayer:GetCapitalCity():Plot():GetX(), pPlayer:GetCapitalCity():Plot():GetY())
							iCapitalsFound = iCapitalsFound + 1
						else
							-- print("EvolveDistantEncampment: Detected living civilization with no cities?")
						end
					else
						-- print("EvolveDistantEncampment: Civilization is dead or major Barbs?")
					end
				else
					-- print("EvolveDistantEncampment: Civilization pointer is nil for player?")
				end
			end
		end
		-- what if there's no city states, too? very unlikely.. then use coords (1, 1)
		if (iCapitalsFound == 0) then
			print("EvolveDistantEncampment: No minors either.. failing over to (1, 1)")
			table.insert(arrCapitals, 1, 1)
			iCapitalsFound = iCapitalsFound + 1
		end

		-- calculate which Encampment is furthest from all checkpoints in array
		local foundCamp = false
		local thisx = 1
		local thisy = 1
		-- first choice
		local firstChoiceCamp = false
		local firstDist = 0
		local firstx = 1
		local firsty = 1
		-- second choice
		local secondChoiceCamp = false
		local secondDist = 0
		local secondx = 1
		local secondy = 1
		-- third choice
		local thirdChoiceCamp = false
		local thirdDist = 0
		local thirdx = 1
		local thirdy = 1
		
		-- the only way to find the camps is to go through every Barb unit, some of which should be fortified on a camp tile (ugh)
		for pUnit in pBarbNPC:Units() do
			local thisDist = 0
			local currDist = 0
			local areaCount = 0
			local tooClose = false
			local tooMany = false
			local tooFew = false

			if pUnit ~= nil then
				pPlot = pUnit:GetPlot()

				if (pPlot:GetImprovementType() == GameInfoTypes.IMPROVEMENT_BARBARIAN_CAMP) or (pPlot:GetImprovementType() == GameInfoTypes.IMPROVEMENT_EVOLVED_CAMP) then
					-- iterate all checkpoints
					for x, y in pairs(arrCapitals) do
						thisDist = Map.PlotDistance(pPlot:GetX(), pPlot:GetY(), x, y)
						currDist = currDist + thisDist

						-- is it too close to a capital?
						if (thisDist <= GameDefines.BARBARIAN_CAMP_MINIMUM_DISTANCE_CAPITAL) then
							tooClose = true
						end

						if (pPlot:Area():GetNumCities() == 0) then
							tooFew = true
						end

						for pRecipientCity in pRecipient:Cities() do
							if pRecipientCity ~= nil then
								-- is this barb city in the same area/continent as this encampment?
								if (pRecipientCity:Plot():Area() == pPlot:Area()) then
									tooMany = true
								end
							end
						end
					end

					-- Avoid Encampments that:
					-- first choice only: are on continents that already have a barbarian city (tooMany)
					-- first and second choice: are on empty continents (tooFew)
					-- all: are too close to capitals/checkpoints (tooClose)
					-- all: are illegal sites for a city
					-- all: don't beat the best case
					if (pRecipient:CanFound(pPlot:GetX(), pPlot:GetY()) and not tooClose) then
						if (currDist > firstDist) and not tooFew and not tooMany then
							firstChoiceCamp = true
							firstDist = currDist
							firstx = pPlot:GetX()
							firsty = pPlot:GetY()
						elseif (currDist > secondDist) and not tooFew then
							secondChoiceCamp = true
							secondDist = currDist
							secondx = pPlot:GetX()
							secondy = pPlot:GetY()
						elseif (currDist > thirdDist) then
							thirdChoiceCamp = true
							thirdDist = currDist
							thirdx = pPlot:GetX()
							thirdy = pPlot:GetY()
						end
					end
				end
			end
		end
		-- fallback logic
		print("EvolveDistantEncampment: testing first choice...")
		foundCamp = firstChoiceCamp
		thisx = firstx
		thisy = firsty

		if not foundCamp then
			print("EvolveDistantEncampment: first choice fails, failing over to second choice...")
			foundCamp = secondChoiceCamp
			thisx = secondx
			thisy = secondy
		end

		if not foundCamp then
			print("EvolveDistantEncampment: second choice fails, failing over to third choice...")
			foundCamp = thirdChoiceCamp
			thisx = thirdx
			thisy = thirdy
		end

		-- plant the city
		if foundCamp then
			local iCityCountBefore = pRecipient:GetNumCities()

			print("EvolveDistantEncampment: Found at least one valid campsite")

			if pRecipient:CanFound(thisx, thisy) then
				print("EvolveDistantEncampment: Spawning city at [" .. thisx .. "] [" .. thisy .. "]")
				if (isUsingDummyCiv and Players[iDummyCiv]:IsEverAlive() and not IsBarbMajorCiv(iDummyCiv) and iCityCountBefore > 0 and inplayer ~= Game.GetActivePlayer()) then
				-- if (isUsingDummyCiv and Players[iDummyCiv]:IsEverAlive()) then
					print("EvolveDistantEncampment: Liberation civ exists - spawning under the ownership of the Liberation civ then acquiring to recipient...")
					-- Players[iDummyCiv]:Found(thisx, thisy)
					FoundCity(Players[iDummyCiv], thisx, thisy)
					local pNewCityPlot = Map.GetPlot(thisx, thisy)
					local pNewCity = pNewCityPlot:GetPlotCity()
					if (pNewCity ~= nil) then
						pRecipient:AcquireCity(pNewCity, true, false)
						-- annex it immediately
						if IsBarbaricCiv(inplayer) then
							pNewCity:SetPuppet(false)
						end
					else
						print("EvolveDistantEncampment: FoundCity() call for Liberation civ must have failed or been delayed (null city pointer from plot)!")
					end
				else
					print("EvolveDistantEncampment: Capital city, human Barbarian or no Liberation civ ingame - spawning city under the direct ownership of the recipient...")
					-- pRecipient:Found(thisx, thisy)
					FoundCity(pRecipient, thisx, thisy)
				end
			else
				print("EvolveDistantEncampment: CanFound returned false, prevented crash?")
			end

			local iCityCountAfter = pRecipient:GetNumCities()

			if (iCityCountBefore ~= iCityCountAfter) then
				local pCity = Map.GetPlot(thisx, thisy):GetPlotCity()
				ClearCityPlot(pCity)
				JumpstartCity(pRecipient, pCity)

				local pActivePlayer = Players[Game.GetActivePlayer()]
				local sTitle = "An " .. sBarbCampDefault .. " has evolved!"
				local sText = "A " .. sBarbAdjDefault .. " " .. sBarbCampDefault .. " has evolved into a city, adding to the ranks of " .. pRecipient:GetCivilizationDescription() .. "!"

				-- override if we are using renaming and have reached at least the first period-appropriate array element
				if bBarbEraNameChange and (iMinEraId > -1) then
					sTitle = "A " .. arrBarbNames[iMinEraId][5] .. " has evolved!"
					sText = "A " .. arrBarbNames[iMinEraId][2] .. " " .. arrBarbNames[iMinEraId][5] .. " has evolved into a city, adding to the ranks of " .. arrBarbNames[iMinEraId][3] .. "!"
				end

				print("EvolveDistantEncampment: sending out notification")
				pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, thisx, thisy)

				if (inunit ~= nil) then
					print("EvolveDistantEncampment: A unit was harmed in the making of this city :)")
					inunit:Kill()
				end

				print("EvolveDistantEncampment exiting true")
				return true
			else
				print("EvolveDistantEncampment: Failed to spawn city - founding failed!")
			end
		else
			print("EvolveDistantEncampment: Failed to spawn city - all options failed.  Are there no valid Encampments to serve as city sites?")
		end
	end

	print("EvolveDistantEncampment exiting false")
	return false
end

--########################################################################
-- force reload text strings
function RefreshText()
	local pActivePlayer = Players[Game.GetActivePlayer()]
	local iLastEraId = iMinEraId - 1

	-- notify of each evolution after the first
	if (iMinEraId > 1) then
		sTitle = arrBarbNames[iLastEraId][4] .. " evolve into " .. arrBarbNames[iMinEraId][4] .. "!"
		sText = arrBarbNames[iLastEraId][4] .. " have begun calling themselves " .. arrBarbNames[iMinEraId][4] .. " and embrace the cause of " .. arrBarbNames[iMinEraId][3] .. "!"

		print("RefreshText: sending out notification")
		pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle, 0, 0)
	end

	Locale.SetCurrentLanguage( Locale.GetCurrentLanguage().Type )
end

--########################################################################
-- This function is from Leuigi's Barbarian Inmersion mod...

function SetComplexStrings(adj, descr, plural, camp)
	local pBarbNPC = Players[iBarbNPCs]

	--[[
	-- Plunder stuff
	plunder0 = "Filthy " .. plural .. "plundered the trade route you established between {1_CityName} and {2_CityName}.";
	plunder1 = plural .. " plundered the trade route {1_PlayerName} established between {2_CityName} and {3_CityName}";
	-- CS Quest stuff
	csquest0 = "We want you to defeat " .. plural .. " that are invading our territory."
	csquest1 = "They want you to defeat " .. adj .. " units that are invading their territory."
	csquest2 = "They will reward the player that destroys a nearby" .. camp
	csquest3 = "You have successfully destroyed the " .. camp .. " as requested by {1_MinorCivName:textkey}! Your [ICON_INFLUENCE] Influence over them has increased by [COLOR_POSITIVE_TEXT]{2_InfluenceReward}[ENDCOLOR]."
	csquest4 = "There is still that " .. camp .. " nearby that we would like someone to take care of."
	csquest5 = "They want a nearby " .. camp .. " destroyed.";
	csquest6 = "{1_CivName:textkey} requests your assistance against invading " .. plural .. "! Each " .. adj .. " you kill will earn you [ICON_INFLUENCE] Influence over the City-State.";
	csquest7 = "{1_CivName:textkey} no longer needs your assistance against" .. plural
	-- Killed near CS
	kill0 = "You have killed a group of " .. plural .. " near {1_CivName:textkey}! They are grateful, and your [ICON_INFLUENCE] Influence with them has increased by 12!";
	kill1 = adj .. " killed near {1_CivName:textkey}!";
	-- Raided
	raid0 = "Your City of {@1_CityName} was raided by " .. plural .. ", and {2_Num} Gold was stolen from the national treasury!";
	raid1 = descr .. " have killed your {@1_UnitName} because you refused to pay heed to their demands!";
	-- Encampment cleared
	clear0 = "You have dispersed a villainous " .. camp .. " and recovered {1_NumGold} [ICON_GOLD] Gold from it!";
	-- Civilian captured
	capture0 = "A civilian was captured by " .. plural
	capture1 = "{TXT_KEY_GRAMMAR_UPPER_A_AN << {@1_UnitName}} was captured by " .. plural .. "! They will take it to their nearest " .. camp .. ". If you wish to recover your unit you will have to track it down!";
	-- Discovered
	discover = "A " .. camp .. " has been discovered! It will create " .. adj .. " units until dispersed!"
	discover2 = camp .. " discovered";
	-----------------
	-- Update Table
	-----------------
	local tquery = {
			"UPDATE Language_en_US SET Text = '".. adj .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_ADJECTIVE'",
			"UPDATE Language_en_US SET Text = '".. descr .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_DESC'",
			"UPDATE Language_en_US SET Text = '".. plural .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_SHORT_DESC'",
			"UPDATE Language_en_US SET Text = '".. plural .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_MAJOR_SHORT_DESC'",
			"UPDATE Language_en_US SET Text = '".. camp .."' WHERE Tag = 'TXT_KEY_IMPROVEMENT_ENCAMPMENT'",
			"UPDATE Language_en_US SET Text = '".. plunder0 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_TRADE_UNIT_PLUNDERED_TRADER_BARBARIAN'",
			"UPDATE Language_en_US SET Text = '".. plunder1 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_TRADE_UNIT_PLUNDERED_TRADEE_BARBARIANS'",
			"UPDATE Language_en_US SET Text = '".. csquest0 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_INVADING_BARBS'",
			"UPDATE Language_en_US SET Text = '".. csquest1 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_INVADING_BARBS_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest2 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest3 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_QUEST_COMPLETE_KILL_CAMP'",
			"UPDATE Language_en_US SET Text = '".. csquest4 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP'",
			"UPDATE Language_en_US SET Text = '".. csquest5 .."' WHERE Tag = 'TXT_KEY_CITY_STATE_QUEST_KILL_CAMP_FORMAL'",
			"UPDATE Language_en_US SET Text = '".. csquest6 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARBS_QUEST'",
			"UPDATE Language_en_US SET Text = '".. csquest7 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARBS_QUEST_LOST_CHANCE'",
			"UPDATE Language_en_US SET Text = '".. discover .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_FOUND_BARB_CAMP'",
			"UPDATE Language_en_US SET Text = '".. kill0 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_MINOR_BARB_KILLED'",
			"UPDATE Language_en_US SET Text = '".. kill1 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_SM_MINOR_BARB_KILLED'" ,
			"UPDATE Language_en_US SET Text = '".. raid0 .."' WHERE Tag = 'TXT_KEY_MISC_YOU_CITY_RANSOMED_BY_BARBARIANS'",
			"UPDATE Language_en_US SET Text = '".. clear0 .."' WHERE Tag = 'TXT_KEY_MISC_DESTROYED_BARBARIAN_CAMP'" ,
			"UPDATE Language_en_US SET Text = '".. capture0 .."' WHERE Tag = 'TXT_KEY_UNIT_CAPTURED_BARBS'",
			"UPDATE Language_en_US SET Text = '".. capture1 .."' WHERE Tag = 'TXT_KEY_UNIT_CAPTURED_BARBS_DETAILED'",
			"UPDATE Language_en_US SET Text = '".. discover2 .."' WHERE Tag = 'TXT_KEY_NOTIFICATION_SUMMARY_FOUND_BARB_CAMP'"
			}
	]]--

	-- rewritten. select the strings used as "befores" so we can pattern match and replace

	-- adjective (adj)
	sql = "select Text from " .. sLanguageTable .. " where tag = 'TXT_KEY_CIV_BARBARIAN_ADJECTIVE'"
	for row in DB.Query(sql) do
		oldadj = row.Text
	end

	-- description (descr)
	sql = "select Text from " .. sLanguageTable .. " where tag = 'TXT_KEY_CIV_BARBARIAN_DESC'"
	for row in DB.Query(sql) do
		olddescr = row.Text
	end

	-- short description (plural)
	sql = "select Text from " .. sLanguageTable .. " where tag = 'TXT_KEY_CIV_BARBARIAN_SHORT_DESC'"
	for row in DB.Query(sql) do
		oldplural = row.Text
	end

	-- encampment (camp)
	sql = "select Text from " .. sLanguageTable .. " where tag = 'TXT_KEY_IMPROVEMENT_ENCAMPMENT'"
	for row in DB.Query(sql) do
		oldcamp = row.Text
	end

	-- Strings in SQL are case sensitive, so we have to be careful about this:
	-- globally replace plural first ("Barbarians") and downcased plural ("barbarians")
	-- then adjective ("Barbarism" or "Barbarian State") and downcased adjective
	-- then descr ("Barbarian") and downcased descr
	-- then camp ("Encampment") and downcased camp string
	-- lastly, update the strings used as the "befores", the strings used for tribal and the strings used for major barbs
    -- this should get us every instance in the entire database
	local tquery = {
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. oldplural .. "', '" .. plural .. "') where Text like '%" .. oldplural .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. string.lower(oldplural) .. "', '" .. string.lower(plural) .. "') where Text like '%" .. string.lower(oldplural) .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. oldadj .. "', '" .. adj .. "') where Text like '%" .. oldadj .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. string.lower(oldadj) .. "', '" .. string.lower(adj) .. "') where Text like '%" .. string.lower(oldadj) .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. olddescr .. "', '" .. descr .. "') where Text like '%" .. olddescr .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. string.lower(olddescr) .. "', '" .. string.lower(descr) .. "') where Text like '%" .. string.lower(olddescr) .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. oldcamp .. "', '" .. camp .. "') where Text like '%" .. oldcamp .. "%'",
					"UPDATE " .. sLanguageTable .. " set Text = replace(text, '" .. string.lower(oldcamp) .. "', '" .. string.lower(camp) .. "') where Text like '%" .. string.lower(oldcamp) .. "%'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. adj .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_ADJECTIVE'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. descr .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_DESC'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. plural .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_SHORT_DESC'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. adj .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_ADJECTIVE'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. descr .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_DESC'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. plural .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_SHORT_DESC'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. adj .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_MAJOR_ADJECTIVE'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. descr .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_MAJOR_DESC'",
					"UPDATE " .. sLanguageTable .. " SET Text = '".. plural .."' WHERE Tag = 'TXT_KEY_CIV_BARBARIAN_MAJOR_SHORT_DESC'"
					}

	for i, iQuery in pairs(tquery) do
		-- print ("Changing Barbarian Texts: " .. i .. "/" .. #tquery );
		for result in DB.Query(iQuery) do
		end
	end
end

--########################################################################
-- Change Barbarian Strings as Eras pass (PART 1)
function InitBarbarianNameChange(tech)
	local pBarbNPC = Players[iBarbNPCs]
	local strEra = GameInfo.Technologies[tech].Era

	if bBarbEraNameChange then
		-- print("InitBarbarianNameChange: Tech [" .. tech .. "], associated Era [" .. strEra .. "]")
	else
		-- disabled in settings; don't bother
		return
	end

	-- Note: this loop may skip the very last era (ERA_FUTURE)
	for i = 1, iMaxEraId, 1 do
		-- print("InitBarbarianNameChange: Updating using strings... [" .. arrBarbNames[i][1] .. "], [" .. arrBarbNames[i][2] .. "], [" .. arrBarbNames[i][3] .. "], [" .. arrBarbNames[i][4] .. "], [" .. arrBarbNames[i][5] .. "]")
		if (arrBarbNames[i][1] == strEra) then
			if (i > iMinEraId) then
				print("InitBarbarianNameChange: Tech [" .. tech .. "], associated Era [" .. strEra .. "]")
				print("InitBarbarianNameChange: Update required to text strings... [" .. arrBarbNames[i][1] .. "], [" .. arrBarbNames[i][2] .. "], [" .. arrBarbNames[i][3] .. "], [" .. arrBarbNames[i][4] .. "], [" .. arrBarbNames[i][5] .. "]")
				iMinEraId = i
				bBarbNamesChanged = true
			end
		end
	end
end

--########################################################################
-- Change Barbarian Strings as Eras pass (PART 2)
function CompleteBarbarianNameChange()
	if bBarbNamesChanged then
		-- issue refresh
		print("CompleteBarbarianNameChange: Updating texts and issuing refresh on [" .. sLanguageTable .. "].")
		SetComplexStrings(arrBarbNames[iMinEraId][2], arrBarbNames[iMinEraId][3], arrBarbNames[iMinEraId][4], arrBarbNames[iMinEraId][5])
		RefreshText()
		bBarbNamesChanged = false
	end
end

--########################################################################
-- Initialize Barbarian Gamestate (War/Peace)
function InitBarbMajorCiv()
	print("InitBarbMajorCiv: Setting up Barbarian teams ...")

	-- PEACE LOOP
	-- only do this if there is a major Barbarian in the game
	-- if isUsingBarbarianCiv or bBarbEvolveCityStates then
	if isUsingBarbarianCiv then
		for playerID = 0, iBarbNPCs - 1 do
			local player = Players[playerID]
			if player:IsAlive() then
				if IsBarbNPCs(playerID) then
					-- Minors, do nothing
				-- elseif IsBarbMajorCiv(playerID) or (player:IsMinorCiv() and bBarbEvolveCityStates) then
				elseif IsBarbMajorCiv(playerID) then
					if Teams[player:GetTeam()]:IsAlive() then
						-- Major Barbs or City State under "Barbs evolve into City States" rules, make peace with tribal
						if Teams[player:GetTeam()]:IsAtWar(Players[iBarbNPCs]:GetTeam()) then
							print("Setting PEACE between teams [" .. player:GetTeam() .. "] and [" .. Players[iBarbNPCs]:GetTeam() .. "].")
							Teams[player:GetTeam()]:MakePeace(Players[iBarbNPCs]:GetTeam())
						end
						Teams[player:GetTeam()]:SetPermanentWarPeace(Players[iBarbNPCs]:GetTeam(), true)
					end
				else
					-- Major non-Barb, do nothing this loop
				end
			end
		end
	end

	-- SET TEAMS
	-- if isUsingBarbarianCiv then
	--	print("Major Barbarians exist.  Moving minor Barbs to team [" .. Players[iBarbMajorCiv]:GetTeam() .. "].")
	--	PreGame.SetTeam(iBarbNPCs, Players[iBarbMajorCiv]:GetTeam())
	-- end

	-- WAR LOOP
	AssertBarbarianStateOfWar()

	-- Assert names (if not changing with the eras)
	if (bBarbEraNameChange == false) then
		print("InitBarbMajorCiv: Names will NOT be changing through the eras.  Performing one-time update of texts with refresh on [" .. sLanguageTable .. "].")
		SetComplexStrings(sBarbAdjDefault, sBarbDescrDefault, sBarbShortDefault, sBarbCampDefault)
		RefreshText()
	end

	print("InitBarbMajorCiv exiting.")
end

--########################################################################
-- Declare war on EVERYONE ELSE
-- Lock war state
function AssertBarbarianStateOfWar()
	-- only do this if using the default CIVILIZATION_BARBARIAN_MAJOR and they're in-game; other civs must handle this themselves.
	if isUsingBarbarianCiv and IsDefaultBarbMajorCiv() then
		-- print("AssertBarbarianStateOfWar: CIVILIZATION_BARBARIAN_MAJOR declares war on the entire world!")

		for playerID = 0, iBarbNPCs - 1 do
			local player = Players[playerID]
			if player:IsAlive() then
				-- if player:GetCivilizationType() == iBarbMajorCivID then
				if IsBarbNPCs(playerID) then
					-- Minors, do nothing
				elseif IsBarbMajorCiv(playerID) then
					-- Major Barbs, done in prevous loop
				-- elseif player:IsMinorCiv() and bBarbEvolveCityStates then
					-- City State under "Barbs evolve into City States" rules, do nothing
				else
					if Teams[player:GetTeam()]:IsAlive() then
						-- Have they met the Major Barbs?
						if Teams[player:GetTeam()]:IsHasMet(Players[iBarbMajorCiv]:GetTeam()) then
							-- They're alive, they've met the major non-Barb, so the Major Barb declares war on THEM
							if not Teams[player:GetTeam()]:IsAtWar(Players[iBarbMajorCiv]:GetTeam()) then
								print("Setting WAR between teams [" .. player:GetTeam() .. "] and [" .. Players[iBarbMajorCiv]:GetTeam() .. "].")
								Teams[Players[iBarbMajorCiv]:GetTeam()]:DeclareWar(player:GetTeam())
							end
							Teams[Players[iBarbMajorCiv]:GetTeam()]:SetPermanentWarPeace(player:GetTeam(), true)
						end
					end
				end
			end
		end
	end
end

--########################################################################
-- Initialize City States if option checked
function BarbEvolvedCityStates()
	-- NEW: Barbarians can evolve into City States
	if bBarbEvolveCityStates then
		print("BarbEvolvedCityStates: Barbarians are evolving into City States...")
		if (Game.GetElapsedGameTurns() == 0) then
			print("BarbEvolvedCityStates: Turn 0 setup.")
			-- turn 0; delete all city state settlers and replace with state-sponsored encampments
			for iCityState = 0, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
				pCityState = Players[iCityState]
				if pCityState:IsMinorCiv() and pCityState:IsAlive() then
					-- kill them off by killing off all units
					print("BarbEvolvedCityStates: Killing off City State [" .. pCityState:GetName() .. "] and placing a State-Sponsored Encampment on their starting plot.")
					for pUnit in pCityState:Units() do
						pUnit:Kill()
					end
					-- place state-sponsored Encampment on their starting plot
					pPlot = pCityState:GetStartingPlot()
					pPlot:SetImprovementType(GameInfoTypes.IMPROVEMENT_EVOLVED_CAMP)
				end
			end
		end
	end
end

--########################################################################
-- Count the number of a unit that the player has
function UnitCount(player, inUT)
	local pPlayer = Players[player]
	local iUnitCount = 0

	if (pPlayer == nil) then
		return
	end

	--[[
	for pUnit in pPlayer:Units() do
		if pUnit ~= nil then
			local iUnitType = pUnit:GetUnitType()

			if (iUnitType == inUT) then
				iUnitCount = iUnitCount + 1
			end
		end
	end
	]]--

	iUnitCount = pPlayer:GetUnitClassCountPlusMaking(inUT)

	-- print("Returning count of [" .. inUT .. "] for player [" .. player .. "] equal to [" .. iUnitCount .. "]");

	return iUnitCount
end

--########################################################################
-- Wrapper for unit bans
function BarbPlayersCantTrainSpecificUnits(player, unitType)
	return BarbEvolvedCantTrainSpecificUnits(player, unitType)
end

function BarbCitiesCantTrainSpecificUnits(player, city, unitType)
	return BarbEvolvedCantTrainSpecificUnits(player, unitType)
end

--########################################################################
-- Ban Barbarians from training workers, settlers and caravans/cargo ships (BNW only)
function BarbEvolvedCantTrainSpecificUnits(player, unitType)
	-- print("BarbEvolvedCantTrainSpecificUnits called")

	-- nobody can build the immobile settlers
	if (unitType == GameInfoTypes.UNIT_IMMOBILE_SETTLER) then
		-- print("BarbEvolvedCantTrainSpecificUnits ending false")
		return false
	end

	if IsBarbNPCs(player) and (unitType == GameInfoTypes.UNIT_WORKER) then
		-- print("BarbEvolvedCantTrainSpecificUnits ending false")
		return false
	end

	if IsBarbaricCiv(player) and (unitType == GameInfoTypes.UNIT_SETTLER) then
		-- print("BarbEvolvedCantTrainSpecificUnits ending false")
		return false
	end

	if IsBarbaricCiv(player) and (unitType == GameInfoTypes.UNIT_DIRTY_BOMB) then
		-- unit limit check
		if UnitCount(player, GameInfoTypes.UNITCLASS_ATOMIC_BOMB) >= iBarbNukeLimit then
			-- print("BarbEvolvedCantTrainSpecificUnits: Unit limit hit on UNIT_DIRTY_BOMB; hiding...")
			return false
		end
	end

	if IsBarbaricCiv(player) and (unitType == GameInfoTypes.UNIT_BARBARIAN_WORKER) then
		-- unit limit check
		if UnitCount(player, GameInfoTypes.UNITCLASS_WORKER) >= iBarbWorkerLimit then
			-- print("BarbEvolvedCantTrainSpecificUnits: Unit limit hit on UNIT_BARBARIAN_WORKER; hiding...")
			return false
		end
	end

	if UsingBNW then
		if IsBarbaricCiv(player) and ((unitType == GameInfoTypes.UNIT_CARGO_SHIP) or (unitType == GameInfoTypes.UNIT_CARAVAN)) then
			-- print("BarbEvolvedCantTrainSpecificUnits ending false")
			return false
		end
	end

	-- print("BarbEvolvedCantTrainSpecificUnits ending true")
	return true
end

--########################################################################
-- Ban Barbarians from building almost everything
function BarbEvolvedCantBuildStuff(player, city, buildingType)
	-- print("BarbsCantBuildStuff called")

	if IsBarbaricCiv(player) then
		-- print("BarbEvolvedCantBuildStuff: player [" .. player .. "] cityid [" .. city .. "] buildingtype [" .. buildingType .. "] buildingname [" .. GameInfo.Buildings[buildingType].Description .. "]")
		-- whitelist below:
		if ((buildingType ~= GameInfoTypes.BUILDING_MONUMENT)
		and (buildingType ~= GameInfoTypes.BUILDING_COURTHOUSE)
		and (buildingType ~= GameInfoTypes.BUILDING_BARRACKS)
		and (buildingType ~= GameInfoTypes.BUILDING_ARMORY)
		and (buildingType ~= GameInfoTypes.BUILDING_WALLS)
		and (buildingType ~= GameInfoTypes.BUILDING_CASTLE)) then
			-- print("BarbEvolvedCantBuildStuff ending false")
			return false
		else
			-- print("BarbEvolvedCantBuildStuff ending true")
			return true
		end
	end

	-- print("BarbEvolvedCantBuildStuff ending true")
	return true
end

--########################################################################
-- Check if Major Barb (playerid) should inherit a specific technological gain of the Barbarians
function BarbInheritSpecificTech(playerid, t)
	local pSource = Players[iBarbNPCs]
	local pSourceTechs = Teams[pSource:GetTeam()]:GetTeamTechs()
	local pDest = Players[playerid]
	local pDestTechs = Teams[pDest:GetTeam()]:GetTeamTechs()

	if IsBarbNPCs(playerid) then
		return
	end

	if pSourceTechs:HasTech(t) then
		if not pDestTechs:HasTech(t) then
			print("BarbInheritSpecificTech: Player [" .. playerid .. "] inheriting tech id [" .. t .. "] from Barbarians...")
			pDestTechs:SetHasTech(t, true)

			if (Game.GetActivePlayer() == playerid) then
				local sTitle = "Technology inherited: " .. Locale.Lookup(GameInfo.Technologies[t].Description)
				local sText = "Your allies have learned " .. Locale.Lookup(GameInfo.Technologies[t].Description) .. " through hostile encounters with civilization, and have passed that learning to you!"
				print("BarbInheritSpecifictech: sending out notification")
				pDest:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sText, sTitle)
			end
		end
	end
end

--########################################################################
-- The Major Barb (playerid) should inherit ALL the technological gains of the Barbarians
function BarbInheritTech(playerid)

	if IsBarbNPCs(playerid) then
		return
	end

	for i = 1, iMaxTechId, 1 do
		BarbInheritSpecificTech(playerid, i)
	end
end

--########################################################################
-- Return false if tech is post-modern
function BadEraTech(tech)
	bCantResearch = true

	if (GameInfo.Technologies[tech].Era == "ERA_ANCIENT") or
		(GameInfo.Technologies[tech].Era == "ERA_CLASSICAL") or
		(GameInfo.Technologies[tech].Era == "ERA_MEDIEVAL") or
		(GameInfo.Technologies[tech].Era == "ERA_RENAISSANCE") or
		(GameInfo.Technologies[tech].Era == "ERA_INDUSTRIAL") or
		(GameInfo.Technologies[tech].Era == "ERA_MODERN") then
		bCantResearch = false
	end

	return bCantResearch
end

--########################################################################
-- Ban Barbarians from passing the industrial era IFF BNW/ideologies
function BarbEvolvedTechWindback()
	local pPlayer = Players[iBarbNPCs]
	local pTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()

	-- if isUsingBarbarianCiv then
		-- major is getting the cities; no need to wind back
	--	return
	-- end

	for i = 1, iMaxTechId, 1 do
		if pTechs:HasTech(i) then
			-- check if global technological progression heralds a name change
			InitBarbarianNameChange(i)

			-- check if technological progression needs to be undone
			if isUsingBNW and (pPlayer:GetNumCities() > 0) then
				if BadEraTech(i) then
					print("BarbEvolvedTechWindback: Stripping tech id [" .. i .. "]")
					pTechs:SetHasTech(i, false)
				end
			end
		end
	end

	if not bDeferNameChange then
		CompleteBarbarianNameChange()
	end
end

--########################################################################
-- Hook for Events.SequenceGameInitComplete
function BarbEvolvedNPCPolicyWindback()
	BarbEvolvedPolicyWindback(iBarbNPCs)
end

--########################################################################
-- Ban Barbarians from adopting policies
function BarbEvolvedPolicyWindback(playerid)
	local pPlayer = Players[playerid]
	local iBarbPolicy = GameInfo.Policies["POLICY_BARBARIC"].ID

	-- Strip all policies if Barbarians (63); stops them getting deep into policy and crashing the game
	if (playerid == iBarbNPCs) then
		for i = 1, iMaxPolicyId, 1 do
			if pPlayer:HasPolicy(i) and (i ~= iBarbPolicy) then
				print("BarbEvolvedPolicyWindback: Stripping policy id [" .. i .. "]")
				pPlayer:SetHasPolicy(i, false)
			end
		end
	end

	-- Adopt the Barbarous policy, which helps with financial matters
	if IsBarbaricCiv(playerid) and not pPlayer:HasPolicy(iBarbPolicy) then
		print("BarbEvolvedPolicyWindback: Adopting policy id [" .. iBarbPolicy .. "]")
		pPlayer:SetHasPolicy(iBarbPolicy, true)
	end
end

--########################################################################
-- Ban Barbarians from all processes (wealth, research, etc)
function BarbEvolvedCantProcess(player, city, process)
    -- stop AI-driven Barbarians from engaging in processes, but allow human Barbarians to do them
	if IsBarbNPCs(player) and (Game.GetActivePlayer() ~= player) then
		return false
	end

	return true
end

--########################################################################
-- Ban Barbarians from passing the industrial era IFF BNW/ideologies
function BarbEvolvedCantReachEra(team, tech, adopted)
	local pPlayer = Players[iBarbNPCs]

	if (adopted == true) then
		print("BarbEvolvedCantReachEra: Team [" .. team .. "] acquires Tech [" .. tech .. "]")

		-- check if global technological progression heralds a name change
		InitBarbarianNameChange(tech)

		if not bDeferNameChange then
			CompleteBarbarianNameChange()
		end
	end

	-- if isUsingBarbarianCiv then
		-- major is getting the cities; no need to strip certain techs
		-- return
	-- end

	if (adopted == true) then
		-- check if technological progression needs to be undone
		if (pPlayer:GetTeam() == team) then
			-- trigger inheritence by major ally before potentially stripping tech
			if isUsingBarbarianCiv and IsDefaultBarbMajorCiv() then
				-- technology inheritance
				BarbInheritSpecificTech(iBarbMajorCiv, tech)
			end

			-- prevent Barb minors from reaching Era if they have at least 1 city
			if isUsingBNW and (pPlayer:GetNumCities() > 0) then
				if BadEraTech(tech) then
					local pTechs = Teams[pPlayer:GetTeam()]:GetTeamTechs()
					print("BarbEvolvedCantReachEra: Setting tech id [" .. tech .. "] back to false")
					pTechs:SetHasTech(tech, false)
				end
			end
		end
	end
end

--########################################################################
-- Wrapper for either/or Barbarian civ check
function IsBarbaricCiv(playerid)
	return (IsBarbMajorCiv(playerid) or IsBarbNPCs(playerid))
end

--########################################################################
-- Wrapper for major Barbarian civ (ally) check
function IsBarbMajorCiv(playerid)
	if isUsingBarbarianCiv then
		if (playerid == iBarbMajorCiv) then
			return true
		end
		return false
	else
		-- always false if not in game
		return false
	end
end

--########################################################################
-- Wrapper for major Barbarian civ USING DEFAULT check
function IsDefaultBarbMajorCiv()
	if sBarbMajorAlly == "CIVILIZATION_BARBARIAN_MAJOR" then
		return true
	else
		return false
	end
end

--########################################################################
-- Wrapper for "npcs" check
function IsBarbNPCs(playerid)
	if (playerid == iBarbNPCs) then
		return true
	end
	return false
end

--########################################################################
-- Detect active mods
-- Compatability addition by Xaragas from civfanatics
-- NO LONGER CALLED.
function UsingMods()
	local cbpdll = "d1b6328c-ff44-4b0d-aad7-c657f83610cd"
	local cbp = "8411a7a8-dad3-4622-a18e-fcc18324c799"
	local csd = "eead0050-1e3f-4178-a91f-26cf1881ac39"
	local whoward = "6da07636-4123-4018-b643-6575b4ec336b"
	local superpowers = "0e3482c6-f74a-4fca-ab3c-fb97036b08af"
	local dummyciv = "438a9930-1967-474f-a6b4-2be57c7deae0"
	local barbciv = "366d5c3d-663b-497c-91cf-f26692ceba11"
	
	for _, mod in pairs(Modding.GetActivatedMods()) do
		-- print(mod.ID)
		if (mod.ID == cbpdll) then
			print("Community Balance Patch / WHoward's Pick n' Mix DLL detected.  Barbarian cities will be disabled.")
			isUsingCBPDLL = true
			bDisableBarbEvolution = true
			bDisableBarbCapture = true
		end
		if (mod.ID == cbp) then
			print ("Community Balance Patch (CBP) detected.")
			isUsingCBP = true
		end
		if (mod.ID == csd) then
			print("City State Diplomacy (CBP) mod detected.")
			isUsingCSD = true
		end
		if (mod.ID == whoward) then
			print("WHoward's DLL detected.  Barbarian cities will be disabled.")
			isUsingWHoward = true
			bDisableBarbEvolution = true
			bDisableBarbCapture = true
		end
		if (mod.ID == superpowers) then
			print("Superpowers mod detected.")
			isUsingSuperpowers = true
		end
		if (mod.ID == dummyciv) then
			print("Dummy Civilization mod detected.")
			isUsingDummyCiv = true
		end
		if (mod.ID == barbciv) then
			print("Barbarians Evolved - Civilization mod detected.")
			isUsingBarbarianCiv = true
		end
	end
end

--########################################################################
-- Detect Liberate and Ally civilizations
function CheckLiberateAndAlly()
	iBarbLiberateTo = GameInfoTypes[sBarbLiberateTo]
	iBarbMajorAlly = GameInfoTypes[sBarbMajorAlly]

	if iBarbLiberateTo == nil then
		iBarbLiberateTo = -1
	end

	if iBarbMajorAlly == nil then
		iBarbMajorAlly = -1
	end

	print("Barbarians Liberate to: [" .. sBarbLiberateTo .. "] civ ID [" .. iBarbLiberateTo .. "]")
	print("Barbarians Allied with: [" .. sBarbMajorAlly .."] civ ID [" .. iBarbMajorAlly .. "]")

	if (iBarbLiberateTo ~= -1) or (iBarbMajorAlly ~= -1) then
		print("Iterating in-game Civilizations...")
		for i = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
			local pPlayer = Players[i]
			if (pPlayer ~= nil) then
				if pPlayer:IsEverAlive() then
					-- print("[" .. i .. "] = [" .. pPlayer:GetCivilizationType() .. "]")
					if iBarbLiberateTo ~= -1 then
						if pPlayer:GetCivilizationType() == iBarbLiberateTo then
							print("Liberator [" .. sBarbLiberateTo .. "] located at player index [" .. i .. "]")
							isUsingDummyCiv = true
							iDummyCiv = i
						end
					end
					if iBarbMajorAlly ~= -1 then
						if pPlayer:GetCivilizationType() == iBarbMajorAlly then
							print("Ally [" .. sBarbMajorAlly .. "] located at player index [" .. i .. "]")
							isUsingBarbarianCiv = true
							iBarbMajorCiv = i
						end
					end
				end
			end
		end
		-- specifically check CIVILIZATION_BARBARIAN as liberation target if and only if ally is in the game
		if isUsingBarbarianCiv then
			local pPlayer = Players[iBarbNPCs]
			if pPlayer:GetCivilizationType() == iBarbLiberateTo then
				print("Liberation target [" .. sBarbLiberateTo .. "] located at player index [" .. iBarbNPCs .. "]")
				isUsingDummyCiv = true
				iDummyCiv = iBarbNPCs
			end
		end
		print("Check complete.")
	else
		print("Neither Liberate nor Ally civs are valid and real civs that could appear in game.  Skipping...")
	end
end

function CheckSponsoredSpawns()
	if bDisableSponsoredSpawns then
		print("CheckSponsoredSpawns: Sponsored Encampments are disabled.")
	else
		print("CheckSponsoredSpawns: Making Sponsored Encampments buildable by workers.")

		local query = "INSERT INTO Unit_Builds (UnitType, BuildType) VALUES ('UNIT_WORKER', 'BUILD_ENCAMPMENT')"
		for result in DB.Query(query) do
		end

		local query = "INSERT INTO Unit_Builds (UnitType, BuildType) VALUES ('UNIT_BARBARIAN_WORKER', 'BUILD_ENCAMPMENT')"
		for result in DB.Query(query) do
		end
	end
end

--########################################################################
-- Check if colors are overriden; update with SQL if required
--
-- Note: Not working as intended.  The colors don't seem to be change-able after game start.
function CheckBarbarianColors()
	if bOverrideBarbColors then
		print("CheckBarbarianColors: Overriding XML Barbarian colors...")

		local query = "UPDATE Colors SET Red = '".. iMinorForeR .."', Green = '".. iMinorForeG .."', Blue = '".. iMinorForeB .."', Alpha = '".. iMinorForeA .."' WHERE Type = 'COLOR_PLAYER_BARBARIAN_ICON'"
		for result in DB.Query(query) do
		end

		local query = "UPDATE Colors SET Red = '".. iMinorBackR .."', Green = '".. iMinorBackG .."', Blue = '".. iMinorBackB .."', Alpha = '".. iMinorBackA .."' WHERE Type = 'COLOR_PLAYER_BARBARIAN_BACKGROUND'"
		for result in DB.Query(query) do
		end

		local query = "UPDATE Colors SET Red = '".. iMajorForeR .."', Green = '".. iMajorForeG .."', Blue = '".. iMajorForeB .."', Alpha = '".. iMajorForeA .."' WHERE Type = 'COLOR_PLAYER_BARBARIAN_MAJOR_ICON'"
		for result in DB.Query(query) do
		end

		local query = "UPDATE Colors SET Red = '".. iMajorBackR .."', Green = '".. iMajorBackG .."', Blue = '".. iMajorBackB .."', Alpha = '".. iMajorBackA .."' WHERE Type = 'COLOR_PLAYER_BARBARIAN_MAJOR_BACKGROUND'"
		for result in DB.Query(query) do
		end

		if isUsingBarbarianCiv then
			PreGame.SetPlayerColor(iBarbMajorCiv, GameInfo.PlayerColors["PLAYERCOLOR_BARBARIAN_MAJOR"].ID);
		end
		PreGame.SetPlayerColor(iBarbNPCs, GameInfo.PlayerColors["PLAYERCOLOR_BARBARIAN"].ID);
	else
		print("CheckBarbarianColors: Keeping XML Barbarian colors...")
	end
end

--########################################################################
-- Detect Brave New World
function UsingDLC()
	-- BNW
	if ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY) then
		print("Brave New World DLC active.")
		isUsingBNW = true
	end

	if ContentManager.IsActive("0E3751A1-F840-4E1B-9706-519BF484E59D", ContentType.GAMEPLAY) then
		print("Gods and Kings DLC active.")
		isUsingGNK = true
	end
end

--########################################################################
-- Init
print("-------------------- Barbarians Evolved Load Start --------------------")

--########################################################################
-- End-User Customizable Settings
print("-- LOADING DEFAULTS FROM FILE --")

-- a necessary evil because it establishes all of the variables as global
include("BEsettings")

userData = Modding.OpenUserData("BE", 1)
saveData = Modding.OpenSaveData()

if BEDataExists(saveData) then
	print("-- LOADING SETTINGS FROM SAVE GAME --")
	BEReadData(saveData)
	print("-- SETTINGS WILL NOT BE WRITTEN BACK TO SAVE GAME --")
else
	if BEDataExists(userData) then
		-- we came via Custom Game
		print("-- LOADING SETTINGS FROM CUSTOM GAME SETUP SCREEN --")
		BEReadData(userData)
	end
	print("-- COMMITTING GAME SETTINGS TO SAVE GAME --")
	BEWriteData(saveData)
end

-- wipe out stale user data
print("Deleting stale user data...");
Modding.DeleteUserData("BE", 1);

--[[
print("iBaseTurnsPerBarbEvolution: [" .. iBaseTurnsPerBarbEvolution .. "]")
print("iSpawnChance: [" .. iSpawnChance .. "]")
print("iBarbNukeLimit: [" .. iBarbNukeLimit .. "]")
print("iBarbWorkerLimit: [" .. iBarbWorkerLimit .. "]")
]]--

--########################################################################
-- Globals and pre-game settings -- DON'T CHANGE THESE
iBarbNPCs = GameDefines.MAX_CIV_PLAYERS
bBarbNamesChanged = false

iDummyCiv = -1
isUsingDummyCiv = false

isUsingBNW = false
isUsingGNK = false

iCityUpdateTypeBanner = CityUpdateTypes.CITY_UPDATE_TYPE_BANNER

-- these vars will remain in scope for the entire minor barbarian's turn
iLastTechsRanged = 0
iBICRanged = "-1"
iLastTechsMountedArmor = 0
iBICMountedArmor = "-1"
iLastTechsNavalMelee = 0
iBICNavalMelee = "-1"
iLastTechsNavalRanged = 0
iBICNavalRanged = "-1"
iLastTechsSiege = 0
iBICSiege = "-1"
iLastTechsMeleeGun = 0
iBICMeleeGun = "-1"

-- Set Turns Per Barb Evolution based on gamespeed
iGameSpeed = Game.GetGameSpeedType()

-- standard/modded gamespeed
iTurnsPerBarbEvolution = iBaseTurnsPerBarbEvolution * 2

-- marathon/epic
if (iGameSpeed == 0) or (iGamespeed == 1) then
	iTurnsPerBarbEvolution = iBaseTurnsPerBarbEvolution * 3
end

-- quick
if (iGameSpeed == 3) then
	iTurnsPerBarbEvolution = iBaseTurnsPerBarbEvolution * 1
end

-- twice as quick if Raging Barbarians are on
--[[
if bRagingBarbarians then
	iTurnsPerBarbEvolution = iTurnsPerBarbEvolution / 2
end
]]--

StateSponsoredEncampmentCheck()

techsql = "SELECT MAX(ID) as ID FROM Technologies"
for techrow in DB.Query(techsql) do
	iMaxTechId = techrow.ID
end

polsql = "SELECT MAX(ID) as ID FROM Policies"
for polrow in DB.Query(polsql) do
	iMaxPolicyId = polrow.ID
end

iMinEraId = -1
erasql = "SELECT MAX(ID) as ID FROM Eras"
for erarow in DB.Query(erasql) do
	iMaxEraId = erarow.ID
end

print("---------- Globals and pre-game settings ----------")
print("iTurnsPerBarbEvolution: [" .. iTurnsPerBarbEvolution .. "]")
print("iCityUpdateTypeBanner: [" .. iCityUpdateTypeBanner .. "]")
print("iMaxPolicyId: [" .. iMaxPolicyId .. "]")
print("iMaxTechId: [" .. iMaxTechId .. "]")
print("iGameSpeed: [" .. iGameSpeed .. "]")
print("iMaxEraId: [" .. iMaxEraId .. "]")
print("iBarbNPCs: [" .. iBarbNPCs .. "]")

print("Checking DLC...")
UsingDLC()

-- I intend to NEVER uncomment this. BEsettings.lua lets you manage this yourself now.
-- print("Checking mods...")
-- UsingMods()

print("Checking Liberate and Ally civs...")
CheckLiberateAndAlly()

-- This isn't working at the moment.
-- CheckSponsoredSpawns()

-- Neither is this :(
-- CheckBarbarianColors()

if isUsingBarbarianCiv then
	print("Barbarian Major Civ is in use.  Skipping assignment of leader to Barbarian NPCs (63).")
else
	print("Barbarian Major Civ is NOT in use.")
	if bConservativeMode then
		print("Entering conservative mode.  Overriding settings to disable Barbarian spawn, evolution, capture and upgrade.")
		bDisableBarbSpawn = true
		bDisableBarbEvolution = true
		bDisableBarbCapture = true
		bDisableGlobalUpgrade = true
	end
	print("Assigning Barbarian NPC leader and trait.")
	PreGame.SetLeaderType(iBarbNPCs, GameInfo.Leaders["LEADER_BARBARIAN_EVOLVED"].ID)
end

if isUsingBarbarianCiv and IsDefaultBarbMajorCiv() then
	print("Assigning Major Barbarian color [" .. sMajorPlayerColor .. "] to [" .. iBarbMajorCiv .. "]")
	PreGame.SetPlayerColor(iBarbMajorCiv, GameInfo.PlayerColors[sMajorPlayerColor].ID);
end
print("Assigning Tribal Barbarian color [" .. sMinorPlayerColor .. "] to [" .. iBarbNPCs .. "]")
PreGame.SetPlayerColor(iBarbNPCs, GameInfo.PlayerColors[sMinorPlayerColor].ID);

print("Hooking functions...")

Events.LoadScreenClose.Add(InitBarbMajorCiv);
Events.LoadScreenClose.Add(BarbEvolvedCityStates);
Events.SequenceGameInitComplete.Add(BarbEvolvedNPCUnitUpgradePass);
Events.SequenceGameInitComplete.Add(BarbEvolvedTechWindback);
Events.SequenceGameInitComplete.Add(BarbEvolvedNPCPolicyWindback);
Events.SpecificCityInfoDirty.Add(BarbEvolvedCityUpdate);
Events.ActivePlayerTurnStart.Add(BarbEvolvedActivePlayerStartTurn);
Events.SerialEventCityCaptured.Add(BarbEvolvedCityCapture);
Events.SerialEventImprovementCreated.Add(BarbEvolvedStateSponsorBuildCheck);
GameEvents.PlayerDoTurn.Add(BarbEvolvedCivStartTurn);
GameEvents.PlayerCanTrain.Add(BarbPlayersCantTrainSpecificUnits);
GameEvents.CityCanTrain.Add(BarbCitiesCantTrainSpecificUnits);
GameEvents.TeamSetHasTech.Add(BarbEvolvedCantReachEra);
GameEvents.CityCanConstruct.Add(BarbEvolvedCantBuildStuff);
GameEvents.CityCanMaintain.Add(BarbEvolvedCantProcess);

print("-------------------- Barbarians Evolved Load End --------------------")