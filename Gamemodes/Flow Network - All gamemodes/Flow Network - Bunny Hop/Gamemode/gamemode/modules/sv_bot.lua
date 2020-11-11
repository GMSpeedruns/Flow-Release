-- If your desire is to only use this module, please leave credits somewhere in your gamemode.

Bot = {}
Bot.RecordAll = false -- Set this to true if you have a really good server; it'll record everyone, always, unless they type !bot remove
Bot.AlwaysDisplayFirst = false -- If you set this to true as well, they can't even use !bot remove, thus the bot will always display the best time (ONLY EFFECTIVE if Bot.RecordAll is set to true)
Bot.Maximum = Bot.RecordAll and 64 or 9
Bot.MinimumTime = 90

local BotPlayer = {}
local BotFrame = {}
local BotFrames = {}
local BotData = {}
local BotInfo = {}

local Queue = {}
local Players = {}
local Recording = {}
local Frame = {}
local Active = {}

local ct = CurTime


-- Initialization and control
function Bot:Setup()
	BotPlayer = {}
	BotFrame = {}
	BotFrames = {}
	BotInfo = {}
	BotData = {}

	if not file.Exists( _C.GameType .. "/bots/revisions", "DATA" ) then
		file.CreateDir( _C.GameType .. "/bots/revisions" )
	end
	
	Bot.PerStyle = {}
	Bot:LoadData()
end

function Bot:LoadData()
	local Result = sql.Query( "SELECT * FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' ORDER BY nStyle ASC" )
	if Core:Assert( Result, "nTime" ) then
		for _,Info in pairs( Result ) do
			local name = _C.GameType .. "/bots/bot_" .. game.GetMap()
			local style = tonumber( Info["nStyle"] )
			
			if style != _C.Style.Normal then
				name = name .. "_" .. style .. ".txt"
			else
				name = name .. ".txt"
			end
			
			local RawData = file.Read( name, "DATA" )
			if not RawData or RawData == "" then continue end
			local RunData = util.Decompress( RawData )
			if not RunData then continue end
			
			BotData[ style ] = util.JSONToTable( RunData )
			BotFrame[ style ] = 1
			BotFrames[ style ] = #BotData[ style ][ 1 ]
			BotInfo[ style ] = { Name = Info["szPlayer"], Time = tonumber( Info["nTime"] ), Style = style, SteamID = Info["szSteam"], Date = Info["szDate"], Saved = true, Start = ct(), CompletedRun = true }
		end
	end
end

function Bot:EndRun( ply, nTime, nRank )
	if not IsValid( ply ) or not Bot:IsRecorded( ply ) then return end
	if not Players[ ply ] or not Recording[ ply ] or #Recording[ ply ][ 1 ] == 0 then return end
	if (not ply.Tn and not ply.Tb) or (not ply.TnF and not ply.TbF) or not ply.BotFull then return end
	
	local style = ply.Style
	if BotInfo[ style ] and BotInfo[ style ].Time and nTime >= BotInfo[ style ].Time then
		return Core:Send( ply, "Print", { "Bhop Timer", Lang:Get( "BotSlow", { Timer:Convert( nTime - BotInfo[ style ].Time ) } ) } )
	end
	
	Core:Broadcast( "Print", { "General", Lang:Get( "BotDisplay", { Core:StyleName( style ), ply:Name(), "#" .. nRank, Timer:Convert( nTime ) } ) } )
	
	BotData[ style ] = Recording[ ply ]
	BotFrame[ style ] = 1
	BotFrames[ style ] = #BotData[ style ][ 1 ]
	BotInfo[ style ] = { Name = ply:Name(), Time = nTime, Style = ply.Style, SteamID = ply:SteamID(), Date = os.date( "%Y-%m-%d %H:%M:%S", os.time() ), Saved = false, Start = ct() }
	
	Bot:SetMultiBot( style )
end

function Bot:ClearStyle( nStyle )
	BotFrame[ nStyle ] = nil
	BotFrames[ nStyle ] = nil
	BotData[ nStyle ] = nil
	BotInfo[ nStyle ] = nil
end

function Bot:SetMultiBot( nStyle )
	local target = nil
	for _,bot in pairs( player.GetBots() ) do
		if nStyle == _C.Style.Normal then
			if bot.Style == _C.Style.Normal and not bot.Temporary then
				target = bot
				break
			end
		else
			if bot.Style != _C.Style.Normal and not bot.Temporary then
				target = bot
				break
			end
		end
	end
	
	if IsValid( target ) then
		target.Style = nStyle
		Bot:SetInfo( target, nStyle, true )
		BotFrame[ nStyle ] = 1
		BotInfo[ nStyle ].CompletedRun = nil
		BotPlayer[ target ] = nStyle
		Bot:NotifyRestart( nStyle )
	end
end

function Bot:Spawn( bMulti, nStyle, bNone )
	if not bMulti then
		nStyle = _C.Style.Normal
	end

	for _,bot in pairs( player.GetBots() ) do
		if bot.Temporary then
			bot:SetMoveType( MOVETYPE_NONE )
			bot:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			bot.Style = nStyle
			bot:StripWeapons()
			bot:SetFOV( 90, 0 )
			bot:SetGravity( 0 )
			bot.Temporary = nil
			Bot:SetInfo( bot, nStyle, true )
			
			return true
		end
	end
	
	if #player.GetBots() < 2 then
		Bot.Recent = nStyle
		if bMulti and bNone then
			Bot.Recent = nil
		end
		
		RunConsoleCommand( "bot" )
		timer.Simple( 1, function()
			Bot:Spawn( bMulti, nStyle )
		end )
	end
end

function Bot:CheckStatus()
	if Bot.IsStatusCheck then
		return true
	else
		Bot.IsStatusCheck = true
	end
	
	local nCount = 0
	local bNormal, bMulti
	
	for _,bot in pairs( player.GetBots() ) do
		if bot.Style == _C.Style.Normal then
			bNormal = true
		elseif bot.Style != _C.Style.Normal then
			bMulti = true
		end
		
		nCount = nCount + 1
	end
	
	if nCount < 2 then
		if not bNormal then
			Bot:Spawn()
		end
		
		if not bMulti then
			local nStyle, bSet = 0, true
			for style,_ in pairs( BotData ) do
				if style != _C.Style.Normal then
					nStyle = style
					bSet = nil
					break
				end
			end
			
			Bot.SpawnData = { nStyle, bSet }
			timer.Simple( not bNormal and 2 or 0, function()
				if Bot and Bot.Spawn and Bot.SpawnData then
					Bot:Spawn( true, Bot.SpawnData[ 1 ], Bot.SpawnData[ 2 ] )
				end
			end )
		end
	end
	
	timer.Simple( 5, function()
		Bot.IsStatusCheck = nil
	end )
end

function Bot:Save( bSave )
	if not bSave and #player.GetHumans() > 0 then
		timer.Simple( 1, function() Bot:Save( true ) end )
		return Core:Broadcast( "Print", { "General", Lang:Get( "BotSaving" ) } )
	end
	
	for style,_ in pairs( BotData ) do
		local info = BotInfo[ style ]
		if not info.Saved then
			if not BotData[ style ] or not BotData[ style ][ 1 ] or #BotData[ style ][ 1 ] == 0 or BotFrames[ style ] == 0 then return end
			
			local Exist = sql.Query( "SELECT nTime FROM game_bots WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. info.Style )
			if Core:Assert( Exist, "nTime" ) and tonumber( Exist[ 1 ]["nTime"] ) then
				sql.Query( "UPDATE game_bots SET szPlayer = " .. sql.SQLStr( info.Name ) .. ", nTime = " .. info.Time .. ", szSteam = '" .. info.SteamID .. "', szDate = '" .. info.Date .. "' WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. info.Style )
			else
				sql.Query( "INSERT INTO game_bots VALUES ('" .. game.GetMap() .. "', " .. sql.SQLStr( info.Name ) .. ", " .. info.Time .. ", " .. info.Style .. ", '" .. info.SteamID .. "', '" .. info.Date .. "')" )
			end
			
			local name = _C.GameType .. "/bots/bot_" .. game.GetMap()
			if style != _C.Style.Normal then
				name = name .. "_" .. style
			end
			
			if file.Exists( name .. ".txt", "DATA" ) then
				local find = 1
				local fp = string.gsub( name, "bots/", "bots/revisions/" ) .. "_v"
				
				while file.Exists( fp .. find .. ".txt", "DATA" ) do
					find = find + 1
				end
				
				local existing = file.Read( name .. ".txt", "DATA" )
				file.Write( fp .. find .. ".txt", util.TableToJSON( info ) .. "\n" )
				file.Append( fp .. find .. ".txt", existing )
			end
			
			local RunData = util.Compress( util.TableToJSON( BotData[ style ] ) )
			file.Write( name .. ".txt", RunData )
			
			BotInfo[ style ].Saved = true
		end
	end
end


-- Dynamic player system
function Bot:CountPlayers()
	local count = 0
	
	for d,b in pairs( Players ) do
		if b and IsValid( d ) and d:IsPlayer() then
			count = count + 1
		else
			Players[ d ] = nil
		end
	end
	
	return count
end

function Bot:IsRecorded( ply )
	if Queue[ ply ] then
		Queue[ ply ] = nil
		Players[ ply ] = true
		
		Bot:CleanRecording( ply )
	end

	return Players[ ply ] or false
end

function Bot:AddPlayer( ply, szReason )
	local count = Bot:CountPlayers()
	
	if count < Bot.Maximum then
		if Bot:IsRecorded( ply ) then
			return Core:Send( ply, "Print", { "Notification", Lang:Get( "BotAlready" ) } )
		end
		
		Queue[ ply ] = true
		Core:Send( ply, "Print", { "Notification", Lang:Get( "BotInstRecord", { szReason or "!" } ) } )
	else
		Core:Send( ply, "Print", { "Notification", Lang:Get( "BotInstFull" ) } )
	end
end

function Bot:RemovePlayer( ply )
	if Bot.AlwaysDisplayFirst then
		return Core:Send( ply, "Print", { "Notification", "This server will always record any player online. Removing is not necessary." } )
	end
	
	if Bot:IsRecorded( ply ) then
		Recording[ ply ] = nil
		Frame[ ply ] = nil
		Players[ ply ] = nil
	end
	
	Core:Send( ply, "Print", { "Notification", Lang:Get( "BotClear" ) } )
end

function Bot:ShowStatus( ply )
	Core:Send( ply, "Print", { "Notification", Lang:Get( "BotStatus", { Bot:IsRecorded( ply ) and "being" or "not being" } ) } )
end

function Bot:SetActive( ply, value )
	Active[ ply ] = value
end

function Bot:CleanRecording( ply )
	Recording[ ply ] = {}
	
	for i = 1, 6 do
		Recording[ ply ][ i ] = {}
	end
	
	Frame[ ply ] = 1
end

function Bot:GetMultiStyle()
	for _,bot in pairs( player.GetAll() ) do
		if bot:IsBot() and bot.Style != _C.Style.Normal then
			return bot.Style
		end
	end
	
	return 0
end

function Bot:ChangeMultiBot( nStyle )
	local current = Bot:GetMultiStyle()
	if not Core:IsValidStyle( current ) then return "None" end
	if not Core:IsValidStyle( nStyle ) then return "Invalid" end
	if nStyle == _C.Style.Normal then return "Exclude" end
	if current == nStyle then return "Same" end
	
	if BotInfo[ nStyle ] and BotData[ nStyle ] then
		if BotInfo[ current ].CompletedRun then
			local ply = Bot:GetPlayer( current )
			ply.Style = nStyle
			Bot:SetInfo( ply, nStyle, true )
			BotFrame[ nStyle ] = 1
			BotInfo[ nStyle ].CompletedRun = nil
			BotPlayer[ ply ] = nStyle
			Bot:NotifyRestart( nStyle )
			
			return "The bot is now displaying " .. BotInfo[ nStyle ].Name .. "'s " .. Core:StyleName( BotInfo[ nStyle ].Style ) .. " run!"
		else
			return "Wait"
		end
	else
		return "Error"
	end
end

function Bot:GetMultiBots()
	local tabStyles = {}
	for style,data in pairs( BotData ) do
		if style != _C.Style.Normal then
			table.insert( tabStyles, Core:StyleName( style ) )
		end
	end
	return tabStyles
end

function Bot:SaveBot( ply )
	local bSave = false
	
	for style,data in pairs( BotInfo ) do
		if data.SteamID == ply:SteamID() then
			if not data.Saved then
				bSave = true
				Bot:Save()
				
				break
			end
		end
	end
	
	Core:Send( ply, "Print", { "General", bSave and "Your bot will now be saved!" or "All your bots have already been saved or you have no bots." } )
end


-- Access functions

function Bot:Exists( nStyle )
	return BotFrame[ nStyle ] and BotFrames[ nStyle ] and BotInfo[ nStyle ].Start
end

function Bot:NotifyRestart( nStyle )
	local ply = Bot:GetPlayer( nStyle )
	local info = BotInfo[ nStyle ]
	local bEmpty = false
	
	if IsValid( ply ) and not info then
		bEmpty = true
	elseif not info or not info.Start or not IsValid( ply ) then
		return false
	end
	
	local tab, Watchers = { "Timer", true, nil, "Waiting bot", nil, ct(), "Save" }, {}
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob:IsBot() and ob == ply then
			table.insert( Watchers, p )
		end
	end

	if not bEmpty then
		tab = { "Timer", true, info.Start, info.Name, info.Time, ct(), "Save" }
	end
	
	Core:Send( Watchers, "Spectate", tab )
end

function Bot:GenerateNotify( nStyle, varList )
	if not BotInfo[ nStyle ] or not BotInfo[ nStyle ].Start then return end
	return { "Timer", true, BotInfo[ nStyle ].Start, BotInfo[ nStyle ].Name, BotInfo[ nStyle ].Time, ct(), varList }
end

function Bot:GetPlayer( nStyle )
	for _,ply in pairs( player.GetBots() ) do
		if ply.Style == nStyle and IsValid( ply ) then
			return ply
		end
	end
end

function Bot:SIDToProfile( sid )
	return util.SteamIDTo64( sid )
end

function Bot:GetInfo( nStyle )
	return BotInfo[ nStyle ]
end

function Bot:SetInfoData( nStyle, varData )
	BotInfo[ nStyle ] = varData
end

function Bot:SetInfo( ply, nStyle, bSet )
	local info = BotInfo[ nStyle ]
	if not info then
		ply:SetNWString( "BotName", "Awaiting playback..." )
		ply:SetNWInt( "Style", 0 )
		return false
	elseif info.Style then
		Bot:SetFramePosition( info.Style, 0 )
	end
	
	if info.Start then
		ply:SetNWString( "BotName", info.Name )
		ply:SetNWString( "ProfileURI", Bot:SIDToProfile( info.SteamID ) )
		ply:SetNWFloat( "Record", info.Time )
		ply:SetNWInt( "Style", info.Style )
		ply:SetNWInt( "Rank", -2 )
		
		local pos = Timer:GetRecordID( info.Time, info.Style )
		if pos > 0 then
			ply:SetNWInt( "WRPos", pos )
		else
			ply:SetNWInt( "WRPos", 0 )
		end
		
		Bot.PerStyle[ info.Style ] = pos
	end
	
	if bSet then
		BotInfo[ nStyle ].Start = ct()
		Bot.Initialized = true
		BotPlayer[ ply ] = nStyle
	end
end

function Bot:SetWRPosition( nStyle )
	local ply = Bot:GetPlayer( nStyle )
	if not IsValid( ply ) then return end
	
	local info = BotInfo[ nStyle ]
	if not info then
		ply:SetNWString( "BotName", "Awaiting playback..." )
		ply:SetNWInt( "Style", 0 )
		return false
	end
	
	if info.Start then
		local pos = Timer:GetRecordID( info.Time, info.Style )
		if pos > 0 then
			ply:SetNWInt( "WRPos", pos )
		else
			ply:SetNWInt( "WRPos", 0 )
		end
		
		Bot.PerStyle[ info.Style ] = pos
	end
end

function Bot:SetFramePosition( nStyle, nFrame )
	if IsValid( Bot:GetPlayer( nStyle ) ) and BotFrame[ nStyle ] then
		Bot:NotifyRestart( nStyle )
		
		if nFrame < BotFrames[ nStyle ] then
			BotFrame[ nStyle ] = nFrame
		end
	end
end

function Bot:GetFramePosition( nStyle )
	if IsValid( Bot:GetPlayer( nStyle ) ) and BotFrame[ nStyle ] and BotFrames[ nStyle ] then
		return { BotFrame[ nStyle ], BotFrames[ nStyle ] }
	end
	
	return { 0, 0 }
end


-- Main control
local function BotRecord( ply, data )
	if Players[ ply ] and Active[ ply ] then
		local origin = data:GetOrigin()
		local eyes = data:GetAngles()
		local frame = Frame[ ply ]
		
		Recording[ ply ][ 1 ][ frame ] = origin.x
		Recording[ ply ][ 2 ][ frame ] = origin.y
		Recording[ ply ][ 3 ][ frame ] = origin.z
		Recording[ ply ][ 4 ][ frame ] = eyes.p
		Recording[ ply ][ 5 ][ frame ] = eyes.y
		
		Frame[ ply ] = frame + 1
	elseif BotPlayer[ ply ] then
		local style = BotPlayer[ ply ]
		local frame = BotFrame[ style ]
		
		if frame >= BotFrames[ style ] then
			if not BotInfo[ style ].BotCooldown then
				BotInfo[ style ].BotCooldown = ct()
				BotInfo[ style ].Start = ct() + 4
				Bot:NotifyRestart( style )
			end
			
			local nDifference = ct() - BotInfo[ style ].BotCooldown
			if nDifference >= 4 then
				BotFrame[ style ] = 1
				BotInfo[ style ].Start = ct()
				BotInfo[ style ].BotCooldown = nil
				BotInfo[ style ].CompletedRun = true
				return Bot:NotifyRestart( style )
			elseif nDifference >= 2 then
				frame = 1
			elseif nDifference >= 0 then
				frame = BotFrames[ style ]
			end
			
			local d = BotData[ style ]
			data:SetOrigin( Vector( d[ 1 ][ frame ], d[ 2 ][ frame ], d[ 3 ][ frame ] ) )
			return ply:SetEyeAngles( Angle( d[ 4 ][ frame ], d[ 5 ][ frame ], 0 ) )
		end
		
		local d = BotData[ style ]
		data:SetOrigin( Vector( d[ 1 ][ frame ], d[ 2 ][ frame ], d[ 3 ][ frame ] ) )
		ply:SetEyeAngles( Angle( d[ 4 ][ frame ], d[ 5 ][ frame ], 0 ) )
		
		BotFrame[ style ] = frame + 1
	end
end
hook.Add( "SetupMove", "PositionRecord", BotRecord )

local function BotButtonRecord( ply, data )
	if Players[ ply ] then
		Recording[ ply ][ 6 ][ Frame[ ply ] ] = data:GetButtons()
	elseif BotPlayer[ ply ] then
		data:ClearButtons()
		data:ClearMovement()
		
		local style = BotPlayer[ ply ]
		if BotData[ style ][ 6 ][ BotFrame[ style ] ] and ply:GetMoveType() == 0 then
			data:SetButtons( tonumber( BotData[ style ][ 6 ][ BotFrame[ style ] ] ) )
		end
	end
end
hook.Add( "StartCommand", "ButtonRecord", BotButtonRecord )

timer.Create( "BotController", 1, 0, function()
	for ply,_ in pairs( BotPlayer ) do
		if IsValid( ply ) then
			if ply:GetMoveType() != 0 then ply:SetMoveType( 0 ) end
			if ply:GetCollisionGroup() != 1 then ply:SetCollisionGroup( 1 ) end
			if ply:GetFOV() != 90 then ply:SetFOV( 90, 0 ) end
		end
	end
	
	if #player.GetBots() == 0 and #player.GetHumans() > 0 then
		Bot.EmptyTick = (Bot.EmptyTick or 0) + 1
		
		if Bot.EmptyTick > 5 then
			Bot.EmptyTick = nil
			Bot:CheckStatus()
		end
	end
end )