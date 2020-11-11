local PLAYER = FindMetaTable( "Player" )
local CT = CurTime
local SpawnCap = 350

Timer = {}

local function ValidTimer( ply, bBonus )
	if ply:IsBot() then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end
	
	return true
end


function PLAYER:StartTimer()
	self:SetInSpawn( false )

	if not ValidTimer( self ) then return end
	
	self.Tn = CT()
	Core.Util:SetPlayerJumps( self, 0 )
	Core:Send( self, "Timer", { "Start", self.Tn } )
end

function PLAYER:ResetTimer()
	if not ValidTimer( self ) then return end
	
	self.Tn = nil
	self.TnF = nil
	
	Core:Send( self, "Timer", { "Start" } )
end

function PLAYER:StopTimer()
	if not ValidTimer( self ) then return end
	if not self.Tn then return end
	self.TnF = CT()
	
	Core:Send( self, "Timer", { "Finish", self.TnF, self.TnF - self.Tn } )
	Timer:Finish( self, self.TnF - self.Tn )
end

function PLAYER:SetInSpawn( bValue )
	if bValue then
		local vel = self:GetVelocity()
		if vel:Length2D() > SpawnCap then
			local new = (vel / vel:Length2D()) * SpawnCap
			self:SetLocalVelocity( new )
		end
		
		Core.Util:SetSpeedCap( self, SpawnCap )
		Core:Send( self, "Timer", { "Speed", SpawnCap } )
		self:ResetTimer()
	else
		Core.Util:SetSpeedCap( self, _C.Player.BaseLimit )
		Core:Send( self, "Timer", { "Speed", _C.Player.BaseLimit } )
	end
end

function PLAYER:LimitVelocity( nLimit )
	local vel = self:GetVelocity()
	if vel:Length2D() > nLimit then
		local new = (vel / vel:Length2D()) * nLimit
		self:SetLocalVelocity( new )
	end
end


local TimerCache
function Timer:Init( bReload )
	Timer.Current = "deathrun/records/" .. game.GetMap() .. ".txt"

	file.CreateDir( "deathrun/records/" )
	
	if not file.Exists( Timer.Current, "DATA" ) then
		file.Write( Timer.Current, util.TableToJSON( {} ) )
		TimerCache = {}
	else
		local data = file.Read( Timer.Current, "DATA" )
		TimerCache = util.JSONToTable( data )
	end
	
	if not bReload then
		Timer:AddPlays()
		Timer:LoadRecords()
		
		Timer:SaveCache()
	end
end

function Timer:SaveCache()
	if not TimerCache then
		Timer:Init( true )
	end
	
	file.Write( Timer.Current, util.TableToJSON( TimerCache ) )
end

function Timer:AddPlays()
	if TimerCache.Plays then
		TimerCache.Plays = TimerCache.Plays + 1
	else
		TimerCache.Plays = 1
	end
end

function Timer:LoadRecords()
	if not TimerCache.Records then
		TimerCache.Records = {}
	end
end

function Timer:GetPlays()
	return TimerCache.Plays or 1
end


-- Records

function Timer:Finish( ply, nTime )
	Player:AddScore( ply )
	
	local pos = Timer:GetRecordPos( nTime )
	if pos >= 1 and pos <= 10 then
		local prev = Timer:GetPreviousTime( ply:SteamID() )
		if prev != 0 and nTime >= prev then
			Core:Send( ply, "Print", { "Deathrun", Lang:Get( "TimerSlower", { Timer:Convert( nTime ), Timer:Convert( nTime - prev ) } ) } )
		else
			Core:Broadcast( "Print", { "Deathrun", Lang:Get( "TimerRecord", { ply:Name(), pos, Timer:Convert( nTime ) } ) } )
			Timer:AddRecord( ply, pos, nTime, prev )
		end
	elseif ply:Team() == TEAM_UNDEAD then
		Core:Send( ply, "Print", { "Deathrun", Lang:Get( "TimerComplete", { Timer:Convert( nTime ) } ) } )
	end
end

function Timer:AddRecord( ply, pos, nTime, nPrev )
	if nPrev != 0 then
		local nRemove
		for p,data in pairs( TimerCache.Records ) do
			if data[ 2 ] == ply:SteamID() then
				nRemove = p
				break
			end
		end
		
		if nRemove then
			table.remove( TimerCache.Records, nRemove )
		end
	end

	local tab = { ply:Name(), ply:SteamID(), nTime, Core.Util:GetPlayerJumps( ply ), pos, Timer:GetDate() }
	table.insert( TimerCache.Records, pos, tab )
	
	if #TimerCache.Records > 10 then
		for i = 11, #TimerCache.Records + 1 do
			if TimerCache.Records[ i ] then
				TimerCache.Records[ i ] = nil
			end
		end
	end
	
	Timer:SaveCache()
end

function Timer:GetRecordPos( nTime )
	if #TimerCache.Records == 0 then return 1 end
	
	for pos,data in pairs( TimerCache.Records ) do
		if nTime <= data[ 3 ] then
			return pos
		end
	end
	
	return #TimerCache.Records + 1
end

function Timer:GetPreviousTime( steam )
	for pos,data in pairs( TimerCache.Records ) do
		if data[ 2 ] == steam then
			return data[ 3 ]
		end
	end
	
	return 0
end

function Timer:GetRecordList()
	return TimerCache.Records
end

-- Conversion

local fl, fo, od, ot = math.floor, string.format, os.date, os.time
function Timer:Convert( ns )
	return fo( "%.2d:%.2d.%.3d", fl( ns / 60 % 60 ), fl( ns % 60 ), fl( ns * 1000 % 1000 ) )
end

function Timer:GetDate()
	return od( "%Y-%m-%d %H:%M:%S", ot() )
end