-- On core_lang.lua, change Lang.Servers from

Lang.Servers = {
	-- Add your servers like this:
	-- ["bhop"] = { "IP.ADDRESS.GOES.HERE:27015", "Our Bunny Hop Server" },
	-- ["deathrun"] = { "IP.ADDRESS.GOES.HERE:27015", "Our Deathrun Server" },
}

-- To something like this!

Lang.Servers = {
	{ "188.165.255.107:27015", "Bunny Hop (EU)" },
	{ "192.223.29.127:27015", "Bunny Hop (US)" },
	{ "188.165.255.107:27030", "Jailbreak" },
	{ "188.165.255.107:27040", "Skill Surf" },
	{ "188.165.255.107:27050", "Deathrun" }
}

-- Then on sv_command.lua, replace this big function

	self:Register( { "hop", "switch", "server" }, function( ply, args )
		if #args > 0 then
			local data = Lang.Servers[ args[ 1 ] ]
			if data then
				ply.DCReason = "Player hopped to " .. data[ 2 ]
				Core:Send( ply, "Client", { "Server", data } )
				timer.Simple( 10, function()
					if IsValid( ply ) then
						ply.DCReason = nil
					end
				end )
			else
				Core:Send( ply, "Print", { "General", "The server '" .. args[ 1 ] .. "' is not a valid server." } )
			end
		else
			local servers = "None"
			local tab = {}
			
			for server,data in pairs( Lang.Servers ) do
				table.insert( tab, server )
			end
			
			if #tab > 0 then
				servers = string.Implode( ", ", tab )
			end
			
			Core:Send( ply, "Print", { "General", "Usage: !hop [server id]\nAvailable servers to !hop to: " .. servers } )
		end
	end )
	
-- With this beauty

	self:Register( { "hop", "switch", "server" }, function( ply )
		Core:Send( ply, "Client", { "Server", Lang.Servers } )
	end )
	
-- Now open up cl_init.lua and look for function Client:ServerSwitch( data )
-- It'll look like this:

function Client:ServerSwitch( data )
	Link:Print( "General", "Now connecting to: " .. data[ 2 ] )
	Derma_Query( 'Are you sure you want to connect to ' .. data[ 2 ] .. '?', 'Connecting to different server', 'Yes', function() LocalPlayer():ConCommand( "connect " .. data[ 1 ] ) end, 'No', function() end)
end

-- Replace it with this:

function Client:ServerSwitch( data )
	local func = {}
	for _,tab in pairs( data ) do
		table.insert( func, tab[ 2 ] )
		table.insert( func, function() LocalPlayer():ConCommand( "connect " .. tab[ 1 ] ) end )
	end
	
	table.insert( func, "Cancel" )
	table.insert( func, function() end )
	
	Window.MakeQuery( "Select a server to connect to", "Server hop", unpack( func ) )
end

-- And that should be it!