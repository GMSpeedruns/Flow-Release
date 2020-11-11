-----------------------------
-- MAIN FUNCTIONS/HOOKS --
-----------------------------

function GM:PlayerSay(ply, text)
	local s = string.sub(text, 0, 1)
	local cmd = ""
	if s != "!" and s != "/" and text != "rtv" then return Ban:Filter(ply, text) else cmd = string.lower(string.gsub(string.gsub(text, "!", ""), "/", "")) end

	-- Bhop Window specific commands
	if cmd == "wr" or cmd == "records" then
		ply:SendLua("SetActiveWindow('WR', " .. ply.HopMode .. ")")
	elseif cmd == "mode" or cmd == "style" then
		ply:SendLua("SetActiveWindow('Mode')")
	elseif cmd == "help" or cmd == "commands" then
		ply:SendLua("SetActiveWindow('Help')")
	elseif cmd == "nominate" or cmd == "maps" then
		ply:SendLua("SetActiveWindow('Nominate')")
	elseif cmd == "left" or cmd == "mapsleft" then
		if not ply.HasBeatList then
			SQLQuery("SELECT szMap, nTime FROM records_normal WHERE nID = " .. ply:UniqueID() .. " ORDER BY szMap ASC", function(data)
				if not data or not data[1] then data = {} end
				SendData(ply, DATA_ID["MapsLeft"], data)
				ply.HasBeatList = true
			end)
		else
			ply:SendLua("SetActiveWindow('Left')")
		end
	elseif cmd == "beat" or cmd == "mapsbeat" then
		if not ply.HasBeatList then
			SQLQuery("SELECT szMap, nTime FROM records_normal WHERE nID = " .. ply:UniqueID() .. " ORDER BY szMap ASC", function(data)
				if not data or not data[1] then data = {} end
				SendData(ply, DATA_ID["MapsBeat"], data)
				ply.HasBeatList = true
			end)
		else
			ply:SendLua("SetActiveWindow('Beat')")
		end
	elseif cmd == "rank" then
		ply:SendLua("SetActiveWindow('Rank', {" .. ply.RankID .. ", " .. ply.RankWeight .. "})")
	elseif cmd == "top" or cmd == "toplist" or cmd == "best" then
		if not ply.HasTopList then
			SendData(ply, DATA_ID["TopList"], Records.Top)
			ply.HasTopList = true
		else
			ply:SendLua("SetActiveWindow('Top')")
		end
	elseif string.sub(cmd, 1, 3) == "wr " then
		local Target = string.lower(string.sub(cmd, 4) or "")
		local ModeID = MODE_NORMAL
		for k,v in pairs(MODE_NAME) do
			if string.find(string.lower(v), Target, 1, true) then
				ModeID = k
				break
			end
		end
		ply:SendLua("SetActiveWindow('WR', " .. ModeID .. ")")
	elseif cmd == "admincp" then
		local Access = Admin:GetAccessLevel(ply)
		if Access > 0 then
			ply:SendLua("Admin.SelfAccess = " .. Access)
			ply:SendLua("SetActiveWindow('Admin')")
		end
	
	-- Bhop Style specific commands
	elseif cmd == "normal" then
		ChangeMode(ply, nil, {MODE_NORMAL})
	elseif cmd == "sideways" or cmd == "sw" then
		ChangeMode(ply, nil, {MODE_SIDEWAYS})
	elseif cmd == "wonly" or cmd == "w" then
		ChangeMode(ply, nil, {MODE_WONLY})
	elseif cmd == "auto" then
		ChangeMode(ply, nil, {MODE_AUTO})
	elseif cmd == "practice" then
		ChangeMode(ply, nil, {MODE_PRACTICE})
	
	-- Bhop CVars
	elseif cmd == "hud" or cmd == "gui" then
		ply:SendLua("SetCV(1)")
	elseif cmd == "showhud" or cmd == "showgui" then
		ply:SendLua("SetCV(1, 1)")
	elseif cmd == "hidehud" or cmd == "hidegui" then
		ply:SendLua("SetCV(1, 0)")
	elseif cmd == "showspec" then
		ply:SendLua("SetCV(2, 1)")
	elseif cmd == "hidespec" then
		ply:SendLua("SetCV(2, 0)")
	elseif cmd == "show" or cmd == "showplayers" then
		ply:SendLua("SetCV(3, 1)")
	elseif cmd == "hide" or cmd == "hideplayers" then
		ply:SendLua("SetCV(3, 0)")
	
	-- Bot commands
	elseif cmd == "bot" then
		Bot.Leader:Info(ply)
	elseif cmd == "bot help" then
		ply:SendLua("SetActiveWindow('Help')")
	elseif cmd == "bot who" then
		Bot.Leader:Who(ply)
	elseif cmd == "bot record" then
		Bot.Leader:Record(ply)
	elseif cmd == "bot record me" then
		Bot.Leader:Record(ply, true)
	elseif cmd == "bot record stop" then
		Bot.Leader:RecordCancel(ply)
	
	-- Bhop General commands
	elseif cmd == "r" or cmd == "restart" then
		RestartMap(ply)
	elseif cmd == "rtv" or cmd == "vote" then
		RTV:Vote(ply)
	elseif cmd == "revoke" or cmd == "rtv revoke" then
		RTV:Revoke(ply)
	elseif cmd == "time" or cmd == "timeleft" then
		SendMessage(ply, MSG_ID["TimeLeft"], {ConvertTime(RTV.MapEnd - CurTime())})
	elseif cmd == "clear" or cmd == "remove" then
		ply:StripWeapons()
		ply:SendLua("SetGun(2)")
	elseif cmd == "usp" or cmd == "glock" or cmd == "knife" or cmd == "p90" then
		if ply.GunBlock then ply:SendLua("SetGun(3)") return "" end
		local Found = false
		for k,v in pairs(ply:GetWeapons()) do
			if v:GetClass() == "weapon_" .. cmd then
				Found = true
				break
			end
		end
		if not Found then
			ply:Give("weapon_" .. cmd)
			ply:SendLua("SetGun(0, '" .. cmd .. "')")
		else
			ply:SendLua("SetGun(1, '" .. cmd .. "')")
		end
	elseif cmd == "points" then
		local TargetMap = game.GetMap()
		if globalMapData[TargetMap] then
			ply:SendLua("ShowPoints(" .. globalMapData[TargetMap][5] .. ", '" .. TargetMap .. "')")
		else
			ply:SendLua("ShowPoints(-1, '" .. TargetMap .. "')")
		end
	elseif string.sub(cmd, 1, 7) == "points " then
		local TargetMap = string.sub(cmd, 8)
		if globalMapData[TargetMap] then
			ply:SendLua("ShowPoints(" .. globalMapData[TargetMap][5] .. ", '" .. TargetMap .. "')")
		else
			ply:SendLua("ShowPoints(-1, '" .. TargetMap .. "')")
		end
	elseif string.sub(cmd, 1, 9) == "nominate " then
		local TargetMap = string.sub(cmd, 10)
		MapNominate(ply, nil, {TargetMap})
	elseif string.sub(cmd, 1, 5) == "tele " or string.sub(cmd, 1, 5) == "tpto " then
		if ply.HopMode == MODE_PRACTICE then
			if ply.TeleportCooldown and CurTime() - ply.TeleportCooldown < 60 then
				SendMessage(ply, MSG_ID["BhopMsg"], {"You can only teleport once every 60 seconds. Please wait " .. math.ceil(60 - (CurTime() - ply.TeleportCooldown)) .. " seconds before trying again."})
				return ""
			end
			local Find = Admin:FindPlayers({string.sub(cmd, 6)})
			local To = Find[1]["Players"][1]
			if Find[1]["Count"] > 1 then SendMessage(ply, MSG_ID["BhopMsg"], {"There was more than one player found with " .. string.sub(cmd, 6) .. " in their name. Please narrow down."})
			elseif Find[1]["Count"] == 1 and To:IsValid() then
				if To != ply then
					ply.TeleportCooldown = CurTime()
					ply:SetPos(To:GetPos())
					SendMessage(ply, MSG_ID["Teleported"], {To:Name()})
				else
					SendMessage(ply, MSG_ID["BhopMsg"], {"And what use do you think that has?..."})
				end
			else SendMessage(ply, MSG_ID["BhopMsg"], {"No valid players found!"}) end
		else
			SendMessage(ply, MSG_ID["TeleportCooldown"])
		end
	elseif cmd == "tpto" or cmd == "tele" then
		if ply.HopMode == MODE_PRACTICE then
			if not ply.Spectating then
				SendMessage(ply, MSG_ID["BhopMsg"], {"You have to be in spectator to teleport directly to someone."})
				return ""
			end
			local ob = ply:GetObserverTarget()
			if ob then
				local cPos = ob:GetPos()
				DoSpectate(ply)
				timer.Simple(1, function() if ply.HopMode == MODE_PACTICE then ply:SetPos(cPos) SendMessage(ply, MSG_ID["BhopMsg"], {"You have been teleported to your spectator location!"}) end end)
				return ""
			end
		else
			SendMessage(ply, MSG_ID["TeleportCooldown"])
		end
	elseif cmd == "spawn" then
		if ply.Spectating and ply.HopMode == MODE_PRACTICE then
			local cPos = ply:GetPos() - Vector(0, 0, 50)
			DoSpectate(ply)
			timer.Simple(1, function() if ply.HopMode == MODE_PRACTICE then ply:SetPos(cPos) SendMessage(ply, MSG_ID["BhopMsg"], {"You have been teleported to your spectator location!"}) end end)
		else
			SendMessage(ply, MSG_ID["BhopMsg"], {"You have to be in spectator AND practice mode to use this command!"})
		end
	elseif cmd == "spec" or cmd == "spectate" then
		if not ply.Spectating then
			ply:SendLua("Derma_Query('Start Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
		else
			ply:SendLua("Derma_Query('Stop Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
		end
	elseif cmd == "botindex" then
		SendMessage(ply, MSG_ID["BhopMsg"], {"Bot: " .. (Bot.PlaybackFrame .. " / " .. Bot.RunnerFrames)})
		if ply:IsAdmin() then
			SendMessage(ply, MSG_ID["AdminMsg"], {"MEM: " .. collectgarbage("count") * 1024 .. " kB"})
		end
	else
		return text
	end
	
	return ""
end

---------------------------
-- KEY/FUNCTION HOOKS --
---------------------------

function GM:ShowHelp(ply)
	ply:SendLua("SetActiveWindow('Help')")
end

function GM:ShowTeam(ply)
	if not ply.Spectating then
		ply:SendLua("Derma_Query('Start Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
	else
		ply:SendLua("Derma_Query('Stop Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
	end
end

function GM:ShowSpare1(ply)
	if ply.Spectating then return end
	ply.ThirdPerson = 1 - ply.ThirdPerson
	ply:SendLua("ThirdPerson = " .. ply.ThirdPerson)
end

--------------------------
-- CONSOLE COMMANDS --
--------------------------

function RestartMap(ply, cmd, args)
	if ply:Team() != TEAM_SPECTATOR then
		ply:ResetTimer()
		ply:KillSilent()
		ply:Spawn()
		ply:SendLua("StopTimer(0)")
	end
end
concommand.Add("bhop_restart", RestartMap)

function DoSpectate(ply, cmd, args)
	if ply.Spectating then
		Spectator:End(ply)
		ply.Spectating = false
		ply:SetTeam(TEAM_HOP)
		RestartMap(ply)
	else
		ply:SendLua("StopTimer(0)")
		ply:SendLua("ClearSpec()")
		ply.Spectating = true
		GAMEMODE:PlayerSpawnAsSpectator(ply)
		ply:SetTeam(TEAM_SPECTATOR)
		
		local ar = GetAlivePlayers()
		if #ar == 0 then
			ply.SpectateType = #Spectator.Modes
			Spectator:Mode(ply, true)
		else
			ply.SpectateType = 1
			if not ply.SpectateID then ply.SpectateID = 1 end
			if not ar[ply.SpectateID] then ply.SpectateID = 1 end
			ply:Spectate(OBS_MODE_IN_EYE)
			ply:SpectateEntity(ar[ply.SpectateID])
			Spectator:Checks(ply)
		end
	end
end
concommand.Add("bhop_spectate", DoSpectate)

function ChangeMode(ply, cmd, args)
	if not args[1] then return end
	if tonumber(args[1]) == ply.HopMode then return end
	if ply.NominateLimit then
		if CurTime() - ply.NominateLimit < 5 then SendMessage(ply, MSG_ID["BhopMsg"], {"Please wait 5 seconds before changing bhop modes."}) return end
		ply.NominateLimit = CurTime()
	else
		ply.NominateLimit = CurTime()
	end
	
	local ToMode = tonumber(args[1]) or MODE_NORMAL
	ply.HopMode = ToMode
	GAMEMODE:ReloadMode(ply)
end
concommand.Add("bhop_mode", ChangeMode)

function MapNominate(ply, cmd, args)
	if not args[1] then return end
	if not globalMapData[args[1]] then return end
	if args[1] == game.GetMap() then return end
	if ply.NominateLimit then
		if CurTime() - ply.NominateLimit < 5 then SendMessage(ply, MSG_ID["BhopMsg"], {"Please wait 5 seconds before nominating a different map."}) return end
		ply.NominateLimit = CurTime()
	else
		ply.NominateLimit = CurTime()
	end
	
	local name = args[1]
	if ply.NominatedMap and ply.NominatedMap == name then
		SendMessage(ply, MSG_ID["AlreadyNominate"], nil)
		return
	end	
	if ply.NominatedMap then
		SendGlobalMessage(MSG_ID["NominateChange"], {ply:Nick(), ply.NominatedMap, name})
		ply.NominatedMap = name
	else
		ply.NominatedMap = name
		SendGlobalMessage(MSG_ID["Nominate"], {ply:Nick(), ply.NominatedMap})
	end
end
concommand.Add("rtv_nominate", MapNominate)

function MapVote(ply, cmd, args)
	if not args[1] or not RTV.Votable then return end
	if not args[2] then
		local Vote = tonumber(args[1])
		if not Vote or Vote < 1 or Vote > 6 then return end
		if Vote == 6 and not RTV.Extendable then SendMessage(ply, MSG_ID["ExtendLimit"], {RTV.ExtendTime}) return end
		
		RTV.MapVoteList[Vote] = RTV.MapVoteList[Vote] + 1
		SendGlobalData(DATA_ID["Votes"], RTV.MapVoteList)
	else
		local Vote = tonumber(args[1])
		local Previous = tonumber(args[2])
		if not Vote or not Previous or Vote < 1 or Vote > 6 or Previous < 1 or Previous > 6 then return end
		if Vote == 6 and not RTV.Extendable then
			SendMessage(ply, MSG_ID["ExtendLimit"], {RTV.ExtendTime})
		else
			RTV.MapVoteList[Vote] = RTV.MapVoteList[Vote] + 1
		end

		RTV.MapVoteList[Previous] = RTV.MapVoteList[Previous] - 1
		if RTV.MapVoteList[Previous] < 0 then RTV.MapVoteList[Previous] = 0 end
		
		SendGlobalData(DATA_ID["Votes"], RTV.MapVoteList)
	end
end
concommand.Add("rtv_vote", MapVote)

function AFKKicker(ply, cmd, args)
	ply:Kick("You have been AFK for too long!")
end
concommand.Add("bhop_afk", AFKKicker)