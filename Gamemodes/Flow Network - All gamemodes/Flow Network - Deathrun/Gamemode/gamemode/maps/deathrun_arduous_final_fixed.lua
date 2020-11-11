-- Deathrun Arduous Final Fixed
-- Added on: 19th of January 2015
-- Added by: Gravious
-- Last updated on: 20th of January 2015

__MAP = {

	Name = "Arduous",
	RealName = "deathrun_arduous_final_fixed",
	
	Hooks = {
		["StartZone"] = {
			Start = Vector( -260, -5128, 1056 ),
			End = Vector( -36, -4330, 1186 )
		},
		
		["EndZone"] = {
			Start = Vector( -260, 3854, -124 ),
			End = Vector( -36, 4124, 4 )
		},
		
		-- Start ramp
		["DamageZone_1"] = {
			Start = Vector( -260, -4317, -135 ),
			End = Vector( -36, -3036, 1186 ),
			Multiplier = 0.0,
			Type = 0
		},
		
		-- Pre end zone
		["DamageZone_2"] = {
			Start = Vector( -244, 3122, -116 ),
			End = Vector( -52, 3402, 12 ),
			Multiplier = 0.0,
			Type = 0
		},
	
		-- End zone
		["DamageZone_3"] = {
			Start = Vector( -260, 3815, -124 ),
			End = Vector( -44, 4124, 20 ),
			Multiplier = 0.0,
			Type = 0
		},
		
		-- Death ramp
		["DamageZone_4"] = {
			Start = Vector( -468, -4052, -140 ),
			End = Vector( -308, -2853, 876 ),
			Multiplier = 0.0,
			Type = 0
		},
		
		-- Death ladder
		["DamageZone_5"] = {
			Start = Vector( -420, 3195, -132 ),
			End = Vector( -359, 3676, 332 ),
			Multiplier = 0.0,
			Type = 0
		}
	}
}