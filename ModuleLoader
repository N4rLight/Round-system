local ModuleLoader = {}

--Services
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--Required modules
local ServerModules = {}
local SharedModules = {}
local ClientModules = {}

--Main function which starts to require modules
function ModuleLoader:Start()
	local reqModulesTable = {}
	
	--Requiring shared modules 
	local modules = game.ReplicatedStorage:WaitForChild("Shared"):GetChildren()
	for _, module in ipairs(modules) do
		if module:IsA("ModuleScript") then		
			local reqModule = require(module)
			SharedModules[module.Name] = reqModule
			table.insert(reqModulesTable, reqModule)
		end
	end
	
	--Requiring server side modules
	if RunService:IsServer() then
		local modulesFolder = game.ServerScriptService:WaitForChild("ModuleScripts"):GetChildren()
		
		for name, module in ipairs(modulesFolder) do
			if module:IsA("ModuleScript") then
				local reqModule = require(module)

				ServerModules[name] = reqModule
				
				table.insert(reqModulesTable, reqModule)
			end
		end
	--Requiring client side modules
	else
		local modules = game.ReplicatedStorage:WaitForChild("ClientModules"):GetChildren()
		for _, module in ipairs(modules) do
			if module:IsA("ModuleScript") then		
				local reqModule = require(module)
				ClientModules[module.Name] = reqModule
				table.insert(reqModulesTable, reqModule)
			end
		end
	end
	
	--Initializing all of the required modules
	for _, module in ipairs(reqModulesTable) do
		if module.Init then
			task.spawn(module.Init)
		end
	end
end

--Function to get the required modules
function ModuleLoader:Get(name : string)
	--Shared modules
	if SharedModules[name] then
		return SharedModules[name]
	end
	
	--Server modules
	if RunService:IsServer() and ServerModules[name] then
		return ServerModules[name]
	--Client modules
	elseif RunService:IsClient() and ClientModules[name] then
		return ClientModules[name]
	end
	
	return nil
end

return ModuleLoader
