if SERVER then return end

nm = nil
lmb = nil
lml = nil

local maps = { }
local rtvMaps = {"","","","",""}
local mapslist = {}
local pointslist = {}
local mapVotes = {0,0,0,0,0}

local GREEN = Color( 0, 255, 25 )
local WHITE = Color( 255, 255, 255 )
local RED = Color( 255, 100, 100 )

local function GetMaps( data )
	local mapfile = data:ReadString()
	table.insert( maps, mapfile )
end
usermessage.Hook( "RTV_AddMaps", GetMaps )

local function receivemaps(len)
	local dataTable = net.ReadTable()
	for k,v in pairs(dataTable) do
		table.insert(mapslist, v[1])
		--table.insert(pointslist, v[2])
		pointslist[v[1]] = v[2]
	end
end
net.Receive("rtv_mapslist",receivemaps)

local function SetVotes( data )
	for i = 1, 5 do
		mapVotes[i] = tonumber(data:ReadChar())
	end
end
usermessage.Hook( "RTV_MapVotes", SetVotes )

local function nominatemenu( )
	if(!mapslist[1]) then return end
	if(IsValid(nm)) then return end
	
	drawWR = false
	drawModes = false
	
	local maplist = {}
	local num = math.ceil(#mapslist/7)
	for k,v in pairs(mapslist) do
		maplist[k] = string.gsub(v, ".bsp", "" )
		maplist[k] = string.gsub(maplist[k], "bhop ", "")
		maplist[k] = string.gsub(maplist[k], "_", " " )
		maplist[k] = maplist[k] .. " [" .. pointslist[v] .. "]"
	end
	
	local currentpage = 1
	
	nm = vgui.Create( "DFrame" )
	nm:SetTitle( "" )
	nm:SetSize( 220, 240 )
	nm:SetPos( 20, ScrH()/2 - nm:GetTall()/2 )
	nm:SetDraggable( false )
	nm:ShowCloseButton( false )
	nm.Paint = function()

		local w, h = nm:GetWide(), nm:GetTall()

		draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 140 ) )
		draw.RoundedBox( 6, 3, 2, w - 6, 20, Color( 2, 3, 5, 100 ) )
		draw.SimpleText( "Nominate a map!", "HudFont2", w/2, 1, RED, TEXT_ALIGN_CENTER )
     
	end
	
	local voted = false

	-- Yeah, you need at least 5 maps for this not to give an error, though I doubt many have less than 5 maps.

	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" } -- pr / nx / q
	local yOffset = 25
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", nm )
		mapLabels[i]:SetPos( 7, yOffset )
		mapLabels[i]:SetFont("HudFont1")
		mapLabels[i]:SetColor( WHITE )
		
		if (i > 7) then
			mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
		else
			mapLabels[i]:SetText( "(" .. tostring(i) .. ") " .. maplist[i] )
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	
	local pallowed = true
	
	nm.Think = function()
	
		local down = -1
		if input.IsKeyDown( KEY_1 ) then down = 1
		elseif input.IsKeyDown( KEY_2 ) then down = 2
		elseif input.IsKeyDown( KEY_3 ) then down = 3
		elseif input.IsKeyDown( KEY_4 ) then down = 4
		elseif input.IsKeyDown( KEY_5 ) then down = 5
		elseif input.IsKeyDown( KEY_6 ) then down = 6
		elseif input.IsKeyDown( KEY_7 ) then down = 7
		elseif input.IsKeyDown( KEY_8 ) then down = 8
		elseif input.IsKeyDown( KEY_9 ) then down = 9
		elseif input.IsKeyDown( KEY_0 ) then down = 0
		end
		
		if down > 0 and down < 8 and not voted then
			voted = true
			RunConsoleCommand( "rtv_nominate", mapslist[(7 * currentpage) - 7 + down] )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			timer.Simple( .25, function() if nm then nm:Close() end end )
		end
	
		if down == 8 and pallowed and not voted and currentpage != 1 then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)

			currentpage = currentpage - 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				mapLabels[i]:SetText("(" .. tostring(i) .. ") "..maplist[ind+i])
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if(currentpage == 1) then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 9 and pallowed and not voted and currentpage != num then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)
		
			currentpage = currentpage + 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				if (maplist[ind+i]) then
					mapLabels[i]:SetText("(" .. tostring(i) .. ") "..maplist[ind+i])
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if(currentpage == num) then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 0 and pallowed and not voted then
			timer.Simple(.25, function()
				if(nm) then
					nm:Close()
					nm = nil
				end
			end)
		end

	end
end
usermessage.Hook( "NominateM", nominatemenu )

local function rtvmenu( )
	
	drawWR = false
	drawModes = false

	for i = 1, 5 do
		rtvMaps[i] = string.gsub( maps[i], ".bsp", "" )
		rtvMaps[i] = string.gsub( rtvMaps[i], "_", " " )
	end

	local isAllowed = false
	local voted = false
	local votedInt = -1

	local rtv = vgui.Create( "DFrame" )
	rtv:SetTitle( "" )
	rtv:SetSize( 200, 130 )
	rtv:SetPos( 20, ScrH()/2 - rtv:GetTall()/2 )
	rtv:SetDraggable( false )
	rtv:ShowCloseButton( false )
	rtv.Paint = function()

		local w, h = rtv:GetWide(), rtv:GetTall()

		draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 140 ) )
		draw.RoundedBox( 6, 3, 2, w - 6, 20, Color( 2, 3, 5, 100 ) )
		draw.SimpleText( "Vote for a map!", "HudFont2", w/2, 1, RED, TEXT_ALIGN_CENTER )
     
	end


	timer.Simple( 30, function()

		if rtv then -- if not voted and rtv then
			rtv:Close()
		end

	end )

	-- Yeah, you need at least 5 maps for this not to give an error, though I doubt many have less than 5 maps.

	local mapLabels = {}
	local yOffset = 25
	
	for i = 1, 5 do
		mapLabels[i] = vgui.Create( "DLabel", rtv )
		mapLabels[i]:SetPos( 7, yOffset )
		mapLabels[i]:SetFont("HudFont1")
		mapLabels[i]:SetColor( WHITE )
		mapLabels[i]:SetText( "(" .. tostring(i) .. ") " .. rtvMaps[i] .. " [" .. mapVotes[i] .. "]" )
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end

	rtv.Think = function()

		-- We have to create multiples to set the color, I'm unsure if there's an easier way.

		for i = 1, 5 do
			mapLabels[i]:SetText( "(" .. tostring(i) .. ") " .. rtvMaps[i] .. " [" .. mapVotes[i] .. "]" )
		end
		
		local down = -1
		if input.IsKeyDown( KEY_1 ) then down = 1
		elseif input.IsKeyDown( KEY_2 ) then down = 2
		elseif input.IsKeyDown( KEY_3 ) then down = 3
		elseif input.IsKeyDown( KEY_4 ) then down = 4
		elseif input.IsKeyDown( KEY_5 ) then down = 5
		end
		
		if down > 0 and down < 6 and not voted then
			voted = true
			votedInt = down
			RunConsoleCommand( "rtv_vote", tostring(down) )
			surface.PlaySound( "garrysmod/save_load1.wav" )
			mapLabels[down]:SetColor( GREEN )
			--timer.Simple( 10, function() if rtv then rtv:Close() end end )
			timer.Simple( 3, function() isAllowed = true end )
		elseif down > 0 and down < 6 and voted and down != votedInt and votedInt >= 0 and isAllowed then
			mapLabels[votedInt]:SetColor( WHITE )
			mapLabels[down]:SetColor( GREEN )
			RunConsoleCommand( "rtv_changevote", tostring(votedInt), tostring(down) )
			votedInt = down
			isAllowed = false
			surface.PlaySound( "garrysmod/save_load1.wav" )
			timer.Simple( 3, function() isAllowed = true end )
		end

	end

end
usermessage.Hook( "StartRTV", rtvmenu )

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

listMapsBeat = {}
local function ReceiveMaps(len)
	listMapsBeat = net.ReadTable()
end
net.Receive("ld_Maps", ReceiveMaps)

local function ShowMapsBeat()
	if(!listMapsBeat[1]) then return end
	if(IsValid(lmb)) then return end

	local currentpage = 1
	local maplist = {}
	local num = math.ceil(#listMapsBeat/7)

	for k,v in pairs(listMapsBeat) do
		maplist[k] = {string.gsub(v['map_name'], "bhop_", ""), v['time']}
	end
	
	lmb = vgui.Create( "DFrame" )
	lmb:SetTitle( "" )
	lmb:SetSize( 200, 240 )
	lmb:SetPos( 20, ScrH()/2 - lmb:GetTall()/2 )
	lmb:SetDraggable( false )
	lmb:ShowCloseButton( false )
	lmb.Paint = function()

		local w, h = lmb:GetWide(), lmb:GetTall()

		draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 140 ) )
		draw.RoundedBox( 6, 3, 2, w - 6, 20, Color( 2, 3, 5, 100 ) )
		draw.SimpleText( "Beaten Maps (" .. tostring(#listMapsBeat) .. ")", "HudFont2", w/2, 1, RED, TEXT_ALIGN_CENTER )
     
	end
	
	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" } -- pr / nx / q
	local yOffset = 25
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", lmb )
		mapLabels[i]:SetPos( 7, yOffset )
		mapLabels[i]:SetFont("HudFont1")
		mapLabels[i]:SetColor( WHITE )
		
		if #maplist == 0 then
			mapLabels[i]:SetText( "" )
		else
			if (i > 7) then
				mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
			else
				mapLabels[i]:SetText( "(" .. GetTime(maplist[i][2]) .. ") " .. maplist[i][1] )
			end
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	
	local pallowed = true
	mapLabels[8]:SetVisible(false)
	
	lmb.Think = function()
	
		local down = -1
		if input.IsKeyDown( KEY_8 ) then down = 8
		elseif input.IsKeyDown( KEY_9 ) then down = 9
		elseif input.IsKeyDown( KEY_0 ) then down = 0
		end

		if down == 8 and pallowed and currentpage != 1 then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)

			currentpage = currentpage - 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				if #maplist == 0 then
					mapLabels[i]:SetText( "" )
				else
					mapLabels[i]:SetText( "(" .. GetTime(maplist[ind+i][2]) .. ") " .. maplist[ind+i][1] )
				end
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if(currentpage == 1) then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 9 and pallowed and currentpage != num then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)
		
			currentpage = currentpage + 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				if (maplist[ind+i]) then
					mapLabels[i]:SetText( "(" .. GetTime(maplist[ind+i][2]) .. ") " .. maplist[ind+i][1] )
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if(currentpage == num) then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 0 and pallowed then
			timer.Simple(.25, function()
				if(lmb) then
					lmb:Close()
					lmb = nil
				end
			end)
		end

	end
end
usermessage.Hook( "LMapsBeat", ShowMapsBeat )

local function ShowMapsLeft()
	if(!listMapsBeat[1]) then return end
	if(IsValid(lml)) then return end

	local currentpage = 1
	local mapCopy = {}
	local maplist = {}

	for k,v in pairs(pointslist) do
		mapCopy[k] = v
	end
	for k,v in pairs(listMapsBeat) do
		mapCopy[v['map_name']] = nil
	end
	for k,v in pairs(mapCopy) do
		table.insert(maplist, {k, v})
	end
	
	local num = math.ceil(#maplist/7)
	
	lml = vgui.Create( "DFrame" )
	lml:SetTitle( "" )
	lml:SetSize( 200, 240 )
	lml:SetPos( 20, ScrH()/2 - lml:GetTall()/2 )
	lml:SetDraggable( false )
	lml:ShowCloseButton( false )
	lml.Paint = function()

		local w, h = lml:GetWide(), lml:GetTall()

		draw.RoundedBox( 8, 0, 0, w, h, Color( 2, 3, 5, 140 ) )
		draw.RoundedBox( 6, 3, 2, w - 6, 20, Color( 2, 3, 5, 100 ) )
		draw.SimpleText( "Unbeaten Maps (" .. tostring(#maplist) .. ")", "HudFont2", w/2, 1, RED, TEXT_ALIGN_CENTER )
     
	end
	
	local mapLabels = {}
	local textData = { "Previous", "Next", "Quit" } -- pr / nx / q
	local yOffset = 25
	for i = 1, 10 do
		mapLabels[i] = vgui.Create( "DLabel", lml )
		mapLabels[i]:SetPos( 7, yOffset )
		mapLabels[i]:SetFont("HudFont1")
		mapLabels[i]:SetColor( WHITE )
		
		if #maplist == 0 then
			mapLabels[i]:SetText( "" )
		else
			if (i > 7) then
				mapLabels[i]:SetText( "(" .. string.gsub(tostring(i), "10", "0") .. ") " .. textData[i - 7] ) 
			else
				mapLabels[i]:SetText( "[" .. maplist[i][2] .. "] " .. maplist[i][1] )
			end
		end
		mapLabels[i]:SizeToContents()
		
		yOffset = yOffset + 20
	end
	
	local pallowed = true
	mapLabels[8]:SetVisible(false)
	
	lml.Think = function()
	
		local down = -1
		if input.IsKeyDown( KEY_8 ) then down = 8
		elseif input.IsKeyDown( KEY_9 ) then down = 9
		elseif input.IsKeyDown( KEY_0 ) then down = 0
		end

		if down == 8 and pallowed and currentpage != 1 then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)

			currentpage = currentpage - 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				if #maplist == 0 then
					mapLabels[i]:SetText( "" )
				else
					mapLabels[i]:SetText( "[" .. maplist[ind+i][2] .. "] " .. maplist[ind+i][1] )
				end
				mapLabels[i]:SetVisible(true)
				mapLabels[i]:SizeToContents()
			end

			if(currentpage == 1) then
				mapLabels[8]:SetVisible(false)
				mapLabels[9]:SetVisible(true)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 9 and pallowed and currentpage != num then
			pallowed = false
			timer.Simple(0.25,function() pallowed = true end)
		
			currentpage = currentpage + 1
			local ind = (7*currentpage)-7
			
			for i = 1, 7 do
				if (maplist[ind+i]) then
					mapLabels[i]:SetText( "[" .. maplist[ind+i][2] .. "] " .. maplist[ind+i][1] )
					mapLabels[i]:SetVisible(true)
					mapLabels[i]:SizeToContents()
				else
					mapLabels[i]:SetVisible(false)
				end
			end

			if(currentpage == num) then
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(false)
			else
				mapLabels[8]:SetVisible(true)
				mapLabels[9]:SetVisible(true)
			end
		elseif down == 0 and pallowed then
			timer.Simple(.25, function()
				if(lml) then
					lml:Close()
					lml = nil
				end
			end)
		end

	end
end
usermessage.Hook( "LMapsLeft", ShowMapsLeft )

local function RTV_Message( data )

	local text = data:ReadString()

	if !text then return end

	chat.AddText( WHITE, "[", GREEN, "Voting", WHITE, "] ", WHITE, text )

end
usermessage.Hook( "RTV_Msg", RTV_Message )