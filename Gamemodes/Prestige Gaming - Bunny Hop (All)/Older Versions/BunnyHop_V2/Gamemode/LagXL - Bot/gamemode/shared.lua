include("player/player_class.lua")

GM.Name 	= "Bunny Hop"
GM.Author 	= "Gravious"
GM.Email 	= ""
GM.Website 	= "prestige-gaming.org"
GM.TeamBased = true

GM.RankList = {
	{"Astronaut",		Color(255, 255, 255),	0},
	{"Initiate",			Color(166, 166, 166),	15},
	{"Newbie",			Color(255, 255, 98),		35},
	{"Beginner",		Color(101, 67, 33),		70},
	{"Rookie",			Color(250, 218, 221),	125},
	{"Apprentice",		Color(80, 80, 80),		200},
	{"Decent",			Color(0,8,8),				290},
	{"Novice",			Color(96, 16, 176),		400},
	{"Getting There",	Color(206, 255, 157),	540},
	{"Average",			Color(128, 128, 128),	700},
	{"Intermediate",	Color(255, 192, 203),	890},
	{"Awesome",		Color(1, 50, 32),			1105},
	{"Advanced",		Color(0, 0, 60),			1350},
	{"Skilled",			Color(98, 0, 0),			1625},
	{"Impressive",		Color(255, 128, 0),		1930},
	{"Pro",				Color(0, 0, 139),			2265},
	{"Hardcore",		Color(196, 255, 196),	2635},
	{"Respected",		Color(30, 166, 48),		3035},
	{"Prestigious",		Color(196, 255, 196),	3475},
	{"Expert",			Color(255, 255, 0),		3950},
	{"Veteran",			Color(128, 0, 128),		4450},
	{"Famous",			Color(0, 168, 255),		5005},
	{"Sublime",			Color(255, 101, 0),		5590},
	{"Beast",			Color(0, 255, 128),		6215},
	{"Wicked",			Color(170, 0, 0),			6880},
	{"Epic",				Color(0, 255, 191),		7590},
	{"Addict",			Color(139, 0, 0),			8335},
	{"Brutal",			Color(190, 255, 0),		9125},
	{"Elite",				Color(255, 0, 255),		9960},
	{"Insane",			Color(255,0,0),			10835},
	{"Nightmare",		Color(255,0,64),			11755},
	{"Divine",			Color(255, 235, 0),		12725},
	{"Stoner",			Color(0, 255, 0),			13735},
	{"Hax0r",			Color(0, 0, 255),			15000},
	{"Majestic",		Color(255, 215, 0),		15900},
	{"God",				Color(0, 255, 255),		16955},
}

TEAM_HOP = 2
AREA_START = 1
AREA_FINISH = 2
AREA_BLOCK = 3
AREA_TELEPORT = 4
AREA_STEPSIZE = 5
AREA_VELOCITY = 6

MODE_NORMAL = 1
MODE_SIDEWAYS = 2
MODE_WONLY = 3
MODE_AUTO = 4
MODE_TELEPORT = 5
MODE_NAME = {[MODE_NORMAL] = "Normal", [MODE_SIDEWAYS] = "Sideways", [MODE_WONLY] = "W-Only", [MODE_TELEPORT] = "Teleportation", [MODE_AUTO] = "Auto Hop"}

NET_TOPLIST = 1
NET_RTVLIST = 2
NET_RTVVOTES = 3
NET_MAPSBEAT = 4
NET_MAPSLEFT = 5
NET_SPECDATA = 6

TEXT_BHOP = 1
TEXT_TIMER = 2
TEXT_ADMIN = 3

MSG_RTV_NOMSET = 1
MSG_RTV_NOMCHG = 2
MSG_RTV_DO = 3
MSG_RTV_WAIT = 4
MSG_RTV_VOTED = 5
MSG_RTV_CHANGE = 6
MSG_RTV_MAP = 7
MSG_TXT_TPTO = 8
MSG_TXT_TPCMD = 9
MSG_WR_NOR_FINISH = 10
MSG_WR_IMPR_FINISH = 11
MSG_WR_TOP_FINISH = 12
MSG_WR_TOPIMPR_FINISH = 13
MSG_WR_RECORDED = 14
MSG_RTV_ALNOM = 15
MSG_ADMIN_GENERAL = 16
MSG_BHOP_GENERAL = 17

VEC_VIEWSTAND = Vector(0, 0, 64)
VEC_VIEWDUCK = Vector(0, 0, 47)
VEC_HULLMIN = Vector(-16, -16, 0)
VEC_HULLSTAND = Vector(16, 16, 62)
VEC_HULLDUCK = Vector(16, 16, 45)

PLAYER_SPEED = 0
PLAYER_AFK_LIMIT = 12 * 10
PLAYER_RTV_TIME = 60 * 15
PLAYER_BOT_PLAYBACK = 100
PLAYER_BOT_MINIMUM = 18

COLOR_DIFFICULTY = {Color(210, 255, 210), Color(210, 255, 255), Color(210, 210, 255), Color(255, 248, 210), Color(255, 210, 210)}

LIST_DOORMAPS = {"bhop_monster_jam", "bhop_bkz_goldhop", "bhop_aoki_final"}
LIST_NOMAPTRIGS = {"bhop_fury", "bhop_hive"}

if SERVER then
	resource.AddFile("materials/pgsb/HUD.png")
	resource.AddFile("materials/pgsb/HUDPointer.png")
	resource.AddFile("materials/pgsb/header.png")
	resource.AddFile("materials/pgsb/emblem.png")
	resource.AddFile("materials/pgsb/topright.png")
end

function GM:CreateTeams()
	team.SetUp(TEAM_HOP, "Players", Color(255, 50, 50, 255), false)
	team.SetSpawnPoint(TEAM_HOP, {"info_player_terrorist", "info_player_counterterrorist"})
	team.SetUp(TEAM_SPECTATOR, "Spectators", Color(50, 255, 50, 255), true)
end

function GM:PlayerNoClip(ply)
	return false
end

------------------------
-- PLAYER MOVEMENT --
------------------------

function EKV_BH(ent, key, value)
	if ent:GetClass() == "func_door" then
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
end
hook.Add("EntityKeyValue", "EKV_BH", EKV_BH)

function PHG_BH(ply)
	--multiplayer bhops implementation
	local ent = ply:GetGroundEntity()
	if(tonumber(ent:GetNWInt("Platform",0)) == 0) then return end
    if (ent:GetClass() == "func_door" || ent:GetClass() == "func_button") && ent.BHSp && ent.BHSp > 100 then
		ply:SetVelocity( Vector( 0, 0, ent.BHSp*2 ) )
	elseif ent:GetClass() == "func_door" || ent:GetClass() == "func_button" then
		timer.Simple( 0.08, function()
			-- setting owner stops collision between two entities
			ent:SetOwner(ply)
			if(CLIENT)then
				ent:SetColor(Color(255,255,255,125))
			end
		end)
		timer.Simple( 0.7, function()  ent:SetOwner(nil) end)
		timer.Simple( 0.7, function()  if(CLIENT)then ent:SetColor(Color (255,255,255,255)) end end)
	end
end
hook.Add("OnPlayerHitGround", "PHG_BH", PHG_BH)

function GM:OnPlayerHitGround(ply)
	ply:SetJumpPower(268.4)
	timer.Simple(0.3, function() ply:SetJumpPower(280) end)
	
	if (self.BaseClass && self.BaseClass.OnPlayerHitGround) then
		self.BaseClass:OnPlayerHitGround(ply)
	end
end

function GM:Move(pl, movedata)
	if(!pl or !pl:IsValid()) then return end
	
	if SERVER then
		local tracedata = {}
		local maxs = pl:Crouching() and VEC_HULLDUCK or VEC_HULLSTAND
		local v = pl:Crouching() and VEC_VIEWDUCK or VEC_VIEWSTAND
		local offset = pl:Crouching() and pl:GetViewOffsetDucked() or pl:GetViewOffset()
		local mins = VEC_HULLMIN
		local s = pl:GetPos()
		s.z = s.z + maxs.z
		tracedata.start = s
		local e = Vector(s.x,s.y,s.z)
		e.z = e.z + (12 - maxs.z)
		e.z = e.z + v.z
		tracedata.endpos = e
		tracedata.filter = pl
		tracedata.mask = MASK_PLAYERSOLID
		local trace = util.TraceLine(tracedata)
		if (trace.Fraction < 1) then
			local est = s.z + trace.Fraction * (e.z - s.z) - pl:GetPos().z - 12
			if not pl:Crouching() then
				offset.z = est
				pl:SetViewOffset(offset)
			else
				offset.z = math.min(offset.z, est)
				pl:SetViewOffsetDucked(offset)
			end
		else
			pl:SetViewOffset(VEC_VIEWSTAND)
			pl:SetViewOffsetDucked(VEC_VIEWDUCK)
		end
	else
		PLAYER_SPEED = math.floor(movedata:GetVelocity():Length())
	end
	
	if pl:IsOnGround() or !pl:Alive() or pl:WaterLevel() > 0 then return end
	if SERVER then
		if pl.InSpawn and movedata:GetVelocity():Length() > 400 then
			movedata:SetVelocity(Vector(0, 0, 0))
			return false
		end
	end
	
	local aim = movedata:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = movedata:GetForwardSpeed()
	local smove = movedata:GetSideSpeed()
	
	if pl:KeyDown( IN_MOVERIGHT ) then
		smove = (smove * 10) + 500
	elseif pl:KeyDown( IN_MOVELEFT ) then
		smove = (smove * 10) - 500
	end
	
	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()

	if(wishspeed > movedata:GetMaxSpeed()) then
		wishvel = wishvel * (movedata:GetMaxSpeed()/wishspeed)
		wishspeed = movedata:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = math.Clamp(wishspd, 0, 30)

	local wishdir = wishvel:GetNormal()
	local current = movedata:GetVelocity():Dot(wishdir)

	local addspeed = wishspd - current

	if(addspeed <= 0) then return end

	local accelspeed = (120) * wishspeed * FrameTime()

	if(accelspeed > addspeed) then
		accelspeed = addspeed
	end

	local vel = movedata:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	movedata:SetVelocity(vel)

	return false
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
				ply:SetLocalVelocity(Vector(0, 0, -100))
			end
		end
	end
end)

local function AutoHop(ply, data)
	if CLIENT and ply != LocalPlayer() then return end
	
	local Style = MODE_NORMAL
	if CLIENT then
		Style = PlayerMode
	elseif ply.HopMode then
		Style = ply.HopMode
	end
	
	if Style == MODE_AUTO || Style == MODE_TELEPORT then
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