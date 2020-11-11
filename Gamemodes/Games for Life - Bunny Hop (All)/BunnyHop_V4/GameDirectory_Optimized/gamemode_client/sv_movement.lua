local function PlayerMove( ply, data )
	local OnGround = ply:IsOnGround()
	if OnGround then
		ply.AirDuck = nil
		
		if not ply.SettingDuck then
			ply.SettingDuck = true
			timer.Simple( 0.05, function()
				if not IsValid( ply ) then return end
				ply:SetDuckSpeed( 0.4 )
				ply:SetUnDuckSpeed( 0.2 )
			end )
		end
	end
	if OnGround or not ply:Alive() then return end
	
	if not ply.AirDuck then
		ply:SetDuckSpeed(0)
		ply:SetUnDuckSpeed(0)
		ply.AirDuck = true
		ply.SettingDuck = nil
	end
	
	if ply.InSpawn and data:GetVelocity():Length2D() > 298 then
		data:SetVelocity( Vector(0, 0, 0) )
		Message:Single( ply, "SpawnSpeed", Config.Prefix.Game )

		return data
	end
end
hook.Add( "Move", "StrafeMovement", PlayerMove )

local function DetectIllegals( ply, key )
	if not IsFirstTimePredicted() then return end
	if not IsValid( ply ) then return end
	if ply.Freestyle then return end

	if ply:Team() == TEAM_HOP and (ply.Mode == Config.Modes["Sideways"] or ply.Mode == Config.Modes["W-Only"]) then
		local data = Config.IllegalKeys[ ply.Mode ]
		for _,k in pairs( data.Key ) do
			if key == k then
				ply:SetLocalVelocity( Vector(0, 0, -100) )
				Message:Single( ply, "KeyLimit", Config.Prefix.Game, { Config.ModeNames[ ply.Mode ] } )
			end
		end
	end
end
hook.Add( "KeyPress", "DetectIllegals", DetectIllegals )

local function NoClipCheck( ply, bState )
	if ply.Mode == Config.Modes["Practice"] then
		return true
	end
	
	return false
end
hook.Add( "PlayerNoClip", "NoClipCheck", NoClipCheck )