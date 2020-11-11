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
	Custom = 100
}

Map.ServerList = nil
Map.ServerMaps = nil
Map.ClientProtocol = "Map"
Map.ClientBinary = nil
Map.ClientLength = 0

Map.Timer = { Start = nil, End = nil }
Map.Entities = {}
Map.Spawn = nil
Map.Bonus = nil
Map.StepSize = nil

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
	end
	
	if #Map.ServerMaps > 0 then
		Map.ClientBinary = util.Compress( util.TableToJSON( Map.ServerMaps ) )
		Map.ClientLength = #Map.ClientBinary
		
		if #Map.ServerMaps != Config.MapCount then
			Map:SyncError( #Map.ServerMaps, Config.MapCount )
		end
	end
end

function Map:Send( ply )
	net.Start( Map.ClientProtocol )
	net.WriteUInt( Map.ClientLength, 32 )
	net.WriteData( Map.ClientBinary, Map.ClientLength )
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
		if not Map.Spawn then
			local BoxA, BoxB = Vector( vec.StartA.x, vec.StartA.y, vec.StartA.z ), Vector( vec.StartB.x, vec.StartB.y, vec.StartA.z )
			Map.Spawn = (BoxA + BoxB) / 2
		end
	end
end

function Map:CreateTriggers()
	local szTriggers = FS:Load( "triggers_" .. game.GetMap() .. ".txt", FS.Folders.Maps )
	if not szTriggers or szTriggers == "" then return end
	
	local szLines = string.Explode( "\n", szTriggers )
	local Triggers = {}
	
	for _, szLine in pairs( szLines ) do
		if szLine == "" then continue end
		table.insert( Triggers, FS.Deserialize:TriggerInfo( szLine ) )
	end

	for _, ent in pairs( Map.Entities ) do
		if IsValid( ent ) then
			ent:Remove()
		end
	end
	Map.Entities = {}
	
	for _, data in pairs( Triggers ) do
		if data.Map != game.GetMap() then continue end
		local ID, TInfo = data.ID, data.Data

		if ID == Map.Specials.AreaBlock or ID == Map.Specials.AreaTeleport or ID == Map.Specials.AreaStepSize or ID == Map.Specials.AreaBonusS or ID == Map.Specials.AreaBonusE or ID == Map.Specials.Freestyle then
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
				ent.min = ent:GetPos() + ToVector( Split[2] )
				ent.max = ent:GetPos() + ToVector( Split[3] )
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
		elseif ID == Map.Specials.Custom then
			Map:CustomTrigger( game.GetMap() )
		end
	end
end

function Map:Setup()
	Map:CreateTimers()
	Map:CreateTriggers()
	
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
	elseif map == "bhop_strafe_fix" then
		local tab = {
			Vector( 3946.5, -4732.5, 459 ),
			Vector( -624.5, 3270, 4428 ),
			Vector( 681.5, 3138, 3941.5 )
		}
		
		for _,ent in pairs( ents.FindByClass("trigger_teleport") ) do
			if table.HasValue( tab, ent:GetPos() ) then
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