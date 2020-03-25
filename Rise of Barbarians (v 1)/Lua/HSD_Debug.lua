-- Historical Spawn Dates Debug
-- Author: Gedemon
-- DateCreated: 1/30/2011 8:03:25 PM
--------------------------------------------------------------

print("Loading Historical Spawn Dates Debug Functions...")
print("-------------------------------------")

-- Output debug text to console
function Dprint ( str, bOutput )
	bOutput = bOutput or true
	if ( PRINT_DEBUG and bOutput ) then
		print (str)
	end
end
