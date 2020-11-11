Timer = {}
Timer.Style = _C.Style.Normal

local fl, fo, sf, ab, cl, ct, lp = math.floor, string.format, string.find, math.abs, math.Clamp, CurTime, LocalPlayer
local ts = _C.Team.Spectator

local nTopVel, nTotVel, nCntVel, nAvgVel = 0, 0, 0, 0
local Tn, TnF = nil, nil
local Tbest, Tdifference = 0, 0

local TCache = {}
local CDelay = nil

function Timer:SetStart( nTime )
	Tn = nTime
	TnF = nil
	
	nTopVel = 0
	nTotVel = 0
	nCntVel = 0
end

function Timer:SetFinish( nTime )
	TnF = nTime
	if TnF and Tn then
		return TnF - Tn
	else
		return 0
	end
end

function Timer:SetRecord( nTime )
	Tbest = nTime
end

function Timer:SetStyle( nStyle )
	Timer.Style = nStyle
	if lp and IsValid( lp() ) then
		lp().Style = nStyle
	end
end

function Timer:Sync( nServer )
	Tdifference = CurTime() - nServer
end

function Timer:GetDifference()
	return Tdifference
end

function Timer:GetSpeedData()
	nAvgVel = nTotVel / nCntVel
	
	return { nTopVel, nAvgVel }
end

function Timer:SetInitial( data )
	for _,id in pairs( _C.Style ) do
		if Cache.T_Data[ id ] and data[ id ] then
			Cache.T_Data[ id ][ 1 ] = { [ 3 ] = data[ id ] }
		end
	end
	
	Timer:GetFirstTimes()
end

function Timer:GetFirstTimes()
	for _,id in pairs( _C.Style ) do
		if Cache.T_Data[ id ] and Cache.T_Data[ id ][ 1 ] and Cache.T_Data[ id ][ 1 ][ 3 ] then
			TCache[ id ] = Cache.T_Data[ id ][ 1 ][ 3 ]
		end
	end
end

function Timer:SetRankScalar( nNormal, nAngled )
	for n,data in pairs( _C.Ranks ) do
		if n < 0 then continue end
		_C.Ranks[ n ][ 3 ] = Core:Exp( nNormal, n )
		_C.Ranks[ n ][ 4 ] = Core:Exp( nAngled, n )
	end
end

function Timer:SetFreestyle( bEnabled )
	if lp and IsValid( lp() ) then
		lp().Freestyle = bEnabled
	end
end

function Timer:SetLegitSpeed( nTop )
	if lp and IsValid( lp() ) then
		Core.Util:SetPlayerLegit( lp(), nTop )
		Link:Print( "Bhop Timer", "Your maximum velocity has been changed to " .. nTop )
	end
end

function Timer:SetCheckpoint( nID, bClear, szSpeed )
	if bClear then
		Cache.C_Data[ nID ] = nil
		Link:Print( "Bhop Timer", "Checkpoint #" .. nID .. " has been cleared!" )
	else
		Cache.C_Data[ nID ] = os.date("%H:%M:%S", os.time()) .. " (" .. szSpeed .. ")"
		Link:Print( "Bhop Timer", "Checkpoint saved to #" .. nID )
	end
	
	if Window:IsActive( "Checkpoints" ) then
		local wnd = Window:GetActive()
		wnd.Data.Labels[ nID ]:SetText( nID .. ". " .. (bClear and "None" or Cache.C_Data[ nID ]) )
		wnd.Data.Labels[ nID ]:SizeToContents()
	end
end

function Timer:StartCheckpointDelay()
	CDelay = CurTime() + 1.5
end

function Timer:ShowStats( data )
	Window:Open( "Stats", data )
	
	print( "[" .. data.Title .. "] " .. data.Distance .. " units (Strafes: " .. #data.SyncValues .. ", Prestrafe: " .. data.Prestrafe .. " u/s, Average Sync: " .. data.Sync .. "%)" )
	print( "#", "Speed", "\tGain", "Loss", "Sync" )
	
	for i = 1, #data.SyncValues do
		local nGain, nLoss, nNext, nThis = 0, 0, data.SpeedValues[ i + 1 ], data.SpeedValues[ i ]
		if nNext then
			if nNext > nThis then nGain = nNext - nThis
			elseif nNext < nThis then nLoss = nThis - nNext end
		end
		
		print( i, nThis .. " u/s", "\t+" .. nGain, nLoss > 0 and "-" .. nLoss or 0, data.SyncValues[ i ] .. "%" )
	end
end


local function SpeedTracker()
	local lpc = lp()
	if not IsValid( lpc ) or not Tn then return end

	local nSpeed = lpc:GetVelocity():Length2D() or 0
	if nSpeed > nTopVel then
		nTopVel = nSpeed
	end
	
	nTotVel = nTotVel + nSpeed
	nCntVel = nCntVel + 1
end
hook.Add( "Think", "SpeedTracker", SpeedTracker )

local function BindTracker( ply, bind )
	if sf( bind, "+left" ) or sf( bind, "+right" ) then return true end
	if sf( bind, "+jump" ) and Client.SpaceToggle then Client:ToggleSpace() end
end
hook.Add( "PlayerBindPress", "BindPrevention", BindTracker )

local function ConvertTime( ns )
	if ns > 3600 then
		return fo( "%d:%.2d:%.2d.%.3d", fl( ns / 3600 ), fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	else
		return fo( "%.2d:%.2d.%.3d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
	end
end

local function GetCurrentTime()
	if not TnF and Tn then
		return ct() - Tn
	elseif TnF and Tn then
		return TnF - Tn
	else
		return 0
	end
end

local function GetTimePiece( nCompare, nStyle )
	local nFirst = TCache[ nStyle or Timer.Style ]
	if not nFirst then return "" end
	
	local nDifference = nCompare - nFirst
	local nAbs = ab( nDifference )

	if nDifference < 0 then
		return fo( " [ -%.2d:%.2d]", fl( nAbs / 60 ), fl( nAbs % 60 ) )
	elseif nDifference == 0 then
		return " [WR]"
	else
		return fo( " [+%.2d:%.2d]", fl( nAbs / 60 ), fl( nAbs % 60 ) )
	end
end


function Timer:Convert( ns ) return ConvertTime( ns ) end
function Timer:GetConvert() return ConvertTime end


local ViewGUI = CreateClientConVar( "sl_showgui", "1", true, false )
local ViewSpec = CreateClientConVar( "sl_showspec", "1", true, false )
local GUI_X = CreateClientConVar( "sl_gui_xoffset", "20", true, false )
local GUI_Y = CreateClientConVar( "sl_gui_yoffset", "115", true, false )
local GUI_O = CreateClientConVar( "sl_gui_opacity", "255", true, false )

local Xo = GUI_X:GetInt() or 20
local Yo = GUI_Y:GetInt() or 115
local Ov = GUI_O:GetInt() or 255

local function HUDEditTick()
	local step = input.IsKeyDown( KEY_LSHIFT ) and 20 or 5
	if input.IsKeyDown( KEY_RIGHT ) and not input.IsKeyDown( KEY_LEFT ) then
		Xo = Xo + step
	elseif input.IsKeyDown( KEY_LEFT ) and not input.IsKeyDown( KEY_RIGHT ) then
		Xo = Xo - step
	end
	
	if input.IsKeyDown( KEY_UP ) and not input.IsKeyDown( KEY_DOWN ) then
		Yo = Yo + step
	elseif input.IsKeyDown( KEY_DOWN ) and not input.IsKeyDown( KEY_UP ) then
		Yo = Yo - step
	end
	
	if Xo < 0 then Xo = Xo + step end
	if Xo + 230 > ScrW() then Xo = Xo - step end
	
	if Yo - 95 < 0 then Yo = Yo + step end
	if Yo > ScrH() then Yo = Yo - step end
end

function Timer:ToggleEdit()
	if not Timer.HUDEdit then
		Timer.HUDEdit = true
		timer.Create( "HUDEdit", 0.05, 0, HUDEditTick )
		
		Link:Print( "General", "You are now editing your HUD position! Use your arrow keys to move it around! Type !hudedit again to save." )
	else
		Timer.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		Timer:SetHUDPosition( Xo, Yo )
		
		Link:Print( "General", "HUD editing has been disabled again. The new position has been saved!" )
	end
end

function Timer:RestoreTo( pos )
	if Timer.HUDEdit then
		Timer.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		
		Link:Print( "General", "HUD editing was enabled. We disabled it for you so if you want to use it again, please type !hudedit." )
	end
	
	Timer:SetHUDPosition( pos[ 1 ], pos[ 2 ] )
	Link:Print( "General", "HUD has been restored to its initial position." )
end

function Timer:SetOpacity( o )
	RunConsoleCommand( "sl_gui_opacity", o )
	
	Ov = o
	
	Link:Print( "General", "HUD opacity has been changed to " .. o .. " (" .. math.Round( (o / 255) * 100, 1 ) .. "%)" )
end

function Timer:SetHUDPosition( x, y )
	RunConsoleCommand( "sl_gui_xoffset", x )
	RunConsoleCommand( "sl_gui_yoffset", y )

	Xo = x
	Yo = y
end

function Timer:GUIVisibility( nTarget )
	local nNew = -1
	if nTarget < 0 then
		nNew = 1 - ViewGUI:GetInt()
		RunConsoleCommand( "sl_showgui", nNew )
	else
		nNew = nTarget
		RunConsoleCommand( "sl_showgui", nNew )
	end
	
	if nNew >= 0 then
		Link:Print( "General", "You have set GUI visibility to " .. (nNew == 0 and "invisible" or "visible") )
	end
end

function Timer:GetSpecSetting()
	return ViewSpec:GetInt()
end

local CPSData = nil
function Timer:SetCPSData( data )
	CPSData = data
end


local CSList = {}
local CSData = { Contains = nil, Bot = false, Player = "Unknown", Start = nil, Record = nil }
local CSRemote = false
local CSTitle = ""
local CSModes = { "First Person", "Chase Cam", "Free Roam" }
local CSDraw = { Header = "Spectating", Player = "Unknown" }

function Timer:SpectateData( varArgs, bRemote, nCount, bReset )
	CSList = varArgs
	CSRemote = bRemote
	CSTitle = "People " .. (CSRemote and "watching player " or "spectating you ") .. "(#" .. nCount .. "):"
	
	if bReset then
		CSList = {}
		CSTitle = ""
	end
end

function Timer:SpectateUpdate()
	CSData = Cache.S_Data
end


function GM:HUDPaintBackground()
	if not ViewGUI:GetBool() then return end
	
	local nWidth, nHeight = ScrW(), ScrH() - 30
	local nHalfW = nWidth / 2
	local lpc = lp()
	
	if not IsValid( lpc ) then return end
	
	if lpc:Team() == ts then
		local ob = lp():GetObserverTarget()
		if IsValid( ob ) and ob:IsPlayer() then
			local nStyle = ob:GetNWInt( "Style", _C.Style.Normal )
			local szStyle = Core:StyleName( nStyle )
			local bData = CSData.Contains
			
			if ob:IsBot() then
				CSDraw.Header = "Spectating Bot"
				CSDraw.Player = ((bData and CSData.Bot) and CSData.Player or "Waiting bot") .. " (" .. szStyle .. " style)"
			else
				CSDraw.Header = "Spectating"
				CSDraw.Player = ob:Name() .. " (" .. szStyle .. ")"
			end
			
			surface.SetDrawColor( Color(35, 35, 35, Ov) )
			surface.DrawRect( Xo, ScrH() - Yo, 230, 95 )
			surface.SetDrawColor( Color(42, 42, 42, Ov) )
			surface.DrawRect( Xo + 5, ScrH() - Yo + 5, 220, 55 )
			surface.DrawRect( Xo + 5, ScrH() - Yo + 65, 220, 25 )
			
			draw.SimpleText( "Time:", "HUDTimer", Xo + 12, ScrH() - Yo + 20, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( "PB:", "HUDTimer", Xo + 12, ScrH() - Yo + 45, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

			local nCurrent, nRecord, nSpeed = 0, 0, ob:GetVelocity():Length2D()
			if bData then
				nCurrent = CSData.Start and CurTime() - CSData.Start or 0
				nRecord = CSData.Best and CSData.Best or 0
			end
			
			draw.SimpleText( ConvertTime( nCurrent ) .. GetTimePiece( nCurrent, nStyle ), "HUDTimer", Xo + 64 + 12, ScrH() - Yo + 20, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			draw.SimpleText( ConvertTime( nRecord ) .. GetTimePiece( nRecord, nStyle ), "HUDTimer", Xo + 64 + 12, ScrH() - Yo + 45, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

			local cp = cl( nSpeed, 0, 3500 ) / 3500
			surface.SetDrawColor( Color( 42 + cp * 213, 42, 42, Ov ) )
			surface.DrawRect( Xo + 5, ScrH() - Yo + 65, cp * 220, 25 )
			
			draw.SimpleText( fo( "%.0f u/s", nSpeed ), "HUDSpeed", Xo + 115, ScrH() - Yo + 77, Color(255, 255, 255, Ov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			draw.SimpleText( CSDraw.Header, "HUDHeaderBig", nHalfW + 2, nHeight - 58, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( CSDraw.Header, "HUDHeaderBig", nHalfW, nHeight - 60, Color(214, 59, 43, 255), TEXT_ALIGN_CENTER )

			draw.SimpleText( CSDraw.Player, "HUDHeader", nHalfW + 2, nHeight - 18, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( CSDraw.Player, "HUDHeader", nHalfW, nHeight - 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
		end

		local text = CSModes[ Cache:S_GetType() ] .. " - Press R to change spectate mode"
		draw.SimpleText( text, "HUDHeader", nHalfW + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text, "HUDHeader", nHalfW, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( "Cycle through players with left/right mouse", "HUDTitleSmall", nHalfW, 60, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		
		if not CSRemote then return end
	else
		surface.SetDrawColor( Color(35, 35, 35, Ov) )
		surface.DrawRect( Xo, ScrH() - Yo, 230, 95 )
		surface.SetDrawColor( Color(42, 42, 42, Ov) )
		surface.DrawRect( Xo + 5, ScrH() - Yo + 5, 220, 55 )
		surface.DrawRect( Xo + 5, ScrH() - Yo + 65, 220, 25 )
		
		draw.SimpleText( "Time:", "HUDTimer", Xo + 12, ScrH() - Yo + 20, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "PB:", "HUDTimer", Xo + 12, ScrH() - Yo + 45, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		local nCurrent, nSpeed = GetCurrentTime(), lpc:GetVelocity():Length2D()
		draw.SimpleText( ConvertTime( nCurrent ) .. GetTimePiece( nCurrent ), "HUDTimer", Xo + 64 + 12, ScrH() - Yo + 20, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( ConvertTime( Tbest ) .. GetTimePiece( Tbest ), "HUDTimer", Xo + 64 + 12, ScrH() - Yo + 45, Color(255, 255, 255, Ov), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )

		local cp = cl( nSpeed, 0, 3500 ) / 3500
		surface.SetDrawColor( Color( 42 + cp * 213, 42, 42, Ov ) )
		surface.DrawRect( Xo + 5, ScrH() - Yo + 65, cp * 220, 25 )
		
		draw.SimpleText( fo( "%.0f u/s", nSpeed ), "HUDSpeed", Xo + 115, ScrH() - Yo + 77, Color(255, 255, 255, Ov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if CPSData then
			draw.SimpleText( CPSData, "HUDTimer", nWidth - 20, (nHeight + 30) / 2 - 80, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
		end
		
		if CDelay then
			local szText = fo( "%.1f", CDelay - CurTime() )
			if CurTime() > CDelay then szText = "" CDelay = nil end
			draw.SimpleText( szText, "HUDCounter", nWidth / 2, (nHeight + 30) / 2 - 150, Color(0, 120, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
		local w = lpc:GetActiveWeapon()
		if IsValid( w ) and w.Clip1 then
			local nAmmo = lpc:GetAmmoCount( w:GetPrimaryAmmoType() )
			local szWeapon = w:Clip1() .. " / " .. nAmmo
			if nAmmo == 0 then return end
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 18, ScrH() - 18, Color(25, 25, 25, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 20, ScrH() - 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end
		
		if CSRemote then return end
	end
	
	if ViewSpec:GetBool() then
		local nStart = (nHeight + 30) / 2 - 50
		local nOffset, bDrawn = nStart + 20, false
		for _,name in pairs( CSList ) do
			if not bDrawn then
				draw.SimpleText( CSTitle, "HUDLabelSmall", nWidth - 165, nStart, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				bDrawn = true
			end
			
			draw.SimpleText( "- " .. name, "HUDLabelSmall", nWidth - 165, nOffset, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			nOffset = nOffset + 15
		end
	end
end