local controllersFolder = script.Parent:WaitForChild("Controllers")
local controllers = {}
local count = 0

for _, module in controllersFolder:GetChildren() do
	if module:IsA("ModuleScript") then
		controllers[module.Name] = require(module)
		count += 1
	end
end

for _, controller in controllers do
	if controller.Init then
		controller:Init(controllers)
	end
end

for _, controller in controllers do
	if controller.Start then
		task.spawn(controller.Start, controller)
	end
end

print(`[Cliente] iniciado con {count} controladores`)
