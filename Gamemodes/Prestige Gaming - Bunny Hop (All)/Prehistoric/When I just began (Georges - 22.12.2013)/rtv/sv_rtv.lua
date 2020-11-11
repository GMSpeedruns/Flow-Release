-- This code was made a long time ago. Beware!

util.AddNetworkString("rtv_mapslist")

local added = 0

local maps = {}
local mapVotes = {0, 0, 0, 0, 0}
local shouldvote = false
local starttime = 0

local Total_Votes = 0

local mt = FindMetaTable( "Player" )

local IsTTT = false
local ShouldChangeMap = false

local themaplist = {}

local tomap = "[error]" -- this will be overwritten, don't worry.

hook.Add( "Initialize", "TTT RTV Init", function( )

	timer.Simple(7200,function() chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] Map vote starting!") START_RTV() end)
	starttime = CurTime()
	
	if string.find( string.lower( gmod.GetGamemode().Name ), "trouble in terrorist" ) then
		IsTTT = true
		MsgN( "The gamemode has been detected as Trouble In Terrorist Town, enabling wait-period for RTV." )
	end

end )

local function tellall( text )

	if !text then return end

	for k,v in pairs( player.GetAll() ) do
		umsg.Start( "RTV_Msg", v )
		umsg.String( text )
		umsg.End()
	end

end

hook.Add( "TTTEndRound", "TTT RTV Change", function( )

	if ShouldChangeMap then
		tellall( "Changing the map to "..tomap.." in 5 seconds!" )

		timer.Simple( 15, function()
			RunConsoleCommand( "changelevel", tomap )
		end)
	end

end )

function mt:rtv_tell( text )

	if not text then return end

	umsg.Start( "RTV_Msg", self )
	umsg.String( text )
	umsg.End()

end

local function Vote( ply, cmd, args )

	if ply.RTVoted then ply:rtv_tell( "You have already voted!" ) return end
	if not shouldvote then ply:rtv_tell( "Voting is over!" ) return end

	ply.RTVoted = true

	local option = tonumber(args[1])
	if not option then return end
	if option < 1 or option > 5 then return end

	mapVotes[option] = mapVotes[option] + 1
	for key,value in pairs( player.GetAll() ) do
		umsg.Start( "RTV_MapVotes", value )
		for i = 1, 5 do
			umsg.Char(mapVotes[i])
		end
		umsg.End()
	end
end
concommand.Add( "rtv_vote", Vote )

local function VoteChange( ply, cmd, args )

	if not shouldvote then ply:rtv_tell( "Voting is over!" ) return end

	ply.RTVoted = true

	local oldVote = tonumber(args[1])
	local newVote = tonumber(args[2])
	
	if not newVote then return end
	if newVote < 1 or newVote > 5 then return end

	mapVotes[oldVote] = mapVotes[oldVote] - 1
	if mapVotes[oldVote] < 0 then mapVotes[oldVote] = 0 end
	mapVotes[newVote] = mapVotes[newVote] + 1
	for key,value in pairs( player.GetAll() ) do
		umsg.Start( "RTV_MapVotes", value )
		for i = 1, 5 do
			umsg.Char(mapVotes[i])
		end
		umsg.End()
	end
end
concommand.Add( "rtv_changevote", VoteChange )

local function rtvresults()

	local highestnum = 0
	local winner = -1

	for i = 1, 5 do
		if mapVotes[i] > highestnum then
			highestnum = mapVotes[i]
			winner = i
		end
	end

	if winner < 0 then
		MsgN( "No map votes." )
		winner = math.random(1, 5)
	end

	local map = maps[winner]
	local mapname = string.Replace( map, ".bsp", "" )

	if IsTTT then
		tellall( "Changing the map to "..mapname.." after the current round!" )
		tomap = mapname
		ShouldChangeMap = true
	else
		tellall( "Changing the map to "..mapname.." now!" )
		if not mapname then ServerLog( "No map name!" ) return end
		timer.Simple(3, function() RunConsoleCommand( "changelevel", mapname ) end)
	end

end

function START_RTV() -- This is global incase you want to call it for map voting inside your gamemode or some other script.

	if shouldvote then return end

	shouldvote = true
	
	local nominations = {}
	for k, v in pairs(player.GetAll()) do
		if(v.nominated) then
			table.insert(nominations,v.nominated..".bsp")
		end
	end
	
	for k,v in RandomPairs(nominations) do
		if added >= 3 then MsgN( "[RTV] Breaking nominated loop, map table sent!" ) break end
		if(table.HasValue(maps, v)) then continue end
		if string.gsub( v, ".bsp", "" ) != game.GetMap() then
			added = added + 1
			table.insert( maps, v )
			MsgN( "[RTV] Added "..v )
		end
	end

	for k, v in RandomPairs( GAMEMODE:GetMapList() ) do
		if added >= 5 then MsgN( "[RTV] Breaking loop, map table sent!" ) break end
		if(table.HasValue(maps, v)) then continue end
		if (v != game.GetMap()..".bsp") then
			added = added + 1
			table.insert( maps, v )
			MsgN( "[RTV] Added "..v )
		end
	end
	
	for key,value in pairs( player.GetAll() ) do
		for k,v in pairs( maps ) do
			umsg.Start( "RTV_AddMaps", value )
			umsg.String( v )
			umsg.End()
		end
	end

	timer.Simple( 1, function() 
		for k,v in pairs( player.GetAll() ) do
			umsg.Start( "StartRTV", v )
			umsg.End()
			v.RTVoted = false
		end
	end )

	timer.Simple( 31, function() 
		rtvresults()
	end )

end

local function RTVNom (ply,cmd,args)
	local index = args[1]
	local contains = false
	for k,v in pairs(themaplist) do
		if v[1] == index then
			contains = true
			break
		end
	end
	if not contains then return end
	if(ply.nominated) then
		local old = ply.nominated
		ply.nominated = string.gsub(index,".bsp","")
		ply:rtv_tell("You have changed your nomination from "..old.." to "..ply.nominated)
		for k,v in pairs(player.GetAll()) do
			if(v != ply) then
				v:rtv_tell(ply:Nick().." has changed his nomination from "..old.." to "..ply.nominated)
			end
		end
	else
		ply.nominated = string.gsub(index,".bsp","")
		ply:rtv_tell("You have nominated "..ply.nominated)
		for k,v in pairs(player.GetAll()) do
			if(v != ply) then
				v:rtv_tell(ply:Nick().." has nominated "..ply.nominated)
			end
		end
	end
end
concommand.Add( "rtv_nominate", RTVNom )

local function StartRTV( ply )

	if shouldvote then
		ply:rtv_tell( "You cannot vote to Rock the Vote at this time!" )
		return
	end

	if ply.Rocked then
		ply:rtv_tell( "You have already voted to Rock the Vote!" )
		return
	end

	ply.Rocked = true

	Total_Votes = Total_Votes + 1

	tellall( ply:Nick().." has voted to Rock the Vote! ("..math.ceil( #player.GetAll() * 0.66 ) - Total_Votes.." more needed)" )

	if Total_Votes >= math.ceil( #player.GetAll() * 0.66 ) then
		tellall( "A vote to change the map has started!" )
		START_RTV()
	end

end
concommand.Add( "rtv_start", StartRTV )

local function RemoveVotes( ply )

	if ply.Rocked then
		Total_Votes = Total_Votes - 1
	end

	timer.Simple( 1, function() -- We don't want to get the amount of players when the guy who's leaving is still here... lol
		if #player.GetAll() < 1 then return end
		if not shouldvote then
			if Total_Votes >= math.ceil( #player.GetAll() * 0.66 ) then
				tellall( "A vote to change the map has started!" )
				START_RTV()
			end
		end
	end )

end
hook.Add( "PlayerDisconnected", "RTV_RemoveVotes", RemoveVotes )

local function RTV_Chat( ply, text )

	local small = string.lower( text )

	if small == "!rtv" or small == "rtv" or small == "/rtv" then
		ply:ConCommand( "rtv_start" )
		return ""
	end
	
	if small == "!timeleft" or small == "timeleft" or small == "/timeleft" then
		ply:ConCommand( "bh_timeleft" )
		return ""
	end
	
	if small == "!nominate" or small == "nominate" or small == "/nominate" then
		umsg.Start( "NominateM", ply )
		umsg.End()
		return ""
	end

end
hook.Add( "PlayerSay", "RTV_PlayerSay", RTV_Chat )

function timeleft(ply,cmd,args)
	ply:SendLua("bh_timeleft("..(starttime+7200)-CurTime()..")")
end
concommand.Add("bh_timeleft", timeleft)

local firstjoin = true

local function PointlessHook( ply )

	if(firstjoin) then
		i = 1
		for k,v in pairs(GAMEMODE:GetMapListP()) do
			if string.gsub(v[1],".bsp","") != game.GetMap() then
				themaplist[i] = {v[1], v[2]}
				i = i + 1
				continue
			end
		end
		
		firstjoin = false
	end

	ply.Rocked = false

	timer.Simple( 5, function()
		net.Start("rtv_mapslist")
		net.WriteTable(themaplist)
		net.Send(ply)
	end)

end
hook.Add( "PlayerInitialSpawn", "RTV_Joined", PointlessHook )