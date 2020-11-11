Timer = {}
Timer.Begin = nil
Timer.End = nil

Timer.Record = 0
Timer.MapEnd = CurTime() + 7200
Timer.Difference = 0

function Timer:Start( nTime )
	Timer.Begin = nTime
	Timer.End = nil
	Timer:Sync( nTime )
end

function Timer:Stop( nTime )
	Timer.End = nTime
	Timer:Sync( nTime )
end

function Timer:Reset()
	Timer.Begin = nil
end

function Timer:SetRecord( nTime )
	Timer.Record = nTime
end

function Timer:Finish( nTime, nJumps )
	if nJumps then
		Message:Print( Config.Prefix.Timer, "FinishJumps", { Timer:Convert( nTime ), nJumps } )
	else
		Message:Print( Config.Prefix.Timer, "Finish", { Timer:Convert( nTime ) } )
	end
end

function Timer:PB( nNew, nOld, strDisp )
	if nOld == 0 then
		Message:Print( Config.Prefix.Timer, "PBFirst", { Timer:Convert( nNew ), strDisp } )
	else
		Message:Print( Config.Prefix.Timer, "PBImprove", { Timer:Convert( nNew ), Timer:Convert( nOld - nNew ), strDisp } )
	end
	
	Timer:SetRecord( nNew )
end

function Timer:WR( nNew, nOld, strPos, strDisp, bDefend )
	if nOld == 0 then
		Message:Print( Config.Prefix.Timer, "WRFirst", { strPos, Timer:Convert( nNew ), strDisp } )
	else
		Message:Print( Config.Prefix.Timer, bDefend and "WRDefend" or "WRImprove", { strPos, Timer:Convert( nNew ), Timer:Convert( nOld - nNew ), strDisp } )
	end
	
	Timer:SetRecord( nNew )
end


Timer.Floor = math.floor
Timer.Format = string.format
Timer.Absolute = math.abs

function Timer:Convert( nSeconds )
	if nSeconds > 3600 then
		return Timer.Format( "%d:%.2d:%.2d.%.2d", Timer.Floor(nSeconds / 3600), Timer.Floor(nSeconds / 60 % 60), Timer.Floor(nSeconds % 60), Timer.Floor(nSeconds * 100 % 100) )
	else
		return Timer.Format( "%.2d:%.2d.%.2d", Timer.Floor(nSeconds / 60 % 60), Timer.Floor(nSeconds % 60), Timer.Floor(nSeconds * 100 % 100) )
	end
end

function Timer:GetCurrent()
	return Timer:Convert( Timer:GetCurrentTime() )
end

function Timer:GetCurrentTime()
	local TimeData = 0
	
	if not Timer.End and Timer.Begin then
		TimeData = CurTime() - Timer.Begin
	elseif Timer.End and Timer.Begin then
		TimeData = Timer.End - Timer.Begin
	end
	
	return TimeData
end

function Timer:GetRecord()
	return Timer:Convert( Timer.Record )
end

function Timer:GetRemaining()
	return Timer:Convert( Timer.MapEnd - CurTime() + Timer.Difference )
end

function Timer:SetRemaining( nSv, nAdd )
	Timer:Sync( nSv )
	Timer.MapEnd = CurTime() + nAdd
end

function Timer:GetToWR( nTime, nSpecMode )
	local nMode = nSpecMode or Client.Mode 
	local WRCache = Data.Cache.WR[ nMode ]
	if WRCache and WRCache[1] then
		local szPrefix = "-"
		local nDifference = nTime - WRCache[1][2]
		if nDifference > 0 then
			szPrefix = "+"
		else
			nDifference = Timer.Absolute( nDifference )
		end
		
		return szPrefix .. Timer:Convert( nDifference )
	else
		return "N/A"
	end
end

function Timer:Sync( nSv )
	Timer.Difference = CurTime() - nSv
end

function Timer:SetMode( nMode, nRecord )
	Client.Mode = nMode
	Timer.Record = nRecord

	Message:Print( Config.Prefix.Game, "Mode", { Config.ModeNames[ Client.Mode ] } )
end

function Timer:Freestyle( bSet )
	if bSet then
		Client.Freestyle = true
		Message:Print( Config.Prefix.Timer, "FreestyleEnter" )
	else
		Client.Freestyle = nil
		Message:Print( Config.Prefix.Timer, "FreestyleLeave" )
	end
end