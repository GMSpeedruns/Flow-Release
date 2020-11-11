Cache = {}

Cache.M_Data = {}
Cache.M_Version = 0
Cache.M_Name = "flow-deathrun.txt"
Cache.R_Name = "flow-radio.txt"
Cache.T_Name = "flow-deathrun-pb.txt"
Cache.T_Data = {}
Cache.V_Data = {}
Cache.H_Data = {}


function Cache:V_Update( varList )
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.Votes = varList
		wnd.Data.Update = true
	end
end

function Cache:V_InstantVote( nID )
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.InstantVote = nID
	end
end

function Cache:V_VIPExtend()
	if Window:IsActive( "Vote" ) then
		local wnd = Window:GetActive()
		wnd.Data.EnableExtend = true
	end
end

function Cache:M_Load()
	local data = file.Read( Cache.M_Name, "DATA" )
	local version = tonumber( string.sub( data, 1, 5 ) )
	if not version then return end
	local remain = util.Decompress( string.sub( data, 6 ) )
	if not remain then return end
	local tab = util.JSONToTable( remain )
	
	if #Cache.M_Data > 0 then
		Cache.M_Version = version
		Cache.M_Data = tab
		Cache:M_Update()
	end
end

function Cache:M_Save( varList, nVersion, bOpen )
	Cache.M_Data = varList or {}
	Cache.M_Version = nVersion
	Cache:M_Update()
	
	if #Cache.M_Data > 0 then
		local data = util.Compress( util.TableToJSON( Cache.M_Data ) )
		if not data then return end
		
		file.Write( Cache.M_Name, string.format( "%.5d", nVersion ) .. data )
		if bOpen then
			Window:Open( "Nominate", { nVersion } )
		end
	else
		Window:Close()
	end
end

function Cache:M_Update()
	for i,d in pairs( Cache.M_Data ) do
		Cache.M_Data[ i ][ 2 ] = tonumber( d[ 2 ] )
	end
end

function Cache:T_Load()
	local tab = {}
	if file.Exists( Cache.T_Name, "DATA" ) then
		local data = file.Read( Cache.T_Name, "DATA" )
		if data and data != "" then
			local remain = util.Decompress( data )
			if remain then
				tab = util.JSONToTable( remain )
				if not tab then tab = {} end
			end
		end
	end
	
	Cache.T_Data = tab
end

function Cache:T_SetRecord( nTime )
	Cache:T_Load()
	Cache.T_Data[ game.GetMap() ] = nTime
	
	local data = util.Compress( util.TableToJSON( Cache.T_Data ) )
	if not data then return end
	
	file.Write( Cache.T_Name, data )
end

local ct, Tn, TnF, TL = CurTime
function Cache:T_GetRunTime()
	if not TnF and Tn then return ct() - Tn
	elseif TnF and Tn then return TnF - Tn
	else return 0 end
end

function Cache:T_Reset()
	Tn, TnF = nil, nil
end

function Cache:T_GetRecord()
	return Cache.T_Data[ game.GetMap() ] or -1
end

function Cache:T_Update( nTime )
	local t = Cache:T_GetRecord()
	if t < 0 or nTime < t then
		Cache:T_SetRecord( nTime )
	end
end


Link = {}
Link.Protocol = "SecureTransfer"
Link.Protocol2 = "BinaryTransfer"


function Link:Print( szPrefix, varText )
	if not varText then return end
	if type( varText ) != "table" then varText = { varText } end
	
	chat.AddText( GUIColor.White, "[", _C.Prefixes[ szPrefix ], szPrefix, GUIColor.White, "] ", unpack( varText ) )
end

function Link:Send( szAction, varArgs )
	net.Start( Link.Protocol )
	net.WriteString( szAction )
	
	if varArgs and type( varArgs ) == "table" then
		net.WriteBit( true )
		net.WriteTable( varArgs )
	else
		net.WriteBit( false )
	end
	
	net.SendToServer()
end

local function TransferHandle( szAction, varArgs )
	if szAction == "GUI_Open" then
		Window:Open( tostring( varArgs[ 1 ] ), varArgs[ 2 ] )
	elseif szAction == "GUI_Update" then
		Window:Update( tostring( varArgs[ 1 ] ), varArgs[ 2 ] )
	elseif szAction == "Print" then
		Link:Print( tostring( varArgs[ 1 ] ), tostring( varArgs[ 2 ] ) )
	elseif szAction == "Timer" then
		local szType = tostring( varArgs[ 1 ] )
		
		if szType == "Start" then
			Tn, TnF = varArgs[ 2 ], nil
		elseif szType == "Finish" then
			TnF = varArgs[ 2 ]
			Cache:T_Update( varArgs[ 3 ] )
		elseif szType == "Speed" then
			Core.Util:SetSpeedCap( LocalPlayer(), tonumber( varArgs[ 2 ] ) )
		end
	elseif szAction == "Client" then
		local szType = tostring( varArgs[ 1 ] )
		
		if szType == "HUDEditToggle" then
			Client:ToggleEdit()
		elseif szType == "HUDEditRestore" then
			Client:RestoreTo( varArgs[ 2 ] )
		elseif szType == "HUDOpacity" then
			Client:SetOpacity( varArgs[ 2 ] )
		elseif szType == "Crosshair" then
			Client:ToggleCrosshair( varArgs[ 2 ] )
		elseif szType == "TargetIDs" then
			Client:ToggleTargetIDs()
		elseif szType == "PlayerVisibility" then
			Client:PlayerVisibility( tonumber( varArgs[ 2 ] ) )
		elseif szType == "Chat" then
			Client:ToggleChat()
		elseif szType == "Mute" then
			Client:Mute( varArgs[ 2 ] )
		elseif szType == "GUIVisibility" then
			Client:GUIVisibility( tonumber( varArgs[ 2 ] ) )
		elseif szType == "Water" then
			Client:ChangeWater()
		elseif szType == "Decals" then
			Client:ClearDecals()
		elseif szType == "Reveal" then
			Client:ToggleReveal()
		elseif szType == "Tutorial" then
			gui.OpenURL( varArgs[ 2 ] )
		elseif szType == "WeaponFlip" then
			Client:FlipWeapons()
		elseif szType == "Space" then
			Client:ToggleSpace( varArgs[ 2 ] )
		elseif szType == "Thirdperson" then
			Client:ToggleThirdperson()
		elseif szType == "Victory" then
			Client:SetVictory( varArgs[ 2 ] )
		elseif szType == "Server" then
			Client:ServerSwitch( varArgs[ 2 ] )
		elseif szType == "Emote" then
			Client:ShowEmote( varArgs[ 2 ] )
		elseif szType == "Round" then
			Client:SetRound( varArgs[ 2 ], varArgs[ 3 ] )
		elseif szType == "RoundTime" then
			Client:SetRoundTime( varArgs[ 2 ] )
		elseif szType == "Pointshop" then
			Client:OpenShop()
		end
	elseif szAction == "RTV" then
		local szType = tostring( varArgs[ 1 ] )
		
		if szType == "List" then
			Cache.V_Data = varArgs[ 2 ] or {}
			Window:Open( "Vote" )
		elseif szType == "VoteList" then
			Cache:V_Update( varArgs[ 2 ] )
		elseif szType == "InstantVote" then
			Cache:V_InstantVote( varArgs[ 2 ] )
		elseif szType == "VIPExtend" then
			Cache:V_VIPExtend()
		end
	elseif szAction == "Manage" then
		local szType = tostring( varArgs[ 1 ] )
		
		if szType == "Mute" then
			Client:DoChatMute( varArgs[ 2 ], varArgs[ 3 ] )
		elseif szType == "Gag" then
			Client:DoVoiceGag( varArgs[ 2 ], varArgs[ 3 ] )
		end
	elseif szAction == "Radio" then
		Radio:Receive( varArgs )
	elseif szAction == "Admin" then
		Admin:Receive( varArgs )
	end
end

local function TransferReceive()
	local szAction = net.ReadString()
	local bTable = net.ReadBit() == 1
	local varArgs = {}
	
	if bTable then
		varArgs = net.ReadTable()
	end
	
	TransferHandle( szAction, varArgs )
end
net.Receive( Link.Protocol, TransferReceive )