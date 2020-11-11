include( "sh_settings.lua" )
include( "cl_lang.lua" )
include( "cl_timer.lua" )
include( "cl_datatransfer.lua" )
include( "cl_gui.lua" )
include( "cl_scoreboard.lua" )
include( "cl_spectator.lua" )
include( "modules/cl_admin.lua" )
include( "modules/cl_radio.lua" )

Client = {}
Client.Speed = 0
Client.AFKChecks = 0
Client.ThirdPerson = 0
Client.Mode = Config.Modes["Auto"]

local CPlayers = CreateClientConVar( "cl_showothers", "1", true, false )
local CHidden = { ["CHudHealth"] = true, ["CHudBattery"] = true, ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true, ["CHudCrosshair"] = true, ["CHudSuitPower"] = true }

local bChatOpen = nil
local tabChatData = {}

function GM:Initialize()
	timer.Simple( 5, Client.Tick )
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
	return not CHidden[ szApplet ]
end

function GM:StartChat() bChatOpen = true end
function GM:FinishChat() bChatOpen = nil end


function GM:HUDPaint()
	if bChatOpen then
		local x, y = 270, ScrH() - 145
		surface.SetFont( "ChatFont" )
		
		for _, v in ipairs( tabChatData ) do
			local sx, sy = surface.GetTextSize( v.ChatCommand )
			
			draw.SimpleText( v.ChatCommand, "ChatFont", x, y, Color( 0, 0, 0, 255 ) )
			draw.SimpleText( " " .. v.Usage or "", "ChatFont", x + sx, y, Color( 0, 0, 0, 255 ) )
			draw.SimpleText( v.ChatCommand, "ChatFont", x, y, Color( 255, 255, 100, 255 ) )
			draw.SimpleText( " " .. v.Usage or "", "ChatFont", x + sx, y, Color( 255, 255, 255, 255 ) )
			
			y = y + sy
		end
	end
end


function Client.Tick()
	if not IsValid( LocalPlayer() ) then timer.Simple( 1, Client.Tick ) return end
	timer.Simple( 5, Client.Tick )

	local ent = LocalPlayer()
	ent:SetHull( Config.Player.HullMin, Config.Player.HullStand )
	ent:SetHullDuck( Config.Player.HullMin, Config.Player.HullDuck )
	
	if not Client.ViewSet then
		ent:SetViewOffset( Config.Player.ViewStand )
		ent:SetViewOffsetDucked( Config.Player.ViewDuck )
		Client.ViewSet = true
	end

	if Client.Speed < 1 and ent:Team() != TEAM_SPECTATOR then
		Client.AFKChecks = Client.AFKChecks + 1
		
		if Client.AFKChecks >= (Timer.Start and Config.Player.AFKLimit * 3 or Config.Player.AFKLimit) then
			ent:ConCommand( 'afk ' .. Config.Player.Phrase )
			Client.AFKChecks = 0
		end
	else
		Client.AFKChecks = 0
	end
	
	if GetConVarNumber('fps_max') != 300 then
		ent:ConCommand( 'fpslimit ' .. GetConVarNumber('fps_max') .. ' ' .. Config.Player.Phrase )
	end

	if not CPlayers:GetBool() then
		Client.HidingCallback( nil, 1, 0 )
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

	Message:Print( Config.Prefix.Command, "HUDRankPoints", { nPoints } )
	Message:Print( Config.Prefix.Command, "HUDRankPrint" )
end

function Client:ListCommands()
	print( "Below is a list of all available commands and their aliases:" )
	print( "" )
	
	for ID, Data in pairs( Lang.Commands ) do
		local Aliases = Data[1]
		local Description = Data[2]
		local Main = table.remove( Aliases, 1 )

		if string.find( Description, "<" ) then
			local nEnd = string.find( Description, ">", 1, true )
			Main = Main .. " " .. string.sub( Description, 1, nEnd )
			Description = string.sub( Description, nEnd + 4 )
		elseif string.sub( Description, 1, 2 ) == "- " then
			Description = string.sub( Description, 3 )
		end
		
		MsgC( Color( 255, 0, 0 ), "\tCommand: " .. Main .. "\n" )
		MsgC( Color( 255, 255, 255 ), "\t\tAliases: " .. (#Aliases > 0 and string.Implode( ", ", Aliases ) or "None") .. "\n" )
		MsgC( Color( 255, 255, 255 ), "\t\tUsage: " .. Description .. "\n" )
	end
	
	print( "" )
	Message:Print( Config.Prefix.Command, "Generic", { "A list of commands has been printed in your console!" } )
end


local function DrawBlock( ply )
	ply:SetNoDraw( not CPlayers:GetBool() )
	if not CPlayers:GetBool() then return true end
end
hook.Add( "PrePlayerDraw", "BlockPlayerDraw", DrawBlock )

function Client.TextChanged( str )
	if string.Left( str, 1 ) == "/" or string.Left( str, 1 ) == "!" or string.Left( str, 1 ) == "@" then
		local com = string.sub( str, 2, ( string.find( str, " " ) or ( #str + 1 ) ) - 1 )
		tabChatData = {}
		
		if not Lang.Commands then return end
		for _, v in pairs( Lang.Commands ) do
			for k, cmd in pairs( v[1] ) do
				if (string.sub(cmd, 0, #com) == string.lower(com) and #tabChatData < 4) then
					local suggestion = { ChatCommand = string.sub(str, 1, 1) .. cmd, Usage = v[2] }
					table.insert( tabChatData, suggestion )
				end
			end
		end

		table.SortByMember( tabChatData, "ChatCommand", function( a, b ) return a < b end )
	else
		tabChatData = {}
	end
end
hook.Add( "ChatTextChanged", "ChatAutocomplete", Client.TextChanged )

function Client.EditedChat( nIndex, szName, szText, szID )
	if szID == "joinleave" then return true end
end
hook.Add( "ChatText", "SuppressMessages", Client.EditedChat )

function Client.RankedChat( ply, szText, bTeam, bDead )
	if ply.ChatMuted then
		print("[CHAT MUTE] " .. ply:Name() .. ": " .. szText)
		return true
	end

	local tab = {}
	if bTeam then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end
	
	if ply:GetNWInt( "Spectating", 0 ) == 1 then
		table.insert( tab, Color( 189, 195, 199 ) )
		table.insert( tab, "*SPEC* " )
	end
	
	local ULXRank = ply.GetUserGroup and ply:GetUserGroup() or ""
	local ChatTag = Config.GFLRanks[ string.lower( ULXRank ) ]
	if ChatTag then
		table.insert( tab, ChatTag[1] )
		table.insert( tab, ChatTag[2] )
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

function Client:Visibility( nTarget )
	if CPlayers:GetInt() == nTarget then
		LocalPlayer():ConCommand( "cl_showothers " .. (1 - nTarget) )
		timer.Simple( 1, function() LocalPlayer():ConCommand( "cl_showothers " .. nTarget ) end )
	else
		LocalPlayer():ConCommand( "cl_showothers " .. nTarget )
	end
	
	Message:Print( Config.Prefix.Command, "PlayerToggle", { nTarget == 0 and "invisible" or "visible" } )
end

function Client.HidingCallback( CVar, Previous, New )
	if tonumber( New ) == 1 then
		for _,ent in pairs( ents.FindByClass("env_spritetrail") ) do
			ent:SetNoDraw( false )
		end
		for _,ent in pairs( ents.FindByClass("beam") ) do
			ent:SetNoDraw( false )
		end
	else
		for _,ent in pairs( ents.FindByClass("env_spritetrail") ) do
			ent:SetNoDraw( true )
		end
		for _,ent in pairs( ents.FindByClass("beam") ) do
			ent:SetNoDraw( true )
		end
	end
end
cvars.AddChangeCallback("cl_showothers", Client.HidingCallback)

function Client.TrailFix( ent )
	if ent:GetClass() == "env_spritetrail" or ent:GetClass() == "beam" then
		if not CPlayers:GetBool() then
			ent:SetNoDraw( true )
		end
	end
end
hook.Add( "OnEntityCreated", "TrailBlock", Client.TrailFix )

function Client:WaterFix()
	RunConsoleCommand( "r_WaterDrawRefraction", 0 )
	RunConsoleCommand( "r_WaterDrawReflection", 0 )
	Message:Print( Config.Prefix.Command, "Generic", { "Your water reflections should have been fixed!" } )
end

function Client:DecalFix()
	RunConsoleCommand( "r_cleardecals" )
	Message:Print( Config.Prefix.Command, "Generic", { "All player decals have been cleared!" } )
end

function Client:Brushes( to )
	RunConsoleCommand( "r_DrawClipBrushes", to )
end