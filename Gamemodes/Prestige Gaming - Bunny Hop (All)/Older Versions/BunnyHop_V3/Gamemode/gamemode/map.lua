-------------------
-- MAP LOADING --
-------------------

local SPECIAL = {
	["AREA_BLOCK"] = 1,
	["AREA_TELEPORT"] = 2,
	["TPTRIGGER"] = 3,
	["ENTSPIKE"] = 4,
	["UNUSED"] = 5, -- Unused
	["NOBOT"] = 6, -- Unused
	["STEPSIZE"] = 7,
	["AREA_STEPSIZE"] = 8,
	["SPAWN"] = 9,
	
	["CUSTOM_LOSTWORLD"] = 100,
	["CUSTOM_EXQUISITE"] = 101,
	["CUSTOM_STRAFE"] = 102
}

LIST_FLYMAPS = {["bhop_eject"] = true, ["bhop_highfly"] = true, ["bhop_drop"] = true, ["bhop_together"] = true}
MAP_STEPSIZE = nil
MAP_SPAWN, MAP_SPAWN_CUSTOM = nil, false
MAP_SPAWNSPEED = false
AreaEnts = {["Start"] = nil, ["End"] = nil, ["Block"] = {}, ["Teleport"] = {}, ["Custom"] = {}}

globalMapList = {}
globalMapData = {}
currentMapData = {}
mapsCached = false
mapListLength = 0
cacheRetries = 0

function CacheMaps()
	SQLQuery("SELECT szMap, vStart1, vStart2, vEnd1, vEnd2, nPoints FROM records_maps", function(data)
		if not data or #data == 0 then return end

		globalMapData = {}
		globalMapList = {}
		currentMapData = {}
		
		for k,v in pairs(data) do
			globalMapData[v["szMap"]] = {ToVector(v["vStart1"]), ToVector(v["vStart2"]), ToVector(v["vEnd1"]), ToVector(v["vEnd2"]), tonumber(v["nPoints"])}
			table.insert(globalMapList, v["szMap"])
		end
		
		if globalMapData[game.GetMap()] then
			currentMapData = globalMapData[game.GetMap()]
		end
		
		globalMapList = PrepareMapList()
		
		mapsCached = true
	end)
end

function PrepareMapList()
	table.sort(globalMapList)

	local maps = {}
	for i,map in pairs(globalMapList) do
		table.insert(maps, {map, globalMapData[map][5]})
	end
	maps = util.Compress(util.TableToJSON(maps))
	mapListLength = #maps
	return maps
end

function ExecMapChecks(map, ply)
	if ply and ply:IsValid() then
		if MAP_STEPSIZE then
			ply:SetStepSize(MAP_STEPSIZE)
		end
		if MAP_SPAWN then
			local VARIATION = Vector(math.random(-50, 50), math.random(-50, 50), 0)
			if not MAP_SPAWN_CUSTOM and currentMapData and currentMapData[1] and currentMapData[2] then
				local xwidth, ywidth = math.Clamp((currentMapData[2].x - currentMapData[1].x) / 2 - 16, 0, 100), math.Clamp((currentMapData[2].y - currentMapData[1].y) / 2 - 16, 0, 100)
				VARIATION = Vector(math.random(-xwidth, xwidth), math.random(-ywidth, ywidth), 0)
			end
			ply:SetPos(MAP_SPAWN + VARIATION)
		end
		return
	end

	SQLQuery("UPDATE records_maps SET nPlays = nPlays + 1 WHERE szMap = '" .. game.GetMap() .. "'")
	if map == "bhop_eman_on" or map == "bhop_together" or map == "bhop_highfly" or map == "bhop_drop" then
		game.ConsoleCommand("sv_airaccelerate 1000\n")
	end
end

function CreateAreaBoxes()
	if not mapsCached then
		cacheRetries = cacheRetries + 1
		if cacheRetries > 10 then
			ServerLog("Unable to cache maps and load boxes for map: " .. game.GetMap())
			return
		end
		timer.Simple(2, CreateAreaBoxes)
		return
	end
	
	local startBottom, startTop, endBottom, endTop = nil, nil, nil, nil
	if not currentMapData then
		ServerLog("No Start/End area positions found for map: " .. game.GetMap())
	else
		startBottom = currentMapData[1] and currentMapData[1] + Vector(0, 0, 2) or nil
		startTop = currentMapData[2] and currentMapData[2] - Vector(0, 0, 16) or nil
		endBottom = currentMapData[3] and currentMapData[3] + Vector(0, 0, 2) or nil
		endTop = currentMapData[4] and currentMapData[4] + Vector(0, 0, 2) or nil
	end

	if AreaEnts["Start"] then AreaEnts["Start"]:Remove() end
	if AreaEnts["End"] then AreaEnts["End"]:Remove() end
	for k,v in pairs(AreaEnts["Block"]) do if v then v:Remove() end end
	for k,v in pairs(AreaEnts["Teleport"]) do if v then v:Remove() end end
	for k,v in pairs(AreaEnts["Custom"]) do if v then v:Remove() end end
	AreaEnts = {["Start"] = nil, ["End"] = nil, ["Block"] = {}, ["Teleport"] = {}, ["Custom"] = {}}

	if startBottom and startTop then
		AreaEnts["Start"] = ents.Create("bhop_timer")
		AreaEnts["Start"]:SetPos((startBottom + startTop) / 2)
		AreaEnts["Start"].min = startBottom
		AreaEnts["Start"].max = startTop
		AreaEnts["Start"].areatype = AREA_START
		AreaEnts["Start"]:Spawn()
	end
	
	if endBottom and endTop then
		AreaEnts["End"] = ents.Create("bhop_timer")
		AreaEnts["End"]:SetPos((endBottom + endTop) / 2)
		AreaEnts["End"].min = endBottom
		AreaEnts["End"].max = endTop
		AreaEnts["End"].areatype = AREA_FINISH
		AreaEnts["End"]:Spawn()
	end

	if LIST_FLYMAPS[game.GetMap()] then
		MAP_SPAWNSPEED = true
	end
	
	if not MAP_SPAWN then -- Default spawn is in center of starting area
		if currentMapData and startBottom and startTop then
			local refB, refT = Vector(startBottom.x, startBottom.y, startBottom.z), Vector(startTop.x, startTop.y, startBottom.z)
			MAP_SPAWN = (refB + refT) / 2
		end
	end

	SQLQuery("SELECT szData, nType FROM bhop_mapareas WHERE szMap = '" .. game.GetMap() .. "'", function(data)
		if not data or not data[1] or not data[1]["nType"] then return end
		for k,v in pairs(data) do
			local Type = tonumber(v["nType"])
			local Data = v["szData"]
			
			if Type == SPECIAL["AREA_BLOCK"] then
				local CSplit = string.Explode(";", Data)
				local areaBottom = ToVector(CSplit[1]) + Vector(0, 0, 2)
				local areaTop = ToVector(CSplit[2]) + Vector(0, 0, 2)
				local AreaID = #AreaEnts["Block"] + 1
				
				AreaEnts["Block"][AreaID] = ents.Create("bhop_timer")
				AreaEnts["Block"][AreaID]:SetPos((areaBottom + areaTop) / 2)
				AreaEnts["Block"][AreaID].min = areaBottom
				AreaEnts["Block"][AreaID].max = areaTop
				AreaEnts["Block"][AreaID].areatype = AREA_BLOCK
				AreaEnts["Block"][AreaID]:Spawn()
			elseif Type == SPECIAL["AREA_TELEPORT"] then
				local CSplit = string.Explode(";", Data)
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
			elseif Type == SPECIAL["AREA_STEPSIZE"] then
				local CSplit = string.Explode(";", Data)
				local areaBottom = ToVector(CSplit[1]) + Vector(0, 0, 2)
				local areaTop = ToVector(CSplit[2]) + Vector(0, 0, 2)
				local AreaID = #AreaEnts["Custom"] + 1
				
				AreaEnts["Custom"][AreaID] = ents.Create("bhop_timer")
				AreaEnts["Custom"][AreaID]:SetPos((areaBottom + areaTop) / 2)
				AreaEnts["Custom"][AreaID].min = areaBottom
				AreaEnts["Custom"][AreaID].max = areaTop
				AreaEnts["Custom"][AreaID].areatype = AREA_STEPSIZE
				AreaEnts["Custom"][AreaID].steps = {tonumber(CSplit[3]), tonumber(CSplit[4])}
				AreaEnts["Custom"][AreaID]:Spawn()
			elseif Type == SPECIAL["TPTRIGGER"] then
				local CSplit = string.Explode(";", Data)
				local PosInit = ToVector(CSplit[1])
				for k,v in pairs(ents.FindByClass("trigger_teleport")) do
					if v:GetPos() == PosInit then
						v:SetKeyValue("target", CSplit[2])
					end
				end
			elseif Type == SPECIAL["ENTSPIKE"] then
				local CSplit = string.Explode(";", Data)
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
			elseif Type == SPECIAL["STEPSIZE"] then
				MAP_STEPSIZE = tonumber(Data)
			elseif Type == SPECIAL["SPAWN"] then
				MAP_SPAWN = ToVector(Data)
				MAP_SPAWN_CUSTOM = true
				
				if game.GetMap() == "bhop_catalyst" then
					for k,v in pairs(ents.FindByClass("info_player_terrorist")) do
						if table.HasValue({Vector(7156.240234, 704.713989, -7585), Vector(7130.129883, 702.512024, -7585), Vector(7102.5, 700.283997, -7585), Vector(7069.850098, 700.505005, -7585), Vector(7036.589844, 700.119019, -7585)}, v:GetPos()) then
							v:Remove()
						end
					end
				end
			elseif Type == SPECIAL["CUSTOM_LOSTWORLD"] then
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
			elseif Type == SPECIAL["CUSTOM_EXQUISITE"] then
				for k,v in pairs(ents.FindByClass("trigger_multiple")) do
					if v:GetPos() == Vector(3264, -704.02, -974.49) then
						v:Remove()
					end
				end
			elseif Type == SPECIAL["CUSTOM_STRAFE"] then
				for k,v in pairs(ents.FindByClass("trigger_teleport")) do
					if v:GetPos() == Vector(-3946.5, -4732.5, 459) or v:GetPos() == Vector(-624.5, 3270, 4428) or v:GetPos() == Vector(681.5, 3138, 3941.5) then
						v:Remove()
					end
				end
			end
		end
	end)
end

function SetupMapTriggers()
	if LIST_NOMAPTRIGS[game.GetMap()] then return end

	for k,v in pairs(ents.FindByClass("func_door")) do
		if not v.IsP then continue end
		local mins = v:OBBMins()
		local maxs = v:OBBMaxs()
		local h = maxs.z - mins.z

		if h > 80 and not LIST_DOORMAPS[game.GetMap()] then continue end
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

hook.Add("EntityKeyValue", "SVEnt", function(ent, key, value)
    if !GAMEMODE.BaseStoreOutput or !GAMEMODE.BaseTriggerOutput then
        local e = scripted_ents.Get( "base_entity" )
        GAMEMODE.BaseStoreOutput = e.StoreOutput
        GAMEMODE.BaseTriggerOutput = e.TriggerOutput
    end
 
    if key:lower():sub(1, 2) == "on" then
        if !ent.StoreOutput or !ent.TriggerOutput then
			ent.StoreOutput = GAMEMODE.BaseStoreOutput
			ent.TriggerOutput = GAMEMODE.BaseTriggerOutput
		end

        if ent.StoreOutput then
			ent:StoreOutput(key, value)
        end
    end
end)