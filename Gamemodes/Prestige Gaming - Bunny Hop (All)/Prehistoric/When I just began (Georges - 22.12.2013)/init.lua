AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "vgui.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "rtv/cl_rtv.lua" )
AddCSLuaFile( "player_class/player_bhop.lua" )
AddCSLuaFile( "cl_scoreboard.lua" )

include( "rtv/sv_rtv.lua" )
include( "shared.lua" )
include( "records.lua" )

util.AddNetworkString("acp_conn")

local tab = {"1459921422","308689620","636213044","2396249607","2189768370","110192130","3011988111","911266811","2952709101","1741316097","1530711464","337607878","482195373"}

function team.GetAlivePlayers( team )

	local tab = {}
	for k, v in pairs( player.GetAll() ) do
		if v:Team() == team and v:Alive() then
			tab[#tab+1] = v
		end
	end

	return tab

end

function GM:InitPostEntity()
	self:MakeBoxes()
	timer.Simple(4,function()
		self:ReadWRRun()
	end)
end

function GM:Initialize()
	self:LoadMaps()
	self:LoadTop10()
	self:PrecacheSettings(game.GetMap())
	if(game.GetMap() == "bhop_eman_on" || game.GetMap() == "bhop_together" || game.GetMap() == "bhop_highfly" || game.GetMap() == "bhop_drop") then
		timer.Simple(1, function() game.ConsoleCommand("sv_airaccelerate 1000\n") end)
	end
	self.BaseClass:Initialize()
end

local randomModels = {
	"models/player/group01/male_01.mdl", 
	"models/player/group01/male_02.mdl",
	"models/player/group01/male_03.mdl", 
	"models/player/group01/male_04.mdl", 
	"models/player/group01/male_05.mdl", 
	"models/player/group01/male_06.mdl", 
	"models/player/group01/male_07.mdl", 
	"models/player/group01/male_08.mdl"
}

function GM:PlayerSpawn( ply )
	player_manager.SetPlayerClass( ply, "player_bhop" )
	
	self.BaseClass:PlayerSpawn( ply )
	
	ply.HasFinished = false
		
	ply.JustSpawned = true
	
	ply:SetModel(table.Random(randomModels))
	ply:SetColor(Color(255,255,255,120))
	ply:SetRenderMode(RENDERMODE_TRANSALPHA)
	if(ply.CurEquip[2] != "none_model" && ply:IsVIP()) then
			ply:SetColor(Color(255,255,255,255))
	end

	if(game.GetMap() == "kz_bhop_yonkoma") then
		timer.Simple(1,function() if(ply && ply:IsValid()) then ply:SetStepSize(16) end end)
		if(ply.HasR) then
			timer.Simple(0.1,function() if(ply && ply:IsValid()) then ply:SetPos(Vector(828, 4151, 1169)) end end)
		end
	end
end

local function PointsToRank(p)
	local r = 1
	for k,v in pairs(GAMEMODE.RankList) do
		if(k > r && p >= v[3]) then
			r = k
		end
	end
	return r
end

function GM:PlayerInitialSpawn( ply )
	ply.bhmde = 1
	timer.Simple(1,function()
	local yours = sql.Query("SELECT * FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `unique_id`='"..ply:UniqueID().."'")
	local rec = 0

	if(yours) then
		if(!yours[1]['name'] || yours[1]['name'] == '' || yours[1]['name'] == "") then
			sql.Query("UPDATE playerrecords SET `name`="..sql.SQLStr(ply:Nick()).." WHERE `unique_id`='"..ply:UniqueID().."'")
		end
		rec = yours[1]['time'..ply.bhmde]
	end
	rec = tonumber(rec)
	if(rec > 0) then
		ply:SendLua("SetRecord("..rec..")")
		ply:SetNWInt("SBRC",rec)
	end
	ply.currecord = rec
	
	ply.brankp = self:GetPoints(ply:UniqueID())
	ply.brank = PointsToRank(ply.brankp)
	ply:SetNWInt("MyRank",ply.brank)
	ply.thmode = 0
	ply:SendLua("bh_thirdperson = "..ply.thmode)
	ply:SendLua("StopTime(0.01)")
	ply:SendLua("bhmde = "..ply.bhmde)
	ply:SetNWInt("BHType",ply.bhmde)
	self:SendRecs(ply)
	end)
	ply:SetTeam( TEAM_HOP )
end

function GM:PlayerUse(ply, Ent)
	if(ply:Alive() && ply:Team() == TEAM_HOP) then
		return true
	end
	return false
end

function GM:ShowSpare1( ply )
	if(!ply.InSpec) then
		local th = ply.thmode
		if(th == 1) then
			th = 0
		else
			th = 1
		end
		ply.thmode = th
		ply:SendLua("bh_thirdperson = "..th)
	end
end

function GM:PlayerSwitchFlashlight( ply, SwitchOn )
	return true
end

function RestartMap(ply,cmd,args)
	if(ply:Team() != TEAM_SPECTATOR) then
		ply.HasR = true
		--ply:PS_PlayerDeath()
		ply:Spawn()
		timer.Simple(0.1,function ()
			ply:SendLua("StopTime(0.01)")
			ply.Started = false
		end)
	end
end
concommand.Add("bh_restart",RestartMap)
lechat.AddCmd("/restart",nil,RestartMap)
lechat.AddCmd("/r",nil,RestartMap)

function GM:ShowTeam(ply)
	local th = ply.thmode
	if(th == 0) then
		if(!ply.InSpec) then
			ply:SendLua("Derma_Query('Start Spectating?','Spectator','Yes',function() RunConsoleCommand('bh_spec') end,'No',function() end)")
		else
			ply:SendLua("Derma_Query('Stop Spectating?','Spectator','Yes',function() RunConsoleCommand('bh_spec') end,'No',function() end)")
		end
	end
end

function GM:PlayerCanHearPlayersVoice( list, talk )
	return true
end

function GM:ShowHelp( ply )
	ply:SendLua([[ShowHelp()]])
end

function ShowWR(ply,cmd,args)
	ply:SendLua([[ShowWR()]])
end
concommand.Add("bh_wrs",ShowWR)
lechat.AddCmd("/wr",nil,ShowWR)
lechat.AddCmd("!wr",nil,ShowWR)

function ShowMode(ply,cmd,args)
	ply:SendLua([[ShowModes()]])
end
concommand.Add("bh_openmodeswitch",ShowMode)
lechat.AddCmd("/mode",nil,ShowMode)
lechat.AddCmd("!mode",nil,ShowMode)

function SwitchMode(ply,cmd,args)
	if(!args[1]) then return end
	args[1] = tonumber(args[1])
	chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] Switched to "..GAMEMODE.ModeName[args[1]])
	ply.bhmde = args[1]
	local yours = sql.Query("SELECT * FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `unique_id`='"..ply:UniqueID().."'")
	local rec = 0
	local rec = tonumber(yours[1]['time'..ply.bhmde] or 0)
	ply.currecord = rec
	ply:SendLua("SetRecord("..ply.currecord..")")
	ply:SetNWInt("BHType",args[1])
	ply:SetNWInt("SBRC",rec)
	ply:SendLua("bhmde = "..args[1])
	if(ply.Started) then
		RestartMap(ply)
	end
end
concommand.Add("bh_modeswitch",SwitchMode)

function Spectate(ply,cmd,args)
	if(!ply.InSpec) then
		ply.InSpec = true
		--ply:PS_PlayerDeath()
		GAMEMODE:PlayerSpawnAsSpectator(ply)
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Spectate(OBS_MODE_IN_EYE)
		local tm = team.GetAlivePlayers(TEAM_HOP)
		ply:SpectateEntity( tm[1] )
		ply.spPerson = 1
		ply.spType = 1
	else
		ply.InSpec = false
		ply:SetTeam(TEAM_HOP)
		RestartMap(ply)
	end
end
concommand.Add("bh_spec",Spectate)

local wrframes = 1
local wrsecs = 1
local WRBotEnabled = false

if (WRBotEnabled) then
timer.Create("WRBot",1/120,0,function()
	for k,v in pairs(player.GetAll()) do
		if(!v.RecordMe) then continue end
		if(v:Team() == TEAM_HOP) then
			if(v.Started && !v.HasFinished && v.Secs && v.Frames) then
				if(v.Frames == 0) then
					v.Frames = 1
					v.Q1 = {}
					v.Q2 = {}
					v.Q3 = {}
					v.Q4 = {}
				end
				if(v.Secs/60<30) then
					local start = 0
					local f = v.Secs - start
					if(!v.Q1[f]) then
						v.Q1[f] = ""
					end
					local p = v:GetPos()
					local ang = v:GetAngles()
					local aim = v:EyeAngles()
					local r = v:GetRenderAngles()
					local addon = p.x..","..p.y..","..p.z..":"..ang.p..","..ang.y..","..ang.r..":"..aim.p..","..aim.y..","..aim.r..":"..r.p..","..r.y..","..r.r..";"
					v.Q1[f] = v.Q1[f]..addon
				elseif(v.Secs/60<60) then
					local start = 29*60
					local f = v.Secs - start
					if(!v.Q2[f]) then
						v.Q2[f] = ""
					end
					local p = v:GetPos()
					local ang = v:GetAngles()
					local aim = v:EyeAngles()
					local r = v:GetRenderAngles()
					local addon = p.x..","..p.y..","..p.z..":"..ang.p..","..ang.y..","..ang.r..":"..aim.p..","..aim.y..","..aim.r..":"..r.p..","..r.y..","..r.r..";"
					v.Q2[f] = v.Q2[f]..addon
				elseif(v.Secs/60<90) then
					local start = 59*60
					local f = v.Secs - start
					if(!v.Q3[f]) then
						v.Q3[f] = ""
					end
					local p = v:GetPos()
					local ang = v:GetAngles()
					local aim = v:EyeAngles()
					local r = v:GetRenderAngles()
					local addon = p.x..","..p.y..","..p.z..":"..ang.p..","..ang.y..","..ang.r..":"..aim.p..","..aim.y..","..aim.r..":"..r.p..","..r.y..","..r.r..";"
					v.Q3[f] = v.Q3[f]..addon
				elseif(v.Secs/60<=120) then
					local start = 89*60
					local f = v.Secs - start
					if(!v.Q4[f]) then
						v.Q4[f] = ""
					end
					local p = v:GetPos()
					local ang = v:GetAngles()
					local aim = v:EyeAngles()
					local r = v:GetRenderAngles()
					local addon = p.x..","..p.y..","..p.z..":"..ang.p..","..ang.y..","..ang.r..":"..aim.p..","..aim.y..","..aim.r..":"..r.p..","..r.y..","..r.r..";"
					v.Q4[f] = v.Q4[f]..addon
				end
				v.Frames = v.Frames + 1
				v.Secs = math.floor((v.Frames/120)+1)
			end
		end
	end
	if(GAMEMODE.WRBot && GAMEMODE.WRBot:IsValid() && GAMEMODE.WR1) then
		local bot = GAMEMODE.WRBot
		if(GAMEMODE.NewWR) then
			GAMEMODE.NewWR = false
			wrframes = 1
			wrsecs = 1
		end
		if wrframes >= GAMEMODE.WRFrames then
			wrframes = 1
			wrsecs = 1
		end
		if(wrsecs/60<30 && GAMEMODE.WR1) then
			local start = 0
			local f = wrframes - start
			if(!GAMEMODE.WR1[f] || GAMEMODE.WR1[f] == "") then
				wrframes = wrframes + 1
				f = wrframes - start
			end
			local split = string.Explode(":",GAMEMODE.WR1[f])
			local sp1 = string.Explode(",",split[1])
			local sp2 = string.Explode(",",split[2])
			local sp3 = string.Explode(",",split[3])
			local sp4 = string.Explode(",",string.gsub(split[4],".",","))
			bot:SetPos(Vector(sp1[1],sp1[2],sp1[3]))
			bot:SetAngles(Angle(tonumber(sp2[1]),tonumber(sp2[2]),tonumber(sp2[3])))
			bot:SetEyeAngles(Angle(tonumber(sp3[1]),tonumber(sp3[2]),tonumber(sp3[3])))
			bot:SetRenderAngles(Angle(tonumber(sp4[1]),tonumber(sp4[2]),tonumber(sp4[3])))
		elseif(wrsecs/60<60 && GAMEMODE.WR2) then
			local start = 29*120*60
			local f = wrframes - start
			if(!GAMEMODE.WR2[f] || GAMEMODE.WR2[f] == "") then
				wrframes = wrframes + 1
				f = wrframes - start
			end
			local split = string.Explode(":",GAMEMODE.WR2[f])
			local sp1 = string.Explode(",",split[1])
			local sp2 = string.Explode(",",split[2])
			local sp3 = string.Explode(",",split[3])
			local sp4 = string.Explode(",",string.gsub(split[4],".",","))
			bot:SetPos(Vector(sp1[1],sp1[2],sp1[3]))
			bot:SetAngles(Angle(tonumber(sp2[1]),tonumber(sp2[2]),tonumber(sp2[3])))
			bot:SetEyeAngles(Angle(tonumber(sp3[1]),tonumber(sp3[2]),tonumber(sp3[3])))
			bot:SetRenderAngles(Angle(tonumber(sp4[1]),tonumber(sp4[2]),tonumber(sp4[3])))
		elseif(wrsecs/60<90 && GAMEMODE.WR3) then
			local start = 59*120*60
			local f = wrframes - start
			if(!GAMEMODE.WR3[f] || GAMEMODE.WR3[f] == "") then
				wrframes = wrframes + 1
				f = wrframes - start
			end
			local split = string.Explode(":",GAMEMODE.WR3[f])
			local sp1 = string.Explode(",",split[1])
			local sp2 = string.Explode(",",split[2])
			local sp3 = string.Explode(",",split[3])
			local sp4 = string.Explode(",",string.gsub(split[4],".",","))
			bot:SetPos(Vector(sp1[1],sp1[2],sp1[3]))
			bot:SetAngles(Angle(tonumber(sp2[1]),tonumber(sp2[2]),tonumber(sp2[3])))
			bot:SetEyeAngles(Angle(tonumber(sp3[1]),tonumber(sp3[2]),tonumber(sp3[3])))
			bot:SetRenderAngles(Angle(tonumber(sp4[1]),tonumber(sp4[2]),tonumber(sp4[3])))
		elseif(wrsecs/60<120 && GAMEMODE.WR4) then
			local start = 89*120*60
			local f = wrframes - start
			if(!GAMEMODE.WR4[f] || GAMEMODE.WR4[f] == "") then
				wrframes = wrframes + 1
				f = wrframes - start
			end
			local split = string.Explode(":",GAMEMODE.WR4[f])
			local sp1 = string.Explode(",",split[1])
			local sp2 = string.Explode(",",split[2])
			local sp3 = string.Explode(",",split[3])
			local sp4 = string.Explode(",",string.gsub(split[4],".",","))
			bot:SetPos(Vector(sp1[1],sp1[2],sp1[3]))
			bot:SetAngles(Angle(tonumber(sp2[1]),tonumber(sp2[2]),tonumber(sp2[3])))
			bot:SetEyeAngles(Angle(tonumber(sp3[1]),tonumber(sp3[2]),tonumber(sp3[3])))
			bot:SetRenderAngles(Angle(tonumber(sp4[1]),tonumber(sp4[2]),tonumber(sp4[3])))
		end
		wrframes = wrframes + 1
		wrsecs = math.floor((wrframes/120)+1)
	end
	if(GAMEMODE.WRBot && !GAMEMODE.WRBot:IsValid() && GAMEMODE.WR1 && #player.GetAll() != 0) then
		GAMEMODE:SpawnBot()
	end
end)
end

function GM:Think()
	for k,v in pairs(player.GetAll()) do
		if(v:IsBot()) then 
			if(v:GetMoveType() == 2) then
				v:SetMoveType(0)
			end
			continue
		end
		if(!v.HasFinished && v.Started && self:InRecordArea(v)) then
			local FinishTime = CurTime() - v.StartTime
			v:SendLua("FinishedMap("..FinishTime..")")
			v.HasFinished = true
			v.Started = false
			self:FinishMap(v,FinishTime)
		end
		if(!v.Starter && self:IsStarter(v)) then
			if(v.HasFinished) then
				v.HasFinished = false
				v:SendLua("StopTime(0.01)")
			end
			v.Starter = true
			if(v.Started) then
				v.Started = false
				v:SendLua("StopTime(0.01)")
			end
		end
		if(v.Starter && self:ShouldStart(v)) then
			v.Starter = false
			v.Started = true
			v.Q1 = nil
			v.Q2 = nil
			v.Q3 = nil
			v.Q4 = nil
			v.Secs = 1
			v.Frames = 0
			v:SendLua("StopTime(0)")
			v.StartTime = CurTime()
			v:SendLua("StartTime("..v.StartTime..")")
		end
	end
	self.BaseClass:Think()
end

function MPFallDamage( ply, vel )
	if(game.GetMap() != "kz_bhop_yonkoma") then
		return 0
	end
end
hook.Add( "GetFallDamage", "MPFallDamage", MPFallDamage )

function GM:EntityKeyValue( ent, key, value )
     
    if !GAMEMODE.BaseStoreOutput or !GAMEMODE.BaseTriggerOutput then
     
        local e = scripted_ents.Get( "base_entity" )
        GAMEMODE.BaseStoreOutput = e.StoreOutput
        GAMEMODE.BaseTriggerOutput = e.TriggerOutput
         
    end
 
    if key:lower():sub( 1, 2 ) == "on" then
         
        if !ent.StoreOutput or !ent.TriggerOutput then -- probably an engine entity
         
            ent.StoreOutput = GAMEMODE.BaseStoreOutput
            ent.TriggerOutput = GAMEMODE.BaseTriggerOutput
            
		end
		
        if ent.StoreOutput then
                 
            ent:StoreOutput( key, value )
                 
        end
         
    end
     
end

function GM:EntityTakeDamage( ent, dmginfo )
	if(ent:IsPlayer() && dmginfo:GetAttacker():IsPlayer()) then return false end
	
	return self.BaseClass:EntityTakeDamage( ent, dmginfo )
end

function GM:PlayerShouldTakeDamage( ply, attacker )
	return false
end

function GM:PlayerCanPickupWeapon( ply, wep )
	if(wep:GetClass() == "weapon_physgun") then return false end
	return true
end

function GM:CanPlayerSuicide( ply )
	return false
end

function GM:KeyPress( ply, key )

	if ply:Team() == TEAM_SPECTATOR then

		if not ply.spType then ply.spType = 1 end
		if not ply.spPerson then ply.spPerson = 1 end

		if key == IN_ATTACK then
			ply.spPerson = ply.spPerson + 1
			ChangeSpectate( ply )
		elseif key == IN_ATTACK2 then
			ply.spPerson = ply.spPerson - 1
			ChangeSpectate( ply )
		elseif key == IN_RELOAD then
			ply.spType = ply.spType + 1
			ChangeSpectate( ply )
		end
	end

	return self.BaseClass:KeyPress( ply, key )


end 

local SPM = {}
SPM[1] = OBS_MODE_IN_EYE
SPM[2] = OBS_MODE_ROAMING

function ChangeSpectate( ply )
	local mode = ply.spType
	if #team.GetAlivePlayers(TEAM_HOP) > 0 then
		local tm = team.GetAlivePlayers(TEAM_HOP)
		if not SPM[mode] then
			ply.spType = 1
			ply:Spectate( ply.spType )
			if not tm[ply.spPerson] then ply.spPerson = 1 end
			ply:SpectateEntity( tm[ply.spPerson] )
			return
		end
			
		ply:Spectate( SPM[mode] )
		if mode == 2 then return end

		if tm[ply.spPerson] then
			ply:SpectateEntity( tm[ply.spPerson] )
		else
			ply.spPerson = 1
			ply:SpectateEntity( tm[ply.spPerson] )
		end
	else
		ply:Spectate( OBS_MODE_ROAMING )
	end

end

-- Admin Panel
local ACP_qSelectLimit = 10
local function ACP_IsAllowed( ply )
	if ply:UniqueID() == "3974409736" then return true else return false end
end

local function ACP_TM_CheckTime( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local plyId = tonumber(args[1])
	if !plyId then return end
	local plyMap = args[2]
	if !string.find(plyMap, "bhop_") then return end
	
	local data = sql.Query("SELECT `time" .. ply.bhmde .. "` AS `time`, `map_name`, `unique_id` FROM playerrecords WHERE `unique_id`='" .. plyId .. "' AND `map_name`="..sql.SQLStr(plyMap)) or {}
	
	net.Start("acp_conn")
	net.WriteInt(2,10)
	net.WriteTable(data)
	net.Send(ply)
	--ply:SendLua([[ShowHelp()]])
end
concommand.Add( "acp_tm_time", ACP_TM_CheckTime )

local function ACP_TM_CheckTimeId( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local plyId = tonumber(args[1])
	if !plyId then return end

	local data = sql.Query("SELECT `time" .. ply.bhmde .. "` AS `time`, `map_name`, `unique_id` FROM playerrecords WHERE `unique_id`='" .. plyId .. "' AND `time` != 0 ORDER BY `time` ASC LIMIT "..ACP_qSelectLimit) or {}
	
	net.Start("acp_conn")
	net.WriteInt(3,10)
	net.WriteTable(data)
	net.Send(ply)
end
concommand.Add( "acp_tm_timeid", ACP_TM_CheckTimeId )

local function ACP_TM_CheckTimeMap( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local plyMap = args[1]
	if !string.find(plyMap, "bhop_") then return end
	
	local data = sql.Query("SELECT `time" .. ply.bhmde .. "` AS `time`, `map_name`, `unique_id`, `name` FROM playerrecords WHERE `map_name`="..sql.SQLStr(plyMap) .. " AND `time` != 0 ORDER BY `time` ASC LIMIT "..ACP_qSelectLimit) or {}
	
	net.Start("acp_conn")
	net.WriteInt(4,10)
	net.WriteTable(data)
	net.Send(ply)
end
concommand.Add( "acp_tm_timemap", ACP_TM_CheckTimeMap )

local function ACP_TM_CheckTimeAll( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local data = sql.Query("SELECT `time" .. ply.bhmde .. "` AS `time`, `map_name`, `unique_id`, `name` FROM playerrecords WHERE `time` != 0 ORDER BY `time` ASC LIMIT "..ACP_qSelectLimit) or {}
	
	net.Start("acp_conn")
	net.WriteInt(5,10)
	net.WriteTable(data)
	net.Send(ply)
end
concommand.Add( "acp_tm_timeall", ACP_TM_CheckTimeAll )

local function ACP_TM_CheckName( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end
	if string.len(args[1]) < 4 then return end
	
	local data = sql.Query("SELECT DISTINCT `unique_id`, `name` FROM `playerrecords` WHERE `name` LIKE " .. sql.SQLStr("%"..args[1].."%")) or {}

	net.Start("acp_conn")
	net.WriteInt(1,10)
	net.WriteTable(data)
	net.Send(ply)
end
concommand.Add( "acp_tm_id", ACP_TM_CheckName )

local function ACP_TM_RemoveTime( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local plyId = tonumber(args[1])
	if !plyId then return end
	local plyMap = args[2]
	if !string.find(plyMap, "bhop_") then return end
	
	sql.Query("DELETE FROM `playerrecords` WHERE `map_name`="..sql.SQLStr(plyMap).." AND `unique_id`='"..plyId.."'")
	chat.AddText(ply, "Time has been removed.")
end
concommand.Add( "acp_tm_rem", ACP_TM_RemoveTime )

local function ACP_TM_EditTime( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end

	local plyTime = tonumber(args[1])
	if !plyTime then return end
	local plyId = tonumber(args[2])
	if !plyId then return end
	local plyMap = args[3]
	if !string.find(plyMap, "bhop_") then return end
	
	sql.Query("UPDATE `playerrecords` SET `time"..ply.bhmde.."`="..plyTime.." WHERE `map_name`="..sql.SQLStr(plyMap).." AND `unique_id`='"..plyId.."'")
	chat.AddText(ply, "Time has been updated.")
end
concommand.Add( "acp_tm_edit", ACP_TM_EditTime )

local function ACP_SelectLimit( ply, cmd, args )
	if !ACP_IsAllowed(ply) then return end
	local selectLimit = tonumber(args[1])
	if !selectLimit then return end
	ACP_qSelectLimit = selectLimit
	
	chat.AddText(ply, "SELECT Limit has been changed to "..ACP_qSelectLimit)
end
concommand.Add( "acp_sel_limit", ACP_SelectLimit )