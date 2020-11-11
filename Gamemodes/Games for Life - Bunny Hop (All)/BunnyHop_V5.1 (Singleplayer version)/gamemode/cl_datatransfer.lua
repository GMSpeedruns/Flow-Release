Message = {}
Message.Protocol = "Message"

function Message.Receive()
	local nPrefix = net.ReadInt(6)
	local szIdentifier = net.ReadString()
	local bArgs = net.ReadBit() == 1
	local varArgs = bArgs and net.ReadTable() or {}
	
	if not szIdentifier then return end
	Message:Print( nPrefix, szIdentifier, varArgs )
end
net.Receive( Message.Protocol, Message.Receive )

function Message:Print( nPrefix, szIdentifier, varArgs )
	local szPrefix = "Bhop"
	for prefix, nID in pairs(Config.Prefix) do
		if nID == nPrefix then szPrefix = prefix break end
	end

	chat.AddText( GUIColor.White, "[", GUIColor.Prefixes[ nPrefix ], szPrefix, GUIColor.White, "] ", Lang:Get( szIdentifier, varArgs ) )
	if Client:IsChatEnabled() then chat.PlaySound() end
end


Data = {}
Data.Protocol = "Data"

function Data.Receive()
	local szIdentifier = net.ReadString()
	local bArgs = net.ReadBit() == 1
	local varArgs = bArgs and net.ReadTable() or {}
	
	if not szIdentifier then return end
	Data:Analyze( szIdentifier, varArgs )
end
net.Receive( Data.Protocol, Data.Receive )

function Data:Analyze( szIdentifier, varArgs )
	if szIdentifier == "VoteList" then
		Data.Cache.Vote = varArgs
		Window:Open( "Vote" )
	elseif szIdentifier == "VoteData" then
		local ActiveWindow = Window:GetActive()
		if IsValid( ActiveWindow ) then
			ActiveWindow.Data.Votes = varArgs
			ActiveWindow.Data.bUpdate = true
		end
	elseif szIdentifier == "SpecViewer" then
		Spectator:Viewer( varArgs )
	elseif szIdentifier == "SpecTimer" then
		Spectator:Timer( varArgs )
	elseif szIdentifier == "LJStats" then
		Timer:LJ( varArgs )
	elseif szIdentifier == "TopList" then
		if varArgs and varArgs[1] and type( varArgs[1] ) == "table" and #varArgs[1] > 0 then
			Data.Cache.Top = varArgs[1]
		end
		
		Window:Open( "Top" )
	elseif szIdentifier == "Records" then
		Data.Cache.WR.Mode = varArgs[1]
		Data.Cache.WR.Count = varArgs[2]
		Data.Cache.WR.Data = varArgs[3]
		Data.Cache.WR.Full = varArgs[4]
		Window:Open( "WR", (varArgs[4] and 8) )
	end
end


Data.Cache = {
	WR = { Mode = 1, Count = 0, Data = {}, Full = false },
	Maps = {},
	Vote = {},
	Top = {},
	Beat = {}
}


Data.Maps = {}
Data.Maps.Protocol = "Map"

function Data.Maps.Receive()
	local BinaryData = net.ReadData( net.ReadUInt( 32 ) )
	local Deflated = util.JSONToTable( util.Decompress( BinaryData ) )
	
	for i, obj in pairs( Deflated ) do
		Data.Cache.Maps[ i ] = { obj[ 1 ], Client:MapName( obj[ 1 ] ), obj[ 2 ] }
	end
	
	Data.Maps:Save( BinaryData )
end
net.Receive( Data.Maps.Protocol, Data.Maps.Receive )


function Data.Maps:GetMap( szMap )
	for i, obj in pairs( Data.Cache.Maps ) do
		if obj[1] == szMap then
			return obj
		end
	end
	return nil
end

function Data.Maps:Load()
	local binData = file.Read( "impulse_maps.txt", "DATA" )
	local Deflated = util.JSONToTable( util.Decompress( binData ) )
	
	for i, obj in pairs( Deflated ) do
		Data.Cache.Maps[ i ] = { obj[ 1 ], Client:MapName( obj[ 1 ] ), obj[ 2 ] }
	end

	if #Data.Cache.Maps != Config.MapCount then
		RunConsoleCommand( "requestmaps" )
	end
end

function Data.Maps:Save( binData )
	if file.Exists( "impulse_maps.txt", "DATA" ) then
		file.Delete( "impulse_maps.txt" )
	end
	
	file.Write( "impulse_maps.txt", binData )
end