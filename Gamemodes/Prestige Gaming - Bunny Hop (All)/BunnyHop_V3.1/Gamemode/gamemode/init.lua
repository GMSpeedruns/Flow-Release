AddCSLuaFile("shared.lua")
AddCSLuaFile("player/player_class.lua")
AddCSLuaFile("sh_offsets.lua")
AddCSLuaFile("cl_window.lua")
AddCSLuaFile("cl_data.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_admin.lua")

include("shared.lua")
include("player/timer.lua")
include("command.lua")
include("map.lua")
include("data.lua")
include("bot.lua")
include("admin.lua")
include("lj.lua")

function GM:InitPostEntity()
	mSQLInit()
end

function GM:Initialize()
	self.BaseClass:Initialize()
end

function GM:PlayerSpawn(ply)
	player_manager.SetPlayerClass(ply, "player_bhop")
	self.BaseClass:PlayerSpawn(ply)
	
	ply:SetTeam(TEAM_HOP)
	ply:SetModel("models/player/group01/male_01.mdl")
	ply:SetHull(VEC_HULLMIN, VEC_HULLSTAND)
	ply:SetHullDuck(VEC_HULLMIN, VEC_HULLDUCK)
	ply:ResetTimer()
	
	ply:SelectWeapon("weapon_glock")
	ply:SetJumpPower(VEC_JUMPHEIGHT)

	ExecMapChecks(game.GetMap(), ply)
end

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_HOP)
	ply.HopMode = MODE_AUTO
	ply.ThirdPerson = 0
	ply.RankID = 1
	ply.RankWeight = 0
	ply.CurrentRecord = 0
	
	ply:SetNWInt("BhopRank", ply.RankID)
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWFloat("BhopRec", ply.CurrentRecord)

	if IsValid(ply) and not ply:IsBot() then
		self:LoadPlayer(ply)
		Bot:TestFor()
	end
	
	SendGlobalMessage(MSG_ID["Connect"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply)
end

-- Gamemode Overrides
function GM:CanPlayerSuicide()
	return false
end

function GM:PlayerShouldTakeDamage()
	return false
end

function GM:GetFallDamage()
    return false
end

function GM:EntityTakeDamage(ent, dmginfo)
	if ent:IsPlayer() then return false end
	return self.BaseClass:EntityTakeDamage(ent, dmginfo)
end

function GM:PlayerCanPickupWeapon(ply, wep)
	if (wep:GetClass() == "weapon_physgun") then return false end
	return true
end

function GM:PlayerCanHearPlayersVoice()
	return true
end

function GM:ShouldCollide(a, b)
	return not a:IsPlayer() and not b:IsPlayer()
end

function GM:PlayerCanPickupWeapon(ply, wep)
	if ply.GunBlock then return false end
	if not ply:HasWeapon(wep:GetClass()) then
		timer.Simple(0.1, function() if ply and IsValid(ply) then ply:SetAmmo(999, wep:GetPrimaryAmmoType()) end end)
		return true
	else
		return false
	end
end

-----------------
-- SPECTATING --
-----------------

Spectator = {}
Spectator.Modes = {
	OBS_MODE_IN_EYE,
	OBS_MODE_CHASE,
	OBS_MODE_ROAMING
}

function GM:KeyPress(ply, key)
	if ply:Team() != TEAM_SPECTATOR then return end
	
	if not ply.SpectateID then ply.SpectateID = 1 end
	if not ply.SpectateType then ply.SpectateType = 1 end
	
	if key == IN_ATTACK then
		local ar = GetAlivePlayers()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID + 1
		Spectator:Mode(ply, true)
		Spectator:Change(ar, ply, true)
	elseif key == IN_ATTACK2 then
		local ar = GetAlivePlayers()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID - 1
		Spectator:Mode(ply, true)
		Spectator:Change(ar, ply, false)
	elseif key == IN_RELOAD then
		local ar = GetAlivePlayers()
		if #ar == 0 then
			ply.SpectateType = #Spectator.Modes
			Spectator:Mode(ply, true)
		else
			ply.SpectateType = ply.SpectateType + 1 > #Spectator.Modes and 1 or ply.SpectateType + 1
			Spectator:Mode(ply)
		end
	end
end

function Spectator:Change(ar, ply, forward)
	local previous = ply:GetObserverTarget()
	
	if #ar == 1 then
		ply.SpectateID = forward and ply.SpectateID - 1 or ply.SpectateID + 1
		return
	end
	
	if not ar[ply.SpectateID] then
		ply.SpectateID = forward and 1 or #ar
		if not ar[ply.SpectateID] then DoSpectate(ply) return end
	end
	
	ply:SpectateEntity(ar[ply.SpectateID])
	Spectator:Checks(ply, previous)
end

function Spectator:Mode(ply, cancel)
	if ply.SpectateType == #Spectator.Modes and not cancel then
		Spectator:End(ply)
	end
	
	ply:Spectate(Spectator.Modes[ply.SpectateType])
	ply:SendLua("SpecMode(" .. ply.SpectateType .. ")")
	
	if ply.SpectateType != #Spectator.Modes then
		Spectator:Checks(ply, previous)
	end
end

function Spectator:End(ply)
	if ply.SecretSpectator then return end
	local target = ply:GetObserverTarget()
	if not target or not IsValid(target) then return end
	Spectator:Notify(target, ply, true)
end

function Spectator:Checks(ply, previous)
	if ply.SecretSpectator then return end
	local current = ply:GetObserverTarget()
	if current and IsValid(current) then
		if current:IsBot() then
			Spectator:NotifyBot(ply)
		else
			Spectator:Notify(current, ply, false)
		end
	end
	
	if previous and IsValid(previous) and not previous:IsBot() then
		Spectator:Notify(previous, ply, true)
	end
end

function Spectator:Notify(target, ply, leave)
	if ply.SecretSpectator then return end
	if leave then
		SendData(target, DATA_ID["SpecView"], {false, ply:Name(), ply:UniqueID()})
		return
	else
		SendData(target, DATA_ID["SpecView"], {true, ply:Name(), ply:UniqueID()})
	end
	
	local SpectatorList = {}
	for k,v in pairs(player.GetHumans()) do
		if not v.Spectating then continue end
		local ob = v:GetObserverTarget()
		if ob and IsValid(ob) and ob == target then
			table.insert(SpectatorList, v:Name())
		end
	end
	if #SpectatorList == 0 then SpectatorList = nil end
	
	if target.InSpawn or not target.timer then
		SendData(ply, DATA_ID["SpecTime"], {false, false, (target.CurrentRecord and target.CurrentRecord > 0) and target.CurrentRecord or nil, CurTime(), SpectatorList})
	elseif not target.InSpawn and target.timer and target.timer > 0 then
		SendData(ply, DATA_ID["SpecTime"], {false, target.timer, (target.CurrentRecord and target.CurrentRecord > 0) and target.CurrentRecord or nil, CurTime(), SpectatorList})
	end
end

function Spectator:NotifyBot(ply)
	if not Bot.Data then return end
	
	local SpectatorList = {}
	for k,v in pairs(player.GetHumans()) do
		if not v.Spectating then continue end
		local ob = v:GetObserverTarget()
		if ob and IsValid(ob) and ob == Bot.Runner then
			table.insert(SpectatorList, v:Name())
		end
	end
	if #SpectatorList == 0 then SpectatorList = nil end
	
	SendData(ply, DATA_ID["SpecTime"], {true, tonumber(Bot.PlaybackStart), Bot.Data["Name"], tonumber(Bot.Data["Time"]), CurTime(), SpectatorList})
end

-------------------------------------
-- CALCULATION FUNCTIONS --
-------------------------------------

function ToVector(data)
	if not data or data == "" or #data == 0 then return nil end
	
	local v = string.Explode(",", data)
	if #v == 3 then
		return Vector(v[1], v[2], v[3])
	end
	
	return Vector(0, 0, 0)
end

function GetVectorString(vec, short)
	if short then
		return string.format("%.0f,%.0f,%.0f", vec.x, vec.y, vec.z)
	else
		return vec.x .. "," .. vec.y .. "," .. vec.z
	end
end

function ConvertTime(time)
	if time > 3600 then
		return string.format("%d:%.2d:%.2d.%.2d", math.floor(time / 3600), math.floor(time / 60 % 60), math.floor(time % 60), math.floor(time * 100 % 100))
	else
		return string.format("%.2d:%.2d.%.2d", math.floor(time / 60 % 60), math.floor(time % 60), math.floor(time * 100 % 100))
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