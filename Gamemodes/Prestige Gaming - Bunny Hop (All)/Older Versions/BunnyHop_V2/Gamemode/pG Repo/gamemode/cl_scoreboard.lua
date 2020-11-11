if SERVER then return end
function surface.GetTextWid(text,font)
	surface.SetFont(font)
	local w, h = surface.GetTextSize(text)
	
	return w
end

floor = math.floor
function GetTime(time)
	if time < 0 then time = 0 end
	local detailed = CVTime:GetBool()
	if time > 3600 then
		if detailed then
			return string.format("%.2d:%.2d:%.2d:%.2d", floor(time / 3600), floor(time / 60 % 60), floor(time % 60), floor(time * 60 * 60 % 60))
		else
			return string.format("%.2d:%.2d:%.2d:%.2d", floor(time / 3600), floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60))
		end
	else
		if detailed then
			return string.format("%.2d:%.2d:%.2d:%.2d", floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60), floor(time * 60 * 60 % 60))
		else
			return string.format("%.2d:%.2d:%.2d", floor(time / 60 % 60), floor(time % 60), floor(time * 60 % 60))
		end
	end
end

surface.CreateFont( "ScoreboardDefault",
{
	font		= "Helvetica",
	size		= 22,
	weight		= 800
})

surface.CreateFont( "ScoreboardDefaultTitle",
{
	font		= "Helvetica",
	size		= 32,
	weight		= 800
})

surface.CreateFont( "TahomaText",
{
	font		= "Tahoma",
	size		= 13,
	weight		= 400
})

surface.CreateFont( "TahomaTextB",
{
	font		= "Tahoma",
	size		= 13,
	weight		= 600
})

local img = Material("pgsb/header.png")
local img2 = Material("pgsb/emblem.png")
local img3 = Material("pgsb/topright.png")
--
-- This defines a new panel type for the player row. The player row is given a player
-- and then from that point on it pretty much looks after itself. It updates player info
-- in the think function, and removes itself when the player leaves the server.
--
local PLAYER_LINE = 
{
	Init = function( self )

		self.AvatarButton = self:Add( "DButton" )
		self.AvatarButton:Dock( LEFT )
		self.AvatarButton:DockMargin(10,0,0,0)
		self.AvatarButton:SetSize( 24, 24 )
		self.AvatarButton.DoClick = function() self.Player:ShowProfile() end
		self.AvatarButton.Paint = function( self, w, h )
			surface.SetDrawColor(Color( 80, 80, 80, 200 ))
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor(Color(255,255,255,255))
		end

		self.Avatar		= vgui.Create( "AvatarImage", self.AvatarButton )
		self.Avatar:SetSize( 22, 22 )
		self.Avatar:Dock( TOP )
		self.Avatar:DockMargin(1,1,1,1)
		self.Avatar:SetMouseInputEnabled( false )		

		self.Name		= self:Add( "DLabel" )
		self.Name:Dock( FILL )
		self.Name:SetFont( "TahomaText" )
		self.Name:DockPadding( 5,5,5,5 )
		self.Name:DockMargin( 8, 0, 0, 0 )

		self.Ping		= self:Add( "DLabel" )
		self.Ping:Dock( RIGHT )
		self.Ping:SetWidth( 80 )
		self.Ping:SetFont( "TahomaText" )
		self.Ping:DockPadding( 5,5,5,5 )
		self.Ping:SetContentAlignment( 5 )

		--[[self.Deaths		= self:Add( "DLabel" )
		self.Deaths:Dock( RIGHT )
		self.Deaths:SetWidth( 50 )
		self.Deaths:SetFont( "ScoreboardDefault" )
		self.Deaths:SetContentAlignment( 5 )]]

		self.Kills		= self:Add( "DLabel" )
		self.Kills:Dock( RIGHT )
		self.Kills:SetWidth( 80 )
		self.Kills:SetFont( "TahomaText" )
		self.Kills:DockPadding( 5,5,5,5 )
		self.Kills:SetContentAlignment( 5 )
	
		self.Rcs		= self:Add( "DLabel" )
		self.Rcs:Dock( RIGHT )
		self.Rcs:SetWidth( 80 )
		self.Rcs:SetFont( "TahomaText" )
		self.Rcs:DockPadding( 5,5,5,5 )
		self.Rcs:SetContentAlignment( 5 )
		
		self.Mute		= self:Add( "DImageButton" )
		self.Mute:SetSize( 16, 16 )
		self.Mute:Dock( RIGHT )
		self.Mute:DockPadding( 5,5,5,5 )
		self.Mute:DockMargin( 0, 0, 30, 0 )

		self:Dock( TOP )
		self:DockPadding( 0,0,0,0 )
		self:SetHeight( 24 )
		self:DockMargin( 0, 0, 2, 1 )

	end,

	Setup = function( self, pl )

		self.Player = pl

		self.Avatar:SetPlayer( pl )
		self.Name:SetText( pl:Nick() )

		self:Think( self )

		--local friend = self.Player:GetFriendStatus()
		--MsgN( pl, " Friend: ", friend )

	end,

	Think = function( self )

		if ( !IsValid( self.Player ) ) then
			self:Remove()
			return
		end
		
		if(self.Name:GetText() == "unconnected" && self.Player:Nick() != "unconnected") then
			self.Name:SetText(self.Player:Nick())
		end
		
		if(!self.IsAdmin && self.Player:IsAdmin()) then
			self.Name:SetTextColor(Color(118,200,118))
			self.IsAdmin = true
		end
		
		if ( self.NumKills == nil || self.NumKills != self.Player:Frags() ) then
			self.NumKills	=	self.Player:Frags()
			self.Kills:SetText( self.NumKills )
		end

		if ( self.NumDeaths == nil || self.NumDeaths != self.Player:Deaths() ) then
			self.NumDeaths	=	self.Player:Deaths()
			--self.Deaths:SetText( self.NumDeaths )
		end

		if ( self.NumPing == nil || self.NumPing != self.Player:Ping() ) then
			self.NumPing	=	self.Player:Ping()
			self.Ping:SetText( self.NumPing )
		end
		
		if( self.RcTime == nil || self.RcTime != self.Player:GetNWInt("BhopRec") ) then
			self.RcTime = self.Player:GetNWInt("BhopRec",0)
			self.Rcs:SetText(string.sub(MODE_NAME[self.Player:GetNWInt("BhopType",1)],1,1).." - "..GetTime(self.RcTime))
		end

		--
		-- Change the icon of the mute button based on state
		--
		if ( self.Muted == nil || self.Muted != self.Player:IsMuted() ) then

			self.Muted = self.Player:IsMuted()
			if ( self.Muted ) then
				self.Mute:SetImage( "icon32/muted.png" )
			else
				self.Mute:SetImage( "icon32/unmuted.png" )
			end

			self.Mute.DoClick = function() self.Player:SetMuted( !self.Muted ) end

		end

		--
		-- Connecting players go at the very bottom
		--
		if ( self.Player:Team() == TEAM_CONNECTING ) then
			self:SetZPos( 2000 )
		end

		--
		-- This is what sorts the list. The panels are docked in the z order, 
		-- so if we set the z order according to kills they'll be ordered that way!
		-- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
		--
		self:SetZPos( (self.NumKills * -50) + self.NumDeaths )

	end,

	Paint = function( self, w, h )

		if ( !IsValid( self.Player ) ) then
			return
		end

		--
		-- We draw our background a different colour based on the status of the player
		--
		if( !self.Player:Alive() ) then
			surface.SetDrawColor(Color( 118, 118, 118, 200 ))
		elseif ( self.Player:Team() == TEAM_DEATH ) then
			surface.SetDrawColor(Color( 200, 118, 118, 200 ))
		elseif ( self.Player:Team() == TEAM_RUNNER ) then
			surface.SetDrawColor(Color( 118, 118, 200, 200 ))
		else
			surface.SetDrawColor(Color( 118, 118, 118, 200 ))
		end
		surface.DrawRect( 1, 3, w-1, h-6 )
		
		surface.SetDrawColor(Color( 80, 80, 80, 200 ))
		surface.DrawOutlinedRect( 1, 3, w-1, h-6 )
		
		surface.SetDrawColor(Color(255,255,255,255))
		--[[if ( self.Player:Team() == TEAM_CONNECTING ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200, 200 ) )
			return
		end

		if  ( !self.Player:Alive() ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 200, 200, 255 ) )
			return
		end

		if ( self.Player:IsAdmin() ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 255, 230, 255 ) )
			return
		end

		draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 230, 230, 255 ) )]]

	end,
}

--
-- Convert it from a normal table into a Panel Table based on DPanel
--
PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" );

local ip = "63.251.20.123:27015"
local gmn = "Bunny Hop"

--
-- Here we define a new panel table for the scoreboard. It basically consists 
-- of a header and a scrollpanel - into which the player lines are placed.
--
local SCORE_BOARD = 
{
	Init = function( self )

		self.Header = self:Add( "Panel" )
		self.Header:Dock( TOP )
		self.Header:DockMargin( 0, 68, 0, 0 )
		self.Header:SetHeight( 30 )

		self.Name = self.Header:Add( "DLabel" )
		self.Name:SetFont( "TahomaText" )
		self.Name:SetTextColor( Color( 255, 255, 255, 255 ) )
		self.Name:Dock( LEFT )
		self.Name:SetWidth( surface.GetTextWid("You are connected to: "..ip.." - "..gmn,"TahomaText") )
		self.Name:DockPadding( 0, 5, 0, 0 )
		self.Name:DockMargin(10,0,0,0)
		self.Name:SetContentAlignment( 4 )
		self.Name:SetText("You are connected to: "..ip.." - "..gmn)
		
		self.PingLbl = self.Header:Add( "DLabel" )
		self.PingLbl:SetFont( "TahomaTextB" )
		self.PingLbl:SetTextColor( Color( 0, 0, 0, 255 ) )
		self.PingLbl:Dock( RIGHT )
		self.PingLbl:SetWidth( 80 )
		self.PingLbl:DockPadding( 5, 0, 5, 0 )
		self.PingLbl:DockMargin(0,0,102,0)
		self.PingLbl:SetContentAlignment( 5 )
		self.PingLbl:SetText("PING")

		self.ScLbl = self.Header:Add( "DLabel" )
		self.ScLbl:SetFont( "TahomaTextB" )
		self.ScLbl:SetTextColor( Color( 0, 0, 0, 255 ) )
		self.ScLbl:Dock( RIGHT )
		self.ScLbl:SetWidth( 80 )
		self.ScLbl:DockPadding( 5, 0, 5, 0 )
		self.ScLbl:SetContentAlignment( 5 )
		self.ScLbl:SetText("SCORE")
		
		--[[self.RcLbl = self.Header:Add( "DLabel" )
		self.RcLbl:SetFont( "TahomaTextB" )
		self.RcLbl:SetTextColor( Color( 0, 0, 0, 255 ) )
		self.RcLbl:Dock( RIGHT )
		self.RcLbl:SetWidth( 80 )
		self.RcLbl:DockPadding( 5, 0, 5, 0 )
		self.RcLbl:SetContentAlignment( 5 )
		self.RcLbl:SetText("RECORD")]]

		--self.NumPlayers = self.Header:Add( "DLabel" )
		--self.NumPlayers:SetFont( "ScoreboardDefault" )
		--self.NumPlayers:SetTextColor( Color( 255, 255, 255, 255 ) )
		--self.NumPlayers:SetPos( 0, 100 - 30 )
		--self.NumPlayers:SetSize( 300, 30 )
		--self.NumPlayers:SetContentAlignment( 4 )

		self.Scores = self:Add( "DScrollPanel" )
		self.Scores:Dock( FILL )
		self.Scores:DockMargin( 10, 0, 101, 0 )
	end,

	PerformLayout = function( self )

		self:SetSize( 791, ScrH() - 200 )
		self:SetPos( ScrW() / 2 - 350, 100 )

	end,

	Paint = function( self, w, h )
		surface.SetMaterial(img3)
		
		surface.SetDrawColor(Color(255,255,255,255))
		surface.DrawTexturedRect(w-187,1,182,124)
	
		surface.SetMaterial(img)
		surface.DrawTexturedRect(w-621,35,476,27)
		
		--surface.SetMaterial()
		surface.SetDrawColor(Color( 0, 0, 0, 200 ))
		surface.DrawOutlinedRect( 1, 69, w-93, h-76 )
		
		surface.SetDrawColor(Color( 255, 255, 255, 200 ))
		surface.DrawOutlinedRect( 2, 70, w-95, h-78 )
		
		surface.SetDrawColor(Color( 102, 102, 102, 200 ))
		surface.DrawRect( 2, 70, w-95, h-78 )
		
		
		surface.SetDrawColor(Color(255,255,255,100))
		
		surface.SetMaterial(img2)
		surface.DrawTexturedRect(w-491,h-300,389,287)
		
		surface.SetDrawColor(Color(255,255,255,255))
		
	end,

	Think = function( self, w, h )

		--
		-- Loop through each player, and if one doesn't have a score entry - create it.
		--
		local plyrs = player.GetAll()
		for id, pl in pairs( plyrs ) do

			if ( IsValid( pl.ScoreEntry ) ) then continue end

			pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
			pl.ScoreEntry:Setup( pl )

			self.Scores:AddItem( pl.ScoreEntry )

		end		

	end,
}

SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" );

--[[---------------------------------------------------------
   Name: gamemode:ScoreboardShow( )
   Desc: Sets the scoreboard to visible
-----------------------------------------------------------]]
function GM:ScoreboardShow()

	if ( !IsValid( g_Scoreboard ) ) then
		g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
	end

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Show()
		g_Scoreboard:MakePopup()
		g_Scoreboard:SetKeyboardInputEnabled( false )
	end

end

--[[---------------------------------------------------------
   Name: gamemode:ScoreboardHide( )
   Desc: Hides the scoreboard
-----------------------------------------------------------]]
function GM:ScoreboardHide()

	if ( IsValid( g_Scoreboard ) ) then
		g_Scoreboard:Hide()
	end

end


--[[---------------------------------------------------------
   Name: gamemode:HUDDrawScoreBoard( )
   Desc: If you prefer to draw your scoreboard the stupid way (without vgui)
-----------------------------------------------------------]]
function GM:HUDDrawScoreBoard()

end

