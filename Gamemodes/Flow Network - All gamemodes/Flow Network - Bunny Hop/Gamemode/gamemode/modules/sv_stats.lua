-- Initial stats developed by George
-- Improved by Gravious
-- Okay screw you George, this code is so messy I've given up on improving it...
-- NOT Improved by Gravious, merely edited the displaying part

Stats = {}

local JUMP_LJ = 1
local JUMP_DROP = 2
local JUMP_UP = 3
local JUMP_LADDER = 4
local JUMP_WJ = 5

local MAX_STRAFES = 50

local jumptypes = {}
jumptypes[JUMP_LJ] = "Long Jump"
jumptypes[JUMP_DROP] = "Drop Jump"
jumptypes[JUMP_UP] = "Up Jump"
jumptypes[JUMP_LADDER] = "Ladder Jump"
jumptypes[JUMP_WJ] = "Weird Jump"

local jumpdist = {}
jumpdist[JUMP_LJ] = 230
jumpdist[JUMP_DROP] = 235
jumpdist[JUMP_UP] = 130
jumpdist[JUMP_LADDER] = 110
jumpdist[JUMP_WJ] = 255

local wj = {}
local inbhop = {}
local strafes = {}
local ducking = {}
local lastducking = {}
local didjump = {}
local strafenum = {}
local strafingright = {}
local strafingleft = {}
local speed = {}
local lastspeed = {}
local newp = {}
local oldp = {}
local lastent = {}
local lastonground = {}
local jumpproblem = {}
local jumppos = {}
local jumpvel = {}
local tproblem = {}
local jumptype = {}
local ladder = {}
local strafe = {}

local ba = bit.band

function Stats:ToggleStatus( ply )
	if ply.ljen then
		ply.ljen = false
	else
		ply.ljen = true
	end
	
	Core:Send( ply, "Print", { "Bhop Timer", "LJ Stats are now " .. (ply.ljen and "enabled" or "disabled") } )
end

local function Stats_MoveCheck( p, data )
	if(!p.ljen) then return end
	local b = data:GetButtons()
	if(!p:IsOnGround() && didjump[p] && !inbhop[p]) then
		if(p:Crouching()) then
			ducking[p] = true
		end
		local dontrun = false
		if(!strafe[p]) then
			strafe[p] = {}
		end
		
		local c = 0
		if(ba(b,IN_MOVELEFT)>0) then
			c = c + 1
		end
		if(ba(b,IN_MOVERIGHT)>0) then
			c = c + 1
		end

		if(c == 1 && ((strafenum[p] && strafenum[p] < MAX_STRAFES) || !strafenum[p])) then
			if(strafenum[p] && (ba(b,IN_MOVELEFT)>0) && (strafingright[p] || (!strafingright[p] && !strafingleft[p]))) then
				strafingright[p] = false
				strafingleft[p] = true
				strafenum[p] = strafenum[p] + 1
				strafe[p][strafenum[p]] = {}
				strafe[p][strafenum[p]][1] = 0
				strafe[p][strafenum[p]][2] = 0
			elseif(strafenum[p] && (ba(b,IN_MOVERIGHT)>0) && (strafingleft[p] || (!strafingright[p] && !strafingleft[p]))) then
				strafingright[p] = true
				strafingleft[p] = false
				strafenum[p] = strafenum[p] + 1
				strafe[p][strafenum[p]] = {}
				strafe[p][strafenum[p]][1] = 0
				strafe[p][strafenum[p]][2] = 0
			end
		elseif(strafenum[p] && strafenum[p] == 0) then
			dontrun = true
		end
		if(!strafenum[p]) then
			dontrun = true
		end
		if(!dontrun) then
			speed[p] = data:GetVelocity()
			newp[p] = data:GetOrigin()
			if(lastspeed[p]) then
				local g = (speed[p]:Length2D()) - (lastspeed[p]:Length2D())
				if(g > 0) then
					strafe[p][strafenum[p]][1] = strafe[p][strafenum[p]][1] + 1
				else
					strafe[p][strafenum[p]][2] = strafe[p][strafenum[p]][2] + 1
				end
				strafe[p][strafenum[p]][3] = speed[p]
				local cp = newp[p]
				local op = oldp[p]
				if(lastducking[p] && !p:Crouching()) then
					op.z = op.z - 8.5
				elseif(!lastducking[p] && p:Crouching()) then
					cp.z = cp.z - 8.5
				end
				if(p:Crouching()) then
					lastducking[p] = true
				else
					lastducking[p] = false
				end
				if((cp - op):Length2D() > (lastspeed[p]:Length2D() / 100 + 3)) then
					tproblem[p] = true
				end
			end
			oldp[p] = newp[p]
			lastspeed[p] = speed[p]
		elseif(strafenum[p] && strafenum[p] != 0) then
			strafe[p][strafenum[p]][2] = strafe[p][strafenum[p]][2] + 1
		end
	end
	if(p:GetMoveType() == MOVETYPE_LADDER) then
		jumptype[p] = JUMP_LADDER
		ladder[p] = true
	else
		if(ladder[p]) then
			ladder[p] = false
			didjump[p] = true
			inbhop[p] = false
			jumppos[p] = data:GetOrigin()
			timer.Simple(0.2,function()
				jumpproblem[p] = false
				lastent[p] = nil
			end)
		end
		
	end
	if(p:IsOnGround() && !lastonground[p]) then
		Stats:OnLand(p,data:GetOrigin())
	end
	if(p:IsOnGround()) then
		lastonground[p] = true
	else
		lastonground[p] = false
	end
	if(ba(b,IN_JUMP)>0 && p:IsOnGround()) then
		if(wj[p]) then
			jumptype[p] = JUMP_WJ
			inbhop[p] = false
		end
		local function ljr1()
			if not IsValid(p) or not didjump or not lastent then return end
			didjump[p] = true
			lastent[p] = nil
		end
		timer.Simple(0.2,ljr1)
		jumppos[p] = data:GetOrigin()
		jumpvel[p] = data:GetVelocity():Length2D()
	end
end
hook.Add("SetupMove","LJStats",Stats_MoveCheck)

local function Stats_CollideCheck( ent1,ent2 )
	if not IsValid( ent1 ) or not IsValid( ent2 ) then return false end
	if(ent1:IsPlayer() && ent2:IsPlayer()) then return false end
	local p = nil
	local o = nil
	if(ent1:IsPlayer()) then
		p = ent1
		o = ent2
	else
		p = ent2
		o = ent1
	end
	if(!p.ljen) then return end
	if(didjump[p] && o != lastent[p]) then
		local function ljr2()
			if not IsValid(p) or not inbhop or not didjump or not jumpproblem or not p.GetPos or not util or not util.QuickTrace then return end
			if(!p:IsOnGround() && !inbhop[p] && didjump[p]) then
				local t = util.QuickTrace(p:GetPos()+Vector(0,0,2),Vector(0,0,-34),{p})
				if(!t.Hit) then
					jumpproblem[p] = true
				elseif(t.HitPos) then
					if(p:GetPos().z-t.HitPos.z<=0.2) then
						jumpproblem[p] = true
					end
				end
			end
		end
		timer.Simple(1,ljr2)
	end
	lastent[p] = o
end
hook.Add("ShouldCollide","LJWorldCollide",Stats_CollideCheck)

function Stats:OnLand(p,jpos)
	local good = 0
	local bad = 0
	local sync = 0
	local i = 0
	local totalstats = {}
	totalstats["sync"] = {}
	totalstats["speed"] = {}
	
	for k,v in pairs(strafe[p] or {}) do
		if(type(v) == "table") then
			local sync = math.Round((v[1]*100)/(v[1]+v[2]))
			if(sync && sync != 0 && sync <= 100) then
				i = i + 1
				totalstats["sync"][i] = sync
				totalstats["speed"][i] = math.Round((v[3] or Vector(0,0,0)):Length2D())
				good = good + v[1]
				bad = bad + v[2]
			end
		end
	end
	
	local straf = strafenum[p]
	local validlj = false
	local jt = jumptype[p]
	local dist = 0
	
	if(jumppos[p]) then
		
		local cz = jpos.z
		if(cz-jumppos[p].z > -1 && cz-jumppos[p].z < 1) then
			cz = jumppos[p].z
		end
		if(jt && jt != JUMP_WJ && cz < jumppos[p].z) then
			if(jt != JUMP_LADDER) then
				jt = JUMP_DROP
				validlj = true
			else
				validlj = true
				if(jumppos[p].z - cz > 20) then
					validlj = false
				end
			end
		elseif(jt && jt != JUMP_WJ && cz > jumppos[p].z) then
			if(jt != JUMP_LADDER) then
				jt = JUMP_UP
				validlj = true
			else
				validlj = true
				if(jumppos[p].z - cz < -20) then
					validlj = false
				end
			end
		elseif(jt) then
			if(jt == JUMP_WJ && cz == jumppos[p].z) then
				validlj = true
			elseif(jt != JUMP_WJ) then
				validlj = true
			end
		end
		dist = (jpos-jumppos[p]):Length2D()
		if(jt != JUMP_LADDER) then
			dist = dist + 30
		end
	end
	
	local dj = didjump[p]
	
	if(jumpproblem[p] || tproblem[p]) then
		validlj = false
	end
	
	local function ljr3()
		if(IsValid(p) && p:IsOnGround() && inbhop && jt) then
			inbhop[p] = false
			if((jt == JUMP_WJ || dj) && straf && straf != 0 && dist && dist > jumpdist[jt] && jt && validlj && good && bad && totalstats) then
				sync = good / (good + bad)
				if jt == JUMP_LADDER then jumpvel[ p ] = 0 end
				
				local viewers = p.Watchers or {}
				table.insert( viewers, p )
				Core:Send( viewers, "Timer", { "Stats", {
					Title = jumptypes[ jt ],
					Distance = math.Round( dist ),
					Prestrafe = math.Round( jumpvel[ p ] ),
					Sync = math.Round( sync * 100 ),
					SpeedValues = totalstats.speed,
					SyncValues = totalstats.sync
				} } )
			end
		end
	end
	timer.Simple(0.3,ljr3)
	
	inbhop[p] = true
	strafe[p] = {}
	strafenum[p] = 0
	jumppos[p] = nil
	strafingleft[p] = false
	strafingright[p] = false
	speed[p] = nil
	lastspeed[p] = nil
	jumpproblem[p] = false
	ducking[p] = false
	if(!didjump[p]) then
		wj[p] = true
		inbhop[p] = false
		timer.Simple(0.3,function() 
			if(IsValid(p)) then
				wj[p] = false
			end
		end)
	end
	jumptype[p] = JUMP_LJ
	oldp[p] = nil
	newp[p] = nil
	tproblem[p] = false
	didjump[p] = false
end

function Stats:EnablePlayer( p )
	p:SetCustomCollisionCheck(true)
end

function Stats:InitializePlayer( p )
	inbhop[p] = false
	strafe[p] = {}
	strafenum[p] = 0
	jumppos[p] = nil
	strafingleft[p] = false
	strafingright[p] = false
	speed[p] = nil
	lastspeed[p] = nil
	jumpproblem[p] = false
	ducking[p] = false
	jumptype[p] = JUMP_LJ
	oldp[p] = nil
	newp[p] = nil
	tproblem[p] = false
	didjump[p] = false
end