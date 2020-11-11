include( "vgui.lua" )
include( "rtv/cl_rtv.lua" )
include( "cl_scoreboard.lua" )
include( "shared.lua" )

local showhud = CreateClientConVar("cl_showgui", "1", true, false)
local GREEN = Color( 0, 255, 25 )
local WHITE = Color( 255, 255, 255 )
local RED = Color( 255, 100, 100 )

surface.CreateFont( "HudFont1", { font = "Coolvetica", size = 20 } )
surface.CreateFont( "HudFont2", { font = "Coolvetica", size = 24 } )
surface.CreateFont( "HudFont3", { font = "Coolvetica", size = 30 } )

surface.CreateFont( "MenuFont", { font = "Coolvetica", size = 32.5 } )
surface.CreateFont( "MenuFont2", { font = "Coolvetica", size = 27.5 } )

surface.CreateFont("SPF_S", {
        size = 22,
        weight = 800,
        antialias = true,
        shadow = false,
        font = "Tahoma"})
surface.CreateFont("SPF_N", {
        size = 12,
        weight = 800,
        antialias = true,
        shadow = false,
        font = "Tahoma"})
		
local stoptime = 0
local record = "0:00"
local curtime = 0
local gotrecords = false
local recs = {{},{},{}}
bh_thirdperson = 0
drawWR = false
local ptype = 1
drawModes = false
bhmde = 1
local vmde = 1
local viewset = false

function InitializeClient()
	timer.Create("SetHullAndView", 5, 0, SetHullAndViewOffset)
end
hook.Add( "Initialize", "CInitialize", InitializeClient )

function SetHullAndViewOffset()
	if(LocalPlayer() && LocalPlayer():IsValid() && LocalPlayer().SetHull && LocalPlayer().SetHullDuck) then
		if(LocalPlayer().SetViewOffset && LocalPlayer().SetViewOffsetDucked && !viewset) then
			LocalPlayer():SetViewOffset(Vector(0, 0, 64))
			LocalPlayer():SetViewOffsetDucked(Vector(0, 0, 47))
			viewset = true
		end
		LocalPlayer():SetHull(Vector(-16, -16, 0), Vector(16, 16, 62))
		LocalPlayer():SetHullDuck(Vector(-16, -16, 0), Vector(16, 16, 45))
	end
end

function GM:CalcView( ply, pos, angles, fov )
	if(bh_thirdperson == 1) then
		pos = pos-( angles:Forward()*100 )+( angles:Up()*40 )
		local ang = (ply:GetPos()+( angles:Up()*30 ))-pos
		ang:Normalize()
		angles = ang:Angle()
	end
	
    return self.BaseClass:CalcView( ply, pos, angles, fov )
end

function GM:ShouldDrawLocalPlayer(ply)
	if(bh_thirdperson == 1) then
		return true
	end
	return self.BaseClass:ShouldDrawLocalPlayer(ply)
end

local function GetTime(time)
	local t = string.FormattedTime( time )
	local sec = "00"
	if(t.h > 0) then
		t.m = t.m + (60*t.h)
	end
	if(t.s < 10) then
		sec = "0"..tostring(t.s)
	else
		sec = tostring(t.s)
	end
	return tostring(t.m)..":"..sec
end
		
function surface.GetTextDim(text,font)
	surface.SetFont(font)
	local w, h = surface.GetTextSize(text)
	
	return w, h
end

function GM:HUDPaint()
	if(showhud:GetBool()) then
	local w2 = ScrW() / 2
	local h2 = ScrH() - 30
	
	local ob = LocalPlayer():GetObserverTarget()
	if ob and ob:IsValid() and ob:IsPlayer() then

		local text3 = "You are spectating \""..ob:Nick().."\""
		if(ob:IsBot()) then
			text3 = "You are spectating \""..GetGlobalString("WRBN","00:00 - N/A").."\""
		end
		draw.SimpleText( text3, "MenuFont", w2 + 2, h2 + 2, Color( 25, 25, 25, 255 ), TEXT_ALIGN_CENTER )
		draw.SimpleText( text3, "MenuFont", w2, h2, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
	
	if(LocalPlayer():Team() == TEAM_SPECTATOR) then
		draw.SimpleText( "Press R to change spectate mode.", "MenuFont", w2 + 2, 32, Color( 25, 25, 25, 255 ), TEXT_ALIGN_CENTER )
		draw.SimpleText( "Press R to change spectate mode.", "MenuFont", w2, 30, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end
	end
	
	return self.BaseClass:HUDPaint()
end

local vdata = {
	[1] = {
		x = 6,
		y = ScrH()-6-128,
	},
	[2] = {
		x = 6+128,
		y = ScrH()-6-128,
	},
	[3] = {
		x = 6+200,
		y = ScrH()-6-100,
	},
	[4] = {
		x = 6+200,
		y = ScrH()-6,
	},
	[5] = {
		x = 6,
		y = ScrH()-6,
	},
}
local vdata2 = {
	[1] = {
		x = 4,
		y = ScrH()-8-128,
	},
	[2] = {
		x = 7+128,
		y = ScrH()-8-128,
	},
	[3] = {
		x = 6+200,
		y = ScrH()-8-100,
	},
	[4] = {
		x = 6+200,
		y = ScrH()-4,
	},
	[5] = {
		x = 4,
		y = ScrH()-4,
	},
}
local avatarImg = nil
local mPanel = nil
local noinput = false
function GM:HUDPaintBackground ( )
	local tw,th = surface.GetTextDim("120:00","SPF_S")
	local nw = surface.GetTextDim("1. 120:00 - GGGGGGGGGGGGGGGGGGGG","SPF_N")+10
	local nw2 = surface.GetTextDim("Select your bhop mode:","SPF_N")+10
	tw = tw + 12

		if(drawWR) then
			draw.RoundedBox( 8, 20, ScrH()-6-128-450, nw, 250, Color( 12, 12, 12, 220 ) )
			
			if(gotrecords) then
				draw.SimpleText(GAMEMODE.ModeName[vmde].." Records", "SPF_N", 25, ScrH()-6-128-440, Color(255,255,255,255), 0, 3)
				for k,v in pairs(recs[vmde]) do
					draw.SimpleText(k..". "..GetTime(v['time']).." - "..string.sub(v['name'],1,20), "SPF_N", 25, (ScrH()-6-128-440)+16+16*k, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
				
				local othermodes = {}
				if(vmde == 1) then
					othermodes = {2,3}
				elseif(vmde == 2) then
					othermodes = {3,1}
				elseif(vmde == 3) then
					othermodes = {1,2}
				end
				
				for k,v in pairs(othermodes) do
					draw.SimpleText(tostring(7+k)..". "..GAMEMODE.ModeName[v], "SPF_N", 25, (ScrH()-6-128-440)+160+22+16*k, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
				draw.SimpleText("0. Exit", "SPF_N", 25, (ScrH()-6-128-440)+160+22+16*3, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				
				if(!noinput) then
					if(input.IsKeyDown(KEY_8)) then
						noinput = true
						timer.Simple(.2,function() vmde = othermodes[1] end)
						timer.Simple(.5,function() noinput = false end)
					elseif(input.IsKeyDown(KEY_9)) then
						noinput = true
						timer.Simple(.2,function() vmde = othermodes[2] end)
						timer.Simple(.5,function() noinput = false end)
					elseif(input.IsKeyDown(KEY_0)) then
						noinput = true
						timer.Simple(.2,function() drawWR = false noinput = false end)
					end
				end
			end
		elseif(drawModes) then
			draw.RoundedBox( 8, 20, ScrH()-6-128-279, nw2, 79, Color( 12, 12, 12, 220 ) )
			
			draw.SimpleText("Select your bhop mode:", "SPF_N", 25, ScrH()-6-128-269, Color(255,255,255,255), 0, 3)
			
			for k,v in pairs(GAMEMODE.ModeName) do
				if(k == bhmde) then
					draw.SimpleText(k..". "..v, "SPF_N", 25, (ScrH()-6-128-274)+16+16*k, Color(212,175,55,255),TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				else
					draw.SimpleText(k..". "..v, "SPF_N", 25, (ScrH()-6-128-274)+16+16*k, Color(255,255,255,255),TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end
			
			if(!noinput) then
				if(input.IsKeyDown(KEY_1)) && bhmde != 1 then
					noinput = true
					timer.Simple(.2,function() RunConsoleCommand("bh_modeswitch","1") drawModes = false noinput = false end)
				elseif(input.IsKeyDown(KEY_2)) && bhmde != 2 then
					noinput = true
					timer.Simple(.2,function() RunConsoleCommand("bh_modeswitch","2") drawModes = false noinput = false end)
				elseif(input.IsKeyDown(KEY_3)) && bhmde != 3 then
					noinput = true
					timer.Simple(.2,function() RunConsoleCommand("bh_modeswitch","3") drawModes = false noinput = false end)
				elseif(input.IsKeyDown(KEY_0)) then
					noinput = true
					timer.Simple(.2,function() drawModes = false noinput = false end)
				end
			end
		end

	if(LocalPlayer():Team() != TEAM_SPECTATOR && showhud:GetBool()) then
		if(!avatarImg) then
			avatarImg = vgui.Create("AvatarImage",avatarImg)
			avatarImg:SetSize(128,128)
			avatarImg:SetPos(6,ScrH()-128-6)
			avatarImg:SetPlayer(LocalPlayer(),64)
		end
		
		local w = (sp/2000)*150
		local pos = 6+128+((300-128-150)/2)
		
		surface.SetTexture(0)
		surface.SetDrawColor(Color( 0, 0, 0, 255))
		surface.DrawPoly(vdata2)
		surface.DrawRect(6+199, ScrH()-8-100,102,104)
		surface.SetDrawColor(Color( 122, 122, 122, 255))
		surface.DrawPoly(vdata)
		surface.DrawRect(6+200, ScrH()-6-100,99,100)
		surface.SetDrawColor(Color( 0, 0, 0, 255 ))
		surface.DrawRect(6+128+45-(tw/2), ScrH()-85-14, tw, 38)
		surface.DrawRect(6+300-45-(tw/2), ScrH()-85-14, tw, 38)
		surface.DrawRect(pos-2, ScrH()-6-40, 154, 30)
		surface.SetDrawColor(Color( 187, 187, 187, 255 ))
		surface.DrawRect(6+128+45-(tw/2)+2, ScrH()-85-12, tw-4, 34)
		surface.DrawRect(6+300-45-(tw/2)+2, ScrH()-85-12, tw-4, 34)
		surface.DrawRect(pos, ScrH()-6-38, 150, 26)
		surface.SetDrawColor(Color( 134, 134, 134, 255 ))
		surface.DrawRect(pos, ScrH()-6-38, w, 26)
		
		draw.SimpleText("Current:", "SPF_N", 6+128+45, ScrH()-85-6, Color(0,0,0,255), 1, 1)
		if(stoptime == 0) then
			draw.SimpleText(GetTime(CurTime() - curtime), "SPF_S", 6+128+45, ScrH()-70-6, Color(0,0,0,255), 1, 1)
		else
			draw.SimpleText(GetTime(stoptime), "SPF_S", 6+128+45, ScrH()-70-6, Color(0,0,0,255), 1, 1)
		end
		draw.SimpleText("Best:", "SPF_N", 6+300-45, ScrH()-85-6, Color(0,0,0,255), 1, 1)
		draw.SimpleText(record, "SPF_S", 6+300-45, ScrH()-70-6, Color(0,0,0,255), 1, 1)
		draw.SimpleText(tostring(sp), "SPF_S", pos+75, ScrH()-6-38+13, Color(0,0,0,255), 1, 1)
	else
		if(ValidPanel(avatarImg)) then
			avatarImg:Remove()
			avatarImg = nil
		end
	end
end

function GM:HUDShouldDraw ( Name )
	if Name == "CHudHealth" or Name == "CHudBattery" then
		return false;
	else
		return true;
	end
end

function GM:Move(pl, movedata)
	if(!pl or !pl:IsValid()) then return end
	sp = math.floor(movedata:GetVelocity():Length())
	self.BaseClass:Move(pl, movedata)
end

function RestartMap()
end

function bh_timeleft(time)
	chat.AddText(Color(255,255,255),"[",Color(0, 255, 25),"Voting",Color(255,255,255),"] There is "..GetTime(time).." left on this map.")
	chat.PlaySound()
end

function StopTime(time)
	stoptime = time
end

function FinishedMap(time)
	stoptime = time
	chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You have finished the map in "..GetTime(time)..". Type /restart or /r in chat to restart the level.")
	chat.PlaySound()
end

function PersRec(nt,ot)
	if(ot == 0) then
		chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You have got a new personal record of "..GetTime(nt).."!")
	else
		chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You have got a new personal record of "..GetTime(nt).." beating your old record of "..GetTime(ot).."!")
	end
	SetRecord(nt)
	chat.PlaySound()
end

function GotRec(nt,ot,pos)
	local text = "000"
	if(pos == 1) then
		text = "1st"
	elseif(pos == 2) then
		text = "2nd"
	elseif(pos == 3) then
		text = "3rd"
	else
		text = tostring(pos).."th"
	end
	if(ot == 0) then
		chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You have obtained "..text.." in the top 10 and a new personal record with a time of "..GetTime(nt).."!")
	else
		chat.AddText(Color(255,255,255),"[",Color(74,242,74),"BHOP",Color(255,255,255),"] You have obtained "..text.." in the top 10 and a new personal record with a time of "..GetTime(nt).." beating your old record of "..GetTime(ot).."!")
	end
	SetRecord(nt)
	chat.PlaySound()
end

function StartTime(time)
	stoptime = 0
	curtime = time
end

function SetRecord(time)
	record = GetTime(time)
end

local function ReceiveRecords(len)
	recs[net.ReadInt(10)] = net.ReadTable()
	gotrecords = true
end
net.Receive("bh_Records", ReceiveRecords)

local topdata = {}
local tdl = nil
local function ShowTopList(data)
	local id = data:ReadChar()
	if id == 1 then
		for i = 1, 10 do
			table.insert(topdata, {data:ReadLong(), data:ReadString()})
		end
	end
	
	if(!topdata[1]) then return end
	if(IsValid(tdl)) then return end

	tdl = vgui.Create( "DFrame" )
	tdl:SetTitle( "" )
	tdl:SetSize( 200, 250 )
	tdl:SetPos( 20, ScrH()/2 - tdl:GetTall()/2 )
	tdl:SetDraggable( false )
	tdl:ShowCloseButton( false )
	tdl.Paint = function()

		local w, h = tdl:GetWide(), tdl:GetTall()

		draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 140 ) )
		draw.RoundedBox( 6, 3, 2, w - 6, 20, Color( 2, 3, 5, 100 ) )
		draw.SimpleText( "Top 10 Players", "HudFont2", w/2, 1, RED, TEXT_ALIGN_CENTER )
     
	end
	
	local mapLabels = {}
	local yOffset = 25
	for i = 1, 11 do
		mapLabels[i] = vgui.Create( "DLabel", tdl )
		mapLabels[i]:SetPos( 7, yOffset )
		mapLabels[i]:SetFont("HudFont1")
		mapLabels[i]:SetColor( WHITE )
		
		if (i > 10) then
			mapLabels[i]:SetText( "(0) Quit" ) 
		elseif (i > 1) then
			mapLabels[i]:SetText( tostring(i) .. ". " .. topdata[i][2] .. " [" .. tostring(topdata[i][1]) .. "]" )
		elseif (i == 1) then
			mapLabels[i]:SetText( tostring(i) .. ". " .. topdata[i][2] .. " [" .. tostring(topdata[i][1]) .. "]" )
			mapLabels[i]:SetColor( Color(255,0,64) )
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end

	tdl.Think = function()

		if input.IsKeyDown( KEY_0 ) then
			timer.Simple(.25, function()
				if(tdl) then
					tdl:Close()
					tdl = nil
				end
			end)
		end

	end
end
usermessage.Hook( "LTopList", ShowTopList )


local men = nil

local infoText = {
	"Welcome to Bunny Hop!", 
	"",
	"This gamemode is all about bunny hopping.",
	"Use strafing to hop between the platforms succesfully!",
	"Sometimes some levels are harder than they look, try your best",
	"to conquer these levels as they will give you a high",
	"level of satisfaction.",
	"",
	"",
	"Have fun!",
	"",
	"Controls:",
	"To Enter Spectate press F2",
	"",
	"While spectating:",
	"Press your reload key to change spectating types.",
	"Press Mouse1/Mouse2 keys to cycle through players.",
	"",
	"Chat Commands:",
	"!rtv: Vote to change the map, if you're too impatient to",
	"have it occur normally.",
	"!timeleft: See how much time the current map has left.",
	"!motd: Show pG's MOTD",
	"/r or /restart: Reset your position to the start",
	"!wr: Shows the world records for this map",
	"!nominate: Select a map to be added to the list of",
	"next possible maps",
	"!top or !toplist: Shows the top players of our server",
	"!rank or !points: Shows your rank and the coming ranks",
	"!points [map]: Shows how many points a map",
	"is worth. Example: !points bhop_eazy_v2",
	"!mapsbeat: Shows the maps you have beaten",
	"!mapsleft: Shows the maps you still need to beat"
}

function ShowHelp()

	if not men then
		men = vgui.Create( "DFrame" )
		men:SetDeleteOnClose(false)
		men:MakePopup()

		men:SetSize( 600, 400 )
		men:SetPos( ScrW()/2 -men:GetWide()/2, ScrH() / 2 - men:GetTall()/2 )
		men.SetDText = "Bunny Hop"
		men:SetTitle( "" )

		local dlist = vgui.Create( "DPanelList", men )
		dlist:SetSize( men:GetWide() - 6, men:GetTall() - 50 )
		dlist:SetPos( 3, 45 )
		dlist:EnableVerticalScrollbar(true)

		men.Paint = function()
			--Derma_DrawBackgroundBlur(men)

			local w, h = men:GetWide(), men:GetTall()

			draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 200 ) )
			draw.RoundedBox( 6, 3, 2, w - 6, 40, LocalPlayer() and team.GetColor(LocalPlayer():Team()) or Color( 25, 25, 25, 150 ) )
			draw.SimpleText( men.SetDText, "MenuFont", w/2 + 2, 10, Color( 25, 25, 25, 255 ), TEXT_ALIGN_CENTER )
			draw.SimpleText( men.SetDText, "MenuFont", w/2, 8, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )

		end

		for i = 1, #infoText do
			local text = vgui.Create( "DLabel" )
			text:SetFont( "MenuFont2" )
			text:SetColor( Color( 200, 200, 200, 255 ) )
			text:SetText( infoText[i] )
			text:SizeToContents()
			dlist:AddItem(text)
		end
		
	else
		men:SetVisible(true)
	end

end

function ShowWR()
	if(!drawModes) then
		drawWR = true
	end
end

function ShowModes()
	if(!drawWR) then
		drawModes = true
	end
end

-- Admin CP Code

local function CP_Show( data )

	local id = data:ReadString()
	if string.len(id) != 10 then return end

	local Menu_Items = {
		{ Text = "Manage Player Times", ID = 1 },
		{ Text = "Get Player ID", ID = 2 },
		{ Text = "Manage WR Bot", ID = 3 },
		{ Text = "Long Jump Statistics", ID = 4 },
		{ Text = "Set SELECT Limit", ID = 5 },
		{ Text = "Quit", ID = 6 }
	}
	
	PromptForChoice( "Admin Panel", Menu_Items,
		function( Dlg, Itm, Prm )
			
			if Itm.ID == 1 then
				Dlg:Close()
				
				local Menu_Items = {
					{ Text = "View Single Player", ID = 1 },
					{ Text = "View top for Player", ID = 2 },
					{ Text = "View top for Map", ID = 3 },
					{ Text = "View top for all", ID = 4 },
					{ Text = "Quit", ID = 5 }
				}
				
				PromptForChoice( "Admin Panel - Times", Menu_Items,
					function( IDlg, IItm, IPrm )
					
						if IItm.ID == 1 then
							IDlg:Close()
							PromptStringRequest( "Player ID", 
								"Enter Player ID:", 
								"", 
								function( strTextOutID )
									local num = tonumber(strTextOutID)
									if !num then return end
									
									PromptStringRequest( "Map", 
										"Enter Map Name:", 
										"", 
										function( strTextOutMap )
											if strTextOutMap == "" then return end
											RunConsoleCommand( "acp_tm_time", strTextOutID, strTextOutMap )
										end
									)
								end
							)
						elseif IItm.ID == 2 then
							IDlg:Close()
							PromptStringRequest( "Player ID", 
								"Enter Player ID:", 
								"", 
								function( strTextOutID )
									local num = tonumber(strTextOutID)
									if !num then return end
									RunConsoleCommand( "acp_tm_timeid", strTextOutID )
								end
							)
						elseif IItm.ID == 3 then
							IDlg:Close()
							PromptStringRequest( "Map", 
								"Enter Map Name:", 
								"", 
								function( strTextOutMap )
									if strTextOutMap == "" then return end
									RunConsoleCommand( "acp_tm_timemap", strTextOutMap )
								end
							)
						elseif IItm.ID == 4 then
							IDlg:Close()
							RunConsoleCommand( "acp_tm_timeall" )
						elseif IItm.ID == 5 then
							IDlg:Close()
						end
						
					end
				)
			elseif Itm.ID == 2 then
				Dlg:Close()
				
				PromptStringRequest( "Player Name", 
					"Enter Player Name:", 
					"", 
					function( strTextOut )
						if string.len(strTextOut) < 4 then
							chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "Enter at least 4 characters to avoid overflow." )
							return
						end
						
						RunConsoleCommand( "acp_tm_id", strTextOut )
					end 
				)
				
			elseif Itm.ID == 3 then
				chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "This function is still under construction. GM:ReadWRRun() ++ local WRBotEnabled = false" )
				Dlg:Close()
			elseif Itm.ID == 4 then
				chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "This function is still under construction." )
				Dlg:Close()
			elseif Itm.ID == 5 then
				Dlg:Close()
				
				PromptStringRequest( "SELECT Limit", 
					"Enter new SELECT Limit:", 
					"", 
					function( strTextOut )
						if not tonumber(strTextOut) then
							chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "Enter a valid digit." )
							return
						end
						
						RunConsoleCommand( "acp_sel_limit", strTextOut )
					end 
				)
			elseif Itm.ID == 6 then
				Dlg:Close()
			end
			
		end
	)
	
end
usermessage.Hook( "CP_Show", CP_Show )

local function ReceiveACPData(len)
	local dataId = net.ReadInt(10)
	
	if dataId == 1 then
		local data = net.ReadTable()
		if #data == 0 then
			chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "No received data." )
			return
		end
		
		local Menu_Items = {}
		for k,v in pairs(data) do
			table.insert(Menu_Items, { Text = v['name'] .. " [" .. tostring(v['unique_id']) .. "]", ID = v['unique_id'] })
		end
	
		PromptForChoice( "Unique IDs", Menu_Items,
			function( Dlg, Itm, Prm )
				chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, Itm.Text .. "'s Unique ID: " .. Itm.ID )
				Dlg:Close()
			end
		)
	elseif dataId == 2 then
		local data = net.ReadTable()
		if #data == 0 then
			chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "No received data." )
			return
		end
		
		local Menu_Items = {
			{ Text = "Player Time: "..data[1]['time'], ID = 0 },
			{ Text = "Remove Time", ID = 1, UID = data[1]['unique_id'], MAP = data[1]['map_name'] },
			{ Text = "Edit Time", ID = 2, UID = data[1]['unique_id'], MAP = data[1]['map_name'] },
			{ Text = "Quit", ID = 3 }
		}
		
		PromptForChoice( "Actions", Menu_Items,
			function( Dlg, Itm, Prm )
				if Itm.ID == 1 then
					Derma_Query('Are you sure?','Confirm','Yes',function() RunConsoleCommand('acp_tm_rem', Itm.UID, Itm.MAP) end,'No',function() end)
				elseif Itm.ID == 2 then
					PromptStringRequest( "New time in secs (10 decimals)", 
						"Enter new time for map "..Itm.MAP..":", 
						"", 
						function( strTextOut )
							if !tonumber(strTextOut) then
								chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "An invalid digit was entered! A maximum of 10 digits are allowed." )
								return
							end
							
							RunConsoleCommand( "acp_tm_edit", strTextOut, Itm.UID, Itm.MAP )
						end
					)
				elseif Itm.ID == 0 or Itm.ID == 3 then
					Dlg:Close()
				end
			end
		)
	elseif dataId == 3 or dataId == 4 or dataId == 5 then
		local data = net.ReadTable()
		if #data == 0 then
			chat.AddText( WHITE, "[", RED, "Admin", WHITE, "] ", WHITE, "No received data." )
			return
		end
		
		local Menu_Items = {}
		for k,v in pairs(data) do
			if dataId == 3 then
				table.insert(Menu_Items, { Text = v['map_name']..": "..v['time'], ID = k, UID = v['unique_id'], MAP = v['map_name'] })
			elseif dataId == 4 then
				table.insert(Menu_Items, { Text = v['time']..": "..v['name'], ID = k, UID = v['unique_id'], MAP = v['map_name'] })
			elseif dataId == 5 then
				table.insert(Menu_Items, { Text = v['time']..": "..v['name'].."("..v['map_name']..")", ID = k, UID = v['unique_id'], MAP = v['map_name'] })
			end
		end
		
		PromptForChoice( "Actions", Menu_Items,
			function( Dlg, Itm, Prm )
				Derma_Query('Are you sure you want to remove this time?','Confirm','Yes',function() RunConsoleCommand('acp_tm_rem', Itm.UID, Itm.MAP) end,'No',function() end)
			end
		)
	end
end
net.Receive("acp_conn", ReceiveACPData)