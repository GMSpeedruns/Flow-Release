util.AddNetworkString("bh_Records")
util.AddNetworkString("ld_Maps")

local mapsettings = {}

local function ToVector(str)
	local v = string.Explode(",",str)
	if(#v == 3) then
		return Vector(v[1],v[2],v[3])
	else
		return Vector(0,0,0)
	end
end

function GM:LoadMaps()
	local list = sql.Query("SELECT * FROM mapdata")
	for k,v in pairs(list) do
		mapsettings[v['name']] = {ToVector(v['spos1']),ToVector(v['spos2']),ToVector(v['epos1']),ToVector(v['epos2']),tonumber(v['points'])}
	end
end

function GM:GetMapList()
	local maps = {}
	for k,v in pairs(mapsettings) do
		table.insert(maps,k..".bsp")
	end
	table.sort(maps)
	return maps
end

function GM:GetMapListP()
	local maps = {}
	for k,v in pairs(mapsettings) do
		table.insert(maps,k)
	end
	table.sort(maps)

	local list = {}
	for k,v in pairs(maps) do
		table.insert(list,{v,mapsettings[v][5]})
	end
	return list
end

local curmapsettings = {}

local maprec = {}
local maprec2 = {}
local maprec3 = {}
local worldrec = {}

local function MakeBox(tab,col)
		local c1 = Vector(tab[1].x,tab[1].y,tab[1].z+2)
		local c2 = Vector(tab[1].x,tab[2].y,tab[1].z+2)
		local c3 = Vector(tab[2].x,tab[2].y,tab[1].z+2)
		local c4 = Vector(tab[2].x,tab[1].y,tab[1].z+2)
		
		local c1e = ents.Create("info_target")
		c1e:SetPos(c1)
		c1e:SetName("bhcorner1gg"..tostring(c1.x)..tostring(c1.y))
		c1e:Spawn()
		
		local c2e = ents.Create("info_target")
		c2e:SetPos(c2)
		c2e:SetName("bhcorner2gg"..tostring(c1.x)..tostring(c1.y))
		c2e:Spawn()
		
		local c3e = ents.Create("info_target")
		c3e:SetPos(c3)
		c3e:SetName("bhcorner3gg"..tostring(c1.x)..tostring(c1.y))
		c3e:Spawn()
		
		local c4e = ents.Create("info_target")
		c4e:SetPos(c4)
		c4e:SetName("bhcorner4gg"..tostring(c1.x)..tostring(c1.y))
		c4e:Spawn()
		
		local p = c1+c2
		local b = ents.Create("env_beam")
		b:SetPos(p/2)
		b:SetKeyValue( "spawnflags", "1" )
		b:SetKeyValue( "rendercolor", col)
		b:SetKeyValue( "TextureScroll", "1" )
		b:SetKeyValue( "damage", "0" )
		b:SetKeyValue( "renderfx", "0" )
		b:SetKeyValue( "NoiseAmplitude", "1" )
		b:SetKeyValue( "BoltWidth", "1" )
		b:SetKeyValue( "TouchType", "0" )
		b:SetKeyValue("LightningStart",c1e:GetName())
		b:SetKeyValue("LightningEnd",c2e:GetName())
		b:SetKeyValue( "texture", "sprites/laserbeam.spr" )
		b:SetKeyValue("life","0")
		b:Spawn()
		b:Activate()
		
		p = nil --I wanna avoid that vector reference shit that happens and screws up my code O.O
		p = c2+c3
		b = ents.Create("env_beam")
		b:SetPos(p/2)
		b:SetKeyValue( "spawnflags", "1" )
		b:SetKeyValue( "rendercolor", col)
		b:SetKeyValue( "TextureScroll", "1" )
		b:SetKeyValue( "damage", "0" )
		b:SetKeyValue( "renderfx", "0" )
		b:SetKeyValue( "NoiseAmplitude", "1" )
		b:SetKeyValue( "BoltWidth", "1" )
		b:SetKeyValue( "TouchType", "0" )
		b:SetKeyValue("LightningStart",c2e:GetName())
		b:SetKeyValue("LightningEnd",c3e:GetName())
		b:SetKeyValue( "texture", "sprites/laserbeam.spr" )
		b:SetKeyValue("life","0")
		b:Spawn()
		b:Activate()
		
		p = nil --I wanna avoid that vector reference shit that happens and screws up my code O.O
		p = c3+c4
		b = ents.Create("env_beam")
		b:SetPos(p/2)
		b:SetKeyValue( "spawnflags", "1" )
		b:SetKeyValue( "rendercolor", col)
		b:SetKeyValue( "TextureScroll", "1" )
		b:SetKeyValue( "damage", "0" )
		b:SetKeyValue( "renderfx", "0" )
		b:SetKeyValue( "NoiseAmplitude", "1" )
		b:SetKeyValue( "BoltWidth", "1" )
		b:SetKeyValue( "TouchType", "0" )
		b:SetKeyValue("LightningStart",c3e:GetName())
		b:SetKeyValue("LightningEnd",c4e:GetName())
		b:SetKeyValue( "texture", "sprites/laserbeam.spr" )
		b:SetKeyValue("life","0")
		b:Spawn()
		b:Activate()
		
		p = nil --I wanna avoid that vector reference shit that happens and screws up my code O.O
		p = c4+c1
		b = ents.Create("env_beam")
		b:SetPos(p/2)
		b:SetKeyValue( "spawnflags", "1" )
		b:SetKeyValue( "rendercolor", col)
		b:SetKeyValue( "TextureScroll", "1" )
		b:SetKeyValue( "damage", "0" )
		b:SetKeyValue( "renderfx", "0" )
		b:SetKeyValue( "NoiseAmplitude", "1" )
		b:SetKeyValue( "BoltWidth", "1" )
		b:SetKeyValue( "TouchType", "0" )
		b:SetKeyValue("LightningStart",c4e:GetName())
		b:SetKeyValue("LightningEnd",c1e:GetName())
		b:SetKeyValue( "texture", "sprites/laserbeam.spr" )
		b:SetKeyValue("life","0")
		b:Spawn()
		b:Activate()
end

local function GetTime(time)
	local t = string.FormattedTime( time )
	local sec = "00"
	if(t.h > 0) then
		t.m = t.m + (60*t.h)
	end
	if(t.s < 10) then
		sec = "0"..tostring(t.s)
	else
		sec = tostring(t.s)
	end
	return tostring(t.m)..":"..sec
end

function GM:MakeBoxes()
	if(curmapsettings && curmapsettings[1]) then
		local c = curmapsettings
		local s = {c[1],c[2]}
		MakeBox(s,"72 102 72")
		local tend = {curmapsettings[3],curmapsettings[4]}
		MakeBox(tend,"102 72 72")
	end
	timer.Simple(10,function() SetGlobalString("WRBN", GetTime(maprec[1]['time']).." - "..maprec[1]['name']) end)
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

function GM:GetPoints(id)
	local data = sql.Query("SELECT map_name FROM playerrecords WHERE `unique_id` = '" .. id .. "'")
	local points = 0
	if (data) then
		for k,v in pairs(data) do
			points = points + tonumber(mapsettings[v['map_name']][5])
		end
	end
	return points
end

function GM:FinishMap(ply,time)
	local cur = ply.currecord
	if(!ply.gotpoints) then
		ply.gotpoints = true
		local cr = math.floor(curmapsettings[5]/2)
		ply:SetCredits(ply.Credits + cr)
		ply:StoreNotify("You have been given "..cr.." credits for beating this map. Type !store to access the store.")
	end
	if((tonumber(cur) == 0) or (time < tonumber(cur))) then
		local checkrec = sql.Query("SELECT * FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `unique_id`='"..ply:UniqueID().."'")
		if(!checkrec) then
			local left = {1,2,3}
			table.remove(left, ply.bhmde)
			sql.Query("INSERT INTO playerrecords (`unique_id`,`name`,`map_name`,`time"..ply.bhmde.."`,`time"..left[1].."`,`time"..left[2].."`) VALUES ('"..ply:UniqueID().."',"..sql.SQLStr(ply:Nick())..",'"..game.GetMap().."','"..time.."',0,0)")
			ply.brankp = self:GetPoints(ply:UniqueID())
			local nr = PointsToRank(ply.brankp)
			if(nr != ply.brank) then
				ply.brank = nr
				ply:SetNWInt("MyRank",nr)
			end
		else
			sql.Query("UPDATE playerrecords SET `time"..ply.bhmde.."`='"..time.."', `name`="..sql.SQLStr(ply:Nick()).." WHERE `unique_id`='"..ply:UniqueID().."' AND `map_name`='"..game.GetMap().."'")
		end

		local newrecs = sql.Query("SELECT `unique_id`,`time"..ply.bhmde.."` AS time,`name` FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `time"..ply.bhmde.."`!='0' ORDER BY `time"..ply.bhmde.."` LIMIT 10")
		-- This selects the latest top 10 times, AFTER the new time has been inserted. So it MIGHT be in the WR list
		
		local mrec = nil
		
		if(ply.bhmde == 1) then
			mrec = maprec
		elseif(ply.bhmde == 2) then
			mrec = maprec2
		else
			mrec = maprec3
		end
		
		local mrecl = 0
		for _,data in pairs(mrec) do
			mrecl = mrecl + tonumber(data['time'])
		end
		
		local nrecl = 0
		for _,data in pairs(newrecs) do
			nrecl = nrecl + tonumber(data['time'])
		end
		
		-- mrec is the table containing the pre-loaded data, depending on the mode
		ply.currecord = time
		
		if (mrecl == nrecl) then
			ply:SendLua("PersRec("..time..","..cur..")")
			ply:SetNWInt("SBRC",time)
		else
			if(#newrecs != 10) then
				local n = 10 - #newrecs
				for i=1,n do
					table.insert(newrecs,{['name'] = "blank",['time'] = "0",['unique_id'] = "1"})
				end
			end

			net.Start("bh_Records")
			net.WriteInt(ply.bhmde, 10)
			net.WriteTable(newrecs)
			net.Broadcast()
			
			if(ply.bhmde == 1) then
				maprec = newrecs
			elseif(ply.bhmde == 2) then
				maprec2 = newrecs
			else
				maprec3 = newrecs
			end
			
			local pos = "0"
			for k,v in pairs(newrecs) do
				if(tostring(v['unique_id']) == tostring(ply:UniqueID())) then
					pos = tostring(k)
				end
			end
			
			if(pos == "0") then
				ply:SendLua("PersRec("..time..","..cur..")")
				ply:SetNWInt("SBRC",time)
				return
			end
			
			if(ply.RecordMe && (pos == "1" || pos == 1) && ply.bhmde == 1) then
				SetGlobalString("WRBN", GetTime(time).." - "..ply:Nick())
				local sb = false
				local q = {}
				if(ply.Q1) then
					q[1] = ply.Q1
				end
				if(ply.Q2) then
					q[2] = ply.Q2
				end
				if(ply.Q3) then
					q[3] = ply.Q3
				end
				if(ply.Q4) then
					q[4] = ply.Q4
				end
				if(!self.WRBot) then
					sb = true
				end
				self.WRFrames = ply.Frames
				self.WR1 = nil
				self.WR1 = {}
				self.WR2 = nil
				self.WR2 = {}
				self.WR3 = nil
				self.WR3 = {}
				self.WR4 = nil
				self.WR4 = {}
				for k,v in pairs(q[1]) do
					local tab = string.Explode(";",v)
					for _,l in pairs(tab) do
						if(l != "") then
							table.insert(self.WR1,l)
						end
					end
				end
				if(q[2] && type(q[2]) == "table") then
					for k,v in pairs(q[2]) do
						local tab = string.Explode(";",v)
						for _,l in pairs(tab) do
							if(l != "") then
								table.insert(self.WR2,l)
							end
						end
					end
				end
				if(q[3] && type(q[3]) == "table") then
					for k,v in pairs(q[3]) do
						local tab = string.Explode(";",v)
						for _,l in pairs(tab) do
							if(l != "") then
								table.insert(self.WR3,l)
							end
						end
					end
				end
				if(q[4] && type(q[4]) == "table") then
					for k,v in pairs(q[4]) do
						local tab = string.Explode(";",v)
						for _,l in pairs(tab) do
							if(l != "") then
								table.insert(self.WR4,l)
							end
						end
					end
				end
				self.NewWR = true
				file.Write("botfiles/"..game.GetMap().."_1.txt", "THISISABOTFILE\n")
				local write = util.TableToJSON(self.WR1)
				write = util.Compress(write)
				file.Append("botfiles/"..game.GetMap().."_1.txt",write)
				if(#self.WR2 > 0) then
					file.Write("botfiles/"..game.GetMap().."_2.txt", "THISISABOTFILE\n")
					local write2 = util.TableToJSON(self.WR2)
					write2 = util.Compress(write2)
					file.Append("botfiles/"..game.GetMap().."_2.txt",write2)
				end
				if(#self.WR3 > 0) then
					file.Write("botfiles/"..game.GetMap().."_3.txt", "THISISABOTFILE\n")
					local write2 = util.TableToJSON(self.WR3)
					write2 = util.Compress(write2)
					file.Append("botfiles/"..game.GetMap().."_3.txt",write2)
				end
				if(#self.WR4 > 0) then
					file.Write("botfiles/"..game.GetMap().."_4.txt", "THISISABOTFILE\n")
					local write2 = util.TableToJSON(self.WR4)
					write2 = util.Compress(write2)
					file.Append("botfiles/"..game.GetMap().."_4.txt",write2)
				end
				
				self:SpawnBot()
			end
			
			ply.Frames = 1
			ply.Q1 = nil
			ply.Q2 = nil
			ply.Q3 = nil
			ply.Q4 = nil
			ply.Secs = 1
			
			ply:SendLua("GotRec("..time..","..cur..","..pos..")")
			ply:SetNWInt("SBRC",time)
		end
	end
end

function GM:ReadWRRun()
	self.WRFrames = 0
	if(file.Exists("botfiles/"..game.GetMap().."_1.txt","DATA")) then
		local str = file.Read("botfiles/"..game.GetMap().."_1.txt","DATA")
		str = string.gsub(str,"THISISABOTFILE\n","")
		str = util.Decompress(str)
		str = util.JSONToTable(str)
		self.WR1 = str
		self.WRFrames = self.WRFrames + #self.WR1
	end
	if(file.Exists("botfiles/"..game.GetMap().."_2.txt","DATA")) then
		local str = file.Read("botfiles/"..game.GetMap().."_2.txt","DATA")
		str = string.gsub(str,"THISISABOTFILE\n","")
		str = util.Decompress(str)
		str = util.JSONToTable(str)
		self.WR2 = str
		self.WRFrames = self.WRFrames + #self.WR2
	end
	if(file.Exists("botfiles/"..game.GetMap().."_3.txt","DATA")) then
		local str = file.Read("botfiles/"..game.GetMap().."_3.txt","DATA")
		str = string.gsub(str,"THISISABOTFILE\n","")
		str = util.Decompress(str)
		str = util.JSONToTable(str)
		self.WR3 = str
		self.WRFrames = self.WRFrames + #self.WR3
	end
	if(file.Exists("botfiles/"..game.GetMap().."_4.txt","DATA")) then
		local str = file.Read("botfiles/"..game.GetMap().."_4.txt","DATA")
		str = string.Replace(str,"THISISABOTFILE\n","")
		str = util.Decompress(str)
		str = util.JSONToTable(str)
		self.WR4 = str
		self.WRFrames = self.WRFrames + #self.WR4
	end
	if(self.WR1) then
		self:SpawnBot()
	end
end

function GM:SpawnBot()
	for k,v in pairs(player.GetAll()) do
		if(v:IsBot()) then
			self.WRBot = v
			if(v:GetMoveType() != 0) then
				v:SetMoveType(0)
				v:SetCollisionGroup(10)
			end
		end
	end
	if(self.WRBot) then return end
	RunConsoleCommand("bot")
	timer.Simple(0.5,function()
		for k,v in pairs(player.GetAll()) do
			if(v:IsBot()) then
				self.WRBot = v
				if(v:GetMoveType() != 0) then
					v:SetMoveType(0)
					v:SetCollisionGroup(10)
				end
			end
		end
	end)
end

hook.Add("CheckPassword", "CheckPassword_wrbot", function( comID, ipPort, serverPassword, userPassword, name )
	local num = #player.GetAll()
	if(GAMEMODE.WRBot && GAMEMODE.WRBot:IsValid()) then
		num = num - 1
	end
	if(num >= 24) then
		return false, "Server is full."
	end
end)

local function ParseRecords(mrec)
	local rec = mrec
	if(!rec) then
		rec = {
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"},
			{['name'] = "blank",['time'] = "0",['unique_id'] = "1"}
		}
	elseif(#rec != 10) then
		local n = 10 - #rec
		for i=1,n do
			table.insert(rec,{['name'] = "blank",['time'] = "0",['unique_id'] = "1"})
		end
	end
	return rec
end

function GM:LoadTop10()
	maprec = sql.Query("SELECT `unique_id`,`time1` AS time,`name` FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `time1`!='0' ORDER BY `time1` LIMIT 10")
	maprec = ParseRecords(maprec)
	maprec2 = sql.Query("SELECT `unique_id`,`time2` AS time,`name` FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `time2`!='0' ORDER BY `time2` LIMIT 10")
	maprec2 = ParseRecords(maprec2)
	maprec3 = sql.Query("SELECT `unique_id`,`time3` AS time,`name` FROM playerrecords WHERE `map_name`='"..game.GetMap().."' AND `time3`!='0' ORDER BY `time3` LIMIT 10")
	maprec3 = ParseRecords(maprec3)
	worldrec = sql.Query("SELECT SUM(A.points) AS `rec_points`, B.name AS `rec_name` FROM mapdata AS A JOIN playerrecords AS B ON B.map_name = A.name GROUP BY B.unique_id ORDER BY `rec_points` DESC LIMIT 10")
end

local first = false

function GM:SendRecs(ply)
	net.Start("bh_Records")
	net.WriteInt(1,10)
	net.WriteTable(maprec)
	net.Send(ply)
	net.Start("bh_Records")
	net.WriteInt(2,10)
	net.WriteTable(maprec2)
	net.Send(ply)
	net.Start("bh_Records")
	net.WriteInt(3,10)
	net.WriteTable(maprec3)
	net.Send(ply)
end

function GM:PrecacheSettings(map)
	curmapsettings = mapsettings[map]
end

local function IsInArea(ent,vec,vec2)
	local vec3 = ent:GetPos()
	if((vec3.x > vec.x && vec3.x < vec2.x) && (vec3.y > vec.y && vec3.y < vec2.y) && (vec3.z > vec.z && vec3.z < vec2.z)) then
		return true
	else
		return false
	end
end

local function StartZoneHit(ply)
	if(ply.jump && GAMEMODE:IsInStart(ply)) then
		ply.jump1 = true
		timer.Simple(0.1,function() if(ply && ply:IsValid()) then ply.jump1 = false end end)
	end
	ply.jump = false
end
hook.Add("OnPlayerHitGround","StartZoneHit",StartZoneHit)

hook.Add("Think","SpeedySpeedy",function()
	for k,v in pairs(player.GetAll()) do
		if(v:OnGround() && GAMEMODE:IsInStart(v) && v.sp && v.sp > 300 && !v.Speed) then
			chat.AddText(v,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You cannot have a high speed within the starting area!")
			v.Speed = true
			timer.Simple(0.05,function() if(v && v:IsValid()) then 
				v:SetPos(v:GetPos() + Vector(0,0,8))
				v:SetLocalVelocity(Vector(0,0,-100)) 
			end end)
			timer.Simple(0.1,function() if(v && v:IsValid()) then 
				v:SetPos(v:GetPos() + Vector(0,0,8))
				v:SetLocalVelocity(Vector(0,0,-100)) 
			end end)
			timer.Simple(0.15,function() if(v && v:IsValid()) then 
				v:SetPos(v:GetPos() + Vector(0,0,8))
				v:SetLocalVelocity(Vector(0,0,-100)) 
			end end)
			timer.Simple(0.2,function() if(v && v:IsValid()) then 
				v.Speed = false
			end end)
		end
	end
end)

local function StartZoneJump(ply,key)
	if not IsFirstTimePredicted() then return end
	if not IsValid(ply) then return end

	if key == IN_JUMP && ply:IsOnGround() then
		if(ply.jump1) then
			ply.jump1 = false
			chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You cannot prespeed in the starting area!")
			timer.Simple(0.1,function() if(ply && ply:IsValid()) then ply:SetLocalVelocity(Vector(0,0,-100)) end end)
		else
			ply.jump = true
		end
	end
end
hook.Add("KeyPress","StartZoneJump",StartZoneJump)

local function ProcessCommand( ply, text )
	local small = string.lower( text )
	if small == "!rank" or small == "!points" then
		local currentRank = GAMEMODE.RankList[ply.brank]
		chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You are currently [", currentRank[2], currentRank[1], Color(255,255,255), "] with "..ply.brankp.. " points!")
		if ply.brank < 36 then
			chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] The next rank(s):")
		
			local u = ply.brank + 5
			if u > 36 then u = 36 end
			for i = ply.brank, u do
				chat.AddText(ply,Color(255,255,255),"[",GAMEMODE.RankList[i][2],GAMEMODE.RankList[i][1],Color(255,255,255),"] " .. tostring(GAMEMODE.RankList[i][3]) .. " points")
			end
		end
		
		return ""
	elseif string.sub(small, 1, 8) == "!points " then
		local TargetMap = string.sub(small, 9)
		
		if mapsettings[TargetMap] then
			chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] The map '" .. TargetMap .. "' is worth " .. tostring(mapsettings[TargetMap][5]) .. " points.")
		else
			chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] Please ensure you have entered a valid map name.")
		end
		
		return ""
	elseif small == "!mapsbeat" then
		if not ply.hasReceivedMaps then
			local timeData = sql.Query("SELECT `map_name`, `time" .. ply.bhmde .. "` AS `time` FROM `playerrecords` WHERE `unique_id`='" .. ply:UniqueID() .. "' ORDER BY `map_name` ASC")
			if not timeData then timeData = {} end
		
			net.Start("ld_Maps")
			net.WriteTable(timeData)
			net.Send(ply)
	
			ply.hasReceivedMaps = true
		end
		
		umsg.Start( "LMapsBeat", ply )
		umsg.End()
		
		return ""
	elseif small == "!mapsleft" then
		if not ply.hasReceivedMaps then
			local timeData = sql.Query("SELECT `map_name`, `time" .. ply.bhmde .. "` AS `time` FROM `playerrecords` WHERE `unique_id`='" .. ply:UniqueID() .. "' ORDER BY `map_name` ASC")
			if not timeData then timeData = {} end
		
			net.Start("ld_Maps")
			net.WriteTable(timeData)
			net.Send(ply)
	
			ply.hasReceivedMaps = true
		end	

		umsg.Start( "LMapsLeft", ply )
		umsg.End()
	
		return ""
	elseif small == "!top" or small == "!toplist" then
		umsg.Start( "LTopList", ply )
		
		if not ply.hasReceivedToplist then
			umsg.Char(1)
			for k,v in pairs(worldrec) do
				umsg.Long(tonumber(v['rec_points']))
				umsg.String(v['rec_name'])
			end
			
			ply.hasReceivedToplist = true
		else
			umsg.Char(0)
		end

		umsg.End()
		
		return ""
	elseif small == "!help" then
		local helpData = {
			"!motd: Show pG's MOTD",
			"/r or /restart: Reset your position to the start",
			"!wr: Shows the world records for this map",
			"!nominate: Select a map to be added to the list of next possible maps",
			"!timeleft: View how many minutes are left before the map changes",
			"!rtv: 'Rock The Vote'; vote to change maps",
			"!top or !toplist: Shows the top players of our server",
			"!rank or !points: Shows your rank and the coming ranks",
			"!points [map]: Shows how many points a map is worth. Example: !points bhop_eazy_v2",
			"!mapsbeat: Shows the maps you have beaten",
			"!mapsleft: Shows the maps you still need to beat"
		}
		
		chat.AddText(ply,Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] Press F1 for more data. Below are all possible commands:")
		for k,v in pairs(helpData) do
			chat.AddText(ply,Color(255,255,255),"[",Color(74,136,242),"COMMAND",Color(255,255,255),"] " .. v)
		end
		
		return ""
	elseif small == "!admincp" then
		if ply:UniqueID() == "3974409736" then
			umsg.Start( "CP_Show", ply )
			umsg.String( tostring(ply:UniqueID()) )
			umsg.End()
		
			return ""
		end		
	end
end
hook.Add( "PlayerSay", "CMD_PlayerSay", ProcessCommand )

function GM:IsStarter(ply)
	if(ply:Team() == TEAM_SPECTATOR) then return false end
	if(ply:IsOnGround() && curmapsettings && curmapsettings[1]) then
		if(IsInArea(ply,curmapsettings[1],curmapsettings[2])) then
			return true
		else
			return false
		end
	end
end

function GM:IsInStart(ply)
	if(ply:Team() == TEAM_SPECTATOR) then return false end
	if(curmapsettings && curmapsettings[1]) then
		if(IsInArea(ply,curmapsettings[1],curmapsettings[2])) then
			return true
		else
			return false
		end
	end
end

function GM:ShouldStart(ply)
	if(ply:Team() == TEAM_SPECTATOR) then return false end
	if(curmapsettings && curmapsettings[1]) then
		if(IsInArea(ply,curmapsettings[1],curmapsettings[2])) then
			return false
		else
			return true
		end
	end
end

function GM:InRecordArea(ply)
	if(ply:Team() == TEAM_SPECTATOR) then return false end
	if(curmapsettings && curmapsettings[3]) then
		if(IsInArea(ply,curmapsettings[3],curmapsettings[4])) then
			return true
		else
			return false
		end
	end
end