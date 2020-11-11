-- Deathrun Machine of Doom V2
-- Added on: 19th of January 2015
-- Added by: Gravious
-- Last updated on: 19th of January 2015

__MAP = {

	Name = "Machine of Doom",
	RealName = "dr_machine_of_doom_v2",
	
	--[[
	Tracker = {
		"stats_topspeed",
		"stats_topfastest",
		"stats_topjumps",
		"stats_minjumps",
	},
	
	Hooks = {
		["StartZone"] = {
			Start = Vector( 123, 123, 123 ),
			End = Vector( 456, 456, 456 )
		},
		
		["EndZone"] = {
			Start = Vector( 123, 123, 123 ),
			End = Vector( 456, 456, 456 )
		},
	
		["ResetPosition"] = {
			Start = Vector( 123, 123, 123 ),
			End = Vector( 456, 456, 456 ),
			Target = Vector( 789, 789, 789 )
		}
	}
	]]
}