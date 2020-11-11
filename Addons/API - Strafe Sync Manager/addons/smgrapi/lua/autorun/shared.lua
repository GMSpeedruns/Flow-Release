if SERVER then
	AddCSLuaFile( "client.lua" )
	include( "server.lua" )
elseif CLIENT then
	include( "client.lua" )
end