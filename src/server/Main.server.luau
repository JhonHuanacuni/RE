local ServerScriptService = game:GetService("ServerScriptService")

local servicesFolder = ServerScriptService:WaitForChild("Services")
local services = {}
local count = 0

for _, module in servicesFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		services[module.Name] = require(module)
		count += 1
	end
end

for _, service in services do
	if service.Init then
		service:Init(services)
	end
end

for _, service in services do
	if service.Start then
		task.spawn(service.Start, service)
	end
end

print(`[Servidor] iniciado con {count} servicios`)
