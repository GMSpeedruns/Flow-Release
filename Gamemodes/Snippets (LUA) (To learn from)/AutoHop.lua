-- SHARED CODE
-- HAS TO BE USED SHARED!

-- Full but small code snippet for reliable auto hop
-- The SetupMove is the most accurate hook to be used. StartCommand is preferred but my tests showed those resulted in more failure

local fb = bit.band -- Similarly to the math library, having those local reduces call time - thus resulting in better accuracy - I'll explain more about this with optimization later.
local function AutoHop( ply, data )
	if CLIENT and ply != LocalPlayer() then return end -- This is so that the client has less load calculating stuff for other players
	
	local Style = SERVER and ply.Mode or Client.Mode -- We get their mode here - Since this is shared it has to be compatible for both (You can reduce call load by setting mode on the client to ply.Mode as well). On LP, this variable will most likely be different (ply.AutoHopEnabled or whatever)
	if Style != Config.Modes["Scroll"] then -- Make sure they're not scrolling. Otherwise, if they're on any other modes, they'll have auto hop.
		local ButtonData = data:GetButtons() -- Get their current buttons
		if fb( ButtonData, IN_JUMP ) > 0 then -- If they're holding Space
			if ply:WaterLevel() < 2 and ply:GetMoveType() != MOVETYPE_LADDER and not ply:IsOnGround() then -- Make sure that only when they're not in the water, NOT ON A LADDER (Fixes your problem) and not on the ground the code will ...
				data:SetButtons( bit.band( ButtonData, bit.bnot( IN_JUMP ) ) ) -- ... remove their jump button as it's not needed in the air, only when the player is on the ground.
			end
		end
	end
end
hook.Add( "SetupMove", "AutoHop", AutoHop )