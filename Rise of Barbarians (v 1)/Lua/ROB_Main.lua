--
-- Created by IntelliJ IDEA.
-- User: jordan
-- Date: 3/25/20
-- Time: 3:21 AM
-- To change this template use File | Settings | File Templates.
--

include("bit_ops")
include("SaveLib")
include("ROB_Functions")

function OnMinimapClicked(iX, iY)


    --NotifyStability(iX, iY)
	local pActivePlayer = Players[Game.GetActivePlayer()]
    SpawnCityStateFromCity(pActivePlayer:GetCapitalCity())


--	local pAztecPlot = pActivePlayer:GetCapitalCity():Plot()
--    pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, "You clicked a tile.", "Clicked " .. iX .. ", " .. iY)

--	local pPlot = pActivePlayer:GetCapitalCity():Plot()
--
--    pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, "Plot found", "Clicked " .. iX .. ", " .. iY);
--
--	for i=-3,4 do
--		for j=-3,3 do
--			if i ~= 0 or j ~= 0 then
--
--				local iUnitId = GameInfoTypes["UNIT_PIKEMAN"]
--				if i == 0 then
--					iUnitId = GameInfoTypes["UNIT_AZTEC_JAGUAR"]
--				elseif i == 1 then
--					iUnitId = GameInfoTypes["UNIT_HUN_HORSE_ARCHER"]
--				elseif i == 2 then
--					iUnitId = GameInfoTypes["UNIT_ZULU_IMPI"]
--				elseif i == -1 then
--					iUnitId = GameInfoTypes["UNIT_DANISH_BERSERKER"]
--				elseif i == -2 then
--					iUnitId = GameInfoTypes["UNIT_INCAN_SLINGER"]
--				elseif i == 4 then
--					iUnitId = GameInfoTypes["UNIT_IROQUOIAN_MOHAWKWARRIOR"]
--				end
--
--
--				local newbarb = Players[BARB3ARIAN_PLAYER]:InitUnit(iUnitId, pPlot:GetX() + i, pPlot:GetY() + j, UNITAI_ATTACK)
--			end
--		end
--	end
    --  local newbarb = Players[BARBARIAN_PLAYER]:InitUnit(GameInfoTypes["UNIT_AZTEC_JAGUAR"], pPlot:GetX() + 1, pPlot:GetY() + 1, UNITAI_ATTACK)
    -- pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, "You clicked a tile. Version 2!", "Clicked " .. iX .. ", " .. iY)


end
Events.MinimapClickedEvent.Add(OnMinimapClicked)

function HidePopupIfNotSpawned(popupInfo)
    -- You should hide if the Civ is hibernating
    local bShouldHide = LoadCivHibernating()[Players[Game.GetActivePlayer()]]

    -- TODO: Test this, not sure if it works
    if bShouldHide then
        InGameDebug("Hiding...")
        ContextPtr:SetHide( true )
        InGameDebug("Hidden!")
    end

end
Events.SerialEventGameMessagePopup.Add(HidePopupIfNotSpawned);


function InputHandler(uiMsg, wParam, lParam)
    if (uiMsg == KeyEvents.KeyDown) then
        if (wParam == Keys.X) then
            if (UIManager:GetShift()) then
                NotifyStability()
                return true
            end
        end
    end
end
ContextPtr:SetInputHandler(InputHandler)

GameEvents.PlayerDoTurn.Add(CheckStability)
GameEvents.CityCaptureComplete.Add(CivLostCity)