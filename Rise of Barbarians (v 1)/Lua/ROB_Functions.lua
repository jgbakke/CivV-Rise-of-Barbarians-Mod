--
-- Created by IntelliJ IDEA.
-- User: jordan
-- Date: 3/25/20
-- Time: 3:21 AM
-- To change this template use File | Settings | File Templates.
--
include("ROB_Defines")
include("HSD_Defines")
include("HSD_Utils")
include("HSD_Functions")
include("bit_ops")

ROB_DEBUG = true

function GiveNotification(sDescription, sTitle)
    Players[Game.GetActivePlayer()]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sDescription, sTitle)
end

function InGameDebug(sMessage)
    if ROB_DEBUG then
        GiveNotification(sMessage, sMessage)
    end
end

function BuildStabilityString(iPlayer)
    return "ROB_Stability" .. iPlayer
end

function LoadCivStability(iPlayer)
	return GetPersistentProperty(BuildStabilityString(iPlayer)) or 0
end

function SaveCivStability(iPlayer, iStability)
	SetPersistentProperty(BuildStabilityString(iPlayer), iStability)
end

function BuildCitiesLostString(iPlayer)
    return "ROB_CitiesLost" .. iPlayer
end

function LoadCivCitiesLost(iPlayer)
    return GetPersistentProperty(BuildCitiesLostString(iPlayer)) or 0
end

function SaveCivCitiesLost(iPlayer, iLost)
	SetPersistentProperty(BuildCitiesLostString(iPlayer), iLost)
end

function FindEmptyCityStateID()
--    local fPercentToSpawnCS = (Game.GetGameTurnYear() + 4000) / 60
--    local fCityStateSpawnRoll = Game.Rand(100, "Determining whether to spawn barbarian or city state")
--
--    if fCityStateSpawnRoll > fPercentToSpawnCS then
--        return BARBARIAN_PLAYER
--    end

    local civHibernating = LoadCivHibernating()

    -- Pick a random to spawn
    for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
        if Players[i] ~= nil then
            if Players[i]:GetNumCities() == 0 then
                civHibernating[i] = false
                SaveCivHibernating( civHibernating )
                return i
            end
        end
    end

    -- Return nil if we did not find one
    return nil

end

function SpawnCityStateFromCity(cCity)
    -- Check if a city state is available
    -- We can override the AI choice by providing a parameter
    -- TODO: Find if this causes a bug
    local iCityState = FindEmptyCityStateID()
    InGameDebug("City state ID: " .. iCityState)

    if not iCityState then
        InGameDebug("No Empty City-State found! Giving to a nearby civ!")
        -- TODO: Give to nearby civ
        return
    end

    local iX = cCity:GetX()
    local iY = cCity:GetY()
    local name = cCity:GetName()

    InGameDebug("Coordinates retrieved")

    Players[cCity:GetOwner()]:Disband(cCity)

    InGameDebug("Disband " .. name)

    -- TODO: Why is this crashing?
    local pCityStatePlayer = Players[iCityState]
    local unit = pCityStatePlayer:InitUnit(GameInfoTypes["UNIT_WORKER"], iX, iY, UNITAI_WORKER)
    unit:JumpToNearestValidPlot();
    local unit2 = pCityStatePlayer:InitUnit(GameInfoTypes["UNIT_SETTLER"], iX, iY, UNITAI_SETTLER)
    unit2:JumpToNearestValidPlot();
    --    pCityStatePlayer:InitCity(iX, iY)
--
--    InGameDebug("Initialized")
--    pCityStatePlayer:AcquireCity(cCity, false, true)
--
--    InGameDebug("City acquired")
--    local pCityPlot = cCity:Plot()
--
--    InGameDebug("Got city plot")
--    ConvertNearbyBarbarians(iCityState, pCityPlot:GetX(), pCityPlot:GetY())
--    InGameDebug("Converted Barbarians")
--
--    SpawnInitialCity(cCity)
--
--    InGameDebug("Building a courthouse")
--    cCity:SetNumRealBuilding(GameInfoTypes["BUILDING_COURTHOUSE"], 1)
--    InGameDebug("Courthouse built")
--
--    cCity:SetPuppet(false)
--    InGameDebug("City acquired")
end

function ColorStabilityNumber(iStabilityValue)
    if iStabilityValue > 3 and iStabilityValue < 10 then
        return iStabilityValue
    else
        local sColor = "[COLOR_NEGATIVE_TEXT]"
        if iStabilityValue >= 10 then
            sColor = "[COLOR_POSITIVE_TEXT]"
        elseif iStabilityValue >= 0 then
            sColor = "[COLOR_ADVISOR_HIGHLIGHT_TEXT]"
        end

        return sColor .. iStabilityValue .. "[ENDCOLOR]"
    end
end

function GetToleratedReligions(pPlayer)
    -- Returns a set of tolerated religions
    -- Majority religions are ones where you own the Holy City or are the founder
    -- If no majority, then it is biggest throughout the empire
    local tToleratedReligions = {size=0 }
    local iReligionInMostCities = -1

    local religionCreated = pPlayer:GetReligionCreatedByPlayer()
    if religionCreated ~= nil then
        tToleratedReligions[religionCreated] = true
        tToleratedReligions.size = 1 + tToleratedReligions.size
    end

    for i = GameInfo.Religions.RELIGION_BUDDHISM.ID, GameInfo.Religions.RELIGION_ZOROASTRIANISM.ID do
        local cHolyCity = Game.GetHolyCityForReligion(i, -1)

        if cHolyCity ~= nil then
            if cHolyCity:GetOwner() == pPlayer:GetID() then
                -- check to make sure we don't double-add the size
                if tToleratedReligions[i] then
                    tToleratedReligions.size = 1 + tToleratedReligions.size
                    tToleratedReligions[i] = true
                end
            end
        end

        if pPlayer:HasReligionInMostCities(i) then
            iReligionInMostCities = i
        end
    end

    if tToleratedReligions.size == 0 and iReligionInMostCities ~= -1 then
        -- If we do not have a state religion, make it the one with the most cities
        tToleratedReligions.size = 1
        tToleratedReligions[iReligionInMostCities] = true
    end

    return tToleratedReligions
end

function GetMinorityReligionFollowers(cCity, tToleratedReligions)
    local iFollowers = 0
    for i=GameInfo.Religions.RELIGION_BUDDHISM.ID, GameInfo.Religions.RELIGION_ZOROASTRIANISM.ID do
        if tToleratedReligions[i] == nil then
            iFollowers = iFollowers + cCity:GetNumFollowers(i)
        end
    end
    return iFollowers
end

function GetReligionStability(cCity, tToleratedReligions)
    -- Returns x * Number of followers for any religion NOT tolerated
    -- If religion is ALSO the majority, then multiply majority count * y
    local iReligiousInstability = GetMinorityReligionFollowers(cCity, tToleratedReligions) * RELIGION_MODIFIER

    local iReligiousMajority = cCity:GetReligiousMajority()
    if iReligiousMajority ~= nil then
        -- If we have a religious minority, it is not a pantheon, and it is not tolerated
        if iReligiousMajority > 0 and tToleratedReligions[iReligiousMajority] == nil then
            iReligiousInstability = iReligiousInstability + cCity:GetNumFollowers(iReligiousMajority) *
                    RELIGION_MODIFIER * REL_MAJORITY_MODIFIER
        end
    end
    return iReligiousInstability
end

function CheckCityStability(cCity, tToleratedReligions)
    local iCityStability = 0
    if cCity:FoodDifference() < 0 then
        iCityStability = iCityStability * STARVATION_MODIFIER
    end

    if cCity:IsPuppet() then
        iCityStability = iCityStability + PUPPET_PENALTY
    end

    -- If size is 0 then that means we have no religions yet, let's not waste time searching
    if tToleratedReligions.size ~= 0 then
        iCityStability = iCityStability + GetReligionStability(cCity, tToleratedReligions)
    end

    if iCityStability < 0 and cCity:GetGarrisonedUnit() ~= nil then
        -- You only get the garrison bonus if you are below 0
        iCityStability = iCityStability + GARRISON_BONUS
    end

    return iCityStability
end

function CalculateLostCitiesPenalty(iCities, iPenalty)
    if iCities < 1 then return 0 end
    return iCities * iPenalty * (1 + iCities) / 2
end

function CalculateStability(iPlayer)
    -- Validate that iPlayer is a Major Civilization, if not then just return
    if iPlayer >= GameDefines.MAX_MAJOR_CIVS then
        return 1
    end

    local pPlayer = Players[iPlayer]
    local tTeam = Teams[pPlayer:GetTeam()]
    local tToleratedReligions = GetToleratedReligions(pPlayer)

    local gptPenalty = 0
    if pPlayer:GetGold() < GOLD_THRESHOLD then
        gptPenalty = math.floor(GPT_LOSS_MODIFIER * pPlayer:CalculateGoldRate())
    end

    local iStability = HAPPINESS_MODIFIER * pPlayer:GetExcessHappiness() +
                        SOCIAL_POLICY_MODIFIER * pPlayer:GetNumPolicies() +
                        POLICY_BRANCH_MODIFIER * pPlayer:GetNumPolicyBranchesFinished() +
                        WONDER_MODIFIER        * pPlayer:GetNumWorldWonders() +
                        WAR_PER_CIV_MODIFIER   * tTeam:GetAtWarCount() +
                        gptPenalty

    if pPlayer:IsGoldenAge() then
        iStability = iStability + GOLDEN_AGE_BONUS
    end

    for cCity in pPlayer:Cities() do
        iStability = iStability + CheckCityStability(cCity, tToleratedReligions)
    end

    local iCitiesLostBitString = LoadCivCitiesLost(iPlayer)
    local iNumCitiesLost = CountBits(iCitiesLostBitString)
    iStability = iStability + CalculateLostCitiesPenalty(iNumCitiesLost, CITIES_LOST_MODIFIER)

    -- TODO: Take away the minus
    -- For some unknown reason Lua has math.floor and math.ceil but no math.round
    return -100 + math.floor(iStability + 0.5)
end

function CheckStability(iPlayer)
    local iStability = CalculateStability(iPlayer)
    local tToleratedReligions = GetToleratedReligions(Players[iPlayer])

    if -Game.Rand(100, "Determining whether to start a revolution") > iStability then
        print("Revolution for " .. Players[iPlayer]:GetName() .. " from Stability " .. iStability)
        InGameDebug("Revolution roll success")

        for cCity in Players[iPlayer]:Cities() do
            InGameDebug("City: " .. cCity:GetName())

            -- TODO: test this
            if cCity ~= Players[iPlayer]:GetCapitalCity() then
                InGameDebug(cCity:GetName() .. " is not the capital")

                -- If a city state makes a valid roll they will spawn
                if -Game.Rand(100, "Checkng revolt for " .. cCity:GetName()) > iStability + CheckCityStability(cCity, tToleratedReligions) * CITY_REVOLT_MODIFIER then
                    SpawnCityStateFromCity(cCity)
                end
            end
        end
    elseif iPlayer == Game.GetActivePlayer() then
        if iStability < 1 then
            Players[iPlayer]:AddNotification(NotificationTypes.NOTIFICATION_REBELS, "You are at risk of Civil War. Increase your stability soon!", "Your empire is unstable!")
        end
    end

    local iCitiesLostQueue = LoadCivCitiesLost(iPlayer)
    local iMask = 2^TURNS_TO_TRACK - 1
    iCitiesLostQueue = Lshift(iCitiesLostQueue, 1)
    iCitiesLostQueue = bitoper(iCitiesLostQueue, iMask, BIT_OPERATIONS.AND)
    SaveCivCitiesLost(iPlayer, iCitiesLostQueue)
end

function NotifyStability()
--    local p = Players[Game.GetActivePlayer()]
--    for cCity in p:Cities() do
--        cCity:ChangePopulation(5, true)
--        p:ChangeGold(200)
--    end


    local popupText = ""

    for i = 0, GameDefines.MAX_MAJOR_CIVS-1 do
        local bIsPlayer = Game.GetActivePlayer() == i
        local bHasMet = Teams[Players[Game.GetActivePlayer()]:GetTeam()]:IsHasMet(Players[i]:GetTeam())
        local bHasCities = Players[i]:GetNumCities() > 0

        if bIsPlayer or (bHasMet and bHasCities) or ROB_DEBUG then
            local iStability = CalculateStability(i) + LoadCivStability(i)
            popupText = popupText .. Players[i]:GetName() .. " : " .. ColorStabilityNumber(iStability) .. "[NEWLINE]"
        end
    end

    local AdvisorDisplayShowData = {
		IDName = "FOREIGN",
		Advisor = AdvisorTypes.ADVISOR_FOREIGN,
		TitleText = "Stability Report",
		BodyText = popupText,
		Modal = true
	};

	Events.AdvisorDisplayShow(AdvisorDisplayShowData);
end

function CivLostCity(hexPos, playerID, iCityID, newPlayerID)
    InGameDebug("Lost city")
    local iCitiesLostQueue = LoadCivCitiesLost(playerID)

    -- Check that least significant bit is 0
    if math.fmod(iCitiesLostQueue, 2) == 0 then
        InGameDebug("Least significant bit is 0")
        -- We had to make the check because if it is 1, and we add 1, then we get 0 here
        iCitiesLostQueue = iCitiesLostQueue + 1
    end
    SaveCivCitiesLost(playerID, iCitiesLostQueue)
end