AddCSLuaFile()
DEFINE_BASECLASS("player_default")

local PLAYER = {}

PLAYER.DisplayName			= "Player"
PLAYER.WalkSpeed 			= 250		-- How fast to move when not running
PLAYER.RunSpeed				= 250		-- How fast to move when running
PLAYER.CrouchedWalkSpeed 	= 0.6
PLAYER.DuckSpeed			= 0.4		-- How fast to go from not ducking, to ducking
PLAYER.UnDuckSpeed			= 0.01		-- How fast to go from ducking, to not ducking
PLAYER.JumpPower			= 268.4     -- How powerful our jump should be
PLAYER.AvoidPlayers			= false

function PLAYER:Loadout()
	self.Player:Give( "weapon_crowbar" )
	self.Player:Give( "weapon_knife" )
	self.Player:Give( "weapon_glock" )
end

player_manager.RegisterClass( "player_bhop", PLAYER, "player_default" )