FS = {}
FS.Main = "DATA"
FS.Folders = {
	Log = "log/",
	Bot = "bot/",
	Maps = "maps/",
	Records = "records/",
	Players = "players/",
	Radio = "radio/"
}

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
	for _, folder in pairs( FS.Folders ) do
		if not file.Exists( folder, FS.Main ) then
			file.CreateDir( folder )
		end
	end
end


FS.Serialize = {}
function FS.Serialize:Join( tabInput )
	return util.TableToJSON( tabInput )
end

--[[
NOTE: This whole file is actually useless since I've updated everything to use TableToJSON because it's just better and faster.

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
]]

function FS.Serialize:MapData( tabMap )
	return self:Join( tabMap ) -- { "Map", "Points", "StartA", "StartB", "EndA", "EndB", "Plays" }
end

function FS.Serialize:Records( tabRec )
	return self:Join( tabRec ) -- { "UID", "Name", "Time", "Mode" }
end

function FS.Serialize:Player( tabPly )
	return self:Join( tabPly ) -- { "Rank", "Points", "PlayCount", "BotRecord" }
end

function FS.Serialize:BotInfo( tabBot )
	return self:Join( tabBot ) -- { "Name", "Time", "Style" }
end

function FS.Serialize:TriggerInfo( tabTrigger )
	return self:Join( tabTrigger ) -- { "Map", "ID", "Data" }
end

function FS.Serialize:AdminInfo( tabAdmin )
	return self:Join( tabAdmin ) -- { "UID", "Access" }
end

function FS.Serialize:RadioEntry( tabRadio )
	return self:Join( tabRadio )
end

FS.Deserialize = {}
function FS.Deserialize:Get( szInput )
	return util.JSONToTable( szInput )
end

function FS.Deserialize:MapData( szInput )
	local tabOutput = self:Get( szInput )
	
	if not tabOutput.Plays then
		tabOutput.Plays = 0
	end
	
	return tabOutput
end

function FS.Deserialize:Records( szInput )
	return self:Get( szInput )
end

function FS.Deserialize:Player( szInput )
	return self:Get( szInput )
end

function FS.Deserialize:BotInfo( szInput )
	return self:Get( szInput )
end

function FS.Deserialize:TriggerInfo( szInput )
	return self:Get( szInput )
end

function FS.Deserialize:AdminInfo( szInput )
	return self:Get( szInput )
end

function FS.Deserialize:RadioEntry( szInput )
	return self:Get( szInput )
end