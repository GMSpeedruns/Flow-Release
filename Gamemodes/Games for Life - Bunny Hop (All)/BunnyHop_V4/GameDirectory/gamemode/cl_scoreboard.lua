-- Originally taken from Murder, heavily modified for Bunny Hop by Gravious
local menu

surface.CreateFont( "ScoreboardPlayer" , {
	font = "coolvetica",
	size = 24,
	weight = 500,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersText1" , {
	font = "Tahoma",
	size = 16,
	weight = 1000,
	antialias = true,
	italic = false
})

surface.CreateFont( "MersRadial" , {
	font = "coolvetica",
	size = math.ceil(ScrW() / 34),
	weight = 500,
	antialias = true,
	italic = false
})

local muted = Material("icon32/muted.png")
local admin = Material("icon16/shield.png")

local function PutPlayerItem(self, pList, ply, mw)
	local but = vgui.Create("DButton")
	but.player = ply
	but.ctime = CurTime()
	but:SetTall(32)
	but:SetText("")
	function but:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(Color(150, 150, 150))
		surface.DrawOutlinedRect(0, 0, w, h)

		if IsValid(ply) && ply:IsPlayer() then
			local s = 0

			local rank = Config.Ranks[ ply:GetNWInt("Rank", 1) ]
			local timer = string.sub(Config.ModeNames[ply:GetNWInt("Mode", 1)], 1, 1) .. " - " .. Timer:Convert( ply:GetNWInt("Record", 0) )
			local speccolor = ply:GetNWInt("Spectating", 0) == 1 and Color(180, 180, 180) or color_white
			
			draw.DrawText(rank[1], "ScoreboardPlayer", s + 11, 9, color_black, TEXT_ALIGN_LEFT)
			draw.DrawText(rank[1], "ScoreboardPlayer", s + 10, 8, rank[2], TEXT_ALIGN_LEFT)
			
			s = s + mw + 56
			
			if ply:IsAdmin() then
				surface.SetMaterial(admin)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(s + 4, h / 2 - 8, 16, 16)
				s = s + 20
			end
			
			if ply:IsMuted() then
				surface.SetMaterial(muted)
				surface.SetDrawColor(color_white)
				surface.DrawTexturedRect(s + 4, h / 2 - 16, 32, 32)
				s = s + 32
			end

			local plyName = ply:IsBot() and "Run by: " .. ply:GetNWString("BotName", "Loading...") or ply:Name()
			draw.DrawText(plyName, "ScoreboardPlayer", s + 11, 9, color_black, TEXT_ALIGN_LEFT)
			draw.DrawText(plyName, "ScoreboardPlayer", s + 10, 8, speccolor, TEXT_ALIGN_LEFT)
			
			draw.DrawText(timer, "ScoreboardPlayer", w - (ScrW() * 0.175) + 1, 9, color_black, TEXT_ALIGN_LEFT) -- 327
			draw.DrawText(timer, "ScoreboardPlayer", w - (ScrW() * 0.175), 8, color_white, TEXT_ALIGN_LEFT)
			
			draw.DrawText(ply:Ping(), "ScoreboardPlayer", w - 9, 9, color_black, TEXT_ALIGN_RIGHT)
			draw.DrawText(ply:Ping(), "ScoreboardPlayer", w - 10, 8, color_white, TEXT_ALIGN_RIGHT)
		end
	end
	
	function but:DoClick()
		GAMEMODE:DoScoreboardActionPopup(ply)
	end

	pList:AddItem(but)
end

local function ListPlayers(self, pList, mw)
	local plyList = player.GetAll()
	table.sort(plyList, function(a, b)
		if not a or not b then return false end
		return a:GetNWInt("Rank", 1) > b:GetNWInt("Rank", 1)
	end)
	
	for k, ply in pairs(plyList) do
		local found = false

		for t,v in pairs(pList:GetCanvas():GetChildren()) do
			if v.player == ply then
				found = true
				v.ctime = CurTime()
			end
		end

		if not found then
			PutPlayerItem(self, pList, ply, mw)
		end
	end
	local del = false

	for t,v in pairs(pList:GetCanvas():GetChildren()) do
		if v.ctime != CurTime() then
			v:Remove()
			del = true
		end
	end

	if del then
		timer.Simple(0, function() pList:GetCanvas():InvalidateLayout() end)
	end
end

local function CreateTeamList(parent, mw)
	local pList
	
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(8, 8, 8, 8)
	
	function pnl:Paint(w, h) 
		surface.SetDrawColor(GUIColor.LightGray)
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	function pnl:Think()
		if !self.RefreshWait || self.RefreshWait < CurTime() then
			self.RefreshWait = CurTime() + 0.1
			ListPlayers(self, pList, mw)
		end
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0, 0, 0, 4)
	headp:Dock(TOP)
	function headp:Paint() end

	local rank = vgui.Create("DLabel", headp)
	rank:SetText("Rank")
	rank:SetFont("Trebuchet24")
	rank:SetTextColor(GUIColor.Blue)
	rank:SetWidth(50)
	rank:Dock(LEFT)
	
	local player = vgui.Create("DLabel", headp)
	player:SetText("Player")
	player:SetFont("Trebuchet24")
	player:SetTextColor(GUIColor.Blue)
	player:SetWidth(60)
	player:DockMargin(mw + 10, 0, 0, 0)
	player:Dock(LEFT)
	
	local ping = vgui.Create("DLabel", headp)
	ping:SetText("Ping")
	ping:SetFont("Trebuchet24")
	ping:SetTextColor(GUIColor.Blue)
	ping:SetWidth(50)
	ping:DockMargin(0, 0, 0, 0)
	ping:Dock(RIGHT)
	
	local timer = vgui.Create("DLabel", headp)
	timer:SetText("Record")
	timer:SetFont("Trebuchet24")
	timer:SetTextColor(GUIColor.Blue)
	timer:SetWidth(80)
	timer:DockMargin(0, 0, 200, 0)
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
	if IsValid(menu) then
		menu:SetVisible(true)
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

		local name = Label("Bunny Hop", menu.Credits)
		name:Dock(LEFT)
		name:SetFont("MersRadial")
		name:SetTextColor(GUIColor.Blue)
		
		function name:PerformLayout()
			surface.SetFont(self:GetFont())
			local w, h = surface.GetTextSize(self:GetText())
			self:SetSize(w, h)
		end

		local cred = vgui.Create( "DButton", menu.Credits )
		cred:Dock(RIGHT)
		cred:SetFont("MersText1")
		cred:SetText("by Gravious\nVersion " .. Config.Version)
		cred.PerformLayout = name.PerformLayout
		cred:SetTextColor(GUIColor.White)
		cred:SetDrawBackground( false )
		cred:SetDrawBorder( false )
		cred.DoClick = function()
			print(util.Compress("http://steamcommunity.com/id/Gravious_/"))
			gui.OpenURL( "http://steamcommunity.com/id/Gravious_/" )
		end

		function menu.Credits:PerformLayout()
			surface.SetFont(name:GetFont())
			local w,h = surface.GetTextSize(name:GetText())
			self:SetTall(h)
		end

		surface.SetFont("ScoreboardPlayer")
		local mw,mh = surface.GetTextSize("Getting There")
		
		menu.Players = CreateTeamList(menu, mw)
		menu.Players:Dock(FILL)
	end
end

function GM:ScoreboardHide()
	if IsValid(menu) then
		menu:Close()
	end
end

function GM:HUDDrawScoreBoard()
end

function GM:DoScoreboardActionPopup(ply)
	local actions = DermaMenu()

	if ply:IsAdmin() then
		local admin = actions:AddOption("Player is an admin")
		admin:SetIcon("icon16/shield.png")
	elseif ply:IsBot() then
		local bot = actions:AddOption("Player is a WR bot")
		bot:SetIcon("icon16/control_end.png")
	end

	if ply != LocalPlayer() then
		if not ply:IsBot() then
			local mute = actions:AddOption(ply:IsMuted() and "Unmute" or "Mute")
			mute:SetIcon("icon16/sound_mute.png")
			function mute:DoClick()
				if IsValid(ply) then
					ply:SetMuted(!ply:IsMuted())
				end
			end
			
			local profile = actions:AddOption("View Profile")
			profile:SetIcon("icon16/vcard.png")
			function profile:DoClick()
				ply:ShowProfile()
			end
		end
		
		local spec = actions:AddOption("Spectate Player")
		spec:SetIcon("icon16/eye.png")
		function spec:DoClick()
			RunConsoleCommand("spectate", tostring(ply:UniqueID()))
		end
	end
	
	if IsValid(LocalPlayer()) && LocalPlayer():IsAdmin() then
		actions:AddSpacer()

		local Option3 = actions:AddOption("Copy name")
		Option3:SetIcon("icon16/page_copy.png")
		function Option3:DoClick()
			SetClipboardText(ply:Name())
		end
		
		local Option4 = actions:AddOption("Copy Bhop UID")
		Option4:SetIcon("icon16/page_copy.png")
		function Option4:DoClick()
			SetClipboardText(ply:UniqueID())
		end
		
		local Option5 = actions:AddOption("Copy SteamID")
		Option5:SetIcon("icon16/page_copy.png")
		function Option5:DoClick()
			SetClipboardText(ply:SteamID())
		end
	end

	actions:Open()
end

function muteall()
	for k,v in pairs(player.GetHumans()) do if LocalPlayer() and v != LocalPlayer() and not v:IsMuted() then v:SetMuted(true) end end
	Message:Print( Config.Prefix.Game, "ScoreMute", { "muted" } )
end

function unmuteall()
	for k,v in pairs(player.GetHumans()) do if LocalPlayer() and v != LocalPlayer() and v:IsMuted() then v:SetMuted(false) end end
	Message:Print( Config.Prefix.Game, "ScoreMute", { "unmuted" } )
end

function togglechat()
	local nTime = GetConVar( "hud_saytext_time" ):GetInt()
	if nTime > 0 then
		Message:Print( Config.Prefix.Game, "ChatHide", { "hidden" } )
		RunConsoleCommand( "hud_saytext_time", 0 )
	else
		Message:Print( Config.Prefix.Game, "ChatHide", { "restored" } )
		RunConsoleCommand( "hud_saytext_time", 12 )
	end
end