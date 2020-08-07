local _ENV = xero

local function loadcommand(self)
	self:vanishpoint(scx, scy):fov(45)
	for pn = 1, 2 do
		function temp(proxy, child)
			child
				:visible(false)
				:sleep(9e9)
			proxy
				:SetTarget(child)
				:xy(scx * (pn - 0.5), scy)
				:zoom(sh / 480)
		end
		temp(proxy.notefield[pn], P[pn]:GetChild'NoteField')
		temp(proxy.judge[pn], P[pn]:GetChild'Judgment')
		temp(proxy.combo[pn], P[pn]:GetChild'Combo')
	end
	
	-- your code here
	
end

local af = Def.ActorFrame {
	LoadCommand = loadcommand,
	
	
	Def.ActorProxy { Name = "proxy.combo[1]" },
	Def.ActorProxy { Name = "proxy.combo[2]" },
	Def.ActorProxy { Name = "proxy.judge[1]" },
	Def.ActorProxy { Name = "proxy.judge[2]" },
	Def.ActorProxy { Name = "proxy.notefield[1]" },
	Def.ActorProxy { Name = "proxy.notefield[2]" },

}

return af