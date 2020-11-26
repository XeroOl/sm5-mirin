return Def.ActorFrame {
	LoadCommand = xero(function(self)
		-- judgment / combo proxies
		for pn = 1, 2 do
			setupJudgeProxy(PJ[pn], P[pn]:GetChild('Judgment'), pn)
			setupJudgeProxy(PC[pn], P[pn]:GetChild('Combo'), pn)
		end
		-- player proxies
		for pn = 1, #PP do
			PP[pn]:SetTarget(P[pn])
			P[pn]:visible(false)
		end
		-- your code goes here here:
		
	end),
	Def.ActorProxy {
		Name = "PC[1]",
	},
	Def.ActorProxy {
		Name = "PC[2]",
	},
	Def.ActorProxy {
		Name = "PJ[1]",
	},
	Def.ActorProxy {
		Name = "PJ[2]",
	},
	Def.ActorProxy {
		Name = "PP[1]",
	},
	Def.ActorProxy {
		Name = "PP[2]",
	},
}
