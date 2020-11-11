Client = {}

include( "core.lua" )
include( "cl_receive.lua" )
include( "cl_gui.lua" )
include( "cl_score.lua" )
include( "modules/cl_admin.lua" )
include( "modules/cl_radio.lua" )

local CPlayers = CreateClientConVar( "sl_showteam", "1", true, false )
local CSteam = CreateClientConVar( "sl_steamgroup", "1", true, false )
local CCrosshair = CreateClientConVar( "sl_crosshair", "1", true, false )
local CTargetID = CreateClientConVar( "sl_targetids", "1", true, false )
local CThirdPerson = CreateClientConVar( "sl_thirdperson", "0", true, false )
local HUDItems = { "CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo", "CHudSuitPower" }
local TriggerList = { "trigger_hurt", "env_explosion", "env_beam", "env_fire", "env_physexplosion", "worldspawn", "func_movelinear", "func_physbox", "func_rotating", "func_door", "entityflame", "prop_physics", "suicide" }

for _,str in pairs( HUDItems ) do
	HUDItems[ str ] = true
	
	if str == "CHudCrosshair" then
		HUDItems[ str ] = CCrosshair:GetBool()
	end
end

for _,str in pairs( TriggerList ) do
	killicon.AddAlias( str, "default" )
	language.Add( str, "was killed" )
end

function GM:HUDShouldDraw( szApp )
	return not HUDItems[ szApp ]
end

function GM:CalcView( ply, pos, angles, fov )
	if CThirdPerson:GetBool() then
		pos = pos - (angles:Forward() * 100) + (angles:Up() * 40)
		local ang = (ply:GetPos() + (angles:Up() * 30 )) - pos
		ang:Normalize()
		angles = ang:Angle()
	end
	
    return self.BaseClass:CalcView( ply, pos, angles, fov )
end

function GM:ShouldDrawLocalPlayer( ply )
	return CThirdPerson:GetBool() or self.BaseClass:ShouldDrawLocalPlayer( ply )
end

function GM:HUDWeaponPickedUp( wep )
	if not IsValid( LocalPlayer() ) or not LocalPlayer():Alive() then return end
	local weps = LocalPlayer():GetWeapons()
	if #weps == 0 then return end
	
	return self.BaseClass:HUDWeaponPickedUp( ply )
end


function Client:ToggleCrosshair( tabData )
	if tabData then
		for cmd,target in pairs( tabData ) do
			RunConsoleCommand( cmd, tostring( target ) )
		end
		Link:Print( "General", "Your crosshair options have been changed!" )
	else
		HUDItems[ "CHudCrosshair" ] = not HUDItems[ "CHudCrosshair" ]
		RunConsoleCommand( "sl_crosshair", HUDItems[ "CHudCrosshair" ] and 1 or 0 )
		Link:Print( "General", "Crosshair visibility has been toggled" )
	end
end

function Client:ToggleTargetIDs()
	local nNew = 1 - CTargetID:GetInt()
	RunConsoleCommand( "sl_targetids", nNew )
	Link:Print( "General", "You have " .. (nNew == 0 and "disabled" or "enabled") .. " player labels" )
end

function Client:ToggleThirdperson()
	local nNew = 1 - CThirdPerson:GetInt()
	RunConsoleCommand( "sl_thirdperson", nNew )
end

function Client:PlayerVisibility( nTarget )
	local nNew = -1
	if CPlayers:GetInt() == nTarget then
		RunConsoleCommand( "sl_showteam", 1 - nTarget )
		timer.Simple( 1, function() RunConsoleCommand( "sl_showteam", nTarget ) end )
		nNew = nTarget
	elseif nTarget < 0 then
		nNew = 1 - CPlayers:GetInt()
		RunConsoleCommand( "sl_showteam", nNew )
	else
		nNew = nTarget
		RunConsoleCommand( "sl_showteam", nNew )
	end
	
	if nNew >= 0 then
		Link:Print( "General", "You have set player visibility to " .. (nNew == 0 and "invisible" or "visible") )
	end
end

function Client:ShowHelp( tab )
	print( "\n\nBelow is a list of all available commands and their aliases:\n\n" )

	table.sort( tab, function( a, b )
		if not a or not b or not a[ 2 ] or not a[ 2 ][ 1 ] then return false end
		return a[ 2 ][ 1 ] < b[ 2 ][ 1 ]
	end )
	
	for _,data in pairs( tab ) do
		local desc, alias = data[ 1 ], data[ 2 ]
		local main = table.remove( alias, 1 )
		
		MsgC( Color( 212, 215, 134 ), "\tCommand: " ) MsgC( Color( 255, 255, 255 ), main .. "\n" )
		MsgC( Color( 212, 215, 134 ), "\t\tAliases: " ) MsgC( Color( 255, 255, 255 ), (#alias > 0 and string.Implode( ", ", alias ) or "None") .. "\n" )
		MsgC( Color( 212, 215, 134 ), "\t\tDescription: " ) MsgC( Color( 255, 255, 255 ), desc .. "\n\n" )
	end
	
	Link:Print( "General", "A list of commands and their descriptions has been printed in your console! Press ~ to open." )
end

function Client:ShowEmote( data )
	local ply
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == data[ 1 ] then
			ply = p
			break
		end
	end
	if not IsValid( ply ) then return end
	
	if ply:GetNWInt( "AccessIcon", 0 ) > 0 then
		local tab = {}
		local VIPNameColor = ply:GetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
		if VIPNameColor.x >= 0 then
			local VIPName = ply:GetNWString( "VIPName", "" )
			if VIPName == "" then
				VIPName = ply:Name()
			end
		
			if VIPNameColor.x == 256 then
				tab = Client:GenerateName( tab, VIPName .. " " )
			elseif VIPNameColor.x == 257 then
				tab = Client:GenerateName( tab, VIPName .. " ", ply )
			else
				table.insert( tab, Core.Util:VectorToColor( VIPNameColor ) )
				table.insert( tab, VIPName .. " " )
			end
			
			if Client.VIPReveal and VIPName != ply:Name() then
				table.insert( tab, GUIColor.White )
				table.insert( tab, "(" .. ply:Name() .. ") " )
			end
		else
			table.insert( tab, Color( 98, 176, 255 ) )
			table.insert( tab, ply:Name() .. " " )
		end
		
		table.insert( tab, GUIColor.White )
		table.insert( tab, tostring( data[ 2 ] ) )
		
		chat.AddText( unpack( tab ) )
	end
end

function Client:Mute( bMute )
	for _,p in pairs( player.GetHumans() ) do
		if LocalPlayer() and p != LocalPlayer() then
			if bMute and not p:IsMuted() then
				p:SetMuted( true )
			elseif not bMute and p:IsMuted() then
				p:SetMuted( false )
			end
		end
	end
	
	Link:Print( "General", "All players have been " .. (bMute and "muted" or "unmuted") .. "." )
end

function Client:DoChatMute( szID, bMute )
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == szID then
			p.ChatMuted = bMute
			Link:Print( "General", p:Name() .. " has been " .. (bMute and "chat muted" or "unmuted") .. "!" )
		end
	end
end

function Client:DoVoiceGag( szID, bGag )
	for _,p in pairs( player.GetHumans() ) do
		if tostring( p:SteamID() ) == szID then
			p:SetMuted( bGag )
			Link:Print( "General", p:Name() .. " has been " .. (bGag and "voice gagged" or "ungagged") .. "!" )
		end
	end
end

function Client:GenerateName( tab, szName, gradient )
	szName = szName:gsub('[^%w ]', '')
	local count = #szName
	local start, stop = Core.Util:RandomColor(), Core.Util:RandomColor()
	if gradient then
		local gs = gradient:GetNWVector( "VIPGradientS", Vector( -1, 0, 0 ) )
		local ge = gradient:GetNWVector( "VIPGradientE", Vector( -1, 0, 0 ) )
		
		if gs.x >= 0 then start = Core.Util:VectorToColor( gs ) end
		if ge.x >= 0 then stop = Core.Util:VectorToColor( ge ) end
	end
	
	for i = 1, count do
		local percent = i / count
		table.insert( tab, Color( start.r + percent * (stop.r - start.r), start.g + percent * (stop.g - start.g), start.b + percent * (stop.b - start.b) ) )
		table.insert( tab, szName[ i ] )
	end
	
	return tab
end

function Client:ToggleChat()
	local nTime = GetConVar( "hud_saytext_time" ):GetInt()
	if nTime > 0 then
		Link:Print( "General", "The chat has been hidden." )
		RunConsoleCommand( "hud_saytext_time", 0 )
	else
		Link:Print( "General", "The chat has been restored." )
		RunConsoleCommand( "hud_saytext_time", 12 )
	end
end

function Client:ChangeWater()
	local a = GetConVar( "r_waterdrawrefraction" ):GetInt()
	local b = GetConVar( "r_waterdrawreflection" ):GetInt()
	local c = 1 - a
	
	RunConsoleCommand( "r_waterdrawrefraction", c )
	RunConsoleCommand( "r_waterdrawreflection", c )
	Link:Print( "General", "Water reflection and refraction have been " .. (c == 0 and "disabled" or "re-enabled") .. "!" )
end

function Client:ClearDecals()
	RunConsoleCommand( "r_cleardecals" )
	Link:Print( "General", "All players decals have been cleared from your screen." )
end

function Client:ToggleReveal()
	Client.VIPReveal = not Client.VIPReveal
	Link:Print( "General", "True VIP names will now " .. (Client.VIPReveal and "" or "no longer ") .. "be shown" )
end

function Client:FlipWeapons()
	if IsValid( LocalPlayer() ) then
		local n = 0
		for _,wep in pairs( LocalPlayer():GetWeapons() ) do
			wep.ViewModelFlip = not wep.ViewModelFlip
			wep.ViewModelFlip1 = not wep.ViewModelFlip1
			wep.ViewModelFlip2 = not wep.ViewModelFlip2
			n = n + 1
		end
		
		if n > 0 then
			Link:Print( "General", "Your weapons have been flipped!" )
		else
			Link:Print( "General", "No weapons to flip." )
		end
	end
end

function Client:ToggleSpace( bStart )
	if bStart then
		Client.SpaceToggle = not Client.SpaceToggle
	else
		if not IsValid( LocalPlayer() ) then return end
		if not Client.SpaceEnabled then
			Client.SpaceEnabled = true
			LocalPlayer():ConCommand( "+jump" )
		else
			LocalPlayer():ConCommand( "-jump" )
			Client.SpaceEnabled = nil
		end
	end
end

function Client:VerifyList()
	if file.Exists( Cache.M_Name, "DATA" ) then
		Cache:M_Load()
	end
	
	Cache:T_Load()
end

function Client:SetRound( round, text )
	Client:SetDisplayRound( round )
	if text != "" then Link:Print( "Deathrun", text ) end
end

function Client:ServerSwitch( data )
	Link:Print( "General", "Now connecting to: " .. data[ 2 ] )
	Derma_Query( 'Are you sure you want to connect to ' .. data[ 2 ] .. '?', 'Connecting to different server', 'Yes', function() LocalPlayer():ConCommand( "connect " .. data[ 1 ] ) end, 'No', function() end)
end

function Client:OpenShop()
	RunConsoleCommand( "ps_shop" )
end

function Client:Setup()
	if not IsValid( LocalPlayer() ) then timer.Simple( 0.1, function() Client:Setup() end ) end
	Core.Util:SetSpeedCap( LocalPlayer(), _C.Player.BaseLimit )
	RunConsoleCommand( "sl_targetids", 1 )
end


local function ClientTick()
	if not IsValid( LocalPlayer() ) then timer.Simple( 1, ClientTick ) return end
	timer.Simple( 15, ClientTick )
	
	local ent = LocalPlayer()
	ent:SetHull( _C["Player"].HullMin, _C["Player"].HullStand )
	ent:SetHullDuck( _C["Player"].HullMin, _C["Player"].HullDuck )
	
	if not Client.ViewSet then
		ent:SetViewOffset( _C["Player"].ViewStand )
		ent:SetViewOffsetDucked( _C["Player"].ViewDuck )
		Client.ViewSet = true
	end
end

local function ChatEdit( nIndex, szName, szText, szID )
	if szID == "joinleave" then
		return true
	end
end
hook.Add( "ChatText", "SuppressMessages", ChatEdit )

local function ChatTag( ply, szText, bTeam, bDead )
	if ply.ChatMuted then
		print( "[CHAT MUTE] " .. ply:Name() .. ": " .. szText )
		return true
	end
	
	local tab = {}
	if bTeam then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end
	
	if bDead then
		table.insert( tab, Color( 160, 160, 160 ) )
		table.insert( tab, "(DEAD) " )
	end
	
	if ply:GetNWInt( "Spectating", 0 ) == 1 then
		table.insert( tab, Color( 189, 195, 199 ) )
		table.insert( tab, "*SPEC* " )
	end
	
	local nAccess = 0
	if IsValid( ply ) and ply:IsPlayer() then
		nAccess = ply:GetNWInt( "AccessIcon", 0 )
		table.insert( tab, GUIColor.White )
		
		if nAccess > 0 then
			local VIPTag, VIPTagColor = ply:GetNWString( "VIPTag", "" ), ply:GetNWVector( "VIPTagColor", Vector( -1, 0, 0 ) )
			if VIPTag != "" and VIPTagColor.x >= 0 then
				table.insert( tab, "[" )
				table.insert( tab, Core.Util:VectorToColor( VIPTagColor ) )
				table.insert( tab, VIPTag )
				table.insert( tab, GUIColor.White )
				table.insert( tab, "] " )
			end
		end
		
		table.insert( tab, "(" )
		table.insert( tab, team.GetColor( ply:Team() ) )
		table.insert( tab, team.GetName( ply:Team() ) )
		table.insert( tab, GUIColor.White )
		table.insert( tab, ") " )
		
		if nAccess > 0 then
			local VIPNameColor = ply:GetNWVector( "VIPNameColor", Vector( -1, 0, 0 ) )
			if VIPNameColor.x >= 0 then
				local VIPName = ply:GetNWString( "VIPName", "" )
				if VIPName == "" then
					VIPName = ply:Name()
				end
				
				if VIPNameColor.x == 256 then
					tab = Client:GenerateName( tab, VIPName )
				elseif VIPNameColor.x == 257 then
					tab = Client:GenerateName( tab, VIPName, ply )
				else
					table.insert( tab, Core.Util:VectorToColor( VIPNameColor ) )
					table.insert( tab, VIPName )
				end
				
				if Client.VIPReveal and VIPName != ply:Name() then
					table.insert( tab, GUIColor.White )
					table.insert( tab, " (" .. ply:Name() .. ")" )
				end
			else
				table.insert( tab, Color( 98, 176, 255 ) )
				table.insert( tab, ply:Name() )
			end
		else
			table.insert( tab, Color( 98, 176, 255 ) )
			table.insert( tab, ply:Name() )
		end
	else
		table.insert( tab, "Console" )
	end
	
	table.insert( tab, GUIColor.White )
	table.insert( tab, ": " )

	if nAccess > 0 then
		local VIPChat = ply:GetNWVector( "VIPChat", Vector( -1, 0, 0 ) )
		if VIPChat.x >= 0 then
			table.insert( tab, Core.Util:VectorToColor( VIPChat ) )
		end
	end
	
	table.insert( tab, szText )
	
	chat.AddText( unpack( tab ) )
	return true
end
hook.Add( "OnPlayerChat", "TaggedChat", ChatTag )

local lp, J1, J2 = LocalPlayer, _C.Player.JumpPower, _C.Player.HighJump
local function PlayerGround( ply, bWater )
	if lp and ply != lp() then return end
	
	ply:SetJumpPower( J1 )
	timer.Simple( 0.3, function() if not IsValid( ply ) or not isfunction( ply.SetJumpPower ) or not J2 then return end ply:SetJumpPower( J2 ) end )
end
hook.Add( "OnPlayerHitGround", "HitGround", PlayerGround )

local function BindTracker( ply, bind )
	if string.find( bind, "+jump" ) and Client.SpaceToggle then Client:ToggleSpace() end
end
hook.Add( "PlayerBindPress", "BindChecking", BindTracker )

local function VisibilityCallback( CVar, Previous, New )
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
cvars.AddChangeCallback( "sl_showteam", VisibilityCallback )

local noView = TEAM_UNDEAD
local function PlayerVisiblityCheck( ply )
	local invisible = false
	
	if IsValid( LocalPlayer() ) then
		local me, other = LocalPlayer():Team(), ply:Team()
		
		if me == noView and me != other then
			invisible = true
		elseif other == noView and me != noView then
			invisible = true
		end
		
		if not CPlayers:GetBool() then
			if me != noView and me == other then
				invisible = true
			end
		end
		
		ply:SetNoDraw( invisible )
		return invisible
	else
		ply:SetNoDraw( false )
		return false
	end
end
hook.Add( "PrePlayerDraw", "PlayerVisiblityCheck", PlayerVisiblityCheck )

local function Initialize()
	timer.Simple( 1, function()
		Core:Optimize()
		Radio:Resume()
	end )
	timer.Simple( 1, ClientTick )
	
	Client:VerifyList()
	
	if CSteam:GetBool() then
		timer.Simple( 1, function()
			Derma_Query( "Welcome to Flow Network!\nDo you want to join our public Garry's Mod Steam Group?\n\nClick Yes to join!\nIf you want to play a bit first, press No.\nIf you don't want to see this message any more, click Hide.",
			"Steam Group Invitation", "Yes", function()
				gui.OpenURL( "http://steamcommunity.com/groups/SurflineP" )
				RunConsoleCommand( "sl_steamgroup", 0 )
			end, "No", function() end, "Hide", function()
				RunConsoleCommand( "sl_steamgroup", 0 )
			end )
		end )
	end
end
hook.Add( "Initialize", "ClientBoot", Initialize )