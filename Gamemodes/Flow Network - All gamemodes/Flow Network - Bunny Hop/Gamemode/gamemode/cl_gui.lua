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
surface.CreateFont( "HUDMessage", { size = 30, weight = 800, font = "Verdana" } )
surface.CreateFont( "HUDCounter", { size = 144, weight = 800, font = "Coolvetica" } )

Window = {}
Window.Unclosable = { "Vote" }
Window.NoThink = { "Radio", "Admin", "VIP" }

Window.List = {
	WR = { Dim = { 280, 226 }, Title = "Records" },
	Nominate = { Dim = { 230, 330 }, Title = "Nominate" },
	Vote = { Dim = { 370, 190 }, Title = "Voting" },
	Spectate = { Dim = { 140, 80 }, Title = "Spectate?" },
	Style = { Dim = { 185, 270 }, Title = "Choose Style" },
	Top = { Dim = { 280, 234 }, Title = "Top List" },
	Ranks = { Dim = { 235, 250 }, Title = "Rank List" },
	Maps = { Dim = { 460, 250 }, Title = "Maps" },
	Checkpoints = { Dim = { 260, 250 }, Title = "Checkpoints" },
	Stats = { Dim = { 185, 130 }, Title = "Stats" },
	Radio = { Dim = { 600, 470 }, Title = "Radio" },
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
		
		ActiveWindow.Paint = WindowPaint
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
		wnd.Votes = { 0, 0, 0, 0, 0, 0, 0 }
		wnd.Data = {}
		
		for i = 1, 7 do
			if i < 6 then
				local tab = Cache.V_Data[ i ]
				if not tab then continue end
				wnd.Data[ i ] = tab[ 2 ] or 1
				Cache.V_Data[ i ] = tab[ 1 ] .. " (" .. wnd.Data[ i ] .. " pts)"
			else
				if i == 6 and Cache.V_Data[ i ] and Cache.V_Data[ i ][ 1 ] == "__NO_EXTEND__" then
					Cache.V_Data[ i ] = "Extend not possible"
					wnd.bNoExtend = true
				else
					Cache.V_Data[ i ] = i == 7 and "Go to a random map" or "Extend current map"
				end
			end
			
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = i .. " [" .. wnd.Votes[ i ] .. "] " .. Cache.V_Data[ i ] }
			wnd.Offset = wnd.Offset + 20
			
			if i == 6 and wnd.bNoExtend then
				wnd.Labels[ i ]:SetColor( Color( 125, 125, 125 ) )
			end
		end
		
		timer.Simple( 30, function() if not Window.AbortClose then Window:Close() end end )
	elseif szIdentifier == "WR" then
		local nType = varArgs[ 1 ]
		if nType == 2 then
			local tData, nStyle, nPage, nTotal, szMap = varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ], varArgs[ 5 ], varArgs[ 6 ]
			Cache.T_Data[ nStyle ] = {}
			for n,data in pairs( tData ) do
				Cache.T_Data[ nStyle ][ n ] = data
			end
			
			local nOffset = _C.PageSize * nPage - _C.PageSize			
			wnd.Title = Core:StyleName( nStyle ) .. " Records (#" .. nTotal .. ")"
			wnd.nPages = math.ceil( nTotal / _C.PageSize )
			wnd.nPage = 1
			wnd.nStart = wnd.nPage
			wnd.nStyle = nStyle
			wnd.vLoaded = { true }
			
			if szMap then
				wnd.szMap = szMap
				wnd.Title = wnd.szMap .. " " .. Core:StyleName( nStyle ) .. " Records (#" .. nTotal .. ")"
				
				for s,d in pairs( Cache.T_Data ) do
					if s != nStyle then
						Cache.T_Data[ s ] = {}
					end
				end
				
				ActiveWindow:SetSize( FormData.Dim[ 1 ] + 60, FormData.Dim[ 2 ] )
			else
				Timer:GetFirstTimes()
			end
			
			local data = Cache.T_Data[ nStyle ]
			if data and #data > 0 then
				for i = 1, _C.PageSize do
					wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = data[ i + nOffset ] and (i  .. ". [#" .. i + nOffset .. " " .. Timer:Convert( data[ i + nOffset ][ 3 ] ) .. "]: " .. data[ i + nOffset ][ 2 ]) or "" }
					wnd.Offset = wnd.Offset + 16
					wnd.nPage = math.floor( (i + nOffset) / _C.PageSize )
				end
			else
				wnd.Labels[ 1 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = "No records!" }
			end
			
			local d = Window.List.WR.Dim[ 2 ]
			wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (4 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "8. Previous Page" }
			wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (3 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "9. Next Page" }
			wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (2 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "0. Close Window" }
			
			if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
			if wnd.nPage == wnd.nPages or nTotal < _C.PageSize + 1 then wnd.Labels[ 9 ]:SetVisible( false ) end
		elseif nType == 4 then
			local tData, nPage, nTotal = varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ]
			local bDirection = nPage - wnd.nStart < 0
			local nPages = math.ceil( nTotal / _C.PageSize )
			wnd.nPage = nPage
			wnd.nStart = wnd.nPage
			
			if wnd.nPages != nPages then
				wnd.nPages = nPages
				wnd.vLoaded = { [wnd.nPage] = true }
				wnd.Title = Core:StyleName( wnd.nStyle ) .. " Records (#" .. nTotal .. ")"
			else
				wnd.vLoaded[ wnd.nPage ] = true
			end
			
			for n,data in pairs( tData ) do
				Cache.T_Data[ wnd.nStyle ][ n ] = data
			end
			
			if wnd.szMap then
				wnd.Title = wnd.szMap .. " " .. Core:StyleName( wnd.nStyle ) .. " Records (#" .. nTotal .. ")"
			end
			
			local data = Cache.T_Data[ wnd.nStyle ]
			if data and #data > 0 then
				local Index = _C.PageSize * wnd.nPage - _C.PageSize
				
				for i = 1, _C.PageSize do
					local Item = data[ Index + i ]
					if Item then
						wnd.Labels[ i ]:SetText( i  .. ". [#" .. Index + i .. " " .. Timer:Convert( Item[ 3 ] ) .. "]: " .. Item[ 2 ] )
						wnd.Labels[ i ]:SizeToContents()
						wnd.Labels[ i ]:SetVisible( true )
					else
						wnd.Labels[ i ]:SetText( "" )
						wnd.Labels[ i ]:SetVisible( false )
					end
				end
				
				Window.PageToggle( wnd, bDirection )
			end
		end
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
			wnd.nSort = varArgs[ 2 ] and tonumber( varArgs[ 2 ] ) or 1
			wnd.bVoted = false
			wnd.bPoints = true
			wnd.nPages = math.ceil( #Cache.M_Data / _C.PageSize )
			wnd.nPage = 1
			
			if varArgs[ 2 ] and tonumber( varArgs[ 2 ] ) then
				wnd.bHold = true
			end
			
			if varArgs[ 3 ] != nil then
				wnd.bPoints = varArgs[ 3 ]
			end
			
			if wnd.nSort == 1 then
				table.sort( Cache.M_Data, function( a, b )
					return a[ 1 ] < b[ 1 ]
				end )
			elseif wnd.nSort == 2 then
				table.sort( Cache.M_Data, function( a, b )
					return a[ 2 ] < b[ 2 ]
				end )
			end
			
			if wnd.bPoints then
				ActiveWindow:SetSize( FormData.Dim[ 1 ] + 80, FormData.Dim[ 2 ] )
			end
			
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			for i = 1, _C.PageSize do
				local Item = Cache.M_Data[ Index + i ]
				local Color = Cache:L_Check( Item and Item[ 1 ] or "" ) and _C.Prefixes.Notification or GUIColor.White
				wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = Color, text = Item and i .. ". " .. (wnd.bPoints and "[" .. Item[ 2 ] .. "] " or "") .. Item[ 1 ] or "" }
				wnd.Offset = wnd.Offset + 20
			end
			
			wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Previous Page" }
			wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Next Page" }
			wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 60, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
			
			wnd.Labels[ 11 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 100, font = Fonts.StrongLabel, color = GUIColor.White, text = "N. Toggle details" }
			wnd.Labels[ 12 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 120, font = Fonts.StrongLabel, color = GUIColor.White, text = "M. Toggle sorting mode" }
			
			if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
			if wnd.nPage == wnd.nPages then wnd.Labels[9]:SetVisible( false ) end
		end
	elseif szIdentifier == "Style" then
		for i = _C.Style.Normal, _C.Style.Practice do
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = i == Timer.Style and _C.Prefixes.Notification or GUIColor.White, text = i .. ". " .. Core:StyleName( i ) }
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Offset = wnd.Offset + 20
		wnd.Labels[ #wnd.Labels + 1 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close" }
	elseif szIdentifier == "Ranks" then
		wnd.nRank = tonumber( varArgs[ 1 ] )
		wnd.nPoints = tonumber( varArgs[ 2 ] )
		wnd.bAngled = varArgs[ 3 ]
		wnd.nType = wnd.bAngled and 4 or 3
		wnd.nScalar = tonumber( varArgs[ 4 ] )
		
		wnd.nPage = math.ceil( wnd.nRank / _C.PageSize )
		wnd.nPages = math.ceil( #_C.Ranks / _C.PageSize )
		wnd.Title = "Ranks - " .. math.floor( wnd.nPoints ) .. " pts"
		
		for n,data in pairs( _C.Ranks ) do
			if n < 0 then continue end
			_C.Ranks[ n ][ wnd.nType ] = math.ceil( Core:Exp( wnd.nScalar, n ) )
		end
		
		for i = 1, _C.PageSize do
			local Index = _C.PageSize * wnd.nPage - _C.PageSize + i
			if _C.Ranks[ Index ] then wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Index == wnd.nRank and "HUDSpecial" or Fonts.StrongLabel, color = _C.Ranks[ Index ][ 2 ], text = Index .. ". " .. _C.Ranks[ Index ][ 1 ] .. " (" .. math.ceil( _C.Ranks[ Index ][ wnd.nType ] ) .. ")" }
			else wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "" } end
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Previous Page" }
		wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Next Page" }
		wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
	
		if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
		if wnd.nPage == wnd.nPages then wnd.Labels[ 9 ]:SetVisible( false ) end
	elseif szIdentifier == "Top" then
		local nType = varArgs[ 1 ]
		if nType == 2 then
			local tData, nPage, nTotal, nType = varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ], varArgs[ 5 ]
			
			Cache.R_Data = {}
			for n,data in pairs( tData ) do
				Cache.R_Data[ n ] = data
			end
			
			local nOffset = _C.PageSize * nPage - _C.PageSize
			wnd.nType = nType
			wnd.Title = (wnd.nType == 3 and "Normal" or "Angled") .. " Top List (" .. nTotal .. " Players)"
			wnd.nPages = math.ceil( nTotal / _C.PageSize )
			wnd.nPage = 1
			wnd.nStart = wnd.nPage
			wnd.vLoaded = { true }

			local data = Cache.R_Data
			if data and #data > 0 then
				for i = 1, _C.PageSize do
					wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = data[ i + nOffset ] and ("#" .. i + nOffset .. ": " .. data[ i + nOffset ][ 1 ] .. " with " .. data[ i + nOffset ][ 2 ] .. " pts") or "" }
					wnd.Offset = wnd.Offset + 16
					wnd.nPage = math.floor( (i + nOffset) / _C.PageSize )
				end
			else
				for i = 1, _C.PageSize do
					wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.MediumLabel, color = GUIColor.White, text = i == 1 and "No available records." or "" }
				end
			end
			
			local d = Window.List.Top.Dim[ 2 ]
			wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (4 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "8. Previous Page" }
			wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (3 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "9. Next Page" }
			wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = d - (2 * 16), font = Fonts.MediumLabel, color = GUIColor.White, text = "0. Close Window" }
			
			if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
			if wnd.nPage == wnd.nPages or nTotal < _C.PageSize + 1 then wnd.Labels[ 9 ]:SetVisible( false ) end
		elseif nType == 4 then
			local tData, nPage, nTotal, nType = varArgs[ 2 ], varArgs[ 3 ], varArgs[ 4 ], varArgs[ 5 ]
			local bDirection = nPage - wnd.nStart < 0
			local nPages = math.ceil( nTotal / _C.PageSize )
			wnd.nPage = nPage
			wnd.nStart = wnd.nPage
			wnd.nType = nType
			
			if wnd.nPages != nPages then
				wnd.nPages = nPages
				wnd.vLoaded = { [wnd.nPage] = true }
				wnd.Title = (wnd.nType == 3 and "Normal" or "Angled") .. " Top List (" .. nTotal .. " Players)"
			else
				wnd.vLoaded[ wnd.nPage ] = true
			end
			
			for n,data in pairs( tData ) do
				Cache.R_Data[ n ] = data
			end
			
			local data = Cache.R_Data
			if data and #data > 0 then
				local Index = _C.PageSize * wnd.nPage - _C.PageSize
				
				for i = 1, _C.PageSize do
					local Item = data[ Index + i ]
					if Item then
						wnd.Labels[ i ]:SetText( "#" .. Index + i .. ": " .. Item[ 1 ] .. " with " .. Item[ 2 ] .. " pts" )
						wnd.Labels[ i ]:SizeToContents()
						wnd.Labels[ i ]:SetVisible( true )
					else
						wnd.Labels[ i ]:SetText( "" )
						wnd.Labels[ i ]:SetVisible( false )
					end
				end
				
				Window.PageToggle( wnd, bDirection )
			end
		end
	elseif szIdentifier == "Maps" then
		local szType = varArgs[ 1 ]
		if varArgs[ 2 ] then
			Cache.L_Data = varArgs[ 2 ]
		end
		
		wnd.tabList = {}
		wnd.tabData = {}
		
		if not Cache.M_Data or (Cache.M_Data and #Cache.M_Data == 0) then
			Window:Close()
			return Link:Print( "General", "You must have opened the !nominate menu at least once to use this command" )
		end
		
		for _,d in pairs( Cache.M_Data ) do
			table.insert( wnd.tabList, d[ 1 ] )
			wnd.tabData[ d[ 1 ] ] = d[ 2 ]
		end
		
		wnd.szType = szType
		
		if szType == "Completed" then
			wnd.tabList = Cache.L_Data
		elseif szType == "Left" then
			for _,d in pairs( Cache.L_Data ) do
				table.RemoveByValue( wnd.tabList, d[ 1 ] )
			end
			
			local TempList = {}
			for _,m in pairs( wnd.tabList ) do
				table.insert( TempList, { Map = m, Points = wnd.tabData[ m ] or 1 } )
			end
			
			table.SortByMember( TempList, "Points" )
			
			wnd.tabList = {}
			for _,d in ipairs( TempList ) do
				table.insert( wnd.tabList, { d.Map, d.Points } )
			end
			
			ActiveWindow:SetSize( FormData.Dim[ 1 ] - 120, FormData.Dim[ 2 ] )
		elseif szType == "WR" then
			wnd.tabList = Cache.L_Data
			szType = "with #1 WR"
		end
		
		wnd.nCount = #wnd.tabList
		wnd.nPage = 1
		wnd.nPages = math.ceil( wnd.nCount / _C.PageSize )
		wnd.Title = "Maps " .. szType .. " (" .. wnd.nCount .. ")"
		
		for i = 1, _C.PageSize do
			local Index = _C.PageSize * wnd.nPage - _C.PageSize + i
			local Item = wnd.tabList[ Index ]
			local Text = ""
			
			if Item then
				if wnd.szType == "Completed" then
					Text = Index .. ". [" .. Timer:Convert( Item[ 2 ] ) .. "] " .. Item[ 1 ] .. " (" .. math.floor( Item[ 3 ] ).. " / " .. (wnd.tabData[ Item[ 1 ] ] and wnd.tabData[ Item[ 1 ] ] or "?") .. " pts)"
				elseif wnd.szType == "Left" then
					Text = Index .. ". " .. Item[ 1 ] .. " (" .. Item[ 2 ] .. " pts)"
				elseif wnd.szType == "WR" then
					Text = Index .. ". [" .. Timer:Convert( Item[ 2 ] ) .. "] " .. Item[ 1 ] .. " (Style: " .. Core:StyleName( Item[ 3 ] ) .. ")"
				end
			end
			
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = Text }
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Previous Page" }
		wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Next Page" }
		wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
	
		if wnd.nPage == 1 then wnd.Labels[ 8 ]:SetVisible( false ) end
		if wnd.nPage >= wnd.nPages then wnd.Labels[ 9 ]:SetVisible( false ) end
	elseif szIdentifier == "Checkpoints" then
		wnd.bDelay = false
		wnd.bDelete = false
		
		wnd.Labels[ 1 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "1. Most recent" }
		wnd.Offset = wnd.Offset + 20
		
		for i = 2, _C.PageSize do
			local Item = Cache.C_Data[ i ]
			wnd.Labels[ i ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = Item and i .. ". " .. Item or i .. ". None" }
			wnd.Offset = wnd.Offset + 20
		end
		
		wnd.Labels[ 8 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = "8. Turn Delay " .. (wnd.bDelay and "Off" or "On") }
		wnd.Labels[ 9 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 20, font = Fonts.StrongLabel, color = GUIColor.White, text = "9. Turn Delete " .. (wnd.bDelete and "Off" or "On") }
		wnd.Labels[ 10 ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset + 40, font = Fonts.StrongLabel, color = GUIColor.White, text = "0. Close Window" }
	elseif szIdentifier == "Stats" then
		wnd.Title = varArgs.Title .. " Stats"
		
		local tabRender = {
			"Distance: " .. varArgs.Distance .. " units",
			"Prestrafe: " .. varArgs.Prestrafe .. " u/s",
			"Average Sync: " .. varArgs.Sync .. "%",
			"Strafes: " .. #varArgs.SyncValues
		}
		
		for id,data in pairs( tabRender ) do
			wnd.Labels[ id ] = Window.MakeLabel{ parent = ActiveWindow, x = 15, y = wnd.Offset, font = Fonts.StrongLabel, color = GUIColor.White, text = data }
			wnd.Offset = wnd.Offset + 20
		end
		
		if timer.Exists( "StatsCloser" ) then timer.Destroy( "StatsCloser" ) end
		timer.Create( "StatsCloser", 3, 1, function() Window:Close() end )
	elseif szIdentifier == "Spectate" then
		wnd.Title = (LocalPlayer() and LocalPlayer():Team() == TEAM_SPECTATOR) and "Stop?" or "Spectate?"
		ActiveWindow:Center()
		ActiveWindow:MakePopup()
		
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 33, y = 38, text = "Yes", onclick = function() Window:Close() RunConsoleCommand( "spectate" ) end }
		Window.MakeButton{ parent = ActiveWindow, w = 32, h = 24, x = 75, y = 38, text = "No", onclick = function() Window:Close() end }
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
	elseif ID == "WR" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local Index = _C.PageSize * wnd.nPage - _C.PageSize + Key
			local Item = Cache.T_Data[ wnd.nStyle ][ Index ]
			if Item then
				if Admin.EditType and Admin.EditType == 17 and not wnd.szMap then
					Admin:ReqAction( Admin.EditType, { wnd.nStyle, Index, Item[ 1 ], Item[ 2 ] } )
				else
					local Speed, szMap = Vector( 0, 0, 0 ), wnd.szMap or game.GetMap()
					if Item[ 5 ] then Speed = Core.Util:StringToTab( Item[ 5 ] ) end
					Link:Print( "Bhop Timer", "The #" .. Index .. " record on " .. szMap .. " (Time: " .. Timer:Convert( Item[ 3 ] or 0 ) .. ") was obtained by " .. (Item[ 2 ] or "Unknown Player") .. (Item[ 4 ] and " at " .. Item[ 4 ] or "") .. " on the " .. Core:StyleName( wnd.nStyle ) .. " style" .. (Speed[ 1 ] + Speed[ 2 ] > 0 and ". Their top velocity was " .. math.floor( Speed[ 1 ] ) .. " and had an average velocity of " .. math.floor( Speed[ 2 ] ) .. " and " .. (Speed[ 3 ] and math.ceil( Speed[ 3 ] ) or "?") .. " total jumps." .. ((Speed[ 4 ] and Speed[ 4 ] > 0) and " Captured sync was: " .. Speed[ 4 ] .. "%" or "") or ".") )
				end
			end
		elseif not KeyLimit and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage != wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			
			if not wnd.vLoaded[ wnd.nPage ] then
				Link:Send( "WRList", { wnd.nPage, wnd.nStyle, wnd.szMap } )
			else
				local Index = _C.PageSize * wnd.nPage - _C.PageSize
				
				for i = 1, _C.PageSize do
					local Item = Cache.T_Data[ wnd.nStyle ][ Index + i ]
					if Item then
						wnd.Labels[ i ]:SetText( i  .. ". [#" .. Index + i .. " " .. Timer:Convert( Item[ 3 ] ) .. "]: " .. Item[ 2 ] )
						wnd.Labels[ i ]:SizeToContents()
						wnd.Labels[ i ]:SetVisible( true )
					else
						wnd.Labels[ i ]:SetText( "" )
						wnd.Labels[ i ]:SetVisible( false )
					end
				end
				
				Window.PageToggle( wnd, bPrev )
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
					
					local Color = Cache:L_Check( Item and Item[ 1 ] or "" ) and _C.Prefixes.Notification or GUIColor.White
					wnd.Labels[ i ]:SetText( i .. ". " .. (wnd.bPoints and "[" .. Item[ 2 ] .. "] " or "") .. Item[ 1 ] )
					wnd.Labels[ i ]:SetColor( Color )
					wnd.Labels[ i ]:SizeToContents()
					wnd.Labels[ i ]:SetVisible( true )
				else
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SetColor( GUIColor.White )
					wnd.Labels[ i ]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, bPrev )
		elseif input.IsKeyDown( KEY_N ) and not KeyLimit and not wnd.bVoted then
			if wnd.bHold then return end
			wnd.bHold = true
			wnd.bPoints = not wnd.bPoints
			
			local dim = Window.List[ ID ].Dim
			if wnd.bPoints then
				ActiveWindow:SetSize( dim[ 1 ] + 80, dim[ 2 ] )
			else
				ActiveWindow:SetSize( dim[ 1 ], dim[ 2 ] )
			end
			
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			for i = 1, _C.PageSize do
				if Cache.M_Data[ Index + i ] then
					local Item = Cache.M_Data[ Index + i ]
					wnd.Labels[ i ]:SetText( i .. ". " .. (wnd.bPoints and "[" .. Item[ 2 ] .. "] " or "") .. Item[ 1 ] )
					wnd.Labels[ i ]:SizeToContents()
					wnd.Labels[ i ]:SetVisible( true )
				else
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SetVisible( false )
				end
			end
			
			Key = 20
		elseif input.IsKeyDown( KEY_M ) and not KeyLimit and not wnd.bVoted then
			if wnd.bHold then return end
			wnd.bHold = true
			
			local tabSort = { "their name.", "their multiplier." }
			wnd.nSort = wnd.nSort + 1
			if wnd.nSort > 2 then wnd.nSort = 1 end
			Window:Open( "Nominate", { wnd.nServer, wnd.nSort, wnd.bPoints } )
			
			Link:Print( "General", "Maps are now sorted by " .. tabSort[ wnd.nSort ] or "an undefined parameter." )
			Key = 20
		elseif not KeyLimit then
			wnd.bHold = nil
		end
	elseif ID == "Style" then
		if Key > 0 and Key <= _C.Style.Practice and not KeyLimit and not wnd.Selected then
			wnd.Selected = true
			wnd.Labels[ Timer.Style ]:SetColor( GUIColor.White )
			wnd.Labels[ Key ]:SetColor( _C.Prefixes.Notification )
			RunConsoleCommand( "style", tostring( Key ) )
			Key = 0
		end
	elseif ID == "Ranks" then
		if not KeyLimit and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage != wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			
			for i = 1, _C.PageSize do
				local Item = _C.Ranks[ Index + i ]
				if Item then
					wnd.Labels[ i ]:SetText( Index + i .. ". " .. Item[ 1 ] .. " (" .. math.ceil( Item[ wnd.nType ] ) .. ")" )
					wnd.Labels[ i ]:SetColor( Item[ 2 ] )
					wnd.Labels[ i ]:SetFont( Index + i == wnd.nRank and "HUDSpecial" or Fonts.StrongLabel )
					wnd.Labels[ i ]:SizeToContents()
					wnd.Labels[ i ]:SetVisible( true )
				else
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, bPrev )
		end
	elseif ID == "Top" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local Index = _C.PageSize * wnd.nPage - _C.PageSize + Key
			local Item = Cache.R_Data[ Index ]
			if Item then
				local r = 1 for i,d in pairs( _C.Ranks ) do if i > r and Item[ 2 ] >= d[ wnd.nType ] then r = i end end
				local Rank = _C.Ranks[ r ]
				Link:Print( "Bhop Timer", { GUIColor.White, Item[ 1 ] .. " is currently ranked #" .. Index .. " with " .. Item[ 2 ] .. " points, which set him to the rank of ", Rank and Rank[ 2 ] or GUIColor.White, Rank and Rank[ 1 ] or "Unknown" } )
			end
		elseif not KeyLimit and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage != wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			
			if not wnd.vLoaded[ wnd.nPage ] then
				Link:Send( "TopList", { wnd.nPage, wnd.nType } )
			else
				local Index = _C.PageSize * wnd.nPage - _C.PageSize
				
				for i = 1, _C.PageSize do
					local Item = Cache.R_Data[ Index + i ]
					if Item then
						wnd.Labels[ i ]:SetText( "#" .. Index + i .. ": " .. Item[ 1 ] .. " with " .. Item[ 2 ] .. " pts" )
						wnd.Labels[ i ]:SizeToContents()
						wnd.Labels[ i ]:SetVisible( true )
					else
						wnd.Labels[ i ]:SetText( "" )
						wnd.Labels[ i ]:SetVisible( false )
					end
				end
				
				Window.PageToggle( wnd, bPrev )
			end
		end
	elseif ID == "Maps" then
		if Key > 0 and Key < 8 and not KeyLimit then
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			local Item = wnd.tabList[ Index + Key ]
			if wnd.szType == "WR" and Item and Item[ 4 ] then
				local Sub = Item[ 4 ]
				local Speed = Vector( 0, 0, 0 )
				if Sub[ 2 ] then Speed = Core.Util:StringToTab( Sub[ 2 ] ) end
				Link:Print( "Bhop Timer", "You obtained the #1 record on " .. Item[ 1 ] .. " (Time: " .. Timer:Convert( Item[ 2 ] or 0 ) .. (Sub[ 3 ] and " - Points: " .. Sub[ 3 ] or "") .. ")" .. (Sub[ 1 ] and " at " .. Sub[ 1 ] or "") .. " with the nickname " .. (Sub[ 4 ] or "Unknown Player") .. " on the " .. Core:StyleName( Item[ 3 ] ) .. " style" .. (Speed[ 1 ] + Speed[ 2 ] > 0 and ". Your top velocity was " .. math.floor( Speed[ 1 ] ) .. " and you had an average velocity of " .. math.floor( Speed[ 2 ] ) .. " and " .. (Speed[ 3 ] and math.ceil( Speed[ 3 ] ) or "?") .. " total jumps." .. ((Speed[ 4 ] and Speed[ 4 ] > 0) and " Captured sync was: " .. Speed[ 4 ] .. "%" or "") or ".") )
			elseif Item and Item[ 1 ] then
				RunConsoleCommand( "nominate", Item[ 1 ] )
			end
		elseif not KeyLimit and ((Key == 8 and wnd.nPage != 1) or (Key == 9 and wnd.nPage < wnd.nPages)) then
			local bPrev = Key == 8 and true or false
			wnd.nPage = wnd.nPage + (bPrev and -1 or 1)
			local Index = _C.PageSize * wnd.nPage - _C.PageSize
			
			for i = 1, _C.PageSize do
				local Item = wnd.tabList[ Index + i ]
				if Item then
					local Text = ""
					if wnd.szType == "Completed" then
						Text = Index + i .. ". [" .. Timer:Convert( Item[ 2 ] ) .. "] " .. Item[ 1 ] .. " (" .. math.floor( Item[ 3 ] ).. " / " .. (wnd.tabData[ Item[ 1 ] ] and wnd.tabData[ Item[ 1 ] ] or "?") .. " pts)"
					elseif wnd.szType == "Left" then
						Text = Index + i .. ". " .. Item[ 1 ] .. " (" .. Item[ 2 ] .. " pts)"
					elseif wnd.szType == "WR" then
						Text = Index + i .. ". [" .. Timer:Convert( Item[ 2 ] ) .. "] " .. Item[ 1 ] .. " (Style: " .. Core:StyleName( Item[ 3 ] ) .. ")"
					end
					
					wnd.Labels[ i ]:SetText( Text )
					wnd.Labels[ i ]:SizeToContents()
					wnd.Labels[ i ]:SetVisible( true )
				else
					wnd.Labels[ i ]:SetText( "" )
					wnd.Labels[ i ]:SetVisible( false )
				end
			end
			
			Window.PageToggle( wnd, bPrev )
		end
	elseif ID == "Checkpoints" then
		if Key > 0 and Key < 8 and not KeyLimit then
			Link:Send( "Checkpoints", { Key, wnd.bDelay, wnd.bDelete } )
		elseif not KeyLimit and Key == 8 then
			wnd.bDelay = not wnd.bDelay
			wnd.Labels[ 8 ]:SetText( "8. Turn Delay " .. (wnd.bDelay and "Off" or "On") )
			wnd.Labels[ 8 ]:SizeToContents()
		elseif not KeyLimit and Key == 9 then
			wnd.bDelete = not wnd.bDelete
			wnd.Labels[ 9 ]:SetText( "9. Turn Delete " .. (wnd.bDelete and "Off" or "On") )
			wnd.Labels[ 9 ]:SizeToContents()
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