local path_to_plugins = GAMESTATE:GetCurrentSong():GetSongDir() .. 'plugins/'
local plugins = Def.ActorFrame {}
for i, v in ipairs(FILEMAN:GetDirListing(path_to_plugins)) do
	plugins = plugins .. {
		LoadActor('../plugins/' .. v)
	}
end
return plugins