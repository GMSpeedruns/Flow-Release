Spectator = {}
Spectator.OwnList = {}
Spectator.RemList = {}

Spectator.Data = {
	Contains = false,
	Bot = false,
	Player = "Bot",
	Start = nil,
	Best = nil
}

Spectator.Mode = 3

function Spectator:Clear()
	Spectator.OwnList = {}
	Spectator.RemList = {}
	if Client.ThirdPerson == 1 then Client.ThirdPerson = 0 end
	Spectator.Data = {
		Contains = false,
		Bot = false,
		Player = "Bot",
		Start = nil,
		Best = nil
	}
	Spectator.Mode = 3
end

function Spectator:RemoteSpec( list )
	Spectator.RemList = list
end

function Spectator:SetMode( nMode )
	Spectator.Mode = nMode
	
	if Spectator.Mode == 3 then
		Spectator:Clear()
	end
end


function Spectator:Viewer( data )
	if data[1] then
		if not Spectator.OwnList[ data[3] ] or Spectator.OwnList[ data[3] ] != data[2] then
			Spectator.OwnList[ data[3] ] = data[2]
		end
	else
		if Spectator.OwnList[ data[3] ] then
			Spectator.OwnList[ data[3] ] = nil
		end
	end
end

function Spectator:Timer( data )
	if not data[1] then
		if data[4] then
			Timer:Sync( tonumber(data[4]) )
		end
		
		if data[5] then
			if type( data[5] ) == "table" and #data[5] > 0 then
				Spectator:RemoteSpec( data[5] )
			end
		else
			Spectator:RemoteSpec( {} )
		end
		
		Spectator.Data.Bot = false
		Spectator.Data.Start = data[2] and tonumber(data[2]) + Timer.Difference or nil
		Spectator.Data.Best = data[3] and tonumber(data[3]) or 0
		Spectator.Data.Contains = true
	else
		if data[5] then
			Timer:Sync( tonumber(data[5]) )
		end

		if data[6] then
			if type( data[6] ) == "table" and #data[6] > 0 then
				Spectator:RemoteSpec( data[6] )
			end
		else
			Spectator:RemoteSpec( {} )
		end
		
		Spectator.Data.Bot = true
		Spectator.Data.Player = data[3] or "Bot"
		Spectator.Data.Start = data[2] and tonumber(data[2]) + Timer.Difference or nil
		Spectator.Data.Best = data[4] and tonumber(data[4]) or 0
		Spectator.Data.Contains = true
	end
end