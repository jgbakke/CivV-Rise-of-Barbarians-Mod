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
		tStabilityTable[i] = 1
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

function NotifyStability()
    local tStability = LoadCivStability()
    local popupText = ""

    for i = 0, GameDefines.MAX_MAJOR_CIVS-1 do
        local bIsPlayer = Game.GetActivePlayer() == i
        local bHasMet = Teams[Players[Game.GetActivePlayer()]:GetTeam()]:IsHasMet(Players[i]:GetTeam())
        local bHasCities = Players[i]:GetNumCities() > 0

        if bIsPlayer or (bHasMet and bHasCities) then
            local iStability = tStability[i]
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