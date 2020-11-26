local path_to_plugins = GAMESTATE:GetCurrentSong():GetSongDir()..'plugins/'
local af = Def.ActorFrame {}
for _, filename in ipairs(FILEMAN:GetDirListing(path_to_plugins)) do
	if string.sub(p[i], -4, -1) == '.lua' then
		af[#af + 1] = loadfile(path_to_plugins..filename)()
	end
end
return af
