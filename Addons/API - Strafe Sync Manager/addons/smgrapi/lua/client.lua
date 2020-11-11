SMgrAPI = SMgrAPI or {}
SMgrAPI.Protocol = "SMgrAPI"
SMgrAPI.Selected = nil

SMgrAPI.List = nil
SMgrAPI.Text = nil
SMgrAPI.Buttons = {}

local DrawData = {
	Title = "reganaM cnyS efartS",
	Columns = { { 35, ".rN" }, { 120, "emaN" }, { 110, "DI maetS" }, { 60, "A cnyS" }, { 60, "B cnyS" }, { 55, "derusaeM" }, { 50, "?derotinoM" }, { 40, "?gifnoC" }, { 40, "?kcaH" } },
	Text1A = ".ecnedive gnitroppus sa ti esU .detnarg rof siht ekat ton oD",
	Text1B = ".rotacidni na tsuj era '?kcaH' dna '?gifnoC' yb nwohs seulaV",
	Text2A = ".semarf 0005~ dnuora si gnippohb dnuorgffo fo etunim 1",
	Text2B = ".dekcehc erew semarf ynam woh swohs bat 'derusaeM' ehT",
	Pop1 = ".DI maetS dilav a deretne ton evah uoY",
	Pop2 = ".nraw ot reyalp a detceles ton evah uoY",
	Pop3 = ".rof atad daoler ot reyalp a detceles ton evah uoY",
	Pop4 = ".no gnirotinom elggot ot reyalp a detceles ton evah uoY"
}

local Window = nil
local WindowData = nil

function SMgrAPI:OpenOverview()
	Window = vgui.Create( "DFrame" )
	Window:SetTitle( SMgrAPI.GetString( DrawData.Title ) )
	Window:SetSize( 680, 460 )
	Window:SetPos( ScrW() / 2 - Window:GetWide() / 2, ScrH() / 2 - Window:GetTall() / 2 )
	
	local list = vgui.Create( "DListView", Window )
	list:SetPos( 10, 30 )
	list:SetSize( 660, 340 )
	list:SetMultiSelect( false )
	list:SetHeaderHeight( 20 )
	
	for _,data in pairs( DrawData.Columns ) do
		list:AddColumn( SMgrAPI.GetString( data[ 2 ] ) ):SetWidth( data[ 1 ] )
	end
	
	list.OnRowSelected = function( parent, line )
		SMgrAPI.Selected = list:GetLine( line ):GetValue( 3 )
		
		for _,elem in pairs( SMgrAPI.Buttons ) do
			if IsValid( elem ) then
				elem:SetDisabled( not SMgrAPI.Selected )
			end
		end
	end
	
	SMgrAPI.List = list
	SMgrAPI.Buttons = {}
	
	SMgrAPI.MakeButton{ parent = Window, w = 100, h = 30, x = 10, y = 380, text = "Load / Refresh", onclick = function()
		RunConsoleCommand( "smgr", "load" )
	end }
	SMgrAPI.MakeButton{ parent = Window, w = 100, h = 30, x = 10 + 110, y = 380, text = "Monitor new", onclick = function()
		if SMgrAPI.Text and SMgrAPI.Text:GetValue() != "" and SMgrAPI.Text:GetValue() != "Enter Steam ID..." then
			RunConsoleCommand( "smgr", "addnew", SMgrAPI.Text:GetValue() )
		else
			SMgrAPI.MakeBox( SMgrAPI.GetString( DrawData.Pop1 ) )
		end
	end }
	
	table.insert( SMgrAPI.Buttons, SMgrAPI.MakeButton{ parent = Window, w = 100, h = 30, x = 10, y = 380 + 40, text = "Warn player", onclick = function()
		if SMgrAPI.Selected then
			RunConsoleCommand( "smgr", "warn", SMgrAPI.Selected )
		else
			SMgrAPI.MakeBox( SMgrAPI.GetString( DrawData.Pop2 ) )
		end
	end } )
	table.insert( SMgrAPI.Buttons, SMgrAPI.MakeButton{ parent = Window, w = 100, h = 30, x = 10 + 110, y = 380 + 40, text = "Reload selected", onclick = function()
		if SMgrAPI.Selected then
			RunConsoleCommand( "smgr", "update", SMgrAPI.Selected )
		else
			SMgrAPI.MakeBox( SMgrAPI.GetString( DrawData.Pop3 ) )
		end
	end } )
	table.insert( SMgrAPI.Buttons, SMgrAPI.MakeButton{ parent = Window, w = 140, h = 30, x = 10 + 220, y = 380 + 40, text = "Toggle monitoring player", onclick = function()
		if SMgrAPI.Selected then
			RunConsoleCommand( "smgr", "toggle", SMgrAPI.Selected )
			
			for _,line in pairs( SMgrAPI.List:GetLines() ) do
				if line:GetValue( 3 ) == SMgrAPI.Selected then
					line:SetValue( 7, line:GetValue( 7 ) == "Yes" and "No" or "Yes" )
					break
				end
			end
		else
			SMgrAPI.MakeBox( SMgrAPI.GetString( DrawData.Pop4 ) )
		end
	end } )

	SMgrAPI.Text = SMgrAPI.MakeTextBox{ parent = Window, x = 10 + 220, y = 385, w = 140, h = 20, text = "Enter Steam ID..." }
	SMgrAPI.MakeLabel{ parent = Window, x = 10 + 220 + 150, y = 380, text = SMgrAPI.GetString( DrawData.Text1A ) .. "\n" .. SMgrAPI.GetString( DrawData.Text1B ) }
	SMgrAPI.MakeLabel{ parent = Window, x = 10 + 220 + 150, y = 380 + 40, text = SMgrAPI.GetString( DrawData.Text2A ) .. "\n" .. SMgrAPI.GetString( DrawData.Text2B ) }
	
	for _,elem in pairs( SMgrAPI.Buttons ) do
		if IsValid( elem ) then
			elem:SetDisabled( true )
		end
	end
	
	Window:Center()
	Window:MakePopup()
	
	if not WindowData then
		RunConsoleCommand( "smgr", "load" )
	else
		for _,item in pairs( WindowData ) do
			SMgrAPI:AddToList( item )
		end
	end
end

function SMgrAPI:ClearList()
	if not IsValid( SMgrAPI.List ) then return end
	
	SMgrAPI.List:Clear()
end

function SMgrAPI:AddToList( item )
	if not IsValid( SMgrAPI.List ) then return end

	SMgrAPI.List:AddLine( unpack( item ) )
end

function SMgrAPI.MakeBox( t )
	Derma_Query( t, SMgrAPI.GetString( DrawData.Title ), "Close", function() end )
end

function SMgrAPI.MakeButton( t )
	local btn = vgui.Create( "DButton", t.parent )
	btn:SetSize( t.w, t.h )
	btn:SetPos( t.x, t.y )
	btn:SetText( t.text )
	btn.DoClick = t.onclick
	return btn
end

function SMgrAPI.MakeLabel( t )
	local lbl = vgui.Create( "DLabel", t.parent )
	lbl:SetPos( t.x, t.y )
	lbl:SetText( t.text )
	lbl:SizeToContents()
	return lbl
end

function SMgrAPI.MakeTextBox( t )
	local txt = vgui.Create( "DTextEntry", t.parent )
	txt:SetPos( t.x, t.y )
	txt:SetSize( t.w, t.h )
	txt:SetText( t.text or "" )
	return txt
end

function SMgrAPI.GetString( t )
	return string.reverse( t )
end

function SMgrAPI.Receive()
	local szIdentifier = net.ReadString()

	if not szIdentifier then return end
	if szIdentifier == "OpenGUI" then
		SMgrAPI:OpenOverview()
	elseif szIdentifier == "OpenBox" then
		local Data = net.ReadTable()
		SMgrAPI.MakeBox( Data[ 1 ] )
	elseif szIdentifier == "SetRange" then
		WindowData = net.ReadTable()

		SMgrAPI:ClearList()
		
		for _,item in pairs( WindowData ) do
			SMgrAPI:AddToList( item )
		end
	elseif szIdentifier == "UpdateItem" then
		local Data = net.ReadTable()
		
		if WindowData and type( WindowData ) == "table" then
			for _,item in pairs( WindowData ) do
				if item[ 3 ] == Data[ 3 ] then
					for i = 4, 9 do
						item[ i ] = Data[ i ]
					end
					
					break
				end
			end
		end
		
		if not IsValid( SMgrAPI.List ) then return end
		
		for _,line in pairs( SMgrAPI.List:GetLines() ) do
			if line:GetValue( 3 ) == Data[ 3 ] then
				for i = 4, 9 do
					line:SetValue( i, Data[ i ] )
				end
				
				break
			end
		end
	end
end
net.Receive( SMgrAPI.Protocol, SMgrAPI.Receive )