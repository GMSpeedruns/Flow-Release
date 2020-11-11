Log = {}
Log.Level = { Info = 1, Warning = 2, Error = 3, Critical = 4 }
Log.New = "\n"
Log.File = "log_" .. os.date("%d%m-%H%M", os.time()) .. ".txt"
Log.Default = "Log File - Server Start on " .. os.date("%d/%m %H:%M", os.time())

function Log:Info( szData ) Log:Write( szData, Log.Level.Info ) end
function Log:Warning( szData ) Log:Write( szData, Log.Level.Warning ) end
function Log:Error( szData ) Log:Write( szData, Log.Level.Error ) end
function Log:Critical( szData ) Log:Write( szData, Log.Level.Critical ) end

function Log:Write( szText, nLevel )
	if not file.Exists( FS.Folders.Log .. Log.File, FS.Main ) then
		file.Write( FS.Folders.Log .. Log.File, Log.Default .. Log.New )
	end
	
	file.Append( FS.Folders.Log .. Log.File, Log:GetPrefix( nLevel ) .. szText .. Log.New )
end

function Log:GetPrefix( nLevel )
	for name, level in pairs(Log.Level) do
		if level == nLevel then
			return "[" .. name .. "]: "
		end
	end
end