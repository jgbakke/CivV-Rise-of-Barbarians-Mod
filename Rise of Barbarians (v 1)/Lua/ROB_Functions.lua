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


function NotifyStability(iX, iY)
	InGameDebug("Notify Stability called")
	if UIManager:GetShift() then
        local pPlot = Map.GetPlot(iX, iY)
        local iOwner = pPlot:GetOwner()
        local iStability = 0

        if Teams[player:GetTeam()]:IsHasMet(Players[iOwner]:GetTeam()) then
            GiveNotification("Stability for " .. Players[iOwner]:GetName() .. " is " .. iStability, "Stability Report")
        else
            InGameDebug("You have not met player " .. iOwner)
        end
    else
        InGameDebug("Shift was not pressed")
    end
end