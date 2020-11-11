Records = {}
Records.Cache = {
	[Config.Modes["Auto"]] = {},
	[Config.Modes["Sideways"]] = {},
	[Config.Modes["W-Only"]] = {},
	[Config.Modes["Scroll"]] = {},
	[Config.Modes["Bonus"]] = {}
}

function Records:Init()
	local times = FS:Load( "times_" .. game.GetMap() .. ".txt", FS.Folders.Records, true )
	if not times or times == "" then return end
	
	local tabLines = string.Explode( "\n", times )
	if not tabLines or #tabLines < 2 then return end
	
	for i, szLine in ipairs( tabLines ) do
		if szLine == "" or szLine == "\n" then continue end
		local tabItem = FS.Deserialize:Records( szLine )
		table.insert( Records.Cache[ tabItem.Mode ], tabItem )
	end
end

function Records:Save()
	local szList = ""
	for _, mode in pairs( Records.Cache ) do
		for __, data in pairs( mode ) do
			szList = szList .. FS.Serialize:Records( data ) .. "\n"
		end
	end
	
	FS:Write( "times_" .. game.GetMap() .. ".txt", FS.Folders.Records, szList )
end


function Records:Add( ply, nTime, nOld, nMode )
	local tabRec = { UID = ply:UniqueID(), Name = ply:Name(), Time = nTime, Mode = nMode }
	local uid, rem, pos = ply:UniqueID(), 0, 0
	
	for p,d in pairs( Records.Cache[ nMode ] ) do
		if d.UID == uid then
			rem = p break
		end
	end
	if rem > 0 then table.remove( Records.Cache[ nMode ], rem ) end

	table.insert( Records.Cache[ nMode ], tabRec )
	table.sort( Records.Cache[ nMode ], function(a, b)
		return a.Time < b.Time
	end )

	for p,d in pairs( Records.Cache[ nMode ] ) do
		if d.UID == uid and d.Mode == nMode then
			pos = p break
		end
	end

	local strDisp = pos .. " / " .. #Records.Cache[ nMode ]
	if pos <= 10 then
		local tabRanks = { "st", "nd", "rd" }
		local strRank = pos .. (tabRanks[ pos ] or "th")
	
		ply:SendLua( "Timer:WR(" .. nTime .. "," .. nOld .. ",'" .. strRank .. "','" .. strDisp .. "'" .. (rem == pos and ",true" or "") .. ")" )
		if nOld == 0 then
			Message:Global( "PlayerWR", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), strDisp }, ply )
		elseif rem == pos then
			Message:Global( "PlayerWRDefend", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		else
			Message:Global( "PlayerWRImprove", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		end
		
		Bot:Stop( ply, nTime, strRank )
	else
		ply:SendLua( "Timer:PB(" .. nTime .. "," .. nOld .. ",'" .. strDisp .. "')" )
		if nOld == 0 then
			Message:Global( "PlayerFinish", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), Timer:Convert( nTime ), strDisp }, ply )
		else
			Message:Global( "PlayerImprove", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		end
	end
	
	Data:Global( "WRMode", { nMode, Records:GetWR( nMode ) } )
end

function Records:GetFullWR( ply )
	local tabData = {}
	for i = 1, 6 do
		if Records.Cache[ i ] then
			tabData[ i ] = Records:GetWR( i )
		end
	end

	Data:Single( ply, "WRFull", tabData )
end

function Records:GetWR( nMode )
	local tabSubmit = {}
	for i = 1, 10 do
		local tabData = Records.Cache[ nMode ][ i ]
		if tabData then table.insert( tabSubmit, { tabData.Name, tabData.Time } ) end
	end
	
	table.sort( tabSubmit, function(a, b)
		return a[2] < b[2]
	end )
	
	return tabSubmit
end


function Records:GetPlayer( uid, nMode )
	if not Records.Cache[ nMode ] then return nil end
	for _, data in pairs( Records.Cache[ nMode ] ) do
		if data.UID == uid and data.Mode == nMode then
			return data
		end
	end
	return nil
end