AddCSLuaFile("shared.lua")
AddCSLuaFile("player/player_class.lua")
AddCSLuaFile("cl_data.lua")
AddCSLuaFile("cl_scoreboard.lua")

include("shared.lua")
include("player/timer.lua")
include("command.lua")
include("data.lua")
include("map.lua")
include("admin.lua")

function GM:InitPostEntity()
	LoadMapTriggers()
	SetMapTriggers()
end

function GM:Initialize()
	CacheMaps()
	ExecMapChecks(game.GetMap())
	LoadMapRecords(game.GetMap())
	InitializeVote()

	self.BaseClass:Initialize()
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_bhop")
	self.BaseClass:PlayerSpawn(ply)

	ply:SetMovementData()
	ExecMapChecks(game.GetMap(), ply)
end

function GM:PlayerInitialSpawn(ply)
	ply:LoadPlayerInfo()
	ply:SetTeam(TEAM_HOP)
	
	SendGlobalMessage(MSG_BHOP_CONNECTED, {ply:Name()}, ply)
end

-- Gamemode Overrides
function GM:CanPlayerSuicide(ply)
	return false
end

function GM:PlayerShouldTakeDamage(ply, attacker)
	return false
end

function GM:EntityTakeDamage(ent, dmginfo)
	if ent:IsPlayer() then return dmginfo:ScaleDamage(0) end
	return self.BaseClass:EntityTakeDamage(ent, dmginfo)
end

function GM:GetFallDamage(ply, speed)
    return 0
end

function GM:PlayerCanPickupWeapon(ply, wep)
	return not (wep:GetClass() == "weapon_physgun")
end

function GM:PlayerCanHearPlayersVoice(list, talk)
	return true
end

function GM:ShouldCollide(a, b)
	return not (a:IsPlayer() and b:IsPlayer())
end

----------------------------------
-- LOCAL GAMEMODE FUNCTIONS --
----------------------------------

globalVoteList = {}
globalMapData = {}
currentMapData = {}
currentMapRecords = {{}, {}, {}}
currentTopPlayers = {}

function CacheMaps()
	local list = sql.Query("SELECT * FROM mapdata")
	for i,map in pairs(list) do
		globalMapData[map['name']] = {ToVector(map['spos1']), ToVector(map['spos2']), ToVector(map['epos1']), ToVector(map['epos2']), tonumber(map['points'])}
		table.insert(globalVoteList, map['name'])
	end
	
	if globalMapData[game.GetMap()] then
		currentMapData = globalMapData[game.GetMap()]
	end
	
	globalVoteList = PrepareVoteList()
end

function PrepareVoteList()
	table.sort(globalVoteList)

	local maps = {}
	for i,map in pairs(globalVoteList) do
		table.insert(maps, {map, globalMapData[map][5]})
	end
	return maps
end

function GM:KeyPress(ply, key)
	if ply:Team() != TEAM_SPECTATOR then
		if key == IN_ATTACK then
			local wep = ply:GetActiveWeapon()
			if not wep or not wep.Clip1 then return end
			
			if wep:Clip1() < 0 then return end
			if wep:Clip1() < 32 then wep:SetClip1(32) end
			if wep:Clip2() < 64 then wep:SetClip2(64) end
		end
	else
		if not ply.SpectateID then ply.SpectateID = 1 end
		
		if key == IN_ATTACK then
			ply.SpectateType = 1
			ply.SpectateID = ply.SpectateID + 1
			ChangeSpectate(ply, true)
		elseif key == IN_ATTACK2 then
			ply.SpectateType = 1
			ply.SpectateID = ply.SpectateID - 1
			ChangeSpectate(ply, false)
		elseif key == IN_RELOAD then
			if ply.SpectateType == 2 then
				ply.SpectateType = 1
			else
				ply.SpectateType = 2
			end
			
			ChangeSpectate(ply)
		end
	end
	
	return self.BaseClass:KeyPress(ply, key)
end

--------------------------
-- SPECTATOR SENDING --
--------------------------

function ChangeSpectate(ply, forward)
	local tm = GetAlivePlayers()
	local previous = ply.CurrentObserved
	
	if ply.SpectateType == 1 then
		ply:Spectate(OBS_MODE_IN_EYE)

		if not tm[ply.SpectateID] then
			ply.SpectateID = forward and 1 or #tm
			if not tm[ply.SpectateID] then return end
		end
		
		ply:SpectateEntity(tm[ply.SpectateID])
		ply.CurrentObserved = tm[ply.SpectateID]:UniqueID()
	elseif ply.SpectateType == 2 then
		ply:Spectate(OBS_MODE_ROAMING)
		ply.CurrentObserved = ""
		return
	end
	
	SpectateChecks(ply, previous)
end

function SpectateEnd(ply)
	local target = ply:GetObserverTarget()
	if target then
		NotifySpectate(target, ply, false)
	elseif ply.CurrentObserved and string.len(ply.CurrentObserved) > 0 then
		local newTarget = PlayerByUID(ply.CurrentObserved)
		if newTarget then
			NotifySpectate(newTarget, ply, false)
		end
	end
end

function SpectateChecks(ply, pr)
	local target = ply:GetObserverTarget()
	if target and target:IsValid() then
		if target:IsBot() then
			NotifyTime(ply, target, -1)
		else
			NotifySpectate(target, ply, true)
			NotifyTime(ply, target, target.timer or -1)
		end
	end
	if pr and string.len(pr) > 0 then
		local observed = PlayerByUID(pr)
		if observed then
			NotifySpectate(observed, ply, false)
		end
	end
end

function NotifySpectate(ob, spec, bit)
	if ob:IsBot() then return end
	ob:SendData(NET_SPECDATA, {false, true, bit, spec:Name()})
end

function NotifyTime(ply, ob, timer)
	if ob:IsBot() then
		if GAMEMODE.BotData then
			ply:SendData(NET_SPECDATA, {true, false, tonumber(PlaybackStart), GAMEMODE.BotData["Name"], tonumber(GAMEMODE.BotData["Time"])})
		end
	else
		if ob.InSpawn or timer < 0 then
			ply:SendData(NET_SPECDATA, {false, false, -1, (ob.CurrentRecord and ob.CurrentRecord > 0) and ob.CurrentRecord or nil})
		elseif ob.timer and timer > 0 then
			ply:SendData(NET_SPECDATA, {false, false, ob.timer, (ob.CurrentRecord and ob.CurrentRecord > 0) and ob.CurrentRecord or nil})
		end
	end
end

function PlayerByUID(uid)
	for k,v in pairs(player.GetAll()) do
		if v:UniqueID() == uid then
			return v
		end
	end
	
	return nil
end

-------------------------------------
-- LOCAL CALCULATION FUNCTIONS --
-------------------------------------

function ToVector(data)
	local v = string.Explode(",", data)
	if #v == 3 then
		return Vector(v[1], v[2], v[3])
	end
	
	return Vector(0, 0, 0)
end

function ConvertTime(time, mili)
	if time < 0 then time = 0 end
	if time > 3600 then
		if not mili then
			return string.format("%.2d:%.2d:%.2d:%.2d", math.floor(time / 3600), math.floor(time / 60 % 60), math.floor(time % 60), math.floor(time * 60 % 60))
		else
			return string.format("%.2d:%.2d:%.2d", math.floor(time / 3600), math.floor(time / 60 % 60), math.floor(time % 60))
		end
	else
		if not mili then
			return string.format("%.2d:%.2d:%.2d", math.floor(time / 60 % 60), math.floor(time % 60), math.floor(time * 60 % 60))
		else
			return string.format("%.2d:%.2d", math.floor(time / 60 % 60), math.floor(time % 60))
		end
	end
end

function GetAlivePlayers()
	local d = {}
	for k,v in pairs(player.GetAll()) do
		if v:Team() == TEAM_HOP and v:Alive() then 
			table.insert(d, v)
		end
	end
	return d
end

function CalculateRank(Points)
	local RankID = 1
	
	for ID, Data in pairs(GAMEMODE.RankList) do
		if Points >= Data[3] and ID > RankID then
			RankID = ID
		end
	end
	
	return RankID
end