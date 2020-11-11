DeriveGamemode( "base" )
DEFINE_BASECLASS( "gamemode_base" )

include("player_class/player_bhop.lua")

GM.Name 	= "Bunny Hop"
GM.Author 	= "George"
GM.Email 	= ""
GM.Website 	= "prestige-gaming.org"
GM.TeamBased = true

TEAM_HOP = 2

GM.ModeName = {"Normal","Sideways","W-Only"}

GM.RankList = {
	{"Astronaut", Color(255, 255, 255), 0},
	{"Initiate", Color(166, 166, 166), 15},
	{"Newbie", Color(255, 255, 98), 35},
	{"Beginner",Color(101, 67, 33),70},
	{"Rookie",Color(250, 218, 221),125},
	{"Apprentice",Color(30, 166, 48),200},
	{"Decent",Color(0,8,8),290},
	{"Novice",Color(96, 16, 176),400},
	{"Getting There",Color(206, 255, 157),540},
	{"Average",Color(128, 128, 128),700},
	{"Intermediate",Color(255, 192, 203),890},
	{"Awesome",Color(1, 50, 32),1105},
	{"Advanced",Color(0, 0, 60),1350},
	{"Skilled",Color(98, 0, 0),1625},
	{"Impressive",Color(255, 128, 0),1930},
	{"Pro",Color(0, 0, 139),1320},
	{"Hardcore",Color(196, 255, 196),2635},
	{"Respected",Color(80, 80, 80),3035},
	{"Prestigious",Color(196, 255, 196),3475},
	{"Expert",Color(255, 255, 0),3950},
	{"Veteran",Color(128, 0, 128),4450},
	{"Famous",Color(0, 168, 255),5005},
	{"Sublime",Color(255, 101, 0),5590},
	{"Beast",Color(0, 255, 128),6215},
	{"Wicked",Color(170, 0, 0),6880},
	{"Epic",Color(0, 255, 191),7590},
	{"Addict",Color(139, 0, 0),8335},
	{"Brutal",Color(190, 255, 0),9125},
	{"Elite",Color(255, 0, 255),9960},
	{"Insane",Color(255,0,0),10835},
	{"Nightmare",Color(255,0,64),11755},
	{"Divine",Color(255, 235, 0),12725},
	{"Stoner",Color(0, 255, 0),13735},
	{"Hax0r",Color(0, 0, 255),15000},
	{"Majestic",Color(255, 215, 0),15900},
	{"God",Color(0, 255, 255),16990},
}

function GM:CreateTeams()
	team.SetUp( TEAM_HOP, "Hoppers", Color( 255, 50, 50, 255 ), false )
	team.SetSpawnPoint( TEAM_HOP, {"info_player_terrorist", "info_player_counterterrorist"} )

	team.SetUp( TEAM_SPECTATOR, "Spectator", Color( 50, 255, 50, 255 ), true )
end

function GM:PlayerNoClip( ply )
	return false
end

function GM:OnPlayerHitGround(ply)
	
	-- this is my simple implementation of the jump boost
	ply:SetJumpPower(268.4)
	timer.Simple(0.3,function () ply:SetJumpPower(280) end)
	
	if(self.BaseClass && self.BaseClass.OnPlayerHitGround) then
		self.BaseClass:OnPlayerHitGround(ply)
	end
end

function GM:Move(pl, movedata)
	if(!pl or !pl:IsValid()) then return end
	
	if SERVER then
		pl.sp = math.floor(movedata:GetVelocity():Length())
	end
	
	if pl:IsOnGround() or !pl:Alive() or pl:WaterLevel() > 0 then return end
	
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

if CLIENT then 
	hook.Add("PlayerBindPress","CheckIllegalKey",function(ply,bind,pressed)
		if string.find(bind, "moveright") && (bhmde == 2 || bhmde == 3) then 
			if(pressed) then
				chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] This key is not allowed in "..GAMEMODE.ModeName[bhmde].." mode.")
			end
			return true
		end
		if string.find(bind, "moveleft") && (bhmde == 2 || bhmde == 3) then 
			if(pressed) then
				chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] This key is not allowed in "..GAMEMODE.ModeName[bhmde].." mode.")
			end
			return true
		end
		if string.find(bind, "back") && bhmde == 3 then 
			if(pressed) then
				chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] This key is not allowed in "..GAMEMODE.ModeName[bhmde].." mode.")
			end
			return true
		end
	end)
	return 
end

hook.Add("KeyPress","CheckMode",function(ply,key)
	if not IsFirstTimePredicted() then return end
	if not IsValid(ply) then return end
	
	local mode = ply.bhmde
	
	if mode == 1 then return end
	if mode == 2 && (key == IN_MOVELEFT || key == IN_MOVERIGHT) then
		timer.Simple(0.1,function() if(ply && ply:IsValid()) then ply:SetLocalVelocity(Vector(0,0,-100)) end end)
	elseif mode == 3 && (key == IN_MOVELEFT || key == IN_MOVERIGHT || key == IN_BACK) then
		timer.Simple(0.1,function() if(ply && ply:IsValid()) then ply:SetLocalVelocity(Vector(0,0,-100)) end end)
	end
end)

hook.Add("PlayerSpawn","BH_HULL",function(ply)
	ply:SetHull(Vector(-16, -16, 0), Vector(16, 16, 62))
	ply:SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 45))
		
	ply:SetViewOffset(Vector(0, 0, 64))
	ply:SetViewOffsetDucked(Vector(0, 0, 47))
end)

--[[
//Paranoid Backup incase putting it shared doesn't work
timer.Create("FixHullShit",5,0,function()
	for k,v in pairs(player.GetAll()) do
		local ply = v
		if !ply:IsValid() then continue end
		ply:SendLua("SafeSetShit()")
	end
end)
]]