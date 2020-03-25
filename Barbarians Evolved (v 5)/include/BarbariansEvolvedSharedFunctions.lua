-- BarbariansEvolvedSharedFunctions
-- Author: Charsi
-- DateCreated: 04/14/2016 6:55:41 PM
--------------------------------------------------------------

--########################################################################
-- a string split function, source:
-- http://lua-users.org/wiki/SplitJoin
-- Compatibility: Lua-5.1
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

--########################################################################
-- test against a specific hardcoded value to determine if there's anything in this object
function BEDataExists(beData)
	-- this one hardcoded value is ALWAYS true if it has ever been set
	if (beData.GetValue("bSettingsExist") ~= nil) then
		print("BE settings detected: [" .. beData.GetValue("bSettingsExist") .. "]")
		return true
	end

	return false
end

--########################################################################
-- writes data to the object (which might be a modding.openuserdata or modding.opensavedata object)
function BEWriteData(beData)
	-- strings used in Set/GetValue ARE case sensitive!
	beData.SetValue("bSettingsExist", true)
	beData.SetValue("bConservativeMode", bConservativeMode)
	beData.SetValue("iBaseTurnsPerBarbEvolution", iBaseTurnsPerBarbEvolution)
	beData.SetValue("bDisableBarbHealing", bDisableBarbHealing)
	beData.SetValue("bDisableBarbSpawn", bDisableBarbSpawn)
	beData.SetValue("bDisableBarbSpawnForAlly", bDisableBarbSpawnForAlly)
	beData.SetValue("bDisableBarbSpawnForMe", bDisableBarbSpawnForMe)
	beData.SetValue("bDisableSponsoredSpawns", bDisableSponsoredSpawns)
	beData.SetValue("iSpawnChance", iSpawnChance)
	beData.SetValue("bDisableBarbEvolution", bDisableBarbEvolution)
	beData.SetValue("bBarbEvolveSettlers", bBarbEvolveSettlers)
	beData.SetValue("bBarbEvolveCityStates", bBarbEvolveCityStates)
	beData.SetValue("bDisableBarbCapture", bDisableBarbCapture)
	beData.SetValue("bRequireMeleeCapture", bRequireMeleeCapture)
	beData.SetValue("bDisableGlobalUpgrade", bDisableGlobalUpgrade)
	beData.SetValue("bDisableGlobalUpgradeForMe", bDisableGlobalUpgradeForMe)
	beData.SetValue("sBarbLiberateTo", sBarbLiberateTo)
	beData.SetValue("bBarbDisperseOnLiberate", bBarbDisperseOnLiberate)
	beData.SetValue("sBarbMajorAlly", sBarbMajorAlly)
	beData.SetValue("bBarbMajorAllyExists", bBarbMajorAllyExists)
	beData.SetValue("arrBarbLandUnitPromotions", table.concat(arrBarbLandUnitPromotions, ","))	-- use a temporary comma delimited string (arrays not supported)
	beData.SetValue("arrBarbSeaUnitPromotions", table.concat(arrBarbSeaUnitPromotions, ","))	-- use a temporary comma delimited string (arrays not supported)
	beData.SetValue("arrBarbAirUnitPromotions", table.concat(arrBarbAirUnitPromotions, ","))	-- use a temporary comma delimited string (arrays not supported)
	beData.SetValue("bBarbEraNameChange", bBarbEraNameChange)
	beData.SetValue("bDeferNameChange", bDeferNameChange)
	beData.SetValue("sBarbAdjDefault", sBarbAdjDefault)
	beData.SetValue("sBarbDescrDefault", sBarbDescrDefault)
	beData.SetValue("sBarbShortDefault", sBarbShortDefault)
	beData.SetValue("sBarbCampDefault", sBarbCampDefault)
	-- create a temporary superstring for arrBarbNames... and hope there isn't a character limit on this!
	ssBarbNames = ""
	for _, row in pairs(arrBarbNames) do
		-- 06/27 don't concatenate (save) nullstring name rows
		if (row[2] ~= "") and (row[3] ~= "") and (row[4] ~= "") and (row[5] ~= "") then
			local newstr = table.concat(row, ",")
			ssBarbNames = ssBarbNames .. "|" .. newstr
		end
	end
	beData.SetValue("bDisableBuildingEncampmentsForAll", bDisableBuildingEncampmentsForAll)
	beData.SetValue("bDisableBuildingEncampmentsForOthers", bDisableBuildingEncampmentsForOthers)
	beData.SetValue("arrBarbNames", ssBarbNames)
	beData.SetValue("iBarbNukeLimit", iBarbNukeLimit)
	beData.SetValue("iBarbWorkerLimit", iBarbWorkerLimit)
	beData.SetValue("sMinorPlayerColor", sMinorPlayerColor)
	beData.SetValue("sMajorPlayerColor", sMajorPlayerColor)
end

--########################################################################
-- ReportRead - spams out the reads to debug (because they're all strings, right?)
-- also forces typing by converting string'd booleans and ints to their respective types
-- 2016-12-02: thanks to user Mile on steam, fixed not accounting for NULL - thanks
function BEReportRead(dataobj, datastring)
	retval = dataobj.GetValue(datastring)
	if (retval == nil) then
		print("READ: " .. datastring .. " [ERROR: NULL VALUE]")
	else
		print("READ: " .. datastring .. " [" .. dataobj.GetValue(datastring) .. "]")
	end

	-- what we return depends on what type it is, fortunately I use Hungarian out of habit, saved my ass here
	-- yes, I know lua isn't strongly typed, I don't care
	firstchar = string.sub(datastring, 1, 1)

	-- boolean
	if (firstchar == "b") then
		if (retval == nil) then
			return false
		else
			if (retval == 0) then
				return false
			else
				return true
			end
		end
	end

	-- integer
	if (firstchar == "i") then
		if (retval == nil) then
			return 0
		else
			return tonumber(retval)
		end
	end

	-- string or array masquerading as string
	if (retval == nil) then
		return ""
	else
		return retval
	end
end

--########################################################################
-- reads data from the object (which might be a modding.openuserdata or modding.opensavedata object)
function BEReadData(beData)
	-- strings used in Set/GetValue ARE case sensitive!
	bConservativeMode = BEReportRead(beData, "bConservativeMode")
	iBaseTurnsPerBarbEvolution = BEReportRead(beData, "iBaseTurnsPerBarbEvolution")
	bDisableBarbHealing = BEReportRead(beData, "bDisableBarbHealing")
	bDisableBarbSpawn = BEReportRead(beData, "bDisableBarbSpawn")
	bDisableBarbSpawnForAlly = BEReportRead(beData, "bDisableBarbSpawnForAlly")
	bDisableBarbSpawnForMe = BEReportRead(beData, "bDisableBarbSpawnForMe")
	bDisableSponsoredSpawns = BEReportRead(beData, "bDisableSponsoredSpawns")
	iSpawnChance = BEReportRead(beData, "iSpawnChance")
	bDisableBarbEvolution = BEReportRead(beData, "bDisableBarbEvolution")
	bBarbEvolveSettlers = BEReportRead(beData, "bBarbEvolveSettlers")
	bBarbEvolveCityStates = BEReportRead(beData, "bBarbEvolveCityStates")
	bDisableBarbCapture = BEReportRead(beData, "bDisableBarbCapture")
	bRequireMeleeCapture = BEReportRead(beData, "bRequireMeleeCapture")
	bDisableGlobalUpgrade = BEReportRead(beData, "bDisableGlobalUpgrade")
	bDisableGlobalUpgradeForMe = BEReportRead(beData, "bDisableGlobalUpgradeForMe")
	sBarbLiberateTo = BEReportRead(beData, "sBarbLiberateTo")
	bBarbDisperseOnLiberate = BEReportRead(beData, "bBarbDisperseOnLiberate")
	sBarbMajorAlly = BEReportRead(beData, "sBarbMajorAlly")
	bBarbMajorAllyExists = BEReportRead(beData, "bBarbMajorAllyExists")
	strBarbLandUnitPromotions = BEReportRead(beData, "arrBarbLandUnitPromotions")
	arrBarbLandUnitPromotions = split(strBarbLandUnitPromotions, ",")	-- rebuild array from comma delimited string (arrays not supported)
	strBarbSeaUnitPromotions = BEReportRead(beData, "arrBarbSeaUnitPromotions")
	arrBarbSeaUnitPromotions = split(strBarbSeaUnitPromotions, ",")		-- rebuild array from comma delimited string (arrays not supported)
	strBarbAirUnitPromotions = BEReportRead(beData, "arrBarbAirUnitPromotions")
	arrBarbAirUnitPromotions = split(strBarbAirUnitPromotions, ",")		-- rebuild array from comma delimited string (arrays not supported)
	bBarbEraNameChange = BEReportRead(beData, "bBarbEraNameChange")
	bDeferNameChange = BEReportRead(beData, "bDeferNameChange")
	sBarbAdjDefault = BEReportRead(beData, "sBarbAdjDefault")
	sBarbDescrDefault = BEReportRead(beData, "sBarbDescrDefault")
	sBarbShortDefault = BEReportRead(beData, "sBarbShortDefault")
	sBarbCampDefault = BEReportRead(beData, "sBarbCampDefault")
	-- rebuild an array within an array from the temporary superstring for arrBarbNames...
	arrBarbNames = {}
	ssBarbNames = BEReportRead(beData, "arrBarbNames")
	arrBarbEras = split(ssBarbNames, "|")
	for _, row in pairs(arrBarbEras) do
		local arrEra = {}
		arrEra = split(row, ",")
		table.insert(arrBarbNames, arrEra)
	end
	bDisableBuildingEncampmentsForAll = BEReportRead(beData, "bDisableBuildingEncampmentsForAll")
	bDisableBuildingEncampmentsForOthers = BEReportRead(beData, "bDisableBuildingEncampmentsForOthers")
	iBarbNukeLimit = BEReportRead(beData, "iBarbNukeLimit")
	iBarbWorkerLimit = BEReportRead(beData, "iBarbWorkerLimit")
	sMinorPlayerColor = BEReportRead(beData, "sMinorPlayerColor")
	sMajorPlayerColor = BEReportRead(beData, "sMajorPlayerColor")
end