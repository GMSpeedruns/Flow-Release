-- On SERVER SIDE Gamemode file PostInitEntity

	-- This should be put wherever you iterate over all func_door / func_button and see if they're actaul bhoppable platforms
	-- If they are -> Execute this code:
	
		-- THIS IS EXCLUSIVELY FOR DOORS
			for k,v in pairs( ents.FindByClass( "func_door" ) ) do
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
				if ent.BHS then
					ent:SetKeyValue( "locked_sound", ent.BHS )
				else
					ent:SetKeyValue( "locked_sound", "DoorSound.DefaultMove" )
				end
			end
				
		-- THIS IS FOR BUTTONS
			for k,v in pairs( ents.FindByClass( "func_button" ) ) do
				ent:SetRenderMode( RENDERMODE_TRANSALPHA )
				if ent.BHS then
					ent:SetKeyValue( "locked_sound", ent.BHS )
				else
					ent:SetKeyValue( "locked_sound", "None (Silent)" )
				end
			end

---------------------
---------------------
---------------------

-- On SERVER SIDE Lua Autorun / GAMEMODE is fine as well to load the .BHS value (This is necessary for maps like Bhop_Mist to work normally)
local function KeyValueHook( ent, key, value )
	if ent:GetClass() == "func_door" then
		if string.find( string.lower( key ), "noise1" ) then
			ent.BHS = value
		end
	end
	
	if ent:GetClass() == "func_button" then
		if string.find( string.lower( key ), "sounds" ) then
			ent.BHS = value
		end
	end
end
hook.Add( "EntityKeyValue", "KeyValueHook", KeyValueHook )


---------------------
---------------------
---------------------

-- On SERVER AND CLIENT SIDE Lua Autorun

local function GroundHook( ply )
	local ent = ply:GetGroundEntity()
	
    if ent:GetClass() == "func_door" or ent:GetClass() == "func_button" then
		if CLIENT then
			timer.Simple( 0.04, function()
				ent:SetOwner( ply )
				ent:SetColor( Color( 255, 255, 255, 125 ) )
			end )
			timer.Simple( 0.9, function()
				ent:SetOwner( nil )
				ent:SetColor( Color( 255, 255, 255, 255 ) )
			end )
		else
			timer.Simple( 0.04, function() ent:SetOwner( ply ) end )
			timer.Simple( 0.9, function() ent:SetOwner( nil ) end )
		end
	end
end
hook.Add( "OnPlayerHitGround", "GroundHook", GroundHook )

