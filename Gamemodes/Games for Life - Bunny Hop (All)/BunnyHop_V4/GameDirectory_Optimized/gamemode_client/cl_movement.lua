local function PlayerGround( ply, bWater )
	if Client.Mode == Config.Modes["Scroll"] then
		ply:SetJumpPower( 268.4 )
		timer.Simple(0.3, function()
			ply:SetJumpPower( Config.Player.JumpPower )
		end)
	end
	
	if ply.Jumps then
		ply.Jumps = ply.Jumps + 1
	end
	
	if ply.LJ then
		if not bWater then
			LJ:Complete( ply, ply:GetPos() )
			LJ:Reset( ply )
		else
			LJ:Reset( ply )
		end
	end
end
hook.Add( "OnPlayerHitGround", "HitGround", PlayerGround )

local function PlayerMove( ply, data )
	if CLIENT then
		Client.Speed = data:GetVelocity():Length2D()
	end
	
	local OnGround = ply:IsOnGround()
	if OnGround then
		ply.AirDuck = nil
		
		if not ply.SettingDuck then
			ply.SettingDuck = true
			timer.Simple( 0.05, function()
				if not IsValid( ply ) then return end
				ply:SetDuckSpeed( 0.4 )
				ply:SetUnDuckSpeed( 0.2 )
--[[				ply:SetViewOffset( Config.Player.ViewStand )
				ply:SetViewOffsetDucked( Config.Player.ViewDuck )]]
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
	
	local aim = data:GetMoveAngles()
	local forward, right = aim:Forward(), aim:Right()
	local fmove = data:GetForwardSpeed()
	local smove = data:GetSideSpeed()
	local strafing = false

	if data:KeyDown( IN_MOVERIGHT ) then
		smove = (smove * 10) + 500
		if ply.LJ then
			LJ:Keys( ply, IN_MOVERIGHT, data ) strafing = true
		end
	elseif data:KeyDown( IN_MOVELEFT ) then
		smove = (smove * 10) - 500
		if ply.LJ then
			LJ:Keys( ply, IN_MOVELEFT, data ) strafing = true
		end
	end

	forward.z, right.z = 0,0
	forward:Normalize()
	right:Normalize()

	local wishvel = forward * fmove + right * smove
	wishvel.z = 0

	local wishspeed = wishvel:Length()
	if wishspeed > data:GetMaxSpeed() then
		wishvel = wishvel * (data:GetMaxSpeed() / wishspeed)
		wishspeed = data:GetMaxSpeed()
	end

	local wishspd = wishspeed
	wishspd = math.Clamp(wishspd, 0, 32.4)

	local wishdir = wishvel:GetNormal()
	local current = data:GetVelocity():Dot(wishdir)

	if ply.LJ then
		LJ:BeginMove( ply, strafing, data )
	end
	
	local addspeed = wishspd - current
	if addspeed <= 0 then return end

	local accelspeed = 120 * FrameTime() * wishspeed
	if accelspeed > addspeed then
		accelspeed = addspeed
	end

	local vel = data:GetVelocity()
	vel = vel + (wishdir * accelspeed)
	data:SetVelocity(vel)
	
	if ply.LJ then
		LJ:Accelerate( ply, data )
	end

	return data
end
hook.Add( "Move", "StrafeMovement", PlayerMove )

local function BindDetection( ply, bind, pressed )
	if LocalPlayer():Team() != TEAM_HOP or not pressed then return end
	if Client.Freestyle then return end
	
	if Client.Mode == Config.Modes["Sideways"] or Client.Mode == Config.Modes["W-Only"] then
		local data = Config.IllegalKeys[ Client.Mode ]
		for _,str in pairs( data.Bind ) do
			if string.find(bind, str) then
				Message:Print( Config.Prefix.Game, "BindLimit", { Config.ModeNames[ Client.Mode ] } )
				return true
			end
		end
	elseif not Client.LeftSet and (bind == "+left" or bind == "+right") and Timer.Begin then
		RunConsoleCommand( "leftblock", bind )
		Client.LeftSet = true
	end
end
hook.Add( "PlayerBindPress", "DetectBinds", BindDetection )

local function JumpReset( ply, data )
	if Client.Mode != Config.Modes["Scroll"] then
		local ButtonData = data:GetButtons()
		if ply:WaterLevel() < 2 and ply:GetMoveType() != MOVETYPE_LADDER and not ply:IsFlagSet( FL_ONGROUND ) then
			ButtonData = bit.band( ButtonData, bit.bnot( IN_JUMP ) )
		end
		data:SetButtons( ButtonData )
	end
end
hook.Add( "CreateMove", "ResetSpace", JumpReset )

local function NoClipCheck( ply, bState )
	if Client.Mode == Config.Modes["Practice"] then
		return true
	end
	
	return false
end
hook.Add( "PlayerNoClip", "NoClipCheck", NoClipCheck )