GUIColor = {
	White = Color(255, 255, 255),
	Blue = Color(0, 120, 255),
	LightGray = Color(52, 73, 94),
	DarkGray = Color(44, 62, 80),
	
	Prefixes = {
		[Config.Prefix.Game] = Color(52, 152, 219),
		[Config.Prefix.Timer] = Color(52, 73, 118),
		[Config.Prefix.Admin] = Color(231, 76, 60),
		[Config.Prefix.Bot] = Color(127, 140, 141),
		[Config.Prefix.LJ] = Color(243, 156, 18),
		[Config.Prefix.Radio] = Color(230, 126, 34),
		[Config.Prefix.Command] = Color(46, 204, 113),
		[Config.Prefix.Vote] = Color(192, 57, 43)
	}
}

local Fonts = {
	Label = "HUDLabelSmall",
	StrongLabel = "HUDLabel"
}

surface.CreateFont( "HUDHeaderBig", { size = 44, font = "Coolvetica" } )
surface.CreateFont( "HUDHeader", { size = 30, font = "Coolvetica" } )
surface.CreateFont( "HUDTitle", { size = 24, font = "Coolvetica" } )
surface.CreateFont( "HUDTitleSmall", { size = 20, font = "Coolvetica" } ) 

surface.CreateFont( "HUDFont", { size = 22, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDFontSmall", { size = 14, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDLabelSmall", { size = 12, weight = 800, font = "Tahoma" } )
surface.CreateFont( "HUDLabel", { size = 17, weight = 550, font = "Verdana" } )

Window = {}
Window.Unclosable = { "Vote", "Radio" }

Window.List = {
	WR = { Dim = { 260, 242 }, Title = "Records" },
	Nominate = { Dim = { 260, 290 }, Title = "Nominate" },
	Vote = { Dim = { 270, 170 }, Title = "Voting" },
	Spectate = { Dim = { 140, 80 }, Title = "Spectate?" },
	Style = { Dim = { 145, 170 }, Title = "Set Style" },
	Admin = { Dim = { 260, 230 }, Title = "Admin Panel" },
	Radio = { Dim = { 600, 370 }, Title = "Radio" },
	Top = { Dim = { 240, 250 }, Title = "Top List" },
}

local ActiveWindow = nil
local KeyLimit = false
local KeyLimitDelay = 1 / 4

local WindowThink = function() end
local WindowPaint = function() end

function Window:Open( szIdentifier, szArg )
	if IsValid( ActiveWindow ) then
		if ActiveWindow.Data.ID == "Vote" then
			return
		end
	end
	
	Window:Close()

	ActiveWindow = vgui.Create( "DFrame" )
	ActiveWindow:SetTitle( "" )
	ActiveWindow:SetDraggable( false )
	ActiveWindow:ShowCloseButton( false )
	
	ActiveWindow.Data = Window:LoadData( szIdentifier, szArg )
	ActiveWindow.Think = WindowThink
	ActiveWindow.Paint = WindowPaint
end

function Window:Close()
	if not IsValid( ActiveWindow ) then return end
	ActiveWindow:Close()
	ActiveWindow = nil
end

function Window:LoadData( szIdentifier, szArg )
	local wnd = { ID = szIdentifier, Labels = {}, Offset = 35 }

	local FormData = Window.List[ szIdentifier ]
	if not FormData then return end

	wnd.Title = FormData.Title
	KeyLimitDelay = 1 / 4
	ActiveWindow:SetSize( FormData.Dim[ 1 ], FormData.Dim[ 2 ] )
	ActiveWindow:SetPos( 20, ScrH() / 2 - ActiveWindow:GetTall() / 2 )
	
	if szIdentifier == "WR" then
		wnd.Title = Config.ModeNames[ Data.Cache.WR.Mode ] .. " Records (#" .. Data.Cache.WR.Count .. ")"
		wnd.nPages = math.ceil( Data.Cache.WR.Count / 7 )
		wnd.nPage = 1
		wnd.nMode = Data.Cache.WR.Mode

		local Cache = Data.Cache.WR.Data
		if Cache and #Cache > 0 then
			local nAdd = szArg and tonumber( szArg ) - 1 or 0
			for i = 1, 7 do
				if Cache[ i + nAdd ] then
					wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.Label, color = GUIColor.White, text = i  .. ". [#" .. i + nAdd .. " " .. Timer:Convert( Cache[ i + nAdd ][2] ) .. "]: " .. Cache[ i + nAdd ][1] }
				else
					wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.Label, color = GUIColor.White, text = "" }
				end
				wnd.Offset = wnd.Offset + 16
				wnd.nPage = math.floor( (i + nAdd) / 7 )
			end
		else
			wnd.Labels[1] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.Label, color = GUIColor.White, text = "No records!" }
		end
		
		wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = Window.List.WR.Dim[ 2 ] - (5 * 16), font = Fonts.Label, color = GUIColor.White, text = "8. Previous Page" }
		wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = Window.List.WR.Dim[ 2 ] - (4 * 16), font = Fonts.Label, color = GUIColor.White, text = "9. Next Page" }
		wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = Window.List.WR.Dim[ 2 ] - (3 * 16), font = Fonts.Label, color = GUIColor.White, text = "0. Close Window" }
		wnd.Labels[ 11 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = Window.List.WR.Dim[ 2 ] - (2 * 16), font = Fonts.Label, color = GUIColor.White, text = "Type '!wr [mode]' for other WRs" }
		
		if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
		if wnd.nPage == wnd.nPages then wnd.Labels[9]:SetVisible( false ) end
	elseif szIdentifier == "Style" then
		for i = Config.Modes["Auto"], Config.Modes["Bonus"] + 1 do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.Label, color = i == Client.Mode and GUIColor.Prefixes[Config.Prefix.Admin] or GUIColor.White, text = (i > Config.Modes["Bonus"] and 0 or i) .. ". " .. Config.ModeNames[ i ] }
			wnd.Offset = wnd.Offset + 16
		end
	elseif szIdentifier == "Nominate" then	
		wnd.nMode = tonumber( szArg ) or 0
		wnd.bVoted = false
		wnd.nPages = math.ceil( #Data.Cache.Maps / 7 )
		wnd.nPage = 1
		
		if wnd.nMode == 0 then
			table.sort( Data.Cache.Maps, function(a, b)
				return a[1] < b[1]
			end )
		elseif wnd.nMode == 1 then
			table.sort( Data.Cache.Maps, function(a, b)
				return a[3] < b[3]
			end )
		end
		
		for i = 1, 10 do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i > 7 and (i > 9 and i - 10 or i) .. ". " .. Lang.Navigation[ i - 7 ] or "(" .. i .. ") " .. (wnd.ShowPoints and "[" .. Data.Cache.Maps[ Index + i ][3] .. "] " or "") .. Data.Cache.Maps[ i ][ 2 ] }
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Labels[ 11 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "P. Toggle points" }
		wnd.Labels[ 12 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "S. Toggle sorting mode" }
		wnd.Labels[ 8 ]:SetVisible( false )
	elseif szIdentifier == "Vote" then
		wnd.bVoted = false
		wnd.nVoted = -1
		wnd.VoteEnd = CurTime() + 30
		wnd.Votes = { 0, 0, 0, 0, 0, 0 }
		wnd.Points = { 0, 0, 0, 0, 0, -1 }
		
		for i = 1, 6 do
			if i < 6 then
				local tab = Data.Maps:GetMap( Data.Cache.Vote[i] )
				if not tab then continue end
				wnd.Points[i] = tab[3]
				Data.Cache.Vote[i] = tab[2] .. " (" .. wnd.Points[i] .. " pts)"
			else
				local tab = Data.Maps:GetMap( game.GetMap() )
				if not tab then continue end
				wnd.Points[i] = tab[3]
				Data.Cache.Vote[i] = "Extend current map"
			end
			
			wnd.Labels[i] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i .. " [" .. wnd.Votes[i] .. "] " .. Data.Cache.Vote[i] }
			wnd.Offset = wnd.Offset + 20
		end
		
		timer.Simple( 30, function() Window:Close() end )
	elseif szIdentifier == "Spectate" then
		wnd.Title = (LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR) and "Stop?" or "Spectate?"
		ActiveWindow:Center()
		ActiveWindow:MakePopup()
		
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 33, y = 38, text = "Yes", onclick = function() Window:Close() RunConsoleCommand( "spectate" ) end }
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 75, y = 38, text = "No", onclick = function() Window:Close() end }
	elseif szIdentifier == "Top" then
		wnd.nPages = math.ceil( #Data.Cache.Top / 7 )
		wnd.nPage = 1

		for i = 1, 10 do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i > 7 and (i > 9 and i - 10 or i) .. ". " .. Lang.Navigation[ i - 7 ] or (Data.Cache.Top[ i ] and "#" .. i .. ". " .. Data.Cache.Top[ i ].Name or "#" .. i .. ". Blank") }
			wnd.Offset = wnd.Offset + 20
		end

		wnd.Labels[ 8 ]:SetVisible( false )
		if wnd.nPages < 2 then
			wnd.Labels[ 9 ]:SetVisible( false )
		end
	elseif szIdentifier == "Admin" then
		Admin:CreateWindow( wnd )
	elseif szIdentifier == "Radio" then
		Radio:CreateWindow( wnd )
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
	draw.SimpleText( title, "HUDTitle", 10, 5, GUIColor.Blue, TEXT_ALIGN_LEFT )
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
	
	local ID = wnd.ID
	if ID == "Nominate" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local szVotedMap = Data.Cache.Maps[ 7 * wnd.nPage - 7 + Key ][1]
			if not szVotedMap then return end
			wnd.bVoted = true
			
			RunConsoleCommand( "nominate", szVotedMap )
			timer.Simple( 0.25, function() Window:Close() end )
		elseif Key == 8 and not KeyLimit and not wnd.bVoted and wnd.nPage != 1 then
			wnd.nPage = wnd.nPage - 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				wnd.Labels[i]:SetText( "(" .. i .. ") " .. (wnd.ShowPoints and "[" .. Data.Cache.Maps[ Index + i ][3] .. "] " or "") .. Data.Cache.Maps[ Index + i ][2] )
				wnd.Labels[i]:SizeToContents()
				wnd.Labels[i]:SetVisible( true )
			end
			
			Window.PageToggle( wnd, true )
		elseif Key == 9 and not KeyLimit and not wnd.bVoted and wnd.nPage != wnd.nPages then
			wnd.nPage = wnd.nPage + 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				if Data.Cache.Maps[ Index + i ] then
					wnd.Labels[i]:SetText( "(" .. i .. ") " .. (wnd.ShowPoints and "[" .. Data.Cache.Maps[ Index + i ][3] .. "] " or "") .. Data.Cache.Maps[ Index + i ][2] )
					wnd.Labels[i]:SizeToContents()
					wnd.Labels[i]:SetVisible( true )
				else
					wnd.Labels[i]:SetText( "" )
					wnd.Labels[i]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, false )
		elseif input.IsKeyDown( KEY_P ) and not KeyLimit and not wnd.bVoted then
			wnd.ShowPoints = not wnd.ShowPoints

			local Index = 7 * wnd.nPage - 7
			for i = 1, 7 do
				if Data.Cache.Maps[ Index + i ] then
					wnd.Labels[i]:SetText( "(" .. i .. ") " .. (wnd.ShowPoints and "[" .. Data.Cache.Maps[ Index + i ][3] .. "] " or "") .. Data.Cache.Maps[ Index + i ][2] )
					wnd.Labels[i]:SizeToContents()
					wnd.Labels[i]:SetVisible( true )
				else
					wnd.Labels[i]:SetText( "" )
					wnd.Labels[i]:SetVisible( false )
				end
			end
			
			Key = 20
		elseif input.IsKeyDown( KEY_S ) and not KeyLimit and not wnd.bVoted then
			local tabSort = { [0] = "Alphabetical", [1] = "Numeric" }
			wnd.nMode = 1 - wnd.nMode
			Window:Open( "Nominate", wnd.nMode )
			Message:Print( Config.Prefix.Command, "Generic", { "Sorting mode has been changed to " .. tabSort[ wnd.nMode ] or "Unknown" } )
			Key = 20
		end
	elseif ID == "Vote" then
		local TimeTitle = "Voting (" .. math.ceil( math.Clamp( wnd.VoteEnd - CurTime(), 0, 30 ) ) .. "s left)"
		if TimeTitle != wnd.Title then wnd.Title = TimeTitle end
		
		if Key > 0 and Key < 7 and not KeyLimit and not wnd.bVoted then
			wnd.bVoted = true
			wnd.nVoted = Key
			wnd.Labels[ Key ]:SetColor( GUIColor.Prefixes[ Config.Prefix.Vote ] )

			RunConsoleCommand( "vote", tostring(Key) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			KeyLimitDelay = 3
		elseif Key > 0 and Key < 7 and not KeyLimit and wnd.bVoted and Key != wnd.nVoted then
			wnd.Labels[ wnd.nVoted ]:SetColor( GUIColor.White )
			wnd.Labels[ Key ]:SetColor( GUIColor.Prefixes[ Config.Prefix.Vote ] )
		
			RunConsoleCommand( "vote", tostring(Key), tostring(wnd.nVoted) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			wnd.nVoted = Key
			KeyLimitDelay = 3
		end
		
		if wnd.bUpdate then
			wnd.bUpdate = false
			for i = 1, 6 do
				if not wnd.Votes[i] then continue end
				
				wnd.Labels[i]:SetText( i .. " [" .. wnd.Votes[i] .. "] " .. (Data.Cache.Vote[i] or "Unknown") )
				wnd.Labels[i]:SizeToContents()
			end
		end
	elseif ID == "Style" then
		if Key > 0 and Key < Config.Modes["Bonus"] + 1 and not KeyLimit and not wnd.Selected then
			wnd.Selected = true
			RunConsoleCommand( "mode", tostring( Key ) )
			Key = 0
		end
	elseif ID == "WR" then
		if Key > 0 and Key < 8 and not KeyLimit then
			RunConsoleCommand( "getwrinfo", tostring( wnd.nMode ), tostring( wnd.nPage * 7 - 7 + Key ) )
		elseif Key == 8 and not KeyLimit and wnd.nPage != 1 then
			wnd.nPage = wnd.nPage - 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				wnd.Labels[i]:SetText( i  .. ". [#" .. Index + i .. " " .. Timer:Convert( Data.Cache.WR.Data[ Index + i ][2] ) .. "]: " .. Data.Cache.WR.Data[ Index + i ][1] )
				wnd.Labels[i]:SizeToContents()
				wnd.Labels[i]:SetVisible( true )
			end
			
			Window.PageToggle( wnd, true )
		elseif Key == 9 and not KeyLimit and wnd.nPage != wnd.nPages then
			if not Data.Cache.WR.Full then
				RunConsoleCommand( "getwrinfo", tostring( wnd.nMode ), tostring( 16 ) )
			else
				wnd.nPage = wnd.nPage + 1
				local Index = 7 * wnd.nPage - 7

				for i = 1, 7 do
					if Data.Cache.WR.Data[ Index + i ] then
						wnd.Labels[i]:SetText( i  .. ". [#" .. Index + i .. " " .. Timer:Convert( Data.Cache.WR.Data[ Index + i ][2] ) .. "]: " .. Data.Cache.WR.Data[ Index + i ][1] )
						wnd.Labels[i]:SizeToContents()
						wnd.Labels[i]:SetVisible( true )
					else
						wnd.Labels[i]:SetText( "" )
						wnd.Labels[i]:SetVisible( false )
					end
				end
				
				Window.PageToggle( wnd, false )
			end
		end
	elseif ID == "Top" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local data = Data.Cache.Top[ 7 * wnd.nPage - 7 + Key ]
			if not data then return end
			
			Message:Print( Config.Prefix.Game, "Generic", { "Additional data [Name: " .. data.Name .. ", Points: " .. data.Points .. ", Rank: " .. Config.Ranks[ data.Rank ][1] .. ", Times connected: " .. data.PlayCount .. ", Time in-game: " .. data.ConnectionTime .. "]" } )
		elseif Key == 8 and not KeyLimit and not wnd.bVoted and wnd.nPage != 1 then
			wnd.nPage = wnd.nPage - 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				wnd.Labels[i]:SetText( "#" .. Index + i .. ". " .. Data.Cache.Top[ Index + i ].Name )
				wnd.Labels[i]:SizeToContents()
				wnd.Labels[i]:SetVisible( true )
			end
			
			Window.PageToggle( wnd, true )
		elseif Key == 9 and not KeyLimit and not wnd.bVoted and wnd.nPage != wnd.nPages then
			wnd.nPage = wnd.nPage + 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				if Data.Cache.Top[ Index + i ] then
					wnd.Labels[i]:SetText( "#" .. Index + i .. ". " .. Data.Cache.Top[ Index + i ].Name )
					wnd.Labels[i]:SizeToContents()
					wnd.Labels[i]:SetVisible( true )
				else
					wnd.Labels[i]:SetText( "" )
					wnd.Labels[i]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, false )
		end
	elseif ID == "Admin" then
		if not KeyLimit then
			local varReturn = Admin:WindowProcess( wnd, Key )
			if varReturn and tonumber( varReturn ) then
				Key = varReturn
			end
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

function Window.PageToggle( data, bPrev )
	if not bPrev then
		if data.nPage == data.nPages then
			data.Labels[8]:SetVisible( true )
			data.Labels[9]:SetVisible( false )
		else
			data.Labels[8]:SetVisible( true )
			data.Labels[9]:SetVisible( true )
		end
	else
		if data.nPage == 1 then
			data.Labels[8]:SetVisible( false )
			data.Labels[9]:SetVisible( true )
		else
			data.Labels[8]:SetVisible( true )
			data.Labels[9]:SetVisible( true )
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