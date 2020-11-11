Bot = {}
Bot.Enabled = false

Bot.Force = {
	All = false,
	None = false
}

Bot.Replayers = {
	[Config.Modes["Auto"]] = nil,
	[Config.Modes["Sideways"]] = nil,
	[Config.Modes["W-Only"]] = nil
}

Bot.ReplayData = {
	[Config.Modes["Auto"]] = { Frame = 1, Frames = 0, Start = nil, Position =  {}, Angle = {}, Saved = true },
	[Config.Modes["Sideways"]] = { Frame = 1, Frames = 0, Start = nil, Position =  {}, Angle = {}, Saved = true },
	[Config.Modes["W-Only"]] = { Frame = 1, Frames = 0, Start = nil, Position =  {}, Angle = {}, Saved = true }
}

Bot.Data = {
	[Config.Modes["Auto"]] = nil,
	[Config.Modes["Sideways"]] = nil,
	[Config.Modes["W-Only"]] = nil
}


function Bot:Enable()
	if not Bot.Enabled then
		Bot.Enabled = true
	end
end

function Bot:Disable()
	local _count = 0
	for _, p in pairs( player.GetAll() ) do
		if p.BotRecord then
			_count = _count + 1
		end
	end
	
	if _count == 0 then
		Bot.Enabled = false
	end
end


function Bot:Setup()
	local Spawnable = {}
	
	for mode, data in pairs( Bot.ReplayData ) do
		local szInfo = FS:Load( "info_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot )
		if not szInfo or szInfo == "" then continue end
		local szData = FS:Load( "run_" .. game.GetMap() .. "_" .. mode .. ".txt", FS.Folders.Bot )
		if not szData or szData == "" then continue end
		
		local tabInfo = FS.Deserialize:BotInfo( szInfo )
		local tabData = util.Decompress( szData )
		if not tabData then continue end
		tabData = util.JSONToTable( tabData )
		
		Bot.Data[ mode ] = { Name = tabInfo.Name, Time = tabInfo.Time, Style = tabInfo.Style }
		
		data.Position = tabData[1]
		data.Angle = tabData[2]
		data.Frames = #data.Position
		data.Frame = 1
		
		table.insert( Spawnable, { Delay = mode * 3, Mode = mode } )
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

	for mode, data in pairs( Bot.ReplayData ) do
		if data.Frames > 0 and #data.Position > 0 then
			data.Frame = 1
			table.insert( Spawnable, { Delay = mode * 3, Mode = mode } )
		end
	end
	
	timer.Simple( 1, function()
		for _, data in pairs( Spawnable ) do
			timer.Simple( data.Delay, function()
				Bot:Spawn( data.Mode )
			end )
		end
	end )
end


function Bot:Restart( nMode )
	local ply = Bot.Replayers[ nMode ]
	if not ply then return end

	ply:SetMoveType( MOVETYPE_NONE )
	ply:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

	Bot.ReplayData[ nMode ].Frame = 1
	Bot.ReplayData[ nMode ].Start = CurTime()
	Bot:NotifyRestart( nMode )
end

function Bot:Stop( ply, nTime, szRank )
	if not IsValid( ply ) or not ply.BotRecord then return end
	if not ply.BotPosition or #ply.BotPosition == 0 then return end
	if not ply.timer or not ply.timerFinish or ply.Mode > Config.Modes["W-Only"] then return end
	if not ply.BotFull then return Message:Single( ply, "BotIncomplete", Config.Prefix.Bot ) end

	if Bot.Data[ ply.Mode ] then
		if nTime >= Bot.Data[ ply.Mode ].Time then
			return Message:Single( ply, "BotRecordSlow", Config.Prefix.Bot )
		end
	end

	Message:Global( "BotDisplay", Config.Prefix.Bot, { ply:Name(), "#" .. szRank, Config.ModeNames[ ply.Mode ] } )
	
	Bot.ReplayData[ ply.Mode ].Position = ply.BotPosition
	Bot.ReplayData[ ply.Mode ].Angle = ply.BotAngle
	Bot.ReplayData[ ply.Mode ].Frames = #Bot.ReplayData[ ply.Mode ].Position
	Bot.ReplayData[ ply.Mode ].Frame = 1
	Bot.ReplayData[ ply.Mode ].Saved = false
	Bot.ReplayData[ ply.Mode ].Running = true
	Bot.Data[ ply.Mode ] = { Name = ply:Name(), Time = nTime, Style = ply.Mode }

	Bot:Spawn( ply.Mode )
end


function Bot:NotifyRestart( nMode )
	if not Bot.Data[ nMode ] then return end
	for _,p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob:IsBot() and ob == Bot.Replayers[ nMode ] then
			Data:Single( p, "SpecTimer", { true, Bot.ReplayData[ nMode ].Start, Bot.Data[ nMode ].Name, Bot.Data[ nMode ].Time, CurTime(), "save" } )
		end
	end
end


function Bot:Save()
	for mode, data in pairs( Bot.ReplayData ) do
		if not data.Saved then
			if #data.Position == 0 or data.Frames == 0 or not Bot.Data[ mode ] then continue end
			
			local FileInfo = FS.Serialize:BotInfo( Bot.Data[ mode ] )
			local FileData = util.Compress( util.TableToJSON( { data.Position, data.Angle } ) )
			
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


function Bot:Record( ply, bForce, bSilent )
	if Bot.Force.None then
		return bSilent and nil or Message:Single( ply, "BotDisabled", Config.Prefix.Bot )
	elseif Bot.Force.All then
		return bSilent and nil or Message:Single( ply, "BotForce", Config.Prefix.Bot )
	end

	if ply.BotRecord or bForce then
		Bot:Disable()
		ply.BotRecord = nil
		ply.BotPosition = {}
		ply.BotAngle = {}
		ply.BotFrame = 1
		
		return bSilent and nil or Message:Single( ply, "BotRecordStop", Config.Prefix.Bot )
	else
		if not ply.InSpawn then
			return bSilent and nil or Message:Single( ply, "BotSpawn", Config.Prefix.Bot )
		elseif ply.Mode > Config.Modes["W-Only"] then
			return bSilent and nil or Message:Single( ply, "BotMode", Config.Prefix.Bot )
		end
		
		Bot:Enable()
		ply.BotPosition = {}
		ply.BotAngle = {}
		ply.BotFrame = 1
		ply.BotRecord = true
		
		return bSilent and nil or Message:Single( ply, "BotRecord", Config.Prefix.Bot )
	end
end

function Bot:RecordRestart( ply, bForce )
	if not ply.BotRecord and not bForce then return end
	
	ply.BotPosition = {}
	ply.BotAngle = {}
	ply.BotFrame = 1
	ply.BotRecord = true
end


function Bot:Spawn( nMode )
	local HasBot = false
	for _,bot in pairs( player.GetAll() ) do
		if bot:IsBot() and bot.Mode == nMode then
			HasBot = true
		elseif bot:IsBot() and bot.Mode == Config.Modes["Practice"] then
			HasBot = true
			
			Bot.Replayers[ nMode ] = bot
			Bot.ReplayData[ nMode ].Start = CurTime()
			
			if bot:GetMoveType() != MOVETYPE_NONE then
				bot:SetMoveType( MOVETYPE_NONE )
				bot:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
			end
			
			bot.Mode = nMode
			bot:StripWeapons()
			bot:SetActiveWeapon( bot:Give("weapon_glock") )
			bot:SetFOV( 90, 0 )
			bot:Freeze( true )
			
			if Bot.Data[ nMode ] then
				bot:SetNWString( "BotName", Bot.Data[ nMode ].Name )
				bot:SetNWInt( "Record", tonumber( Bot.Data[ nMode ].Time ) )
				bot:SetNWInt( "Mode", tonumber( Bot.Data[ nMode ].Style ) )
				bot:SetNWInt( "Rank", -1 )
			end
		end
	end
	if not Bot.Replayers[ nMode ] or not HasBot then
		Bot.NewMode = nMode
		RunConsoleCommand( "bot" )
		timer.Simple( 1, function()
			Bot:Spawn( nMode )
		end )
	else
		timer.Simple( 1, function()
			if Bot.Data[ nMode ] then
				local bot = Bot.Replayers[ nMode ]
				bot:SetNWString( "BotName", Bot.Data[ nMode ].Name )
				bot:SetNWInt( "Record", tonumber( Bot.Data[ nMode ].Time ) )
				bot:SetNWInt( "Mode", tonumber( Bot.Data[ nMode ].Style ) )
				bot:SetNWInt( "Rank", -1 )
			end
		
			Bot.ReplayData[ nMode ].Start = CurTime()
			Bot.Initialized = true
			Bot:Enable()
		end )
	end
end

function GM:SetupMove( ply, data )
	if ply.SetBoost then
		if not ply:Crouching() then
			local CurrentVelocity = data:GetVelocity()
			data:SetVelocity( CurrentVelocity + ply.SetBoost )
		end
	end
	if not Bot.Enabled then return end
	
	if Bot.Replayers[ ply.Mode ] == ply then
		if Bot.ReplayData[ ply.Mode ].Frame >= Bot.ReplayData[ ply.Mode ].Frames then return Bot:Restart( ply.Mode ) end
		
		data:SetOrigin( Bot.ReplayData[ ply.Mode ].Position[ Bot.ReplayData[ ply.Mode ].Frame ] )
		ply:SetEyeAngles( Bot.ReplayData[ ply.Mode ].Angle[ Bot.ReplayData[ ply.Mode ].Frame ] )
		Bot.ReplayData[ ply.Mode ].Frame = Bot.ReplayData[ ply.Mode ].Frame + 1
		
		if ply:GetMoveType() != MOVETYPE_NONE then
			ply:SetMoveType( MOVETYPE_NONE )
			ply:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
		end
	elseif ply.BotRecord and ply.timer and not ply.timerFinish then
		ply.BotPosition[ ply.BotFrame ] = data:GetOrigin()
		ply.BotAngle[ ply.BotFrame ] = ply:EyeAngles()
		ply.BotFrame = ply.BotFrame + 1
	end
end