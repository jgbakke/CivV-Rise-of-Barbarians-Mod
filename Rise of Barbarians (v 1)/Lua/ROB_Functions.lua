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

ROB_DEBUG = true

function GiveNotification(sDescription, sTitle)
    Players[Game.GetActivePlayer()]:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, sDescription, sTitle)
end

function InGameDebug(sMessage)
    if ROB_DEBUG then
        GiveNotification(sMessage, sMessage)
    end
end

function CreateCivStabilityTable()
	local tStabilityTable = {}
	for i = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		tStabilityTable[i] = 0
	end
	return tStabilityTable
end

function LoadCivStability()
	--local pPlayer = Players[LOCAL_PLAYER]
	local tStabilityTable = LoadData("CivStability", CreateCivStabilityTable() )
	return tStabilityTable
end

function SaveCivStability( tStabilityTable )
	--local pPlayer = Players[LOCAL_PLAYER]
	SaveData( "CivStability", tStabilityTable )
end

function FindEmptyCityStateID()
    local civHibernating = LoadCivHibernating()

    -- Pick a random to spawn
    for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
        if civHibernating[i] then
            civHibernating[i] = false
            SaveCivHibernating( civHibernating )
            return i
        end
    end

    -- Return barbarian if we did not find one
    return BARBARIAN_PLAYER

end

function SpawnCityStateFromCity(cCity)
    -- Check if a city state is available
    InGameDebug("SpawnCityStateFromCity")

    local iCityState = FindEmptyCityStateID()
    local pCityStatePlayer = Players[iCityState]

    InGameDebug("Acquiring City...")
	pCityStatePlayer:AcquireCity(cCity, false, true)

    if cCity:GetPopulation() < 1 then
        cCity:SetPopulation(1, true)
    end

    -- TODO: The check to determine if it is ready to spawn
    if iCityState ~= BARBARIAN_PLAYER then
        InGameDebug("Not a barbarian")
        local pCityPlot = cCity:Plot()

        InGameDebug("Got city plot")
        ConvertNearbyBarbarians(iCityState, pCityPlot:GetX(), pCityPlot:GetY())
        InGameDebug("Converted Barbarians")

        SpawnInitialUnits(iCityState, pCityPlot:GetX(), pCityPlot:GetY())
        InGameDebug("Initial Units spawned")

        SpawnInitialCity(cCity)

        -- TODO: Test this
        InGameDebug("Building a courthouse")
        cCity:SetNumRealBuilding(GameInfoTypes["BUILDING_COURTHOUSE"], 1)
        InGameDebug("Courthouse built")
    end

    cCity:SetPuppet(false)
    InGameDebug("Success!")
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

    if tToleratedReligions.size == 0 then
        -- If we do not have a state religion, make it the one with the most cities
        tToleratedReligions.size = 1
        tToleratedReligions[iReligionInMostCities] = true
    end

    for k, v in pairs(tToleratedReligions) do
        if k ~= "size" then
            InGameDebug("Tolerate Religion" .. k)
        end
    end

    if tToleratedReligions.size == 0 then
        InGameDebug("No majority religion in the civilization")
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
        iCityStability = iCityStability * STARVATION_PENALTY
    end

    -- TODO: Puppets should give 1 instability
    if cCity:IsPuppet() then
        iCityStability = iCityStability + PUPPET_PENALTY
    end

    -- If size is 0 then that means we have no religions yet, let's not waste time searching
    if tToleratedReligions.size ~= 0 then
        iCityStability = iCityStability + GetReligionStability(cCity, tToleratedReligions)
    end

    if iCityStability < 0 and cCity:GetGarrisonedUnit() ~= nil then
        iCityStability = iCityStability + GARRISON_BONUS
    end

    return iCityStability
end

function CalculateStability(iPlayer)
    -- Validate that iPlayer is a Major Civilization, if not then just return
    if iPlayer >= GameDefines.MAX_MAJOR_CIVS then
        return 1
    end

    InGameDebug(Players[iPlayer]:GetCapitalCity():GetName() .. " Majority: " .. Players[iPlayer]:GetCapitalCity():GetReligiousMajority())

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

    -- TODO: The more cities you lose, the faster you should go down

    -- For some unknown reason Lua has math.floor and math.ceil but no math.round
    return math.floor(iStability + 0.5)
end

function CheckStability(iPlayer)
    local iStability = CalculateStability(iPlayer)

    -- TODO: Revolt if low enough

    if iPlayer == Game.GetActivePlayer() then
        if iStability < 1 then
            Players[iPlayer]:AddNotification(NotificationTypes.NOTIFICATION_REBELS, "You are at risk of Civil War. Increase your stability soon!", "Your empire is unstable!")
        end
    end
end

function NotifyStability()
    local tStability = LoadCivStability()
    local popupText = ""

    for i = 0, GameDefines.MAX_MAJOR_CIVS-1 do
        local bIsPlayer = Game.GetActivePlayer() == i
        local bHasMet = Teams[Players[Game.GetActivePlayer()]:GetTeam()]:IsHasMet(Players[i]:GetTeam())
        local bHasCities = Players[i]:GetNumCities() > 0

        if bIsPlayer or (bHasMet and bHasCities) then
            -- TODO: Do we need to record tStability?
            local iStability = CalculateStability(i) + tStability[i]
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

	--print("Showing Tutorial - " .. tutorial.ID);
	Events.AdvisorDisplayShow(AdvisorDisplayShowData);
end