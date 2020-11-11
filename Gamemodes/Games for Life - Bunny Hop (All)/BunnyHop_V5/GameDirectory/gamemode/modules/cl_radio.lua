Radio = {}
Radio.Protocol = "Radio"

local RadioCache = {}
local RadioBase = "" -- Not here, idiot.
Radio.SelectedItem = nil
Radio.DataTable = nil
Radio.SearchBox = nil
Radio.ProgressLabel = nil
Radio.PageLabel = nil
Radio.Page = 1
Radio.Pages = 1
Radio.SetVolume = 50

function Radio.Receive()
	local szIdentifier = net.ReadString()
	local bArgs = net.ReadBit() == 1
	local varArgs = bArgs and net.ReadTable() or {}
	
	if not szIdentifier then return end
	Radio:Analyze( szIdentifier, varArgs )
end
net.Receive( Radio.Protocol, Radio.Receive )

function Radio:Analyze( szIdentifier, varArgs )
	if szIdentifier == "Open" then
		if not varArgs or not varArgs[1] then return end
		RadioBase = varArgs[1]
		
		if Radio.DataTable then
			if #Radio.DataTable:GetLines() > 0 then
				Radio.DataTable:Clear()
			end
			
			if varArgs[2] then
				RadioCache = varArgs[2]
				for id, data in pairs( RadioCache ) do
					Radio.DataTable:AddLine( data.Title, Timer:SimpleTime( data.Duration ), id )
				end
			else
				Radio.DataTable:AddLine( "No songs found", "", "" )
			end
			
			if varArgs[3] and tonumber( varArgs[3] ) then
				Radio:SetPage( nil, tonumber( varArgs[3] ) )
			end
		end
	elseif szIdentifier == "Update" then
		if not varArgs or not varArgs[1] or not varArgs[2] then return end

		if Radio.DataTable then
			Radio.Page = tonumber( varArgs[1] )
		
			if #Radio.DataTable:GetLines() > 0 then
				Radio.DataTable:Clear()
			end
			
			if varArgs[2] then
				RadioCache = varArgs[2]
				for id, data in pairs( RadioCache ) do
					Radio.DataTable:AddLine( data.Title, Timer:SimpleTime( data.Duration ), id )
				end
			else
				Radio.DataTable:AddLine( "No songs found", "", "" )
			end
			
			if varArgs[3] and tonumber( varArgs[3] ) then
				Radio:SetPage( tonumber( varArgs[1] ), tonumber( varArgs[3] ) )
			end
		end
	elseif szIdentifier == "Search" then
		if IsValid( Radio.SearchBox ) then
			Message:Print( Config.Prefix.Radio, "Generic", { "Now listing " .. #varArgs[1] .. " results for: " .. Radio.SearchBox:GetValue() } )
			Radio:Analyze( "Update", { 1, varArgs[1] } )
		end
	end
end


function Radio:CreateWindow( wnd )
	local ActiveWindow = Window:GetActive()
	if IsValid( ActiveWindow ) then
		Radio.Page = 1
		
		ActiveWindow:Center()
		ActiveWindow:MakePopup()
		
		Window.MakeButton{ parent = ActiveWindow, w = 16, h = 16, x = ActiveWindow:GetWide() - 25, y = 8, text = "X", onclick = function() timer.Destroy( "ProgressBarUpdater" ) Window:Close() end }
		
		local sx, sy = 20, 39
		local list = vgui.Create( "DListView", ActiveWindow )
		list:SetPos( sx, sy )
		list:SetSize( 380, 280 )
		list:SetMultiSelect( false )
		list:SetHeaderHeight( 20 )
		list:AddColumn( "Title" ):SetWidth( 200 )
		list:AddColumn( "Length" ):SetFixedWidth( 50 )
		list:AddColumn( "ID" ):SetFixedWidth( 35 )
		list.OnRowSelected = function( parent, line ) Radio.SelectedItem = list:GetLine( line ):GetValue(3) end
		list.DoDoubleClick = function( parent, index, list ) Radio.SelectedItem = list:GetValue(3) Radio.Execute( { SetID = 9 } ) end
		Radio.DataTable = list
		
		ActiveWindow.OnMousePressed = function()
			Radio.DataTable:ClearSelection()
			Radio.SelectedItem = nil
		end
		
		sy = sy + 290
		Window.MakeButton{ parent = ActiveWindow, w = 50, h = 22, x = sx, y = sy, text = "< Prev", id = 1, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 50, h = 22, x = sx + 380 - 50, y = sy, text = "Next >", id = 2, onclick = Radio.Execute }
		Radio.SearchBox = Window.MakeTextBox{ parent = ActiveWindow, w = 260, h = 22, x = sx + 50 + 10, y = sy, text = "Search Query" }
		Radio.SearchBox.OnEnter = function() Radio:Search( Radio.SearchBox:GetValue() ) end
		
		sx, sy = ActiveWindow:GetWide() - 190, 39
		Window.MakeLabel{ parent = ActiveWindow, x = sx, y = sy, font = "HUDTitleSmall", color = GUIColor.White, text = "Controls" }
		
		sy = sy + 30
--[[		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy, text = "Tune In", id = 3, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx + 90, y = sy, text = "Tune Out", id = 4, onclick = Radio.Execute }
		sy = sy + 42
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy, text = "Add to Queue", id = 5, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx + 90, y = sy, text = "Clear Queue", id = 6, onclick = Radio.Execute }
		sy = sy + 42
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy, text = "View Queue", id = 7, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx + 90, y = sy, text = "View List", id = 8, onclick = Radio.Execute }
		sy = sy + 42]]
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy, text = "Play Song", id = 9, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx + 90, y = sy, text = "Stop Playing", id = 10, onclick = Radio.Execute }
		sy = sy + 42
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy, text = "Add Song", id = 110, onclick = Radio.Execute }
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx + 90, y = sy, text = "Deselect", id = 12, onclick = Radio.Execute }
		
		Window.MakeButton{ parent = ActiveWindow, w = 80, h = 32, x = sx, y = sy + 42, text = "Refresh", id = 8, onclick = Radio.Execute }
		
		sy = 59 + 264
		local slider = vgui.Create("DNumSlider", ActiveWindow)
		slider:SetPos(sx, sy)
		slider:SetWide(170)
		slider:SetText("Volume")
		slider:SetMin(0)
		slider:SetMax(100)
		slider:SetDecimals(0)
		slider:SetValue(Radio.SetVolume)
		slider.ValueChanged = function(owner, value)
			Radio:Volume(value)
		end
		
		Radio.PageLabel = Window.MakeLabel{ parent = ActiveWindow, x = sx, y = sy - 20, font = "HUDLabelSmall", color = GUIColor.White, text = "Page: 1 / 1" }
		Radio.ProgressLabel = Window.MakeLabel{ parent = ActiveWindow, x = sx, y = sy - 6, font = "HUDLabelSmall", color = GUIColor.White, text = "Time: 00:00 / 00:00" }
		Radio.Execute( { SetID = 0 } )
		
		if not timer.Exists( "ProgressBarUpdater" ) then
			timer.Create( "ProgressBarUpdater", 1, 0, Radio.UpdateProgress )
		end
	end
end

local RadioApp = nil
function Radio:OpenApp()
	if IsValid( RadioApp ) then
		RadioApp:MakePopup()
		RadioApp:Show()
		return true
	end
end



function Radio.Execute( parent )
	local nID = parent.SetID
	if not nID or not tonumber( nID ) then return end
	
	if nID == 0 then
		Radio:DoNet( nID, { Radio.Page or 1 } )
	elseif nID == 1 then
		if Radio.Page > 1 then
			Radio:GoPage( Radio.Page, -1 )
		end
	elseif nID == 2 then
		Radio:GoPage( Radio.Page, 1 )
	elseif nID == 8 then
		Radio.Page = 1
		Radio:GoPage( Radio.Page, 0 )
	elseif nID == 9 then
		if Radio.SelectedItem then
			local Cached = RadioCache[ Radio.SelectedItem ]
			if Cached then
				Radio:StartSong( Cached )
			end
		else
			Message:Print( Config.Prefix.Radio, "Generic", { "Please select a valid song in the list." } )
		end
	elseif nID == 10 then
		Radio:StopSong()
	elseif nID == 11 then
		local szURL = parent.SetData
		Radio:DoNet( nID, { szURL } )
	elseif nID == 110 then
		Derma_StringRequest( "Enter URL", "Enter YouTube URL (Example: http://www.youtube.com/watch?v=ID)", "", function( szText ) Radio.Execute( { SetID = 11, SetData = szText } ) end)
	elseif nID == 12 then
		Radio.DataTable:ClearSelection()
		Radio.SelectedItem = nil
	end
end

function Radio:GoPage( nCurrent, nDirection )
	Radio:DoNet( 1, { nCurrent, nDirection } )
end

function Radio:Search( szQuery )
	Radio:DoNet( 2, { szQuery } )
end

function Radio:DoNet( nID, varArgs )
	net.Start( Radio.Protocol )
	net.WriteInt( nID, 16 )
	net.WriteTable( varArgs )
	net.SendToServer()
end

-- Playback
local RadioChannel = nil
function Radio:StartSong( cache )
	Radio:StopSong()

	local szURL = RadioBase .. cache.ID .. ".mp3"
	sound.PlayURL( szURL, "loop", function( channel )
		if not IsValid( channel ) then return end
		RadioChannel = channel
		RadioChannel:Play()
		RadioChannel:SetVolume( Radio.SetVolume / 100 )
		
		Message:Print( Config.Prefix.Radio, "Generic", { "Now playing " .. cache.Title .. "!" } )
	end )
end

function Radio:StopSong()
	if IsValid( RadioChannel ) then
		RadioChannel:SetVolume( 0 )
		RadioChannel:Stop()
		RadioChannel = nil
	end
end

function Radio:Volume( nValue )
	Radio.SetVolume = nValue
	if IsValid( RadioChannel ) then
		RadioChannel:SetVolume( Radio.SetVolume / 100 )
	end
end

function Radio.UpdateProgress()
	if IsValid( Radio.ProgressLabel ) then
		local nTime, nLength = 0, 0
		if IsValid( RadioChannel ) then
			nTime = RadioChannel:GetTime()
			nLength = RadioChannel:GetLength()
		end
		
		local szText = "Time: " .. Timer:SimpleTime( nTime ) .. " / " .. Timer:SimpleTime( nLength )
		Radio.ProgressLabel:SetText( szText )
	end
end

function Radio:SetPage( nPage, nTotal )
	if nPage then Radio.Page = nPage end
	if nTotal then Radio.Pages = nTotal end
	if IsValid( Radio.PageLabel ) then
		Radio.PageLabel:SetText( "Page: " .. Radio.Page .. " / " .. Radio.Pages )
	end
end