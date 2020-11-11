ADMIN = {}

local AuthorizedIDs = {
	"3974409736", -- Gravious
}

function ADMIN:HasAccess(ply)
	if table.HasValue(AuthorizedIDs, ply:UniqueID()) then
		return true
	end
	
	-- Steam authorization
	
	return false
end

function ADMIN:FindPlayers(str, single)
	local targets = {}
	for k,v in pairs(player.GetAll()) do
		if string.find(string.lower(v:Name()), string.lower(str), 1, true) then
			table.insert(targets, v)
		end
	end
	
	if #targets == 1 and not single then
		return targets
	elseif single then
		if #targets == 1 then
			return targets[1]
		else
			return nil
		end
	else
		return targets
	end
end

function ADMIN:AreaAddNew(admin, map, id, vec1, vec2)
	local current = sql.Query("SELECT * FROM mapdata WHERE map_name = '" .. map .. "'")
	if not current or #current < 1 then
		-- ToDo
		ply:SendMessage(MSG_ADMIN_GENERAL, {"This function is still under construction!"})
	else
		admin:SendMessage(MSG_ADMIN_GENERAL, {"The map '" .. map .. "' already has entered data. Delete it first!"})
	end
end

function ADMIN:Unstuck(admin, ply)
	if ply:GetMoveType() == MOVETYPE_OBSERVER or not ply:Alive() then return end
	ply:Freeze(true)
	ply:SendMessage(MSG_ADMIN_GENERAL, {"You have been unstucked by " .. admin:Name()})

	local pos = ply:GetShootPos()
	local ang = ply:GetAimVector()
	local forward = ply:GetForward()
	local center = Vector( 0, 0, 30 )
	local realpos = ( (pos + center ) + (forward * 75) )
		
	local chprop = ents.Create( "prop_physics" )		
	chprop:SetModel( "models/props_c17/oildrum001.mdl" )
	chprop:SetPos( realpos )
	chprop:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	chprop:SetOwner( ply )
	chprop:SetNoDraw( true )
	chprop:DrawShadow( false )
	chprop:DropToFloor()
	chprop:Spawn()

	local p = chprop:GetPhysicsObject()
	if IsValid( p ) then
		p:EnableMotion( false )
	end
		
	local tracedata = {}
	tracedata.start = pos
	tracedata.endpos = chprop:GetPos()
	tracedata.filter = ply	
	
	local trace = util.TraceLine(tracedata)
	timer.Simple(.5, function()
		ply:Freeze(false)
			
		if IsValid( chprop:GetGroundEntity() ) then
			local gent = chprop:GetGroundEntity()
			gent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
			timer.Simple(1, function()
				gent:SetCollisionGroup( COLLISION_GROUP_NONE )
			end)
		end
		
		if chprop:IsInWorld() then			
			if trace.Entity == chprop then
				ply:SetPos( chprop:GetPos() )
			end
		end
				
		chprop:Remove()
	end)
end