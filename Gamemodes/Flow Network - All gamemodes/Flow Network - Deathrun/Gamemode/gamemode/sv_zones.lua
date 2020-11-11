Zones = {}
Zones.Type = {
	StartZone = 1,
	EndZone = 2,
	DamageZone = 3,
	VelocityZone = 4,
}

Zones.Cache = {}
Zones.Entities = {}

Zones.EndPoint = nil

function Zones:Setup()
	Zones.Entities = {}
	
	for _,zone in pairs( Zones.Cache ) do
		local ent = ents.Create( "game_zone" )
		ent:SetPos( (zone.P1 + zone.P2) / 2 )
		ent.min = zone.P1
		ent.max = zone.P2
		ent.zonetype = zone.Type
		ent.data = zone.Data
		
		if zone.Type == Zones.Type.EndZone then
			Zones.EndPoint = (zone.P1 + zone.P2) / 2
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
	
	RTV:LoadData()
	Zones:Setup()
end

function Zones:GetName( nID )
	for name,id in pairs( Zones.Type ) do
		if id == nID then
			return name
		end
	end
	
	return "Unknown"
end


-- Editor
Zones.Editor = {}
Zones.Extra = {}

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
	
	local Start, End = editor.Start, editor.End
	local Min = Vector( math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z) )
	local Max = Vector( math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128) )
	
	print( "[\"" .. Zones:GetName( editor.Type ) .. "_1\"] = {" )
	print( "\tStart = Vector( " .. math.Round( Min.x ) .. ", " .. math.Round( Min.y ) .. ", " .. math.Round( Min.z ) .. " )," )
	print( "\tEnd = Vector( " .. math.Round( Max.x ) .. ", " .. math.Round( Max.y ) .. ", " .. math.Round( Max.z ) .. " )," )
	if editor.Type == Zones.Type.DamageZone then print( "\tMultiplier = 0.0," ) print( "\tType = 0" ) end
	if editor.Type == Zones.Type.VelocityZone then print( "\tVelocity = 350," ) end
	print( "}," )
	
	Zones:CancelSet( ply )
	Zones:Reload()
end


-- Map specific

function Zones:SetupMap()
	if Zones.HasInit then return end
	Zones.HasInit = true
	
	Zones:PermanentFixes()
	Zones:Setup()
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