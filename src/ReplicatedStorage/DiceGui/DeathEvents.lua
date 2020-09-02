--[[
	@Author: Lucas W. (codes4breakfast)
	@Desc: provides a simple event list module, upon which all events are disconnected when the player dies.
	
	USAGE:
		1) Require the module and call the Module.hook() function once.
		2) Add events with Module.add_connection(event), such as in Module.add_connection(workspace.Changed:Connect()).
		3) When the player dies (or when a character is removed), all events will be disconnected and the event list cleared.
]]

local player = game:GetService("Players").LocalPlayer
local new_char_functions, died_char_functions, events, alive = {}, {}, {}, false
local next_death_functions = {}
local next_added_functions = {}
local Module = {}
local listening = false

Module.add_connections = function(...)
	for _, c in ipairs({...}) do
		table.insert(events, c)
	end
end

Module.bind_to_character_add = function(closure)
	table.insert(new_char_functions, closure)
end

Module.bind_to_character_death = function(closure)
	table.insert(died_char_functions, closure)
end

Module.bind_to_next_character_add = function(closure)
	table.insert(next_added_functions, closure)
end

Module.bind_to_next_character_death = function(closure)
	table.insert(next_death_functions, closure)
end

Module.disconnect_connections = function()
	for _, event in ipairs(events) do
		if event.Connected then
			event:Disconnect()
		end
	end
	events = {}
	
	if alive then
		for _, c in ipairs(died_char_functions) do
			c()
		end
		for _, c in ipairs(next_death_functions) do
			c()
		end
		next_death_functions = {}
		alive = false
	end
end

Module._add_character = function(character)
	if not character.Parent then
		character.AncestryChanged:Wait()
	end
	
	while alive do wait() end
	
	local humanoid = character:WaitForChild("Humanoid", 20)
	if not humanoid then
		return
	end
	
	alive = true
	for _, f in ipairs(new_char_functions) do
		f(character)
	end
	for _, f in ipairs(next_added_functions) do
		f(character)
	end
	next_added_functions = {}
	humanoid.Died:Connect(Module.disconnect_connections)
end

Module.hook = function()
	if listening then
		return
	end
	listening = true
	
	if player.Character then
		-- this function might yield and we want to connect to it immediately
		coroutine.wrap(Module._add_character)(player.Character)
	end
	player.CharacterAdded:Connect(Module._add_character)
	player.CharacterRemoving:Connect(Module.disconnect_connections)
end

return Module