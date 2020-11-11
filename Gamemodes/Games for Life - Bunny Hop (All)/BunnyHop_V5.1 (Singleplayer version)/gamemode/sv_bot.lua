Bot = {}
Bot.RecordLimit = 10

Bot.Force = {
	All = false,
	None = false
}

Bot.Modes = {
	[Config.Modes["Auto"]] = true,
	[Config.Modes["Sideways"]] = true,
	[Config.Modes["W-Only"]] = true,
	[Config.Modes["Scroll"]] = true,
	[Config.Modes["Bonus"]] = true
}

local BotInfo = {}
local BotPlayers = {}
local BotContent = {}
local BotFrame = {}
local BotLocale = {}

local MoveRecord = {}
local Frames = {}
local LastWeapon = {}

local MoveBotRecord = function() end
local MoveButtonRecord = function() end


function Bot:CreateHook()
	if not Bot.Hooked then
		hook.Add( "SetupMove", "BotRecording", MoveBotRecord )
		hook.Add( "StartCommand", "ButtonRecording", MoveButtonRecord )
		Bot.Hooked = true
	end
end

function Bot:Setup()
	for mode, enabled in pairs( Bot.Modes ) do
		if not enabled then continue end
		
		BotPlayers[ mode ] = nil
		BotInfo[ mode ] = nil
		BotContent[ mode ] = {}
		BotFrame[ mode ] = { 1, 0 }
		BotLocale[ mode ] = { Start = nil, Saved = true }
	end

	local Spawnable = {}
	
	for mode, data in pairs( BotContent ) do
		local szInfo = FS:Load( "info_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot )
		if not szInfo or szInfo == "" then continue end
		local szData = FS:Load( "run_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot )
		if not szData or szData == "" then continue end
		
		local tabInfo = FS.Deserialize:BotInfo( szInfo )
		local tabData = util.Decompress( szData )
		if not tabData then continue end
		
		BotContent[ mode ] = util.JSONToTable( tabData )
		BotInfo[ mode ] = tabInfo
		BotFrame[ mode ] = { 1, #BotContent[ mode ][ 1 ] }
		
		table.insert( Spawnable, { Delay = mode * 3, Mode = mode } )
	end
	
	if #Spawnable > 0 then
		Bot:CreateHook()
	end
	
	timer.Simple( 1, function()
		for _, data in pairs( Spawnable ) do
			timer.Simple( data.Delay, function()
				Bot:Spawn( data.Mode )
			end )
		end
	end )
end

function Bot:Reload()
	local Spawnable = {}

	for mode, data in pairs( BotLocale ) do
		if BotFrame[ mode ][ 2 ] and #BotContent[ mode ] > 0 then
			BotFrame[ mode ][ 1 ] = 1
			table.insert( Spawnable, { Delay = mode * 3, Mode = mode } )
		end
	end
	
	if #Spawnable > 0 then
		Bot:CreateHook()
	end
	
	timer.Simple( 1, function()
		for _, data in pairs( Spawnable ) do
			timer.Simple( data.Delay, function()
				Bot:Spawn( data.Mode )
			end )
		end
	end )
end


function Bot:Stop( ply, nTime, szRank )
	if not IsValid( ply ) or not Bot:IsRecorded( ply ) then return end
	if not MoveRecord[ ply ] or #MoveRecord[ ply ][ 1 ] == 0 then return end
	if not Bot.Modes[ ply.Mode ] then return end

	if ply.Mode == Config.Modes["Bonus"] and (not ply.timerB or not ply.timerFinishB) then
		return Message:Single( ply, "BotIncomplete", Config.Prefix.Bot )
	elseif ply.Mode != Config.Modes["Bonus"] and (not ply.timer or not ply.timerFinish) then
		return Message:Single( ply, "BotIncomplete", Config.Prefix.Bot )
	end
	
	if not ply.BotFull then return Message:Single( ply, "BotIncomplete", Config.Prefix.Bot ) end
	
	if BotInfo[ ply.Mode ] then
		if nTime >= BotInfo[ ply.Mode ].Time then
			return Message:Single( ply, "BotRecordSlow", Config.Prefix.Bot )
		end
	else
		if file.Exists( "info_" .. game.GetMap() .. "_" .. ply.Mode .. ".txt", "DATA" ) then
			Log:Warning( "BotInfo table has not been loaded on " .. game.GetMap() .. " for mode " .. ply.Mode )
			return Message:Single( ply, "Generic", Config.Prefix.Bot, { "An error occurred while saving your bot. Please contact an admin!" } )
		end
	end
	
	Message:Global( "BotDisplay", Config.Prefix.Bot, { ply:Name(), "#" .. szRank, Config.ModeNames[ ply.Mode ] } )
	
	BotContent[ ply.Mode ] = MoveRecord[ ply ]
	BotFrame[ ply.Mode ] = { 1, #BotContent[ ply.Mode ][ 1 ] }
	BotLocale[ ply.Mode ].Saved = false
	BotLocale[ ply.Mode ].Start = CurTime()
	BotInfo[ ply.Mode ] = { Name = ply:Name(), Time = nTime, Style = ply.Mode, UID = ply:UniqueID(), SteamID = ply:SteamID(), Date = os.date("%Y-%m-%d %H:%M:%S", os.time()) }

	Bot:Spawn( ply.Mode )
end


function Bot:NotifyRestart( nMode, nStart, bHold )
	if not BotInfo[ nMode ] then return end
	
	local tab = { true, nStart or BotLocale[ nMode ].Start, BotInfo[ nMode ].Name, BotInfo[ nMode ].Time, CurTime(), "save" }
	if not nStart and bHold then tab[ 2 ] = nil end
	
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob:IsBot() and ob == BotPlayers[ nMode ] then
			Data:Single( p, "SpecTimer", tab )
		end
	end
end

function Bot:GenerateNotify( nMode, mList )
	if not BotInfo[ nMode ] then return nil end

	return { true, BotLocale[ nMode ].Start, BotInfo[ nMode ].Name, BotInfo[ nMode ].Time, CurTime(), mList }
end


function Bot:Save()
	for mode, data in pairs( BotLocale ) do
		if not data.Saved then
			if not BotContent[ mode ] or #BotContent[ mode ][ 1 ] == 0 or BotFrame[ mode ][ 2 ] == 0 or not BotInfo[ mode ] then continue end
			
			local FileInfo = FS.Serialize:BotInfo( BotInfo[ mode ] )
			local FileData = util.Compress( util.TableToJSON( BotContent[ mode ] ) )
			
			FS:Write( "info_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot, FileInfo )
			FS:Write( "run_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot, FileData )
		end
	end
end

function Bot:TestPlayers()
	if Bot.Initialized and #player.GetAll() == 1 then
		Bot.Initialized = false
		Bot:Reload()
	end
end


function Bot:RecordStart( ply )
	if Bot.Force.None then
		return Message:Single( ply, "BotDisabled", Config.Prefix.Bot )
	elseif Bot.Force.All then
		return Message:Single( ply, "BotForce", Config.Prefix.Bot )
	elseif Bot:IsRecorded( ply ) then
		return Message:Single( ply, "BotRecordSet", Config.Prefix.Bot, { "already" } )
	elseif not ply.InSpawn then
		return Message:Single( ply, "BotSpawn", Config.Prefix.Bot )
	elseif not Bot.Modes[ ply.Mode ] then
		return Message:Single( ply, "BotMode", Config.Prefix.Bot )
	elseif Bot:RecordTest() >= Bot.RecordLimit then
		return Message:Single( ply, "BotLimit", Config.Prefix.Bot, { Bot.RecordLimit } )
	end
	
	Bot:CreateHook()

	MoveRecord[ ply ] = {}
	MoveRecord[ ply ][ 1 ] = {}
	MoveRecord[ ply ][ 2 ] = {}
	MoveRecord[ ply ][ 3 ] = {}
	MoveRecord[ ply ][ 4 ] = {}
	MoveRecord[ ply ][ 5 ] = {}
	MoveRecord[ ply ][ 6 ] = {}
	MoveRecord[ ply ][ 7 ] = {}
	
	Frames[ ply ] = 1
	LastWeapon[ ply ] = "weapon_crowbar"
	
	Message:Single( ply, "BotRecord", Config.Prefix.Bot )
end

function Bot:RecordStop( ply )
	if Bot:IsRecorded( ply ) then
		MoveRecord[ ply ] = nil
		Frames[ ply ] = nil
		LastWeapon[ ply ] = nil
		
		Message:Single( ply, "BotRecordStop", Config.Prefix.Bot )
	else
		Message:Single( ply, "BotRecordSet", Config.Prefix.Bot, { "not" } )
	end
end

function Bot:RecordRestart( ply, bForce )
	if not Bot:IsRecorded( ply ) and not bForce then return end

	MoveRecord[ ply ] = {}
	MoveRecord[ ply ][ 1 ] = {}
	MoveRecord[ ply ][ 2 ] = {}
	MoveRecord[ ply ][ 3 ] = {}
	MoveRecord[ ply ][ 4 ] = {}
	MoveRecord[ ply ][ 5 ] = {}
	MoveRecord[ ply ][ 6 ] = {}
	MoveRecord[ ply ][ 7 ] = {}
	
	Frames[ ply ] = 1
	LastWeapon[ ply ] = "weapon_crowbar"
end

function Bot:RecordTest( bList )
	local nCount, tab = 0, {}
	
	for _, p in pairs( player.GetHumans() ) do
		if Bot:IsRecorded( p ) then
			nCount = nCount + 1
			if bList then table.insert( tab, p:Name() ) end
		end
	end
	
	return bList and { nCount, tab } or nCount
end

function Bot:RecordList( ply )
	local mList = Bot:RecordTest( true )
	
	if mList[1] == 0 then
		Message:Single( ply, "Generic", Config.Prefix.Bot, { "Nobody is being recorded. There are " .. Bot.RecordLimit .. " record slots left!" } )
	else
		Message:Single( ply, "Generic", Config.Prefix.Bot, { "The recording people (" .. mList[1] .. ") are: " .. string.Implode( ", ", mList[2] ) } )
	end
end

function Bot:IsRecorded( ply )
	if MoveRecord[ ply ] and Frames[ ply ] then
		return true
	end
	
	return false
end

function Bot:RemoveBot( nMode )
	local szRun = "bot/run_" .. game.GetMap() .. "_" .. nMode .. ".txt"
	local szInfo = "bot/info_" .. game.GetMap() .. "_" .. nMode .. ".txt"
	local tabReturn = {}
	
	if file.Exists( szRun, "DATA" ) then
		file.Delete( szRun )
		tabReturn[1] = true
	end
	
	if file.Exists( szInfo, "DATA" ) then
		file.Delete( szInfo )
		tabReturn[2] = true
	end
	
	if IsValid( BotPlayers[ nMode ] ) then
		BotPlayers[ nMode ]:Kick( "Bot has been deleted!" )
		tabReturn[3] = true
	end
	
	return tabReturn
end

function Bot:SetFramePosition( nMode, nFrame )
	if BotPlayers[ nMode ] and BotFrame[ nMode ] then
		Bot:NotifyRestart( nMode, nil, true )
		
		if nFrame < BotFrame[ nMode ][ 2 ] then
			BotFrame[ nMode ][ 1 ] = nFrame
		end
	end
end

function Bot:GetFramePosition( nMode )
	if BotPlayers[ nMode ] and BotFrame[ nMode ] then
		return { BotFrame[ nMode ][ 1 ], BotFrame[ nMode ][ 2 ] }
	end
	
	return { 0, 0 }
end

function Bot:GetInfo() return BotInfo end


function Bot:Spawn( nMode )
	local HasBot = false
	for _,bot in pairs( player.GetAll() ) do
		if bot:IsBot() and bot.Mode == nMode then
			HasBot = true
		elseif bot:IsBot() and bot.Mode == Config.Modes["Practice"] then
			HasBot = true
			
			BotPlayers[ nMode ] = bot
			BotLocale[ nMode ].Start = CurTime()

			bot:SetMoveType( MOVETYPE_NONE )
			bot:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

			bot.Mode = nMode
			bot:StripWeapons()
			bot:SetFOV( 90, 0 )

			if BotInfo[ nMode ] then
				bot:SetNWString( "BotName", BotInfo[ nMode ].Name )
				bot:SetNWInt( "Record", tonumber( BotInfo[ nMode ].Time ) )
				bot:SetNWInt( "Mode", tonumber( BotInfo[ nMode ].Style ) )
				bot:SetNWInt( "Rank", -1 )
			end
		end
	end
	if not BotPlayers[ nMode ] or not HasBot then
		Bot.NewMode = nMode
		RunConsoleCommand( "bot" )
		timer.Simple( 1, function()
			Bot:Spawn( nMode )
		end )
	else
		timer.Simple( 1, function()
			if BotInfo[ nMode ] then
				local bot = BotPlayers[ nMode ]
				bot:SetNWString( "BotName", BotInfo[ nMode ].Name )
				bot:SetNWInt( "Record", tonumber( BotInfo[ nMode ].Time ) )
				bot:SetNWInt( "Mode", tonumber( BotInfo[ nMode ].Style ) )
				bot:SetNWInt( "Rank", -1 )
			end
		
			BotLocale[ nMode ].Start = CurTime()
			Bot.Initialized = true
		end )
	end
end


MoveBotRecord = function( ply, data )
	if ply.SetBoost then
		if not ply:Crouching() then
			local CurrentVelocity = data:GetVelocity()
			data:SetVelocity( CurrentVelocity + ply.SetBoost )
		end
	end

	local nMode = ply.Mode
	if BotPlayers[ nMode ] == ply then
		local frame = BotFrame[ nMode ][ 1 ]
	
		if frame >= BotFrame[ nMode ][ 2 ] then
			if not BotLocale[ nMode ].BotCooldown then
				BotLocale[ nMode ].BotCooldown = CurTime()
				BotLocale[ nMode ].Start = CurTime() + 6
				Bot:NotifyRestart( nMode, nil, true )
			end
			
			local nDifference = CurTime() - BotLocale[ nMode ].BotCooldown
			if nDifference >= 6 then
				BotFrame[ nMode ][ 1 ] = 1
				BotLocale[ nMode ].Start = CurTime()
				BotLocale[ nMode ].BotCooldown = nil
				Bot:NotifyRestart( nMode )
				
				ply:SetMoveType( MOVETYPE_NONE )
				ply:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
			elseif nDifference >= 2 then
				frame = 1
				BotFrame[ nMode ][ 1 ] = BotFrame[ nMode ][ 2 ]
			elseif nDifference >= 0 then
				frame = BotFrame[ nMode ][ 2 ]
				BotFrame[ nMode ][ 1 ] = BotFrame[ nMode ][ 2 ]
			end
		end

		local origin = Vector( BotContent[ nMode ][ 1 ][ frame ], BotContent[ nMode ][ 2 ][ frame ], BotContent[ nMode ][ 3 ][ frame ] )
		local eyes = Angle( BotContent[ nMode ][ 4 ][ frame ], BotContent[ nMode ][ 5 ][ frame ], 0 )
		
		data:SetOrigin( origin )
		ply:SetEyeAngles( eyes )
		
		if BotContent[ nMode ][ 7 ][ frame ] then
			if BotContent[ nMode ][ 7 ][ frame ] == "none" then
				if #ply:GetWeapons() > 0 then
					ply:StripWeapons()
				end
			elseif not ply:HasWeapon( BotContent[ nMode ][ 7 ][ frame ] ) then
				ply:Give( BotContent[ nMode ][ 7 ][ frame ] ):SetNWBool( "NoCrosshair", true )
				ply:SelectWeapon( BotContent[ nMode ][ 7 ][ frame ] )
			else
				ply:SelectWeapon( BotContent[ nMode ][ 7 ][ frame ] )
			end

			ply:SetFOV( 90, 0 )
		end
		
		-- This should probably be moved to a place where it isn't getting called 200 times per second
		if ply:GetMoveType() != MOVETYPE_NONE then
			ply:SetMoveType( MOVETYPE_NONE )
		end
		
		BotFrame[ ply.Mode ][ 1 ] = BotFrame[ ply.Mode ][ 1 ] + 1
	elseif MoveRecord[ ply ] and ply.InRun then
		local origin = data:GetOrigin()
		local eyes = data:GetAngles()
		local weap = ply:GetActiveWeapon()

		MoveRecord[ ply ][ 1 ][ Frames[ ply ] ] = origin.x
		MoveRecord[ ply ][ 2 ][ Frames[ ply ] ] = origin.y
		MoveRecord[ ply ][ 3 ][ Frames[ ply ] ] = origin.z
		MoveRecord[ ply ][ 4 ][ Frames[ ply ] ] = eyes.p
		MoveRecord[ ply ][ 5 ][ Frames[ ply ] ] = eyes.y
		
		if IsValid( weap ) and LastWeapon[ ply ] != weap:GetClass() then
			LastWeapon[ ply ] = weap:GetClass()
			MoveRecord[ ply ][ 7 ][ Frames[ ply ] ] = weap:GetClass()
		elseif not IsValid( weap ) and LastWeapon[ ply ] != "none" then
			LastWeapon[ ply ] = "none"
			MoveRecord[ ply ][ 7 ][ Frames[ ply ] ] = "none"
		end
		
		Frames[ ply ] = Frames[ ply ] + 1
	end
end

MoveButtonRecord = function( ply, data )
	if BotPlayers[ ply.Mode ] == ply then
		data:ClearButtons()
		data:ClearMovement()

		if BotContent[ ply.Mode ][ 6 ][ BotFrame[ ply.Mode ][ 1 ] ] then
			data:SetButtons( BotContent[ ply.Mode ][ 6 ][ BotFrame[ ply.Mode ][ 1 ] ] )
		end
	elseif MoveRecord[ ply ] and ply.timer and not ply.timerFinish then
		MoveRecord[ ply ][ 6 ][ Frames[ ply ] ] = data:GetButtons()
	end
end