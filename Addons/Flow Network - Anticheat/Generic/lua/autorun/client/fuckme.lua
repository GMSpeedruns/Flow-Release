-- George Anti Cheat
-- Modified by Gravious
-- For Flow Network

local runstring = false
local tablesdone = false

local dbgi = _G["debug"]["getinfo"]
local dbuv = _G["debug"]["getupvalue"]
local fr = _G["file"]["Read"]
local ff = _G["file"]["Find"]
local ns = _G["net"]["Start"]
local nw = _G["net"]["WriteString"]
local nwt = _G["net"]["WriteTable"]
local ns2 = _G["net"]["SendToServer"]
local ti = _G["table"]["insert"]
local th = _G["table"]["HasValue"]
local simp = _G["string"]["Implode"]
local lply = _G["LocalPlayer"]

local rawget = rawget
local sfind = string.find
local slen = string.len
local srev = string.reverse
local pairs = pairs
local type = type
local GCV = GetConVar
local smt = setmetatable
local schar = string.char
local mrand = math.random
local sgsub = string.gsub
local slow = string.lower
local ssub = string.sub
local se = string.Explode

mrand() mrand() mrand()

local b = ""
local dtbl = { { 65, 90 }, { 97, 122 }, { 48, 57 } }
for _,p in pairs(dtbl) do for i=p[1],p[2] do b=b..schar(i) end end b=b.."+/"

local function bc(d)
    d = sgsub(srev(d), '[^'..b..'=]', '')
    return (d:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return schar(c)
    end))
end

local itm = {
	bc("==QZ1xWY2BXd0V2cucWdiVGZgU2c1Byb0BCdw1WZ0RXQ"),bc("hVHbuUWbrNWdm9CduVWasN2LuVncvRXdh9SY1xGQ"),bc("=8yclR2btVWbhdGQ"),
	bc("=UWbltWasNnbhVmayVGalJ3b3xmcpdGdhhGdzITMjJWY"),bc("==Adph2cyVnbpxWYlR3ch1Wa"),bc("g0CIn5WayR3UuVnUgU2c1Byb0BCdw1WZ0RXQ"),bc("=AibvByav9GSgQWZ05WY35WV"),
	bc("=ACZlJXa1FXZyBSZsVHZv1GI"),bc("=ASeyFmcilGbgQWZ0NWZ09mcwBSemlGZv1GIvRHIn5Wa5JHV"),bc("gI3bmBSZjJXdvNHI0NWZyJ3bj5WS"),bc("==AbsRmLq8ibpJ2LhVHb"),
	bc("sxGZuoyLz52bkRWY"),bc("=ASZsVHZv1GIkR2T"),bc("lZ3bNBXd0V2U"),bc("==AZlRWYvxUZk9Wbl1WYH52T"),bc("=AiblRGZpJnclZ3T"),bc("=4SeyFmcilGbgcWdiVGZgQWZpZWak9WT"),
	bc("gUGbiFGdgUERP1URNF0Rg42bgMnbvlGdj5WdmBiblRGZpJnclZ3T"),bc("==AItASY0FGZgIXZkJ3bjVmU"),bc("=4Wa39GbsF2cpRWYt1Wa"),
	bc("=QXdw5Wa"),bc("ud3bElXZLNXS"),bc("==wZulGZulmQwV3av9GT"),bc("==QZtFmT5V2S0V2R")
}

local function plsrep(faggotry,sf)
	ns(itm[4]) nw(faggotry) ns2()
	if sf then ns(itm[5]) nw(ssub(sf,2)) nw(fr(ssub(sf,2),"GAME")) ns2() end
end

local function fakegup(f,u)
	local s = dbgi(2,"S").source
	if(s != itm[2]) then
		plsrep(itm[1],s)
	end
	return dbuv(f,u)
end

local function fakesup(f,u,v)
	local s = dbgi(2,"S").source
	if(s != itm[2]) then
		plsrep(itm[1],s)
	end
end

local function randomstringpls(l)
	if l < 1 then return nil end
	local s = ""
	for i = 1, l do
		s = s .. schar(mrand(32, 126))
	end
	return s
end

local function runstringov()
	_G['RunString'] = function()
		local source = dbgi(2,"S").source
		plsrep(itm[6]..source,source)
	end
	runstring = true
end

local protectzors = {"hook","debug"}
local oa = hook.Add

local function add(hook,s,f)
	local source = dbgi(2,"S").source
	if(ssub(source,1,11) != itm[3]) then
		plsrep(itm[7]..hook.." named "..s.." "..source,source)
	end
	oa(hook,s,f)
end

local ore = require
local function req(m)
	local source = dbgi(2,"S").source
	if(ssub(source,1,11) != itm[3]) then
		plsrep(m..itm[8]..source,source)
	end
	ore(m)
end

local function gonindex(t, k)
	return rawget(t, k)
end

local function gonnewindex(t, k, v)
	for _,q in pairs(protectzors) do
		if sfind(k,q) then
			local s = dbgi(3,"S")
			if(s) then
				plsrep(itm[9]..q.. " - "..s.source,s.source)
			else
				plsrep(itm[9]..q)
			end
			return
		end
	end

	rawset(t, k, v)
end

local function metaov()
	_G["hook"]["Add"] = add
	_G["require"] = req
	_G["debug"]["setupvalue"] = fakesup
	_G["debug"]["getupvalue"] = fakegup
	local mt = {
		__index = function(...) return gonindex(...) end,
		__newindex = function(...)
			gonnewindex(...)
		end,
		__metatable = {}
	}
	
	tablesdone = true
	
	local did, err = pcall(smt, _G, mt)
	return not did
end

local function testupvalues()
	local f = randomstringpls(mrand(10,17))
	local d = randomstringpls(mrand(16,20))
	local t = {}
	local b, v, ts, ts2

	t[f] = function(a, b, c)
		return a+b+c
	end

	t[d] = t[f]
	t[f] = function(a, b, c)
		return t[d](a, b, c)
	end

	b, v = debug.getupvalue(t[f], 2)
	ts, ts2 = dbuv(t[f], 2)
	return d != v or b != "d" or ts != b or ts2 != v
end

local checkdebug = {
	"getupvalue",
	"sethook",
	"getlocal",
	"setlocal",
	"gethook",
	"getmetatable",
	"setmetatable",
	"traceback",
	"setfenv",
	"getinfo",
	"setupvalue",
	"getregistry",
	"getfenv",
}

local checkthisout = {
	["hook"] = {
		["Add"] = itm[2]
	},
	["file"] = {
		["Read"] = "@lua/includes/extensions/file.lua",
		["Write"] = "@lua/includes/extensions/file.lua",
		["Append"] = "@lua/includes/extensions/file.lua",
		["Exists"] = "=[C]",
		["Find"] = "=[C]",
		["Open"] = "=[C]",
	},
	["sql"] = {
		["Query"] = "=[C]",
		["QueryValue"] = "@lua/includes/util/sql.lua",
	},
	["debug"] = {
		["getupvalue"] = itm[2],
		["sethook"] = "=[C]",
		["getlocal"] = "=[C]",
		["setlocal"] = "=[C]",
		["gethook"] = "=[C]",
		["getmetatable"] = "=[C]",
		["setmetatable"] = "=[C]",
		["traceback"] = "=[C]",
		["setfenv"] = "=[C]",
		["getinfo"] = "=[C]",
		["setupvalue"] = itm[2],
		["getregistry"] = "=[C]",
		["getfenv"] = "=[C]",
	},
	["GetConVar"] = "=[C]",
	["GetConVarNumber"] = "=[C]",
	["GetConVarString"] = "=[C]",
	["engineConsoleCommand"] = "@lua/includes/modules/concommand.lua",
	["RunConsoleCommand"] = "=[C]",
}

local shitwedontwant = {
	"spreadthebutter",
	"cat_win32",
	"hera",
	"nyx", "xyn",
	"name_enabler",
	"hack", "hake", "hac_win32",
	"hax",
	"cv3", "cvar",
	"nerve",
	"exposer",
	"nospread",
	"bot",
	"shit",
	"snix",
	"datastream",
	"crack",
	"bypass",
}

local function checkstuff()
	for k, s in pairs(checkthisout) do
		local x = {}
		if type(s) == "table" then
			for func, v in pairs(s) do
				if not _G[k] or type(_G[k][func]) != "function" then continue end
				x = dbgi(_G[k][func],"S")
					
				if sgsub(x.source,[[\]], "") != v then
					plsrep(itm[10]..k.."."..func..": "..x.source,x.source)
				end				
			end
		elseif type(s) == "string" then
			if type(_G[k]) != "function" then continue end
			x = dbgi(_G[k],"S")
				
			if sgsub(x.source,[[\]], "") != s then
				plsrep(itm[10]..k..": "..x.source,x.source)
			end
		end
	end
end

local function plsgetoutnow()
	local a = ff(itm[11], "GAME")
	local b = ff(itm[12], "MOD")
	for _,f in pairs(b) do ti(a,f) end
	for _,q in pairs(shitwedontwant) do
		for i,f in pairs(a) do
			if sfind(f,q,1,true) then
				return plsrep(itm[13]..tostring(f))
			end
		end
	end
end

local icvars = {
	["sv_cheats"] = 0,
	["sv_allowcslua"] = 0,
	["r_drawothermodels"] = 1,
	["host_timescale"] = 1,
	["mat_wireframe"] = 0,
}

local function notathinkhook()
	if not IsValid or not IsValid(lply()) then
		timer.Simple(1, notathinkhook)
		return
	end
	
	for k,v in pairs(icvars) do
		local d = false
		if tonumber(GCV(k):GetString()) != v then
			plsrep(itm[16]..tostring(k))
			d = true
		end
		if !d && tonumber(GCV(k):GetString()) != GCV(k):GetInt() then
			plsrep(itm[16]..tostring(k))
			d = true
		end
		if !d && GCV(k):GetInt() != v then
			plsrep(itm[16]..tostring(k))
			d = true
		end
		if !d && !GCV(k) then
			plsrep(itm[16]..tostring(k))
			d = true
		end
	end 
	
	if type(_G.debug) != "table" then plsrep(itm[17]) end
	for _,v in pairs(checkdebug) do
		if type(_G.debug[v]) != "function" then
			plsrep(itm[17])
			break
		end
	end
	if testupvalues() then
		plsrep(itm[17])
	end
	
	checkstuff()

	for k,v in pairs(GAMEMODE) do
		if(type(v) == "function") then
			local s = dbgi(v,"S").source
			if(ssub(s,1,11) != itm[3]) then
				plsrep(itm[18]..s,s)
			end
		end
	end
	
	timer.Simple(5,notathinkhook)
end

local function immareloading()
	runstringov()
	metaov()
	plsgetoutnow()
	notathinkhook()
end
oa(itm[15],randomstringpls(mrand(10,17)),immareloading)