include( "sh_settings.lua" )
include( "cl_movement.lua" )
include( "cl_view.lua" )
include( "cl_lang.lua" )
include( "cl_timer.lua" )
include( "cl_datatransfer.lua" )
include( "cl_gui.lua" )
include( "cl_scoreboard.lua" )
include( "cl_spectator.lua" )
include( "modules/cl_admin.lua" )

Client = {}
Client.Speed = 0
Client.AFKChecks = 0
Client.ThirdPerson = 0
Client.Mode = Config.Modes["Auto"]

Client.CHUD = CreateClientConVar( "cl_showgui", "1", true, false )
Client.CSpec = CreateClientConVar( "cl_showspec", "1", true, false )
Client.CPlayers = CreateClientConVar( "cl_showothers", "1", true, false )

Client.HUD = {}
Client.HUD.Hidden = { ["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true, ["CHudCrosshair"] = true, ["CHudSuitPower"] = true }

function GM:Initialize()
	timer.Create( "ClientTick", 5, 0, Client.Tick )
	
	Client:TestMaps()
end

function GM:CalcView( ply, vPos, vAng, nFov )
	if Client.ThirdPerson == 1 then
		vPos = vPos - (vAng:Forward() * 100) + (vAng:Up() * 40)
		
		local vAngTemp = (ply:GetPos() + (vAng:Up() * 30)) - vPos
		vAngTemp:Normalize()
		vAng = vAngTemp:Angle()
	end
	
	return self.BaseClass:CalcView( ply, vPos, vAng, nFov )
end

function GM:ShouldDrawLocalPlayer( ply )
	return Client.ThirdPerson == 1 and true or self.BaseClass:ShouldDrawLocalPlayer( ply )
end

function GM:HUDShouldDraw( szApplet )
	return not Client.HUD.Hidden[ szApplet ]
end


function GM:HUDPaint()
	if not Client.CHUD:GetBool() then return self.BaseClass:HUDPaint() end
	
	local nWidth, nHeight = ScrW(), ScrH() - 30
	local nHalfW = nWidth / 2
	
	local ob = LocalPlayer():GetObserverTarget()
	if IsValid( ob ) and ob:IsPlayer() then
		local nMode = ob:GetNWInt( "Mode", Config.Modes["Auto"] )
		local szMode = Config.ModeNames[ nMode ]
		local text = { Header = "Spectating", Player = ob:Name() .. " (" .. szMode .. ")" }
		if ob:IsBot() then
			text.Header = "Spectating WR Bot"
			if Spectator.Data.Contains and Spectator.Data.Bot then
				text.Player = Spectator.Data.Player .. " (" .. szMode .. ")"
			end
		end
	
		surface.SetDrawColor( GUIColor.DarkGray )
		surface.DrawRect( 20, ScrH() - 145, 230, 125 )
		surface.SetDrawColor( GUIColor.LightGray )
		surface.DrawRect( 25, ScrH() - 140, 220, 55 )
		surface.DrawRect( 25, ScrH() - 80, 220, 25 )
		surface.DrawRect( 25, ScrH() - 50, 220, 25 )
		
		draw.SimpleText( "Time:", "HUDFont", 30, ScrH() - 125, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Best:", "HUDFont", 30, ScrH() - 100, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( "Time to WR:", "HUDFontSmall", 30, ScrH() - 68, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		
		local nCurrent, nRecord = 0, 0
		if Spectator.Data.Contains then
			nCurrent = Spectator.Data.Start and CurTime() - Spectator.Data.Start or 0
			nRecord = Spectator.Data.Best and Spectator.Data.Best or 0
		end
		
		draw.SimpleText( Timer:Convert( nCurrent ), "HUDFont", 120, ScrH() - 125, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( Timer:Convert( nRecord ), "HUDFont", 120, ScrH() - 100, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( Timer:GetToWR( nCurrent, nMode ), "HUDFontSmall", 120, ScrH() - 68, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		
		
		local Speed = ob:GetVelocity():Length2D()
		local BarWidth = (math.Clamp( Speed, 0, 2000) / 2000 ) * 220
		surface.SetDrawColor( Color(0, 132, 132, 255) )
		surface.DrawRect( 25, ScrH() - 50, BarWidth, 25 )
		
		draw.SimpleText( string.format( "%.0f", Speed ), "HUDFont", 135, ScrH() - 38, GUIColor.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		draw.SimpleText( text.Header, "HUDHeaderBig", nHalfW + 2, nHeight - 58, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text.Header, "HUDHeaderBig", nHalfW, nHeight - 60, Color(0, 120, 255, 255), TEXT_ALIGN_CENTER )

		draw.SimpleText( text.Player, "HUDHeader", nHalfW + 2, nHeight - 18, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text.Player, "HUDHeader", nHalfW, nHeight - 20, GUIColor.White, TEXT_ALIGN_CENTER )
	end
	
	local SpecList = { Caption = "Spectators:", Data = Spectator.OwnList }
	if LocalPlayer():Team() == TEAM_SPECTATOR then
		local text = Config.SpectatorModes[ Spectator.Mode ] .. Lang.HUDSpecMode
		draw.SimpleText( text, "HUDHeader", nHalfW + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text, "HUDHeader", nHalfW, 30, GUIColor.White, TEXT_ALIGN_CENTER )
		draw.SimpleText( Lang.HUDSpecCycle, "HUDTitleSmall", nHalfW, 60, GUIColor.White, TEXT_ALIGN_CENTER )
		
		SpecList = { Caption = "Watching:", Data = Spectator.RemList }
	end
	
	if Client.CSpec:GetBool() then
		local nStart = (nHeight + 30) / 2 - 50
		local nOffset, bDrawn = nStart + 20, false
		for _,name in pairs( SpecList.Data ) do
			if not bDrawn then
				draw.SimpleText( SpecList.Caption, Fonts.Label, nWidth - 165, nStart, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
				bDrawn = true
			end
			
			draw.SimpleText( name, Fonts.Label, nWidth - 165, nOffset, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
			nOffset = nOffset + 15
		end
	end
	
	return self.BaseClass:HUDPaint()
end

function GM:HUDPaintBackground()
	if not Client.CHUD:GetBool() then return end
	if LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR then return end
	
	surface.SetDrawColor( GUIColor.DarkGray )
	surface.DrawRect( 20, ScrH() - 145, 230, 125 )
	surface.SetDrawColor( GUIColor.LightGray )
	surface.DrawRect( 25, ScrH() - 140, 220, 55 )
	surface.DrawRect( 25, ScrH() - 80, 220, 25 )
	surface.DrawRect( 25, ScrH() - 50, 220, 25 )
	
	draw.SimpleText( "Time:", "HUDFont", 30, ScrH() - 125, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( "Best:", "HUDFont", 30, ScrH() - 100, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( "Time to WR:", "HUDFontSmall", 30, ScrH() - 68, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	
	draw.SimpleText( Timer:GetCurrent(), "HUDFont", 120, ScrH() - 125, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( Timer:GetRecord(), "HUDFont", 120, ScrH() - 100, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	draw.SimpleText( Timer:GetToWR( Timer:GetCurrentTime() ), "HUDFontSmall", 120, ScrH() - 68, GUIColor.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	
	local BarWidth = (math.Clamp( Client.Speed, 0, 2000) / 2000 ) * 220
	surface.SetDrawColor( Color(0, 132, 132, 255) )
	surface.DrawRect( 25, ScrH() - 50, BarWidth, 25 )
	
	draw.SimpleText( string.format( "%.0f", Client.Speed ), "HUDFont", 135, ScrH() - 38, GUIColor.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

	local Weapon = LocalPlayer():GetActiveWeapon()
	if Weapon and IsValid( Weapon ) and Weapon.Clip1 then
		local nAmmo = LocalPlayer():GetAmmoCount( Weapon:GetPrimaryAmmoType() )
		local szWeapon = Weapon:Clip1() .. " / " .. nAmmo
		if nAmmo == 0 then return end
		draw.SimpleText( szWeapon, "HUDHeader", ScrW() - 18, ScrH() - 18, Color(25, 25, 25, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		draw.SimpleText( szWeapon, "HUDHeader", ScrW() - 20, ScrH() - 20, GUIColor.White, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end
end


function Client.Tick()
	if not IsValid( LocalPlayer() ) then return end
	
	if not Client.ViewSet then
		LocalPlayer():SetViewOffset( Config.Player.ViewStand )
		LocalPlayer():SetViewOffsetDucked( Config.Player.ViewDuck )
		Client.ViewSet = true
	end
	
	LocalPlayer():SetHull( Config.Player.HullMin, Config.Player.HullStand )
	LocalPlayer():SetHullDuck( Config.Player.HullMin, Config.Player.HullDuck )

	if Client.Speed < 1 and LocalPlayer():Team() != TEAM_SPECTATOR then
		Client.AFKChecks = Client.AFKChecks + 1
		
		if Client.AFKChecks >= (Timer.Start and Config.Player.AFKLimit * 3 or Config.Player.AFKLimit) then
			RunConsoleCommand("afk")
			Client.AFKChecks = 0
		end
	else
		Client.AFKChecks = 0
	end
end

function Client:IsChatEnabled()
	return GetConVar( "hud_saytext_time" ):GetInt() > 0
end

function Client:MapName( szName )
	if string.StartWith( szName, "bhop_" ) then
		szName = string.sub( szName, 6 )
	end
	
	return string.gsub( szName, "_", " " )
end

function Client:ShowHelp( szID )
	if not Lang.Help[ szID ] then return end
	local Split = string.Explode( "\n", Lang.Help[ szID ] )
	for _, text in pairs( Split ) do
		chat.AddText( GUIColor.White, "[", GUIColor.DarkGray, "Info", GUIColor.White, "] ", text )
	end
	if Client:IsChatEnabled() then chat.PlaySound() end
end

function Client:ShowRanks( nRank, nPoints )
	local PlayerRank = Config.Ranks[ nRank ]
	
	print( "You are currently ranked, with " .. nPoints .. " points:" )
	MsgC( PlayerRank[2], PlayerRank[1] .. "\n\n" )
	
	print( "Below is the list of ranks active on the server:" )
	for RankID, Data in pairs( Config.Ranks ) do
		if RankID < 1 then continue end
		MsgC( Data[2], "#" .. RankID .. ": " .. Data[1] .. " - " .. Data[3] .. "\n" )
	end

	Message:Print( Config.Prefix.Command, "HUDRankPrint" )
end


function Client.DrawBlock( ply )
	ply:SetNoDraw( not Client.CPlayers:GetBool() )
	if not Client.CPlayers:GetBool() then return true end
end
hook.Add( "PrePlayerDraw", "BlockPlayerDraw", Client.DrawBlock )

function Client.RankedChat( ply, szText, bTeam, bDead )
	local tab = {}
	if bTeam then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end
	
	if ply:GetNWInt( "Spectating", 0 ) == 1 then
		table.insert( tab, Color( 189, 195, 199 ) )
		table.insert( tab, "*SPEC* " )
	end
	
	if IsValid( ply ) then
		local RankID = ply:GetNWInt( "Rank", 1 )
		table.insert( tab, GUIColor.White )
		table.insert( tab, "[" )
		table.insert( tab, Config.Ranks[ RankID ][2] )
		table.insert( tab, Config.Ranks[ RankID ][1] )
		table.insert( tab, GUIColor.White )
		table.insert( tab, "] " )
		table.insert( tab, Color( 98, 176, 255 ) )
		table.insert( tab, ply:Name() )
	else
		table.insert( tab, "Console" )
	end
	
	table.insert( tab, GUIColor.White )
	table.insert( tab, ": " .. szText )
	
	chat.AddText( unpack( tab ) )
	return true
end
hook.Add( "OnPlayerChat", "RankedChat", Client.RankedChat )

function Client:TestMaps()
	if file.Exists( "impulse_maps.txt", "DATA" ) then
		Data.Maps:Load()
	else
		RunConsoleCommand( "requestmaps" )
	end
end