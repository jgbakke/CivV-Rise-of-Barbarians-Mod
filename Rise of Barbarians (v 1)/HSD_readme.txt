Historical Spawn Dates
for Civilization 5
v.5

	-- Presentation --


	-- Installation --


	-- Credits & thanks --

Rhye, whoward69, Whys

	-- To do --


	-- version history --

v.5 (Aug 06, 2013) :
- Bugfix: add minimum date before domination (1200 AD), culture (1500 AD) and diplomatic (1700 AD) victories are possible to prevent victory when a civilization spawns alone before every others.
- Balance: make culture, faith and gold bonuses relative to the number of civilizations (was uncapped before)
- Change: set Carthage HSD to 650 BC

v.5 (July 09, 2013) :
- Bugfix: barbarian conversion range was bigger than expected.
- Feature: spawn a City for the AI if the starting Position is not overlapping with another Civilization. This should fix the issue when the AI decide to move it's initial settler.
- Feature: add a 'NoFreeTech' tag to the HSD table, which prevent some Civilizations to get the global free techs on spawn (used to prevent the "new world" to be more advanced in research than the "old world")
- Balance: don't let CS units to wander around after the CS have been converted by a spawning Civilization.
 
v.4 (May 23, 2013) :
- Bugfix: check if an unit is still on the plot where looping on before trying to convert it.
- Auto-close "Who's Winning" and Natural Wonders popups for "sleeping" human player.
	
v.3 (May 12, 2013) :
- Use only civilization that have settled at least one city for balance calculations
- Add a "land culture" value for balance, given to the first city (it will grab new tiles faster the first turns)
- Add a "population" value for balance, given to the first city (food value in that city will be 75% filled to prevent immediate loss from starvation)
- Bugfix: don't fail at initialization when a civilization is not listed in the HSD table
- Use in game auto-turn function instead of custom function
- Add columns in Civilization_HistoricalSpawnDates table to set initial units for each civilizations and CS. (use fixed list if the table entry for units is empty)
- Give all techs that are known by all settled civilization when creating first city
- Add option (default ON) to balance per science points instead of free techs for the other known techs.
- Give all techs that are known by all settled civilization when creating first city
- Add option (default ON) to balance per culture points instead of free policies (free policies are OP for late spawn civilizations)


v.1 / v.2 (Mar 01, 2013) :
- initial release on CFC





