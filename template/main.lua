if GAMESTATE:GetNumPlayersEnabled() ~= 2 then
	SCREENMAN:SystemMessage "Two players are required for this file to work"
	return nil
end

local af = Def.ActorFrame {}
_G.xero = {}

LoadActor 'std.lua'
LoadActor 'ease.lua'

return af .. {
	Name = 'foreground',
	InitCommand = function(self)
		foreground = self
		self:sleep(9e9)
	end,
	LoadActor 'template.lua' ,
	LoadActor 'plugins.lua' ,
	LoadActor '../lua/mods.lua' ,
}
