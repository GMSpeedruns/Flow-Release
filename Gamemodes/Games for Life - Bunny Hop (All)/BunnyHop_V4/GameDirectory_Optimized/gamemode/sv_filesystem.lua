FS = {}
FS.Main = "DATA"
FS.Folders = {
	Log = "log/",
	Bot = "bot/",
	Maps = "maps/",
	Records = "records/",
	Players = "players/"
}
FS.Delimiter = ';*;'

resource.AddFile( "materials/bhop/timer.png" )


function FS:Init()
	FS:VerifyFolders()
	
	--timer.Create( "ScheduledChecker", 60, 0, FS.Scheduled )
end

function FS:Finalize()
	local szFile = "data_" .. game.GetMap() .. ".txt"
	FS:Write( "data_" .. game.GetMap() .. ".txt", FS.Folders.Maps, FS.Serialize:MapData( Map.Current ) )
	
	Player:Save()
	Records:Save()
	Bot:Save()
end

function FS.Scheduled()
	--print( "Scheduled check at " .. CurTime() )
end


function FS:Load( szFile, szFolder, bCreate, bReport )
	if szFolder then
		szFile = szFolder .. szFile
	end
	
	if not file.Exists( szFile, FS.Main ) then
		if bCreate then
			file.Write( szFile, "" )
			return ""
		elseif bReport then
			Log:Error( "File " .. szFile .. " does not exist!" )
			return nil
		end
	end
	
	return file.Read( szFile, FS.Main )
end

function FS:Write( szFile, szFolder, szData, bCreate )
	if szFolder then
		szFile = szFolder .. szFile
	end
	
	if file.Exists( szFile, FS.Main ) and bCreate then
		Log:Warning( "File " .. szFile .. " already exist on Create option!" )
		return false
	end
	
	file.Write( szFile, szData )
	return true
end

function FS:VerifyFolders()
	for _, folder in pairs(FS.Folders) do
		if not file.Exists( folder, FS.Main ) then
			file.CreateDir( folder )
		end
	end
end


FS.Serialize = {}
function FS.Serialize:Join( tabInput )
	return string.Implode( FS.Delimiter, tabInput )
end

function FS.Serialize:JoinKeys( tabInput, tabKeys )
	local szOutput = ""
	for i = 1, #tabKeys do
		if type( tabInput[ tabKeys[ i ] ] ) == "Vector" then
			szOutput = szOutput .. GetVectorString( tabInput[ tabKeys[ i ] ], true )
		else
			szOutput = szOutput .. tabInput[ tabKeys[ i ] ]
		end
			
		if i != #tabKeys then szOutput = szOutput .. FS.Delimiter end
	end
	return szOutput
end

function FS.Serialize:MapData( tabMap )
	return self:JoinKeys( tabMap, { "Map", "Points", "StartA", "StartB", "EndA", "EndB", "Plays" } )
end

function FS.Serialize:Records( tabRec )
	return self:JoinKeys( tabRec, { "UID", "Name", "Time", "Mode" } )
end

function FS.Serialize:Player( tabPly )
	return self:JoinKeys( tabPly, { "Rank", "Points", "PlayCount", "BotRecord" } )
end

function FS.Serialize:BotInfo( tabBot )
	return self:JoinKeys( tabBot, { "Name", "Time", "Style" } )
end

function FS.Serialize:TriggerInfo( tabTrigger )
	return self:JoinKeys( tabTrigger, { "Map", "ID", "Data" } )
end

FS.Deserialize = {}
function FS.Deserialize:MapData( szInput )
	local Split = string.Explode( FS.Delimiter, szInput )
	local Base = { Map = Split[1], Points = tonumber( Split[2] ), StartA = ToVector( Split[3] ), StartB = ToVector( Split[4] ), EndA = ToVector( Split[5] ), EndB = ToVector( Split[6] ), Plays = 0 }
	
	if Split[7] then Base.Plays = tonumber( Split[7] ) end
	
	return Base
end

function FS.Deserialize:Records( szInput )
	local Split = string.Explode( FS.Delimiter, szInput )
	return { UID = Split[1], Name = Split[2], Time = tonumber( Split[3] ), Mode = tonumber( Split[4] ) }
end

function FS.Deserialize:Player( szInput )
	local Split = string.Explode( FS.Delimiter, szInput )
	return { Rank = tonumber( Split[1] ), Points = tonumber( Split[2] ), PlayCount = tonumber( Split[3] ), BotRecord = tonumber( Split[4] ) }
end

function FS.Deserialize:BotInfo( szInput )
	local Split = string.Explode( FS.Delimiter, szInput )
	return { Name = Split[1], Time = tonumber( Split[2] ), Style = tonumber( Split[3] ) }
end

function FS.Deserialize:TriggerInfo( szInput )
	local Split = string.Explode( FS.Delimiter, szInput )
	return { Map = Split[1], ID = tonumber( Split[2] ), Data = Split[3] }
end