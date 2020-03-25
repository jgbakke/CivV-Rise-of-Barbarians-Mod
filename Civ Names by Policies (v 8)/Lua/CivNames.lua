-- Some settings

-- 1 - English Kingdom
-- 2 - Kingdom of England
-- 0 - Random choise
local defaultForm = 2

local shortNameMaxLen = 21
local minPeriod = 10

local useForMinors = false

local useSoviet = true -- If not "council" will be used
local useFascist = true -- If not only "of ... Nation" will be used
local useReich = true -- If not "Empire" will be used

-- end of settings


-- Now it's code begining, don't change it if you don't know what you're doing.
include( "GameplayUtilities" );

MapModData.leaderTitles = MapModData.leaderTitles or {}
MapModData.govs = MapModData.govs or {}

local debug = false
local debugNewName = false
local debugCalc = false
local debugParts = false
local debugVassals = false

local starting = true
local vassalMod = true

local holyCityMul = 1.5

local eraEarly = 5
local eraMed = 8
local eraRen = 12
local eraInd = 16

local usingParts = {
	["Primitive"] = {"state"},
	["Chiefdom"] = {"state", "gr"},
	["Early"] = {},
	["Communist"] = {"state", "theo", "sov", "dem", "fc", "pre"},
	["Autocracy"] = {"state", "pre", "gr", "theo", "nat"},
	["Liberty"] = {"state", "theo", "fc", "dem"},
	["Theocratic"] = {"state", "gr", "religion", "fc", "dem"}
}

function maxCivs()
	if (useForMinors) then
		return GameDefines.MAX_CIV_PLAYERS
	else
		return GameDefines.MAX_MAJOR_CIVS
	end
end

local flavour = {
	SIKHISM = "HINDUISM",
	TAOISM = "CONFUCIANISM"	
}

local pols = {"TRADITION", "LIBERTY", "HONOR", "PATRONAGE", "PIETY", "FREEDOM", "ORDER", "AUTOCRACY", "RATIONALISM", "COMMERCE", "AESTHETICS", "EXPLORATION"}

function ForPols(f)
	for i, p in pairs(pols) do
		f(p)
	end
end

function Name(table, key, defaultValue)
	local v = table[key]
	if (v == nil) then 
		return defaultValue
	else
		return v
	end
end

function trim(s)
  return s:match "^%s*(.-)%s*$"
end

function RelScore(relPercent)
	local n = relPercent + 0.1
	return 10 * n * n * n
end

function CivInfo(id)
	return CivInfoEx(id, true)
end

function CivInfoEx(id, aliveOnly)
	local player = Players[id]
	if( player and (not aliveOnly or player:IsAlive()) ) then
		if (id < GameDefines.MAX_MAJOR_CIVS) then
			local civType = player:GetCivilizationType();
			return GameInfo.Civilizations[ civType ];
		else
			local minorCivType = player:GetMinorCivType();
			return GameInfo.MinorCivilizations[minorCivType];
		end
	else 
		return nil
	end
end

function DebugOut(pd)
	if (debugCalc) then 
		print("CivId " .. pd.id)

		ForPols(function(p)
			print(p .. ": " .. pd[p])
		end)

		print("Comm. Level " .. tostring(pd.commLevel))
		print("Liberty Level " .. tostring(pd.libertyLevel))
		print("Autocracy Level " .. tostring(pd.autocracyLevel))
		print("Theoc. Level " .. tostring(pd.theoLevel))
		print("Progress " .. tostring(pd.progress))

		print("Cities " .. tostring(pd.cities))
		print("Puppets " .. tostring(pd.puppets))
		print("Minors " .. tostring(pd.minors))
		print("All Cities " .. tostring(pd.allCities))

		print("Units " .. toString(pd.units))

		print("Power " .. tostring(pd.power))
	end
end

function DebugParts(pd)
	if (debugParts) then
		if (pd == nil) then
			print("nil")
		else
			print("Way: " .. pd.way)
			print("WayType: " .. pd.wayType)
			print("Religion: " .. pd.religion)
			print("Pre: " .. pd.pre)
			print("Dem: " .. pd.dem)
			print("Sov: " .. pd.sov)
			print("State: " .. pd.state)
			print("Theo: " .. pd.theo)
			print("Gr: " .. pd.gr)
			print("Const: " .. pd.const)
			print("Nat: " .. pd.nat)
			print("Fc: " .. pd.fc)
			print("")
		end
	end
end 

function MinorPolicies(pd)
	local masterId = Master(pd.id)

	if (masterId >= 0) then
		local master = MapModData.govs[masterId]
		if master ~= nil then 
			ForPols(function(p)
				pd[p] = master[p] * 0.8
			end)
		else
			MinorPoliciesMean(pd)
		end
	else
		MinorPoliciesMean(pd)
	end

	local iTrait = pd.player:GetMinorCivTrait();
    if( iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_CULTURED ) then
        pd.TRADITION = pd.TRADITION * 2
    elseif( iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MILITARISTIC ) then
        pd.HONOR = pd.HONOR * 2
    elseif( iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MARITIME ) then
        pd.RATIONALISM = pd.RATIONALISM * 2
    elseif(iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_MERCANTILE) then
        pd.COMMERCE = pd.COMMERCE * 2
    elseif(iTrait == MinorCivTraitTypes.MINOR_CIV_TRAIT_RELIGIOUS) then
        pd.PIETY = pd.PIETY * 2
    end
end

function MinorPoliciesMean(pd)
	local count = 0
	local vals = {}

	ForPols(function (p)
		vals[p] = 0
	end)
	
	for id = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
		if(CivInfo(id)) then
			local other = MapModData.govs[id]
			
			if(Teams[ other.player:GetTeam() ]:IsHasMet(pd.player:GetTeam()) ) then
				count = count + 1
				ForPols(function (p)
					vals[p] = vals[p] + other[p]
				end)
			else
				count = count + 0.3
			end
		end
	end

	if (count == 0) then count = 1 end

	ForPols(function (p)
		pd[p] = vals[p] / count
	end)
end

function Units(id)
	local calc = 0
	if (Players[id] ~= nil and Players[id]:IsAlive()) then
		for unit in Players[id]:Units() do
			if( unit:GetUnitCombatType() ~= -1 and not unit:CanNuke() ) then
				calc = calc + 1
			end
		end
	end
	return calc
end

function CreateData(id)
	local pd = {}

	pd.id = id
	pd.player = Players[id]
	pd.civInfo = CivInfo(id)	

	if (pd.civInfo) then 
		pd.shortDescKey = pd.player:GetCivilizationShortDescriptionKey()
		pd.shortDescText = ShortDesc(pd.id)
		
		local last = MapModData.govs[pd.id]
		if (last ~= nil) then
			pd.currentName = last.name
		else
			pd.currentName = pd.shortDescText
		end

		pd.name = ""
		pd.shortName = ""
		pd.fullName = pd.name

		pd.ps = Policies(id)

		if (pd.id < GameDefines.MAX_MAJOR_CIVS) then
			ForPols(
				function (p)
					pd[p] = pd.ps["POLICY_BRANCH_" .. p]
				end
			)
		else
			MinorPolicies(pd)
		end

		pd.minors = Minors(pd.id)
		pd.cities = pd.player:GetNumCities()
		pd.puppets = Puppets(pd.id)
		pd.isVassal = Master(pd.id) >= 0

		pd.units = Units(pd.player:GetNumUnits()) / 15

		pd.wayType = "Unknown"
		pd.religion, pd.relScore = Religion(pd.id)
		pd.pre = ""
		pd.dem = ""
		pd.sov = ""
		pd.state = ""
		pd.theo = ""
		pd.gr = ""
		pd.const = ""
		pd.nat = ""
		pd.fc = ""
		
		pd.masterOf = "puppets"
		pd.puppetOf = "puppet"

		pd.title = "Lord"

		pd.turn = 0

		pd.form = 0
	end

	return pd
end

function EqualGov(pd1, pd2)
	if (pd2 == nil or pd1.wayType ~= pd2.wayType) then
		return false
	end

	for k, v in pairs(usingParts[pd1.wayType]) do
		if pd1[v] ~= pd2[v] then
			return false
		end
	end

	return true
end

function RandomStat(pd, i)
	local p1 = math.max(0, (i + 1) * 2)
	local p2 = math.max(0, (i + 0) * 2)
	local p3 = math.max(0, (i - 1) * 2)
	local p4 = math.max(0, (i - 2) * 2)
	local p5 = math.max(0, (i - 3) * 2)

	ForPols(function (p)
		pd[p] = math.min(6, math.random(0, p1))
	end)

	pd.FREEDOM = 0
	pd.ORDER = 0
	pd.AUTOCRACY = 0

	local way = math.random(1, 3)

	if (way == 1) then
		pd.FREEDOM = math.min(25, math.random(0, p5))
	elseif (way == 2) then
		pd.ORDER = math.min(25, math.random(0, p5)) * 2
	else
		pd.AUTOCRACY = math.min(25, math.random(0, p5))
	end

	if (pd.id < GameDefines.MAX_MAJOR_CIVS) then
		local r = math.random()
		pd.cities = r*r*(3*i + 1)
	
		r = math.random()
		pd.minors = r*r*6
	
		r = math.random()
		pd.puppets = pd.cities * r * r
	else
		pd.cities = math.random(1, 2)
		pd.minors = 0
		pd.puppets = 0
	end

	pd.units = math.sqrt(1, math.random(10000)) / 15

	local n = 0
	local rels = {}
	for pReligion in GameInfo.Religions() do
		n = n + 1
		rels[n] = pReligion.ID
	end
	pd.religion = Game.GetReligionName(rels[math.random(1, n)])
	
	r = math.random()
	pd.relScore = r * r
end

function Calculations(pd)
	pd.pureProgress = pd.LIBERTY + pd.FREEDOM + pd.RATIONALISM + pd.COMMERCE + pd.EXPLORATION + pd.AESTHETICS + pd.PATRONAGE

	pd.progress = pd.pureProgress + pd.TRADITION
	pd.commProgress = pd.pureProgress + pd.ORDER
	pd.fullProgress = pd.progress + pd.HONOR + pd.PIETY

	pd.med = pd.fullProgress > eraMed
	pd.ren = pd.fullProgress > eraRen
	pd.ind = pd.fullProgress > eraInd

	pd.libertyLevel = pd.FREEDOM + pd.LIBERTY + pd.COMMERCE
	pd.autocracyLevel = pd.AUTOCRACY + pd.TRADITION + pd.HONOR + pd.PIETY
	pd.commLevel = pd.ORDER + pd.RATIONALISM + pd.PATRONAGE
	if (not pd.ind) then pd.commLevel = 0 end
	pd.theoLevel = pd.PIETY

	if (pd.religion == "") then 
		pd.theoLevel = 0
	else 
		pd.theoLevel = pd.theoLevel + RelScore(pd.relScore)
	end

	pd.way = math.max(pd.commLevel, pd.autocracyLevel)
	pd.way = math.max(pd.way, pd.libertyLevel)
	pd.way = math.max(pd.way, pd.theoLevel)

	if (pd.commLevel == pd.way) then
		pd.way = "Communist"
	elseif (pd.autocracyLevel == pd.way) then 
		pd.way = "Autocracy"
	elseif (pd.libertyLevel == pd.way) then
		pd.way = "Liberty"
	else
		pd.way = "Theocratic"
	end

	pd.wayType = pd.way

	pd.allCities = pd.cities + pd.minors
	pd.allPuppets = pd.puppets + pd.minors
					
	pd.one = pd.allCities <= 1
	pd.two = pd.allCities <= 2
	pd.small = pd.allCities <= 3
	pd.big = pd.allCities > 7

	pd.power = pd.allCities + pd.HONOR

	pd.huge = pd.power >= 13
	pd.great = pd.power >= 18
		
	pd.theocratic = (1.5 * pd.theoLevel) > pd.progress

	pd.federal = pd.allPuppets > (pd.cities/3)
	pd.united = pd.allPuppets > (pd.cities/2)
	pd.confed = 2*pd.minors + pd.puppets > pd.cities
	pd.union = (pd.federal or pd.confed)

	pd.unitary = pd.allPuppets < (0.2 * pd.cities)
	pd.diarchy = pd.minors > pd.cities

	pd.hugeUnion = pd.huge and pd.union
	pd.empire = pd.hugeUnion or pd.great
	pd.fascEmpire = pd.union or pd.big
	pd.smallEmpire = pd.big and pd.confed
	pd.autEmpire = pd.smallEmpire or pd.hugeUnion

	pd.dictatorship = (pd.AUTOCRACY + 2*pd.HONOR) > (pd.progress + pd.cities/2 + pd.puppets/3)
	pd.commDictatorship = 1.5*pd.autocracyLevel > (pd.libertyLevel + pd.commLevel)
	pd.demDictatorship = pd.commDictatorship
	pd.fascist = pd.AUTOCRACY + pd.HONOR + pd.units >= 12

	pd.canBeDemocratic = (pd.progress > 12) and not pd.dictatorship and (pd.LIBERTY > 3)
	pd.republic = (pd.LIBERTY + pd.RATIONALISM + pd.FREEDOM + pd.ORDER + pd.COMMERCE) >= (pd.TRADITION + pd.PIETY + pd.HONOR + pd.AUTOCRACY)
	pd.democratic = (pd.libertyLevel >= 1.2*pd.autocracyLevel) and pd.canBeDemocratic
	pd.council = pd.democratic and (pd.commLevel > 1.5*pd.autocracyLevel)
	pd.soviet = 1.5 * pd.commLevel >= (pd.libertyLevel + pd.autocracyLevel) and pd.democratic
	pd.aDemocratic = pd.democratic or pd.soviet or pd.council
	pd.war = 2*pd.HONOR > pd.pureProgress
	pd.land = (pd.TRADITION + pd.HONOR) > (pd.LIBERTY + pd.PIETY) and pd.TRADITION > 0 and pd.HONOR > 0
	pd.clan = (pd.TRADITION + pd.LIBERTY) > (pd.PIETY + pd.HONOR) and pd.TRADITION > 0 and pd.LIBERTY > 0

	if (pd.religion == "TXT_KEY_RELIGION_PANTHEON") then
		pd.religion = ""
	end

	pd.rel = pd.religion:gsub("TXT_KEY_RELIGION_", "")
	local fl = flavour[pd.rel]
	if(fl == nil) then
		pd.flavour = pd.rel
	else
		pd.flavour = fl
	end

	pd.merchant = pd.small and 2*pd.COMMERCE > (pd.HONOR + pd.TRADITION) and pd.COMMERCE > 2 and pd.demDictatorship
end

function PrimitiveGov(pd)
	pd.masterOf = "puppets"
	pd.puppetOf = "puppet"

	pd.state = "Tribe"
	pd.title = "Elder"
	pd.form = 1

	if (pd.big) then
		pd.state = "Tribal Union"
	elseif (pd.two) then
		pd.state = "Tribe"
	else
		pd.state = "Tribes"
	end

	if (pd.theocratic) then
		pd.title = "High Shaman"
	end
end

function ChiefdomGov(pd)
	pd.masterOf = "puppets"
	pd.puppetOf = "puppet"

	pd.form = 1

	if (EmpireAut(pd)) then
	elseif (pd.confed and not pd.small) then
		pd.masterOf = "members"
		pd.puppetOf = "member"
		pd.state = "League"
		pd.title = "Representative"
	elseif (pd.clan) then
		pd.state = "Clan"
		pd.title = "Clan Chief"
	elseif(pd.land) then
		pd.state = "Land"
		pd.title = "Lord"
	elseif (pd.way == "Liberty") then 
		pd.state = "Republic"
		pd.title = Pres(pd.fullProgress)
	elseif (pd.way == "Theocratic") then
		pd.title = "High Priest"
		pd.state = "Priestdom"
	else
		pd.state = "Chiefdom"
		if not pd.small then
			pd.title = "High Chief"
		else
			pd.title = "Chief"
		end
	end
end

function EarlyGov(pd)
	ChiefdomGov(pd)

	if (pd.state == "Clan" or pd.state == "Land") then
		pd.state = ""
		pd.title = "Lord"
		pd.form = 2
	else
		pd.wayType = "Chiefdom"
	end
end

function Federation(pd, orElse)
	if (pd.confed) then 
		pd.state = "Confederation"
		pd.masterOf = "assosiated members"
		pd.puppetOf = "assosiated member"
		pd.form = 1
	elseif (pd.federal) then 
		pd.state = "Federation"
		pd.masterOf = "autonomous regions"
		pd.puppetOf = "autonomous region"
		pd.form = 1
	else pd.state = orElse end
end

function Federal(pd) 
	if (pd.confed) then 
		pd.fc = "Confederate"
		pd.masterOf = "assosiated members"
		pd.puppetOf = "assosiated member"
	elseif (pd.federal) then 
		pd.fc = "Federal" 
		pd.masterOf = "autonomous regions"
		pd.puppetOf = "autonomous region"
	end
end

function CityState(pd)
	if (pd.one) then 
		pd.state = "City-State"
		pd.form = 2
	elseif (pd.small) then 
		pd.state = "City-States"
		pd.form = 1
	else return false end

	return true
end

function CommunistGov(pd)
	if (pd.commDictatorship) then 
		pd.pre = "Proletariat"
		pd.title = "People's Commissar"
	elseif (pd.commLevel >= 20) then 
		pd.pre = "Communist"
		pd.title = "Comrade"
	elseif (pd.commLevel >= 13) then 
		pd.pre = "Socialist"
		if (pd.soviet) then 
			if (useSoviet) then
				pd.title = "Chairman of Supreme Soviet"
			else
				pd.title = "Chairman of Supreme Council"
			end
		elseif (pd.democratic) then 
			pd.title = "Chairman of Supreme Assembly"
		else 
			pd.title = "Prime Minister"
		end
	else 
		pd.pre = "People's"
		pd.title = "President"
	end

	pd.masterOf = "lesser partners"
	pd.puppetOf = "lesser partner"
			
	if ( pd.empire ) then
		pd.state = "Union"
		if (pd.confed) then 
			pd.fc = "Confederate"
		end
		pd.masterOf = "assosiated members"
		pd.puppetOf = "assosiated member"
		pd.form = 1
		
	elseif (pd.republic) then
		pd.state = "Republic"
		Federal(pd)
	else
		pd.masterOf = "puppets"
		pd.puppetOf = "puppet"
		Federation(pd, "State")
	end

	if (pd.soviet) then 
		if (useSoviet) then
			pd.sov = "Soviet"
		else
			pd.sov = "Council"
		end
	elseif (pd.democratic) then 
		pd.dem = "Democratic" 
	end
end

function EmpireAut(pd)
	if (pd.great or pd.autEmpire) then 
		pd.state = "Empire"
		pd.title = "Emperor"
		pd.form = 1

		if (pd.great) then
			pd.gr = "Great"
		end
		return true
	end
	return false
end

function JapAut(pd)
	if (pd.flavour ~= "SHINTO" or not pd.med or pd.empire) then
		return false
	elseif (pd.fascEmpire) then
		if (pd.huge) then
			pd.gr = "Great"
		end

		pd.state = "Shogunate"
		pd.title = "Shogun"
	else
		if (not pd.small) then
			pd.gr = "Great"
		end
							
		pd.state = "Daimyo"
		if pd.ren then
			pd.title = "Kinsei"
		else
			pd.title = "Daimyo"
		end
	end

	return true
end

function IndAut(pd)
	if (pd.flavour ~= "HINDUISM" or not pd.med or pd.empire) then
		return false
	elseif (pd.fascEmpire) then
		if (pd.huge) then
			pd.gr = "Great"
		end
		
		pd.state = "Maharaj"
		pd.title = "Maharaja"
	else
		if (pd.big) then
			pd.gr = "Great"
		end
		pd.state = "Raj"
		pd.title = "Raja"
	end

	return true
end

function IslAut(pd)
	if (pd.flavour ~= "ISLAM" or not pd.med) then
		return false
	elseif (pd.great) then
		pd.state = "Caliphate"
		pd.title = "Caliph"
		pd.form = 1
	elseif (not pd.big) then
		if (pd.unitary) then
			pd.state = "Emirate"
		else
			pd.form = 1
			pd.state = "Emirates"
			
			if (pd.united) then 
				pd.gr = "United"
			end
		end
							
		pd.title = "Emir"
	else
		if (pd.huge) then
			pd.gr = "Great"
		end

		pd.state = "Sultanate"
		pd.title = "Sultan"
	end

	return true
end

function MonAut(pd)
	if (pd.flavour ~= "TENGRIISM" or not pd.med) then
		return false
	elseif (pd.empire) then
		if (pd.huge) then
			pd.gr = "Great"
		end
		
		pd.state = "Khaganate"
		pd.title = "Khagan"
	else
		if (pd.big) then
			pd.gr = "Great"
		end
		
		pd.state = "Khanate"
		pd.title = "Khan"
	end
					
	return true	
end

function Prince(pd, grand)
	pd.state = "Principality"
	pd.title = "Prince"
	if (grand) then
		pd.gr = "Grand"
		pd.title = "Grand Prince"
	end
end

function AutocracyGov(pd)
	
	--Fascism way
	if (pd.fascist) then
		pd.masterOf = "satellite states"
		pd.puppetOf = "satellite state"
		
		if (pd.empire and useReich) then 
			pd.state = "Reich"
			pd.form = 1
		elseif (CityState(pd)) then 
			pd.state = pd.state
		elseif (pd.fascEmpire) then 
			pd.state = "Empire"
			pd.form = 1
		else 
			pd.state = "State" 
		end
					
		pd.title = "Head of Government"

	-- Monarchy way
	else
		if (pd.med) then
			pd.masterOf = "vassals"
			pd.puppetOf = "vassal"
		elseif(pd.ind) then
			pd.masterOf = "protectorates"
			pd.puppetOf = "protectorate"			
		else
			pd.masterOf = "puppets"
			pd.puppetOf = "puppet"
		end

		if(MonAut(pd)) then		
		elseif(IslAut(pd)) then
		elseif(JapAut(pd)) then
		elseif(IndAut(pd)) then
		elseif (EmpireAut(pd)) then
		elseif (not pd.small and pd.united and pd.ren) then 
			if (pd.republic) then 
				pd.state = "Commonwealth"
				pd.masterOf = "members"
				pd.puppetOf = "member"
				pd.title = "Lord Protector"
				pd.form = 1
			else 
				pd.state = "United Kingdom"
				pd.masterOf = "lesser partners"
				pd.puppetOf = "member"
				pd.title = "King"
			end
		elseif (not pd.huge and pd.diarchy and pd.med) then
			Prince(pd, pd.big)
		elseif (not pd.big and pd.dictatorship) then 
			pd.masterOf = "puppets"
			pd.puppetOf = "puppet"
			pd.state = "Despotate"
			pd.title = "Despot"
		elseif (pd.one and pd.med) then 
			if (pd.flavour == "PROTESTANTISM") then
				pd.state = "Earldom"
				pd.title = "Earl"
			else
				pd.state = "County"
				pd.title = "Count"
			end
		elseif (pd.small and pd.med) then 
			if (pd.flavour == "ORTHODOXY") then
				Prince(pd, not pd.two)
			else 
				pd.state = "Duchy"
				pd.title = "Duke"
				if (not pd.two) then 
					pd.gr = "Grand"
				end
			end
		elseif (pd.small and pd.isVassal) then
			pd.state = "Province"
			pd.title = "Lord"
		elseif (pd.huge) then 
			pd.state = "Kingdom"
			pd.gr = "Great"
			pd.title = "King"
		else 
			pd.state = "Kingdom" 
			pd.title = "King"
		end
	end

	if (pd.theocratic) then 
		pd.theo = "Holy" 
	end

	-- Fascism way
	local level = pd.autocracyLevel + pd.units
	if (level >= 20 and useFascist) then 
		pd.masterOf = "satellite states"
		pd.puppetOf = "satellite state"

		pd.pre = "Fascist"
		if (pd.state == "Reich") then pd.title = "Fuehrer" end
	elseif (level > 14 and not pd.small) then
		pd.masterOf = "satellite states"
		pd.puppetOf = "satellite state"
		pd.form = 3
		pd.nat = "Nation" 
	end
end

function LibertyGov(pd)
	pd.title = Pres(pd.fullProgress)

	pd.masterOf = "protectorates"
	pd.puppetOf = "protectorate"

	pd.state = "Republic"

	if (pd.hugeUnion) then 
		pd.state = "States"
		if (pd.confed) then pd.fc = "Confederate" 
		else pd.fc = "United" end
		pd.form = 1
		pd.masterOf = "assosiated members"
		pd.puppetOf = "assosiated member"
	elseif (pd.merchant) then
		pd.fc = "Merchant" 
		pd.title = "Doge"
	elseif (not pd.demDictatorship) then
		Federal(pd)
		if (pd.confed) then 
			pd.title = "Chairman of Federal Assembly"
		end
	else
		if (CityState(pd)) then pd.state = pd.state
		else Federation(pd, "Free State") end

		if (pd.confed) then 
			pd.title = "Chairman of Federal Counsil"
		end
	end

	if (pd.theocratic) then pd.theo = "Holy" end

	if (pd.aDemocratic) then 
		pd.masterOf = "assosiated states"
		pd.puppetOf = "assosiated state"
	end

	if (pd.council) then 
		pd.dem = "Council" 
		pd.title = "Chairman of Supreme Council"
	elseif (pd.democratic) then 
		pd.dem = "Democratic"
		pd.title = "Prime Minister"
	end
end

function ChristTheo(pd)
	if ((pd.flavour ~= "CATHOLICISM" and pd.flavour ~= "PROTESTANTISM" and pd.flavour ~= "ORTHODOXY" and pd.flavour ~= "CHRISTIANITY") or not pd.med) then
		return false
	elseif (pd.dictatorship or not pd.small) then 
		pd.state = "Order"
		pd.form = 1
		pd.title = "Grand Master"
	elseif (pd.one) then 
		pd.state = "Bishopric"
		pd.title = "Bishop"
	else 
		pd.state = "Archbishopric"
		pd.title = "Archbishop"
	end

	pd.masterOf = "vassals"
	pd.puppetOf = "vassal"

	return true
end

function IslTheo(pd)
	if (pd.flavour ~= "ISLAM" or not pd.med) then
		return false	
	elseif (pd.empire) then 
		pd.state = "Caliphate"
		pd.title = "Caliph"
		pd.form = 1
	else
		pd.state = "Sheikhdom"
		pd.title = "Sheikh"
		pd.religion = ""
	end

	pd.masterOf = "vassals"
	pd.puppetOf = "vassal"

	return true
end

function TheocraticGov(pd)
	pd.masterOf = "puppets"
	pd.puppetOf = "puppet"

	if ( pd.huge ) then pd.gr = "Great" end

	if (pd.religion == "") then 
		pd.state = "Priestdom"
		pd.religion = ""
		pd.title = "High Priest"
	elseif (pd.republic and not pd.demDictatorship) then
		pd.masterOf = "protectorates"
		pd.puppetOf = "protectorate"
		pd.state = "Republic"
		Federal(pd)
		pd.title = "Supreme Leader"
	elseif (IslTheo(pd)) then
	elseif (pd.empire) then 
		pd.state = "Empire"
		pd.form = 1
		if ( not pd.great ) then pd.gr = "" end
		pd.title = "Holy Emperor"
		pd.masterOf = "vassals"
		pd.puppetOf = "vassal"
	elseif (ChristTheo(pd)) then
	elseif (pd.small or pd.dictatorship) then 
		pd.state = "Order"
		pd.form = 1
		pd.title = "Grand Master"
		pd.masterOf = "vassals"
		pd.puppetOf = "vassal"
	else
		Federation(pd, "State")

		pd.title = "His Holiness"
	end
			
	if (pd.aDemocratic and not pd.demDictatorship) then
		pd.masterOf = "assosiated states"
		pd.puppetOf = "assosiated state"		
		pd.dem = "Democratic" 
	end
end

function GetPartName(part)
	if (part == "") then return "" 
	else 
		return "TXT_KEY_PART_" .. Adapt(part)
	end
end

function GetPart(partName, state)
	if (partName == "") then return "" 
	else
		partName = GetPartName(partName)
		local result = Locale.ConvertTextKey(partName, state)
		return result
	end
end

function ShortTxt(txt, short)
	if (txt == "") then return "" else
		if (short ~= nil) then 
			if(short) then return txt .. "_SHORT" else return "" end
		else return txt end
	end
end

function GetForm(pd)
	local key = pd.shortDescKey:gsub("TXT_KEY_CIV_", "")
	key = key:gsub("_SHORT_DESC", "")

	local always1 = Locale.ConvertTextKey("TXT_KEY_FORMAT_Always1"):find(key) ~= nil
	local always2 = Locale.ConvertTextKey("TXT_KEY_FORMAT_Always2"):find(key) ~= nil
	
	local form = pd.form

	if (form ~= 3) then
		if (always2) then
			form = 2
		elseif(always1) then
			form = 1
		end
	end

	if(form == 0) then
		if (defaultForm > 0) then 
			form = defaultForm
		else
			form = math.random(1, 2)
		end
	end

	local formTxt = ""
	if form > 1 then 
		formTxt = "_" .. form
	end

	pd.form = form

	return formTxt
end

function ShortDesc(id)
	local player = Players[id]
	return Locale.ConvertTextKey(player:GetCivilizationShortDescriptionKey())
end

function Adjective(pd, stateTxt)
	local format = Locale.ConvertTextKey("TXT_KEY_ADJ_FORMAT", stateTxt, pd.player:GetCivilizationAdjectiveKey())

	if (format ~= "TXT_KEY_ADJ_FORMAT") then
		return format
	end

	local key = pd.player:GetCivilizationAdjectiveKey() .. "_WORD"
	local adj = Locale.ConvertTextKey(key, stateTxt)
	if (adj ~= key) then 
		return adj
	else
		return Locale.ConvertTextKey(pd.player:GetCivilizationAdjectiveKey(), stateTxt):gsub("^%l", string.upper)
	end
end

function MakeNameExt(pd, shortList)
	local form = GetForm(pd)

	local format = "TXT_KEY_FORMAT_" .. pd.wayType .. form

	local stateTxt = GetPartName(pd.state)
	
	local religion = ""

	if(pd.religion ~= "") then 
		local religionId = ShortTxt(pd.religion .. "_ADJ", shortList.religion)
		religion = Locale.ConvertTextKey(religionId, stateTxt)
		if (string.find(religion, "_ADJ")) then 
			religion = GetPart(ShortTxt("Holy", shortList.religion), stateTxt)
		else 
			religion = religion
		end
	end

	local state = GetPart(ShortTxt(pd.state, shortList.state), stateTxt)
	local pre = GetPart(ShortTxt(pd.pre, shortList.pre), stateTxt)
	local dem = GetPart(ShortTxt(pd.dem, shortList.dem), stateTxt)
	local sov = GetPart(ShortTxt(pd.sov, shortList.sov), stateTxt)
	local theo = GetPart(ShortTxt(pd.theo, shortList.theo), stateTxt)
	local gr = GetPart(ShortTxt(pd.gr, shortList.gr), stateTxt)
	local const = GetPart(ShortTxt(pd.const, shortList.const), stateTxt)
	local natTxt = GetPartName(ShortTxt(pd.nat, shortList.nat), stateTxt)
	local nat = GetPart(ShortTxt(pd.nat, shortList.nat), stateTxt)
	local fc = GetPart(ShortTxt(pd.fc, shortList.fc), stateTxt)
	local adj = Adjective(pd, stateTxt)

	if(pd.nat ~= "") then 
		adj = Adjective(pd, natTxt)
	end

	return trim(Locale.ConvertTextKey(format, 
	pd.shortDescKey, 
	adj, 
	state,
	religion,
	pre,
	dem,
	sov,
	theo,
	gr,
	const,
	nat,
	fc,
	natTxt)):gsub("%s%s+", " ")
end

function MakeName(pd)
	pd.name = MakeNameExt(pd, {})
end

function ProceedCivName(id, debugCount)
	if id < maxCivs() then
		local pd = CreateData(id)

		if (pd.civInfo) then
			if (starting or debug or (Game.GetGameTurn() - MapModData.govs[id].turn) >= minPeriod) then
				if(debug) then
					RandomStat(pd, debugCount)
				end

				Calculations(pd)

				-- Primitive
				if (pd.fullProgress <= 2) then
					pd.wayType = "Primitive"
					PrimitiveGov(pd)
				-- Chiefdom
				elseif (pd.fullProgress + pd.cities <= eraEarly) then
					pd.wayType = "Chiefdom"
					ChiefdomGov(pd)
				--Early state
				elseif (pd.fullProgress <= eraEarly) then
					pd.wayType = "Early"
					EarlyGov(pd)
				-- Communism way
				elseif (pd.way == "Communist") then
					CommunistGov(pd)
				elseif (pd.way == "Autocracy") then 
					AutocracyGov(pd)
				-- Republic way
				elseif (pd.way == "Liberty") then
					LibertyGov(pd)
				-- Theocracy way
				elseif (pd.way == "Theocratic") then 
					TheocraticGov(pd)
				else
					print("Way: " .. pd.way)
				end
			
				DebugOut(pd)
			
				SetName(pd)

			end
		end
	end

	if (id == 0) then
		if (not starting) then 
			ProcessMasterOrVassals() 
		end
	end
end

function ChooseCivName (id) 
	if (debug) then 
		local max = 20
		local k = 8 / max
		for i = 0, max do
			ProceedCivName(id, i * k)
		end
	else
		ProceedCivName(id, 0)
	end
end

function SetName(pd)
	local prevGov = MapModData.govs[pd.id]
	if (debug or not EqualGov(pd, prevGov)) then
		
		MakeName(pd)

		ShortName(pd)

		local pActivePlayer = Players[Game.GetActivePlayer()]
		if (not starting) then
			if( (pd.player == pActivePlayer) or Teams[ pActivePlayer:GetTeam() ]:IsHasMet(pd.player:GetTeam()) ) then
				local text = Locale.ConvertTextKey("TXT_KEY_NOTIFICATION_NEW_NAME", pd.currentName, pd.name, pd.state)
				pActivePlayer:AddNotification(NotificationTypes.NOTIFICATION_PEACE_ACTIVE_PLAYER, text, text, -1, -1, pd.id);
			end
		end

		if (pd.id < GameDefines.MAX_MAJOR_CIVS) then
			pd.civInfo.Description = pd.name
		else
			pd.civInfo.Description = pd.shortName
		end

		pd.civInfo.ShortDescription = pd.shortName
		pd.fullName = pd.name
		pd.turn = Game.GetGameTurn()
		MapModData.leaderTitles[pd.id] = AdaptTitle(pd.title)
		MapModData.govs[pd.id] = pd

		if (debugNewName) then
			if (true) then 
				DebugParts(pd)
				print(pd.name .. " (" .. pd.shortName .. ")") 
				print(GameplayUtilities.GetLocalizedLeaderTitle(Players[pd.id]))
				print()
			end
		end
	end
end 

function Adapt(str)
	return str:gsub("'", "_")
end

function AdaptTitle(title)
	return "TXT_KEY_TITLE_" .. Adapt(title)
end

function Pres(progress)
	if (progress >= 14) then 
		return "President"
	else
		return "Consul"
	end
end

function PuppetOfTxt(pd)
	local masterId = Master(pd.id)

	if (masterId >= 0) then
		local master = MapModData.govs[masterId]

		if (master == nil) then return "" end

		local title = Locale.ConvertTextKey("TXT_KEY_PART_" .. master.puppetOf)
		local result = Locale.ConvertTextKey("TXT_KEY_FORMAT_Puppet", title, master.name)
		return result
	else
		return ""
	end
end

function PuppetsTxt(pd)
	local vassals = makeString(Vassals(pd.id))

	if (vassals ~= "") then
		local title = Locale.ConvertTextKey("TXT_KEY_PART_" .. pd.masterOf)
		local result = Locale.ConvertTextKey("TXT_KEY_FORMAT_Master", title, vassals)
		return result
	else 
		return ""
	end
end

function MasterOrVassal(pd)
	local puppetOfTxt = PuppetOfTxt(pd)
	local puppetsTxt = PuppetsTxt(pd)

	if (puppetOfTxt == "" or puppetsTxt == "") then txt = puppetOfTxt .. puppetsTxt
	else txt = puppetOfTxt .. "; " .. puppetsTxt end

	if (txt ~= "") then
		if (pd.civInfo) then
			pd.fullName = pd.name .. " (" .. txt .. ")"
			if (pd.id < GameDefines.MAX_MAJOR_CIVS) then
				pd.civInfo.Description = pd.fullName
			end

			if (debugVassals) then
				if (true) then
					print(pd.civInfo.Description)
				end
			end
		end
	end
end

function MakeShortName(pd, shortList)
	if (pd.shortName:len() > shortNameMaxLen) then 
		pd.shortName = MakeNameExt(pd, shortList)
	end
end

function ShortName(pd) 
	pd.shortName = pd.name
	local max = 21

	local shortList = {}

	shortList.fc = true
	MakeShortName(pd, shortList)

	shortList.religion = true
	MakeShortName(pd, shortList)

	shortList.dem = true
	shortList.sov = true
	MakeShortName(pd, shortList)

	shortList.gr = true
	MakeShortName(pd, shortList)

	shortList.pre = true
	shortList.nat = true
	MakeShortName(pd, shortList)

	shortList.state = true
	MakeShortName(pd, shortList)

	shortList.fc = false
	MakeShortName(pd, shortList)

	shortList.theo = false
	MakeShortName(pd, shortList)
	
	shortList.dem = false
	shortList.sov = false
	MakeShortName(pd, shortList)

	shortList.pre = false
	MakeShortName(pd, shortList)
end

function Policies(id)
	local ps = {}
	local player = Players[id]

	for branch in GameInfo.PolicyBranchTypes() do
		local bt = branch.Type
		if (player:IsPolicyBranchUnlocked(branch.ID)) then
			ps[bt] = 1
		else
			ps[bt] = 0
		end
	end

	for pPolicy in GameInfo.Policies() do
		local bt = pPolicy.PolicyBranchType

		if (bt ~= nil) then
			local n = ps[bt]
			if (player:HasPolicy(pPolicy.ID)) then
				ps[bt] = n + 1
			end 
		end
	end 

	return ps
end

function Count(id, process, add)
	local counter = 0
	process(id, function (pCity) counter = counter + add(pCity) end)
	return counter
end

function Count1(id, process, add)
	return Count(id, process, function (dummy) return 1 end)
end

function ForMinors(id, f)
	for iPlayerLoop = 0, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
		if(IsVassal(id, iPlayerLoop)) then
			local player = Players[iPlayerLoop];
			f(player)
		end
	end
end


function Minors(id)
	return Count(id, ForMinors, function (player) return player:GetNumCities() end)
end

function Puppets(id) 
	return Count1(id, ForPuppets)
end

function ForPuppets(id, f)
	local player = Players[id]

	for pCity in player:Cities() do
		if (pCity:IsPuppet()) then
			f(pCity)
		end
	end
end

function ForCities(id, f) 
	local player = Players[id]

	for pCity in player:Cities() do
		f(pCity)
	end
end

function Religion(id)
	local religions = {}
	local counter = 0 
	
	function f (city)
		for pReligion in GameInfo.Religions() do
			local rID = pReligion.ID
			local n = city:GetNumFollowers(rID)
			if (city:IsHolyCityForReligion(rID)) then n = n * holyCityMul end
			local prev = religions[rID]
			if (prev) then n = prev + n end
			religions[rID] = n
			counter = counter + 1
		end
	end

	ForCities(id, f)
	
	local max = 0
	local ri = 0

	for i, n in pairs(religions) do
		if (n > max) then
			max = n
			ri = i
		end
	end

	local name = ""
	max = max / counter
	if (max > 0.33) then name = Game.GetReligionName(ri) end

	if (name == "TXT_KEY_RELIGION_PANTHEON") then
		name = ""
	end

	return name, max
end

function IsVassal(masterID, vassalID)
	if (vassalID >= GameDefines.MAX_MAJOR_CIVS) then
		if (vassalID ~= masterID) then
			local pThirdPlayer = Players[vassalID];
						
			if (pThirdPlayer ~= nil and pThirdPlayer:IsAlive()) then
				local vassal = pThirdPlayer:IsAllies(masterID)
				if (debug) then
					vassal = math.random(1, 5) == 1
				end
				return vassal
			end
		else
			return false
		end
	elseif (vassalMod) then
		local vassal = Players[vassalID];
		local master = Players[masterID];
		
		if(vassal and master and vassal:IsAlive() and master:IsAlive()) then
			if (debug) then
				return math.random(1, 5) == 1
			end

			local vassalTeam = Teams[ vassal:GetTeam() ];

			return vassalTeam:GetMaster() == master:GetTeam()
		else return false end
	else
		return false
	end
end

function makeString(t)
	local result = ""
	for key, entry in pairs(t) do
		if (result == "") then result = entry
		else result = result .. ", " .. entry end
	end
	return result
end

function toString(i)
	if (i == nil) then
		return "nil"
	else 
		return tostring(i)
	end
end

function Vassals(id)
	local vassals = {};

	ForMinors(id,
		function (player)
			local id = player:GetID() 
			local desc
			if (id < maxCivs()) then 
				desc = MapModData.govs[id].shortName
			else
				desc = ShortDesc(id)
			end
			table.insert(vassals, desc)
		end
	)

	return vassals
end

function Master(id)
	for iPlayerLoop = 0, GameDefines.MAX_MAJOR_CIVS - 1, 1 do
		if (IsVassal(iPlayerLoop, id)) then
			return iPlayerLoop
		end
	end
	return -1
end

function OnEnterGame()
	if(
		pcall ( 
			function () 
				Teams[Game.GetActivePlayer()]:GetMaster()
			end
		) 
	) then
		print("Vassal mod is on")
	else 
		vassalMod = false
		print("Vassal mod is off")
	end

	for iPlayer = 0, maxCivs() - 1 do
		local civInfo = CivInfo(iPlayer)

		if (civInfo) then
			ChooseCivName(iPlayer)
		end
	end

	for iPlayer = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
		local civInfo = CivInfoEx(iPlayer, false)
		if (civInfo ~= nil) then
			civInfo.ShortDescription = civInfo.Description
		end
	end

	ProcessMasterOrVassals()
	starting = false

end

function ProcessMasterOrVassals()
	for iPlayer = 0, maxCivs() - 1 do
		local civInfo = CivInfo(iPlayer)
		if (civInfo) then
			MasterOrVassal(MapModData.govs[iPlayer])
		end
	end
end

GameEvents.PlayerDoTurn.Add(ChooseCivName);
Events.LoadScreenClose.Add(OnEnterGame)