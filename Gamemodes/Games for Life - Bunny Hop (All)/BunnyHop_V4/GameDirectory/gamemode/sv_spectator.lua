Spectator = {}
Spectator.Modes = {
	OBS_MODE_IN_EYE,
	OBS_MODE_CHASE,
	OBS_MODE_ROAMING
}

local function PlayerPressKey( ply, key )
	if ply:Team() != TEAM_SPECTATOR then return end
	
	if not ply.SpectateID then ply.SpectateID = 1 end
	if not ply.SpectateType then ply.SpectateType = 1 end
	
	if key == IN_ATTACK then
		local ar = Spectator:GetAlive()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID + 1
		Spectator:Mode( ply, true )
		Spectator:Change( ar, ply, true )
	elseif key == IN_ATTACK2 then
		local ar = Spectator:GetAlive()
		ply.SpectateType = 1
		ply.SpectateID = ply.SpectateID - 1
		Spectator:Mode( ply, true )
		Spectator:Change( ar, ply, false )
	elseif key == IN_RELOAD then
		local ar = Spectator:GetAlive()
		if #ar == 0 then
			ply.SpectateType = #Spectator.Modes
			Spectator:Mode( ply, true )
		else
			ply.SpectateType = ply.SpectateType + 1 > #Spectator.Modes and 1 or ply.SpectateType + 1
			Spectator:Mode( ply )
		end
	end
end
hook.Add( "KeyPress", "SpectatorKey", PlayerPressKey )

function Spectator:Change( ar, ply, forward )
	local previous = ply:GetObserverTarget()
	
	if #ar == 1 then
		ply.SpectateID = forward and ply.SpectateID - 1 or ply.SpectateID + 1
		return
	end

	if not ar[ ply.SpectateID ] then
		ply.SpectateID = forward and 1 or #ar
		if not ar[ ply.SpectateID ] then ply.CommandTimer = nil Command.Spectate( ply ) return end
	end

	ply:SpectateEntity( ar[ ply.SpectateID ] )
	Spectator:Checks( ply, previous )
end

function Spectator:Mode( ply, cancel )
	if ply.SpectateType == #Spectator.Modes and not cancel then
		Spectator:End( ply, ply:GetObserverTarget() )
	end
	
	ply:Spectate( Spectator.Modes[ply.SpectateType] )
	ply:SendLua( "Spectator:SetMode(" .. ply.SpectateType .. ")" )
end

function Spectator:End( ply, watching )
	if not IsValid( watching ) then return end
	Spectator:Notify( watching, ply, true )
	Spectator:NotifyWatchers( watching )
end

function Spectator:New( ply )
	local ar = Spectator:GetAlive()
	if #ar == 0 then
		ply.SpectateType = #Spectator.Modes
		Spectator:Mode( ply, true )
	else
		ply.SpectateType = 1
		if not ply.SpectateID then ply.SpectateID = 1 end
		if not ar[ ply.SpectateID ] then ply.SpectateID = 1 end
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( ar[ ply.SpectateID ] )
		ply:SendLua( "Spectator:SetMode(" .. ply.SpectateType .. ")" )
		Spectator:Checks( ply )
	end
end

function Spectator:NewById( ply, szUID )
	local ar = Spectator:GetAlive()
	local target = { ID = nil, Ent = nil }
	for id, p in pairs( ar ) do 
		if tostring( p:UniqueID() ) == tostring( szUID ) then
			target.Ent = p
			target.ID = id
			break
		end
	end
	if target.Ent then
		ply.SpectateType = 1
		ply.SpectateID = target.ID
		ply:Spectate( Spectator.Modes[ ply.SpectateType ] )
		ply:SpectateEntity( target.Ent )
		ply:SendLua( "Spectator:SetMode(" .. ply.SpectateType .. ")" )
		Spectator:Checks( ply )
	else
		return Message:Single( ply, "SpectatorInvalid", Config.Prefix.Game )
	end
end


function Spectator:Checks( ply, previous )
	local current = ply:GetObserverTarget()
	if IsValid( current ) then
		if current:IsBot() then
			Spectator:NotifyBot( current )
		else
			Spectator:Notify( current, ply )
		end
	end

	if IsValid( previous ) then
		Spectator:Notify( previous, ply, true )
	end
end

function Spectator:Notify( target, ply, bLeave )
	if bLeave then
		Spectator:NotifyWatchers( target )
		return Data:Single( target, "SpecViewer", { false, ply:Name(), ply:UniqueID() } )
	else
		Data:Single( target, "SpecViewer", { true, ply:Name(), ply:UniqueID() } )
	end
	
	Spectator:NotifyWatchers( target )
end

function Spectator:NotifyBot( bot )
	if not Bot.Data[ bot.Mode ] then return end
	
	Spectator:NotifyWatchers( bot )
end

function Spectator:PlayerRestart( ply )
	local nTimer = ply.timerB or ply.timer
	for _, p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid( ob ) and ob == ply and nTimer then
			Data:Single( p, "SpecTimer", { false, nTimer, (ply.CurrentRecord and ply.CurrentRecord > 0) and ply.CurrentRecord or nil, CurTime(), "save" } )
		end
	end
end

function Spectator:NotifyWatchers( ply )
	local SpectatorList, Watchers = {}, {}
	for _, p in pairs( player.GetHumans() ) do
		if not p.Spectating then continue end
		local ob = p:GetObserverTarget()
		if IsValid(ob) and ob == ply then
			table.insert( Watchers, p )
			table.insert( SpectatorList, p:Name() )
		end
	end
	
	if #SpectatorList == 0 then SpectatorList = nil end
	
	local data = {}
	if ply:IsBot() then
		data = { true, Bot.ReplayData[ ply.Mode ].Start, Bot.Data[ ply.Mode ].Name, Bot.Data[ ply.Mode ].Time, CurTime(), SpectatorList }
	else
		data = { false, false, (ply.CurrentRecord and ply.CurrentRecord > 0) and ply.CurrentRecord or nil, CurTime(), SpectatorList }
		if not ply.InSpawn and ply.timer then data[2] = ply.timer end
	end
	
	if #Watchers > 0 then
		Data:Single( Watchers, "SpecTimer", data )
	end
end

function Spectator:GetAlive()
	local d = {}
	for k,v in pairs(player.GetAll()) do
		if v:Team() == TEAM_HOP and v:Alive() then 
			table.insert(d, v)
		end
	end
	return d
end