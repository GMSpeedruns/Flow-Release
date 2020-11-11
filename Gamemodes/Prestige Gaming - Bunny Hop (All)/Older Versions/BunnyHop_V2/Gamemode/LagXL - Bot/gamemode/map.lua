local SPECIAL_AREABLOCK = 1
local SPECIAL_AREATP = 2
local SPECIAL_SETAREATP = 3
local SPECIAL_ENTSPIKE = 4
local SPECIAL_GIVEWEAPON = 5
local SPECIAL_NORECORD = 6
local SPECIAL_STEPSIZE = 7
local SPECIAL_AREASTEPSIZE = 8
local SPECIAL_SPAWNPOINT = 9

local SPECIAL_CUSTOM_LW = 100
local SPECIAL_CUSTOM_EXQ = 101

MAP_STEPSIZE = nil
MAP_SPAWNPOINT = nil

AreaEnts = {["Start"] = nil, ["End"] = nil, ["Block"] = {}, ["Teleport"] = {}, ["Custom"] = {}}

function LoadMapTriggers()
	if not currentMapData then MsgN("No area positions found for map: " .. game.GetMap()) return end

	local startBottom = currentMapData[1] + Vector(0, 0, 2)
	local startTop = currentMapData[2] + Vector(0, 0, 2)
	local endBottom = currentMapData[3] + Vector(0, 0, 2)
	local endTop = currentMapData[4] + Vector(0, 0, 2)

	AreaEnts["Start"] = ents.Create("bhop_timer")
	AreaEnts["Start"]:SetPos((startBottom + startTop) / 2)
	AreaEnts["Start"].min = startBottom
	AreaEnts["Start"].max = startTop
	AreaEnts["Start"].areatype = AREA_START
	AreaEnts["Start"]:Spawn()
	
	AreaEnts["End"] = ents.Create("bhop_timer")
	AreaEnts["End"]:SetPos((endBottom + endTop) / 2)
	AreaEnts["End"].min = endBottom
	AreaEnts["End"].max = endTop
	AreaEnts["End"].areatype = AREA_FINISH
	AreaEnts["End"]:Spawn()
	
	local query = sql.Query("SELECT * FROM mapareas WHERE map_name = '" .. game.GetMap() .. "'")
	if query then
		for i,data in pairs(query) do
			local Type = tonumber(data["type"])

			if Type == SPECIAL_STEPSIZE then
				MAP_STEPSIZE = tonumber(data["data"])
			elseif Type == SPECIAL_AREABLOCK then
				local CSplit = string.Explode(";", data["data"])
				local areaBottom = ToVector(CSplit[1]) + Vector(0, 0, 2)
				local areaTop = ToVector(CSplit[2]) + Vector(0, 0, 2)
				local AreaID = #AreaEnts["Block"] + 1
				
				AreaEnts["Block"][AreaID] = ents.Create("bhop_timer")
				AreaEnts["Block"][AreaID]:SetPos((areaBottom + areaTop) / 2)
				AreaEnts["Block"][AreaID].min = areaBottom
				AreaEnts["Block"][AreaID].max = areaTop
				AreaEnts["Block"][AreaID].areatype = AREA_BLOCK
				AreaEnts["Block"][AreaID]:Spawn()
			elseif Type == SPECIAL_AREATP then
				local CSplit = string.Explode(";", data["data"])
				local areaBottom = ToVector(CSplit[1]) + Vector(0, 0, 2)
				local areaTop = ToVector(CSplit[2]) + Vector(0, 0, 2)
				local AreaID = #AreaEnts["Teleport"] + 1
				
				AreaEnts["Teleport"][AreaID] = ents.Create("bhop_timer")
				AreaEnts["Teleport"][AreaID]:SetPos((areaBottom + areaTop) / 2)
				AreaEnts["Teleport"][AreaID].min = areaBottom
				AreaEnts["Teleport"][AreaID].max = areaTop
				AreaEnts["Teleport"][AreaID].areatype = AREA_TELEPORT
				AreaEnts["Teleport"][AreaID].dest = ToVector(CSplit[3])
				AreaEnts["Teleport"][AreaID]:Spawn()
			elseif Type == SPECIAL_SETAREATP then
				local CSplit = string.Explode(";", data["data"])
				local PosInit = ToVector(CSplit[1])
				for k,v in pairs(ents.FindByClass("trigger_teleport")) do
					if v:GetPos() == PosInit then
						v:SetKeyValue("target", CSplit[2])
					end
				end
			elseif Type == SPECIAL_ENTSPIKE then
				local CSplit = string.Explode(";", data["data"])
				if #CSplit == 3 then
					local ent = ents.Create("bhop_spike")
					ent:SetPos(ToVector(CSplit[1]))
					ent.min = ToVector(CSplit[2])
					ent.max = ToVector(CSplit[3])
					ent:Spawn()
				elseif #CSplit == 2 then
					local v = {ToVector(CSplit[1]), ToVector(CSplit[2])}
					local x = (v[1].x + v[2].x) / 2
					local y = (v[1].y + v[2].y) / 2
					local z = (v[1].z + v[2].z) / 2
					local midpoint = Vector(x, y, z)
					x = v[2].x - x
					y = v[2].y - y
					z = v[2].z - z
					
					local ent = ents.Create("bhop_spike")
					ent:SetPos(midpoint)
					ent.max = Vector(x, y, z)
					ent.min = Vector(x * -1,y * -1,z * -1)
					ent:Spawn()
				end
			elseif Type == SPECIAL_NORECORD then
				if tonumber(data["data"]) == 1 then
					DisableRecording = true
				end
			elseif Type == SPECIAL_AREASTEPSIZE then
				local CSplit = string.Explode(";", data["data"])
				local areaBottom = ToVector(CSplit[1]) + Vector(0, 0, 2)
				local areaTop = ToVector(CSplit[2]) + Vector(0, 0, 2)
				local AreaID = #AreaEnts["Custom"] + 1
				
				AreaEnts["Custom"][AreaID] = ents.Create("bhop_timer")
				AreaEnts["Custom"][AreaID]:SetPos((areaBottom + areaTop) / 2)
				AreaEnts["Custom"][AreaID].min = areaBottom
				AreaEnts["Custom"][AreaID].max = areaTop
				AreaEnts["Custom"][AreaID].areatype = AREA_STEPSIZE
				AreaEnts["Custom"][AreaID].steps = {tonumber(CSplit[3]), tonumber(CSplit[4])} -- 3 = new, 4 = init
				AreaEnts["Custom"][AreaID]:Spawn()
			elseif Type == SPECIAL_SPAWNPOINT then
				MAP_SPAWNPOINT = ToVector(data["data"])
				
				if game.GetMap() == "bhop_catalyst" then
					for k,v in pairs(ents.FindByClass("info_player_terrorist")) do
						if table.HasValue({Vector(7156.240234, 704.713989, -7585), Vector(7130.129883, 702.512024, -7585), Vector(7102.5, 700.283997, -7585), Vector(7069.850098, 700.505005, -7585), Vector(7036.589844, 700.119019, -7585)}, v:GetPos()) then
							v:Remove()
						end
					end
				end
			elseif Type == SPECIAL_CUSTOM_LW then
				local push = nil
				for k,v in pairs(ents.FindByClass("trigger_push")) do
					if v:GetPos() == Vector(5864, 4808, -128) then
						push = v
					end
				end
				if push then
					push:SetKeyValue("spawnflags", "0")
					push:Spawn()
					
					local tmax = push:LocalToWorld(push:OBBMaxs())
					local tmin = push:LocalToWorld(push:OBBMins())
					
					local AreaID = #AreaEnts["Custom"] + 1
					AreaEnts["Custom"][AreaID] = ents.Create("bhop_timer")
					AreaEnts["Custom"][AreaID]:SetPos((tmin + tmax) / 2)
					AreaEnts["Custom"][AreaID].min = tmin
					AreaEnts["Custom"][AreaID].max = tmax
					AreaEnts["Custom"][AreaID].areatype = AREA_VELOCITY
					AreaEnts["Custom"][AreaID].velocity = Vector(0, 0, 60)
					AreaEnts["Custom"][AreaID]:Spawn()
				end
			elseif Type == SPECIAL_CUSTOM_EXQ then
				for k,v in pairs(ents.FindByClass("trigger_multiple")) do
					if v:GetPos() == Vector(3264, -704.02, -974.49) then
						v:Remove()
					end
				end
			end
		end
	end
	
	if not MAP_SPAWNPOINT then
		MAP_SPAWNPOINT = (startBottom + startTop) / 2
	end
end

function ExecMapChecks(map, ply)
	if ply && ply:IsValid() then
		if MAP_STEPSIZE then
			ply:SetStepSize(MAP_STEPSIZE)
		end
		if MAP_SPAWNPOINT then
			ply:SetPos(MAP_SPAWNPOINT)
		end
		return
	end

	sql.Query("UPDATE mapdata SET playcount = playcount + 1 WHERE name = '" .. game.GetMap() .. "'")
	if map == "bhop_eman_on" or map == "bhop_together" or map == "bhop_highfly" or map == "bhop_drop" then
		game.ConsoleCommand("sv_airaccelerate 1000\n")
	end
end

-- Multiplayer Bunny Hop Fixes
function GM:EntityKeyValue(ent, key, value) 
    if not GAMEMODE.BaseStoreOutput or not GAMEMODE.BaseTriggerOutput then
        local e = scripted_ents.Get("base_entity")
        GAMEMODE.BaseStoreOutput = e.StoreOutput
        GAMEMODE.BaseTriggerOutput = e.TriggerOutput
    end
 
    if key:lower():sub(1, 2) == "on" then
        if not ent.StoreOutput or not ent.TriggerOutput then
            ent.StoreOutput = GAMEMODE.BaseStoreOutput
            ent.TriggerOutput = GAMEMODE.BaseTriggerOutput
		end
        if ent.StoreOutput then
            ent:StoreOutput(key, value)
        end
    end
	
	if self.BaseClass.EntityKeyValue then
		self.BaseClass:EntityKeyValue(ent, key, value)
	end
end

function SetMapTriggers()
	if table.HasValue(LIST_NOMAPTRIGS, game.GetMap()) then return end

	for k,v in pairs(ents.FindByClass("func_door")) do
		if not v.IsP then continue end
		local mins = v:OBBMins()
		local maxs = v:OBBMaxs()
		local h = maxs.z - mins.z

		if h > 80 and not table.HasValue(LIST_DOORMAPS, game.GetMap()) then continue end
		local tab = ents.FindInBox(v:LocalToWorld(mins) - Vector(0,0,10), v:LocalToWorld(maxs) + Vector(0,0,5))
		if tab then
			local teleport = nil
			for _,v2 in pairs(tab) do
				if v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport" then 
					teleport = v2
				end
			end
			if teleport then
				v:Fire("Lock")
				v:SetKeyValue("spawnflags", "1024")
				v:SetKeyValue("speed", "0")
				v:SetRenderMode(RENDERMODE_TRANSALPHA)
				if v.BHS then
					v:SetKeyValue("locked_sound", v.BHS)
				else
					v:SetKeyValue("locked_sound", "DoorSound.DefaultMove")
				end
				v:SetNWInt("Platform", 1)
			end
		end
	end
	
	for k,v in pairs(ents.FindByClass("func_button")) do
		if not v.IsP then continue end
		if v.SpawnFlags == "256" then 
			local mins = v:OBBMins()
			local maxs = v:OBBMaxs()
			local tab = ents.FindInBox(v:LocalToWorld(mins) - Vector(0,0,10), v:LocalToWorld(maxs) + Vector(0,0,5))
			if tab then
				local teleport = nil
				for _,v2 in pairs(tab) do
					if v2 && v2:IsValid() && v2:GetClass() == "trigger_teleport" then
						teleport = v2
					end
				end
				if teleport then
					v:Fire("Lock")
					v:SetKeyValue("spawnflags", "257")
					v:SetKeyValue("speed", "0")
					v:SetRenderMode(RENDERMODE_TRANSALPHA)
					if v.BHS then
						v:SetKeyValue("locked_sound", v.BHS)
					else
						v:SetKeyValue("locked_sound", "None (Silent)")
					end
					v:SetNWInt("Platform", 1)
				end
			end
		end
	end
end