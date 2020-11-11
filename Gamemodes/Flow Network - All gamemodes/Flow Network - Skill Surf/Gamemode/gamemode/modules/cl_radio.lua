Radio = {}
Radio.File = _C.Identifier .. "-radio-mapchange.txt"

local rWnd
local fPlay = sound.PlayURL

local InBlock, UpdateOnce = true, false
local Channel, ChannelBase
local CurrentSong, CurrentID
local Progress, PositionSlide, PositionBtn, PositionSet
local SelectedLine, RadioData
local SearchCache, SearchID, SearchBtn
local DataColumns = {}
local RadioCache = {}

local RadioVolume = CreateClientConVar( "sl_radio_volume", "50", true, false )
local RadioLastID = CreateClientConVar( "sl_radio_lastid", "0", true, false )
local RadioLastTime = CreateClientConVar( "sl_radio_lasttime", "0", true, false )

local function fTime( nTime )
	if nTime < 3600 then
		return string.ToMinutesSeconds( nTime )
	else
		local nHours = 0		
		for i = 1, 10 do
			nTime = nTime - 3600
			nHours = nHours + 1
			if nTime < 3600 then break end
		end
		return (nHours < 10 and "0" or "") .. nHours .. ":" .. string.ToMinutesSeconds( nTime )
	end
end

local function DoStopSong()
	if IsValid( Channel ) then
		Channel:SetVolume( 0 )
		Channel:Stop()
		Channel = nil
	end
end

local function PlayCallback( channel )
	if not IsValid( channel ) then return end
	Channel = channel
	Channel:Play()
	Channel:SetVolume( RadioVolume:GetInt() / 100 )
	
	if IsValid( PositionSlide ) then
		PositionSlide:SetVisible( not InBlock )
		PositionSlide:SetMin( 0 )
		PositionSlide:SetMax( Channel:GetLength() )
		PositionSlide:SetValue( 0 )
	end
	
	if CurrentSong then
		Link:Print( "Radio", "Now playing " .. CurrentSong[ 4 ] .. ((CurrentSong[ 5 ] and CurrentSong[ 5 ] != "") and " by " .. CurrentSong[ 5 ] or "") .. "!" )
		
		if PositionSet then
			timer.Create( "PositionSetter", 0.1, 0, function()
				if IsValid( Channel ) and PositionSet then
					if Channel:GetTime() > 1 then
						Channel:SetTime( PositionSet )
						PositionSet = nil
						timer.Destroy( "PositionSetter" )
					end
				else
					timer.Destroy( "PositionSetter" )
				end
			end )
		end
		
		local nLength = tonumber( CurrentSong[ 3 ] )
		if nLength and nLength == 0 then
			local nReal = math.ceil( Channel:GetLength() )
			if nReal < 1 then nReal = 1 end
			Link:Send( "Radio", { "Length", { CurrentSong[ 1 ], CurrentSong[ 2 ], nReal } } )
		end
	end
end

local function DoPlaySong( data, id )
	if not ChannelBase then return end
	UpdateOnce = false
	CurrentSong = data
	CurrentID = id
	DoStopSong()
	local szTarget = ChannelBase .. data[ 1 ] .. "_" .. data[ 2 ] .. ".mp3"
	fPlay( szTarget, not InBlock and "noblock" or "", PlayCallback )
end

local function SetVolume( self, nVolume )
	if IsValid( Channel ) then
		Channel:SetVolume( nVolume / 100 )
		
		if not timer.Exists( "VolumeSave" ) then
			timer.Create( "VolumeSave", 1, 0, function()
				local vol = IsValid( Channel ) and Channel:GetVolume() * 100 or 50
				RunConsoleCommand( "sl_radio_volume", vol )
				timer.Destroy( "VolumeSave" )
			end )
		end
	end
end

local PosLastSet = CurTime()
local function SetPos( self, nPos )
	if InBlock then return end
	if not self:IsEditing() then return false end
	if IsValid( Channel ) then
		if CurTime() - PosLastSet > 0.33 then
			Channel:SetTime( nPos )
			PosLastSet = CurTime()
		end
	end
end

local function SearchList( szTerm )
	if szTerm == "Search Query" or szTerm == "" or szTerm == " " then
		return Link:Print( "Radio", "Please enter a valid search query" )
	end
	
	Link:Send( "Radio", { "Search", szTerm } )
end

local function ContainsItem( szID )
	for i,d in pairs( RadioCache ) do
		if d[ 2 ] == szID then
			return d,i
		end
	end
	return false
end

local function GetNextSong()
	if CurrentID then
		local Next = RadioCache[ CurrentID + 1 ]
		if Next then
			return { CurrentID + 1, Next }
		else
			local GetNext = false
			for id,data in pairs( RadioCache ) do
				if GetNext then
					return { id, data }
				else
					if id == CurrentID then
						GetNext = true
					end
				end
			end
			for id,data in pairs( RadioCache ) do
				return { id, data }
			end
		end
	end
end

local ColumnTypes = {
	{ { "Title", 250 }, { "Length", 35 }, { "ID", 35 } },
	{ { "Title", 175 }, { "Channel", 75 }, { "Published", 70 } },
	{ { "Title", 140 }, { "Artist", 75 }, { "Album", 90 } }
}

local function SetColumns( nType )
	for i,col in pairs( DataColumns ) do
		local d = ColumnTypes[ nType ][ i ]
		col:SetName( d[ 1 ] )
		col:SetWidth( d[ 2 ] )
	end
end

local function RestoreList()
	if IsValid( RadioData ) then
		RadioData:Clear()
		SetColumns( 1 )
		
		if #RadioCache > 0 then
			for i,d in pairs( RadioCache ) do
				RadioData:AddLine( d[ 4 ] .. ((d[ 5 ] and d[ 5 ] != "") and " (By " .. d[ 5 ] .. ")" or ""), d[ 3 ] and fTime( d[ 3 ] ) or "?", i )
			end
		else
			RadioData:AddLine( "Find songs by searching!", "", "" )
		end
		
		Link:Print( "Radio", "Your list has been restored!" )
	end
	
	if IsValid( SearchBtn ) then
		SearchBtn:SetAlpha( 180 )
	end
end

local function GetSearchSong( line )
	local set
	local title, artist, detail = line:GetValue(1), line:GetValue(2), line:GetValue(3)
	for id,data in pairs( SearchCache ) do
		if data[ 2 ] == title and data[ 3 ] == artist and data[ 4 ] == detail then
			set = id
		end
	end
	
	RestoreList()
	
	if set then
		Link:Send( "Radio", { "Add", SearchID[ 1 ], SearchID[ 3 ] .. set, SearchCache[ set ] } )
	else
		Link:Print( "Radio", "Couldn't retrieve song id. Please try again." )
	end
	
	SearchCache = nil
end

local function SaveCurrentList( szPath )
	local data = util.Compress( util.TableToJSON( RadioCache ) )
	if not data then return end
	file.Write( szPath, data )
end

local function LoadSavedList( szPath, bClosed )
	if file.Exists( szPath, "DATA" ) then
		local data = file.Read( szPath, "DATA" )
		if not data or data == "" then return end
		local remain = util.Decompress( data )
		if not remain then return end
		
		local tab = util.JSONToTable( remain ) or {}
		if #tab > 0 then
			RadioCache = tab
			
			if not IsValid( RadioData ) then
				return bClosed
			end
			
			if #RadioData:GetLines() > 0 then
				RadioData:Clear()
			end
			
			for i,d in pairs( RadioCache ) do
				RadioData:AddLine( d[ 4 ] .. ((d[ 5 ] and d[ 5 ] != "") and " (By " .. d[ 5 ] .. ")" or ""), d[ 3 ] and fTime( d[ 3 ] ) or "?", i )
			end
			
			return true
		else
			return false
		end
	end
	
	return false
end

local function RadioExecute( btn, data )
	local nID = btn.SetID and tonumber( btn.SetID ) or -1
	if nID == 2 then
		if IsValid( SearchBtn ) and SearchBtn:GetAlpha() == 255 then
			RestoreList()
		end
	elseif nID == 3 then
		if IsValid( RadioData ) then
			RadioData:ClearSelection()
			if SelectedLine then
				RadioData:RemoveLine( SelectedLine )
			end
		end
		if Radio.SelectedItem then
			if RadioCache[ Radio.SelectedItem ] then
				Link:Print( "Radio", "Removed " .. RadioCache[ Radio.SelectedItem ][ 4 ] .. " from your list (ID " .. Radio.SelectedItem .. ")" )
				RadioCache[ Radio.SelectedItem ] = nil
			end
		end
	elseif nID == 4 then
		SaveCurrentList( Cache.R_Name )
		Link:Print( "Radio", "Your playlist has been saved!" )
	elseif nID == 5 then
		if LoadSavedList( Cache.R_Name ) then
			Link:Print( "Radio", "Your playlist of " .. #RadioCache .. " songs has been loaded!" )
		else
			Link:Print( "Radio", "Your saved playlist was empty" )
		end
	elseif nID == 6 then
		if not IsValid( Channel ) then return Link:Print( "Radio", "No song playing to pause" ) end
		Channel:Pause()
	elseif nID == 7 then
		if not IsValid( Channel ) then return Link:Print( "Radio", "No song paused to resume" ) end
		Channel:Play()
	elseif nID == 8 then
		SearchList( Radio.SearchBox:GetValue() )
	elseif nID == 9 then
		if Radio.SelectedItem then
			local Cached = RadioCache[ Radio.SelectedItem ]
			if Cached then
				DoPlaySong( Cached, Radio.SelectedItem )
			end
		else
			Link:Print( "Radio", "Please select a valid song to play" )
		end
	elseif nID == 10 then
		DoStopSong()
	elseif nID == 11 then
		Window.MakeQuery( "From what service do you want to add a song?", "Add a song",
			"YouTube URL", function() RadioExecute( { SetID = 111 } ) end,
			"Search YouTube", function() RadioExecute( { SetID = 112 } ) end,
			"Search Grooveshark", function() RadioExecute( { SetID = 113 } ) end,
			"Cancel", function() end
		)
	elseif nID == 111 then
		if not data then
			Window.MakeRequest( "Enter YouTube URL of your song", "Add a song (YouTube URL)", "https://www.youtube.com/", function(r) RadioExecute( { SetID = 111 }, r ) end, function() end )
		else
			Link:Send( "Radio", { "Add", 1, data } )
		end
	elseif nID == 112 then
		if not data then
			Window.MakeRequest( "Enter search query for YouTube", "Search for a song (YouTube)", "Search Query: Video title", function(r) RadioExecute( { SetID = 112 }, r ) end, function() end )
		else
			Link:Send( "Radio", { "Add", 102, data } )
		end
	elseif nID == 113 then
		if not data then
			Window.MakeRequest( "Enter Grooveshark name of your song", "Add a song", "Search Query: Band - Title", function(r) RadioExecute( { SetID = 113 }, r ) end, function() end )
		else
			Link:Send( "Radio", { "Add", 103, data } )
		end
	elseif nID == 12 then
		if IsValid( RadioData ) then
			RadioData:ClearSelection()
		end
		if Radio.SelectedItem then Radio.SelectedItem = nil end
	elseif nID == 13 then
		InBlock = not InBlock
		if IsValid( PositionBtn ) then
			PositionBtn:SetText( (InBlock and "Enable" or "Disable") .. " position changing" )
		end
		Link:Print( "Radio", "Upon starting the next song, position changing will" .. (InBlock and " not" or "") .. " be possible" )
	elseif nID == 14 then
		Link:Send( "Radio", { "Search", "all" } )
	elseif nID == 15 then
		if IsValid( RadioData ) then
			if #RadioData:GetLines() > 0 then
				RadioData:Clear()
			end
		end
		
		RadioCache = {}
		Link:Print( "Radio", "Your current list has been cleared" )
	end
end

local function UpdateProgress()
	local nTime, nLength = 0, 0
	if IsValid( Channel ) then
		nTime = Channel:GetTime()
		nLength = Channel:GetLength()
		
		if Channel:GetState() == 0 and nTime > 1 and nLength > 1 and not UpdateOnce then
			local n = GetNextSong()
			if n then UpdateOnce = true DoPlaySong( n[ 2 ], n[ 1 ] ) end
		end
	end
	
	if IsValid( Progress ) then		
		local szText = "Time: " .. fTime( nTime ) .. " / " .. fTime( nLength )
		Progress:SetText( szText )
		Progress:SizeToContents()
	end
end

function Radio:CreateWindow( hWnd, varArgs )
	if not IsValid( hWnd ) then return true end
	
	hWnd:Center()
	hWnd:MakePopup()
	
	Window.MakeButton{ parent = hWnd, w = 16, h = 16, x = hWnd:GetWide() - 25, y = 8, text = "X", onclick = function() Window:Close() end }
	
	local sx, sy = 20, 39
	local list = vgui.Create( "DListView", hWnd )
	list:SetPos( sx, sy )
	list:SetSize( 380, 380 )
	list:SetMultiSelect( false )
	list:SetHeaderHeight( 20 )
	DataColumns = { list:AddColumn( "Title" ), list:AddColumn( "Length" ), list:AddColumn( "ID" ) }
	SetColumns( 1 )
	list.OnRowSelected = function( parent, index, line ) if SearchCache then return end Radio.SelectedItem = parent:GetLine( index ):GetValue(3) SelectedLine = index end
	list.DoDoubleClick = function( parent, index, line ) if SearchCache then return GetSearchSong( line ) end Radio.SelectedItem = line:GetValue(3) SelectedLine = index RadioExecute( { SetID = 9 } ) end
	RadioData = list
	
	if #RadioCache == 0 then
		list:AddLine( "Find songs by searching!", "", "" )
	else
		for i,d in pairs( RadioCache ) do
			list:AddLine( d[ 4 ] .. ((d[ 5 ] and d[ 5 ] != "") and " (By " .. d[ 5 ] .. ")" or ""), d[ 3 ] and fTime( d[ 3 ] ) or "?", i )
		end
	end
	
	hWnd.OnMousePressed = function()
		RadioData:ClearSelection()
		Radio.SelectedItem = nil
	end
	
	sy = sy + 390
	Window.MakeButton{ parent = hWnd, w = 60, h = 22, x = sx + 380 - 60, y = sy, text = "Search", id = 8, onclick = RadioExecute }
	Radio.SearchBox = Window.MakeTextBox{ parent = hWnd, w = 310, h = 22, x = sx, y = sy, text = "Search Query" }
	Radio.SearchBox.OnEnter = function() SearchList( Radio.SearchBox:GetValue() ) end
	
	sx, sy = hWnd:GetWide() - 190, 39
	Window.MakeLabel{ parent = hWnd, x = sx, y = sy, font = "HUDFontSmall", color = GUIColor.White, text = "Controls" }
	
	sy = sy + 30
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "Start playing", id = 9, onclick = RadioExecute }
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Stop playback", id = 10, onclick = RadioExecute }
	sy = sy + 35
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "Pause", id = 6, onclick = RadioExecute }
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Resume", id = 7, onclick = RadioExecute }
	sy = sy + 35
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "Add song", id = 11, onclick = RadioExecute }
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Deselect item", id = 12, onclick = RadioExecute }
	sy = sy + 35
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "Save playlist", id = 4, onclick = RadioExecute }
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Load playlist", id = 5, onclick = RadioExecute }
	sy = sy + 35
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "Remove item", id = 3, onclick = RadioExecute }
	SearchBtn = Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Cancel search", id = 2, onclick = RadioExecute }
	SearchBtn:SetAlpha( 180 )
	sy = sy + 35
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx, y = sy, text = "View full list", id = 14, onclick = RadioExecute }
	Window.MakeButton{ parent = hWnd, w = 80, h = 25, x = sx + 90, y = sy, text = "Clear list", id = 15, onclick = RadioExecute }
	
	sy = 59 + 300
	local pos = vgui.Create( "DNumSlider", hWnd )
	pos:SetPos( sx, sy )
	pos:SetWide( 170 )
	pos:SetText( "Position" )
	pos:SetMin( 0 )
	pos:SetMax( 1 )
	pos:SetDecimals( 0 )
	pos:SetValue( 0 )
	pos:SetVisible( not InBlock )
	pos.ValueChanged = SetPos
	PositionSlide = pos
	
	PositionBtn = Window.MakeButton{ parent = hWnd, w = 170, h = 22, x = sx, y = sy + 35, text = "Enable position changing", id = 13, onclick = RadioExecute }
	Progress = Window.MakeLabel{ parent = hWnd, x = sx, y = sy - 6, font = "HUDLabelSmall", color = GUIColor.White, text = "Time: 00:00 / 00:00" }
	
	sy = sy + 60
	local vol = vgui.Create( "DNumSlider", hWnd )
	vol:SetPos( sx, sy )
	vol:SetWide( 170 )
	vol:SetText( "Volume" )
	vol:SetMin( 0 )
	vol:SetMax( 100 )
	vol:SetDecimals( 0 )
	vol:SetValue( RadioVolume:GetInt() )
	vol.ValueChanged = SetVolume
	
	if not timer.Exists( "ProgressBarUpdater" ) then
		timer.Create( "ProgressBarUpdater", 0.33, 0, UpdateProgress )
	end
	
	rWnd = hWnd
	if not ChannelBase then ChannelBase = varArgs end
end

function Radio:Receive( varArgs )
	local szType = tostring( varArgs[ 1 ] )
	
	if szType == "Open" then
		Window:Open( "Radio", varArgs[ 2 ] )
	elseif szType == "Initialize" then
		if not ChannelBase then ChannelBase = varArgs[ 2 ] end
		Radio:ResumeStart()
	elseif szType == "Single" then
		if varArgs[ 3 ] then DoStopSong() return fPlay( varArgs[ 3 ], "", function( channel ) if not IsValid( channel ) then return end channel:Play() channel:SetVolume( 0.5 ) if varArgs[ 4 ] then Admin:Receive( { "Message", varArgs[ 4 ] } ) end end ) end
		local has,ix = ContainsItem( varArgs[ 2 ][ 2 ] )
		local id = -1
		if not ix then
			id = table.insert( RadioCache, varArgs[ 2 ] )
			if IsValid( RadioData ) then
				RadioData:AddLine( varArgs[ 4 ] .. ((varArgs[ 5 ] and varArgs[ 5 ] != "") and " (By " .. varArgs[ 5 ] .. ")" or ""), varArgs[ 3 ] and fTime( varArgs[ 3 ] ) or "?", id )
			end
		else
			id = ix
		end
		
		if id > -1 then
			Radio.SelectedItem = id
			RadioExecute( { SetID = 9 } )
			Radio.SelectedItem = nil
		end
	elseif szType == "Result" then
		if not varArgs[ 2 ] or not type( varArgs[ 2 ] ) == "table" then
			return Link:Print( "Radio", "Something went wrong while obtaining your data" )
		end
		
		local bClear = false
		if not IsValid( rWnd ) then
			Window:Open( "Radio" )
			bClear = true
		end
		
		if varArgs[ 3 ] then
			timer.Simple( 1, function() Link:Print( "Radio", "Your newly downloaded song has been added to your radio" ) end )
		else
			Link:Print( "Radio", "Found " .. #varArgs[ 2 ] .. " results for your query" )
		end
		
		if IsValid( RadioData ) then
			if (#RadioData:GetLines() > 0 and bClear) or #RadioCache == 0 then
				RadioData:Clear()
			end
			
			if bClear and #RadioCache > 0 then
				for i,d in pairs( RadioCache ) do
					RadioData:AddLine( d[ 4 ] .. ((d[ 5 ] and d[ 5 ] != "") and " (By " .. d[ 5 ] .. ")" or ""), d[ 3 ] and fTime( d[ 3 ] ) or "?", i )
				end
			end
			
			local n = 0
			for i,data in pairs( varArgs[ 2 ] ) do
				if not ContainsItem( data[ 2 ] ) then
					local id = table.insert( RadioCache, data )
					RadioData:AddLine( data[ 4 ] .. ((data[ 5 ] and data[ 5 ] != "") and " (By " .. data[ 5 ] .. ")" or ""), data[ 3 ] and fTime( data[ 3 ] ) or "?", id )
					n = n + 1
				end
			end
			
			if n == 0 then
				Link:Print( "Radio", "No new results were added to your list as it already contained them" )
			end
		end
	elseif szType == "Search" then
		if IsValid( RadioData ) then
			local data = varArgs[ 2 ]
			if data.items and #data.items > 0 then
				SearchID = varArgs[ 3 ]
				RadioData:Clear()
				SetColumns( SearchID[ 2 ] )
				SearchCache = {}
				if IsValid( SearchBtn ) then
					SearchBtn:SetAlpha( 255 )
				end
				
				for i,d in pairs( data.items ) do
					SearchCache[ d[ 1 ] ] = d
					RadioData:AddLine( d[ 2 ], d[ 3 ], d[ 4 ] )
				end
				
				Link:Print( "Radio", "Now displaying " .. data.display .. " out of " .. data.total .. " results in your radio list." )
				Link:Print( "Radio", "Double click a song in your list to start downloading it. Your old list will then be restored." )
			else
				Link:Print( "Radio", "No results found to display" )
			end
		else
			Link:Print( "Radio", "Couldn't display found items in your radio" )
		end
	elseif szType == "Save" then
		if RadioCache and #RadioCache > 0 then
			SaveCurrentList( Radio.File )
		end
		
		if CurrentSong and CurrentID and IsValid( Channel ) then
			RunConsoleCommand( "sl_radio_lastid", tostring( CurrentID ) )
			RunConsoleCommand( "sl_radio_lasttime", tostring( math.floor( Channel:GetTime() ) ) )
		end
	end
end

function Radio:Resume()
	if LoadSavedList( Radio.File, true ) then
		Link:Send( "Radio", { "Initialize" } )
	end
end

function Radio:ResumeStart()
	local id = RadioLastID:GetInt()
	if id > 0 then
		local t = RadioLastTime:GetInt()
		if t < 0 then t = 0 end
		if t > 0 then
			InBlock = false
			PositionSet = t
		end
		
		local Cached = RadioCache[ id ]
		if Cached then
			DoPlaySong( Cached, id )
		end
		
		InBlock = true
		
		RunConsoleCommand( "sl_radio_lastid", tostring( 0 ) )
		RunConsoleCommand( "sl_radio_lasttime", tostring( 0 ) )
	end
end