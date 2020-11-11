-- Deathrun Industrial
-- Added on: 11th of January 2015
-- Added by: Gravious
-- Last updated on: 14th of January 2015

__MAP = {

	Name = "Industrial",
	RealName = "deathrun_industrial",
	
	--[[
	Tracker = {
		"stats_topspeed",
		"stats_topfastest",
		"stats_topjumps",
		"stats_minjumps",
	},
	]]
	
	Hooks = {
		["StartZone"] = {
			Start = Vector( -234, 296, 0 ),
			End = Vector( 104, 773, 128 )
		},
		
		["EndZone"] = {
			Start = Vector( 2727, 993, 0 ),
			End = Vector( 3399, 1409, 128 )
		},
	
		["DamageZone"] = {
			Start = Vector( 2652, 152, 0 ),
			End = Vector( 2748, 248, 128 ),
			Multiplier = 0.0
		}
	}
}