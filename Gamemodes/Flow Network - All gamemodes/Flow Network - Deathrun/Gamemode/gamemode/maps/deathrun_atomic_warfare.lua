-- Deathrun Atomic Warfare
-- Added on: 19th of January 2015
-- Added by: Gravious
-- Last updated on: 22nd of January 2015

__MAP = {

	Name = "Atomic Warfare",
	RealName = "deathrun_atomic_warfare",
	
	Hooks = {
		["StartZone"] = {
			Start = Vector( -2177, 4864, 0 ),
			End = Vector( -1664, 5375, 128 )
		},
		
		["EndZone"] = {
			Start = Vector( 4866, 9986, -2048 ),
			End = Vector( 5374, 10494, -1920 )
		},
		
		-- First teleporter
		["VelocityZone_1"] = {
			Start = Vector( -6109, -448, 0 ),
			End = Vector( -5916, 32, 144 ),
			Velocity = 350,
		},
		
		-- Second (backwards) teleporter
		["VelocityZone_2"] = {
			Start = Vector( -8432, -424, 0 ),
			End = Vector( -8208, -190, 130 ),
			Velocity = 350,
		},
		
		-- Third teleporter
		["VelocityZone_3"] = {
			Start = Vector( 9616, -9879, 2 ),
			End = Vector( 9840, -9384, 130 ),
			Velocity = 350,
		},
		
		-- Last teleporter (so nobody falls off)
		["VelocityZone_4"] = {
			Start = Vector( 4866, 9986, -2048 ),
			End = Vector( 5374, 10494, -1920 ),
			Velocity = 10,
		},
	}
}