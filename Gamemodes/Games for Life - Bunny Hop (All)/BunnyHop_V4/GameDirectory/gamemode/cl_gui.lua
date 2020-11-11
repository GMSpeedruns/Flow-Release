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

Fonts = {
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
Window.Active = nil
Window.KeyLimit = false
Window.KeyLimitDelay = 1 / 4
Window.Unclosable = { "Vote", "Radio" }

Window.List = {
	WR = { Dim = { 235, 290 }, Title = "Records" },
	Nominate = { Dim = { 230, 250 }, Title = "Nominate" },
	Vote = { Dim = { 270, 170 }, Title = "Voting" },
	Spectate = { Dim = { 140, 80 }, Title = "Spectate?" },
	Style = { Dim = { 145, 170 }, Title = "Set Style" }
}

function Window:Open( szIdentifier, szArg )
	Window.Active = vgui.Create( "DFrame" )
	Window.Active:SetTitle( "" )
	Window.Active:SetDraggable( false )
	Window.Active:ShowCloseButton( false )
	
	Window.Active.Data = Window:LoadData( szIdentifier, szArg )
	Window.Active.Think = Window.Think
	Window.Active.Paint = Window.Paint
end

function Window:Close()
	if not IsValid( Window.Active ) then return end
	Window.Active:Close()
	Window.Active = nil
end

function Window.Paint()
	if not IsValid( Window.Active ) then return end

	local w, h = Window.Active:GetWide(), Window.Active:GetTall()
	surface.SetDrawColor( GUIColor.DarkGray )
	surface.DrawRect( 0, 0, w, h )
	surface.SetDrawColor( GUIColor.LightGray )
	surface.DrawRect( 10, 30, w - 20, h - 40 )
	
	local title = Window.Active.Data and Window.Active.Data.Title or ""
	draw.SimpleText( title, "HUDTitle", 10, 5, GUIColor.Blue, TEXT_ALIGN_LEFT )
end

function Window:LoadData( szIdentifier, szArg )
	local wnd = { ID = szIdentifier, Labels = {}, Offset = 35 }

	local FormData = Window.List[ szIdentifier ]
	if not FormData then return end

	wnd.Title = FormData.Title
	Window.Active:SetSize( FormData.Dim[ 1 ], FormData.Dim[ 2 ] )
	Window.Active:SetPos( 20, ScrH() / 2 - Window.Active:GetTall() / 2 )
	
	if szIdentifier == "WR" then
		wnd.View = tonumber( szArg ) or Config.Modes["Auto"]
		wnd.Title = Config.ModeNames[ wnd.View ] .. " Records"
		
		local Cache = Data.Cache.WR and Data.Cache.WR[ wnd.View ] or nil
		if Cache and #Cache > 0 then
			for rank, details in pairs( Cache ) do
				wnd.Labels[ rank ] = Window.MakeLabel{ parent = Window.Active, x = 15, y = wnd.Offset, font = Fonts.Label, color = GUIColor.White, text = "#" .. rank .. " [" .. Timer:Convert( details[2] ) .. "]: " .. details[1] }
				wnd.Offset = wnd.Offset + 16
			end
		else
			wnd.Labels[1] = Window.MakeLabel{ parent = Window.Active, x = 15, y = wnd.Offset, font = Fonts.Label, color = GUIColor.White, text = "No records!" }
		end
	elseif szIdentifier == "Style" then
		for i = Config.Modes["Auto"], Config.Modes["Bonus"] + 1 do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = Window.Active, x = 15, y = wnd.Offset, font = Fonts.Label, color = i == Client.Mode and GUIColor.Prefixes[Config.Prefix.Admin] or GUIColor.White, text = (i > Config.Modes["Bonus"] and 0 or i) .. ". " .. Config.ModeNames[ i ] }
			wnd.Offset = wnd.Offset + 16
		end
	elseif szIdentifier == "Nominate" then
		wnd.bVoted = false
		wnd.nPages = math.ceil( #Data.Cache.Maps / 7 )
		wnd.nPage = 1
		
		for i = 1, 10 do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = Window.Active, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i > 7 and (i > 9 and i - 10 or i) .. ". " .. Lang.Navigation[ i - 7 ] or "(" .. i .. ") " .. Data.Cache.Maps[ i ][ 2 ] }
			wnd.Offset = wnd.Offset + 20
		end
		
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
			
			wnd.Labels[i] = Window.MakeLabel{ parent = Window.Active, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i .. " [" .. wnd.Votes[i] .. "] " .. Data.Cache.Vote[i] }
			wnd.Offset = wnd.Offset + 20
		end
		
		timer.Simple( 30, function() Window:Close() end )
	elseif szIdentifier == "Spectate" then
		wnd.Title = (LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR) and "Stop?" or "Spectate?"
		Window.Active:Center()
		Window.Active:MakePopup()
		
		Window.MakeButton{ parent = Window.Active, w = 32, h = 24, x = 33, y = 38, text = "Yes", onclick = function() Window:Close() RunConsoleCommand( "spectate" ) end }
		Window.MakeButton{ parent = Window.Active, w = 32, h = 24, x = 75, y = 38, text = "No", onclick = function() Window:Close() end }
	end
	
	return wnd
end

function Window.Think()
	if not IsValid( Window.Active ) then return end
	local wnd = Window.Active.Data
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
		if Key > 0 and Key < 8 and not Window.KeyLimit then
			local szVotedMap = Data.Cache.Maps[ 7 * wnd.nPage - 7 + Key ][1]
			if not szVotedMap then return end
			wnd.bVoted = true
			
			RunConsoleCommand( "nominate", szVotedMap )
			timer.Simple( 0.25, function() Window:Close() end )
		elseif Key == 8 and not Window.KeyLimit and not wnd.bVoted and wnd.nPage != 1 then
			wnd.nPage = wnd.nPage - 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				wnd.Labels[i]:SetText( "(" .. i .. ") " .. Data.Cache.Maps[ Index + i ][2] )
				wnd.Labels[i]:SizeToContents()
				wnd.Labels[i]:SetVisible( true )
			end
			
			Window.PageToggle( wnd, true )
		elseif Key == 9 and not Window.KeyLimit and not wnd.bVoted and wnd.nPage != wnd.nPages then
			wnd.nPage = wnd.nPage + 1
			local Index = 7 * wnd.nPage - 7
			
			for i = 1, 7 do
				if Data.Cache.Maps[ Index + i ] then
					wnd.Labels[i]:SetText( "(" .. i .. ") " .. Data.Cache.Maps[ Index + i ][2] )
					wnd.Labels[i]:SizeToContents()
					wnd.Labels[i]:SetVisible( true )
				else
					wnd.Labels[i]:SetText( "" )
					wnd.Labels[i]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, false )
		end
	elseif ID == "Vote" then
		local TimeTitle = "Voting (" .. math.ceil( math.Clamp( wnd.VoteEnd - CurTime(), 0, 30 ) ) .. "s left)"
		if TimeTitle != wnd.Title then wnd.Title = TimeTitle end
		
		if Key > 0 and Key < 7 and not Window.KeyLimit and not wnd.bVoted then
			wnd.bVoted = true
			wnd.nVoted = Key
			wnd.Labels[ Key ]:SetColor( GUIColor.Prefixes[ Config.Prefix.Vote ] )

			RunConsoleCommand( "vote", tostring(Key) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			Window.KeyLimitDelay = 3
		elseif Key > 0 and Key < 7 and not Window.KeyLimit and wnd.bVoted and Key != wnd.nVoted then
			wnd.Labels[ wnd.nVoted ]:SetColor( GUIColor.White )
			wnd.Labels[ Key ]:SetColor( GUIColor.Prefixes[ Config.Prefix.Vote ] )
		
			RunConsoleCommand( "vote", tostring(Key), tostring(wnd.nVoted) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			
			wnd.nVoted = Key
			Window.KeyLimitDelay = 3
		end
		
		if wnd.bUpdate then
			wnd.bUpdate = false
			for i = 1, 6 do
				if not wnd.Votes[i] then continue end
				wnd.Labels[i]:SetText( i .. " [" .. wnd.Votes[i] .. "] " .. Data.Cache.Vote[i] )
				wnd.Labels[i]:SizeToContents()
			end
		end
	elseif ID == "Style" then
		if Key > 0 and Key < Config.Modes["Bonus"] + 1 and not Window.KeyLimit and not wnd.Selected then
			wnd.Selected = true
			RunConsoleCommand( "mode", tostring( Key ) )
			Key = 0
		end
	end
	
	if Key == 0 and not Window.KeyLimit and not table.HasValue( Window.Unclosable, ID ) then
		timer.Simple( Window.KeyLimitDelay, function()
			if IsValid( Window.Active ) then
				Window.Active:Close()
				Window.Active = nil
			end
		end )
	elseif Key >= 0 and not Window.KeyLimit then
		Window.KeyLimit = true
		timer.Simple( Window.KeyLimitDelay, function()
			Window.KeyLimit = false
		end )
	end
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