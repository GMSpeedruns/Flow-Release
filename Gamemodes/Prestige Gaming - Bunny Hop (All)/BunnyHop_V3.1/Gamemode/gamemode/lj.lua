-------------
-- LJ Stats --
-------------

LJ = {}
LJ.Stats = {}

function LJ:Toggle(ply)
	if ply.LJ then
		self:Disable(ply)
	else
		self:Enable(ply)
	end
end

function LJ:Enable(ply)
	ply.LJ = true
	ply.LJStats = {}
	ply.LJStats.Accelerate = 0
	ply.LJStats.Air = 0
	
	SendMessage(ply, MSG_ID["LJMsg"], {"Statistics: On"})
end

function LJ:Disable(ply)
	ply.LJ = nil
	ply.LJStats = {}
	ply.LJStats.Accelerate = 0
	ply.LJStats.Air = 0
	
	SendMessage(ply, MSG_ID["LJMsg"], {"Statistics: Off"})
end

function LJ:StartBlock(ply)
	--ply.LJBlock = 0
	SendMessage(ply, MSG_ID["LJMsg"], {"This function is not yet available!"})
end

function LJ.Stats:BeginMove(ply, start, md)
	if not ply.LJStats.Strafing and start then
		ply.LJStats.Strafing = true
		ply.LJStats.Start = ply:GetPos()
		ply.LJStats.Prestrafe = md:GetVelocity():Length2D()
		ply.LJStats.Max = ply.LJStats.Prestrafe
	end
	if ply.LJStats.Strafing then
		ply.LJStats.Air = ply.LJStats.Air + 1
	end
end

function LJ.Stats:Accelerate(ply, md)
	if ply.LJStats.Strafing then
		ply.LJStats.Accelerate = ply.LJStats.Accelerate + 1
		local speed = md:GetVelocity():Length2D()
		if not ply.LJStats.Max or speed > ply.LJStats.Max then ply.LJStats.Max = speed end
	end
end

function LJ.Stats:Complete(ply, pos)
	if ply.LJStats.Strafing and ply.LJStats.Air > 10 then
		if not ply.LJStats.Start then return end
		if ply.LJStats.Prestrafe < 240 or ply.LJStats.Prestrafe > 278 then return end
		if ply.LJStats.Start.z == pos.z then return end
		local Sync, Distance = (ply.LJStats.Accelerate / ply.LJStats.Air) * 100, ply.LJStats.Start:Distance(pos) + 32.00
		if Distance < 240 or Distance > 268 then return end
		if ply.LJStats.Max and ply.LJStats.Max > 400 then return end
		if ply.LJStats.SyncTable and #ply.LJStats.SyncTable > 0 then
			Sync = 0
			for k,v in pairs(ply.LJStats.SyncTable) do
				Sync = Sync + tonumber(v[5])
			end
			Sync = Sync / #ply.LJStats.SyncTable
		end
		SendData(ply, DATA_ID["LJ"], {string.format("%.2f", Distance), string.format("%.2f", Sync), string.format("%.2f", ply.LJStats.Prestrafe), ply.LJStats.Strafes, string.format("%.2f", ply.LJStats.Max), ply.LJStats.SyncTable})
	end
end

function LJ.Stats:Keys(ply, key, md)
	if not ply.LJStats.Strafing or ply.LJStats.Air < 10 then return end
	if not ply.LJStats.Strafes then ply.LJStats.Strafes = 0 ply.LJStats.SyncTable = {} end
	if not ply.LJStats.LastKey then ply.LJStats.LastKey = 0 end
	if ply.LJStats.LastKey != key then ply.LJStats.LastKey = key else return end
	ply.LJStats.Strafes = ply.LJStats.Strafes + 1
--	if ply.LJStats.Strafes < 2 then return end
	local Speed, Gain, Loss = md:GetVelocity():Length2D(), 0, 0
	if #ply.LJStats.SyncTable > 0 then
		local Last = ply.LJStats.SyncTable[#ply.LJStats.SyncTable]
		Gain = Speed - Last[2]
	else
		Gain = Speed - ply.LJStats.Prestrafe
	end
	if Gain < 0 then Gain = 0 Loss = -Gain end
	table.insert(ply.LJStats.SyncTable, {ply.LJStats.Strafes, string.format("%.2f", ply.LJStats.Max), string.format("%.2f", Gain), string.format("%.2f", Loss), string.format("%.2f", (ply.LJStats.Accelerate / ply.LJStats.Air) * 100)})
end

function LJ.Stats:Reset(ply)
	ply.LJStats = {}
	ply.LJStats.Accelerate = 0
	ply.LJStats.Air = 0
end