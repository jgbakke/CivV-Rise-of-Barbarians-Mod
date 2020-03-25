-- Insert SQL Rules Here 

-- Let Barbs build all kinds of awesome units!
-- Deliberately missing: UNITCOMBAT_SUBMARINE, UNITCOMBAT_CARRIER, UNITCOMBAT_BOMBER, UNITCOMBAT_FIGHTER, UNITCOMBAT_HELICOPTER, UNITCOMBAT_RECON
DELETE FROM Civilization_UnitClassOverrides WHERE CivilizationType = 'CIVILIZATION_BARBARIAN' AND UnitClassType IN (SELECT Class FROM Units WHERE CombatClass IN ('UNITCOMBAT_ARCHER', 'UNITCOMBAT_MOUNTED', 'UNITCOMBAT_ARMOR', 'UNITCOMBAT_NAVALMELEE', 'UNITCOMBAT_NAVALRANGED', 'UNITCOMBAT_SIEGE', 'UNITCOMBAT_MELEE', 'UNITCOMBAT_GUN')) AND UnitType IS NULL;

-- Remove Barbarian combat penalties and increase acquisition range; ranges were 8 and 20 respectively
UPDATE HandicapInfos SET BarbarianBonus = 0, AIBarbarianBonus = 0, BarbarianLandTargetRange = 100, BarbarianSeaTargetRange = 100 WHERE IconAtlas = 'DIFFICULTY_ATLAS';

-- Update Barbarian strings
UPDATE Civilizations SET Description = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_DESC', Adjective = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_ADJECTIVE', ShortDescription = 'TXT_KEY_CIV_BARBARIAN_TRIBAL_SHORT_DESC' WHERE Type = 'CIVILIZATION_BARBARIAN';

-- Block Barbarians from Policies (doesn't work)
-- INSERT INTO Policy_Disables (PolicyType, PolicyDisable) SELECT 'POLICY_BARBARIC', Type FROM Policies WHERE Type <> 'POLICY_BARBARIC';

-- New Barbarian Civ
-- Synch Barb Major and Barb Minor City names
-- DELETE FROM Civilization_CityNames WHERE CivilizationType in ('CIVILIZATION_BARBARIAN_MAJOR');
-- INSERT INTO Civilization_CityNames (CivilizationType, CityName) SELECT 'CIVILIZATION_BARBARIAN_MAJOR', CityName FROM Civilization_CityNames WHERE CivilizationType = 'CIVILIZATION_BARBARIAN';

-- clone new Barbarian Major unit setup from existing units

-- Enslaved Workers
INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor) SELECT 'UNIT_BARBARIAN_WORKER', FlavorType, Flavor FROM Unit_Flavors WHERE UnitType = 'UNIT_WORKER';

INSERT INTO Unit_Builds (UnitType, BuildType) SELECT 'UNIT_BARBARIAN_WORKER', BuildType FROM Unit_Builds WHERE UnitType = 'UNIT_WORKER';

-- Dirty Bomb
INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor) VALUES ('UNIT_DIRTY_BOMB', 'FLAVOR_NUKE', 50);

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor) VALUES ('UNIT_DIRTY_BOMB', 'FLAVOR_OFFENSE', 50);

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor) VALUES ('UNIT_DIRTY_BOMB', 'FLAVOR_RANGED', 50);

-- clone unit locks
DELETE FROM Civilization_UnitClassOverrides WHERE CivilizationType = 'CIVILIZATION_BARBARIAN_MAJOR' AND UnitClassType NOT IN ('UNITCLASS_WORKER', 'UNITCLASS_ATOMIC_BOMB');

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) VALUES ('CIVILIZATION_BARBARIAN_MAJOR', 'UNITCLASS_WORKER', 'UNIT_BARBARIAN_WORKER');

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) VALUES ('CIVILIZATION_BARBARIAN_MAJOR', 'UNITCLASS_ATOMIC_BOMB', 'UNIT_DIRTY_BOMB');

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) SELECT 'CIVILIZATION_BARBARIAN_MAJOR', UnitClassType, UnitType FROM Civilization_UnitClassOverrides WHERE CivilizationType = 'CIVILIZATION_BARBARIAN' AND UnitType IS NOT NULL;

-- lock UNITCLASS_EVOLVED_CS_MARKER for all civs except Tribal Barbarians
INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) SELECT Type, 'UNITCLASS_EVOLVED_CS_MARKER', '' FROM Civilizations; -- WHERE Type <> 'CIVILIZATION_BARBARIAN';

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType) VALUES ('CIVILIZATION_BARBARIAN_MAJOR', 'UNITCLASS_EVOLVED_CS_MARKER', '');

-- diplomacy minimal responses
INSERT INTO Diplomacy_Responses (LeaderType, ResponseType, Response, Bias) VALUES ('LEADER_BARBARIAN_EVOLVED', 'RESPONSE_FIRST_GREETING', 'TXT_KEY_LEADER_BARBARIAN_EVOLVED_FIRSTGREETING%', '1');

INSERT INTO Diplomacy_Responses (LeaderType, ResponseType, Response, Bias) VALUES ('LEADER_BARBARIAN_EVOLVED', 'RESPONSE_DEFEATED', 'TXT_KEY_LEADER_BARBARIAN_EVOLVED_DEFEATED%', '1');

-- GNK & BNW CHANGES (placed at end to prevent an early script death)

-- create tables if they don't exist (stops crash if GNK/BNW)
CREATE TABLE IF NOT EXISTS Trait_NoTrain('TraitType' text , 'UnitClassType' text);

CREATE TABLE IF NOT EXISTS Beliefs ('Type' text , 'ConvertsBarbarians' text);

CREATE TABLE IF NOT EXISTS Civilization_Religions ('CivilizationType' text , 'ReligionType' text , foreign key (CivilizationType) references Civilizations(Type), foreign key (ReligionType) references Religions(Type));

CREATE TABLE IF NOT EXISTS Civilization_SpyNames ('CivilizationType' text , 'SpyName' text  not null , foreign key (CivilizationType) references Civilizations(Type), foreign key (SpyName) references Language_en_US(Tag));

-- remove any belief that converts Barbarians (i.e. Heathen Conversion)
DELETE FROM Beliefs WHERE ConvertsBarbarians = 1;

-- clone religion for Barbarian State
INSERT INTO Civilization_Religions (CivilizationType, ReligionType) SELECT 'CIVILIZATION_BARBARIAN', ReligionType FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ENGLAND';

-- clone religion for Barbarian Civ
INSERT INTO Civilization_Religions (CivilizationType, ReligionType) SELECT 'CIVILIZATION_BARBARIAN_MAJOR', ReligionType FROM Civilization_Religions WHERE CivilizationType = 'CIVILIZATION_ENGLAND';

-- clone spies for Barbarian State
INSERT INTO Civilization_SpyNames (CivilizationType, SpyName) SELECT 'CIVILIZATION_BARBARIAN', SpyName FROM Civilization_SpyNames WHERE CivilizationType = 'CIVILIZATION_ENGLAND';

-- clone spies for Barbarian Civ
INSERT INTO Civilization_SpyNames (CivilizationType, SpyName) SELECT 'CIVILIZATION_BARBARIAN_MAJOR', SpyName FROM Civilization_SpyNames WHERE CivilizationType = 'CIVILIZATION_ENGLAND';
