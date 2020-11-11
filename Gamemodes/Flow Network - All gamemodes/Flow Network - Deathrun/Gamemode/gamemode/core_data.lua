require( "mysqloo" )

Core = Core or {}
Core.Protocol = "SecureTransfer"
Core.Protocol2 = "BinaryTransfer"

util.AddNetworkString( Core.Protocol )
util.AddNetworkString( Core.Protocol2 )


function Core:Boot()
	Command:Init()
	RTV:Init()
	Round:Init()
	Timer:Init()
	Player:Init()
end

function Core:Unload( bForce )
	-- To-Do: Finalization mechanism here for the flatfiles
end


function Core:AwaitLoad( bRetry )
	Zones:SetupMap()
	Radio:Setup()
	Core:Optimize()
	
	if timer.Exists( "SQLCheck" ) then
		timer.Destroy( "SQLCheck" )
	end
	
	timer.Simple( 0, function() Core:StartSQL() end )
	timer.Create( "SQLCheck", 10, 0, Core.SQLCheck )
end

function Core:StartSQL()
	local function OnComplete()
		Admin:LoadAdmins()
		Admin:LoadNotifications()
		
		Core.SQLChecking = nil
	end
	
	SQL:CreateObject( OnComplete )
	timer.Simple( 5, function()
		Core.SQLChecking = nil
	end )
end

function Core.SQLCheck()
	if not SQL or not Core then return end
	if (SQL.Error or not SQL.Available) and not Core.SQLChecking then
		SQL.Error = nil
		Core.SQLChecking = true
		Core:StartSQL()
	end
end

function Core:Lock()
	Core.Locked = true
	
	for k,v in pairs( player.GetAll() ) do
		v:Kick( Lang.AdminDataFailure )
	end
end

function Core:Assert( varType, szType )
	if varType and type( varType ) == "table" and varType[ 1 ] and type( varType[ 1 ] ) == "table" and varType[ 1 ][ szType ] then
		return true
	end
	
	return false
end

function Core:Null( varInput, varAlternate )
	if varInput and type( varInput ) == "string" and varInput != "NULL" then
		return varInput
	end
	
	return varAlternate or nil
end

function Core:Print( szPrefix, szText )
	print( "[" .. (szPrefix or "Core") .. "]", szText )
end


function Core:AddResources()
	-- To-Do: Add any other materials here
end


function Core:Send( ply, szAction, varArgs )
	net.Start( Core.Protocol )
	net.WriteString( szAction )
	
	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.Send( ply )
end

function Core:Broadcast( szAction, varArgs, varExclude )
	net.Start( Core.Protocol )
	net.WriteString( szAction )
	
	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	if varExclude and (type( varExlude ) == "table" or (IsValid( varExclude ) and varExclude:IsPlayer())) then
		net.SendOmit( varExclude )
	else
		net.Broadcast()
	end
end


local function CoreHandle( ply, szAction, varArgs )
	if szAction == "Admin" then
		Admin:HandleClient( ply, varArgs )
	elseif szAction == "MapList" then
		RTV:GetMapList( ply, varArgs[ 1 ] )
	elseif szAction == "Vote" then
		RTV:ReceiveVote( ply, varArgs[ 1 ], varArgs[ 2 ] )
	elseif szAction == "Radio" then
		Radio:HandleClient( ply, varArgs )
	end
end

local function CoreReceive( _, ply )
	local szAction = net.ReadString()
	local bTable = net.ReadBit() == 1
	local varArgs = {}
	
	if bTable then
		varArgs = net.ReadTable()
	end
	
	if IsValid( ply ) and ply:IsPlayer() then
		CoreHandle( ply, szAction, varArgs )
	end
end
net.Receive( Core.Protocol, CoreReceive )

local function BinaryReceive( l, ply )
	local length = net.ReadUInt( 32 )
	local data = net.ReadData( length )
	
	if IsValid( ply ) then
		local target = Admin.Screenshot[ ply ]
		if IsValid( target ) then
			net.Start( Core.Protocol2 )
			net.WriteString( "Data" )
			net.WriteUInt( length, 32 )
			net.WriteData( data, length )
			net.Send( target )
			
			Admin.Screenshot[ ply ] = nil
		end
	end
end
net.Receive( Core.Protocol2, BinaryReceive )


--- SQL ---

SQL = {}
SQL.Available = false

local SQLObject
local SQLDetails = {
	Host = "127.0.0.1", Port = 3306,
	User = "root", Pass = "",
	Database = "flow_gmod"
}

local function SQL_Print( szMsg, varArg )
	print( szMsg, varArg or "" )
end

local function SQL_ConnectSuccess( fCallback )
	SQL.Available = true
	SQL.Busy = false
	
	SQL_Print( "[SQL Connect] Connected to " .. string.upper( SQLDetails.Host ) .. " successfully (User: " .. string.upper( SQLDetails.User ) .. ")" )
	
	fCallback()
end

local function SQL_ConnectFailure( obj, szError )
	SQL.Available = false
	SQL.Busy = false
	
	SQL_Print( "[SQL Connect] Failed to connect: ", szError )
end

local function SQL_Query( szQuery, fCallback, varArgs )
	if not SQLObject or not SQL.Available then
		return SQL_Print( "No valid SQLObject to execute query: ", szQuery )
	elseif not szQuery or szQuery == "" then
		return SQL_Print( "No valid SQLQuery to execute" )
	end

	local query = SQLObject:query( szQuery )
	local function fSuccess( obj, varData )
		if fCallback then
			fCallback( varData, varArgs )
		end
	end
	
	local function fError( obj, szError, szSQL )
		if fCallback then
			fCallback( nil, nil, szError or "" )
		end
		
		SQL_Print( "[SQL Error] " .. szError, "(On query: " .. szSQL .. ")" )
		
		if string.find( string.lower( szError ), "lost connection", 1, true ) or string.find( string.lower( szError ), "gone away", 1, true ) then
			SQL.Error = true
			return false
		end
	end
	
	query.onSuccess = fSuccess
	query.onError = fError
	query:start()
end

local function SQL_Execute( szQuery, fCallback, varArg )
	SQL_Query( szQuery, function( varData, varArgs, szError )
		fCallback( varData, varArgs, szError )
	end, varArg )
end

function SQL:CreateObject( SQL_ConnectCallback )
	local function SQL_SelectCallback()
		SQL_ConnectSuccess( SQL_ConnectCallback )
	end

	SQL.Busy = true
	
	SQLObject = mysqloo.connect( SQLDetails.Host, SQLDetails.User, SQLDetails.Pass, SQLDetails.Database, SQLDetails.Port )
	SQLObject.onConnected = SQL_SelectCallback
	SQLObject.onConnectionFailed = SQL_ConnectFailure
	SQLObject:connect()
end	
	
function SQL:Prepare( szQuery, varArgs, bNoQuote )
	if not SQLObject or not SQL.Available then
		SQL_Print( "No valid SQLObject to prepare query: " .. szQuery )
		return { Execute = function() end }
	end
	
	if varArgs and #varArgs > 0 then
		for i = 1, #varArgs do
			local sort = type( varArgs[ i ] )
			local num = tonumber( varArgs[ i ] )
			local arg = ""
			
			if sort == "string" and not num then
				arg = SQLObject:escape( varArgs[ i ] )
				if not bNoQuote then
					arg = "'" .. arg .. "'"
				end
			elseif (sort == "string" and num) or (sort == "number") then
				arg = varArgs[ i ]
			else
				arg = tostring( varArgs[ i ] ) or ""
				SQL_Print( "Parameter of type " .. sort .. " was parsed to a default value on query: " .. szQuery )
			end
			
			szQuery = string.gsub( szQuery, "{" .. i - 1 .. "}", arg )
		end
	end
	
	return { Query = szQuery, Execute = function( self, fCallback, varArg ) SQL_Execute( self.Query, fCallback, varArg ) end }
end