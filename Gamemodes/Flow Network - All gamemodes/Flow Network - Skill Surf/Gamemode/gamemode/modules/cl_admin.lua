Admin = {}
Admin.Protocol = "Admin"

local Verify = false
local Secure = {}
local RawCache = {}
local DrawData = nil
local DrawTimer = nil

local ElemList = {}
local ElemCache = {}
local ElemData = {}

function Admin:Receive( varArgs )
	local szType = tostring( varArgs[ 1 ] )
	
	if szType == "Open" then
		Secure.Setup = varArgs[ 2 ]
		Verify = true
		Window:Open( "Admin" )
	elseif szType == "Query" then
		local tab, func = varArgs[ 2 ], {}
		
		for i = 1, #tab do
			table.insert( func, tab[ i ][ 1 ] )
			table.insert( func, function() Admin:ReqAction( tab[ i ][ 2 ][ 1 ], tab[ i ][ 2 ][ 2 ] ) end )
		end
		
		Window.MakeQuery( tab.Caption, tab.Title, unpack( func ) )
	elseif szType == "EditZone" then
		Secure.Editor = varArgs[ 2 ] and varArgs[ 2 ] or nil
	elseif szType == "Request" then
		local tab = varArgs[ 2 ]
		Window.MakeRequest( tab.Caption, tab.Title, tab.Default, function( r ) Admin:ReqAction( tab.Return, r or tab.Default ) end, function() end )
	elseif szType == "Edit" then
		Admin.EditType = varArgs[ 2 ]
	elseif szType == "Raw" then
		RawCache = varArgs[ 2 ]
	elseif szType == "Message" then
		DrawData = varArgs[ 2 ]
		DrawTimer = CurTime()
	elseif szType == "Grab" then
		Admin:GrabIt()
	elseif szType == "GUI" then
		Verify = true
		Window:Open( varArgs[ 2 ], varArgs[ 3 ], true )
	elseif szType == "GUIData" then
		Admin:SubmitAction( varArgs[ 2 ], varArgs[ 3 ] )
	end
end

function Admin:ReqAction( nID, varData )
	if not Verify then return end
	if not nID or nID < 0 then return end
	
	Link:Send( "Admin", { -1, nID, varData } )
end

function Admin:SendAction( nID, varData )
	if not Verify then return end
	if not nID or nID < 0 then return end
	
	Link:Send( "Admin", { -2, nID, varData } )
end

function Admin:IsAvailable() return Verify end


local function ButtonCallback( self )
	if self.Close then
		return Window:Close()
	elseif self.VIP and self.Extra then
		if self.Extra == "Random" then
			ElemCache["ColorChat"]:SetColor( Core.Util:RandomColor() )
		elseif self.Extra == "Gradient" then
			Link:Send( "Admin", { 1, { self.Extra, ElemCache["ColorTag"]:GetColor(), ElemCache["ColorName"]:GetColor(), ElemCache["TextName"]:GetValue() } } )
		elseif self.Extra == "Tag" or self.Extra == "Name" then
			Link:Send( "Admin", { 1, { self.Extra, ElemCache["Color" .. self.Extra]:GetColor(), ElemCache["Text" .. self.Extra]:GetValue() } } )
		else
			Link:Send( "Admin", { 1, { self.Extra, self.Extra == "Save" and ElemCache["ColorChat"]:GetColor() or nil } } )
		end
		
		return false
	end

	if not ElemData.Store then return end
	local data = ElemData.Store:GetValue()
	if not self.Require or (data != "" and data != ElemData.Default) then
		Admin:SendAction( self.Identifier, ElemData.Store:GetValue() )
	else
		Link:Print( "Admin", "You have to select or enter a valid player steam id." )
	end
end

local function CreateElement( data, parent )
	local elem = vgui.Create( data["Type"], parent )
	for func,args in pairs( data["Modifications"] ) do
		if func == "Sequence" then
			for _,seq in pairs( args ) do
				local f = elem[ seq[ 1 ] ]
				local d = f( elem, unpack( seq[ 2 ] ) )
				if seq[ 3 ] then
					local q = d[ seq[ 3 ] ]
					q( d, seq[ 4 ] )
				end
			end
		else
			local f = elem[ func ]
			f( elem, unpack( args ) )
		end
	end
	
	if data["Label"] then
		ElemCache[ data["Label"] ] = elem
	end
	
	if data["Type"] == "DListView" then
		elem.OnRowSelected = function( self, row )
			if ElemData.Store then
				ElemData.Store:SetText( self:GetLine( row ):GetValue( 2 ) )
			end
		end
	elseif data["Type"] == "DButton" then
		elem.Identifier = data["Identifier"]
		elem.Require = data["Require"]
		elem.VIP = data["VIP"]
		elem.Extra = data["Extra"]
		elem.Close = data["Close"]
		elem.DoClick = ButtonCallback
	end
	
	table.insert( ElemList, elem )
end

function Admin:SubmitAction( szID, varArgs )
	if szID == "Players" then
		local elem = ElemCache["PlayerList"]
		if not elem then return end
		for _,line in pairs( varArgs ) do
			elem:AddLine( unpack( line ) )
		end
	elseif szID == "Store" then
		ElemData.Store = ElemCache[ varArgs[ 1 ] ]
		ElemData.Default = varArgs[ 2 ]
	end
end

function Admin:GenerateGUI( parent, data )
	parent:Center()
	parent:MakePopup()
	
	ElemList = {}
	
	for i = 1, #data do
		local elemdata = data[ i ]
		CreateElement( elemdata, parent )
	end
end


function Admin:GrabIt()
	local data = util.Compress( util.Base64Encode( render.Capture( { format = "jpeg", w = ScrW(), h = ScrH(), x = 0, y = 0, quality = 1 } ) ) )
	local length = #data
	
	net.Start( Link.Protocol2 )
	net.WriteUInt( length, 32 )
	net.WriteData( data, length )
	net.SendToServer()
end

local function ReceiveGrab()
	local id = net.ReadString()
	local length = net.ReadUInt( 32 )
	
	if id == "Help" then
		if length > 0 then
			local data = util.Decompress( net.ReadData( length ) )
			if not data then return Link:Print( "General", "Couldn't load help" ) end
			
			Cache.H_Data = util.JSONToTable( data )
		end
		
		return Client:ShowHelp( Cache.H_Data )
	end
	
	local data = util.Decompress( net.ReadData( length ) )
	if id == "Data" then
		if not data then return Link:Print( "Admin", "Couldn't obtain data!" ) end
		
		local frame = vgui.Create( "DFrame" )
		frame:SetSize( ScrW() * 0.8, ScrH() * 0.8 )
		frame:MakePopup()
		frame:Center()
		frame:SetTitle( "Admin Data" )

		local html = frame:Add("HTML")
		html:SetHTML([[<style type="text/css">body{margin:0;padding:0;overflow:hidden;} img{width:100%;height:100%;}</style><img src="data:image/jpg;base64,]] .. data .. [[">]])
		html:Dock( FILL )
	elseif id == "List" then
		if not data then return Link:Print( "Notification", "An error occurred while obtaining data!" ) end
		local tab = util.JSONToTable( data )
		if not tab[ 1 ] or not tab[ 2 ] then return end
		Cache:M_Save( tab[ 1 ], tab[ 2 ], true )
	end
end
net.Receive( Link.Protocol2, ReceiveGrab )

local DrawLaser = Material( _C.MaterialID .. "/timer.png" )
local DrawColor = Color( 50, 0, 255, 255 )
local DrawWidth = 5

local function DrawAreaEditor()
	if Secure.Editor and Secure.Editor.Active then
		local Start, End = Secure.Editor.Start, LocalPlayer():GetPos()
		local Min = Vector(math.min(Start.x, End.x), math.min(Start.y, End.y), math.min(Start.z, End.z))
		local Max = Vector(math.max(Start.x, End.x), math.max(Start.y, End.y), math.max(Start.z + 128, End.z + 128))
		local B1, B2, B3, B4 = Vector(Min.x, Min.y, Min.z), Vector(Min.x, Max.y, Min.z), Vector(Max.x, Max.y, Min.z), Vector(Max.x, Min.y, Min.z)
		local T1, T2, T3, T4 = Vector(Min.x, Min.y, Max.z), Vector(Min.x, Max.y, Max.z), Vector(Max.x, Max.y, Max.z), Vector(Max.x, Min.y, Max.z)
	
		render.SetMaterial( DrawLaser )
		render.DrawBeam( B1, B2, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B2, B3, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B3, B4, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B4, B1, DrawWidth, 0, 1, DrawColor )
			
		render.DrawBeam( T1, T2, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( T2, T3, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( T3, T4, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( T4, T1, DrawWidth, 0, 1, DrawColor )
		
		render.DrawBeam( B1, T1, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B2, T2, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B3, T3, DrawWidth, 0, 1, DrawColor )
		render.DrawBeam( B4, T4, DrawWidth, 0, 1, DrawColor )
	end
end
hook.Add( "PostDrawOpaqueRenderables", "PreviewArea", DrawAreaEditor )

local function AddDrawHud()
	if RawCache and RawCache[ 1 ] then
		local w, h, n = ScrW(), 20, 10
		for _,i in pairs( RawCache ) do
			draw.SimpleText( i, "HUDTimer", w - 20, h + n, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP )
			n = n + 20
		end
	end
	
	if DrawData then
		local alpha = 255
		if CurTime() - DrawTimer > 5 then
			local val = math.Clamp( CurTime() - DrawTimer, 5, 7.5 ) - 5
			alpha = 255 - (val * 102)
			
			if alpha == 0 then
				DrawData, DrawTimer = nil, nil
				return true
			end
		end
		
		draw.SimpleText( DrawData, "HUDMessage", ScrW() / 2, 120, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER )
	end
end
hook.Add( "HUDPaint", "PreviewStats", AddDrawHud )