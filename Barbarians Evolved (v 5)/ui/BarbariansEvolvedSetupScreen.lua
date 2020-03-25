-- BarbariansEvolvedSetupScreen
-- Author: Charsi
-- DateCreated: 04/03/2016 12:00:31 PM
--------------------------------------------------------------

include( "IconSupport" );
include( "InstanceManager" );
include( "BarbariansEvolvedSharedFunctions" );

g_FeedbackID = "BESetupScreen"

-- these are created as global but set and used for the purposes of referencing the tribal and barbarian major civs
iTribalBarbCivID = -1
iMajorBarbCivID = -1

------------------------------------------------------------------------------------------------- VARIABLES -------------------------------------------------------------------------------------------------
-- yeah these are global... get the fuck over it
bConservativeMode = false
iBaseTurnsPerBarbEvolution = 20
bRagingBarbarians = false
bDisableBarbHealing = false
bDisableBarbSpawn = false
bDisableBarbSpawnForAlly = false
bDisableBarbSpawnForMe = true
bDisableSponsoredSpawns = false
iSpawnChance = 4
bDisableBarbEvolution = false
bBarbEvolveSettlers = false
bBarbEvolveCityStates = false
bDisableBarbCapture = false
bRequireMeleeCapture = false
bDisableGlobalUpgrade = false
bDisableGlobalUpgradeForMe = true
sBarbLiberateTo = "CIVILIZATION_BARBARIAN"
bBarbDisperseOnLiberate = true
sBarbMajorAlly = "CIVILIZATION_BARBARIAN_MAJOR"
bBarbMajorAllyExists = true
bBarbMajorAllyAsMe = false
arrBarbLandUnitPromotions = {"PROMOTION_EVOLVED_FORCES"}
arrBarbSeaUnitPromotions = {}
arrBarbAirUnitPromotions = {}
bBarbEraNameChange = true
bDeferNameChange = false
sBarbAdjDefault = "Barbarian"
sBarbDescrDefault = "Barbarian"
sBarbShortDefault = "Barbarians"
sBarbCampDefault = "Encampment"

arrBarbNames = {
	{"ERA_ANCIENT", "Barbarian", "Barbarism", "Barbarians", "Encampment"},
	{"ERA_CLASSICAL", "Raider", "Barbarism", "Raiders", "Encampment"},
	{"ERA_MEDIEVAL", "Criminal", "the Lawless", "Criminals", "Hideout"},
	{"ERA_RENAISSANCE", "Pirate", "the Lawless", "Pirates", "Hideout"},
	{"ERA_INDUSTRIAL", "Rebel", "the Rebellion", "Rebels", "Base"},
	{"ERA_MODERN", "Insurgent", "the Insurgency", "Insurgents", "Base"},
	{"ERA_POSTMODERN", "Terrorist", "Anarchy", "Terrorists", "Training Camp"},
	{"ERA_FUTURE", "Terrorist", "Anarchy", "Terrorists", "Training Camp"}
}

bDisableBuildingEncampmentsForAll = false
bDisableBuildingEncampmentsForOthers = false
sLanguageTable = "language_" .. Locale.GetCurrentLanguage().Type	-- e.g. language_en_US - there is no need to ask this of the user, they already indicated it in setup
iBarbNukeLimit = 2
iBarbWorkerLimit = 4

-- Colors
sMinorPlayerColor = "PLAYERCOLOR_BARBARIAN"
sMajorPlayerColor = "PLAYERCOLOR_BARBARIAN_MAJOR"

-- wipe out stale user data
print("Deleting stale user data...");
Modding.DeleteUserData("BE", 1);

-------------------------------------------------------------------------------------------------- GENERAL --------------------------------------------------------------------------------------------------

-------------------------------------------------
-- tab handler
-------------------------------------------------
function OnCategory( which )
    Controls.BEPresetPanel:SetHide( which ~= 1 );
    Controls.BEOptionPanel:SetHide( which ~= 2 );
    Controls.BEStringPanel:SetHide( which ~= 3 );
    
    Controls.BEPresetHighlight:SetHide( which ~= 1 );
    Controls.BEOptionHighlight:SetHide( which ~= 2 );
    Controls.BEStringHighlight:SetHide( which ~= 3 );

	-- panel specific reprocessing
	if (which == 3) then
		ShowHideEraNames();
	end
    
    Controls.BEScreenTitle:SetText( m_PanelNames[ which ] );
end
Controls.BEPresetButton:RegisterCallback( Mouse.eLClick, OnCategory );
Controls.BEOptionButton:RegisterCallback( Mouse.eLClick, OnCategory );
Controls.BEStringButton:RegisterCallback( Mouse.eLClick, OnCategory );

Controls.BEPresetButton:SetVoid1( 1 );
Controls.BEOptionButton:SetVoid1( 2 );
Controls.BEStringButton:SetVoid1( 3 );

m_PanelNames = {};
m_PanelNames[ 1 ] = Locale.ConvertTextKey( "TXT_KEY_BESETTING_TITLE_PRESETS_SCREEN" );
m_PanelNames[ 2 ] = Locale.ConvertTextKey( "TXT_KEY_BESETTING_TITLE_OPTIONS_SCREEN" );
m_PanelNames[ 3 ] = Locale.ConvertTextKey( "TXT_KEY_BESETTING_TITLE_STRINGS_SCREEN" );

-- default
OnCategory(1);

-------------------------------------------------
-- Back Button Handler
-------------------------------------------------
function BackButtonClicked()
	print("BackButtonClicked()");

	-- wipe out stale user data
	print("Deleting stale user data...");
	Modding.DeleteUserData("BE", 1);

    UIManager:DequeuePopup( ContextPtr );
end
Controls.BackButton:RegisterCallback( Mouse.eLClick, BackButtonClicked );

-------------------------------------------------
-- Basic Button Handler
-------------------------------------------------
--[[
function BasicClicked()
	print("BasicClicked()");
	CommitSettings();
	UIManager:DequeuePopup( ContextPtr );
	UIManager:QueuePopup( Controls.GameSetupScreen, PopupPriority.GameSetupScreen );
end
Controls.BasicButton:RegisterCallback( Mouse.eLClick, BasicClicked );
]]--

-------------------------------------------------
-- Advanced Button Handler
-------------------------------------------------
function AdvancedClicked()
	print("AdvancedClicked()");
	CommitSettings();
	UIManager:DequeuePopup( ContextPtr );
    UIManager:QueuePopup( Controls.AdvancedSetup, PopupPriority.AdvancedSetup );
end
Controls.AdvancedButton:RegisterCallback( Mouse.eLClick, AdvancedClicked );

-------------------------------------------------
-- Input processing
-------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyDown then
        if wParam == Keys.VK_ESCAPE then
            BackButtonClicked();
            return true;
        end
    end
end
ContextPtr:SetInputHandler( InputHandler );

-------------------------------------------------------------------------------------------------- PRESETS --------------------------------------------------------------------------------------------------

-------------------------------------------------
-- Preset Icon Offsets
-------------------------------------------------
-- BE == brute
IconHookup( 25, 64, "UNIT_ATLAS_1", Controls.PortraitVanilla );

-- CityStates = scout
IconHookup( 5, 64, "UNIT_ATLAS_1", Controls.PortraitCityStates );

-- DLL == worker
IconHookup( 1, 64, "UNIT_ATLAS_1", Controls.PortraitDLL );

-- Minimal == settler
IconHookup( 0, 64, "UNIT_ATLAS_1", Controls.PortraitMinimal );

-- Nightmare == atomic bomb
IconHookup( 24, 64, "UNIT_ATLAS_2", Controls.PortraitNightmare );

-- Generic stuff that happens when you pick a preset
function PresetPicked()
	-- reinit all arrays
	arrBarbLandUnitPromotions = {}
	arrBarbSeaUnitPromotions = {}
	arrBarbAirUnitPromotions = {}
	arrBarbNames = {}
	-- unhide the 2nd and 3rd panels
	Controls.BEOptionButton:SetHide(false)
	Controls.BEStringButton:SetHide(false)
	-- Controls.BasicButton:SetHide(false)
	Controls.AdvancedButton:SetHide(false)
	-- enable anything that happened to be disabled
	Controls.AllyCivPulldown:SetDisabled(false);
	Controls.AllyOption:SetDisabled(false);
	Controls.AllyMeOption:SetDisabled(false);
	-- move to the 2nd panel
	OnCategory(2)
end

function ApplyPreset()
	-- locate the desired default civs
	local allyid = -1
	local libid = -1
	local oAlly = GameInfo.Civilizations[sBarbMajorAlly]
	local oLib = GameInfo.Civilizations[sBarbLiberateTo]

	for index,civobj in pairs(playableCivs) do
		if (oAlly ~= nil) then
			if (civobj.CivID == oAlly.ID) then
				allyid = index
			end
		end
		if (oLib ~= nil) then
			if (civobj.CivID == oLib.ID) then
				libid = index
			end
		end
	end

	-- left pane
	-- ally civ (handler in callback)
	AllyCivCallback(0, allyid);
	-- general checkbox options
	Controls.AllyOption:SetCheck(bBarbMajorAllyExists == true)			-- checked means YES
	Controls.AllyOption:RegisterCheckHandler(function (bCheck) bBarbMajorAllyExists = bCheck end);
	Controls.AllyMeOption:SetCheck(bBarbMajorAllyAsMe == true)			-- checked means YES
	Controls.AllyMeOption:RegisterCheckHandler(function (bCheck) bBarbMajorAllyAsMe = bCheck end);
	Controls.EraOption:SetCheck(bBarbEraNameChange == true)				-- checked means YES
	Controls.EraOption:RegisterCheckHandler(function (bCheck) bBarbEraNameChange = bCheck end);
	Controls.EraDefer:SetCheck(bDeferNameChange == true)				-- checked means YES
	Controls.EraDefer:RegisterCheckHandler(function (bCheck) bDeferNameChange = bCheck end);
	Controls.UpgradeOption:SetCheck(bDisableGlobalUpgrade ~= true)
	Controls.UpgradeOption:RegisterCheckHandler(function (bCheck) bDisableGlobalUpgrade = not bCheck end);
	Controls.UpgradeMe:SetCheck(bDisableGlobalUpgradeForMe ~= true)
	Controls.UpgradeMe:RegisterCheckHandler(function (bCheck) bDisableGlobalUpgradeForMe = not bCheck end);
	Controls.CaptureOption:SetCheck(bDisableBarbCapture ~= true)
	Controls.CaptureOption:RegisterCheckHandler(function (bCheck) bDisableBarbCapture = not bCheck end);
	Controls.CaptureMelee:SetCheck(bRequireMeleeCapture == true)		-- checked means YES
	Controls.CaptureMelee:RegisterCheckHandler(function (bCheck) bRequireMeleeCapture = bCheck end);
	Controls.EvolveOption:SetCheck(bDisableBarbEvolution ~= true)
	Controls.EvolveOption:RegisterCheckHandler(function (bCheck) bDisableBarbEvolution = not bCheck end);
	Controls.EvolveSettlers:SetCheck(bBarbEvolveSettlers == true)		-- checked means YES
	Controls.EvolveSettlers:RegisterCheckHandler(function (bCheck) bBarbEvolveSettlers = bCheck end);
	-- evolution slider
	Controls.EvolutionTimerSlider:SetValue(iBaseTurnsPerBarbEvolution / 100)
	Controls.EvolutionTimerLength:SetText(Locale.ConvertTextKey("TXT_KEY_BESETTING_LABEL_EVOLUTION_TIMER", iBaseTurnsPerBarbEvolution ))
	-- handler triggered as slider moves; value updated separately

	-- right pane
	-- liberate civ (handler in callback)
	LiberateCivCallback(0, libid);
	-- general checkbox options
	Controls.LiberateOption:SetCheck(bBarbDisperseOnLiberate == true)	-- checked means YES
	Controls.LiberateOption:RegisterCheckHandler(function (bCheck) bBarbDisperseOnLiberate = bCheck end);
	Controls.HealingOption:SetCheck(bDisableBarbHealing ~= true)
	Controls.HealingOption:RegisterCheckHandler(function (bCheck) bDisableBarbHealing = not bCheck end);
	Controls.SpawningOption:SetCheck(bDisableBarbSpawn ~= true)
	Controls.SpawningOption:RegisterCheckHandler(function (bCheck) bDisableBarbSpawn = not bCheck end);
	Controls.SpawningAllyOption:SetCheck(bDisableBarbSpawnForAlly ~= true)
	Controls.SpawningAllyOption:RegisterCheckHandler(function (bCheck) bDisableBarbSpawnForAlly = not bCheck end);
	Controls.SpawningMeOption:SetCheck(bDisableBarbSpawnForMe ~= true)
	Controls.SpawningMeOption:RegisterCheckHandler(function (bCheck) bDisableBarbSpawnForMe = not bCheck end);
	-- spawn chance dropdown (handler in callback)
	HandicapCallback(iSpawnChance);
	-- more checkbox options
	Controls.EncampmentOption:SetCheck(bDisableBuildingEncampmentsForAll ~= true)
	Controls.EncampmentOption:RegisterCheckHandler(function (bCheck) bDisableBuildingEncampmentsForAll = not bCheck end);
	Controls.EncampmentOther:SetCheck(bDisableBuildingEncampmentsForOthers ~= true)
	Controls.EncampmentOther:RegisterCheckHandler(function (bCheck) bDisableBuildingEncampmentsForOthers = not bCheck end);
	-- unit limits
	Controls.InfiltratorLimitEdit:SetText(iBarbNukeLimit);
	Controls.InfiltratorLimitEdit:RegisterCallback(function (val,obj,bfire) iBarbNukeLimit = tonumber(val) end);
	Controls.EnslavedLimitEdit:SetText(iBarbWorkerLimit);
	Controls.EnslavedLimitEdit:RegisterCallback(function (val,obj,bfire) iBarbWorkerLimit = tonumber(val) end);

	-- era name strings (handlers created in function)
	SetEraNames();

	-- promotions
	Controls.LandPromoEdit:SetText(table.concat(arrBarbLandUnitPromotions, ","));
	Controls.LandPromoEdit:RegisterCallback(function (val,obj,bfire) arrBarbLandUnitPromotions = split(val, ",") end);
	Controls.SeaPromoEdit:SetText(table.concat(arrBarbSeaUnitPromotions, ","));
	Controls.SeaPromoEdit:RegisterCallback(function (val,obj,bfire) arrBarbSeaUnitPromotions = split(val, ",") end);
	Controls.AirPromoEdit:SetText(table.concat(arrBarbAirUnitPromotions, ","));
	Controls.AirPromoEdit:RegisterCallback(function (val,obj,bfire) arrBarbAirUnitPromotions = split(val, ",") end);

	-- colors
	MinorColorCallback(GameInfo.PlayerColors[sMinorPlayerColor].ID)
	MajorColorCallback(GameInfo.PlayerColors[sMajorPlayerColor].ID)
	
	SetDemoIconColors();
end

-- Vanilla presets
function PresetVanilla()
	print("Vanilla preset selected...");
	PresetPicked();

	-- formerly BEsetVanilla.lua
	include("BEsetVanilla")

	-- newer params
	bBarbMajorAllyExists = true
	bBarbMajorAllyAsMe = false
	bBarbEvolveCityStates = false

	ApplyPreset();
end
Controls.PresetVanilla:RegisterCallback( Mouse.eLClick, PresetVanilla );

-- City State presets
function PresetCityStates()
	print("City State preset selected...");
	PresetPicked();

	-- formerly BEsetVanilla.lua
	include("BEsetCityStates")

	-- disabled controls
	Controls.AllyCivPulldown:SetDisabled(true);
	Controls.AllyOption:SetDisabled(true);
	Controls.AllyMeOption:SetDisabled(true);

	-- newer params
	bBarbMajorAllyExists = false
	bBarbMajorAllyAsMe = false
	bBarbEvolveCityStates = true

	ApplyPreset();
end
Controls.PresetCityStates:RegisterCallback( Mouse.eLClick, PresetCityStates );

-- DLL presets
function PresetDLL()
	print("DLL preset selected...");
	PresetPicked();

	-- formerly BEsetCBP.lua
	include("BEsetCBP")

	-- newer params
	bBarbMajorAllyExists = true
	bBarbMajorAllyAsMe = false
	bBarbEvolveCityStates = false

	ApplyPreset();
end
Controls.PresetDLL:RegisterCallback( Mouse.eLClick, PresetDLL );

-- Minimal presets
function PresetMinimal()
	print("Minimal preset selected...");
	PresetPicked();

	-- formerly BEsetMinimal.lua
	include("BEsetMinimal")

	-- newer params
	bBarbMajorAllyExists = false
	bBarbMajorAllyAsMe = false
	bBarbEvolveCityStates = false

	ApplyPreset();
end
Controls.PresetMinimal:RegisterCallback( Mouse.eLClick, PresetMinimal );

-- Nightmare presets
function PresetNightmare()
	print("Nightmare preset selected...");
	PresetPicked();

	-- formerly BEsetWhiteWalkers.lua
	include("BEsetWhiteWalkers")

	-- newer params
	bBarbMajorAllyExists = false
	bBarbMajorAllyAsMe = false
	bBarbEvolveCityStates = false

	ApplyPreset();
end
Controls.PresetNightmare:RegisterCallback( Mouse.eLClick, PresetNightmare );

-------------------------------------------------------------------------------------------------- SETTINGS --------------------------------------------------------------------------------------------------

-------------------------------------------------
-- Evolution Timer Slider
-------------------------------------------------
function EvolutionTimerSliderChanged(value)
	
	-- print("value: " .. value);
	
	i = math.floor(value * 100);
	i = i * 10;
	Controls.EvolutionTimerLength:SetText(Locale.ConvertTextKey("TXT_KEY_BESETTING_LABEL_EVOLUTION_TIMER", math.floor(i / 10) ));
	iBaseTurnsPerBarbEvolution = math.floor(i / 10);
end
Controls.EvolutionTimerSlider:RegisterSliderCallback(EvolutionTimerSliderChanged)

-------------------------------------------------
-- Spawn chance pulldown (based on game difficulty)
-------------------------------------------------
HandicapPullDown = Controls.HandicapPullDown;
HandicapPullDown:ClearEntries();
for info in GameInfo.HandicapInfos() do
	if ( info.Type ~= "HANDICAP_AI_DEFAULT" ) then

		local instance = {};
		HandicapPullDown:BuildEntry( "InstanceOne", instance );
		instance.Button:LocalizeAndSetText(info.Description);
		instance.Button:LocalizeAndSetToolTip(info.Help);
		instance.Button:SetVoid1( info.ID );
	end
end

HandicapPullDown:CalculateInternals();

function HandicapCallback(id)
	local handicap = GameInfo.HandicapInfos[id]

	print("HandicapCallback: " .. id)

	HandicapPullDown:GetButton():LocalizeAndSetText(handicap.Description)
	HandicapPullDown:GetButton():LocalizeAndSetToolTip("TXT_KEY_BESETTING_LABEL_SPAWN_CHANCE_TIP")

	iSpawnChance = id
end
HandicapPullDown:RegisterSelectionCallback( HandicapCallback );

-------------------------------------------------
-- Liberate civ pulldown
-------------------------------------------------
LiberatePulldown = Controls.LiberateCivPulldown;

function GetPlayableCivInfo()
	local civs = {};
	local sql = [[Select	Civilizations.ID as CivID, 
							Civilizations.Type as CivType,
							Leaders.ID as LeaderID, 
							Civilizations.Description, 
							Civilizations.ShortDescription, 
							Leaders.Description as LeaderDescription 
							from Civilizations, Leaders, Civilization_Leaders 
							where (Civilizations.Playable = 1 or Civilizations.Type = 'CIVILIZATION_BARBARIAN')
							and CivilizationType = Civilizations.Type and LeaderheadType = Leaders.Type]];
	
	for row in DB.Query(sql) do
		table.insert(civs, {
			CivID = row.CivID,
			CivType = row.CivType,
			LeaderID = row.LeaderID,
			LeaderDescription = Locale.Lookup(row.LeaderDescription),
			ShortDescription = Locale.Lookup(row.ShortDescription),
			Description = row.Description,
		});

		if (row.CivType == "CIVILIZATION_BARBARIAN") then
			iTribalBarbCivID = row.CivID
		end
		if (row.CivType == "CIVILIZATION_BARBARIAN_MAJOR") then
			iMajorBarbCivID = row.CivID
		end
	end

	table.sort(civs, function(a,b) return Locale.Compare(a.LeaderDescription, b.LeaderDescription) == -1; end);

	return civs;
end

function PopulateCivPulldown( playableCivs, pullDown )
	pullDown:ClearEntries();
	-- set up the random slot
	local controlTable = {};
	pullDown:BuildEntry( "InstanceOne", controlTable );
	controlTable.Button:SetVoids( playerID, -1 );
	controlTable.Button:LocalizeAndSetText("TXT_KEY_BARBARIANS_EVOLVED_NOBODY");
	controlTable.Button:LocalizeAndSetToolTip("TXT_KEY_BARBARIANS_EVOLVED_NOBODY_HELP");
	
	for id, civ in ipairs(playableCivs) do
		local controlTable = {};
		pullDown:BuildEntry( "InstanceOne", controlTable );

		controlTable.Button:SetVoids( playerID, id );
		controlTable.Button:LocalizeAndSetText("TXT_KEY_RANDOM_LEADER_CIV", civ.LeaderDescription, civ.ShortDescription);
		controlTable.Button:LocalizeAndSetToolTip(civ.Description);
	end    
		    
	pullDown:CalculateInternals();
end

function LiberateCivCallback(player, id)
	local civID = playableCivs[id] and playableCivs[id].CivID or -1;
			
	print("LiberateCivCallback: " .. id);

	if (id ~= -1) then
		LiberatePulldown:GetButton():LocalizeAndSetText(playableCivs[id].ShortDescription);
		sBarbLiberateTo = playableCivs[id].CivType;
	else
		LiberatePulldown:GetButton():LocalizeAndSetText("TXT_KEY_BARBARIANS_EVOLVED_NOBODY");
		sBarbLiberateTo = "CIVILIZATION_INTENTIONALLY_INVALID";
	end

	LiberatePulldown:GetButton():LocalizeAndSetToolTip("TXT_KEY_BESETTING_LABEL_LIBERATE_TIP");
end
LiberatePulldown:RegisterSelectionCallback( LiberateCivCallback );

playableCivs = GetPlayableCivInfo();
PopulateCivPulldown(playableCivs, LiberatePulldown);

-------------------------------------------------
-- Ally civ pulldown
-------------------------------------------------
AllyPulldown = Controls.AllyCivPulldown;

function AllyCivCallback(player, id)
	local civID = playableCivs[id] and playableCivs[id].CivID or -1;
			
	print("AllyCivCallback: " .. id);

	if (id ~= -1) then
		AllyPulldown:GetButton():LocalizeAndSetText(playableCivs[id].ShortDescription);
		sBarbMajorAlly = playableCivs[id].CivType;
	else
		AllyPulldown:GetButton():LocalizeAndSetText("TXT_KEY_BARBARIANS_EVOLVED_NOBODY");
		sBarbMajorAlly = "CIVILIZATION_INTENTIONALLY_INVALID";
	end

	AllyPulldown:GetButton():LocalizeAndSetToolTip("TXT_KEY_BESETTING_LABEL_ALLY_TIP");
end
AllyPulldown:RegisterSelectionCallback( AllyCivCallback );

PopulateCivPulldown(playableCivs, AllyPulldown);

-------------------------------------------------------------------------------------------------- STRINGS --------------------------------------------------------------------------------------------------
-- reorder strings array
function ReorderBarbNamesArray()
	arrReorder = {}

	print("ReorderBarbNamesArray: commencing rebuild...")

	for era in GameInfo.Eras() do
		for _, row in pairs(arrBarbNames) do
			if row[1] == era.Type then
				print("[" .. row[1] .. "], [" .. row[2] .. "], [" .. row[3] .. "], [" .. row[4] .. "], [" .. row[5] .. "]")
				table.insert(arrReorder, row)
			end
		end
	end

	arrBarbNames = {}
	arrBarbNames = arrReorder

	print("ReorderBarbNamesArray: rebuild complete.")
end

-- rebuild strings array
function RebuildBarbNames(inrow, incol, val)
	-- print("Updating [" .. inrow .. "]-[" .. incol .. "] to [" .. val .. "]");

	for _, row in pairs(arrBarbNames) do
		if row[1] == inrow then
			row[incol] = val
		end
	end
end

-- reset strings
function SetEraNames()
	local BEStringDefaults = Controls.BEDefaultEraStrings;
	local BEStringRows = Controls.BEStringRows;
	local BEStringScroll = Controls.BEStringScroll;

	-- import default strings
	Controls.EraDefault:SetText("All");
	Controls.AdjDefault:SetText(sBarbAdjDefault);
	Controls.DescrDefault:SetText(sBarbDescrDefault);
	Controls.ShortDefault:SetText(sBarbShortDefault);
	Controls.CampDefault:SetText(sBarbCampDefault);

	-- import era strings
	-- clear the stack first
	BEStringRows:DestroyAllChildren();

	for era in GameInfo.Eras() do
		local instance = {};
		ContextPtr:BuildInstanceForControl( "BEStringsInstance", instance, BEStringRows );
		instance.EraVal:LocalizeAndSetText(era.Description)
		instance.EraVal:SetDisabled(true)
		-- find the Era in presets
		bFoundEra = false
		for _, row in pairs(arrBarbNames) do
			if row[1] == era.Type then
				bFoundEra = true
				instance.AdjVal:LocalizeAndSetText(row[2])
				instance.AdjVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(row[1], 2, val) end)
				instance.DescrVal:LocalizeAndSetText(row[3])
				instance.DescrVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(row[1], 3, val) end)
				instance.ShortVal:LocalizeAndSetText(row[4])
				instance.ShortVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(row[1], 4, val) end)
				instance.CampVal:LocalizeAndSetText(row[5])
				instance.CampVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(row[1], 5, val) end)
			end
		end
		if not bFoundEra then
			-- another mod has added a new Era not found in the defaults; add it to the array and register callbacks
			print("SetEraNames: New era discovered [" .. era.Type .. "], adding to Names array...")
			newEra = {era.Type, "", "", "", ""}
			table.insert(arrBarbNames, newEra)
			ReorderBarbNamesArray()
			instance.AdjVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(era.Type, 2, val) end)
			instance.DescrVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(era.Type, 3, val) end)
			instance.ShortVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(era.Type, 4, val) end)
			instance.CampVal:RegisterCallback(function (val,obj,bfire) RebuildBarbNames(era.Type, 5, val) end)
		end
	end
	BEStringRows:CalculateSize()
	BEStringRows:ReprocessAnchoring()
	BEStringScroll:CalculateInternalSize()

	ShowHideEraNames()
end

function ShowHideEraNames()
	if bBarbEraNameChange then
		Controls.BEDefaultEraStrings:SetHide(true)
		Controls.BEStringRows:SetHide(false)
	else
		Controls.BEDefaultEraStrings:SetHide(false)
		Controls.BEStringRows:SetHide(true)
	end
end

-- default
-- SetEraNames();

-- colors
function SetDemoIconColors()
	for color in GameInfo.PlayerColors() do
		if (color.Type == sMinorPlayerColor) then
			-- print("MINOR match: Type [" .. color.Type .. "] Primary [" .. color.PrimaryColor .. "] Secondary [" .. color.SecondaryColor .. "] Text [" .. color.TextColor .. "]")
			Controls.MinorIconBG:SetColor( Vector4( GameInfo.Colors[color.SecondaryColor].Red, GameInfo.Colors[color.SecondaryColor].Green, GameInfo.Colors[color.SecondaryColor].Blue, GameInfo.Colors[color.SecondaryColor].Alpha ));
			Controls.MinorIconFG:SetColor( Vector4( GameInfo.Colors[color.PrimaryColor].Red, GameInfo.Colors[color.PrimaryColor].Green, GameInfo.Colors[color.PrimaryColor].Blue, GameInfo.Colors[color.PrimaryColor].Alpha ));
			local minortext = Locale.ConvertTextKey("TXT_KEY_BESETTING_LABEL_MINORBARB_COLOR")
			Controls.MinorIconText:SetText(string.format("[%s]%s[ENDCOLOR]", color.TextColor, minortext));
		end
		if (color.Type == sMajorPlayerColor) then
			-- print("MAJOR match: Type [" .. color.Type .. "] Primary [" .. color.PrimaryColor .. "] Secondary [" .. color.SecondaryColor .. "] Text [" .. color.TextColor .. "]")
			Controls.MajorIconBG:SetColor( Vector4( GameInfo.Colors[color.SecondaryColor].Red, GameInfo.Colors[color.SecondaryColor].Green, GameInfo.Colors[color.SecondaryColor].Blue, GameInfo.Colors[color.SecondaryColor].Alpha ));
			Controls.MajorIconFG:SetColor( Vector4( GameInfo.Colors[color.PrimaryColor].Red, GameInfo.Colors[color.PrimaryColor].Green, GameInfo.Colors[color.PrimaryColor].Blue, GameInfo.Colors[color.PrimaryColor].Alpha ));
			local majortext = Locale.ConvertTextKey("TXT_KEY_BESETTING_LABEL_MAJORBARB_COLOR")
			Controls.MajorIconText:SetText(string.format("[%s]%s[ENDCOLOR]", color.TextColor, majortext));
		end
	end
end

-------------------------------------------------
-- Colors pulldowns (based on game difficulty)
-------------------------------------------------
MinorColorPullDown = Controls.MinorColorPullDown;
MajorColorPullDown = Controls.MajorColorPullDown;

MinorColorPullDown:ClearEntries();
MajorColorPullDown:ClearEntries();

for color in GameInfo.PlayerColors() do
	local minorinstance = {};
	MinorColorPullDown:BuildEntry( "InstanceOne", minorinstance );
	minorinstance.Button:LocalizeAndSetText(color.Type);
	minorinstance.Button:SetVoid1( color.ID );

	local majorinstance = {};
	MajorColorPullDown:BuildEntry( "InstanceOne", majorinstance );
	majorinstance.Button:LocalizeAndSetText(color.Type);
	majorinstance.Button:SetVoid1( color.ID );
end

MinorColorPullDown:CalculateInternals();
MajorColorPullDown:CalculateInternals();

function MinorColorCallback(id)
	local color = GameInfo.PlayerColors[id]

	print("MinorColorCallback: " .. color.Type)

	MinorColorPullDown:GetButton():LocalizeAndSetText(color.Type)

	sMinorPlayerColor = color.Type
	SetDemoIconColors()
end
MinorColorPullDown:RegisterSelectionCallback( MinorColorCallback );

function MajorColorCallback(id)
	local color = GameInfo.PlayerColors[id]

	print("MajorColorCallback: " .. color.Type)

	MajorColorPullDown:GetButton():LocalizeAndSetText(color.Type)

	sMajorPlayerColor = color.Type
	SetDemoIconColors()
end
MajorColorPullDown:RegisterSelectionCallback( MajorColorCallback );

-- default
-- SetDemoIconColors();

-------------------------------------------------------------------------------------------------- SAVE/LOAD --------------------------------------------------------------------------------------------------

function CommitSettings()
	print("Applying and saving settings...")

	-- display & save
	userData = Modding.OpenUserData("BE", 1)

	BEWriteData(userData)

	-- apply what needs to be applied
	print("Setting Raging Barbarians option...")
	PreGame.SetGameOption("GAMEOPTION_RAGING_BARBARIANS", bRagingBarbarians)

	print("Checking if Barbarians evolve into City States...")
	if bBarbEvolveCityStates then
		-- print("Disabling Tribal Barbarians.")
		print("State-Sponsored Encampments will be placed at City State starting plots.")
		-- PreGame.SetGameOption("GAMEOPTION_NO_BARBARIANS", true)
	end

	local oAlly = GameInfo.Civilizations[sBarbMajorAlly]

	print("Checking if Barbarian ally is valid...")
	if (oAlly ~= nil) then
		print("Ally is valid.  Checking if we should pre-set slot 0 or 1...")
		if bBarbMajorAllyExists then
			if bBarbMajorAllyAsMe then
				print("Placed the Barbarian ally in slot 0.")
				PreGame.SetCivilization(0, GameInfo.Civilizations[sBarbMajorAlly].ID);
				-- PreGame.SetPlayerColor(0, GameInfo.PlayerColors[sMajorPlayerColor].ID);
			else
				print("Placed the Barbarian ally in slot 1.")
				PreGame.SetCivilization(1, GameInfo.Civilizations[sBarbMajorAlly].ID);
				-- PreGame.SetPlayerColor(1, GameInfo.PlayerColors[sMajorPlayerColor].ID);
			end
		end
	else
	--[[
		print("Ally is not valid.  Setting playable flag to false for Barbarian major civ.")
		allysql = "UPDATE Civilizations SET Playable = 0 WHERE Type = 'CIVILIZATION_BARBARIAN_MAJOR'"
		for allyrow in DB.Query(allysql) do
		end
	]]--
	end

	-- apply spawn chance to game difficulty
	-- PreGame.SetHandicap(0, iSpawnChance);
end