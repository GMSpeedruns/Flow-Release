-- HUD module used for my tutorials

-- README.txt
--[[
			Put this file in your modules folder.
			On send.txt add a new line with: gamemodes\bhop\gamemode\modules\cl_strafe.lua
			Then on your cl_init.lua top add: include( "modules/cl_strafe.lua" )
			
			Note that in order to reset the strafes, you have go to cl_receive.lua (TransferHandle function)
			
			And look for this part

				elseif szAction == "Timer" then
					local szType = tostring( varArgs[ 1 ] )
					
					if szType == "Start" then
						Timer:SetStart( tonumber( varArgs[ 2 ] ) )
					elseif szType == "Restart" then
						if imstnit then imstnit( 1 ) end
			
			And below the "if imstnit then imstnit( 1 ) end"
			Add this: if ResetStrafes then ResetStrafes() end

			and on your cl_timer.lua file you'll have to replace Timer:SetCPSData( data ) with this:
			
			function Timer:SetCPSData( data )
				SetSyncData( data )
			end
			
			You might also want to disable ammo drawing or the displays will overlap
			
			ALSO remove this text because it'll take some time to transfer to the client
]]


local StrafeAxis = 0 -- Saves the last eye angle yaw for checking mouse movement
local StrafeButtons = nil -- Saves the buttons from SetupMove for displaying
local StrafeCounter = 0 -- Holds the amount of strafes
local StrafeLast = nil -- Your last strafe key for counting strafes
local StrafeDirection = nil -- The direction of your strafes used for displaying
local StrafeStill = 0 -- Counter to reset mouse movement

local fb, ik, lp, ts = bit.band, input.IsKeyDown, LocalPlayer, _C.Team.Spectator -- This function is used frequently so to reduce lag...
local function norm( i ) if i > 180 then i = i - 360 elseif i < -180 then i = i + 360 end return i end -- Custom function to normalize eye angles

local StrafeData -- Your Sync value is stored here
local KeyADown, KeyDDown -- For displaying on the HUD
local MouseLeft, MouseRight --- For displaying on the HUD

local ViewGUI = CreateClientConVar( "sl_showgui", "1", true, false ) -- GUI visibility
surface.CreateFont( "HUDFont2", { size = 20, weight = 800, font = "Tahoma" } )

function ResetStrafes() StrafeCounter = 0 end -- Resets your stafes (global)
function SetSyncData( data ) StrafeData = data end -- Sets your sync data (global)

-- Monitors the buttons and angles
local function MonitorInput( ply, data )
	StrafeButtons = data:GetButtons()
	
	local ang = data:GetAngles().y
	local difference = norm( ang - StrafeAxis )
	
	if difference > 0 then
		StrafeDirection = -1
		StrafeStill = 0
	elseif difference < 0 then
		StrafeDirection = 1
		StrafeStill = 0
	else
		if StrafeStill > 20 then
			StrafeDirection = nil
		end
		
		StrafeStill = StrafeStill + 1
	end
	
	StrafeAxis = ang
end
hook.Add( "SetupMove", "MonitorInput", MonitorInput )

-- Monitors your key presses for strafe counting
local function StrafeKeyPress( ply, key )
	if ply:IsOnGround() then return end
	
	local SetLast = true
	if key == IN_MOVELEFT or key == IN_MOVERIGHT then
		if StrafeLast != key then
			StrafeCounter = StrafeCounter + 1
		end
	else
		SetLast = false
	end
	
	if SetLast then
		StrafeLast = key
	end
end
hook.Add( "KeyPress", "StrafeKeys", StrafeKeyPress )

-- Paints the actual HUD
local function HUDPaintB()
	if not ViewGUI:GetBool() then return end
	if not IsValid( lp() ) or lp():Team() == ts then return end
	
	-- Background
	local x,y = ScrW() - 250, ScrH() - 145
	surface.SetDrawColor( Color(35, 35, 35, 255) )
	surface.DrawRect( x, y, 230, 125 )
	
	-- Setting the key colors
	if StrafeButtons then
		if fb( StrafeButtons, IN_MOVELEFT ) > 0 then KeyADown = Color( 142, 42, 42, 255 ) else KeyADown = nil end
		if fb( StrafeButtons, IN_MOVERIGHT ) > 0 then KeyDDown = Color( 142, 42, 42, 255 ) else KeyDDown = nil end
	end
	
	-- Getting the direction for the mouse
	if StrafeDirection then
		if StrafeDirection > 0 then
			MouseLeft, MouseRight = nil, Color( 142, 42, 42, 255 )
		elseif StrafeDirection < 0 then
			MouseLeft, MouseRight = Color( 142, 42, 42, 255 ), nil
		else
			MouseLeft, MouseRight = nil, nil
		end
	else
		MouseLeft, MouseRight = nil, nil
	end
	
	-- Box on top
	surface.SetDrawColor( Color(42, 42, 42, 255) )
	surface.DrawRect( x + 5, y + 5, 220, 55 )
	draw.SimpleText( "Extra keys:", "HUDTimer", x + 12, y + 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	
	-- If we have buttons, display them
	if StrafeButtons then
		local zx = x + 40
		if fb( StrafeButtons, IN_FORWARD ) > 0 then
			draw.SimpleText( "W", "HUDTimer", zx + 56, y + 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		if fb( StrafeButtons, IN_BACK ) > 0 then
			draw.SimpleText( "S", "HUDTimer", zx + 76, y + 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		if ik( KEY_SPACE ) or fb( StrafeButtons, IN_JUMP ) > 0 then
			draw.SimpleText( "Jump", "HUDTimer", zx + 92, y + 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
		if fb( StrafeButtons, IN_DUCK ) > 0 then
			draw.SimpleText( "Duck", "HUDTimer", zx + 136, y + 20, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
		end
	end
	
	-- Display the amount of strafes
	if StrafeCounter then
		draw.SimpleText( "Strafes: " .. StrafeCounter, "HUDTimer", x + 12, y + 45, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
	end
	
	-- If we have sync, display the sync
	if StrafeData then
		draw.SimpleText( StrafeData, "HUDTimer", x + 216, y + 45, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER )
	end
	
	-- Bottom left
	surface.SetDrawColor( KeyADown or Color(42, 42, 42, 255) )
	surface.DrawRect( x + 5, y + 65, 108, 25 )
	draw.SimpleText( "A", "HUDFont", x + 58, y + 77, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	
	-- Bottom right
	surface.SetDrawColor( KeyDDown or Color(42, 42, 42, 255) )
	surface.DrawRect( x + 118, y + 65, 107, 25 )
	draw.SimpleText( "D", "HUDFont", x + 172, y + 77, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	
	-- Bottom left
	surface.SetDrawColor( MouseLeft or Color(42, 42, 42, 255) )
	surface.DrawRect( x + 5, y + 95, 108, 25 )
	draw.SimpleText( "Mouse Left", "HUDFont2", x + 58, y + 107, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	
	-- Bottom right
	surface.SetDrawColor( MouseRight or Color(42, 42, 42, 255) )
	surface.DrawRect( x + 118, y + 95, 107, 25 )
	draw.SimpleText( "Mouse Right", "HUDFont2", x + 172, y + 107, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
end
hook.Add( "HUDPaint", "PaintB", HUDPaintB )