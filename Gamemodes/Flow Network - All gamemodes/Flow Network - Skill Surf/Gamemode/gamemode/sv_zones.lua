Zones = {}
Zones.Type = {
	["Normal Start"] = 0,
	["Normal End"] = 1,
	["Bonus Start"] = 2,
	["Bonus End"] = 3,
	["Anticheat"] = 4,
	["Restart"] = 5
}

Zones.Options = {
	NoStartLimit = 1,
	NoSpeedLimit = 2,
}

Zones.Settings = {
	MaxVelocity = 3500,
	UnlimitedVelocity = 100000
}

Zones.StartPoint = nil
Zones.BottomLevel = nil
Zones.BonusPoint = nil

Zones.Cache = {}
Zones.Entities = {}

function Zones:Setup()
	Zones.StartPoint = nil
	Zones.BonusPoint = nil

	for _,zone in pairs( Zones.Cache ) do
		local ent = ents.Create( "game_timer" )
		ent:SetPos( (zone.P1 + zone.P2) / 2 )
		ent.min = zone.P1
		ent.max = zone.P2
		ent.zonetype = zone.Type
		
		if zone.Type == Zones.Type["Normal Start"] then
			Zones.StartPoint = { zone.P1, zone.P2, (zone.P1 + zone.P2) / 2 }
			Zones.BotPoint = Vector( Zones.StartPoint[ 3 ].x, Zones.StartPoint[ 3 ].y, Zones.StartPoint[ 1 ].z )
		elseif zone.Type == Zones.Type["Bonus Start"] then
			Zones.BonusPoint = { zone.P1, zone.P2, (zone.P1 + zone.P2) / 2 }
		end
		
		ent:Spawn()
		table.insert( Zones.Entities, ent )
	end
end

function Zones:Reload()
	for _,zone in pairs( Zones.Entities ) do
		if IsValid( zone ) then
			zone:Remove()
			zone = nil
		end
	end
	
	Zones.Entities = {}
	
	Core:LoadZones()
	Zones:Setup()
end

function Zones:MapChecks()
	if bit.band( Timer.Options, Zones.Options.NoSpeedLimit ) > 0 then
		RunConsoleCommand( "sv_maxvelocity", Zones.Settings.UnlimitedVelocity )
	else
		RunConsoleCommand( "sv_maxvelocity", Zones.Settings.MaxVelocity )
	end
end

function Zones:GetName( nID )
	for name,id in pairs( Zones.Type ) do
		if id == nID then
			return name
		end
	end
	
	return "Unknown"
end

function Zones:GetCenterPoint( nType )
	for _,zone in pairs( Zones.Entities ) do
		if IsValid( zone ) and zone.zonetype == nType then
			local pos = zone:GetPos()
			local height = zone.max.z - zone.min.z
			
			pos.z = pos.z - (height / 2)
			return pos
		end
	end
end

function Zones:GetSpawnPoint( data )
	local vx, vy, vz = 8, 8, 0
	local dx, dy, dz = data[ 2 ].x - data[ 1 ].x, data[ 2 ].y - data[ 1 ].y, data[ 2 ].z - data[ 1 ].z
	
	if dx > 96 then vx = dx - 32 - ((data[ 2 ].x - data[ 1 ].x) / 2) end
	if dy > 96 then vy = dy - 32 - ((data[ 2 ].y - data[ 1 ].y) / 2) end
	if dz > 32 then vz = 16 end
	
	local center = Vector( data[ 3 ].x, data[ 3 ].y, data[ 1 ].z )
	local out = center + Vector( math.random( -vx, vx ), math.random( -vy, vy ), vz )
	
	return out
end


-- Editor
Zones.Editor = {}
Zones.Extra = {
	[4] = "Anticheat",
	[5] = "Restart"
}

function Zones:StartSet( ply, ID )
	if Zones.Extra[ ID ] and not ply.ZoneExtra then
		ply.ZoneExtra = true
		Core:Send( ply, "Print", { "Admin", "You forgot to check 'Add Extra' on a zone that requires it, so I went ahead and did it for you!" } )
	end

	Zones.Editor[ ply ] = {
		Active = true,
		Start = ply:GetPos(),
		Type = ID
	}
	
	Core:Send( ply, "Admin", { "EditZone", Zones.Editor[ ply ] } )
	Core:Send( ply, "Print", { "Admin", Lang:Get( "ZoneStart" ) } )
end

function Zones:CheckSet( ply, finish, extra )
	if Zones.Editor[ ply ] then
		if finish then
			if extra then
				ply.ZoneExtra = nil
			end
			
			Zones:FinishSet( ply, extra )
		end

		return true
	end
end

function Zones:CancelSet( ply, force )
	Zones.Editor[ ply ] = nil
	Core:Send( ply, "Admin", { "EditZone", Zones.Editor[ ply ] } )
	Core:Send( ply, "Print", { "Admin", Lang:Get( force and "ZoneCancel" or "ZoneFinish" ) } )
end

function Zones:FinishSet( ply, extra )
	local editor = Zones.Editor[ ply ]
	if not editor.End then editor.End = ply:GetPos() end
	
	if editor.Type == Zones.Type["LegitSpeed"] then
		if not editor.Steps then
			Zones.Editor[ ply ].Extra = extra
			return Admin:HandleButton( ply, { -2, 26 } )
		else
			editor.Type = tonumber( tostring( editor.Type ) .. tostring( extra ) )
			extra = editor.Extra
		end
	end
	
	local Start, End = editor.Start, editor.End
	local Min = util.TypeToString( Vector( math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z) ) )
	local Max = util.TypeToString( Vector( math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128) ) )
		
	if sql.Query( "SELECT nType FROM game_zones WHERE szMap = '" .. game.GetMap() .. "' AND nType = " .. editor.Type ) and not extra then
		sql.Query( "UPDATE game_zones SET vPos1 = '" .. Min .. "', vPos2 = '" .. Max .. "' WHERE szMap = '" .. game.GetMap() .. "' AND nType = " .. editor.Type )
	else
		sql.Query( "INSERT INTO game_zones VALUES ('" .. game.GetMap() .. "', " .. editor.Type .. ", '" .. Min .. "', '" .. Max .. "')" )
	end
	
	Zones:CancelSet( ply )
	Zones:Reload()
	
	if (editor.Type == Zones.Type["Bonus Start"] or editor.Type == Zones.Type["Bonus End"]) and not extra then
		sql.Query( "DELETE FROM game_times WHERE szMap = '" .. game.GetMap() .. "' AND nStyle = " .. _C.Style.Bonus )
		Timer:LoadRecords()
	end
end

function Zones:PermanentFixes()
	for _,ent in pairs( ents.FindByClass("func_lod") ) do
		ent:SetRenderMode( RENDERMODE_TRANSALPHA )
	end
		
	for _,ent in pairs( ents.GetAll() ) do
		if ent:GetRenderFX() != 0 and ent:GetRenderMode() == 0 then
			ent:SetRenderMode( RENDERMODE_TRANSALPHA )
		end
	end
end

local function KeyValueChecks( ent, key, value )
	if ent:GetClass() == "game_player_equip" then
		if string.sub( key, 1, 4 ) == "ammo" or string.sub( key, 1, 5 ) == "weapon" or string.sub( 1, 5 ) == "item_" then
			return "1"
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueChecks", KeyValueChecks )