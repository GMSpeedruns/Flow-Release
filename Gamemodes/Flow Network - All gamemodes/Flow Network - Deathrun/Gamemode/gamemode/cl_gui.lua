GUIColor = {
	White = Color(255, 255, 255),
	Header = Color(255, 255, 255),
	LightGray = Color(42, 42, 42),
	DarkGray = Color(35, 35, 35)
}

local Fonts = {
	Label = "HUDLabelSmall",
	MediumLabel = "HUDLabelMed",
	StrongLabel = "HUDLabel"
}

surface.CreateFont( "HUDHeaderBig", { size = 44, font = "Coolvetica" } )
surface.CreateFont( "HUDHeader", { size = 30, font = "Coolvetica" } )
surface.CreateFont( "HUDTitle", { size = 24, font = "Coolvetica" } )
surface.CreateFont( "HUDTitleSmall", { size = 20, font = "Coolvetica" } ) 

surface.CreateFont( "HUDFont", { size = 22, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDFontSmall", { size = 14, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDLabelSmall", { size = 12, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDLabelMed", { size = 15, weight = 550, font = "Verdana" } )
surface.CreateFont( "HUDLabel", { size = 17, weight = 550, font = "Verdana" } )

surface.CreateFont( "HUDSpecial", { size = 17, weight = 550, font = "Verdana", italic = true } )
surface.CreateFont( "HUDSpeed", { size = 16, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDTimer", { size = 17, weight = 800, font = "Trebuchet24" } )
surface.CreateFont( "HUDPrint", { size = 14, weight = 800, font = "Trebuchet24" } )
surface.CreateFont( "HUDMessage", { size = 30, weight = 800, font = "Verdana" } )
surface.CreateFont( "HUDCounter", { size = 144, weight = 800, font = "Coolvetica" } )
surface.CreateFont( "HUDRound", { size = 48, weight = 550, font = "Coolvetica", antialias = true } )

Window = {}
Window.Unclosable = { "Vote" }
Window.NoThink = { "Radio", "Help", "Admin", "VIP" }

Window.List = {
	Vote = { Dim = { 370, 170 }, Title = "Voting" },
	Nominate = { Dim = { 230, 270 }, Title = "Nominate" },
	WR = { Dim = { 280, 226 }, Title = "Records" },
	Ranks = { Dim = { 235, 250 }, Title = "Rank List" },
	Spectate = { Dim = { 140, 80 }, Title = "Spectate?" },
	Radio = { Dim = { 600, 470 }, Title = "Radio" },
	Help = { Dim = { 650, 400 }, Title = "Help" },
	Admin = { Dim = { 0, 0 }, Title = "Admin Panel" },
	VIP = { Dim = { 0, 0 }, Title = "VIP Panel" }
}

local ActiveWindow = nil
local KeyLimit = false
local KeyLimitDelay = 1 / 4
local KeyChecker = LocalPlayer

local WindowThink = function() end
local WindowPaint = function() end

function Window:Open( szIdentifier, varArgs, bForce )
	if IsValid( ActiveWindow ) and not bForce then
		if ActiveWindow.Data and table.HasValue( Window.Unclosable, ActiveWindow.Data.ID ) then
			return
		end
	end
	
	Window:Close()

	ActiveWindow = vgui.Create( "DFrame" )
	ActiveWindow:SetTitle( "" )
	ActiveWindow:SetDraggable( false )
	ActiveWindow:ShowCloseButton( false )
	
	ActiveWindow.Data = Window:LoadData( szIdentifier, varArgs )
	
	if IsValid( ActiveWindow ) then
		if not table.HasValue( Window.NoThink, szIdentifier ) then
			ActiveWindow.Think = WindowThink
		end
		if szIdentifier != "Help" then
			ActiveWindow.Paint = WindowPaint
		end
	end
end

function Window:Update( szIdentifier, varArgs )
	if not IsValid( ActiveWindow ) then return end
	if not ActiveWindow.Data then return end
	
	ActiveWindow.Data = Window:LoadData( szIdentifier, varArgs, ActiveWindow.Data )
end

function Window:Close()
	if not IsValid( ActiveWindow ) then return end
	ActiveWindow:Close()
	ActiveWindow = nil
end

function Window:LoadData( szIdentifier, varArgs, varUpdate )
	local wnd = varUpdate or { ID = szIdentifier, Labels = {}, Offset = 35 }

	local FormData = Window.List[ szIdentifier ]
	if not FormData then return end
	
	if not varUpdate then
		if szIdentifier == "Admin" or szIdentifier == "VIP" then
			Window.List[ szIdentifier ].Title = varArgs.Title
			Window.List[ szIdentifier ].Dim = { varArgs.Width, varArgs.Height }
			FormData = Window.List[ szIdentifier ]
		end
	
		wnd.Title = FormData.Title
		KeyLimitDelay = 1 / 4
		ActiveWindow:SetSize( FormData.Dim[ 1 ], FormData.Dim[ 2 ] )
		ActiveWindow:SetPos( 20, ScrH() / 2 - ActiveWindow:GetTall() / 2 )
	end
	
	if szIdentifier == "Vote" then
		wnd.bVoted = false
		wnd.nVoted = -1
		wnd.VoteEnd = CurTime() + 30
		wnd.Votes = { 0, 0, 0, 0, 0, 0 }
		
		for i = 1, 6 do
			if i < 6 then
				local tab = Cache.V_Data[ i ]
				if not tab then continue end
				Cache.V_Data[ i ] = tab
			else
				if i == 6 and Cache.V_Data[ i ] and Cache.V_Data[ i ][ 1 ] == "__NO_EXTEND__" then
					Cache.V_Data[ i ] = "Extend not possible"
					wnd.bNoExtend = true
				else
					Cache.V_Data[ i ] = "Extend current map"
				end
			end
			
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i .. " [" .. wnd.Votes[ i ] .. "] " .. Cache.V_Data[ i ] }
			wnd.Offset = wnd.Offset + 20
			
			if i == 6 and wnd.bNoExtend then
				wnd.Labels[ i ]:SetColor( Color( 125, 125, 125 ) )
			end
		end
		
		timer.Simple( 30, function() if not Window.AbortClose then Window:Close() end end )
	elseif szIdentifier == "Nominate" then
		wnd.nServer = tonumber( varArgs[ 1 ] )
		if #Cache.M_Data == 0 or wnd.nServer != Cache.M_Version then
			Link:Send( "MapList", { Cache.M_Version } )
			Window:Close()
		else
			if wnd.nServer != Cache.M_Version then
				return Link:Send( "MapList", { Cache.M_Version } )
			end
			
			wnd.Title = "Nominate (" .. #Cache.M_Data .. " maps)"
			wnd.bVoted = false
			wnd.nPages = math.ceil( #Cache.M_Data / _C.PageSize )
			wnd.nPage = 1
			
			table.sort( Cache.M_Data, function( a, b )
				return a[ 1 ] < b[ 1 ]
			end )
			
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			for i = 1, _C.PageSize do
				local Item = Cache.M_Data[ Index + i ]
				wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = Item and i .. ". " .. Item[ 1 ] or "" }
				wnd.Offset = wnd.Offset + 20
			end
			
			wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Previous Page" }
			wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Next Page" }
			wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 60, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
			
			if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
			if wnd.nPage == wnd.nPages then wnd.Labels[9]:SetVisible( false ) end
		end
	elseif szIdentifier == "WR" then
		wnd.Times = varArgs
		wnd.Title = "Records (#" .. #wnd.Times .. ")"
		
		if wnd.Times and #wnd.Times > 0 then
			for i = 1, #wnd.Times do
				wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = i  .. ". [" .. Core.Util:Convert( wnd.Times[ i ][ 3 ] ) .. "]: " .. wnd.Times[ i ][ 1 ] }
				wnd.Offset = wnd.Offset + 16
			end
		else
			wnd.Labels[ 1 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = "No records!" }
		end
		
		wnd.Labels[ 11 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = Window.List.WR.Dim[ 2 ] - (2 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "0. Close Window" }
	elseif szIdentifier == "Ranks" then
		Link:Print( "General", "This functionality isn't finished yet. Here is a list of the ranks that are to come." )
		
		wnd.Ranks = {}
		wnd.nRanks = 0
		
		for i,item in pairs( _C.Ranks ) do
			if i >= 0 then
				table.insert( wnd.Ranks, { ID = i, Data = item } )
				wnd.nRanks = wnd.nRanks + 1
			end
		end
		
		table.SortByMember( wnd.Ranks, "ID", true )
		
		wnd.nPage = 1
		wnd.nPages = math.ceil( wnd.nRanks / _C.PageSize )
		wnd.Title = "Deathrun Ranks (#" .. wnd.nRanks .. ")"
		
		for i = 1, _C.PageSize do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "" }
			wnd.Offset = wnd.Offset + 20
		end
		
		local c = 1
		for id,data in pairs( wnd.Ranks ) do
			if c > _C.PageSize then break end
			
			wnd.Labels[ c ]:SetColor( data.Data[ 2 ] )
			wnd.Labels[ c ]:SetText( data.ID .. ". " .. data.Data[ 1 ] )
			wnd.Labels[ c ]:SizeToContents()
			c = c + 1
		end
		
		wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Previous Page" }
		wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Next Page" }
		wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
	
		if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
		if wnd.nPage == wnd.nPages then wnd.Labels[ 9 ]:SetVisible( false ) end
	elseif szIdentifier == "Spectate" then
		wnd.Title = (LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR) and "Stop?" or "Spectate?"
		ActiveWindow:Center()
		ActiveWindow:MakePopup()
		
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 33, y = 38, text = "Yes", onclick = function() Window:Close() RunConsoleCommand( "say", "!spectate" ) end }
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 75, y = 38, text = "No", onclick = function() Window:Close() end }
	elseif szIdentifier == "Help" then
		ActiveWindow:SetTitle( "" )
		ActiveWindow:ShowCloseButton( true )
		ActiveWindow:SetDraggable( true )
		ActiveWindow:Center()
		
		local list = vgui.Create( "DPanelList", ActiveWindow )
		list:SetSize( ActiveWindow:GetWide() - 12, ActiveWindow:GetTall() - 50 )
		list:SetPos( 8, 45 )
		list:EnableVerticalScrollbar( true )
		
		local wndHelpText = string.Explode( "\n", varArgs )
		if #Cache.H_Data > 0 then
			for i = 1, 3 do table.insert( wndHelpText, "" ) end
			table.insert( wndHelpText, "Simple Command List" )
			for _,data in pairs( Cache.H_Data ) do
				table.insert( wndHelpText, "!" .. data[ 2 ][ 1 ] .. "      " .. data[ 1 ] )
			end
		end
		
		for i = 1, #wndHelpText do
			local text = vgui.Create( "DLabel", ActiveWindow )
			text:SetFont( "HUDTitleSmall" )
			text:SetColor( GUIColor.White )
			text:SetText( wndHelpText[ i ] )
			text:SizeToContents()
			list:AddItem( text )
		end
		
		ActiveWindow.Paint = function()
			local w, h = ActiveWindow:GetWide(), ActiveWindow:GetTall()
			surface.SetDrawColor( GUIColor.DarkGray )
			surface.DrawRect( 0, 0, w, h )
			surface.SetDrawColor( GUIColor.LightGray )
			surface.DrawRect( 5, 5, w - 10, h - 10 )
			surface.SetDrawColor( LocalPlayer() and team.GetColor( LocalPlayer():Team() ) or Color(25, 25, 25, 150) )
			surface.DrawOutlinedRect( 4, 4, w - 8, 40 )
			draw.SimpleText( GAMEMODE.DisplayName, "HUDHeader", w / 2 + 2, 10, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( GAMEMODE.DisplayName, "HUDHeader", w / 2, 8, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
		end
		
		ActiveWindow:MakePopup()
	elseif szIdentifier == "Radio" then
		Radio:CreateWindow( ActiveWindow, varArgs )
	elseif szIdentifier == "Admin" or szIdentifier == "VIP" then
		Admin:GenerateGUI( ActiveWindow, varArgs )
	end
	
	return wnd
end

WindowPaint = function()
	if not IsValid( ActiveWindow ) then return end

	local w, h = ActiveWindow:GetWide(), ActiveWindow:GetTall()
	surface.SetDrawColor( GUIColor.DarkGray )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( GUIColor.LightGray )
	surface.DrawRect( 10, 30, w - 20, h - 40 )
	
	local title = ActiveWindow.Data and ActiveWindow.Data.Title or ""
	draw.SimpleText( title, "HUDTitle", 10, 5, GUIColor.Header, TEXT_ALIGN_LEFT )
end

WindowThink = function()
	if not IsValid( ActiveWindow ) then return end
	local wnd = ActiveWindow.Data
	if not wnd then return end
	
	local Key = -1
	for KeyID = 1, 10 do
		if input.IsKeyDown( KeyID ) then
			Key = KeyID - 1
			break
		end
	end
	
	if KeyChecker and IsValid( KeyChecker() ) and KeyChecker():IsTyping() then
		Key = -1
	end
	
	local ID = wnd.ID
	if ID == "Vote" then
		local TimeTitle = "Voting (" .. math.ceil( math.Clamp( wnd.VoteEnd - CurTime(), 0, 30 ) ) .. "s left)"
		if TimeTitle != wnd.Title then wnd.Title = TimeTitle end
		
		if wnd.EnableExtend then
			Cache.V_Data[ 6 ] = "Extend current map"
			wnd.bNoExtend = nil
			wnd.EnableExtend = nil
			wnd.VoteEnd = CurTime() + 30
			wnd.Labels[ 6 ]:SetText( "6 [" .. wnd.Votes[ 6 ] .. "] " .. Cache.V_Data[ 6 ] )
			wnd.Labels[ 6 ]:SetColor( GUIColor.White )
			
			Window.AbortClose = true
			timer.Simple( 30, function() Window:Close() Window.AbortClose = nil end )
		end
		
		if wnd.InstantVote then
			wnd.bVoted = true
			wnd.nVoted = wnd.InstantVote
			wnd.Labels[ wnd.nVoted ]:SetColor( _C.Prefixes.Notification )
			
			Link:Send( "Vote", { wnd.nVoted } )
			
			KeyLimitDelay = 1
			wnd.InstantVote = nil
		end
		
		if Key > 0 and Key < 8 and not KeyLimit and not wnd.bVoted then
			if Key == 6 and wnd.bNoExtend then return end
		
			wnd.bVoted = true
			wnd.nVoted = Key
			wnd.Labels[ Key ]:SetColor( _C.Prefixes.Notification )

			Link:Send( "Vote", { Key } )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			KeyLimitDelay = 3
		elseif Key > 0 and Key < 8 and not KeyLimit and wnd.bVoted and Key != wnd.nVoted then
			if Key == 6 and wnd.bNoExtend then return end
		
			wnd.Labels[ wnd.nVoted ]:SetColor( GUIColor.White )
			wnd.Labels[ Key ]:SetColor( _C.Prefixes.Notification )
			
			Link:Send( "Vote", { Key, wnd.nVoted } )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			wnd.nVoted = Key
			KeyLimitDelay = 3
		end
		
		if wnd.Update then
			wnd.Update = false
			
			for i = 1, 7 do
				if not wnd.Votes[ i ] then continue end
				
				wnd.Labels[ i ]:SetText( i .. " [" .. wnd.Votes[ i ] .. "] " .. (Cache.V_Data[ i ] or "ERROR") )
				wnd.Labels[ i ]:SizeToContents()
			end
		end
	elseif ID == "Nominate" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local Index = _C.PageSize * wnd.nPage - _C.PageSize + Key
			local szVotedMap = Cache.M_Data[ Index ]
			if not szVotedMap or not szVotedMap[ 1 ] then return end
			wnd.bVoted = true
			
			RunConsoleCommand( "nominate", szVotedMap[ 1 ] )
			timer.Simple( 0.25, function() Window:Close() end )
		elseif not KeyLimit and not wnd.bVoted and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage != wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			
			for i = 1, _C.PageSize do
				if Cache.M_Data[ Index + i ] then
					local Item = Cache.M_Data[ Index + i ]
					
					wnd.Labels[ i ]:SetText( i .. ". " .. Item[ 1 ] )
					wnd.Labels[ i ]:SetColor( GUIColor.White )
					wnd.Labels[ i ]:SizeToContents()
					wnd.Labels[ i ]:SetVisible( true )
				else
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SetColor( GUIColor.White )
					wnd.Labels[ i ]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, bPrev )
		end
	elseif ID == "WR" then
		if Key >= 0 and Key <= 9 and not KeyLimit then
			local Index = Key == 0 and 10 or Key
			local Item = wnd.Times[ Index ]
			if Item then
				local orig = Index != Item[ 5 ] and "(Originally #" .. Item[ 5 ] .. ") " or ""
				Link:Print( "Deathrun", "The #" .. Index .. " record " .. orig .. "on this map (Time: " .. Core.Util:Convert( Item[ 3 ] ) .. ") was obtained by " .. Item[ 1 ] .. " (Steam ID: " .. Item[ 2 ] .. ") on " .. Item[ 6 ] .. " with " .. Item[ 4 ] .. " jumps." )
			end
			
			if Index == 10 and Item then
				if Key == 0 and not wnd.Close then Key = 1 wnd.Close = true Link:Print( "General", "Showing #10 record data. Press 0 again to close the window." )
				elseif Key == 0 and wnd.Close then Key = 0 wnd.Close = nil
				elseif Key != 0 then wnd.Close = nil end
			end
		end
	elseif ID == "Ranks" then
		if not KeyLimit and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage != wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			
			local c, start, begin, changed = 1, 1, _C.PageSize * wnd.nPage - _C.PageSize
			for id,data in pairs( wnd.Ranks ) do
				if start > begin then
					if c > _C.PageSize then break end
				
					wnd.Labels[ c ]:SetColor( data.Data[ 2 ] )
					wnd.Labels[ c ]:SetText( data.ID .. ". " .. data.Data[ 1 ] )
					wnd.Labels[ c ]:SizeToContents()
					c = c + 1
				else
					start = start + 1
				end
			end
			
			if c < 8 then
				for i = c, 8 do
					if i > _C.PageSize then break end
					wnd.Labels[ i ]:SetColor( GUIColor.White )
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SizeToContents()
				end
			end
			
			Window.PageToggle( wnd, bPrev )
		end
	end
	
	if Key == 0 and not KeyLimit and not table.HasValue( Window.Unclosable, ID ) then
		timer.Simple( KeyLimitDelay, function()
			if IsValid( ActiveWindow ) then
				ActiveWindow:Close()
				ActiveWindow = nil
			end
		end )
	elseif Key >= 0 and not KeyLimit then
		KeyLimit = true
		timer.Simple( KeyLimitDelay, function()
			KeyLimit = false
		end )
	end
end


function Window:GetActive()
	return ActiveWindow
end

function Window:IsActive( szIdentifier )
	if IsValid( ActiveWindow ) then
		if not ActiveWindow.Data then return false end
		return ActiveWindow.Data.ID == szIdentifier
	end
	
	return false
end


function Window.PageToggle( data, bPrev )
	if not bPrev then
		if data.nPage == data.nPages then
			data.Labels[ 8 ]:SetVisible( true )
			data.Labels[ 9 ]:SetVisible( false )
		else
			data.Labels[ 8 ]:SetVisible( true )
			data.Labels[ 9 ]:SetVisible( true )
		end
	else
		if data.nPage == 1 then
			data.Labels[ 8 ]:SetVisible( false )
			data.Labels[ 9 ]:SetVisible( true )
		else
			data.Labels[ 8 ]:SetVisible( true )
			data.Labels[ 9 ]:SetVisible( true )
		end
	end
end

function Window.MakeLabel( t )
	local lbl = vgui.Create( "DLabel", t.parent )
	lbl:SetPos( t.x, t.y )
	lbl:SetFont( t.font )
	lbl:SetColor( t.color )
	lbl:SetText( t.text )
	lbl:SizeToContents()
	return lbl
end

function Window.MakeButton( t )
	local btn = vgui.Create( "DButton", t.parent )
	btn:SetSize( t.w, t.h )
	btn:SetPos( t.x, t.y )
	btn:SetText( t.text )
	if t.id then btn.SetID = t.id end
	btn.DoClick = t.onclick
	return btn
end

function Window.MakeTextBox( t )
	local txt = vgui.Create( "DTextEntry", t.parent )
	txt:SetPos( t.x, t.y )
	txt:SetSize( t.w, t.h )
	txt:SetText( t.text or "" )
	return txt
end

function Window.MakeQuery( c, t, ... )
	local qry = Derma_Query( c, t, ... )
	local arg = { ... }

	if #arg < 9 then return end
	
	local nTall = math.ceil( #arg / 8 ) * 30
	local nExtra = nTall - 30
	local x, y, c = 5, 25, 1
	local dPanel = nil
	
	for _,panel in pairs( qry:GetChildren() ) do
		if panel:GetClassName() == "Panel" then
			if panel:GetTall() == 30 then
				panel:SetTall( nTall )
				dPanel = panel
			end
		end
	end

	for k=9, #arg, 2 do
		local Text, Func = arg[ k ], arg[ k + 1 ] or function() end
		local Button = vgui.Create( "DButton", dPanel )
			Button:SetText( Text )
			Button:SizeToContents()
			Button:SetTall( 20 )
			Button:SetWide( Button:GetWide() + 20 )
			Button.DoClick = function() qry:Close(); Func() end
			Button:SetPos( x, y + 5 )
			
		x, c = x + Button:GetWide() + 5, c + 1

		if c > 4 then x, y, c = 5, y + 25, 1 end
	end
	
	qry:SetTall( qry:GetTall() + nExtra )
end

function Window.MakeRequest( c, t, d, f, l )
	Derma_StringRequest( t, c, d or "", f, l )
end

local function AddAlpha( c, v )
	return Color( c.r, c.g, c.b, v )
end

function Core.Util:AddAlpha( c, v )
	AddAlpha( c, v )
end

-- Drawing

local ViewGUI = CreateClientConVar( "sl_showgui", "1", true, false )
local GUI_X = CreateClientConVar( "sl_gui_xoffsetd", ScrW() / 2 - 106, true, false )
local GUI_Y = CreateClientConVar( "sl_gui_yoffsetd", 5, true, false )
local GUI_O = CreateClientConVar( "sl_gui_opacity", "255", true, false )

local Xo = GUI_X:GetInt() or ScrW() / 2 - 106
local Yo = GUI_Y:GetInt() or 5
local Ov = GUI_O:GetInt() or 255

local lp, ct = LocalPlayer, CurTime
local mm, mc, mr = math.max, math.ceil, math.Round
local CVictoryEnd, CVictory, CRound, CEndTime

local TopCaptions = {
	[0] = {
		{ "Round time: ", function() local t = CEndTime if not t then t = RealTime() end return string.ToMinutesSeconds( mm( t - RealTime(), 0 ) ) end },
		{ "Velocity: ", function() return LocalPlayer():Alive() and mr( LocalPlayer():GetVelocity():Length2D() ) or 0 end }
	},
	[1] = {
		{ "Run time: ", function() local t = Cache:T_GetRunTime() return t < 0 and "N/A" or string.ToMinutesSeconds( t ) end },
		{ "My record: ", function() local t = Cache:T_GetRecord() return t < 0 and "N/A" or string.ToMinutesSeconds( t ) end }
	}
}
local ActiveCaption, ActiveEnd = 0, ct() + 7

local function HUDEditTick()
	local step = input.IsKeyDown( KEY_LSHIFT ) and 20 or 5
	if input.IsKeyDown( KEY_RIGHT ) and not input.IsKeyDown( KEY_LEFT ) then
		Xo = Xo + step
	elseif input.IsKeyDown( KEY_LEFT ) and not input.IsKeyDown( KEY_RIGHT ) then
		Xo = Xo - step
	end
	
	if input.IsKeyDown( KEY_UP ) and not input.IsKeyDown( KEY_DOWN ) then
		Yo = Yo - step
	elseif input.IsKeyDown( KEY_DOWN ) and not input.IsKeyDown( KEY_UP ) then
		Yo = Yo + step
	end
	
	if Xo < 0 then Xo = Xo + step end
	if Xo + 212 > ScrW() then Xo = Xo - step end
	
	if Yo < 0 then Yo = Yo + step end
	if Yo > ScrH() - 80 then Yo = Yo - step end
end

function Client:ToggleEdit()
	if not Client.HUDEdit then
		Client.HUDEdit = true
		timer.Create( "HUDEdit", 0.05, 0, HUDEditTick )
		
		Link:Print( "General", "You are now editing your HUD position! Use your arrow keys to move it around! Type !hudedit again to save." )
	else
		Client.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		Client:SetHUDPosition( Xo, Yo )
		
		Link:Print( "General", "HUD editing has been disabled again. The new position has been saved!" )
	end
end

function Client:RestoreTo( pos )
	if Client.HUDEdit then
		Client.HUDEdit = nil
		timer.Destroy( "HUDEdit" )
		
		Link:Print( "General", "HUD editing was enabled. We disabled it for you so if you want to use it again, please type !hudedit." )
	end
	
	Client:SetHUDPosition( ScrW() / 2 - pos[ 1 ], pos[ 2 ] )
	Link:Print( "General", "HUD has been restored to its initial position." )
end

function Client:SetOpacity( o )
	RunConsoleCommand( "sl_gui_opacity", o )
	
	Ov = o
	
	Link:Print( "General", "HUD opacity has been changed to " .. o .. " (" .. math.Round( (o / 255) * 100, 1 ) .. "%)" )
end

function Client:SetHUDPosition( x, y )
	RunConsoleCommand( "sl_gui_xoffsetd", x )
	RunConsoleCommand( "sl_gui_yoffsetd", y )

	Xo = x
	Yo = y
end

function Client:GUIVisibility( nTarget )
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

function Client:SetVictory( varData )
	CVictoryEnd = ct() + 5
	CVictory = varData
end

function Client:SetDisplayRound( nRound )
	CRound = nRound
end

function Client:SetRoundTime( nTime )
	CEndTime = RealTime() + nTime
end


local function PaintHUD()
	if not ViewGUI:GetBool() then return end
	
	local nWidth, nHeight = ScrW(), ScrH() - 30
	local nHalfW = nWidth / 2
	local lpc = lp()
	
	if not IsValid( lpc ) then return end
	
	if CVictory then
		local szText = CVictory[ 1 ]
		local a = 255
		
		if ct() > CVictoryEnd then a = 0 szText = ""
		elseif ct() > CVictoryEnd - 1 then a = 255 * (CVictoryEnd - ct()) end
		
		draw.SimpleText( szText, "HUDCounter", nWidth / 2, (nHeight + 30) / 2 - 150, AddAlpha( CVictory[ 2 ], a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if szText == "" then CVictoryEnd, CVictory = nil, nil end
	end
	
	local ob = lpc:GetObserverTarget()
	if not lpc:Alive() or IsValid( ob ) then
		if IsValid( ob ) and ob:IsPlayer() then
			local DrawData = { Header = "Spectating", Player = ob:Name() }
			draw.SimpleText( DrawData.Header, "HUDHeaderBig", nHalfW + 2, nHeight - 58, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( DrawData.Header, "HUDHeaderBig", nHalfW, nHeight - 60, team.GetColor( ob:Team() ), TEXT_ALIGN_CENTER )

			draw.SimpleText( DrawData.Player, "HUDHeader", nHalfW + 2, nHeight - 18, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
			draw.SimpleText( DrawData.Player, "HUDHeader", nHalfW, nHeight - 20, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER )
		end
		
		local text = "Press R to change spectate mode"
		draw.SimpleText( text, "HUDHeader", nHalfW + 2, 32, Color(25, 25, 25, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( text, "HUDHeader", nHalfW, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER )
		draw.SimpleText( "Cycle through players with left/right mouse", "HUDTitleSmall", nHalfW, 60, Color(255, 255, 255), TEXT_ALIGN_CENTER )
	else
		local col = AddAlpha( team.GetColor( lpc:Team() ), Ov )
		local mid, wid = Xo + 106, 212
		
		surface.SetDrawColor( col )
		surface.DrawRect( mid - (wid / 2), Yo, wid, 80 )
		surface.SetDrawColor( Color(35, 35, 35, Ov) )
		surface.DrawRect( mid - (wid / 2 ) + 2, Yo + 2, wid - 50, 56 )
		surface.DrawRect( mid - (wid / 2 ) + 2, Yo + 60, wid - 50, 18 )
		
		local health = mm( mr( lpc:Health() or 100 ), 0 )
		for i = 0, 9 do
			local block, increased = (i + 1) * 10, mc( health / 10 ) * 10
			surface.SetDrawColor( block <= increased and col or Color(54, 54, 54, Ov) )
			surface.DrawRect( mid - (wid / 2) + 4 + (i * 16), Yo + 62, 14, 14 )
		end
		
		draw.SimpleText( health .. "%", "HUDTimer", mid + (wid / 2) - 24, Yo + 68, Color(255, 255, 255, Ov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( CRound or "?", "HUDRound", mid + (wid / 2) - 25, Yo + 32, Color(255, 255, 255, Ov), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		local a = 255
		if ct() > ActiveEnd and ActiveEnd > 0 then
			a = 255 * (ActiveEnd + 0.5 - ct())
		end
		a = (Ov / 255) * a
		
		local caption = TopCaptions[ ActiveCaption ]
		draw.SimpleText( caption[ 1 ][ 1 ], "HUDTimer", mid - (wid / 2) + 10, Yo + 15, Color(255, 255, 255, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( caption[ 1 ][ 2 ](), "HUDTimer", mid + (wid / 2) - 55, Yo + 15, Color(255, 255, 255, a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		
		draw.SimpleText( caption[ 2 ][ 1 ], "HUDTimer", mid - (wid / 2) + 10, Yo + 43, Color(255, 255, 255, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		draw.SimpleText( caption[ 2 ][ 2 ](), "HUDTimer", mid + (wid / 2) - 55, Yo + 43, Color(255, 255, 255, a), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		
		
		local w = lpc:GetActiveWeapon()
		if IsValid( w ) and w.Clip1 then
			local nAmmo = lpc:GetAmmoCount( w:GetPrimaryAmmoType() )
			local szWeapon = w:Clip1() .. " / " .. nAmmo
			if nAmmo == 0 then return end
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 18, ScrH() - 18, Color(25, 25, 25, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
			draw.SimpleText( szWeapon, "HUDHeader", nWidth - 20, ScrH() - 20, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
		end
	end
end
hook.Add( "HUDPaintBackground", "GUIHook", PaintHUD )

local function SwitchHUDContent()
	if IsValid( lp() ) and lp():Team() == TEAM_DEATH then
		ActiveCaption = 0
		ActiveEnd = 0
	else
		if IsValid( lp() ) and not lp():Alive() then
			Cache:T_Reset()
		end
		
		ActiveCaption = 1 - ActiveCaption
		ActiveEnd = ct() + 7.5
	end
end
timer.Create( "HUDSwapper", 8, 0, SwitchHUDContent )