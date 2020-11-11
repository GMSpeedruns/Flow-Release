Message = {}
Message.Protocol = "Message"

util.AddNetworkString( Message.Protocol )

function Message:Single( ply, szIdentifier, nPrefix, varArgs )
	net.Start( Message.Protocol )
	net.WriteInt( nPrefix, 6 )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.Send( ply )
end

function Message:Global( szIdentifier, nPrefix, varArgs, varExclude )
	net.Start( Message.Protocol )
	net.WriteInt( nPrefix, 6 )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
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


Data = {}
Data.Protocol = "Data"

util.AddNetworkString( Data.Protocol )

function Data:Single( ply, szIdentifier, varArgs )
	net.Start( Data.Protocol )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.Send( ply )
	
	Data:ResetProtocol()
end

function Data:Global( szIdentifier, varArgs, varExclude )
	net.Start( Data.Protocol )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
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
	
	Data:ResetProtocol()
end

function Data:SetProtocol( szProtocol )
	Data.Protocol = szProtocol
end

function Data:ResetProtocol()
	Data:SetProtocol( "Data" )
end