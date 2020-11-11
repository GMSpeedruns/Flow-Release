surface.CreateFont( "ScoreboardPlayer", { font = "coolvetica", size = 24, weight = 500, antialias = true, italic = false })
surface.CreateFont( "MersText1", { font = "Tahoma", size = 16, weight = 1000, antialias = true, italic = false })
surface.CreateFont( "MersRadial", { font = "coolvetica", size = math.ceil( ScrW() / 34 ), weight = 500, antialias = true, italic = false })

local menu = nil
local icon_muted = Material( "icon32/muted.png" )
local icon_access = { Material( "icon16/heart.png" ), Material( "icon16/heart_add.png" ), Material( "icon16/report_user.png" ), Material( "icon16/shield.png" ), Material( "icon16/shield_add.png" ), Material( "icon16/script_code_red.png" ), Material( "icon16/house.png" ) }

local function _AA( szAction, szSID )
	if not IsValid( LocalPlayer() ) then return end
	if Admin:IsAvailable() or LocalPlayer():GetNWInt( "AccessIcon", 0 ) > 2 then
		RunConsoleCommand( "say", "!admin " .. szAction .. " " .. szSID )
	else
		Link:Print( "Admin", "Please open the admin panel before trying to access scoreboard functionality." )
	end
end

local function PutPlayerItem( self, pList, ply, mw )
	local btn = vgui.Create( "DButton" )
	btn.player = ply
	btn.ctime = CurTime()
	btn:SetTall( 32 )
	btn:SetText( "" )
	
	function btn:Paint( w, h )
		surface.SetDrawColor( 0, 0, 0, 0 )
		surface.DrawRect( 0, 0, w, h )

		surface.SetDrawColor( Color( 150, 150, 150 ) )
		surface.DrawOutlinedRect( 0, 0, w, h )

		if IsValid( ply ) and ply:IsPlayer() then
			local s = 0
			
			local nRank, Rank = ply:GetNWInt( "Rank", -1 ), { "Retrieving...", Color( 255, 255, 255 ) }
			if _C.Ranks and _C.Ranks[ nRank ] then
				Rank = _C.Ranks[ nRank ] or Rank
			end
			
			local TeamText, TeamColor = team.GetName( ply:Team() ), team.GetColor( ply:Team() ) or Color( 255, 255, 255 )
			local ColorSpec = ply:Alive() and Color( 255, 255, 255 ) or Color( 180, 180, 180 )
			
			draw.DrawText( Rank[ 1 ], "ScoreboardPlayer", s + 11, 9, Color( 0, 0, 0 ), TEXT_ALIGN_LEFT )
			draw.DrawText( Rank[ 1 ], "ScoreboardPlayer", s + 10, 8, Rank[ 2 ], TEXT_ALIGN_LEFT )
			
			s = s + mw + 56
			
			local nAccess = ply:GetNWInt( "AccessIcon", 0 )
			if nAccess > 0 then
				surface.SetMaterial( icon_access[ nAccess ] )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( s + 4, h / 2 - 8, 16, 16 )
				s = s + 20
			end

			if ply:IsMuted() then
				surface.SetMaterial( icon_muted )
				surface.SetDrawColor( Color( 255, 255, 255 ) )
				surface.DrawTexturedRect( s + 4, h / 2 - 16, 32, 32 )
				s = s + 32
			end
			
			local PlayerName = ply:Name()
			draw.DrawText( PlayerName, "ScoreboardPlayer", s + 11, 9, Color( 0, 0, 0 ), TEXT_ALIGN_LEFT )
			draw.DrawText( PlayerName, "ScoreboardPlayer", s + 10, 8, ColorSpec, TEXT_ALIGN_LEFT )
			
			surface.SetFont( "ScoreboardPlayer" )
			local wt, ht = surface.GetTextSize( TeamText )
			local wx = 105 - wt
			local o = w - wt - (wx * 2) - menu.RecordOffset
				
			draw.DrawText( TeamText, "ScoreboardPlayer", o + 1, 9, Color( 0, 0, 0 ), TEXT_ALIGN_RIGHT )
			draw.DrawText( TeamText, "ScoreboardPlayer", o, 8, TeamColor, TEXT_ALIGN_RIGHT )
			
			draw.DrawText( ply:Ping(), "ScoreboardPlayer", w - 9, 9, Color( 0, 0, 0 ), TEXT_ALIGN_RIGHT )
			draw.DrawText( ply:Ping(), "ScoreboardPlayer", w - 10, 8, Color( 255, 255, 255 ), TEXT_ALIGN_RIGHT )
		end
	end

	function btn:DoClick()
		GAMEMODE:DoScoreboardActionPopup( ply )
	end
	
	pList:AddItem( btn )
end

local function ListPlayers( self, pList, mw )
	local players = player.GetAll()
	table.sort( players, function( a, b )
		if not a or not b then return false end
		return a:Team() < b:Team()
	end )

	for k,v in pairs( pList:GetCanvas():GetChildren() ) do
		if IsValid( v ) then
			v:Remove()
		end
	end

	for k,ply in pairs( players ) do
		PutPlayerItem( self, pList, ply, mw )
	end
		
	pList:GetCanvas():InvalidateLayout()
end

local function CreateTeamList( parent, mw )
	local pList
	
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8, 8, 8, 8)
	
	function pnl:Paint(w, h) 
		surface.SetDrawColor(GUIColor.LightGray)
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	pnl.RefreshPlayers = function()
		ListPlayers(self, pList, mw)
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0, 0, 0, 4)
	headp:Dock(TOP)
	function headp:Paint() end

	local rank = vgui.Create("DLabel", headp)
	rank:SetText("Rank")
	rank:SetFont("Trebuchet24")
	rank:SetTextColor(GUIColor.Header)
	rank:SetWidth(50)
	rank:Dock(LEFT)
	
	local player = vgui.Create("DLabel", headp)
	player:SetText("Player")
	player:SetFont("Trebuchet24")
	player:SetTextColor(GUIColor.Header)
	player:SetWidth(60)
	player:DockMargin(mw + 14, 0, 0, 0)
	player:Dock(LEFT)
	
	local ping = vgui.Create("DLabel", headp)
	ping:SetText("Ping")
	ping:SetFont("Trebuchet24")
	ping:SetTextColor(GUIColor.Header)
	ping:SetWidth(50)
	ping:DockMargin(0, 0, 0, 0)
	ping:Dock(RIGHT)

	local timer = vgui.Create("DLabel", headp)
	timer:SetText("Team")
	timer:SetFont("Trebuchet24")
	timer:SetTextColor(GUIColor.Header)
	timer:SetWidth(80)
	timer:DockMargin(0, 0, 80 + menu.RecordOffset, 0)
	timer:Dock(RIGHT)
	
	pList = vgui.Create("DScrollPanel", pnl)
	pList:Dock(FILL)

	local canvas = pList:GetCanvas()
	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, 4)
	end

	return pnl
end

function GM:ScoreboardShow()
	if IsValid( menu ) then
		menu:SetVisible(true)
		
		if menu.Players then
			menu.Players:RefreshPlayers()
		end
	else
		menu = vgui.Create("DFrame")
		menu:SetSize(ScrW() * 0.5, ScrH() * 0.8)
		menu:Center()
		menu:MakePopup()
		menu:SetKeyboardInputEnabled(false)
		menu:SetDeleteOnClose(false)
		menu:SetDraggable(false)
		menu:ShowCloseButton(false)
		menu:SetTitle("")
		menu:DockPadding(4, 4, 4, 4)
		menu.RecordOffset = ((ScrW() - 1280) / 64) * 8
		
		function menu:PerformLayout()
			menu.Players:SetWidth(self:GetWide())
		end

		function menu:Paint()
			surface.SetDrawColor(GUIColor.DarkGray)
			surface.DrawRect(0, 0, menu:GetWide(), menu:GetTall())
		end

		menu.Credits = vgui.Create("DPanel", menu)
		menu.Credits:Dock(TOP)
		menu.Credits:DockPadding(8, 6, 8, 0)
		
		function menu.Credits:Paint()
		end

		local name = Label( GAMEMODE.DisplayName, menu.Credits )
		name:Dock(LEFT)
		name:SetFont("MersRadial")
		name:SetTextColor(GUIColor.Header)
		
		function name:PerformLayout()
			surface.SetFont(self:GetFont())
			local w, h = surface.GetTextSize(self:GetText())
			self:SetSize(w, h)
		end

		local cred = vgui.Create( "DButton", menu.Credits )
		cred:Dock(RIGHT)
		cred:SetFont("MersText1")
		cred:SetText("By Gravious\nVersion " .. string.format( "%.2f", _C.Version )) -- No thank you. Keep this. You can add a "modified by" but please don't remove my name.
		cred.PerformLayout = name.PerformLayout
		cred:SetTextColor(GUIColor.White)
		cred:SetDrawBackground( false )
		cred:SetDrawBorder( false )
		cred.DoClick = function()
			gui.OpenURL( "http://steamcommunity.com/id/Gravious_/" )
		end

		function menu.Credits:PerformLayout()
			surface.SetFont(name:GetFont())
			local w,h = surface.GetTextSize(name:GetText())
			self:SetTall(h)
		end

		surface.SetFont("ScoreboardPlayer")
		local mw,mh = surface.GetTextSize("Retrieving...")
		
		menu.Players = CreateTeamList(menu, mw)
		menu.Players:Dock(FILL)
		
		if menu.Players then
			menu.Players:RefreshPlayers()
		end
	end
end

function GM:DoScoreboardActionPopup(ply)
	if not IsValid( ply ) then return end
	local actions, open = DermaMenu(), true

	if ply != LocalPlayer() then	
		if not ply:IsBot() then
			if ply:IsAdmin() then
				local admin = actions:AddOption("Player is an admin")
				admin:SetIcon("icon16/shield.png")
				actions:AddSpacer()
			end
		
			local mute = actions:AddOption(ply:IsMuted() and "Unmute" or "Mute")
			mute:SetIcon("icon16/sound_mute.png")
			function mute:DoClick()
				if IsValid(ply) then
					ply:SetMuted(!ply:IsMuted())
				end
			end
			
			local chatmute = actions:AddOption(ply.ChatMuted and "Chat unmute" or "Chat mute")
			chatmute:SetIcon("icon16/keyboard_delete.png")
			function chatmute:DoClick()
				if IsValid(ply) then
					ply.ChatMuted = not ply.ChatMuted
					Link:Print( "General", ply:Name() .. " has been " .. (ply.ChatMuted and "chat muted" or "chat unmuted") )
				end
			end
			
			local profile = actions:AddOption("View Profile")
			profile:SetIcon("icon16/vcard.png")
			function profile:DoClick()
				if IsValid(ply) then
					ply:ShowProfile()
				end
			end
		else
			local bot = actions:AddOption("Player is a bot")
			bot:SetIcon("icon16/control_end.png")
			actions:AddSpacer()
		end
		
		local spec = actions:AddOption("Spectate Player")
		spec:SetIcon("icon16/eye.png")
		function spec:DoClick()
			if IsValid(ply) then
				RunConsoleCommand( "spectate", ply:SteamID(), ply:Name() )
			end
		end
	else
		open = false
	end
	
	if open and IsValid( LocalPlayer() ) and LocalPlayer():IsAdmin() then
		actions:AddSpacer()

		local Option1 = actions:AddOption("Copy name")
		Option1:SetIcon("icon16/page_copy.png")
		function Option1:DoClick()
			SetClipboardText( ply:Name() )
		end
		
		local Option3 = actions:AddOption("Copy SteamID")
		Option3:SetIcon("icon16/page_copy.png")
		function Option3:DoClick()
			SetClipboardText( ply:SteamID() )
		end
		
		actions:AddSpacer()
		
		local Option4 = actions:AddOption("Move to spectator")
		Option4:SetIcon("icon16/eye.png")
		function Option4:DoClick()
			_AA( "spectator", ply:SteamID() )
		end
		
		local Option4a = actions:AddOption("Strip weapons")
		Option4a:SetIcon("icon16/delete.png")
		function Option4a:DoClick()
			_AA( "strip", ply:SteamID() )
		end
		
		local Option4b = actions:AddOption("Slay player")
		Option4b:SetIcon("icon16/eye.png")
		function Option4b:DoClick()
			_AA( "slay", ply:SteamID() )
		end
		
		local Option5 = actions:AddOption((ply.ChatMuted and "Unm" or "M") .. "ute player")
		Option5:SetIcon("icon16/keyboard_" .. (not ply.ChatMuted and "delete" or "add") .. ".png")
		function Option5:DoClick()
			_AA( "mute", ply:SteamID() )
		end
		
		local Option6 = actions:AddOption((ply:IsMuted() and "Ung" or "G") .. "ag player")
		Option6:SetIcon("icon16/sound" .. (not ply:IsMuted() and "_mute" or "") .. ".png")
		function Option6:DoClick()
			_AA( "gag", ply:SteamID() )
		end
		
		local Option7 = actions:AddOption("Kick player")
		Option7:SetIcon("icon16/door_out.png")
		function Option7:DoClick()
			_AA( "kick", ply:SteamID() )
		end
		
		local Option8 = actions:AddOption("Ban player")
		Option8:SetIcon("icon16/report_user.png")
		function Option8:DoClick()
			_AA( "ban", ply:SteamID() )
		end
	end

	if open then
		actions:Open()
	end
end

function GM:ScoreboardHide() if IsValid( menu ) then menu:Close() end end
function GM:HUDDrawScoreBoard() end

-- Voice Icons
local PANEL = { lastw = 0, lastName = "" }
local PlayerVoicePanels = {}

function PANEL:Init()
	self.LabelName = vgui.Create( "DLabel", self )
	self.LabelName:SetFont( "GModNotify" )
	self.LabelName:Dock( FILL )
	self.LabelName:DockMargin( 8, 0, 0, 0 )
	self.LabelName:SetTextColor( Color( 255, 255, 255, 255 ) )

	self.Avatar = vgui.Create( "AvatarImage", self )
	self.Avatar:Dock( LEFT )
	self.Avatar:SetSize( 32, 32 )

	self.Color = color_transparent
	
	self:SetSize( 250, 32 + 8 )
	self:DockPadding( 4, 4, 4, 4 )
	self:DockMargin( 2, 2, 2, 2 )
	self:Dock( TOP )
end

function PANEL:Setup( ply )
	self.ply = ply
	self.LabelName:SetText( ply:Nick() )
	self.Avatar:SetPlayer( ply )
	
	self.Color = team.GetColor( ply:Team() )
	
	self:InvalidateLayout()
end

function PANEL:Paint( w, h )
	if not IsValid( self.ply ) then return end

	local cw = w
	w = self.lastw
	draw.RoundedBox( 4, 0, 0, w, h, Color( 35, 45, 55, 180 + self.ply:VoiceVolume() * 255 ) )
	draw.RoundedBox( 4, 0, 0, 32 + 4 + 4, h, self.ply:Alive() and team.GetColor( self.ply:Team() ) or team.GetColor( TEAM_SPECTATOR ) )
	
	if self.lastw != cw then
		local nick = self.ply:Nick()

		surface.SetFont( "GModNotify" )
		local w2, h2 = surface.GetTextSize( nick )
		w2 = w2 + 32 + 16
		self:SetSize( w2, h )
		self.lastw = w2

		if self.lastName != nick then
			self.LabelName:SetText( nick )
			self.lastName = nick
		end
	end

end

function PANEL:Think( )
	if self.fadeAnim then
		self.fadeAnim:Run()
	end
end

function PANEL:FadeOut( anim, delta, data )
	if anim.Finished then
		if IsValid( PlayerVoicePanels[ self.ply ] ) then
			PlayerVoicePanels[ self.ply ]:Remove()
			PlayerVoicePanels[ self.ply ] = nil
			return
		end
		
		return
	end
	
	self:SetAlpha( 255 - (255 * delta) )
end
derma.DefineControl( "VoiceNotify2", "", PANEL, "DPanel" )

function GM:PlayerStartVoice( ply )
	if not IsValid( g_VoicePanelList ) then return end

	GAMEMODE:PlayerEndVoice( ply )

	if IsValid( PlayerVoicePanels[ ply ] ) then
		if PlayerVoicePanels[ ply ].fadeAnim then
			PlayerVoicePanels[ ply ].fadeAnim:Stop()
			PlayerVoicePanels[ ply ].fadeAnim = nil
		end
		
		return PlayerVoicePanels[ ply ]:SetAlpha( 255 )
	end

	if not IsValid( ply ) then return end

	local pnl = g_VoicePanelList:Add( "VoiceNotify2" )
	pnl:Setup( ply )
	
	PlayerVoicePanels[ ply ] = pnl
end

local function VoiceClean()
	for p,_ in pairs( PlayerVoicePanels ) do
		if not IsValid( p ) then
			GAMEMODE:PlayerEndVoice( p )
		end
	end
end
timer.Create( "VoiceClean", 10, 0, VoiceClean )

function GM:PlayerEndVoice( ply )
	if IsValid( PlayerVoicePanels[ ply ] ) then
		if PlayerVoicePanels[ ply ].fadeAnim then return end
		PlayerVoicePanels[ ply ].fadeAnim = Derma_Anim( "FadeOut", PlayerVoicePanels[ ply ], PlayerVoicePanels[ ply ].FadeOut )
		PlayerVoicePanels[ ply ].fadeAnim:Start( 0.5 )
	end
end

local function CreateVoiceVGUI()
	g_VoicePanelList = vgui.Create( "DPanel" )

	g_VoicePanelList:ParentToHUD()
	g_VoicePanelList:SetPos( ScrW() - 300, 100 )
	g_VoicePanelList:SetSize( 250, ScrH() - 200 )
	g_VoicePanelList:SetDrawBackground( false )
	
	Client:Setup()
end
hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )

if IsValid( g_VoicePanelList ) then
	g_VoicePanelList:Remove()
	CreateVoiceVGUI()
end