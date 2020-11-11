Radio = {}
Radio.Protocol = "Radio"

Radio.Root = "http://93.104.209.200/radio/"
Radio.Files = Radio.Root .. "data/"
Radio.Action = Radio.Root .. "?id="

Radio.CopyRoot = "http://radio.gflclan.com/"
Radio.CopyAction = Radio.CopyRoot .. "get.php?id="

Radio.PlaybackBase = Radio.CopyRoot .. "mp3/"
Radio.YouTubeBase = {
	"http://www.youtube.com/watch?v=",
	"https://www.youtube.com/watch?v=",
	"http://youtu.be/",
	"https://youtu.be/"
}

Radio.ErrorCodesA = {
	[100] = "Invalid ID Supplied",
	[101] = "Invalid ID Supplied",
	[1] = "This video is not available in for playback in this country.",
}

Radio.ErrorCodesB = {
	[1] = "Unable to retrieve remote MP3. Try again.",
	[2] = "Unable to write to disk. Try again.",
	[4] = "Invalid file info retrieved. Try again.",
	[5] = "File info was empty. Try again.",
	[9] = "Impossible error. Try again!",
}

util.AddNetworkString( Radio.Protocol )

local RadioList = {}
local RadioPage = 25

function Radio:Init()
	RadioList = {}
	
	local Content = FS:Load( "RadioCache.txt", FS.Folders.Radio, true )
	if not Content or Content == "" then return end
	
	local Lines = string.Explode( "\n", Content )
	for _, data in pairs( Lines ) do
		local tab = FS.Deserialize:RadioEntry( data )
		table.insert( RadioList, tab )
	end
end

function Radio:Save()
	local tabList = {}
	
	for _, entry in pairs( RadioList ) do
		table.insert( tabList, FS.Serialize:RadioEntry( entry ) )
	end
	
	local szData = string.Implode( "\n", tabList )
	FS:Write( "RadioCache.txt", FS.Folders.Radio, szData )
end


function Radio:AddToList( szID, nDuration, szTitle )
	local tabNew = { ID = szID, Duration = nDuration, Title = szTitle }
	table.insert( RadioList, tabNew )
	
	Radio:Save()
end

function Radio:GetPage( nPage )
	local nCount = #RadioList
	if nPage * RadioPage - RadioPage >= nCount then return nil end
	
	local Send, Start = {}, (nPage - 1) * RadioPage + 1
	for i = Start, Start + RadioPage - 1 do
		if not RadioList[i] then break end
		table.insert( Send, RadioList[i] )
	end
	
	return Send
end

function Radio:FindInList( szQuery )
	local find = nil
	szQuery = string.lower( szQuery )
	
	local added = 0
	for _, data in pairs( RadioList ) do
		if added >= RadioPage then break end
		if string.find( string.lower( data.Title ), szQuery, 1, true) then
			if not find then find = {} end
			table.insert( find, data )
			added = added + 1
		end
	end

	return find
end


function Radio:AddSong( ply, szURL )
	if not Radio:ValidateURL( szURL ) then
		return Message:Single( ply, "Generic", Config.Prefix.Radio, { "You have entered an invalid YouTube URL: " .. szURL } )
	end
	
	local szID = Radio:ExtractID( szURL )
	if not szID or #szID != 11 then
		return Message:Single( ply, "Generic", Config.Prefix.Radio, { "You have entered an invalid YouTube ID: " .. szURL } )
	end
	
	if Radio:IsExist( szID ) then
		return Message:Single( ply, "Generic", Config.Prefix.Radio, { "This video already exists in the download list. Use search!" } )
	end
	
	Message:Single( ply, "Generic", Config.Prefix.Radio, { "Now trying to download video. You will be notified shortly." } )
	
	local szTarget = Radio.Action .. szID
	http.Fetch( szTarget, 
		function( body, length, headers, code )
			if body and body != "" then
				if body == "0" then
					-- 0 - Success or pre-exist
					-- 100 - Invalid ID
					-- 101 - Very invalid ID
					-- Other - Conversion error
					Radio:AddSongGet( ply, szID )
				else
					if not tonumber( body ) then
						Message:Single( ply, "Generic", Config.Prefix.Radio, { "Received an invalid download response: " .. string.sub(body, 1, 3) .. " - Try again or pick a different video" } )
					else
						local ErrorCode = Radio.ErrorCodesA[ tonumber( body ) ]
						if ErrorCode then
							Message:Single( ply, "Generic", Config.Prefix.Radio, { "The following error occurred while downloading your video: " .. ErrorCode } )
						else
							Message:Single( ply, "Generic", Config.Prefix.Radio, { "Received an invalid response: " .. string.sub(body, 1, 3) .. " - Report to Gravious with Video ID (" .. szID .. " and response)" } )
						end
					end
				end
			else
				Message:Single( ply, "Generic", Config.Prefix.Radio, { "Your video could not be resolved. Please try again later." } )
			end
		end,
		function( err )
			Message:Single( ply, "Generic", Config.Prefix.Radio, { "Your video could not be resolved. Please try again later." } )
		end
	)
end

function Radio:AddSongGet( ply, szID )
	local szTarget = Radio.CopyAction .. szID
	http.Fetch( szTarget, 
		function( body, length, headers, code )
			if body and body != "" then
				local code = string.sub(body, 1, 1)
				if code == "0" or code == "3" then
					-- 0 - First download, mp3 was written
					-- 1 - First download, can't get MP3
					-- 2 - First download, failed to write data
					-- 3 - MP3 Already exists locally
					-- 4 - .info file doesn't have correct JSON format
					-- 5 - .info file is empty
					-- 9 - Weird error, file doesn't exist after successful write
					Radio:AddSongFinish( ply, code, body )
				else
					if not tonumber( code ) then
						Message:Single( ply, "Generic", Config.Prefix.Radio, { "Received an invalid response: " .. code .. " - Try again!" } )
					else
						local ErrorCode = Radio.ErrorCodesB[ tonumber( code ) ]
						if ErrorCode then
							Message:Single( ply, "Generic", Config.Prefix.Radio, { "The following error occurred while downloading your video file: " .. ErrorCode } )
						else
							Message:Single( ply, "Generic", Config.Prefix.Radio, { "Received an invalid response: " .. string.sub(body, 1, 3) .. " - Report to Gravious with Video ID (" .. szID .. " and response ID)" } )
						end
					end
				end
			else
				Message:Single( ply, "Generic", Config.Prefix.Radio, { "Your video could not be resolved. Please try again later." } )
			end
		end,
		function( err )
			Message:Single( ply, "Generic", Config.Prefix.Radio, { "Your video could not be resolved. Please try again later." } )
		end
	)
end

function Radio:AddSongFinish( ply, code, body )
	local data = string.Explode( "\n", body )
	if #data == 4 then
		Radio:AddToList( data[2], tonumber( data[3] ), data[4] )
		Message:Single( ply, "Generic", Config.Prefix.Radio, { "Your video has successfully been downloaded and added!" } )
	else
		Message:Single( ply, "Generic", Config.Prefix.Radio, { "An unexpected error occurred while adding your video. Report to Gravious if you can." } )
	end
end


function Radio:ValidateURL( szURL )
	for _, base in pairs( Radio.YouTubeBase ) do
		if string.sub( szURL, 1, #base ) == base then
			return true
		end
	end

	return false
end

function Radio:ExtractID( szURL )
	for _, base in pairs( Radio.YouTubeBase ) do
		if string.sub( szURL, 1, #base ) == base then
			return string.sub( szURL, #base + 1, #szURL )
		end
	end
end

function Radio:IsExist( szID )
	local bDefault = false

	for _, data in pairs( RadioList ) do
		if tostring( szID ) == tostring( data.ID ) then
			bDefault = true
			break
		end
	end
	
	return bDefault
end

function Radio.CommandProcess( ply, args )
	if #args == 0 then
		ply:SendLua( "Window:Open('Radio')" )
	else
		local szID = args[1]

		if szID == "help" then
			Message:Single( ply, "Generic", Config.Prefix.Radio, { "Test" } )
		end
	end
end

function Radio:Send( ply, szIdentifier, varArgs )
	net.Start( Radio.Protocol )
	net.WriteString( szIdentifier )
	
	if varArgs and type( varArgs ) == "table" and #varArgs > 0 then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.Send( ply )
end

function Radio.Receive( nLength, ply )
	local nID = net.ReadInt(16)
	local varArgs = net.ReadTable()
	if not nID then return end
	
	if nID == 0 then
		if not varArgs[1] or not tonumber( varArgs[1] ) then return end
		local varData = Radio:GetPage( tonumber( varArgs[1] ) )
		Radio:Send( ply, "Open", { Radio.PlaybackBase, varData, math.ceil( #RadioList / RadioPage ) } )
	elseif nID == 1 then
		if not varArgs[1] or not tonumber( varArgs[1] ) or not varArgs[2] or not tonumber( varArgs[2] ) then return end
		local nPage, nDirection = tonumber( varArgs[1] ) or 1, tonumber( varArgs[2] ) or 0
		
		if nDirection == 0 then
			local varData = Radio:GetPage( nPage )
			Radio:Send( ply, "Update", { nPage, varData, math.ceil( #RadioList / RadioPage ) } )
		elseif nDirection == 1 then
			local nNew = nPage + nDirection
			local varData = Radio:GetPage( nNew )
			if varData then
				Radio:Send( ply, "Update", { nNew, varData, math.ceil( #RadioList / RadioPage ) } )
			end
		elseif nDirection == -1 then
			local nNew = nPage + nDirection
			if nNew < 1 then nNew = 1 end
			local varData = Radio:GetPage( nNew )
			if varData then
				Radio:Send( ply, "Update", { nNew, varData, math.ceil( #RadioList / RadioPage ) } )
			end
		end
	elseif nID == 2 then
		if not varArgs[1] or varArgs[1] == "" then return end
		local varData = Radio:FindInList( varArgs[1] ) or {}
		Radio:Send( ply, "Search", { varData } )
	elseif nID == 11 then
		if not varArgs[1] then return end
		
		Radio:AddSong( ply, varArgs[1] )
	end
end
net.Receive( Radio.Protocol, Radio.Receive )