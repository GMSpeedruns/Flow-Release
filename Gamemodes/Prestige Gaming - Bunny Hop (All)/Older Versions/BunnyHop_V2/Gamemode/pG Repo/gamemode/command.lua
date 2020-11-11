-----------------------------
-- MAIN FUNCTIONS/HOOKS --
-----------------------------

local function ProcessPlayerCommand(ply, text)
	local s = string.sub(text, 0, 1)
	local cmd = ""
	if s != "!" and s != "/" and text != "rtv" then return else cmd = string.lower(string.gsub(string.gsub(text, "!", ""), "/", "")) end

	if cmd == "r" or cmd == "restart" then
		RestartMap(ply)
	elseif cmd == "store" then
		ply:SendMessage(MSG_BHOP_GENERAL, {"Store has temporarily been disabled! It will be back soon!"})
	elseif cmd == "wr" or cmd == "records" then
		ply:SendLua("ShowWR()")
	elseif cmd == "mode" or cmd == "style" then
		ply:SendLua("ShowModes()")
	elseif cmd == "help" or cmd == "commands" then
		ply:SendLua("ShowHelp()")
	elseif cmd == "rtv" or cmd == "vote" then
		ply:Rock()
	elseif cmd == "nominate" then
		ply:SendLua("ShowNominate()")
	elseif cmd == "maps" or cmd == "left" or cmd == "mapsleft" then
		local HopMode = ply.HopMode > MODE_WONLY and MODE_NORMAL or ply.HopMode
		if not ply.HasBeatList then
			ply:SendData(NET_MAPSLEFT, sql.Query("SELECT map_name, time" .. HopMode .. " AS time FROM playerrecords WHERE unique_id='" .. ply:UniqueID() .. "' ORDER BY map_name ASC") or {})
			ply.HasBeatList = true
		else
			ply:SendLua("ShowLeft()")
		end
	elseif cmd == "beat" or cmd == "mapsbeat" then
		local HopMode = ply.HopMode > MODE_WONLY and MODE_NORMAL or ply.HopMode
		if not ply.HasBeatList then
			ply:SendData(NET_MAPSBEAT, sql.Query("SELECT map_name, time" .. HopMode .. " AS time FROM playerrecords WHERE unique_id='" .. ply:UniqueID() .. "' ORDER BY map_name ASC") or {})
			ply.HasBeatList = true
		else
			ply:SendLua("ShowBeat()")
		end
	elseif cmd == "rank" then
		ply:SendLua("ShowRank(" .. ply.RankID .. ", " .. ply.RankPoints .. ")")
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
	elseif cmd == "top" or cmd == "toplist" or cmd == "best" then
		if not ply.HasTopList then
			ply:SendData(NET_TOPLIST, currentTopPlayers)
			ply.HasTopList = true
		else
			ply:SendLua("ShowTop()")
		end
	elseif string.sub(cmd, 1, 5) == "tele " or string.sub(cmd, 1, 5) == "tpto " then
		if ply.HopMode == MODE_TELEPORT then
			if ply.CMDCooldown and CurTime() - ply.CMDCooldown < 60 then ply:SendMessage(MSG_BHOP_GENERAL, {"You can only teleport once every 60 seconds."}) return "" end
			ply.CMDCooldown = CurTime()
			local target = ADMIN:FindPlayers(string.sub(cmd, 6), true)
			if target then
				ply:SetPos(target:GetPos())
				ply:SendMessage(MSG_TXT_TPTO, {target:Name()})
			else
				ply:SendMessage(MSG_BHOP_GENERAL, {"No player with '" .. string.sub(cmd, 6) .. "' in their name was found!"})
			end
		else
			ply:SendMessage(MSG_TXT_TPCMD, nil)
		end
	elseif cmd == "nowep" or cmd == "noweapons" or cmd == "remove" or cmd == "stripweapons" then
		ply:StripWeapons()
		ply:SendLua("ShowGun(2)")
	elseif cmd == "usp" or cmd == "glock" or cmd == "knife" then
		local FoundWeapon = false
		for k,v in pairs(ply:GetWeapons()) do
			if v:GetClass() == "weapon_" .. cmd then
				FoundWeapon = true
				break
			end
		end
		if not FoundWeapon then
			ply:SetActiveWeapon(ply:Give("weapon_" .. cmd))
			ply:SendLua("ShowGun(1, '" .. cmd .. "')")
		else
			ply:SendLua("ShowGun(0, '" .. cmd .. "')")
		end
	elseif cmd == "show" or cmd == "showplayers" then
		ply:SendLua("SetCV(3, 1)")
	elseif cmd == "hide" or cmd == "hideplayers" then
		ply:SendLua("SetCV(3, 0)")
	elseif cmd == "showhud" or cmd == "showgui" then
		ply:SendLua("SetCV(1, 1)")
	elseif cmd == "hidehud" or cmd == "hidegui" then
		ply:SendLua("SetCV(1, 0)")
	elseif cmd == "showspec" then
		ply:SendLua("SetCV(2, 1)")
	elseif cmd == "hidespec" then
		ply:SendLua("SetCV(2, 0)")
	elseif cmd == "hud" or cmd == "dignhud" or cmd == "changehud" or cmd == "gui" then
		ply:SendLua("SetCV(4, 0)")
	elseif cmd == "mili" or cmd == "precision" or cmd == "timeprecision" then
		ply:SendLua("SetCV(5, 0)")
	elseif cmd == "timeleft" or cmd == "time" then
		ply:SendLua("ShowTime(" .. 7200 - (CurTime() - MapInit) .. ")")
	elseif cmd == "spec" or cmd == "spectate" then
		if not ply.Spectating then
			ply:SendLua("Derma_Query('Start Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
		else
			ply:SendLua("Derma_Query('Stop Spectating?','Spectator','Yes',function() RunConsoleCommand('bhop_spectate') end,'No',function() end)")
		end
	elseif cmd == "auto" then
		ChangeMode(ply, nil, {MODE_AUTO})
	elseif cmd == "normal" or cmd == "scroll" then
		ChangeMode(ply, nil, {MODE_NORMAL})
	elseif cmd == "wonly" or cmd == "w" then
		ChangeMode(ply, nil, {MODE_WONLY})
	elseif cmd == "sideways" or cmd == "sw" then
		ChangeMode(ply, nil, {MODE_SIDEWAYS})
	elseif cmd == "admincp" then
		if ADMIN:HasAccess(ply) then
			ply:SendLua("ShowAdmin()")
			return ""
		end
		return text
	else
		return
	end
	
	return ""
end
hook.Add("PlayerSay", "ProcessCommand", ProcessPlayerCommand)

---------------------------
-- KEY/FUNCTION HOOKS --
---------------------------

function GM:ShowHelp(ply)
	ply:SendLua("ShowHelp()")
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
		ply:Spawn()
		ply:SendLua("StopTimer(0)")
	end
end
concommand.Add("bhop_restart", RestartMap)

function DoSpectate(ply, cmd, args)
	if ply.Spectating then
		ply.Spectating = false
		ply:SetTeam(TEAM_HOP)
		RestartMap(ply)
		SpectateEnd(ply)
		ply:SendData(NET_SPECDATA, {})
	else
		ply:SendLua("StopTimer(0)")
		ply.Recorded = false
		ply.Spectating = true
		GAMEMODE:PlayerSpawnAsSpectator(ply)
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Spectate(OBS_MODE_IN_EYE)
		ply:SendData(NET_SPECDATA, {})
		
		local tm = GetAlivePlayers()
		if #tm == 0 then return end
		if not ply.SpectateID then ply.SpectateID = 1 end
		if not tm[ply.SpectateID] then ply.SpectateID = 1 end
		ply:SpectateEntity(tm[ply.SpectateID])
		ply.CurrentObserved = tm[ply.SpectateID]:UniqueID()
		SpectateChecks(ply)
	end
end
concommand.Add("bhop_spectate", DoSpectate)

function ChangeMode(ply, cmd, args)
	if not args[1] then return end
	local ToMode = tonumber(args[1]) or MODE_NORMAL
	ply.HopMode = ToMode
	ply.CurrentRecord = 0
	
	if ply.HopMode == MODE_AUTO then
		local data = sql.Query("SELECT * FROM playerauto WHERE map_name = '" .. game.GetMap() .. "' AND unique_id = '" .. ply:UniqueID() .. "'")
		if data then
			ply.CurrentRecord = tonumber(data[1]["time"])
		end
	elseif ply.HopMode != MODE_TELEPORT then
		local data = sql.Query("SELECT * FROM playerrecords WHERE map_name = '" .. game.GetMap() .. "' AND unique_id = '" .. ply:UniqueID() .. "'")
		if data then
			ply.CurrentRecord = tonumber(data[1]["time" .. ply.HopMode])
		end
	end
	
	ply:SendLua("SetMode(" .. ply.HopMode .. "," .. ply.CurrentRecord .. ")")
	ply:SetNWInt("BhopType", ply.HopMode)
	ply:SetNWInt("BhopRec", ply.CurrentRecord)
	
	RestartMap(ply)
end
concommand.Add("bhop_setmode", ChangeMode)

function MapNominate(ply, cmd, args)
	if not args[1] then return end
	if not globalMapData[args[1]] then return end
	if args[1] == game.GetMap() then return end
	
	local name = args[1]
	if ply.NominatedMap and ply.NominatedMap == name then
		ply:SendMessage(MSG_RTV_ALNOM, nil)
		return
	end	
	if ply.NominatedMap then
		SendGlobalMessage(MSG_RTV_NOMCHG, {ply:Nick(), ply.NominatedMap, name})
		ply.NominatedMap = name
	else
		ply.NominatedMap = name
		SendGlobalMessage(MSG_RTV_NOMSET, {ply:Nick(), ply.NominatedMap})
	end
end
concommand.Add("rtv_nominate", MapNominate)

function MapVote(ply, cmd, args)
	if not args[1] or not Votable then return end
	if not args[2] then
		local New = tonumber(args[1])
		if not New or New < 1 or New > 5 then return end
		
		MapVoteList[New] = MapVoteList[New] + 1
		SendGlobalData(NET_RTVVOTES, MapVoteList)
	else
		local Old = tonumber(args[1])
		local New = tonumber(args[2])
		if not New or not Old or New < 1 or New > 5 or Old < 1 or Old > 5 then return end
		
		MapVoteList[Old] = MapVoteList[Old] - 1
		MapVoteList[New] = MapVoteList[New] + 1
		if MapVoteList[Old] < 0 then MapVoteList[Old] = 0 end
		SendGlobalData(NET_RTVVOTES, MapVoteList)
	end
end
concommand.Add("rtv_vote", MapVote)

function AFKKickPlayer(ply, cmd, args)
	ply:Kick("You have been AFK for too long!")
end
concommand.Add("afk_kickplayer", AFKKickPlayer)

function AdminCommand(ply, cmd, args)
	if not args[1] or not tonumber(args[1]) then return end
	if not ADMIN:HasAccess(ply) then return end
	local ID = tonumber(args[1])
	local DataNum = args[2]
	local DataStr = tostring(DataNum)
	
	if ID == 100 then -- [MAP] Reload map data
		LoadMapTriggers()
		ply:SendMessage(MSG_ADMIN_GENERAL, {"Map data has been reloaded!"})
	elseif ID == 200 then -- [MAP] Area editor: Add new area
		if not DataNum or not tonumber(DataNum) or not args[3] or not args[4] then return end
		local AreaID = tonumber(DataNum)
		local Vec1, Vec2 = ToVector(args[3]), ToVector(args[4])
		if not Vec1 or not Vec2 or AreaID < AREA_START or AreaID > AREA_END then
			ply:SendMessage(MSG_ADMIN_GENERAL, {"Invalid vectors/data received!"})
			return
		end
		
		ADMIN:AreaAddNew(ply, game.GetMap(), AreaID, Vec1, Vec2)
	elseif ID == 201 then -- [MAP] Area editor: Remove area
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 202 then -- [MAP] Area editor: Edit area
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 203 then -- [MAP] Specials editor: Add new special
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 204 then -- [MAP] Specials editor: Remove special
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 205 then -- [MAP] Specials editor: Edit special
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 206 then -- [MAP] Set Points
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 300 then -- [MAP] Manage times
		PLAYER_RTV_TIME = 0
		ply:SendMessage(MSG_ADMIN_GENERAL, {"Player RTV Time has been set to 0"})
	elseif ID == 400 then -- [MAP] Change map
		if not DataNum or string.len(DataStr) < 4 then return end
		SendGlobalMessage(MSG_RTV_MAP, {DataStr})
		timer.Simple(5, function() RunConsoleCommand("changelevel", DataStr) end)
	elseif ID == 500 then -- [PLY] Manage times: Add time
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 501 then -- [PLY] Manage times: Remove time
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 502 then -- [PLY] Manage times: Edit time
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	elseif ID == 600 then -- [PLY] Teleport
		if not DataNum or string.len(DataStr) < 4 or not args[3] or string.len(tostring(args[3])) < 4 then return end
		local Players1 = ADMIN:FindPlayers(DataStr)
		local Players2 = ADMIN:FindPlayers(tostring(args[3]))
		if #Players1 > 1 or #Players2 > 1 then
			ply:SendMessage(MSG_ADMIN_GENERAL, {"More than one player with '" .. DataStr .. "' or '" .. tostring(args[3]) .. "' in their name!"})
		elseif #Players1 == 1 and #Players2 == 1 then
			Players1[1]:SetPos(Players2[1]:GetPos())
			ply:SendMessage(MSG_ADMIN_GENERAL, {Players1[1]:Name() .. " has been teleported to " .. Players2[1]:Name()})
		else
			ply:SendMessage(MSG_ADMIN_GENERAL, {"No players found with '" .. DataStr .. "' or '" .. tostring(args[3]) .. "' in their name!"})
		end
	elseif ID == 700 then -- [PLY] Unstuck
		if not DataNum or string.len(DataStr) < 4 then return end
		local Players = ADMIN:FindPlayers(DataStr)
		if #Players > 1 then
			ply:SendMessage(MSG_ADMIN_GENERAL, {"More than one player with '" .. DataStr .. "' in their name!"})
		elseif #Players == 1 then
			ply:SendMessage(MSG_ADMIN_GENERAL, {"Attempting to unstuck " .. Players[1]:Name() .. "!"})
			ADMIN:Unstuck(ply, Players[1])
		else
			ply:SendMessage(MSG_ADMIN_GENERAL, {"No players found with '" .. DataStr .. "' in their name!"})
		end
	elseif ID == 800 then -- [BOT] Enable bot
		if DisableRecording then
			DisableRecording = false
			ply:SendMessage(MSG_ADMIN_GENERAL, {"The bot is now recording again!"})
		else
			ply:SendMessage(MSG_ADMIN_GENERAL, {"The bot is already enabled!"})
		end
	elseif ID == 801 then -- [BOT] Disable bot
		if not DisableRecording then
			DisableRecording = true
			ply:SendMessage(MSG_ADMIN_GENERAL, {"The bot is no longer recording!"})
		else
			ply:SendMessage(MSG_ADMIN_GENERAL, {"The bot is already disabled!"})
		end
	elseif ID == 802 then -- [BOT] Override record
		if not DataNum or string.len(DataStr) < 4 or not tonumber(args[3]) then return end
		local Players = ADMIN:FindPlayers(DataStr)
		if #Players > 1 then
			ply:SendMessage(MSG_ADMIN_GENERAL, {"More than one player with '" .. DataStr .. "' in their name!"})
		elseif #Players == 1 then
			if not Players[1].BotOverride then
				Players[1].BotOverride = true
				Players[1].BotMinimum = tonumber(args[3])
				ply:SendMessage(MSG_ADMIN_GENERAL, {Players[1]:Name() .. " is now being recorded on a minimum run of " .. Players[1].BotMinimum})
			else
				Players[1].BotOverride = nil
				Players[1].BotMinimum = nil
				ply:SendMessage(MSG_ADMIN_GENERAL, {Players[1]:Name() .. " is no longer being recorded."})
			end
		else
			ply:SendMessage(MSG_ADMIN_GENERAL, {"No players found with '" .. DataStr .. "' in their name!"})
		end
	elseif ID == 803 then -- [BOT] Toggle autohop recording
		if not BotAutoAllowed then
			BotAutoAllowed = true
			ply:SendMessage(MSG_ADMIN_GENERAL, {"Auto runs will now be recorded!"})
		else
			BotAutoAllowed = false
			ply:SendMessage(MSG_ADMIN_GENERAL, {"Auto runs are no longer recored!"})
		end
	end
end
concommand.Add("acp_runcmd", AdminCommand)