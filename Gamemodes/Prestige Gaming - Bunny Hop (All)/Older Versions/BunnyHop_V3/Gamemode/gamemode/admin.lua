util.AddNetworkString("BHOP_ADM")

-----------
-- ADMIN --
-----------

Admin = {}
Admin.Access = {
	["Owner"] = 3,
	["Admin"] = 2,
	["Moderator"] = 1
}
Admin.List = {
	{"3974409736", Admin.Access["Owner"]}, -- Gravious
	{"4074253482", Admin.Access["Moderator"]}, -- Own3r
	{"549068386", Admin.Access["Moderator"]} -- 1337 Designs
}
Admin.Functions = {
	{3, "Maximum Access", 500},
	{2, "[Map] Reload", 101},
	{2, "[Map] Area Editor", 102},
	{2, "[Map] Times", 103},
	{2, "[Map] Change", 104},
	{2, "[Map] Specials", 105},
	{2, "[Players] Times", 201},
	{2, "[Players] Teleport", 202},
	{2, "[Players] Manage", 203},
	{1, "[Players] Scripting", 204},
	{1, "[Bot] Manage", 301}
}

function Admin:GetAccessLevel(ply)
	for k,v in pairs(Admin.List) do
		if v[1] == ply:UniqueID() then
			return v[2]
		end
	end
	
	return 0
end

function Admin:GetAllowed(ply, id)
	local ac = Admin:GetAccessLevel(ply)
	local tg = math.floor(id / 10)
	for k,v in pairs(Admin.Functions) do
		if v[3] == tg then
			if ac >= v[1] then
				return true
			end
		end
	end
	return false
end

function Admin:FindPlayers(args)
	local Data = {} for i=1,#args do Data[i] = {["Count"] = 0, ["Players"] = {}} end
	for k,v in pairs(player.GetAll()) do
		for i,str in pairs(args) do
			if string.find(string.lower(v:Name()), string.lower(str), 1, true) then
				table.insert(Data[i]["Players"], v)
				Data[i]["Count"] = Data[i]["Count"] + 1
			end
		end
	end
	return Data
end

function AdminCommand(ply, cmd, args)
	if not args or not args[1] or not tonumber(args[1]) then return end
	local id = tonumber(args[1])
	if id == 2032 then
		local allowed = false
		if ply:IsAdmin() then allowed = true end
		if not allowed then allowed = Admin:GetAllowed(ply, id) end
		if not allowed then return end
	else
		if not Admin:GetAllowed(ply, id) then return end
	end

	if id == 1010 then -- Reload map entities
		CreateAreaBoxes()
		SendMessage(ply, MSG_ID["AdminMsg"], {"Map triggers have been reloaded!"})
	elseif id == 1011 then -- Reload map WRs and ranks
		SendMessage(ply, MSG_ID["AdminMsg"], {"Starting data reload!"})
		
		Records:Initialize()
		timer.Simple(1, function() Records:GlobalFull() end)
		timer.Simple(2, function() for k,v in pairs(player.GetHumans()) do GAMEMODE:ReloadPlayer(v) end end)
		timer.Simple(4, function() Ranks:LoadMaximum() end)
		timer.Simple(5, function() Ranks:ReloadGlobal() SendMessage(ply, MSG_ID["AdminMsg"], {"Data reload has ended!"}) end)
	elseif id == 1012 then
		CacheMaps()
		SendMessage(ply, MSG_ID["AdminMsg"], {"Map data has been recached!"})
	elseif id == 1024 then -- Start Add
		if not args[2] or not args[3] then return end
		if not ToVector(args[2]) or not ToVector(args[3]) then SendMessage(ply, MSG_ID["AdminMsg"], {"Invalid vectors received!"}) return end
		SQLQuery("SELECT vStart1, vStart2 FROM records_maps WHERE szMap = '" .. game.GetMap() .. "'", function(data)
			if data and data[1] and data[1]["vStart1"] then
				SQLQuery("UPDATE records_maps SET vStart1 = '" .. args[2] .. "', vStart2 = '" .. args[3] .. "' WHERE szMap = '" .. game.GetMap() .. "'", function(data)
					SendMessage(ply, MSG_ID["AdminMsg"], {"Start field has been updated! Recache maps and reload areas to reload in-game areas!"})
				end)
			else
				SQLQuery("INSERT INTO records_maps VALUES ('" .. game.GetMap() .. "', '" .. args[2] .. "', '" .. args[3] .. "', '', '', 5, 0)", function(data)
					SendMessage(ply, MSG_ID["AdminMsg"], {"Start field has been added (Remember to add points + end)! Recache maps and reload areas to reload in-game areas!"})
				end)
			end
		end)
	elseif id == 1021 then -- Start Remove
		SQLQuery("UPDATE records_maps SET vStart1 = '', vStart2 = '' WHERE szMap = '" .. game.GetMap() .. "'", function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"Start field has been removed! Recache maps and reload areas to reload in-game areas!"})
		end)
	elseif id == 1025 then -- End Add
		if not args[2] or not args[3] then return end
		if not ToVector(args[2]) or not ToVector(args[3]) then SendMessage(ply, MSG_ID["AdminMsg"], {"Invalid vectors received!"}) return end
		SQLQuery("SELECT vEnd1, vEnd2 FROM records_maps WHERE szMap = '" .. game.GetMap() .. "'", function(data)
			if data and data[1] and data[1]["vEnd1"] then
				SQLQuery("UPDATE records_maps SET vEnd1 = '" .. args[2] .. "', vEnd2 = '" .. args[3] .. "' WHERE szMap = '" .. game.GetMap() .. "'", function(data)
					SendMessage(ply, MSG_ID["AdminMsg"], {"End field has been updated! Recache maps and reload areas to reload in-game areas!"})
				end)
			else
				SQLQuery("INSERT INTO records_maps VALUES ('" .. game.GetMap() .. "', '', '', '" .. args[2] .. "', '" .. args[3] .. "', 5, 0)", function(data)
					SendMessage(ply, MSG_ID["AdminMsg"], {"End field has been added (Remember to add points + start)! Recache maps and reload areas to reload in-game areas!"})
				end)
			end
		end)
	elseif id == 1023 then -- End Remove
		SQLQuery("UPDATE records_maps SET vEnd1 = '', vEnd2 = '' WHERE szMap = '" .. game.GetMap() .. "'", function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"End field has been removed! Recache maps and reload areas to reload in-game areas!"})
		end)
	elseif id == 1030 then
		if not args[2] or not args[3] or not args[4] or not tonumber(args[3]) or not tonumber(args[4]) then return end
		local mode = tonumber(args[3])
		if mode == MODE_NORMAL then
			SQLQuery("SELECT nID, nTime, szName FROM records_normal WHERE szMap = '" .. args[2] .. "' ORDER BY nTime ASC LIMIT " .. tonumber(args[4]), function(data)
				if data and #data > 0 and data[1]["nTime"] then
					local target = {}
					for k,v in pairs(data) do
						table.insert(target, {k, v["szName"], tonumber(v["nTime"]), v["nID"]})
					end
					AdminSend(ply, id, target)
				else
					AdminSend(ply, id, {})
				end
			end)
		elseif mode < MODE_PRACTICE then
			SQLQuery("SELECT nID, nTime, szName FROM records_special WHERE szMap = '" .. args[2] .. "' AND nStyle = " .. mode .. " ORDER BY nTime ASC LIMIT " .. tonumber(args[4]), function(data)
				if data and #data > 0 and data[1]["nTime"] then
					local target = {}
					for k,v in pairs(data) do
						table.insert(target, {k, v["szName"], tonumber(v["nTime"]), v["nID"]})
					end
					AdminSend(ply, id, target)
				else
					AdminSend(ply, id, {})
				end
			end)
		end
	elseif id == 1031 then
		if not args[2] or not globalMapData[args[2]] or not args[3] or not args[4] or not tonumber(args[3]) or not tonumber(args[4]) then return end
		local mode = tonumber(args[3])
		if mode == MODE_NORMAL then
			SQLQuery("DELETE FROM records_normal WHERE szMap = '" .. args[2] .. "' AND nID = " .. args[4], function(data)
				SendMessage(ply, MSG_ID["AdminMsg"], {"Time on " .. args[2] .. " [" .. MODE_NAME[mode] .. "] by " .. args[4] .. " has been removed! Reload map data (ranks) if necessary!"})
				Timer:SQLFuncRankUID(tonumber(args[4]))
			end)
		elseif mode < MODE_PRACTICE then
			SQLQuery("DELETE FROM records_special WHERE szMap = '" .. args[2] .. "' AND nID = " .. args[4] .. " AND nStyle = " .. mode, function(data)
				SendMessage(ply, MSG_ID["AdminMsg"], {"Time on " .. args[2] .. " [" .. MODE_NAME[mode] .. "] by " .. args[4] .. " has been removed! Reload map data (ranks) if necessary!"})
				Timer:SQLFuncRankUID(tonumber(args[4]))
			end)
		end
	elseif id == 1040 then -- Change Map
		if not args[2] then return end
		if not file.Exists("maps/" .. args[2] .. ".bsp", "GAME") then return end
		SendGlobalMessage(MSG_ID["MapChange"], {args[2]})
		timer.Simple(5, function() RunConsoleCommand("changelevel", args[2]) end)
	elseif id == 1041 then -- Force extend
		if args[2] and tonumber(args[2]) then
			RTV:ForceExtend(tonumber(args[2]))
		else
			RTV:ForceExtend()
		end
	elseif id == 1042 then
		if not args[2] or not tonumber(args[2]) then return end
		local TargetPoints = tonumber(args[2]) or 5
		SQLQuery("UPDATE records_maps SET nPoints = " .. TargetPoints .. " WHERE szMap = '" .. game.GetMap() .. "'", function()
			SQLQuery("UPDATE records_normal SET nWeight = (" .. TargetPoints .. " / (nTime / (" .. Ranks.PointFactor .. " * " .. TargetPoints .. "))) WHERE szMap = '" .. game.GetMap() .. "'", function()
				SQLQuery("UPDATE records_rank AS a INNER JOIN (SELECT b.nID, SUM(b.nWeight) AS nSum FROM records_normal AS b GROUP BY b.nID) AS g ON g.nID = a.nID SET a.nTotalWeight = g.nSum", function()
					SendMessage(ply, MSG_ID["AdminMsg"], {"Point data and time weight for " .. game.GetMap () .. " have been updated!"})
				end)
			end)
		end)
	elseif id == 1050 then -- Sending areas for map
		SQLQuery("SELECT nID, nType, szData FROM bhop_mapareas WHERE szMap = '" .. game.GetMap() .. "'", function(data)
			AdminSend(ply, id, data)
		end)
	elseif id == 1051 then -- [Special] Add
		if not args[2] or not tonumber(args[2]) or not args[3] then return end
		SQLQuery("INSERT INTO bhop_mapareas VALUES (0, '" .. game.GetMap() .. "', " .. tonumber(args[2]) .. ", '" .. args[3] .. "')", function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"Trigger has been added!"})
		end)
	elseif id == 1052 then -- [Special] Edit
		if not args[2] or not tonumber(args[2]) or not args[3] then return end
		SQLQuery("UPDATE bhop_mapareas SET szData = '" .. args[3] .. "' WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. tonumber(args[2]), function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"Trigger [# " .. args[2] .. "] has been edited!"})
		end)
	elseif id == 1053 then -- [Special] Remove
		if not args[2] or not tonumber(args[2]) then return end
		SQLQuery("DELETE FROM bhop_mapareas WHERE szMap = '" .. game.GetMap() .. "' AND nID = " .. tonumber(args[2]), function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"Trigger [# " .. args[2] .. "] has been removed!"})
		end)
	elseif id == 2010 then
		if not args[2] or not args[4] or not tonumber(args[4]) or not args[5] or not tonumber(args[5]) then return end
		local mode = tonumber(args[4])
		local map = "szMap != ''"
		local player = ""
		if args[3] and globalMapData[args[3]] then map = "szMap = '" .. args[3] .. "'" end
		if tonumber(args[2]) and string.len(args[2]) > 7 then -- UID specified
			player = "nID = " .. args[2]
		elseif args[2] != "" then
			player = "szName LIKE '%" .. mSQL:escape(args[2]) .. "%'"
		end
		
		if mode == MODE_NORMAL then
			SQLQuery("SELECT nID, nTime, szName, szMap FROM records_normal WHERE " .. map .. (player != "" and " AND " .. player or "") .. " ORDER BY nTime ASC LIMIT " .. tonumber(args[5]), function(data)
				if data and #data > 0 and data[1]["nTime"] then
					local target = {}
					for k,v in pairs(data) do
						table.insert(target, {k, v["szName"], tonumber(v["nTime"]), v["nID"], v["szMap"]})
					end
					AdminSend(ply, id, target)
				else
					AdminSend(ply, id, {})
				end
			end)
		elseif mode < MODE_PRACTICE then
			SQLQuery("SELECT nID, nTime, szName, szMap FROM records_special WHERE " .. map .. (player != "" and " AND " .. player or "") .. " AND nStyle = " .. mode .. " ORDER BY nTime ASC LIMIT " .. tonumber(args[5]), function(data)
				if data and #data > 0 and data[1]["nTime"] then
					local target = {}
					for k,v in pairs(data) do
						table.insert(target, {k, v["szName"], tonumber(v["nTime"]), v["nID"], v["szMap"]})
					end
					AdminSend(ply, id, target)
				else
					AdminSend(ply, id, {})
				end
			end)
		end
	elseif id == 2020 then
		if not args[2] or not args[3] then return end
		if args[4] and args[4] == "true" then
			local Find = Admin:FindPlayers({args[2]})
			local From = Find[1]["Players"][1]
			if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were more than two candidates found, please narrow down your search!"})
			elseif Find[1]["Count"] == 1 and From:IsValid() then
				From:SetPos(ToVector(args[3]))
				SendMessage(ply, MSG_ID["AdminMsg"], {From:Name() .. " has been teleported to " .. args[3]})
			else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
		else
			local Find = Admin:FindPlayers({args[2], args[3]})
			local From, To = Find[1]["Players"][1], Find[2]["Players"][1]
			if Find[1]["Count"] > 1 or Find[2]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were more than two candidates found, please narrow down your search!"})
			elseif Find[1]["Count"] == 1 and Find[2]["Count"] == 1 and From:IsValid() and To:IsValid() then
				From:SetPos(To:GetPos())
				SendMessage(ply, MSG_ID["AdminMsg"], {From:Name() .. " has been teleported to " .. To:Name()})
				SendMessage(From, MSG_ID["AdminMsg"], {"You have been teleported to " .. To:Name() .. " by " .. ply:Name()})
			else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
		end
	elseif id == 2021 then
		if ply.HopMode != MODE_PRACTICE or not ply.Spectating then return end
		local cPos = ply:GetPos()
		DoSpectate(ply)
		timer.Simple(1, function() ply:SetPos(cPos) SendMessage(ply, MSG_ID["AdminMsg"], {"You have been teleported to your spectator location!"}) end)
	elseif id == 2030 then
		if not args[2] or not args[3] or not tonumber(args[3]) then return end
		local Find = Admin:FindPlayers({args[2]})
		local Target = Find[1]["Players"][1]
		if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were multiple candidates found, please narrow down your search!"})
		elseif Find[1]["Count"] == 1 and Target:IsValid() then
			if ply.AdminSlap then
				if ply.AdminSlap[1] == Target:UniqueID() then
					ply.AdminSlap[2] = ply.AdminSlap[2] + 1
				else
					ply.AdminSlap[1] = Target:UniqueID()
					ply.AdminSlap[2] = 0
					ply.AdminSlap[3] = Target:GetPos()
				end
			else
				ply.AdminSlap = {Target:UniqueID(), 0, Target:GetPos()}
			end
			local Init = ply.AdminSlap[3]
			local SlapData = {Init - Vector(100, 0, 0), Init, Init + Vector(0, 100, 0), Init, Init + Vector(100, 0, 0), Init, Init - Vector(0, 100, 0), Init, Init + Vector(0, 0, 100), Init, Init - Vector(0, 0, 100), Init}
			local SlapTitles = {[0] = "Initial", "Left (Negative X)", "Initial", "Up (Positive Y)", "Initial", "Right (Positive X)", "Initial", "Down (Negative Y)", "Initial", "Up (Positive Z)", "Initial", "Down (Negative Z)", "Initial"}
			if SlapData[ply.AdminSlap[2]] then Target:SetPos(SlapData[ply.AdminSlap[2]]) elseif ply.AdminSlap[2] > 12 then ply.AdminSlap[2] = 0 ply.AdminSlap[3] = Target:GetPos() end
			local SetVelocity = tonumber(args[3])
			local RandomVelocity = Vector(math.random(SetVelocity) - (SetVelocity / 2 ), math.random(SetVelocity) - (SetVelocity / 2 ), math.random(SetVelocity) - (SetVelocity / 4 ))
			Target:EmitSound("physics/body/body_medium_impact_hard1.wav")
			Target:SetVelocity(RandomVelocity)
			if not args[4] then SendMessage(Target, MSG_ID["AdminMsg"], {"You have been slapped by " .. ply:Name()})
			SendMessage(ply, MSG_ID["AdminMsg"], {Target:Name() .. " has been slapped with " .. SetVelocity .. " force! - " .. SlapTitles[ply.AdminSlap[2]]}) end
		else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
	elseif id == 2031 then
		ply.SecretSpectator = !ply.SecretSpectator
		SendMessage(ply, MSG_ID["AdminMsg"], {ply.SecretSpectator and "You have entered secret spectator mode!" or "You have returned to normal spectate mode!"})
	elseif id == 2032 then
		if not args[2] then return end
		local Find = Admin:FindPlayers({args[2]})
		local Target = Find[1]["Players"][1]
		if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were multiple candidates found, please narrow down your search!"})
		elseif Find[1]["Count"] == 1 and Target:IsValid() then
			Target:StripWeapons()
			Target:SendLua("SetGun(2)")
			if args[3] and args[3] == "true" then Target.GunBlock = true else Target.GunBlock = false end
			SendMessage(ply, MSG_ID["AdminMsg"], {Target:Name() .. " has been stripped of his weapons" .. (Target.GunBlock and " permanently!" or "!")})
		else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
	elseif id == 2033 then
		if not Admin:GetAllowed(ply, 5000) then return end
		if file.Exists("positions_" .. game.GetMap() .. ".txt", "DATA") then
			file.Delete("positions_" .. game.GetMap() .. ".txt")
		end
		local Data = {}
		for k,v in pairs(player.GetHumans()) do if v.Spectating then continue end table.insert(Data, {v:UniqueID(), GetVectorString(v:GetPos())}) end
		file.Write("positions_" .. game.GetMap() .. ".txt", util.TableToJSON(Data))
		SendMessage(ply, MSG_ID["AdminMsg"], {"Current player positions (" .. #Data .. ") have been saved!"})
	elseif id == 2034 then
		if not Admin:GetAllowed(ply, 5000) then return end
		local fileTest, CSetPos = file.Exists("positions_" .. game.GetMap() .. ".txt", "DATA"), 0
		if not fileTest and not GAMEMODE.SavedPositions then
			SendMessage(ply, MSG_ID["AdminMsg"], {"No saved positions were found for this map!"})
		elseif fileTest and not GAMEMODE.SavedPositions then
			GAMEMODE.SavedPositions = util.JSONToTable(file.Read("positions_" .. game.GetMap() .. ".txt", "DATA"))
		end
		for k,v in pairs(player.GetHumans()) do for k2,v2 in pairs(GAMEMODE.SavedPositions) do if v2[1] == v:UniqueID() then v:SetPos(ToVector(v2[2])) CSetPos = CSetPos + 1 end end end
		file.Delete("positions_" .. game.GetMap() .. ".txt")
		SendMessage(ply, MSG_ID["AdminMsg"], {"All players (" .. CSetPos .. " / " .. #player.GetHumans() .. " - File: " .. #GAMEMODE.SavedPositions .. ") have been set back to their old position!"})
	elseif id == 2036 then
		if not Admin:GetAllowed(ply, 5000) then return end
		for i = 1, 12 do
			timer.Simple(i * 0.20, function() AdminCommand(ply, cmd, {2030, args[2], args[3], true}) end)
		end
	elseif id == 2040 then
		if not args[2] or not args[3] or not args[4] or not tonumber(args[3]) then return end
		if not tonumber(args[2]) then
			local Find = Admin:FindPlayers({args[2]})
			local Target = Find[1]["Players"][1]
			if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were multiple candidates found, please narrow down your search!"})
			elseif Find[1]["Count"] == 1 and Target:IsValid() then
				Ban:AddUser(ply:Name(), Target, tonumber(args[3]), args[4])
			else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
		else
			Ban:AddUser(ply:Name(), nil, tonumber(args[3]), args[4], tonumber(args[2]))
			SendMessage(ply, MSG_ID["AdminMsg"], {args[2] .. " has been locked out of the pG Bhop Server " .. (tonumber(args[3]) == 0 and "permanently!" or "for " .. tonumber(args[3]) .. " minutes!")})
		end
	elseif id == 2041 then
		if not Admin:GetAllowed(ply, 5000) then return end
		SQLQuery("SELECT nID, szName, nUID, nExpire, szReason, szDate, szAdmin FROM bhop_limitations ORDER BY nID DESC", function(data)
			local send = {}
			for k,v in pairs(data) do
				table.insert(send, {v["nID"], v["nUID"], v["szName"], v["nExpire"], v["szReason"], v["szDate"], v["szAdmin"]})
			end
			AdminSend(ply, id, send)
		end)
	elseif id == 2042 then
		if not args[2] or not tonumber(args[2]) then return end
		if not Admin:GetAllowed(ply, 5000) then return end
		SQLQuery("SELECT szMap, szName, nID, nTime, nWeight FROM records_normal WHERE nID = " .. args[2], function(data)
			local str = ""
			if data and data[1] and data[1]["nID"] then
				for k,v in pairs(data) do
					str = str .. "INSERT INTO records_normal VALUES ('" .. v["szMap"] .. "','" .. v["szName"] .. "'," .. v["nID"] .. "," .. v["nTime"] .. "," .. v["nWeight"] .. ");\n"
				end
			end
			
			if str != "" then
				file.CreateDir("playertimes")
				if file.Exists("playertimes/" .. args[2] .. ".txt", "DATA") then
					file.Delete("playertimes/" .. args[2] .. ".txt")
				end
				file.Write("playertimes/" .. args[2] .. ".txt", str)
				SendMessage(ply, MSG_ID["AdminMsg"], {"All times have been saved to playertimes/" .. args[2] .. ".txt"})
				
				SQLQuery("DELETE FROM records_normal WHERE nID = " .. args[2], function(data)
					SendMessage(ply, MSG_ID["AdminMsg"], {"All times by this player have been deleted!"})
				end)
			else
				SendMessage(ply, MSG_ID["AdminMsg"], {"This player has to times on normal!"})
			end
		end)
	elseif id == 2043 then
		if not args[2] or not tonumber(args[2]) then return end
		if not Admin:GetAllowed(ply, 5000) then return end
		SQLQuery("DELETE FROM bhop_limitations WHERE nUID = " .. args[2], function(data)
			SendMessage(ply, MSG_ID["AdminMsg"], {"The lock-out on this player has been lifted!"})
		end)
	elseif id == 3010 then
		if Bot.Enabled then SendMessage(ply, MSG_ID["AdminMsg"], {"Bot recording is already enabled!"})
		else Bot.Enabled = true SendMessage(ply, MSG_ID["AdminMsg"], {"Bot recording has been enabled!"}) end
	elseif id == 3011 then
		if not Bot.Enabled then SendMessage(ply, MSG_ID["AdminMsg"], {"Bot recording is already disabled!"})
		else Bot.Enabled = false SendMessage(ply, MSG_ID["AdminMsg"], {"Bot recording has been disabled!"}) end
	elseif id == 3012 or id == 3013 then
		if not args[2] then return end
		local Find = Admin:FindPlayers({args[2]})
		local Target = Find[1]["Players"][1]
		if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["AdminMsg"], {"There were multiple candidates found, please narrow down your search!"})
		elseif Find[1]["Count"] == 1 and Target:IsValid() then
			if id == 3013 then
				Bot.Leader:StopRecord(Target)
				SendMessage(ply, MSG_ID["AdminMsg"], {Target:Name() .. " is no longer being recorded!"})
			else
				Bot.Leader:StartRecord(Target)
				SendMessage(ply, MSG_ID["AdminMsg"], {Target:Name() .. " is now being recorded!"})
			end
		else SendMessage(ply, MSG_ID["AdminMsg"], {"No valid candidates found!"}) end
	elseif id == 3014 then
		if not Admin:GetAllowed(ply, 5000) then return end
		Bot:Save()
		SendMessage(ply, MSG_ID["AdminMsg"], {"Bot data for this map has been forcably saved!"})
	elseif id == 3015 then
		if not Admin:GetAllowed(ply, 5000) then return end
		if ply.BotDelete then
			ply.BotDelete = nil
			
			if not file.Exists("botdata/" .. game.GetMap() .. ".txt", "DATA") then
				if Bot.Runner and Bot.RunnerFrames > 0 then
					Bot:Remove()
					SendMessage(ply, MSG_ID["AdminMsg"], {"Bot has been disabled and live bot data for this map has been deleted!"})
				end
				return
			end

			file.Delete("botdata/" .. game.GetMap() .. ".txt")
			SQLQuery("DELETE FROM bhop_botdata WHERE szMap = '" .. game.GetMap() .. "'", function()
				Bot:Remove()
				SendMessage(ply, MSG_ID["AdminMsg"], {"Bot has been disabled and bot (file) data for this map has been deleted!"})
			end)
		else
			SendMessage(ply, MSG_ID["AdminMsg"], {"Are you sure you want to delete this run? Click the button again if you do. (Auto-reset in 10 seconds!)"})
			ply.BotDelete = true
			
			if not file.Exists("botdata/" .. game.GetMap() .. ".txt", "DATA") then
				local add = ""
				if Bot.Runner and Bot.RunnerFrames > 0 then add = " But there is currently a bot which can be deleted" end
				SendMessage(ply, MSG_ID["AdminMsg"], {"There is currently no saved bot data for this map." .. add})
			end
			
			timer.Simple(10, function() ply.BotDelete = nil end)
		end
	elseif id == 3016 then
		if not Admin:GetAllowed(ply, 5000) then return end
		SendMessage(ply, MSG_ID["AdminMsg"], {"Old: " .. collectgarbage("count") * 1024 .. " kB"})
		collectgarbage()
		SendMessage(ply, MSG_ID["AdminMsg"], {"New: " .. collectgarbage("count") * 1024 .. " kB"})
	end
end
concommand.Add("bhop_adm", AdminCommand)

function AdminSend(ply, id, vars)
	net.Start("BHOP_ADM")
	net.WriteInt(id, 12)
	net.WriteTable(vars)
	net.Send(ply)
end

----------

Ban = {}
Ban.Filters = {
	{"niggers ", 0, "ni***** "},
	{"you nigger", 0, "you ni****"},
	{"nigger", 10080, "ni****"},
	{" nig ", 10080, " n** "},
	{"nigg", 10080, "n***"},
	{"niqq", 10080, "n***"},
	{"negro", 10080, "ne***"},
}

function Ban:Test(ply)
	if ply:IsBot() then SendGlobalMessage(MSG_ID["Connect"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply) ply.Connected = true return end
	SQLQuery("SELECT nExpire, szReason, (NOW() - szDate) / 60 AS nTime FROM bhop_limitations WHERE nUID = " .. ply:UniqueID() .. " ORDER BY szDate DESC", function(data)
		if data and data[1] and data[1]["nExpire"] and data[1]["nTime"] then
			if tonumber(data[1]["nTime"]) < tonumber(data[1]["nExpire"]) or tonumber(data[1]["nExpire"]) == 0 then
				ply:Kick("You are locked out of pG Bhop " .. (tonumber(data[1]["nExpire"]) == 0 and "permanently!" or "for a remaining " .. math.ceil(tonumber(data[1]["nExpire"]) - tonumber(data[1]["nTime"])) .. " minutes!") .. " Reason: " .. data[1]["szReason"])
			else
				SendGlobalMessage(MSG_ID["Connect"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply)
				ply.Connected = true
			end
		else
			SendGlobalMessage(MSG_ID["Connect"], {ply:IsBot() and "The WR Bot" or ply:Name()}, ply)
			ply.Connected = true
		end
	end)
end

function Ban:AddUser(admin, user, length, reason, uid)
	if uid then
		SQLQuery("INSERT INTO bhop_limitations VALUES (0, 'Ban By UID " .. uid .. "', " .. uid .. ", " .. length .. ", '" .. mSQL:escape(reason) .. "', NOW(), '" .. mSQL:escape(admin) .. "')")
	else
		SQLQuery("INSERT INTO bhop_limitations VALUES (0, '" .. mSQL:escape(user:Name()) .. "', " .. user:UniqueID() .. ", " .. length .. ", '" .. mSQL:escape(reason) .. "', NOW(), '" .. mSQL:escape(admin) .. "')", function()
			user:Kick("You have been locked out of pG Bhop " .. (length == 0 and "permanently!" or "for " .. length .. " minutes!") .. " Reason: " .. reason)
			SendGlobalMessage(MSG_ID["AdminMsg"], {user:Name() .. " has been locked out of the pG Bhop Server " .. (length == 0 and "permanently!" or "for " .. length .. " minutes!")}, user)
		end)
	end
end

function Ban:Filter(ply, text)
	local lower = string.lower(text)
	for k,v in pairs(Ban.Filters) do
		if string.find(lower, v[1], 1, true) then
			self:AddUser("CONSOLE", ply, v[2], "Racism, Message: " .. text)
			text = string.gsub(text, v[1], v[3])
			break
		end
	end
	return text
end