_G.xero = {}
return Def.ActorFrame {
	InitCommand = function(self)
		xero.foreground = self
		self:sleep(9e9)
	end,
	assert(loadfile(GAMESTATE:GetCurrentSong():GetSongDir()..'template/std.lua'))(),
	assert(loadfile(GAMESTATE:GetCurrentSong():GetSongDir()..'template/template.lua'))(),
	assert(loadfile(GAMESTATE:GetCurrentSong():GetSongDir()..'template/ease.lua'))(),
	assert(loadfile(GAMESTATE:GetCurrentSong():GetSongDir()..'template/plugins.lua'))(),
	assert(loadfile(GAMESTATE:GetCurrentSong():GetSongDir()..'lua/mods.lua'))(),
}
