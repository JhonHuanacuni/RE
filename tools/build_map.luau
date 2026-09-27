-- Construye el mapa de prueba (fase 1). Ejecutar en Studio en modo edición.
-- Reemplaza Workspace.Map si ya existe, así que se puede volver a ejecutar tras cambiar parámetros.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local PLOT_COUNT = 8
local PLOT_RADIUS = 210
local PLOT_WIDTH = 56
local PLOT_DEPTH = 70
local WALL_HEIGHT = 12
local WALL_THICKNESS = 2
local DOOR_WIDTH = 16
local ARENA_RADIUS = 90
local MAP_HALF_SIZE = 390
local ZONE_RADIUS = 135

local COLORS = {
	Ground = Color3.fromRGB(106, 170, 80),
	Arena = Color3.fromRGB(226, 200, 140),
	Path = Color3.fromRGB(205, 180, 125),
	PlotFloor = Color3.fromRGB(200, 200, 205),
	Wall = Color3.fromRGB(120, 125, 140),
	Pedestal = Color3.fromRGB(245, 245, 245),
	CollectPad = Color3.fromRGB(70, 200, 90),
	LockButton = Color3.fromRGB(220, 60, 60),
	Platform = Color3.fromRGB(150, 110, 80),
	Island = Color3.fromRGB(90, 160, 220),
	Tower = Color3.fromRGB(110, 90, 160),
	Step = Color3.fromRGB(255, 200, 60),
}

local function makePart(props)
	local part = Instance.new(props.ClassName or "Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		if key ~= "ClassName" and key ~= "Parent" then
			part[key] = value
		end
	end
	part.Parent = props.Parent
	return part
end

local function makeFolder(name, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function makeZone(tier, cframe, size, parent)
	local zone = makePart({
		Name = tier .. "Zone",
		Size = size,
		CFrame = cframe,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = parent,
	})
	zone:SetAttribute("Tier", tier)
	return zone
end

local function polar(angle, radius, y)
	return Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius)
end

local function makeRamp(bottom, top, width, parent)
	local length = (top - bottom).Magnitude
	local cframe = CFrame.lookAt(bottom, top) * CFrame.new(0, -0.5, -length / 2)
	return makePart({
		Name = "Ramp",
		Size = Vector3.new(width, 1, length),
		CFrame = cframe,
		Color = COLORS.Platform,
		Material = Enum.Material.WoodPlanks,
		Parent = parent,
	})
end

for _, name in { "Map", "Baseplate", "SpawnLocation" } do
	local existing = Workspace:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

local map = makeFolder("Map", Workspace)
local environment = makeFolder("Environment", map)
local plots = makeFolder("Plots", map)
local zones = makeFolder("Zones", map)
local dropZones = makeFolder("DropZones", map)

-- Suelo, arena y límites

makePart({
	Name = "Ground",
	Size = Vector3.new(MAP_HALF_SIZE * 2 + 20, 2, MAP_HALF_SIZE * 2 + 20),
	CFrame = CFrame.new(0, -1, 0),
	Color = COLORS.Ground,
	Material = Enum.Material.Grass,
	Parent = environment,
})

makePart({
	Name = "Arena",
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(1, ARENA_RADIUS * 2, ARENA_RADIUS * 2),
	CFrame = CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Color = COLORS.Arena,
	Material = Enum.Material.Sand,
	Parent = environment,
})

local boundaries = makeFolder("Boundaries", environment)
for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
	local isX = side.X ~= 0
	makePart({
		Name = "Boundary",
		Size = if isX
			then Vector3.new(2, 300, MAP_HALF_SIZE * 2)
			else Vector3.new(MAP_HALF_SIZE * 2, 300, 2),
		CFrame = CFrame.new(side * MAP_HALF_SIZE + Vector3.new(0, 150, 0)),
		Transparency = 1,
		Parent = boundaries,
	})
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Anchored = true
spawn.Neutral = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 0.5, 60)
spawn.Material = Enum.Material.SmoothPlastic
spawn.TopSurface = Enum.SurfaceType.Smooth
spawn.Parent = environment

-- Bases de los jugadores

local PEDESTAL_OFFSETS = {
	Vector3.new(-18, 0, -12),
	Vector3.new(-18, 0, 4),
	Vector3.new(-18, 0, 20),
	Vector3.new(18, 0, -12),
	Vector3.new(18, 0, 4),
	Vector3.new(18, 0, 20),
}

local function buildSign(parent, cframe)
	local sign = makePart({
		Name = "Sign",
		Size = Vector3.new(24, 5, 1),
		CFrame = cframe,
		Color = Color3.fromRGB(40, 40, 50),
		Parent = parent,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Base libre"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	return sign
end

local function buildPlot(index)
	local angle = (index - 1) / PLOT_COUNT * math.pi * 2
	local origin = CFrame.lookAt(polar(angle, PLOT_RADIUS, 0), Vector3.zero)
	local function at(x, y, z)
		return origin * CFrame.new(x, y, z)
	end

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("PlotId", index)
	model:SetAttribute("OwnerUserId", 0)
	model.Parent = plots

	local floor = makePart({
		Name = "Floor",
		Size = Vector3.new(PLOT_WIDTH, 1, PLOT_DEPTH),
		CFrame = at(0, 0.5, 0),
		Color = COLORS.PlotFloor,
		Material = Enum.Material.Concrete,
		Parent = model,
	})
	model.PrimaryPart = floor

	local floorTop = 1
	local wallY = floorTop + WALL_HEIGHT / 2
	local walls = makeFolder("Walls", model)
	local function wall(size, cframe)
		makePart({ Name = "Wall", Size = size, CFrame = cframe, Color = COLORS.Wall, Parent = walls })
	end

	wall(Vector3.new(PLOT_WIDTH, WALL_HEIGHT, WALL_THICKNESS), at(0, wallY, PLOT_DEPTH / 2 - WALL_THICKNESS / 2))
	for _, sideX in { -1, 1 } do
		wall(
			Vector3.new(WALL_THICKNESS, WALL_HEIGHT, PLOT_DEPTH),
			at(sideX * (PLOT_WIDTH / 2 - WALL_THICKNESS / 2), wallY, 0)
		)
		local segmentWidth = (PLOT_WIDTH - DOOR_WIDTH) / 2
		wall(
			Vector3.new(segmentWidth, WALL_HEIGHT, WALL_THICKNESS),
			at(sideX * (DOOR_WIDTH / 2 + segmentWidth / 2), wallY, -PLOT_DEPTH / 2 + WALL_THICKNESS / 2)
		)
	end
	wall(
		Vector3.new(DOOR_WIDTH, 2, WALL_THICKNESS),
		at(0, floorTop + WALL_HEIGHT - 1, -PLOT_DEPTH / 2 + WALL_THICKNESS / 2)
	)

	makePart({
		Name = "Door",
		Size = Vector3.new(DOOR_WIDTH, WALL_HEIGHT - 2, WALL_THICKNESS),
		CFrame = at(0, floorTop + (WALL_HEIGHT - 2) / 2, -PLOT_DEPTH / 2 + WALL_THICKNESS / 2),
		Color = Color3.fromRGB(90, 170, 255),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		Parent = model,
	})

	buildSign(model, at(0, floorTop + WALL_HEIGHT + 2.5, -PLOT_DEPTH / 2 + WALL_THICKNESS / 2))

	local pedestals = makeFolder("Pedestals", model)
	for i, offset in PEDESTAL_OFFSETS do
		local pedestal = makePart({
			Name = "Pedestal" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2, 7, 7),
			CFrame = at(offset.X, floorTop + 1, offset.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = COLORS.Pedestal,
			Parent = pedestals,
		})
		pedestal:SetAttribute("Index", i)
	end

	makePart({
		Name = "CollectPad",
		Size = Vector3.new(10, 0.4, 10),
		CFrame = at(0, floorTop + 0.2, 24),
		Color = COLORS.CollectPad,
		Material = Enum.Material.Neon,
		Parent = model,
	})

	makePart({
		Name = "LockButton",
		Size = Vector3.new(5, 1, 5),
		CFrame = at(-18, floorTop + 0.5, -27),
		Color = COLORS.LockButton,
		Material = Enum.Material.Neon,
		Parent = model,
	})

	makePart({
		Name = "Spawn",
		Size = Vector3.new(6, 1, 6),
		CFrame = at(0, floorTop + 0.5, 8),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = model,
	})

	local pathLength = PLOT_RADIUS - PLOT_DEPTH / 2 - ARENA_RADIUS + 2
	makePart({
		Name = "Path",
		Size = Vector3.new(DOOR_WIDTH, 0.2, pathLength),
		CFrame = at(0, 0.05, -PLOT_DEPTH / 2 - pathLength / 2),
		Color = COLORS.Path,
		Material = Enum.Material.Sand,
		Parent = environment,
	})
end

for index = 1, PLOT_COUNT do
	buildPlot(index)
end

-- Zonas de caída: Ground (arena), Mid (plataformas con rampa), High (islas con parkour), Top (torre central)

makeZone("Ground", CFrame.new(0, 0.5, 0), Vector3.new(140, 1, 140), dropZones)

local gapAngle = math.pi / PLOT_COUNT
for k = 0, 3 do
	local angle = gapAngle + k * math.pi / 2
	local center = polar(angle, ZONE_RADIUS, 0)
	local platformTop = 16
	local platformModel = Instance.new("Model")
	platformModel.Name = "MidPlatform" .. (k + 1)
	platformModel.Parent = zones

	makePart({
		Name = "Platform",
		Size = Vector3.new(24, 2, 24),
		CFrame = CFrame.new(center + Vector3.new(0, platformTop - 1, 0)),
		Color = COLORS.Platform,
		Material = Enum.Material.WoodPlanks,
		Parent = platformModel,
	})
	makePart({
		Name = "Pillar",
		Size = Vector3.new(6, platformTop - 2, 6),
		CFrame = CFrame.new(center + Vector3.new(0, (platformTop - 2) / 2, 0)),
		Color = COLORS.Wall,
		Parent = platformModel,
	})
	local inward = -center.Unit
	local rampTop = center + inward * 12 + Vector3.new(0, platformTop, 0)
	local rampBottom = center + inward * 52
	makeRamp(rampBottom, rampTop, 10, platformModel)

	makeZone("Mid", CFrame.new(center + Vector3.new(0, platformTop + 0.5, 0)), Vector3.new(20, 1, 20), dropZones)
end

for k = 0, 3 do
	local angle = gapAngle + math.pi / 4 + k * math.pi / 2
	local center = polar(angle, ZONE_RADIUS, 0)
	local islandTop = 46
	local islandModel = Instance.new("Model")
	islandModel.Name = "HighIsland" .. (k + 1)
	islandModel.Parent = zones

	makePart({
		Name = "Island",
		Size = Vector3.new(24, 3, 24),
		CFrame = CFrame.new(center + Vector3.new(0, islandTop - 1.5, 0)),
		Color = COLORS.Island,
		Material = Enum.Material.Glacier,
		Parent = islandModel,
	})

	local startAngle = math.atan2(-center.Z, -center.X)
	for step = 1, 9 do
		local stepAngle = startAngle + (step - 1) * math.rad(30)
		local offset = Vector3.new(math.cos(stepAngle) * 17, 0, math.sin(stepAngle) * 17)
		makePart({
			Name = "Step" .. step,
			Size = Vector3.new(6, 1, 6),
			CFrame = CFrame.new(center + offset + Vector3.new(0, step * 5 - 0.5, 0)),
			Color = COLORS.Step,
			Parent = islandModel,
		})
	end

	makeZone("High", CFrame.new(center + Vector3.new(0, islandTop + 0.5, 0)), Vector3.new(20, 1, 20), dropZones)
end

local towerHeight = 72
local tower = Instance.new("Model")
tower.Name = "CentralTower"
tower.Parent = zones
makePart({
	Name = "Pillar",
	Size = Vector3.new(16, towerHeight, 16),
	CFrame = CFrame.new(0, towerHeight / 2, 0),
	Color = COLORS.Tower,
	Material = Enum.Material.Slate,
	Parent = tower,
})
makePart({
	ClassName = "TrussPart",
	Name = "Truss",
	Size = Vector3.new(2, towerHeight, 2),
	CFrame = CFrame.new(0, towerHeight / 2, 9),
	Color = COLORS.Step,
	Parent = tower,
})
makeZone("Top", CFrame.new(0, towerHeight + 0.5, 0), Vector3.new(12, 1, 12), dropZones)

-- Iluminación

Lighting.ClockTime = 14
Lighting.Brightness = 2
Lighting.GlobalShadows = true
Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)

return `Mapa construido: {#plots:GetChildren()} bases, {#dropZones:GetChildren()} zonas de caída`
