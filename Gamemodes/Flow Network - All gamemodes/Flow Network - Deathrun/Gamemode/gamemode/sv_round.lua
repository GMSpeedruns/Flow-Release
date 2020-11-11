Round = {}
Round.WAITING = 0
Round.PREPARING = 1
Round.ACTIVE = 2
Round.ENDING = 3
Round.EMPTY = 4

Round.ROUND_COUNT = 10
Round.ROUND_TIME = 360

local Instance = {}
Instance.Current = Round.WAITING
Instance.Remaining = Round.ROUND_COUNT
Instance.Time = 5

SetGlobalInt( "RoundTime", 0 )

function Round:Init()
	Instance.Remaining = Round.ROUND_COUNT
end

function Round:Extend( nCount )
	Instance.Remaining = nCount or (Round.ROUND_COUNT / 2)
	Core:Broadcast( "Client", { "Round", Instance.Remaining, "" } )
end


local RoundProcess = {
	[Round.WAITING] = function()
		Core:Broadcast( "Print", { "Deathrun", Lang:Get( "PlayerMissing" ) } )
		Round:SetRoundTime( 0 )
	end,
	
	[Round.PREPARING] = function()
		if RTV.ChangeMap then
			RTV:Change()
		else
			game.CleanUpMap()
			Zones:Setup()
			
			Round:SetRoundTime( 5 )
			Player:Sort()
			
			local rounds = math.max( Instance.Remaining, 0 )
			if rounds > 0 then
				local extra = "s"
				if rounds == 1 then extra = "" end
				Core:Broadcast( "Client", { "Round", rounds, Lang:Get( "RoundChange", { rounds, extra } ) } )
			end
		end
	end,
	
	[Round.ACTIVE] = function()
		Round:SetRoundTime( Round.ROUND_TIME )
		
		Core:Broadcast( "Print", { "Deathrun", Lang:Get( "StartRound" ) } )
		
		for _,p in pairs( player.GetHumans() ) do
			p:Freeze( false )
			Player:Loadout( p )
		end
	end,
	
	[Round.ENDING] = function( te )
		Round:SetRoundTime( 5 )
		
		local lang = te < 0 and Lang:Get( "EndTime" ) or Lang:Get( "TeamVictory", { team.GetName( te ) } )
		Core:Broadcast( "Print", { "Deathrun", lang } )
		
		local msg = te < 0 and "Time is up!" or team.GetName( te ) .. " are victorious"
		Core:Broadcast( "Client", { "Victory", { msg, team.GetColor( te ) } } )
		
		if te == TEAM_DEATH then
			for _,v in pairs( team.GetPlayers( te ) ) do
				if v.PS_GivePoints then
					v:PS_GivePoints( 10 )
				end
			end
		end
		
		local rounds = math.max( Instance.Remaining - 1, 0 )
		Instance.Remaining = rounds
		
		if rounds < 1 then
			RTV:StartVote()
		end
	end,
	
	[Round.EMPTY] = function( ply )
		Player:SpawnUndead( ply, true )
		Core:Send( ply, "Print", { "Deathrun", Lang:Get( "SingleRunner" ) } )
	end
}

local RoundAFKChecked = false
local RoundThink = {
	[Round.WAITING] = function()
		local ar = player.GetHumans()
		local count = #ar
		if count > 1 then
			Round:SetRound( Round.PREPARING )
		elseif count == 1 then
			Round:SetRound( Round.EMPTY, ar[ 1 ] )
		end
	end,
	
	[Round.PREPARING] = function()
		if Round:GetRoundTime() <= 0 then
			if #player.GetHumans() > 1 then
				Round:SetRound( Round.ACTIVE )
			else
				Round:SetRound( Round.WAITING )
			end
		end
	end,
	
	[Round.ACTIVE] = function()
		local remaining = Round:GetRoundTime()
		if remaining <= 0 then
			return Round:SetRound( Round.ENDING, -1 )
		elseif not RoundAFKChecked and remaining <= Round.ROUND_TIME * 0.5 then
			RoundAFKChecked = true
			
			for _,p in pairs( player.GetHumans() ) do
				if p:Alive() and not p.HasPressedKey then
					p.HasPressedKey = true
					p:Kill()
					Core:Broadcast( "Print", { "Deathrun", Lang:Get( "AFKKill", { p:Name(), "" } ) } )
				end
			end
		end
		
		if Player:CountAlive( TEAM_RUNNER ) == 0 then
			Round:SetRound( Round.ENDING, TEAM_DEATH )
		elseif Player:CountAlive( TEAM_DEATH ) == 0 then
			Round:SetRound( Round.ENDING, TEAM_RUNNER )
		end
	end,
	
	[Round.ENDING] = function()
		if Round:GetRoundTime() <= 0 then
			RoundAFKChecked = false
			Round:SetRound( Round.PREPARING )
		end
	end,
	
	[Round.EMPTY] = function()
		local count = #player.GetHumans()
		if count > 1 then
			Round:SetRound( Round.PREPARING )
		elseif count == 0 then
			Round:SetRound( Round.WAITING )
		end
	end
}

function Round:SetRound( round, args )
	Instance.Current = round
	
	if RoundProcess[ round ] then
		RoundProcess[ round ]( args )
	end
end

function Round:GetRound()
	return Instance.Current
end

function Round:SetRounds( rounds )
	Instance.Current = rounds
end

function Round:SetRoundTime( remaining )
	remaining = remaining or 5
	Instance.Time = RealTime() + remaining
	Core:Broadcast( "Client", { "RoundTime", remaining } )
end

local mm = math.max
function Round:GetRoundTime()
	return mm( Instance.Time - RealTime(), 0 )
end


function GM:Think()
	self.BaseClass:Think()
	
	local current = Instance.Current
	if current != Round.WAITING then
		local count = #player.GetHumans()
		if count < 2 and current != Round.EMPTY then
			return Round:SetRound( Round.WAITING )
		end
	end
	
	if RoundThink[ current ] then
		RoundThink[ current ]()
	end
end