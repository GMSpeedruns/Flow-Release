-- I was trying to suppress console logs for:
-- > Attempted to create unknown entity type weapon_scout!
-- > NULL Ent in GiveNamedItem!

-- But it's impossible AFAIK without having a C++ module that actually checks before they're created
-- All of the below weapons aren't in-game, but you can add them yourself. Adding fake ammo_ or item_ entities might not be a good idea though

local SkippableEntities = {
	-- Non-default weapons
	["weapon_scout"] = true, ["weapon_aug"] = true, ["weapon_sg550"] = true, ["weapon_sg552"] = true, ["weapon_awp"] = true, ["weapon_elite"] = true, ["weapon_g3sg1"] = true,
	
	-- CS:S ammo
	["ammo_45acp"] = true, ["ammo_762mm"] = true, ["ammo_9mm"] = true, ["ammo_57mm"] = true, ["ammo_buckshot"] = true,
	
	-- CS:S misc
	["item_assaultsuit"] = true,
}
