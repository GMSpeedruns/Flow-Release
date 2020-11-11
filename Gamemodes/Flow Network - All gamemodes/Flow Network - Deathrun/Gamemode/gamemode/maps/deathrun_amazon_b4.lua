-- Deathrun Amazon Beta 4
-- Added on: 19th of January 2015
-- Added by: Gravious
-- Last updated on: 21st of January 2015

__MAP = {

	Name = "Amazon",
	RealName = "deathrun_amazon_b4",
	DeathSpeed = 500,
	
	Hooks = {
		["StartZone"] = {
			Start = Vector( -1178, 378, 80 ),
			End = Vector( -866, 722, 208 ),
		},
		
		["EndZone"] = {
			Start = Vector( -3756, -39, 1298 ),
			End = Vector( -3476, 495, 1426 ),
		},
		
		["DamageZone_1"] = {
			Start = Vector( -2220, 786, 691 ),
			End = Vector( -1022, 963, 820 ),
			Multiplier = 0.0,
			Type = 0
		}
	}
}