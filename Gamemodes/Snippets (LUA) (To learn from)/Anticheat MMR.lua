-- George Anti Cheat
-- Modified by Gravious
-- For Flow Network

-- Documented for itzaname

-- Functions that were 'obfuscated' with itm reverse base 64 strings
local Input_GetKeyName = _G["input"]["GetKeyName"]
local Input_LookupBinding = _G["input"]["LookupBinding"]
local Input_IsKeyDown = _G["input"]["IsKeyDown"]

-- Numbers obtained from: http://wiki.garrysmod.com/page/Enums/KEY
local kq = 11 -- A Key
local ko = 14 -- D Key
local kf = 72 -- INSERT Key

-- Detection / measurement variables
local ki = 0 -- INSERT key presses total
local ke = 0 -- Valid CROUCH movements
local kc = 0 -- Invalid CROUCH movements (kc = key crouch)
local kt = 0 -- Valid RIGHT movements
local kr = 0 -- Invalid RIGHT movement (kr = key right)
local kj = 0 -- Valid LEFT movements
local kl = 0 -- Invalid LEFT movements (kl = key left)

local ku = 0.5 -- Percentage of time the player is allowed to not press keys WHEN crouching 
local kg = 0.3 -- Percentage of time the player is allowed to not press keys WHEN pressing A / D in order to not get false positives. With MMR (if you FULLY replay a run, you'll get 100% incorrect keys)

local ks = "" -- Really only to make the string.Implode at the report part look like something else
local km = {{},{},{},false} -- Holds key mappings

-- Get the key number for a keyname (moveleft for example)
local function getdakenr(k)
	-- Yes, again, because Garry is retarded, we have to use this hacky method to loop through all normal keys and figure out which number belongs to which key
	for i = 1, 170 do
		if k == Input_GetKeyName(i) then
			return i
		end
	end
	
	return -1
end

-- Do kick right now for a player (if they have bad bindings - SINCE WE FULLY RELY on this...)
local function dokikatm(e)
	ns(itm[20])
	nwt(e)
	ns2()
end

-- Checks if the player has any important keys down
local function anydowns(t)
	if not km[1][t] then return end
	
	for _,n in pairs( km[1][t] ) do
		if Input_IsKeyDown( n ) then
			return true
		end
	end
end

-- Basically just parse a .cfg file and read all bound keys from it (downside from having to do this is that it doesn't instantly save when people rebind things
-- I've tried methods to pick up a player rebinding a key but it's fucking impossible. Thanks Garry.
local function addfromcfg(sz,vars)
	local cfg = file.Read( "cfg/" .. sz .. ".cfg", "GAME" )
	if not cfg or cfg == "" then return vars end
	
	local exz = string.Explode( "\n", cfg )
	if not exz or #exz == 0 then return vars end
	
	for n,l in pairs( exz ) do
		if string.sub( l, 1, 5 ) == "bind " then
			-- Getting rid of quotes and leaving the remainder
			local rem = string.gsub( string.sub( l, 6 ), "\"", "" )
			
			local vals = string.Explode( " ", rem )
			for i,val in pairs( vars ) do
				-- Loop through our lookup table (all important binds)
				-- If we find it, we'll map the key
				if vals[ 2 ] == val[ 1 ] then
					if not val[ 2 ] then
						vars[ i ][ 2 ] = {}
						vars[ i ][ 3 ] = {}
					end
					local k = getdakenr(vals[ 1 ])
					if not table.HasValue(vars[i][2],k) then
						table.insert( vars[ i ][ 2 ],k )
						table.insert( vars[ i ][ 3 ],vals[1] )
					end
				end
			end
		end
	end
	return vars
end

-- Make sure they have their things bound normally
-- This also checks their configs
local function checksomkez()
	-- Load in all data from the configs since input.LookupBinding will only result in the first one rather than ALL of them, fuck...
	local kbs = { { "+moveleft", false }, { "+moveright", false }, { "+duck", false }, { "+forward", false }, { "+back", false } }
	kbs = addfromcfg("config",kbs)
	kbs = addfromcfg("autoexec",kbs)
	
	for i,tab in pairs( kbs ) do
		-- If they haven't got it bound, kick them right now
		if not tab[ 2 ] then
			km[ 4 ] = { "C", tab[ 1 ] }
			return true
		else
			if #tab[ 2 ] == 0 then
				km[ 4 ] = { "C", tab[ 1 ] }
				return true
			end
		end
		
		-- Here will insert ALL of the keys for a specific bind (moveleft for example)
		km[ 1 ][ i ] = tab[ 2 ]
		km[ 2 ][ i ] = tab[ 3 ]
		km[ 3 ][ i ] = tab[ 1 ]
	end
end

local function validatesomkez()
	if km[ 4 ] then return dokikatm( km[ 4 ] ) end
	
	-- I'm not even sure anymore haha
	for k,v in pairs( km[ 2 ] ) do
		local e
		if v and type(v) == "table" and #v > 0 then
			if Input_LookupBinding(km[3][k]) != v[1] then
				e = { "Q", k }
			end
		else
			e = { "I", k }
		end
		
		if e then return dokikatm(e) end
	end
end

-- SetupMove hook
local function chksomspd(p,d)
	if p:OnGround() then return end
	
	local s = d:GetSideSpeed()
	if s < 0 then
		-- If we're going to the left, check if they're actually pressing the key
		if anydowns(1) then
			kj = kj + 1 -- If they press it, increase the LEGIT variable for left
		else
			kl = kl + 1 -- If they don't press it but they still go left, increase the INVALID variable for left
		end
	elseif s > 0 then
		-- Same for right movement
		if anydowns(2) then
			kt = kt + 1
		else
			kr = kr + 1
		end
	else
		-- When they're not pressing keys, check if their INSERT key is pressed (this is FIXED and will open up your MMR menu. If this is high the server will increase the risk of it being MMR)
		if Input_IsKeyDown( kf ) then
			ki = ki + 1
		end
	end
	
	-- To make measurements better, we also included the crouch key because this will also trigger without them actually pressing CTRL
	if p:Crouching() then
		if anydowns(3) then
			ke = ke + 1
		else
			kc = kc + 1
		end
	end
end
hook.Add( "SetupMove", "Blabla", chksomspd )

-- The actual report function
function imstnit(n,z)
	if n == 1 then -- When the user restarts by either doing /r or by re-entering the start zone (for proper measurements)
		kc,ke,kl,kj,kr,kt=0,0,0,0,0,0 -- Reset all measurement variables
	elseif n == 2 then -- When the player finishes
		-- Here we detect the percentage
		-- Invalid / (Invalid + Valid) > 30% for A and D
		-- OR If crouch is over 50% invalid, we report them and check the percentages on the server again (which is stricter and takes the INSERT presses into account)
		
		if (kl/(kl+kj)>kg and kr/(kr+kt)>kg) or kc/(kc+ke)>ku then -- We'll only want to detect whenever we have collected enough data for a run
			plsrep(itm[19]..string.Implode(ks,{ki,kl,kj,kr,kt,kc,ke,z})) -- Report them with the data we gathered in order to check it on the server again
		end
	end
end


-- Think hook with code removed
local function notathinkhook()
	-- Validate key binds constantly to avoid people rebinding on the go and then bypassing
	validatesomkez()
	
	timer.Simple(5,notathinkhook)
end