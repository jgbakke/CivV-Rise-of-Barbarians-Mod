-- Historical Spawn Dates Main File
-- Author: Jordan
-- DateCreated: 3/22/2020 2:00 AM
--------------------------------------------------------------

-- This script is modified from Gedemon's HSD Mod

print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("+++++++++++++++++++++++++++++++++++++++++++++++++++++ Historical Spawn Dates script started... ++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
--------------------------------------------------------------
include ("HSD_Defines")
include ("HSD_Debug")
include ("PlotIterators") -- by whoward69
include ("HSD_Utils")
include("bit_ops")
include ("HSD_Functions")

--------------------------------------------------------------

local bWaitBeforeInitialize = true
local bDebug = true

local endTurnTime = 0
local startTurnTime = 0

function NewTurnSummary()
	local year = Game.GetGameTurnYear()
	local turn = Game.GetGameTurn()
	startTurnTime = os.clock()
	print("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
	print("---------------------------------------------------------------------------------------- NEW TURN -----------------------------------------------------------------------------------------------------")
	print("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
	Dprint ("Game year = " .. year .. ", Game turn = " .. turn)
	if endTurnTime > 0 then
		print ("AI turn execution time = " .. startTurnTime - endTurnTime )	
	end
	print("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
end

function EndTurnsummary()
	endTurnTime = os.clock()
	print("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
	print ("Your turn execution time = " .. endTurnTime - startTurnTime )
	print("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
end


-----------------------------------------
-- Initializing functions
-----------------------------------------

-- functions to call at beginning of each turn
function OnNewTurn()
	Dprint("Calling OnNewTurn()...", bDebug)
	Dprint("-------------------------------------", bDebug)
	NewTurnSummary()
	ResetGoldenAgeMeter()
	SetStartingBonus()
	SetValidVictories()
end

Events.ActivePlayerTurnStart.Add( OnNewTurn )

-- functions to call at end of each turn
function OnEndTurn()
	Dprint("Calling OnEndTurn()...", bDebug)
	Dprint("-------------------------------------", bDebug)
	WakeUp()
	EndTurnsummary()
end

-- functions to call once at end of 1st turn
function OnFirstTurnEnd()
	Dprint("End of First turn detected, calling OnFirstTurnEnd() ...", bDebug)
	Dprint("-------------------------------------", bDebug)
	--
	--
	Events.ActivePlayerTurnEnd.Remove(OnFirstTurnEnd)
end


-- functions to call after loading this file when game is launched for the first time
function OnFirstTurn()
	Dprint("Calling OnFirstTurn() ...", bDebug)
	Dprint("-------------------------------------", bDebug)
	--
	NewTurnSummary()
end

-- functions to call ASAP after loading a game
function OnLoading()
	Dprint("Calling OnLoading() ...", bDebug)
	Dprint("-------------------------------------", bDebug)
	--
	HibernateOnLoading ()
	SetValidVictories()
	NewTurnSummary()
end

-- functions to call after game initialization (DoM screen button "Begin your journey" appears)
function OnGameInit ()
	if not UI:IsLoadedGame() then
		Dprint ("Game is initialized, calling OnGameInit() for new game ...", bDebug)
		Dprint("-------------------------------------", bDebug)
		--
		Hibernate() -- After YnAEMP initialization
	else
		Dprint ("Game is initialized, calling OnGameInit() for loaded game ...", bDebug)
		Dprint("-------------------------------------", bDebug)
		--
		--
	end
end

-- functions to call after entering game (DoM screen button pushed)
function OnEnterGame()
	Dprint ("Calling OnEnterGame() ...", bDebug)
	Dprint("-------------------------------------", bDebug)
	--
	GameEvents.PlayerCityFounded.Add(OnFirstCity)
	InitializeKnownTechTable()
	SetStartingBonus()
	--
end

-- Initialize when HSD is loaded
if ( bWaitBeforeInitialize ) then
	bWaitBeforeInitialize = false
	if not UI:IsLoadedGame() then
		OnFirstTurn()
		Events.ActivePlayerTurnEnd.Add(OnFirstTurnEnd)
	else
		OnLoading()
	end
end

-- Add functions to corresponding events
Events.ActivePlayerTurnStart.Add( OnNewTurn )
Events.ActivePlayerTurnEnd.Add( OnEndTurn )
Events.SequenceGameInitComplete.Add( OnGameInit )
Events.LoadScreenClose.Add( OnEnterGame )
Events.SerialEventGameMessagePopup.Add( OnEventReceived )

-----------------------------------------
-----------------------------------------

print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("++++++++++++++++++++++++++++++++++++++++++++++++++++++ Historical Spawn Dates script loaded ! +++++++++++++++++++++++++++++++++++++++++++++++++++++")
print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")


-- Trying to fix a strange bug... overflowing overflow ?
function ShowPlayerInfo(iPlayer)
	local player = Players[iPlayer]
	print(" " )
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	print("+++++++++++++++++++++++++++++++++++++++++++++++++++++ Start active turn for " .. Locale.ToUpper(player:GetCivilizationShortDescription()) .. " (id = " .. tostring(iPlayer) ..") +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
	print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")

	if g_PreviousOverflowResearch and g_PreviousOverflowResearch[iPlayer] then
		print ("- Previous Overflow Research = ".. tostring(g_PreviousOverflowResearch[iPlayer]) )
		print ("- Current Overflow Research = ".. tostring(player:GetOverflowResearch()) )
		print ("- Current Science/turn = ".. tostring(player:GetScience()) )
		if player:GetCurrentResearch() >= 0 then
			print ("- Current Research = ".. tostring(Locale.ConvertTextKey(GameInfo.Technologies[player:GetCurrentResearch()].Description)) )
		end
		if (player:GetOverflowResearch() > g_PreviousOverflowResearch[iPlayer] + player:GetScience()) and (g_PreviousOverflowResearch[iPlayer] > 0) then			
			print ("- WARNING ! Overflow Research has raised when it should not...")
			local team = Teams[player:GetTeam()]
			local teamTechs = team:GetTeamTechs()
			--teamTechs:SetResearchProgress(player:GetCurrentResearch(), 0, iPlayer)
			player:ClearResearchQueue()
			print ("- Actualized Overflow Research = ".. tostring(player:GetOverflowResearch()) )
		end
	end
end
GameEvents.PlayerDoTurn.Add(ShowPlayerInfo)