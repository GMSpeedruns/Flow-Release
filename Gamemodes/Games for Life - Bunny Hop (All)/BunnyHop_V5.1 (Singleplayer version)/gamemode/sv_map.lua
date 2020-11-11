Map = {}
Map.Current = nil
Map.Default = { Map = game.GetMap(), Points = 0, StartA = Vector(0, 0, 0), StartB = Vector(0, 0, 0), EndA = Vector(0, 0, 0), EndB = Vector(0, 0, 0), Plays = 0 }

Map.NoTrigger = {
	["bhop_fury"] = true,
	["bhop_hive"] = true
}

Map.Doors = {
	["bhop_monster_jam"] = true, 
	["bhop_bkz_goldhop"] = true,
	["bhop_aoki_final"] = true
}

Map.Specials = {
	AreaBlock = 1,
	AreaTeleport = 2,
	TeleportTrigger = 3,
	InvisBlock = 4,
	EntBlock = 5,
	BotOption = 6,
	StepSize = 7,
	AreaStepSize = 8,
	Spawn = 9,
	AreaBonusS = 10,
	AreaBonusE = 11,
	Freestyle = 13,
	BonusAngles = 14,
	AreaFunction = 20,
	Custom = 100
}

Map.ServerList = nil
Map.ServerMaps = nil
Map.ClientProtocol = "Map"

Map.Timer = { Start = nil, End = nil }
Map.Entities = {}
Map.Spawn = nil
Map.Bonus = nil
Map.StepSize = nil
Map.BonusAngles = nil

local ClientBinary = nil
local ClientLength = nil

util.AddNetworkString( Map.ClientProtocol )

function Map:Init()
	Map.ServerList = {}
	Map.ServerMaps = {}
	Map.ClientList = {}

	local files = file.Find( FS.Folders.Maps .. "data_*.txt", FS.Main )
	for _, file in pairs( files ) do
		local content = FS:Load( file, FS.Folders.Maps )
		local map = string.sub( string.StripExtension( file ), 6 )

		Map.ServerList[ map ] = FS.Deserialize:MapData( content )
		table.insert( Map.ServerMaps, { map, Map.ServerList[ map ].Points } )
	end
	
	if Map.ServerList[ game.GetMap() ] then
		Map.Current = Map.ServerList[ game.GetMap() ]
		
		local nPlays = (Map.ServerList[ game.GetMap() ].Plays or 0) + 1
		Map.ServerList[ game.GetMap() ].Plays = nPlays
		
		local szData = FS.Serialize:MapData( Map.ServerList[ game.GetMap() ] )
		FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, szData )
	end
	
	if #Map.ServerMaps > 0 then
		ClientBinary = util.Compress( util.TableToJSON( Map.ServerMaps ) )
		ClientLength = #ClientBinary
		
		if #Map.ServerMaps != Config.MapCount then
			Map:SyncError( #Map.ServerMaps, Config.MapCount )
		end
	end
end

function Map:Send( ply )
	if not ClientBinary then
		return print( "ClientBinary not loaded properly on " .. ply:Name() .. "'s join!" )
	end
	net.Start( Map.ClientProtocol )
	net.WriteUInt( ClientLength, 32 )
	net.WriteData( ClientBinary, ClientLength )
	net.Send( ply )
end

function Map:SyncError( nLoaded, nSetup )
	for i = 1, 100 do
		print( "[CRITICAL] MAP COUNT SYNC ERROR (Loaded: " .. nLoaded .. " - Config: " .. nSetup )
	end
end


function Map:CreateTimers( bReload )
	if not Map.Current or not Map.Current.StartA then
		ServerLog( "No start or end positions found for this map: " .. game.GetMap() )
		return
	end
	
	local vec = {
		StartA = Map.Current.StartA, 
		StartB = Map.Current.StartB, 
		EndA = Map.Current.EndA, 
		EndB = Map.Current.EndB
	}
	
	if Map.Timer.Start then Map.Timer.Start:Remove() Map.Timer.Start = nil end
	if Map.Timer.End then Map.Timer.End:Remove() Map.Timer.End = nil end

	local entStart = ents.Create( "bhop_timer" )
	entStart:SetPos( (vec.StartA + vec.StartB) / 2 )
	entStart.min = vec.StartA
	entStart.max = vec.StartB
	entStart.areatype = Config.Area.Start
	entStart:Spawn()
	
	local entEnd = ents.Create( "bhop_timer" )
	entEnd:SetPos( (vec.EndA + vec.EndB) / 2 )
	entEnd.min = vec.EndA
	entEnd.max = vec.EndB
	entEnd.areatype = Config.Area.Finish
	entEnd:Spawn()
	
	Map.Timer.Start = entStart
	Map.Timer.End = entEnd

	if vec.StartA == vec.StartB then
		Map.Spawn = nil
	else
		local BoxA, BoxB = Vector( vec.StartA.x, vec.StartA.y, vec.StartA.z ), Vector( vec.StartB.x, vec.StartB.y, vec.StartA.z )
		Map.Spawn = (BoxA + BoxB) / 2
	end
end

function Map:CreateTriggers()
	local szTriggers = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps )
	if not szTriggers or szTriggers == "" then return end
	
	local szLines = string.Explode( "\n", szTriggers )
	local Triggers = {}
	
	for _, szLine in pairs( szLines ) do
		if szLine == "" then continue end
		if string.sub( szLine, 1, 2 ) == "//" then continue end
		table.insert( Triggers, FS.Deserialize:TriggerInfo( szLine ) )
	end

	for _, ent in pairs( Map.Entities ) do
		if IsValid( ent ) then
			ent:Remove()
		end
	end
	Map.Entities = {}
	
	Map.Bonus = nil
	Map.StepSize = nil
	Map.BonusAngles = nil
	
	for _, data in pairs( Triggers ) do
		if data.Map != game.GetMap() then continue end
		local ID, TInfo = data.ID, data.Data

		if ID == Map.Specials.AreaBlock or ID == Map.Specials.AreaTeleport or ID == Map.Specials.AreaStepSize or ID == Map.Specials.AreaBonusS or ID == Map.Specials.AreaBonusE or ID == Map.Specials.Freestyle or ID == Map.Specials.AreaFunction then
			local Split = string.Explode( ";", TInfo )
			local Bottom, Top = ToVector( Split[1] ), ToVector( Split[2] )
			local EntID = table.insert( Map.Entities, ents.Create( "bhop_timer" ) )
			
			Map.Entities[ EntID ]:SetPos( (Bottom + Top) / 2 )
			Map.Entities[ EntID ].min = Bottom
			Map.Entities[ EntID ].max = Top
			
			if ID == Map.Specials.AreaBlock then
				Map.Entities[ EntID ].areatype = Config.Area.Block
			elseif ID == Map.Specials.AreaTeleport then
				Map.Entities[ EntID ].areatype = Config.Area.Teleport
				Map.Entities[ EntID ].dest = ToVector( Split[3] )
			elseif ID == Map.Specials.AreaStepSize then
				Map.Entities[ EntID ].areatype = Config.Area.StepSize
				Map.Entities[ EntID ].steps = { tonumber( Split[3] ), tonumber( Split[4] ) }
			elseif ID == Map.Specials.AreaBonusS then
				Map.Entities[ EntID ].areatype = Config.Area.BonusA
				local BoxA, BoxB = Vector( Bottom.x, Bottom.y, Bottom.z ), Vector( Top.x, Top.y, Bottom.z )
				Map.Bonus = (BoxA + BoxB) / 2
			elseif ID == Map.Specials.AreaBonusE then
				Map.Entities[ EntID ].areatype = Config.Area.BonusB
			elseif ID == Map.Specials.Freestyle then
				Map.Entities[ EntID ].areatype = Config.Area.Freestyle
			elseif ID == Map.Specials.AreaFunction then
				Map.Entities[ EntID ].areatype = Config.Area.Function
				
				local id = tonumber( Split[3] )
				if id == 10 or id == 11 then
					local pow = (id == 10) and {1.20, 180} or {1.35, 120}
					Map.Entities[ EntID ].AtEnd = true
					Map.Entities[ EntID ].SetFunction = function( ply )
						timer.Simple( pow[1], function() ply:SetLocalVelocity( ply:GetVelocity() + Vector(0, 0, pow[2] ) ) end )
					end
				elseif id == 12 then
					Map.Entities[ EntID ].AtStart = true
					Map.Entities[ EntID ].SetFunction = function( ply ) ply:SendLua( "Client:Brushes(1)" ) end
				elseif id == 13 then
					Map.Entities[ EntID ].AtStart = true
					Map.Entities[ EntID ].SetFunction = function( ply ) ply:SendLua( "Client:Brushes(0)" ) end
				end
			end
			
			Map.Entities[ EntID ]:Spawn()
		elseif ID == Map.Specials.TeleportTrigger then
			local Split = string.Explode( ";", TInfo )
			local Pos = ToVector( Split[1] )
			
			for _, ent in pairs( ents.FindByClass( "trigger_teleport" ) ) do
				if ent:GetPos() == Pos then
					ent:SetKeyValue( "target", Split[2] )
				end
			end
		elseif ID == Map.Specials.InvisBlock then
			local Split = string.Explode( ";", TInfo )
			if #Split == 3 then
				local ent = ents.Create( "bhop_block" )
				ent:SetPos( ToVector( Split[1] ) )
				ent.min = ToVector( Split[2] )
				ent.max = ToVector( Split[3] )
				ent:Spawn()
			elseif #Split == 2 then
				local Bottom, Top = ToVector( Split[1] ), ToVector( Split[2] )		
				local ent = ents.Create( "bhop_block" )
				ent:SetPos( (Bottom + Top) / 2 )
				ent.min = Bottom
				ent.max = Top
				ent:Spawn()
			end
		elseif ID == Map.Specials.EntBlock then
			for _,ent in pairs( ents.FindByClass( TInfo ) ) do
				ent:Remove()
			end
		elseif ID == Map.Specials.BotOption then
			if TInfo == "0" then
				Bot.Force.None = true
			elseif TInfo == "1" then
				Bot.Force.All = true
			end
		elseif ID == Map.Specials.StepSize then
			Map.StepSize = tonumber( TInfo )
		elseif ID == Map.Specials.Spawn then
			Map.Spawn = ToVector( TInfo )
		elseif ID == Map.Specials.BonusAngles then
			local Split = string.Explode( ";", TInfo )
			if #Split != 2 then continue end
			Map.BonusAngles = Angle( tonumber( Split[1] ), tonumber( Split[2] ), 0 )
		elseif ID == Map.Specials.Custom then
			Map:CustomTrigger( game.GetMap() )
		end
	end
end

function Map:Setup()
	Map:CreateTimers()
	Map:CreateTriggers()
	Map:PermanentFixes()
	
	if Map.NoTrigger[ game.GetMap() ] then return end

	for _,ent in pairs( ents.FindByClass("func_door") ) do
		if not ent.IsP then continue end
		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local h = maxs.z - mins.z

		if h > 80 and not Map.Doors[ game.GetMap() ] then continue end
		local tab = ents.FindInBox(ent:LocalToWorld(mins) - Vector(0, 0, 10), ent:LocalToWorld(maxs) + Vector(0, 0, 5))
		if tab then
			local teleport = nil
			for _,v2 in pairs(tab) do
				if v2 and v2:IsValid() and v2:GetClass() == "trigger_teleport" then 
					teleport = v2
				end
			end
			if teleport then
				ent:Fire("Lock")
				ent:SetKeyValue("spawnflags", "1024")
				ent:SetKeyValue("speed", "0")
				ent:SetRenderMode(RENDERMODE_TRANSALPHA)
				if ent.BHS then
					ent:SetKeyValue("locked_sound", ent.BHS)
				else
					ent:SetKeyValue("locked_sound", "DoorSound.DefaultMove")
				end
				ent:SetNWInt("Platform", 1)
			end
		end
	end
	
	for _,ent in pairs( ents.FindByClass("func_button") ) do
		if not ent.IsP then continue end
		if ent.SpawnFlags == "256" then
			local mins = ent:OBBMins()
			local maxs = ent:OBBMaxs()
			local tab = ents.FindInBox(ent:LocalToWorld(mins) - Vector(0,0,10), ent:LocalToWorld(maxs) + Vector(0,0,5))
			if tab then
				local teleport = nil
				for _,v2 in pairs(tab) do
					if v2 and v2:IsValid() and v2:GetClass() == "trigger_teleport" then
						teleport = v2
					end
				end
				if teleport then
					ent:Fire("Lock")
					ent:SetKeyValue("spawnflags", "257")
					ent:SetKeyValue("speed", "0")
					ent:SetRenderMode(RENDERMODE_TRANSALPHA)
					if ent.BHS then
						ent:SetKeyValue("locked_sound", ent.BHS)
					else
						ent:SetKeyValue("locked_sound", "None (Silent)")
					end
					ent:SetNWInt("Platform", 1)
				end
			end
		end
	end
end

function Map:CustomTrigger( map )
	if map == "bhop_lost_world" then
		local entPush = nil
		for _, ent in pairs( ents.FindByClass("trigger_push") ) do
			if ent:GetPos() == Vector(5864, 4808, -128) then
				entPush = ent
				break
			end
		end
		if not entPush then return end

		entPush:SetKeyValue( "spawnflags", "0" )
		entPush:Spawn()
		
		local max = entPush:LocalToWorld( entPush:OBBMaxs() )
		local min = entPush:LocalToWorld( entPush:OBBMins() ) - Vector( 0, 0, 128 )

		local EntID = table.insert( Map.Entities, ents.Create("bhop_timer") )
		Map.Entities[ EntID ]:SetPos( (min + max) / 2 )
		Map.Entities[ EntID ].min = min
		Map.Entities[ EntID ].max = max
		Map.Entities[ EntID ].areatype = Config.Area.Velocity
		Map.Entities[ EntID ].velocity = Vector( 0, 0, 16 )
		Map.Entities[ EntID ]:Spawn()
		
		Bot:CreateHook()
	elseif map == "bhop_catalyst" then
		local tab = {
			Vector(7156.240234, 704.713989, -7585),
			Vector(7130.129883, 702.512024, -7585),
			Vector(7102.5, 700.283997, -7585),
			Vector(7069.850098, 700.505005, -7585),
			Vector(7036.589844, 700.119019, -7585)
		}
		
		for _,ent in pairs( ents.FindByClass("info_player_terrorist") ) do
			if table.HasValue( tab, ent:GetPos() ) then
				ent:Remove()
			end
		end
	elseif map == "bhop_exquisite" then
		for _,ent in pairs( ents.FindByClass("trigger_multiple") ) do
			if ent:GetPos() == Vector( 3264, -704.02, -974.49 ) then
				ent:Remove()
				break
			end
		end
	elseif map == "bhop_exodus" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(6560, 5112, 7412) then
				ent:SetKeyValue( "target", "13" )
			end
		end
		for _,ent in pairs( ents.FindByClass("func_brush") ) do
			if ent:GetName() == "aokilv6" then
				ent:SetName( "disabled" )
			end
		end
	elseif map == "bhop_strafe_fix" then
		for _,ent in pairs(ents.FindByClass("trigger_teleport")) do
			if ent:GetPos() == Vector(-3946.5, -4732.5, 459) or ent:GetPos() == Vector(-624.5, 3270, 4428) or ent:GetPos() == Vector(681.5, 3138, 3941.5) then
				ent:Remove()
			end
		end
	elseif map == "bhop_eman_on" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			local vPos = ent:GetPos()
			if vPos.x == -1316 and (pos.y > -10975 and pos.y < -10841) then
				ent:SetPos( vPos + Vector( 0, 0, 14.5 ) )
				local Min, Max = ent:GetCollisionBounds()
				Min.y, Max.y = Min.y + 64, Max.y - 64
				ent:SetCollisionBounds( ent:GetPos(), Min, Max )
				ent:Spawn()
			end
		end
	elseif map == "bhop_inmomentum_gfl_final" then
		for _,ent in pairs( ents.FindByClass("func_lod") ) do
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
		
		for _,ent in pairs( ents.GetAll() ) do
			if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
			end
		end
	elseif map == "bhop_impulse" then
		local tab = {
			Vector( 10368, -532, -192 ),
			Vector( 10368, -556, -192 )
		}
		
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if table.HasValue( tab, ent:GetPos() ) then
				ent:Remove()
			end
		end
		
		for _,ent in pairs( ents.FindByClass("func_wall_toggle") ) do
			ent:Remove()
		end
	elseif map == "bhop_stronghold" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(-912, -2880, 4510) then
				ent:Remove()
			end
		end
	elseif map == "bhop_voyage" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(0, -404.5, -136) then
				ent:Remove()
			end
		end
	elseif map == "bhop_badges2" then
		for _,ent in pairs( ents.FindByClass("trigger_multiple") ) do
			if ent:GetPos() == Vector(-12543.9, -8448, 4319.96) then
				ent:Remove()
			end
		end
		
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(-3840, -4832, -468) or ent:GetPos() == Vector(-9216, -2168, -1732) then
				ent:Remove()
			end
		end
	elseif map == "kz_bhop_benchmark" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(5592, 11296, 7120) or ent:GetPos() == Vector(5536, 11172, 7120) or ent:GetPos() == Vector(-832.02, 1039.94, 3128) then
				ent:SetPos( ent:GetPos() + Vector(0, 0, 8) )
				ent:Spawn()
			end
		end
	elseif map == "kz_bhop_lucid" then
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if ent:GetPos() == Vector(880, 2432, 100) or ent:GetPos() == Vector(-1248, 1384.01, 268) then
				ent:Remove()
			end
		end
	elseif map == "bhop_harmony" then
		for _,v in pairs(ents.FindByClass("logic_*")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_wall_toggle")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_illusionary")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("point_clientcommand")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("shadow_control")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("func_brush")) do
			v:Remove()
		end
		for _,v in pairs(ents.FindByClass("env_smokestack")) do
			v:Remove()
		end
	end
end

function Map:PermanentFixes()
	for _,ent in pairs( ents.FindByClass("func_lod") ) do
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	end
		
	for _,ent in pairs( ents.GetAll() ) do
		if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
	end
end

local function KeyValueTriggers(ent, key, value)
    if not GAMEMODE.BaseStoreOutput or not GAMEMODE.BaseTriggerOutput then
        local e = scripted_ents.Get( "base_entity" )
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
end
hook.Add("EntityKeyValue", "KeyValueTriggers", KeyValueTriggers)