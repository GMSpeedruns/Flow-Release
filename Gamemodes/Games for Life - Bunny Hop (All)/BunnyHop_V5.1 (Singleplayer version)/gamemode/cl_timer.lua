Timer = {}

local TBegin = nil
local TEnd = nil
local TRecord = 0
local TMapEnd = CurTime() + 7200
local TDifference = 0

function Timer:Start( nTime )
	TBegin = nTime
	TEnd = nil
	Timer:Sync( nTime )
end

function Timer:Stop( nTime )
	TEnd = nTime
	Timer:Sync( nTime )
end

function Timer:Reset()
	TBegin = nil
end

function Timer:SetRecord( nTime )
	TRecord = nTime
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


local mFloor = math.floor
local mFormat = string.format
local mAbs = math.abs
local mClamp = math.Clamp

local function ConvertTime( nSeconds )
	if nSeconds > 3600 then
		return mFormat( "%d:%.2d:%.2d.%.3d", mFloor(nSeconds / 3600), mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	else
		return mFormat( "%.2d:%.2d.%.3d", mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	end
end


local function GetCurrentTime()
	if not TEnd and TBegin then
		return CurTime() - TBegin
	elseif TEnd and TBegin then
		return TEnd - TBegin
	else
		return 0
	end
end

local WRTime = nil
local function GetToWR( nTime, nMode )
	local lCache = Data.Cache.WR.Data
	if lCache and lCache[1] then
		local szPrefix, szRank, bSet = "-", "", nil
		local nDifference = nTime - lCache[1][2]
		if nDifference > 0 then
			szPrefix = "+"
		else
			nDifference = mAbs( nDifference )
		end
		
		for _rank,data in pairs( lCache ) do
			if nTime < data[2] then
				szRank = " [#" .. _rank .. "]"
				bSet = true
				break
			end
		end
		
		if not bSet then
			local nCount = #lCache
			if nCount < 10 then
				szRank = " [#" .. (nCount + 1) .. "]"
			end
		end
		
		return szPrefix .. ConvertTime( nDifference ) .. szRank
	elseif WRTime then
		local szPrefix, szRank, bSet = "-", "", nil
		local nDifference = nTime - WRTime
		if nDifference > 0 then
			szPrefix = "+"
		else
			nDifference = mAbs( nDifference )
		end
		
		return szPrefix .. ConvertTime( nDifference )
	else
		return "N/A [#1]"
	end
end


-- GLOBAL FUNCTIONS
function Timer:Convert( nSeconds )
	if nSeconds > 3600 then
		return mFormat( "%d:%.2d:%.2d.%.3d", mFloor(nSeconds / 3600), mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	else
		return mFormat( "%.2d:%.2d.%.3d", mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60), mFloor(nSeconds * 1000 % 1000) )
	end
end

function Timer:SimpleTime( nSeconds )
	return mFormat( "%.2d:%.2d", mFloor(nSeconds / 60 % 60), mFloor(nSeconds % 60) )
end

function Timer:GetDifference()
	return TDifference
end

function Timer:SetWRTime( nTime )
	WRTime = nTime
end

function Timer:Sync( nSv )
	TDifference = CurTime() - nSv
end

function Timer:SetMode( nMode, nRecord )
	Client.Mode = nMode
	TRecord = nRecord

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

function Timer:LJ( data )
	for i = 1, 5 do
		if not data[i] or not tonumber( data[i] ) then
			return
		else
			data[i] = tonumber( data[i] )
		end
	end
	
	Message:Print( Config.Prefix.LJ, "LJUnits", { data[1] } )
	print( "Long Jump Distance: " .. data[1] .. ", Prestrafe: " .. data[3] .. ", Strafes: " .. data[4] .. ", Max Speed: " .. data[5] .. ", Sync: " .. data[2] )
	if tonumber( data[5] ) > 0 and data[6] and #data[6] > 0 then
		print("#	Max	Gain	Loss	Sync")
		for _,v in pairs( data[6] ) do
			print(v[1] .. "	" .. v[2] .. "	" .. v[3] .. "	" .. v[4] .. "	" .. v[5])
		end
	end
end

local SpecList = {}
local SpecTitle = ""
local SpecTypeRemote = nil
function Timer:SetSpecData( list, bRemote, nCount, bReset )
	SpecList = list
	SpecTypeRemote = bRemote
	SpecTitle = (SpecTypeRemote and "Watching (" or "Spectating (") .. nCount .. "):"
	if bReset then SpecList = {} SpecTitle = "" end
end

-- HUD
local CHUD = CreateClientConVar( "cl_showgui", "1", true, false )
local CSpec = CreateClientConVar( "cl_showspec", "1", true, false )

local DrawText = { Header = "Spectating", Player = "Unknown", Additional = "Time to WR:" }

function GM:HUDPaintBackground()
	if not CHUD:GetBool() then return end
	
	local nWidth, nHeight = ScrW(), ScrH() - 30
	local nHalfW = nWidth / 2
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local ob = LocalPlayer():GetObserverTarget()
		if IsValid( ob ) and ob:IsPlayer() then
			local nMode = ob:GetNWInt( "Mode", Config.Modes["Auto"] )
			local szMode = Config.ModeNames[ nMode ]

			if ob:IsBot() then
				DrawText.Header = "Spectating WR Bot"
				if Spectator.Data.Contains and Spectator.Data.Bot then
					DrawText.Player = Spectator.Data.Player .. " (" .. szMode .. ")"
					DrawText.Additional = "Percentage:"
				else
					DrawText.Player = ob:Name() .. " (" .. szMode .. ")"
					DrawText.Additional = "Time to WR:"
				end
			else
				DrawText.Header = "Spectating"
				DrawText.Player = ob:Name() .. " (" .. szMode .. ")"
				DrawText.Additional = "Time to WR:"
			end
		
			surface.SetDrawColor( Color(44, 62, 80) )
			surface.DrawRect( 20, ScrH() - 145, 230, 125 )
			surface.SetDrawColor( Color(52, 73, 94) )
			surface.DrawRect( 25, ScrH() - 140, 220, 55 )
			surface.DrawRect( 25, ScrH() - 80, 220, 25 )
			surface.DrawRect( 25, ScrH() - 50, 220, 25 )
			
			draw.SimpleText( "Time:", "HUDFont", 30, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( "Best:", "HUDFont", 30, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( DrawText.Additional, "HUDFontSmall", 30, ScrH() - 68, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			
			local nCurrent, nRecord, szPercentage = 0, 0, nil
			if Spectator.Data.Contains then
				nCurrent = Spectator.Data.Start and CurTime() - Spectator.Data.Start or 0
				nRecord = Spectator.Data.Best and Spectator.Data.Best or 0
				
				if nRecord > 0 and ob:IsBot() then
					szPercentage = mFormat( "%.1f", (nCurrent / nRecord) * 100 )
				end
			end
			
			draw.SimpleText( ConvertTime( nCurrent ), "HUDFont", 120, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( ConvertTime( nRecord ), "HUDFont", 120, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( szPercentage and szPercentage or GetToWR( nCurrent, nMode ), "HUDFontSmall", 120, ScrH() - 68, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			
			
			local Speed = ob:GetVelocity():Length2D()
			local BarWidth = (mClamp( Speed, 0, 2000) / 2000 ) * 220
			surface.SetDrawColor( Color(0, 132, 132, 255) )
			surface.DrawRect( 25, ScrH() - 50, BarWidth, 25 )
			
			draw.SimpleText( mFormat( "%.0f", Speed ), "HUDFont", 135, ScrH() - 38, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			draw.SimpleText( DrawText.Header, "HUDHeaderBig", nHalfW + 2, nHeight - 58, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( DrawText.Header, "HUDHeaderBig", nHalfW, nHeight - 60, Color(0, 120, 255, 255), TEXT_ALIGN_CENTER )

			draw.SimpleText( DrawText.Player, "HUDHeader", nHalfW + 2, nHeight - 18, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( DrawText.Player, "HUDHeader", nHalfW, nHeight - 20, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		end

		local text = Config.SpectatorModes[ Spectator.Mode ] .. Lang.HUDSpecMode
		draw.SimpleText( text, "HUDHeader", nHalfW + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text, "HUDHeader", nHalfW, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( Lang.HUDSpecCycle, "HUDTitleSmall", nHalfW, 60, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		
		if not SpecTypeRemote then return end
	else
		surface.SetDrawColor( Color(44, 62, 80) )
		surface.DrawRect( 20, ScrH() - 145, 230, 125 )
		surface.SetDrawColor( Color(52, 73, 94) )
		surface.DrawRect( 25, ScrH() - 140, 220, 55 )
		surface.DrawRect( 25, ScrH() - 80, 220, 25 )
		surface.DrawRect( 25, ScrH() - 50, 220, 25 )
		
		draw.SimpleText( "Time:", "HUDFont", 30, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Best:", "HUDFont", 30, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Time to WR:", "HUDFontSmall", 30, ScrH() - 68, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		
		local nCurrent = GetCurrentTime()
		draw.SimpleText( ConvertTime( nCurrent ), "HUDFont", 120, ScrH() - 125, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( ConvertTime( TRecord ), "HUDFont", 120, ScrH() - 100, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( GetToWR( nCurrent ), "HUDFontSmall", 120, ScrH() - 68, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		
		local BarWidth = (mClamp( Client.Speed, 0, 2000) / 2000 ) * 220
		surface.SetDrawColor( Color(0, 132, 132, 255) )
		surface.DrawRect( 25, ScrH() - 50, BarWidth, 25 )
		
		draw.SimpleText( mFormat( "%.0f", Client.Speed ), "HUDFont", 135, ScrH() - 38, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		local Weapon = LocalPlayer():GetActiveWeapon()
		if Weapon and IsValid( Weapon ) and Weapon.Clip1 then
			local nAmmo = LocalPlayer():GetAmmoCount( Weapon:GetPrimaryAmmoType() )
			local szWeapon = Weapon:Clip1() .. " / " .. nAmmo
			if nAmmo == 0 then return end
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 18, ScrH() - 18, Color(25, 25, 25, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 20, ScrH() - 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end
		
		if SpecTypeRemote then return end
	end
	
	if CSpec:GetBool() then
		local nStart = (nHeight + 30) / 2 - 50
		local nOffset, bDrawn = nStart + 20, false
		for _,name in pairs( SpecList ) do
			if not bDrawn then
				draw.SimpleText( SpecTitle, "HUDLabelSmall", nWidth - 165, nStart, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				bDrawn = true
			end
			
			draw.SimpleText( name, "HUDLabelSmall", nWidth - 165, nOffset, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			nOffset = nOffset + 15
		end
	end
end