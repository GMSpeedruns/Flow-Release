-- This file needs some more set-up knowledge
-- You must own a server that runs on Windows and has a webserver (Apache) running on it

-- Set Radio.Path to your /radio directory. For example: Radio.Path = "http://mywebsite.com/radio/"
-- Make sure the /radio directory then contains the files provided in the post you got this gamemode from: post.php, processing files and the radio/data/ folder

-- Now, to enable searching on YouTube and Grooveshark, you must obtain a Google API Key and a TinySong API Key. Visit these pages for that:
-- * https://console.developers.google.com/project -> Create Project -> APIs & auth -> Credentials -> Key for server applications -> API KEY + Also add IPs
-- * http://tinysong.com/api -> Request an API Key

-- Once the keys are inserted in this file, the radio should automatically work
-- If you can add songs, but the radio doesn't process them, check all relevant files on the server

Radio = {}
Radio.Idle = true

Radio.Path = ""
Radio.Submit = Radio.Path .. "post.php"
Radio.Files = Radio.Path .. "data/"

Radio.GoogleAPIKey = ""
Radio.TinyAPIKey = ""
Radio.FetchCount = 25

local RadioCache = {}
local RadioTickets = {}
local DurationCache = {}
local SearchCache
local LastTicketUpdate = CurTime()


local function SearchYouTube( ply, szText )
	local szSearch = Admin:URLEncode( szText )
	local szPath = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=" .. szSearch .. "&maxResults=" .. Radio.FetchCount .. "&order=viewCount&type=video&key=" .. Radio.GoogleAPIKey
	Admin:ExecuteRequest( szPath, function( body )
		if body and body != "" then
			local tab = util.JSONToTable( body )
			local send = {}
			
			if not tab or not tab["pageInfo"] then
				local reason = "."
				if tab and tab["error"] and tab["error"]["errors"] and tab["error"]["errors"]["reason"] then
					reason = ": " .. tostring( tab["error"]["errors"]["reason"] ) .. "."
				end
					
				Core:Send( ply, "Print", { "Radio", "An error occurred while trying to access YouTube" .. reason } )
				print( "Page obtained was: ", body )
				return false
			end
			
			send.total = tab["pageInfo"]["totalResults"]
			send.items = tab["items"]
			send.display = #send.items
			
			for i,item in pairs( send.items ) do
				local video = item["id"]
				local id = video["videoId"]
				
				if id then
					local snippet = item["snippet"]
					local published = string.Explode( "T", snippet["publishedAt"] )[ 1 ]
					local channel = snippet["channelTitle"]
					local title = snippet["title"]
					
					if not channel or channel == "" then
						channel = "Google+ channel"
					end
					
					item = { id, title, channel, published }
				else
					item = nil
				end
				
				send.items[ i ] = item
			end
			
			Core:Send( ply, "Radio", { "Search", send, { 1, 2, "https://www.youtube.com/watch?v=" } } )
		end
	end, function( e )
		Core:Send( ply, "Print", { "Radio", "An error occurred while trying to access YouTube: " .. e } )
	end )
end

local function SearchTiny( ply, szText )
	local szSearch = Admin:URLEncode( szText )
	local szPath = "http://tinysong.com/s/" .. szSearch .. "?format=json&limit=" .. Radio.FetchCount .. "&key=" .. Radio.TinyAPIKey
	Admin:ExecuteRequest( szPath, function( body )
		if body and body != "" then
			local tab = util.JSONToTable( body )
			local send = {}
			
			send.items = tab
			send.display = #send.items
			send.total = send.display
			
			for i,item in pairs( send.items ) do
				local songId = item["SongID"]
				if songId and tonumber( songId ) then
					item = { songId, item["SongName"], item["ArtistName"], item["AlbumName"] }
				else
					item = nil
				end
				
				send.items[ i ] = item
			end
			
			Core:Send( ply, "Radio", { "Search", send, { 3, 3, "" } } )
		end
	end, function( e )
		Core:Send( ply, "Print", { "Radio", "An error occurred while trying to access Grooveshark: " .. e } )
	end )
end

local function GetStatusFrom( szID )
	local szStatus = "Unknown status: " .. szID
	
	if szID == "CREATE" then
		szStatus = "Created and processing"
	elseif szID == "TIMEOUT" then
		szStatus = "Ticket processing time exceeded"
	elseif szID == "FAIL_0" then
		szStatus = "Couldn't add song to database"
	elseif szID == "FAIL_1" then
		szStatus = "Processing module timed out (very busy, wait and try later)"
	elseif szID == "DONE" then
		szStatus = "Song download complete"
	end
	
	return szStatus
end

local function AddToCache( data )
end

local function ExistsInCurrent( entry )
	return true
end

-- Summary: Query heavy function that will change the status of a ticket and even add details of a song when that status marks DONE
local function SetQueueTicket( ticket, szType, varArgs )
	if szType == "TIMEOUT" then
		SQL:Prepare( "UPDATE gmod_radio_queue SET szStatus = {0} WHERE nTicket = {1}", { "TIMEOUT", ticket } ):Execute( function() end )
	elseif szType == "REMOVE" then
		SQL:Prepare( "DELETE FROM gmod_radio_queue WHERE nTicket = {0} AND nType = {1}", { ticket, varArgs[ 1 ] } ):Execute( function() end )
	elseif szType == "DONE" then
		SQL:Prepare( "DELETE FROM gmod_radio_queue WHERE nTicket = {0} AND nID = {1}", { ticket, varArgs[ 1 ] } ):Execute( function( data, varArg, szError )
			SQL:Prepare( "UPDATE gmod_radio SET szRequester = {0} WHERE nTicket = {1} AND nService = {3}", { varArg[ 3 ], varArg[ 1 ], varArg[ 2 ], varArg[ 4 ] } ):Execute( function() end )
			SQL:Prepare( "SELECT * FROM gmod_radio WHERE nTicket = {0} AND nService = {1} LIMIT 1", { varArg[ 1 ], varArg[ 4 ] } ):Execute( function( dataX, varArgX, szErrorX )
				if Core:Assert( dataX, "szUnique" ) then
					local item = dataX[ 1 ]
					local newEntry = { item["nService"], item["szUnique"], item["nDuration"], item["szTagTitle"], item["szTagArtist"] }
					if not ExistsInCurrent( newEntry ) then
						AddToCache( newEntry )
					end
					
					local ply = Admin:FindPlayer( varArgX )
					if IsValid( ply ) then
						Core:Send( ply, "Radio", { "Result", { newEntry }, true } )
					end
				end				
			end, varArg[ 3 ] )
		end, { ticket, varArgs[ 1 ], varArgs[ 2 ], varArgs[ 3 ] } )
	end
end

-- Summary: Periodic function that triggers every 5 seconds to load all active tickets and keeps notifying their respectful owners
local function UpdateAllTickets()
	SQL:Prepare(
		"SELECT * FROM gmod_radio_queue ORDER BY nID DESC"
	):Execute( function( data, varArg, szError )
		if data and #data > 0 then
			for _,item in pairs( data ) do
				local ticket = item["nTicket"]
				if RadioTickets[ ticket ] then
					local status = GetStatusFrom( item["szStatus"] )
					if status != RadioTickets[ ticket ][ 3 ] then
						RadioTickets[ ticket ][ 2 ] = CurTime()
						RadioTickets[ ticket ][ 3 ] = GetStatusFrom( item["szStatus"] )
						RadioTickets[ ticket ][ 4 ] = true
					end
					
					if item["szStatus"] == "DONE" then
						SetQueueTicket( ticket, "DONE", { item["nID"], RadioTickets[ ticket ][ 1 ], RadioTickets[ ticket ][ 6 ] } )
						RadioTickets[ ticket ][ 5 ] = true
					end
				elseif item["nType"] == tonumber( Admin.GamemodeKey ) then
					SetQueueTicket( ticket, "REMOVE", { item["nType"] } )
				end
			end
		end
	end )
end

local function TicketTicker()
	if Radio.Idle then return false end

	if CurTime() - LastTicketUpdate > 5 then
		UpdateAllTickets()
		LastTicketUpdate = CurTime()
	end
	
	local deleteTickets = {}
	for ticket,data in pairs( RadioTickets ) do
		if not data then continue end
		
		local ply = Admin:FindPlayer( data[ 1 ] )
		if IsValid( ply ) then
			if data[ 5 ] then
				Core:Send( ply, "Print", { "Radio", "Song download with ticket #" .. ticket .. " was completed succesfully!" } )
				
				table.insert( deleteTickets, ticket )
				ply.RadioActive = nil
			elseif data[ 4 ] then
				Core:Send( ply, "Print", { "Radio", "Status of your ticket #" .. ticket .. " was changed to: " .. data[ 3 ] } )
				RadioTickets[ ticket ][ 4 ] = false
			else
				local dt = CurTime() - data[ 2 ]
				if dt > 300 then
					Core:Send( ply, "Print", { "Radio", "Item with ticket #" .. ticket .. " took too long to process. Notifications will now stop. Song might still be downloaded!" } )
					SetQueueTicket( ticket, "TIMEOUT" )
					
					table.insert( deleteTickets, ticket )
					ply.RadioActive = nil
				end
			end
		else
			table.insert( deleteTickets, ticket )
		end
	end
	
	for _,ticket in pairs( deleteTickets ) do
		RadioTickets[ ticket ] = nil
	end
	
	local nCount = 0
	for _,t in pairs( RadioTickets ) do nCount = nCount + 1 end
	
	Radio.Idle = nCount == 0
end

function Radio:Setup()
	if Radio.Path != "" and Radio.GoogleAPIKey != "" and Radio.TinyAPIKey != "" then
		Radio.Prepared = true
	else
		return print( "[Gravious's spirit]", "The radio is not correctly setup. Please check the modules/sv_radio.lua file for instructions about this." )
	end
	
	if not SQL.Use then
		Radio.Prepared = false
		return print( "[Gravious's spirit]", "Since the radio isn't local, you'll need a working MySQL database to get this working." )
	end

	if timer.Exists( "RadioTicketChecker" ) then
		timer.Destroy( "RadioTicketChecker" )
	end

	timer.Create( "RadioTicketChecker", 1, 0, TicketTicker )
	
	if not Radio.Misc then
		Radio.Misc = { jiggy = Radio.Files .. "Misc_Jiggy.wav", mate = Radio.Files .. "Misc_Mate.wav", problem = Radio.Files .. "Misc_Problem.wav", rude = Radio.Files .. "Misc_Rude.wav", target = { "STEAM_0:0:37549378", "STEAM_0:0:122758484", "STEAM_0:1:25992854" } } -- Yes, you can change this is you know what it does. And if you do, don't blatantly use it. Use it so it still stays funny. Leaving my Steam ID in there would keep me happy :)
	end
end

function Radio.CommandProcess( ply, args )
	if not Radio.Prepared then return Core:Send( ply, "Print", { "General", "The radio is not correctly setup. Please ask the server owner for this." } ) end
	
	if #args == 0 then
		Core:Send( ply, "Radio", { "Open", Radio.Files .. "t" } )
	else
		local search = string.Implode( " ", args.Upper )
		-- Summary: Searches the radio databases and returns all results in the form of a radioEntry structure
		SQL:Prepare(
			"SELECT * FROM gmod_radio WHERE szTagTitle LIKE '%{0}%' OR szTagArtist LIKE '%{0}%' OR szUnique LIKE '%{0}%' LIMIT 1",
			{ search },
			true
		):Execute( function( data, varArg, szError )
			if data and #data > 0 then
				local p = varArg[ 1 ]
				local s = varArg[ 2 ]
				
				local tabItem
				for _,item in pairs( data ) do
					local newEntry = { item["nService"], item["szUnique"], item["nDuration"], item["szTagTitle"], item["szTagArtist"] }
					if not ExistsInCurrent( newEntry ) then
						AddToCache( newEntry )
					end
					
					tabItem = newEntry
					break
				end
				
				if tabItem then
					Core:Send( p, "Radio", { "Single", tabItem } )
				else
					Core:Send( p, "Print", { "Radio", "A strange error occurred while retrieving your song!" } )
				end
			else
				Core:Send( p, "Print", { "Radio", "No results found for your search query: " .. s } )
			end
		end, { ply, search } )
	end
end

function Radio:HandleClient( ply, varArgs )	
	local szType = tostring( varArgs[ 1 ] )
	
	if not Radio.Prepared then
		if szType != "Initialize" then
			return Core:Send( ply, "Print", { "General", "The radio is not correctly setup. Please ask the server owner for this." } )
		else
			return false
		end
	end
	
	if szType == "Add" then
		local nType = tonumber( varArgs[ 2 ] )
		local szURL = tostring( varArgs[ 3 ] )
		
		if nType > 100 then
			if nType == 102 then
				SearchYouTube( ply, szURL )
			elseif nType == 103 then
				SearchTiny( ply, szURL )
			end
		else
			if ply.RadioActive then
				return Core:Send( ply, "Print", { "Radio", "You still have an active ticket assigned to you. Please wait for it to finish." } )
			end
			
			Radio.Idle = false
			Core:Send( ply, "Print", { "Radio", "Processing your request. Please wait, you will be notified soon." } )
			
			local szPath = Radio.Submit .. "?Type=" .. nType .. "&URL=" .. Admin:URLEncode( szURL )
			if nType == 3 then
				local tabDetail = varArgs[ 4 ]
				if tabDetail then
					szPath = szPath .. "&Song=" .. Admin:URLEncode( tabDetail[ 2 ] ) .. "&Artist=" .. Admin:URLEncode( tabDetail[ 3 ] )
				end
			end
			
			Admin:ExecuteRequest( szPath, function( body )
				Radio.Idle = false
				
				local key = string.sub( body, 1, 4 )
				if key == "S000" then
					local ticket = tonumber( string.sub( body, 24, 30 ) )
					RadioTickets[ ticket ] = { ply:SteamID(), CurTime(), "Ticket submitted. Waiting for response.", true, nil, nType }
					
					Core:Send( ply, "Print", { "Radio", "Your song is now being prepared under ticket #" .. ticket } )
					ply.RadioActive = true
				else
					local details = string.sub( body, 7 )
					if key == "S001" then
						Core:Send( ply, "Print", { "Radio", "This song has already been added to our database!" } )
						
						local tab = string.Explode( ";", details )
						local tabEntry = { tonumber( tab[ 2 ] ), tab[ 1 ], tonumber( tab[ 3 ] ), tab[ 4 ], tab[ 5 ] }
						if not ExistsInCurrent( tabEntry ) then
							AddToCache( tabEntry )
						end
					elseif key == "S002" then
						Core:Send( ply, "Print", { "Radio", "There is already an active ticket for this song! Please wait for it to finish downloading and try again." } )
					else
						Core:Send( ply, "Print", { "Radio", "Couldn't start request (Reason: " .. details .. ")" } )
					end
				end
			end, function( e )
				Core:Send( ply, "Print", { "Radio", "An unexpected error occurred while submitting, please try again. (Error: " .. e .. ")" } )
			end )
		end
	elseif szType == "Search" then
		local search = varArgs[ 2 ]
		local query = "SELECT * FROM gmod_radio WHERE szTagTitle LIKE '%{0}%' OR szTagArtist LIKE '%{0}%' OR szUnique LIKE '%{0}%' LIMIT " .. Radio.FetchCount
		if search and search == "*" or string.lower( search ) == "all" or string.lower( search ) == "list" then
			if not SearchCache then
				search = "all"
				query = "SELECT * FROM gmod_radio ORDER BY szTagTitle ASC LIMIT 250"
			else
				if #SearchCache > 0 then
					return Core:Send( ply, "Radio", { "Result", SearchCache } )
				else
					return Core:Send( ply, "Print", { "Radio", "There are no songs available in the radio." } )
				end
			end
		end
	
		-- Summary: Searches the radio databases and returns all results in the form of a radioEntry structure
		SQL:Prepare(
			query,
			{ search },
			true
		):Execute( function( data, varArg, szError )
			if data and #data > 0 then
				local p = varArg[ 1 ]
				local s = varArg[ 2 ]
				
				local tabSend = {}
				for _,item in pairs( data ) do
					local newEntry = { item["nService"], item["szUnique"], item["nDuration"], item["szTagTitle"], item["szTagArtist"] }
					if not ExistsInCurrent( newEntry ) then
						AddToCache( newEntry )
					end
					
					table.insert( tabSend, newEntry )
				end
				
				if s == "all" then
					SearchCache = tabSend
				end
				
				Core:Send( p, "Radio", { "Result", tabSend } )
			else
				Core:Send( p, "Print", { "Radio", "No results found for your search query: " .. varArg[ 2 ] } )
			end
		end, { ply, search } )
	elseif szType == "Length" then
		local item = varArgs[ 2 ]
		if not tonumber( item[ 1 ] ) or not item[ 2 ] or not tonumber( item[ 3 ] ) then return end
		
		local serviceId = item[ 1 ] .. "_" .. item[ 2 ]
		if DurationCache[ serviceId ] then return end
		
		-- Summary: Updates the duration of a song when this was initially determined incorrectly
		SQL:Prepare(
			"UPDATE gmod_radio SET nDuration = {0} WHERE nService = {1} AND szUnique = {2}",
			{ tonumber( item[ 3 ] ), tonumber( item[ 1 ] ), item[ 2 ] }
		):Execute( function( data, varArg, szError )
			if data then
				DurationCache[ varArg ] = true
			end
		end, serviceId )
	elseif szType == "Initialize" then
		Core:Send( ply, "Radio", { "Initialize", Radio.Files .. "t" } )
	end
end