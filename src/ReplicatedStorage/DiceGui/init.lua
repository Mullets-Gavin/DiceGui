--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: Custom UI replication. works great for no dependency on the character. require on both server & client and run DiceGui()
--]]

--// services
local Services = setmetatable({}, {__index = function(cache, serviceName)
    cache[serviceName] = game:GetService(serviceName)
    return cache[serviceName]
end})

--// logic
local DiceGui = {}
DiceGui.Folder = 'DiceGui'
DiceGui.Path = Services['ReplicatedStorage']
DiceGui.Container = {}
DiceGui.Initialized = false

--// variables
local DeathEvents = require(script:WaitForChild('DeathEvents'))

--// functions
local function WaitForPath(interface)
	for index,element in pairs(interface:GetChildren()) do
		local ui = interface:WaitForChild(element.Name)
		local findChildren = ui:GetChildren()
		if #findChildren > 0 then
			for each,child in pairs(findChildren) do
				WaitForPath(child)
			end
		end
	end
	return interface
end

local function Replicate()
	local player = Services['Players'].LocalPlayer
	local playerGui = player:WaitForChild('PlayerGui')
	local folder = DiceGui.Path:WaitForChild(DiceGui.Folder)
	for index,ui in pairs(folder:GetChildren()) do
		local interface = WaitForPath(ui)
		if not DiceGui.Container[interface.Name] then
			DiceGui.Container[interface.Name] = {
				['ResetOnSpawn'] = interface.ResetOnSpawn;
				['Enabled'] = interface.Enabled;
				['IgnoreGuiInset'] = interface.IgnoreGuiInset;
			}
			local findUI = playerGui:FindFirstChild(interface.Name)
			if not findUI then
				local cloneUI = interface:Clone()
				cloneUI.Parent = playerGui
			end
		elseif DiceGui.Container[interface.Name]['ResetOnSpawn'] then
			local findOld = playerGui:FindFirstChild(interface.Name)
			if findOld then findOld:Destroy() end
			local cloneUI = interface:Clone()
			cloneUI.Parent = playerGui
		end
	end
	if not DiceGui.Initialized then
		DiceGui.Initialized = true
		print('[DICE GUI]: Successfully loaded PlayerGui with contents from',DiceGui.Folder..', located in',DiceGui.Path)
	end
end

local function Initialize()
	local folder = Instance.new('Folder')
	folder.Name = DiceGui.Folder
	folder.Parent = DiceGui.Path
	for index,interface in pairs(Services['StarterGui']:GetChildren()) do
		interface.Parent = folder
	end
	DiceGui.Initialized = true
	print('[DICE GUI]: Successfully initialized StarterGui for automatic PlayerGui replication')
end

return function()
	if Services['RunService']:IsServer() then
		Initialize()
	elseif Services['RunService']:IsClient() then
		Replicate()
		DeathEvents.bind_to_character_add(function(Character)
			Replicate()
		end)
		DeathEvents.hook()
	end
end