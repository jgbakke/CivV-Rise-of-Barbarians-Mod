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
    InGameDebug("Start FECSID")
    local civHibernating = LoadCivHibernating()
    InGameDebug("Loaded civs hibernating")

    -- Pick a random to spawn
    for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
        if civHibernating[i] then
            InGameDebug("Found one: " .. i)
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

--    if cCity:GetPopulation() < 1 then
--        cCity:SetPopulation(1, true)
--    end

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

    --InGameDebug("Set Puppet False...")
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

function GetToleratedReligions(iPlayer)
    -- TODO: Return a set of tolerated religions
    -- Majority religions are ones where you own the Holy City or are the founder
    -- If no majority, then it is biggest throughout the empire
    return {}
end

function GetMinorityReligionFollowers(cCity, tToleratedReligions)
    -- TODO: Return an int representing the number of followers not following a tolerated religion
    return 0
end

function GetReligionStability(cCity, tToleratedReligions)
    -- TODO: Return x * Number of followers for any religion NOT tolerated
    -- If religion is ALSO the majority, then multiply majority count * y
    return 0
end

function CheckCityStability(cCity)
    local iCityStability = 0
    if cCity:FoodDifference() < 0 then
        iCityStability = iCityStability * STARVATION_PENALTY
    end

    if (cCity:GetGarrisonedUnit() ~= nil) then
        iCityStability = iCityStability + GARRISON_BONUS
    end

    -- TODO: Puppets should give 1 instability

    -- TODO: Religion
    return iCityStability
end

function CalculateStability(iPlayer)
    -- TODO: Validate that iPlayer is a Major Civilization

    local pPlayer = Players[iPlayer]
    local tTeam = Teams[pPlayer:GetTeam()]

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
        iStability = iStability + CheckCityStability(cCity)
    end

    -- TODO: The more cities you lose, the faster you should go down

    return iStability
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
            local iStability = CalculateStability(i) --+ tStability[i]
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