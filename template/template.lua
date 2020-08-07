local _ENV = xero

max_pn = 2 -- default: `2`
local debug_print_applymodifier_input = false -- default: `false`
local debug_print_mod_targets = false -- default: `false`

function copy(src)
	local dest = {}
	for k, v in pairs(src) do
		dest[k] = v
	end
	return dest
end

xero = xero
type = type
print = print
pairs = pairs
ipairs = ipairs
unpack = unpack
tonumber = tonumber
tostring = tostring
math = copy(math)
table = copy(table)

dw = DISPLAY:GetDisplayWidth()
dh = DISPLAY:GetDisplayHeight()

scx = SCREEN_CENTER_X
scy = SCREEN_CENTER_Y
sw = SCREEN_WIDTH
sh = SCREEN_HEIGHT
e = 'end'

plr = {1, 2}

function sprite(self)
	self:basezoomx(sw / dw)
	self:basezoomy(-sh / dh)
	self:x(scx)
	self:y(scy)
end

function aft(self)
	self:SetWidth(dw)
	self:SetHeight(dh)
	self:EnableDepthBuffer(false)
	self:EnableAlphaBuffer(false)
	self:EnableFloat(false)
	self:EnablePreserveTexture(true)
	self:Create()
end

local function screen_error(output, depth, name)
	local depth = 3 + (depth or 0)
	local _, err = pcall(error, name and (name .. ':' .. output) or output, depth)
	SCREENMAN:SystemMessage(err)
end

local function push(self, obj)
	self.n = self.n + 1
	self[self.n] = obj
end

local default_plr = {1, 2}

local eases = {n = 0}

function ease(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'ease'
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return ease
	end
	if type(self[1]) ~= 'number' then
		screen_error('beat missing', depth, name)
		return ease
	end
	if type(self[2]) ~= 'number' then
		screen_error('len / end missing', depth, name)
		return ease
	end
	if type(self[3]) ~= 'function' then
		screen_error('invalid ease function', depth, name)
		return ease
	end
	local i = 4
	while self[i] do
		if type(self[i]) ~= 'number' then
			screen_error('invalid mod percent', depth, name)
			return ease
		end
		if type(self[i + 1]) ~= 'string' and type(self[i + 1]) ~= 'function' then
			screen_error('invalid mod', depth, name)
			return ease
		end
		i = i + 2
	end
	self.n = i - 1
	
	local result = self[3](1)
	if type(result) ~= 'number' then
		screen_error('invalid ease function', depth, name)
		return ease
	end
	if result < 0.5 then
		self.transient = 1
	end
	if self.mode or self.m then
		self[2] = self[2] - self[1]
	end
	local plr = self.plr or rawget(xero, plr) or default_plr
	if type(plr) == 'number' then
		self.plr = plr
		push(eases, self)
	elseif type(plr) == 'table' then
		self.plr = nil
		for _, plr in ipairs(plr) do
			local copy = copy(self)
			copy.plr = plr
			push(eases, copy)
		end
	else
		screen_error('invalid plr', depth, name)
		return ease
	end
	
	return ease
end

function add(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local name = name or 'add'
	self.relative = true
	ease(self, depth, name)
	return add
end

function set(self, depth, name)
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	local a, b, i = 0, instant, 2
	while a do
		a, self[i] = self[i], a
		b, self[i + 1] = self[i + 1], b
		i = i + 2
	end
	ease(self, depth, name)
	return set
end

-- mod aliases, or ease vars
local aliases = {}

-- reverse aliases, looks up the name of functions
local reverse_aliases = {}

-- alias a mod (useful if you want string names for function-eases)
function alias(key, value)
	-- accept {} syntax
	if type(key) == 'table' then
		key, value = key[1], key[2]
	end
	
	if type(key) ~= 'string' then
		screen_error('unexpected argument 1' , 1, 'alias')
		return alias
	end
		
	if type(value) ~= 'string' and type(value) ~= 'function' and type(value) ~= 'nil' then
		screen_error('unexpected argument 2' , 1, 'alias')
		return alias
	end
	
	-- make the alias
	aliases[key] = value or function() end
	
	-- mark the reverse alias
	reverse_aliases[aliases[key]] = key
	
	-- return for chain calls
	return alias
end

-- the table of scheduled functions and perframes
local funcs = {n = 0}

function func(self, depth, name)
	local name = name or 'func'
	local depth = 1 + (type(depth) == 'number' and depth or 0)
	if type(self) ~= 'table' then
		screen_error('curly braces expected', depth, name)
		return func
	end
	
	local a, b, c = self[1], self[2], self[3]
	
	-- three possible valid configurations
	if type(a) == 'number' and type(b) == 'function' then
		a, b, c = a, nil, b
	elseif type(a) == 'number' and type(b) == 'number' and type(c) == 'function' then
		-- a, b, c = a, b, c
	elseif type(a) == 'string' then
		return func
	else
		screen_error('invalid arguments', depth, name)
		return func
	end
	self[1], self[2], self[3] = a, b, c
	if self.mode or self.m then
		self[2] = self[2] - self[1]
	end
	
	self.mods = {}
	for pn = 1, max_pn do
		self.mods[pn] = {}
	end
	
	push(funcs, self)
	
	if self.defer then
		self.priority = -funcs.n
	else
		self.priority = funcs.n
	end
	
	return func
end

function on_command(self)
	local mt = {}
	function mt.__index(self, k)
		self[k] = setmetatable({}, mt)
		return self[k]
	end
	
	local actors = setmetatable({}, mt)
	
	local list = {n = 0}
	local code = {n = 0}
	
	local function sweep(actor)
		if actor.GetNumChildren then
			for i = 1, actor:GetNumChildren() do
				sweep(actor:GetChildAt(i))
			end
		end
		
		local name = actor:GetName()
		if name and name ~= '' and not name:find('/') then
			push(list, actor)
			local n = code.n
			code[n + 1], code[n + 2], code[n + 3], code[n + 4], code[n + 5] = '\tactors.', name, ' = list[', list.n, ']\n'
			code.n = code.n + 5
		end
	end
	
	push(code, 'return function(list, actors)\n')
	sweep(foreground)
	push(code, 'end')
	
	local code = table.concat(code)
	
	local load_actors = xero(assert(loadstring(code)))()
	load_actors(list, actors)
	
	local function clear_metatables(tab)
		setmetatable(tab, nil)
		for _, obj in pairs(tab) do
			if type(obj) == 'table' and getmetatable(obj) == mt then
				clear_metatables(obj)
			end
		end
	end
	
	clear_metatables(actors)
	
	for name, actor in pairs(actors) do
		xero[name] = actor
	end
	
	self:queuecommand('BeginUpdate')
	
end

function begin_update_command(self)
	
	for _, element in ipairs {
		'Overlay',
		'Underlay',
		'ScoreP1',
		'ScoreP2',
		'LifeP1',
		'LifeP2',
	} do
		local child = SCREENMAN:GetTopScreen():GetChild(element)
		if child then
			child:visible(false)
		end
	end
	
	P = {}
	for pn = 1, max_pn do
		local player = SCREENMAN:GetTopScreen():GetChild('PlayerP' .. pn)
		xero['P' .. pn] = player
		P[pn] = player
	end
	
	foreground:playcommand('Load')
	
	stable_sort(eases, function(a, b) return a[1] < b[1] end)
	stable_sort(funcs, function(a, b)
		if a[1] == b[1] then
			local x, y = a.priority, b.priority
			return x * x * y < x * y * y
		else
			return a[1] < b[1]
		end
	end)
	
	-- de-alias the alias table
	for key, value in pairs(aliases) do
		while aliases[value] do
			value = aliases[value]
		end
		aliases[key] = value
	end
	
	-- de-alias the ease table
	for _, entry in ipairs(eases) do
		for i = 5, entry.n, 2 do
			entry[i] = aliases[entry[i]] or entry[i]
		end
	end
	
	self:luaeffect('Update')
	
end

local targets_mt = {__index = function() return 0 end}

local targets = {}
for pn = 1, max_pn do
	targets[pn] = setmetatable({}, targets_mt)
end

local mods_mt = {}
for pn = 1, max_pn do
	mods_mt[pn] = {__index = targets[pn]}
end

local mods = {}
for pn = 1, max_pn do
	mods[pn] = setmetatable({}, mods_mt[pn])
end

local poptions = {}
local poptions_mt = {}
local poptions_logging_target
for pn = 1, max_pn do
	local pn = pn
	local mods_pn = mods[pn]
	local mt = {
		__index = function(self, k)
			return mods_pn[aliases[k] or k]
		end,
		__newindex = function(self, k, v)
			k = aliases[k] or k
			mods_pn[k] = v
			if v then
				poptions_logging_target[pn][k] = true
			end
		end,
	}
	poptions_mt[pn] = mt
	poptions[pn] = setmetatable({}, mt)
end

local eases_index = 1
local funcs_index = 1

local active_eases = {n = 0}
local active_funcs = perframe_data_structure(function(a, b)
	local x, y = a.priority, b.priority
	return x * x * y < x * y * y
end)

-- default eases
function xmod(x) return '*9e9 ' .. x .. 'x' end
function cmod(c) return '*9e9 c' .. c end
alias {'xmod', xmod} {'cmod', cmod}
ease {0, 0, function() return 1 end, 100, 'zoom', 100, 'zoomx', 100, 'zoomy', 100, 'zoomz'}

local function apply_modifiers(str, pn)
	GAMESTATE:GetPlayerState(pn - 1):GetPlayerOptions('ModsLevel_Song'):FromString(str)
end

for pn = 1, max_pn do
	apply_modifiers('clearall,*0 0x,*9e9 overhead', pn)
end

if debug_print_applymodifier_input then
	local old_apply_modifiers = apply_modifiers
	apply_modifiers = function(str, pn)
		if debug_print_mod_targets == true or debug_print_mod_targets < beat then
			print('PLAYER ' .. pn .. ': ' .. str)
			if debug_print_mod_targets ~= true then
				apply_modifiers = old_apply_modifiers
			end 
		end
		old_apply_modifiers(str, pn)
	end
end

local oldbeat = 0
function update_command(self)
	
	local beat = GAMESTATE:GetSongBeat()
	if beat == oldbeat then return end
	oldbeat = beat
	
	while eases_index <= eases.n and eases[eases_index][1] < beat do
		local e = eases[eases_index]
		local plr = e.plr
		e.offset = e.transient and 0 or 1
		if not e.relative then
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				e[i] = e[i] - targets[plr][mod]
			end
		end
		if not e.transient then
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				targets[plr][mod] = targets[plr][mod] + e[i]
			end
		end
		push(active_eases, e)
		eases_index = eases_index + 1
	end
	
	local active_eases_index = 1
	while active_eases_index <= active_eases.n do
		local e = active_eases[active_eases_index]
		local plr = e.plr
		if beat < e[1] + e[2] then
			local e3 = e[3]((beat - e[1]) / e[2]) - e.offset
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				mods[plr][mod] = mods[plr][mod] + e3 * e[i]
			end
			active_eases_index = active_eases_index + 1
		else
			for i = 4, e.n, 2 do
				local mod = e[i + 1]
				mods[plr][mod] = mods[plr][mod] + 0
			end
			active_eases[active_eases_index] = active_eases[active_eases.n]
			active_eases[active_eases.n] = nil
			active_eases.n = active_eases.n - 1
		end
	end
	
	while funcs_index <= funcs.n and funcs[funcs_index][1] < beat do
		local e = funcs[funcs_index]
		if not e[2] then
			e[3](beat)
		elseif beat < e[1] + e[2] then
			active_funcs:add(e)
		end
		funcs_index = funcs_index + 1
	end
	
	while true do
		local e = active_funcs:next()
		if not e then break end
		if beat < e[1] + e[2] then
			poptions_logging_target = e.mods
			e[3](beat, poptions)
		else
			for pn = 1, max_pn do
				for mod, _ in e.mods[pn] do
					mods[pn][mod] = mods[pn][mod] + 0
				end
			end
			active_funcs:remove()
		end
	end
	
	for pn = 1, max_pn do
		local modifiers = {n = 0}
		for mod, percent in pairs(mods[pn]) do
			local modstring
			if type(mod) == 'function' then
				modstring = mod(percent, pn)
				if modstring then
					push(modifiers, modstring)
				end
			else
				modstring = '*9e9 ' .. percent .. ' ' .. mod
				push(modifiers, modstring)
			end
			mods[pn][mod] = nil
		end
		if modifiers.n ~= 0 then
			local str = table.concat(modifiers, ',')
			apply_modifiers(str, pn)
		end
	end
	
	if debug_print_mod_targets then
		if debug_print_mod_targets == true or debug_print_mod_targets < beat then
			for pn = 1, max_pn do
				local outputs = {}
				local i = 0
				for k, v in pairs(targets[pn]) do
					if v ~= 0 then
						i = i + 1
						outputs[i] = reverse_aliases[k] or tostring(k) .. ': ' .. tostring(v)
					end
				end
				print('Player ' .. pn .. ' at beat ' .. beat .. ' --> ' .. table.concat(outputs, ', '))
			end
			debug_print_mod_targets = (debug_print_mod_targets == true)
		end
	end
end


return Def.ActorFrame {
	BeginUpdateCommand = begin_update_command,
	OnCommand = on_command,
	UpdateCommand = update_command,
}
