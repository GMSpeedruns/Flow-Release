include( "sh_player.lua" )
include( "sh_movement.lua" )
include( "sh_view.lua" )

GM.Name = "Bunny Hop"
GM.Author = "Gravious"
GM.Email = ""
GM.Website = ""
GM.TeamBased = true

TEAM_HOP = 1

function GM:CreateTeams()
	team.SetUp( TEAM_HOP, "Players", Color( 255, 50, 50, 255 ), false )
	team.SetUp( TEAM_SPECTATOR, "Spectators", Color( 50, 255, 50, 255 ), true )
	team.SetSpawnPoint( TEAM_HOP, { "info_player_terrorist", "info_player_counterterrorist" } )
end

function GM:PlayerNoClip() return false end


Config = {}
Config.Version = 1.15
Config.MapCount = 155

Config.Modes = {
	["Auto"] = 1,
	["Sideways"] = 2,
	["W-Only"] = 3,
	["Scroll"] = 4,
	["Practice"] = 5,
	["Bonus"] = 6
}
Config.ModeNames = { "Auto", "Sideways", "W-Only", "Normal", "Practice", "Bonus", "Close" }

Config.IllegalKeys = {
	[Config.Modes["Sideways"]] = {["Key"] = {IN_MOVELEFT, IN_MOVERIGHT}, ["Bind"] = {"moveleft", "moveright"}},
	[Config.Modes["W-Only"]] = {["Key"] = {IN_MOVELEFT, IN_MOVERIGHT, IN_BACK}, ["Bind"] = {"moveleft", "moveright", "back"}}
}

Config.Player = {
	DefaultModel = "models/player/group01/male_01.mdl",
	DefaultWeapon = "weapon_glock",
	JumpPower = 284,
	HullMin = Vector(-16, -16, 0),
	HullDuck = Vector(16, 16, 45),
	HullStand = Vector(16, 16, 62),
	ViewDuck = Vector(0, 0, 47),
	ViewStand = Vector(0, 0, 64),
	AFKLimit = 12 * 10
}

Config.Prefix = {
	Game = 1, Timer = 2, Admin = 3, Bot = 4, LJ = 5, Radio = 6, Command = 7, Vote = 8
}

Config.Area = {
	Start = 1,
	Finish = 2,
	Block = 3,
	Teleport = 4,
	StepSize = 5,
	Velocity = 6,
	Freestyle = 7,
	BonusA = 10,
	BonusB = 11,
}

Config.Ranks = {
	{"Unranked",		Color(255, 255, 255)},
	{"Slave",			Color(166, 166, 166)},
	{"Grunt",			Color(255, 255, 98)},
	{"Squire",			Color(101, 67, 33)},
	{"Snail",				Color(250, 218, 221)},
	{"Freshman",		Color(80, 80, 80)},
	{"Amateur",		Color(0, 8, 8)},
	{"Crawler",			Color(96, 16, 176)},
	{"Private", 			Color(206, 255, 157)},
	{"Peasant",			Color(128, 128, 128)},
	{"Learning",		Color(255, 192, 203)},
	{"Advanced",		Color(0, 50, 32)},
	{"Experienced",	Color(0, 0, 60)},
	{"Mortal",			Color(196, 255, 196)},
	{"Warden",			Color(255, 128, 0)},
	{"Professional",	Color(0, 0, 139)},
	{"Centurion",		Color(196, 255, 196)},
	{"Admired",			Color(30, 166, 48)},
	{"Executioner",	Color(98, 0, 0)},
	{"Boss",				Color(255, 255, 0)},
	{"Legendary",		Color(128, 0, 128)},
	{"The Honored",	Color(0, 168, 255)},
	{"Champion",		Color(255, 101, 0)},
	{"Zombie",			Color(0, 255, 128)},
	{"Genius",			Color(170, 0, 0)},
	{"Brawler",			Color(0, 255, 191)},
	{"Tsar",				Color(139, 0, 0)},
	{"Bishop",			Color(190, 255, 0)},
	{"Pharaoh",			Color(255, 0, 255)},
	{"Demon",			Color(255, 0, 0)},
	{"Insane",			Color(255, 0, 64)},
	{"Immortal",		Color(255, 235, 0)},
	{"Titan",				Color(0, 255, 0)},
	{"Wizard",			Color(0, 0, 255)},
	{"Demi God",		Color(255, 215, 0)},
	{"God",				Color(0, 255, 255)},
	
	[-1] = {"WR Bot", Color(255, 0, 0)},
	[-2] = {"Loading...", Color(255, 255, 255)}
}

for RankID, _ in pairs( Config.Ranks ) do
	Config.Ranks[ RankID ][3] = math.floor( 2.25 * math.pow( RankID, 2.538 ) )
	if RankID == 36 then
		Config.Ranks[ RankID ][3] = 20030
	end
end

function ToVector( szInput )
	if not szInput or szInput == "" or #szInput == 0 then return nil end
	
	local vec = string.Explode( ",", szInput )
	if #vec == 3 then
		return Vector( vec[1], vec[2], vec[3] )
	end
	
	return Vector( 0, 0, 0 )
end

function GetVectorString( vec, bShort )
	return bShort and string.format( "%.0f,%.0f,%.0f", vec.x, vec.y, vec.z ) or vec.x .. "," .. vec.y .. "," .. vec.z
end