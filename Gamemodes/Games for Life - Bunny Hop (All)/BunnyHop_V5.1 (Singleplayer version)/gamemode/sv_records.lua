Records = {}

local RecordsCache = {
	[Config.Modes["Auto"]] = {},
	[Config.Modes["Sideways"]] = {},
	[Config.Modes["W-Only"]] = {},
	[Config.Modes["Scroll"]] = {},
	[Config.Modes["Bonus"]] = {}
}

local RankSuffixes = { "st", "nd", "rd" }


function Records:Init()
	local times = FS:Load( "times_" .. game.GetMap() .. ".txt", FS.Folders.Records, true )
	if not times or times == "" then return end
	
	local tabLines = string.Explode( "\n", times )
	if not tabLines or #tabLines < 2 then return end
	
	for i, szLine in ipairs( tabLines ) do
		if szLine == "" or szLine == "\n" then continue end
		local tabItem = FS.Deserialize:Records( szLine )
		table.insert( RecordsCache[ tabItem.Mode ], tabItem )
	end
end

function Records:Save()
	local szList = ""
	for _, mode in pairs( RecordsCache ) do
		for __, data in pairs( mode ) do
			szList = szList .. FS.Serialize:Records( data ) .. "\n"
		end
	end
	
	FS:Write( "times_" .. game.GetMap() .. ".txt", FS.Folders.Records, szList )
end


function Records:Add( ply, nTime, nOld, nMode, nJumps )
	local tabRec = { UID = ply:UniqueID(), Name = ply:Name(), Time = nTime, Mode = nMode, Date = os.date("%Y-%m-%d %H:%M:%S", os.time()) }
	local uid, rem, pos = ply:UniqueID(), 0, 0
	
	if nJumps and nJumps > 0 then
		tabRec.Jumps = nJumps
	end
	
	for p,d in pairs( RecordsCache[ nMode ] ) do
		if d.UID == uid then
			rem = p break
		end
	end
	if rem > 0 then table.remove( RecordsCache[ nMode ], rem ) end

	table.insert( RecordsCache[ nMode ], tabRec )
	table.sort( RecordsCache[ nMode ], function(a, b)
		return a.Time < b.Time
	end )

	for p,d in pairs( RecordsCache[ nMode ] ) do
		if d.UID == uid and d.Mode == nMode then
			pos = p
			d.Position = p
			break
		end
	end
	
	local ScoreBest = RecordsCache[ nMode ][ 1 ].Time
	local ScoreIndex = ScoreBest / nTime
	local ScoreAdd = math.Clamp( ScoreIndex * 35, 1, 50 )
	ply:AddFrags( math.floor( ScoreAdd ) )

	local strRank = pos .. (RankSuffixes[ pos ] or "th")
	Bot:Stop( ply, nTime, strRank )
	
	local strDisp = pos .. " / " .. #RecordsCache[ nMode ]
	if pos <= 10 then	
		ply:SendLua( "Timer:WR(" .. nTime .. "," .. nOld .. ",'" .. strRank .. "','" .. strDisp .. "'" .. (rem == pos and ",true" or "") .. ")" )
		if nOld == 0 then
			Message:Global( "PlayerWR", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), strDisp }, ply )
		elseif rem == pos then
			Message:Global( "PlayerWRDefend", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		else
			Message:Global( "PlayerWRImprove", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), strRank, Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		end
	else
		ply:SendLua( "Timer:PB(" .. nTime .. "," .. nOld .. ",'" .. strDisp .. "')" )
		if nOld == 0 then
			Message:Global( "PlayerFinish", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), Timer:Convert( nTime ), strDisp }, ply )
		else
			Message:Global( "PlayerImprove", Config.Prefix.Timer, { Config.ModeNames[ ply.Mode ], ply:Name(), Timer:Convert( nTime ), Timer:Convert( nOld - nTime ), strDisp }, ply )
		end
	end
end

function Records:GetWR( nMode, nMax )
	local tabSubmit = {}
	
	for i = 1, (nMax or 7) do
		local tabData = RecordsCache[ nMode ][ i ]
		if tabData then
			table.insert( tabSubmit, { tabData.Name, tabData.Time } )
		end
	end
	
	table.sort( tabSubmit, function(a, b)
		return a[2] < b[2]
	end )
	
	return tabSubmit
end

function Records:GetCache( nMode )
	if RecordsCache[ nMode ] and #RecordsCache[ nMode ] > 0 then
		return RecordsCache[ nMode ]
	end
	
	return nil
end


function Records:GetPlayer( uid, nMode )
	if not RecordsCache[ nMode ] then return nil end
	for _, data in pairs( RecordsCache[ nMode ] ) do
		if data.UID == uid and data.Mode == nMode then
			return data
		end
	end
	return nil
end

function Records:LoadPlayer( ply )
	if not RecordsCache[ ply.Mode ] then
		ply:SendLua( "Timer:SetMode(" .. ply.Mode .. "," .. ply.CurrentRecord .. ")" )
		return
	end
	
	for _, data in pairs( RecordsCache[ ply.Mode ] ) do
		if data.UID == ply:UniqueID() then
			ply.CurrentRecord = data.Time
			ply:SetNWInt( "Record", ply.CurrentRecord )
			break
		end
	end
	
	ply:SendLua( "Timer:SetMode(" .. ply.Mode .. "," .. ply.CurrentRecord .. ")" )
end

function Records:IsFirstBeat( szUID )
	local bFirst = true
	
	for i = Config.Modes["Auto"], Config.Modes["Scroll"] do
		for _, data in pairs( RecordsCache[i] ) do
			if data.UID == szUID then
				bFirst = false
				break
			end
		end
	end
	
	return bFirst
end

function Records:SendFirst( ply )
	if RecordsCache[ ply.Mode ] and RecordsCache[ ply.Mode ][1] and RecordsCache[ ply.Mode ][1].Time then
		ply:SendLua( "Timer:SetWRTime(" .. RecordsCache[ ply.Mode ][1].Time .. ")" )
	end
end

function Records:OpenWindow( ply, nMode, bFull )
	local tab = { nMode, 0, {} }
	
	if RecordsCache[ nMode ] and type( RecordsCache[ nMode ] ) == "table" and #RecordsCache[ nMode ] > 0 then
		tab[2] = #RecordsCache[ nMode ]
		tab[3] = Records:GetWR( nMode, bFull and tab[2] or nil )
		tab[4] = bFull
	end
	
	Data:Single( ply, "Records", tab )
end