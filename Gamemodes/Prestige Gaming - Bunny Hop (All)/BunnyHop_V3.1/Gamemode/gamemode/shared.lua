include("player/player_class.lua")
include("sh_offsets.lua")

GM.Name 	= "Bunny Hop"
GM.Author 	= "Gravious"
GM.Email 	= ""
GM.Website 	= "prestige-gaming.org"
GM.TeamBased = true

GM.RankList = {
	{"Astronaut",		Color(255, 255, 255)},
	{"Initiate",			Color(166, 166, 166)},
	{"Newbie",			Color(255, 255, 98)},
	{"Beginner",		Color(101, 67, 33)},
	{"Rookie",			Color(250, 218, 221)},
	{"Apprentice",		Color(80, 80, 80)},
	{"Decent",			Color(0,8,8)},
	{"Novice",			Color(96, 16, 176)},
	{"Getting There", Color(206, 255, 157)},
	{"Average",			Color(128, 128, 128)},
	{"Intermediate",	Color(255, 192, 203)},
	{"Awesome",		Color(1, 50, 32)},
	{"Advanced",		Color(0, 0, 60)},
	{"Skilled",			Color(98, 0, 0)},
	{"Impressive",		Color(255, 128, 0)},
	{"Pro",					Color(0, 0, 139)},
	{"Hardcore",		Color(196, 255, 196)},
	{"Respected",		Color(30, 166, 48)},
	{"Prestigious",	Color(196, 255, 196)},
	{"Expert",			Color(255, 255, 0)},
	{"Veteran",			Color(128, 0, 128)},
	{"Famous",			Color(0, 168, 255)},
	{"Sublime",			Color(255, 101, 0)},
	{"Beast",				Color(0, 255, 128)},
	{"Wicked",			Color(170, 0, 0)},
	{"Epic",				Color(0, 255, 191)},
	{"Addict",			Color(139, 0, 0)},
	{"Brutal",				Color(190, 255, 0)},
	{"Elite",				Color(255, 0, 255)},
	{"Insane",			Color(255,0,0)},
	{"Nightmare",		Color(255,0,64)},
	{"Divine",			Color(255, 235, 0)},
	{"Stoner",			Color(0, 255, 0)},
	{"Hax0r",				Color(0, 0, 255)},
	{"Majestic",			Color(255, 215, 0)},
	{"God",				Color(0, 255, 255)},
	
	[-1337] = {"WR Bot", Color(255,0,0)},
}

MSG_ID = {
	["Nominate"] = 1,
	["NominateChange"] = 2,
	["RTV"] = 3,
	["WaitPeriod"] = 4,
	["AlreadyVoted"] = 5,
	["AlreadyNominate"] = 6,
	["VoteStart"] = 7,
	["MapChange"] = 8,
	["Teleported"] = 9,
	["TeleportCooldown"] = 10,
	["TimerFinish"] = 11,
	["TimerImprove"] = 12,
	["WRFinish"] = 13,
	["WRImprove"] = 14,
	["WRRecord"] = 15,
	["AdminMsg"] = 16,
	["BhopMsg"] = 17,
	["BotMsg"] = 18,
	["Connect"] = 19,
	["Leave"] = 20,
	["MapExtend"] = 21,
	["ExtendLimit"] = 22,
	["TimeLeft"] = 23,
	["Revoke"] = 24,
	["LJMsg"] = 25,
}

DATA_ID = {
	["VoteList"] = 1,
	["Votes"] = 2,
	["WRFull"] = 3,
	["WRUpdate"] = 4,
	["MapsLeft"] = 5,
	["MapsBeat"] = 6,
	["TopList"] = 7,
	["SpecView"] = 8,
	["SpecTime"] = 9,
	["LJ"] = 11
}

TEAM_HOP = 2
AREA_START = 1
AREA_FINISH = 2
AREA_BLOCK = 3
AREA_TELEPORT = 4
AREA_STEPSIZE = 5
AREA_VELOCITY = 6

TEXT_BHOP = 1
TEXT_TIMER = 2
TEXT_ADMIN = 3
TEXT_BOT = 4
TEXT_LJ = 5

VEC_VIEWSTAND = Vector(0, 0, 64)
VEC_VIEWDUCK = Vector(0, 0, 47)
VEC_HULLMIN = Vector(-16, -16, 0)
VEC_HULLSTAND = Vector(16, 16, 62)
VEC_HULLDUCK = Vector(16, 16, 45)
VEC_JUMPHEIGHT = 284

PLAYER_SPEED = 0
PLAYER_AFK_LIMIT = 12 * 10
PLAYER_RTV_TIME = 60 * 10

MODE_AUTO = 1
MODE_SIDEWAYS = 2
MODE_WONLY = 3
MODE_SCROLL = 4
MODE_PRACTICE = 5
MODE_BONUS = 6
MODE_NAME = {[MODE_AUTO] = "Auto Hop", [MODE_SIDEWAYS] = "Sideways", [MODE_WONLY] = "W-Only", [MODE_SCROLL] = "Normal", [MODE_PRACTICE] = "Practice", [MODE_BONUS] = "Bonus"}

LIST_DOORMAPS = {["bhop_monster_jam"] = true, ["bhop_bkz_goldhop"] = true, ["bhop_aoki_final"] = true}
LIST_NOMAPTRIGS = {["bhop_fury"] = true, ["bhop_hive"] = true}
LIST_BOOSTERS = {["bhop_dan"] = 2.4}

function GM:CreateTeams()
	team.SetUp(TEAM_HOP, "Players", Color(255, 50, 50, 255), false)
	team.SetSpawnPoint(TEAM_HOP, {"info_player_terrorist", "info_player_counterterrorist"})
	team.SetUp(TEAM_SPECTATOR, "Spectators", Color(50, 255, 50, 255), true)
end

function GM:PlayerNoClip(ply)
	return false
end

function GM:OnPlayerHitGround(ply, water)
	if not IsValid(ply) then return end
	
	local Style = MODE_AUTO
	if CLIENT then
		Style = PlayerMode
	elseif SERVER then
		Style = ply.HopMode
		
		if ply.LJ then
			if not water then
				LJ.Stats:Complete(ply, ply:GetPos())
				LJ.Stats:Reset(ply)
			else
				LJ.Stats:Reset(ply)
			end
		end
	end
	
	if Style == MODE_SCROLL then
		ply:SetJumpPower(268.4)
		timer.Simple(0.3, function() ply:SetJumpPower(VEC_JUMPHEIGHT) end)
	end

	local ent = ply:GetGroundEntity()
	if tonumber(ent:GetNWInt("Platform", 0)) == 0 then return end
    if (ent:GetClass() == "func_door" or ent:GetClass() == "func_button") and not LIST_DOORMAPS[game.GetMap()] and ent.BHSp and ent.BHSp > 100 then
		if LIST_BOOSTERS[game.GetMap()] then
			ply:SetVelocity(Vector(0, 0, ent.BHSp * LIST_BOOSTERS[game.GetMap()]))
		else
			ply:SetVelocity(Vector(0, 0, ent.BHSp * 1.9))
		end
	elseif ent:GetClass() == "func_door" || ent:GetClass() == "func_button" then
		timer.Simple(0.04, function()
			ent:SetOwner(ply)
			if CLIENT then
				ent:SetColor(Color(255,255,255,125))
			end
		end)
		timer.Simple(0.7, function() ent:SetOwner(nil) end)
		timer.Simple(0.7, function() if CLIENT then ent:SetColor(Color(255, 255, 255, 255)) end end)
	end
	
	if (self.BaseClass && self.BaseClass.OnPlayerHitGround) then
		self.BaseClass:OnPlayerHitGround(ply)
	end
end

function GM:Move(pl, movedata)
	if not pl or not IsValid(pl) then return end
	
	if CLIENT then
		PLAYER_SPEED = math.ceil(movedata:GetVelocity():Length2D())
	end
	
	local OnGround = pl:IsOnGround()
	if OnGround then 
		timer.Simple(0.1, function()
			if not pl or not IsValid(pl) then return end
			pl:SetDuckSpeed(0.4)
			pl:SetUnDuckSpeed(0.2)
		end)
	end
	if OnGround or not pl:Alive() then return end

	if SERVER and not MAP_SPAWNSPEED then
		if pl.InSpawn and movedata:GetVelocity():Length() > 400 then
			movedata:SetVelocity(Vector(0, 0, 0))
			return false
		end
	end
	
	pl:SetDuckSpeed(0)
	pl:SetUnDuckSpeed(0)
	
	local aim = movedata:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = movedata:GetForwardSpeed()
	local smove = movedata:GetSideSpeed()
	local strafing = false

	if pl:KeyDown(IN_MOVERIGHT) then
		smove = (smove * 10) + 500
		if SERVER and pl.LJ then LJ.Stats:Keys(pl, IN_MOVERIGHT, movedata) strafing = true end
	elseif pl:KeyDown(IN_MOVELEFT) then
		smove = (smove * 10) - 500
		if SERVER and pl.LJ then LJ.Stats:Keys(pl, IN_MOVELEFT, movedata) strafing = true end
	end

	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > movedata:GetMaxSpeed() then
		wishvel = wishvel * (movedata:GetMaxSpeed() / wishspeed)
		wishspeed = movedata:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = math.Clamp(wishspd, 0, 32.4)

	local wishdir = wishvel:GetNormal()
	local current = movedata:GetVelocity():Dot(wishdir)

	if SERVER and pl.LJ then
		LJ.Stats:BeginMove(pl, strafing, movedata)
	end
	
	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = 120 * FrameTime() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	local vel = movedata:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	movedata:SetVelocity(vel)

	if SERVER and pl.LJ then
		LJ.Stats:Accelerate(pl, movedata)
	end
	
	return false
end

function GM:EntityKeyValue(ent, key, value) 
	if ent:GetClass() == "func_door" then
		if LIST_DOORMAPS[game.GetMap()] then
			ent.IsP = true
		end
		if string.find(string.lower(key), "movedir") then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if string.find(string.lower(key), "noise1") then
			ent.BHS = value
		end
		if string.find(string.lower(key), "speed") then
			if tonumber(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
	
	if ent:GetClass() == "func_button" then
		if LIST_DOORMAPS[game.GetMap()] then
			ent.IsP = true
		end
		if string.find(string.lower(key), "movedir") then
			if value == "90 0 0" then
				ent.IsP = true
			end
		end
		if key == "spawnflags" then ent.SpawnFlags = value end
		if string.find(string.lower(key), "sounds") then
			ent.BHS = value
		end
		if string.find(string.lower(key), "speed") then
			if tonumber(value) > 100 then
				ent.IsP = true
			end
			ent.BHSp = tonumber(value)
		end
	end
	
	if self.BaseClass.EntityKeyValue then
		self.BaseClass:EntityKeyValue(ent, key, value)
	end
end 

IllegalKeys = {
	[MODE_SIDEWAYS] = {["Key"] = {IN_MOVELEFT, IN_MOVERIGHT}, ["Bind"] = {"moveleft", "moveright"}},
	[MODE_WONLY] = {["Key"] = {IN_MOVELEFT, IN_MOVERIGHT, IN_BACK}, ["Bind"] = {"moveleft", "moveright", "back"}}
}

hook.Add("KeyPress", "CheckIllegalKey", function(ply, key)
	if not IsFirstTimePredicted() then return end
	if not IsValid(ply) then return end

	if ply:Team() == TEAM_HOP and (ply.HopMode == MODE_SIDEWAYS or ply.HopMode == MODE_WONLY) then
		local data = IllegalKeys[ply.HopMode]
		for k,v in pairs(data.Key) do
			if key == v then
--				ply:SetEyeAngles(Angle(math.random(-90, 90), math.random(-180, 180), 0))
				ply:SetLocalVelocity(Vector(0, 0, -100))
			end
		end
	end
end)

local function AutoHop(ply, data)
	if CLIENT and ply != LocalPlayer() then return end
	
	local Style = MODE_AUTO
	if CLIENT then
		Style = PlayerMode
	elseif ply.HopMode then
		Style = ply.HopMode
	end
	
	if Style != MODE_SCROLL then
		local ButtonData = data:GetButtons()
		if bit.band(ButtonData, IN_JUMP) > 0 then
			if ply:WaterLevel() < 2 and ply:GetMoveType() != MOVETYPE_LADDER and not ply:IsOnGround() then
				ButtonData = bit.band(ButtonData, bit.bnot(IN_JUMP))
			end
			data:SetButtons(ButtonData)
		end
	end
end
hook.Add("SetupMove", "AutoHop", AutoHop)