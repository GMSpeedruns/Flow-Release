
AddCSLuaFile()
DEFINE_BASECLASS("player_default")

local PLAYER = {}

PLAYER.DisplayName			= "Bhop Player"

PLAYER.WalkSpeed 			= 250		-- How fast to move when not running
PLAYER.RunSpeed				= 250		-- How fast to move when running
PLAYER.CrouchedWalkSpeed 	= 0.6
PLAYER.DuckSpeed			= 0.4		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.01		-- How fast to go from ducking, to not ducking
PLAYER.JumpPower			= 268.4     -- How powerful our jump should be
PLAYER.AvoidPlayers			= false

--
-- Called serverside only when the player spawns
--
function PLAYER:Spawn()

end

--
-- Called on spawn to give the player their default loadout
--
function PLAYER:Loadout()

	self.Player:Give( "weapon_crowbar" )
	self.Player:Give( "weapon_glock" )

end


player_manager.RegisterClass( "player_bhop", PLAYER, "player_default" )