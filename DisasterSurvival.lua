--[[
🌪️ SUPERVIVENCIA A DESASTRES NATURALES - JUEGO COMPLETO
Coloca este script en ServerScriptService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

-- CONFIGURACIÓN DEL JUEGO
local GAME_CONFIG = {
    ROUND_TIME = 120,           -- Duración de cada ronda
    INTERMISSION_TIME = 15,     -- Tiempo entre rondas
    MIN_PLAYERS = 2,            -- Mínimo de jugadores para iniciar
    SPAWN_HEIGHT = 50,          -- Altura del spawn
    SAFE_ZONE_SIZE = 20         -- Tamaño de la zona segura
}

-- ESTADO DEL JUEGO
local GameState = {
    Status = "Intermission",    -- "Intermission", "InRound", "Ending"
    Timer = GAME_CONFIG.INTERMISSION_TIME,
    CurrentDisaster = nil,
    AlivePlayers = {},
    RoundNumber = 0,
    Map = nil
}

-- CREAR REMOTES
local function createRemote(name, type)
    local remote = ReplicatedStorage:FindFirstChild(name)
    if not remote then
        remote = Instance.new(type or "RemoteEvent")
        remote.Name = name
        remote.Parent = ReplicatedStorage
    end
    return remote
end

local UpdateClient = createRemote("UpdateClient")
local PlayerAction = createRemote("PlayerAction")

-- MAPAS DISPONIBLES
local MAPS = {
    {
        Name = "Ciudad Moderna",
        Buildings = 15,
        Theme = "Urban",
        SpawnPoints = 20
    },
    {
        Name = "Bosque Salvaje",
        Buildings = 8,
        Theme = "Forest",
        SpawnPoints = 16
    },
    {
        Name = "Playa Tropical",
        Buildings = 10,
        Theme = "Beach",
        SpawnPoints = 18
    }
}

-- DESASTRES NATURALES
local DISASTERS = {
    {
        Name = "🌪️ TORNADO",
        Duration = 30,
        Intensity = "Extreme",
        Description = "¡Un tornado masivo se acerca! Busca refugio sólido.",
        Color = Color3.fromRGB(100, 100, 100)
    },
    {
        Name = "🌊 TSUNAMI",
        Duration = 25,
        Intensity = "Extreme",
        Description = "¡Ola gigante! Sube a terreno alto inmediatamente.",
        Color = Color3.fromRGB(0, 100, 200)
    },
    {
        Name = "🌋 ERUPCIÓN VOLCÁNICA",
        Duration = 35,
        Intensity = "High",
        Description = "¡Lava y rocas caen del cielo! Busca cobertura.",
        Color = Color3.fromRGB(255, 100, 0)
    },
    {
        Name = "⚡ TORMENTA ELÉCTRICA",
        Duration = 20,
        Intensity = "Medium",
        Description = "¡Rayos mortales! Evita objetos metálicos y agua.",
        Color = Color3.fromRGB(255, 255, 0)
    },
    {
        Name = "🌨️ VENTISCA EXTREMA",
        Duration = 40,
        Intensity = "High",
        Description = "¡Frío mortal! Busca calor o morirás congelado.",
        Color = Color3.fromRGB(200, 200, 255)
    },
    {
        Name = "🔥 INCENDIO FORESTAL",
        Duration = 30,
        Intensity = "High",
        Description = "¡Fuego descontrolado! Huye hacia zona segura.",
        Color = Color3.fromRGB(255, 50, 0)
    },
    {
        Name = "💨 HURACÁN",
        Duration = 45,
        Intensity = "Extreme",
        Description = "¡Vientos devastadores! Agárrate fuerte.",
        Color = Color3.fromRGB(150, 150, 150)
    },
    {
        Name = "🌍 TERREMOTO",
        Duration = 15,
        Intensity = "Extreme",
        Description = "¡La tierra tiembla! Aléjate de estructuras.",
        Color = Color3.fromRGB(139, 69, 19)
    }
}

-- FUNCIÓN PARA NOTIFICAR CLIENTES
local function notifyAllClients(eventType, data)
    UpdateClient:FireAllClients(eventType, data)
end

local function notifyClient(player, eventType, data)
    UpdateClient:FireClient(player, eventType, data)
end

-- CREAR MAPA BÁSICO
local function createMap(mapData)
    -- Limpiar mapa anterior
    if GameState.Map then
        GameState.Map:Destroy()
    end
    
    local map = Instance.new("Model")
    map.Name = "DisasterMap"
    map.Parent = workspace
    GameState.Map = map
    
    -- Crear terreno base
    local terrain = Instance.new("Part")
    terrain.Name = "Terrain"
    terrain.Size = Vector3.new(500, 10, 500)
    terrain.Position = Vector3.new(0, -5, 0)
    terrain.Anchored = true
    terrain.BrickColor = BrickColor.new("Bright green")
    terrain.Material = Enum.Material.Grass
    terrain.Parent = map
    
    -- Crear edificios
    for i = 1, mapData.Buildings do
        local building = Instance.new("Part")
        building.Name = "Building" .. i
        building.Size = Vector3.new(
            math.random(20, 40),
            math.random(30, 80),
            math.random(20, 40)
        )
        building.Position = Vector3.new(
            math.random(-200, 200),
            building.Size.Y / 2,
            math.random(-200, 200)
        )
        building.Anchored = true
        building.BrickColor = BrickColor.new("Medium stone grey")
        building.Material = Enum.Material.Concrete
        building.Parent = map
        
        -- Agregar detalles
        local roof = Instance.new("Part")
        roof.Name = "Roof"
        roof.Size = Vector3.new(building.Size.X + 2, 2, building.Size.Z + 2)
        roof.Position = building.Position + Vector3.new(0, building.Size.Y/2 + 1, 0)
        roof.Anchored = true
        roof.BrickColor = BrickColor.new("Dark stone grey")
        roof.Material = Enum.Material.Slate
        roof.Parent = map
    end
    
    -- Crear zona segura
    local safeZone = Instance.new("Part")
    safeZone.Name = "SafeZone"
    safeZone.Size = Vector3.new(GAME_CONFIG.SAFE_ZONE_SIZE, 1, GAME_CONFIG.SAFE_ZONE_SIZE)
    safeZone.Position = Vector3.new(0, 0.5, 0)
    safeZone.Anchored = true
    safeZone.BrickColor = BrickColor.new("Bright green")
    safeZone.Material = Enum.Material.Neon
    safeZone.Transparency = 0.5
    safeZone.Parent = map
    
    print("🗺️ Mapa creado: " .. mapData.Name)
end

-- SPAWN DE JUGADORES
local function spawnPlayer(player)
    if player.Character then
        player.Character:Destroy()
    end
    
    player:LoadCharacter()
    
    task.wait(0.1)
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Position = Vector3.new(
            math.random(-50, 50),
            GAME_CONFIG.SPAWN_HEIGHT,
            math.random(-50, 50)
        )
        
        -- Dar herramientas básicas
        local tool = Instance.new("Tool")
        tool.Name = "🔧 Kit de Supervivencia"
        tool.RequiresHandle = false
        tool.Parent = player.Backpack
        
        GameState.AlivePlayers[player.UserId] = true
    end
end

-- EFECTOS DE DESASTRES
local function createTornado()
    local tornado = Instance.new("Part")
    tornado.Name = "Tornado"
    tornado.Size = Vector3.new(50, 200, 50)
    tornado.Position = Vector3.new(math.random(-200, 200), 100, math.random(-200, 200))
    tornado.Shape = Enum.PartType.Cylinder
    tornado.BrickColor = BrickColor.new("Dark stone grey")
    tornado.Material = Enum.Material.Neon
    tornado.Anchored = true
    tornado.CanCollide = false
    tornado.Transparency = 0.3
    tornado.Parent = GameState.Map
    
    -- Movimiento del tornado
    task.spawn(function()
        local startTime = tick()
        while tornado.Parent and tick() - startTime < 30 do
            tornado.Position = tornado.Position + Vector3.new(
                math.random(-10, 10),
                0,
                math.random(-10, 10)
            )
            tornado.Rotation = tornado.Rotation + Vector3.new(0, 10, 0)
            
            -- Dañar jugadores cercanos
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (player.Character.HumanoidRootPart.Position - tornado.Position).Magnitude
                    if distance < 60 then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.Health = humanoid.Health - 20
                            -- Efecto de succión
                            local bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                            bodyVelocity.Velocity = (tornado.Position - player.Character.HumanoidRootPart.Position).Unit * 50
                            bodyVelocity.Parent = player.Character.HumanoidRootPart
                            Debris:AddItem(bodyVelocity, 1)
                        end
                    end
                end
            end
            
            task.wait(0.5)
        end
        tornado:Destroy()
    end)
end

local function createTsunami()
    local wave = Instance.new("Part")
    wave.Name = "TsunamiWave"
    wave.Size = Vector3.new(600, 100, 50)
    wave.Position = Vector3.new(0, 50, -300)
    wave.BrickColor = BrickColor.new("Deep blue")
    wave.Material = Enum.Material.Water
    wave.Anchored = true
    wave.CanCollide = false
    wave.Transparency = 0.3
    wave.Parent = GameState.Map
    
    -- Movimiento de la ola
    local tween = TweenService:Create(wave, 
        TweenInfo.new(25, Enum.EasingStyle.Linear),
        {Position = Vector3.new(0, 50, 300)}
    )
    tween:Play()
    
    -- Detectar colisiones
    task.spawn(function()
        while wave.Parent do
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local playerPos = player.Character.HumanoidRootPart.Position
                    if playerPos.Y < 60 and math.abs(playerPos.Z - wave.Position.Z) < 30 then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.Health = 0 -- Muerte instantánea por tsunami
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
    
    tween.Completed:Connect(function()
        wave:Destroy()
    end)
end

local function createVolcanicEruption()
    -- Crear volcán
    local volcano = Instance.new("Part")
    volcano.Name = "Volcano"
    volcano.Size = Vector3.new(80, 60, 80)
    volcano.Position = Vector3.new(0, 30, 0)
    volcano.Shape = Enum.PartType.Cylinder
    volcano.BrickColor = BrickColor.new("Really red")
    volcano.Material = Enum.Material.Neon
    volcano.Anchored = true
    volcano.Parent = GameState.Map
    
    -- Lluvia de lava
    task.spawn(function()
        for i = 1, 50 do
            local lavaRock = Instance.new("Part")
            lavaRock.Name = "LavaRock"
            lavaRock.Size = Vector3.new(4, 4, 4)
            lavaRock.Position = Vector3.new(
                math.random(-150, 150),
                200,
                math.random(-150, 150)
            )
            lavaRock.BrickColor = BrickColor.new("Really red")
            lavaRock.Material = Enum.Material.Neon
            lavaRock.Shape = Enum.PartType.Ball
            lavaRock.Parent = GameState.Map
            
            -- Física de caída
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVelocity.Velocity = Vector3.new(0, -50, 0)
            bodyVelocity.Parent = lavaRock
            
            -- Detectar impacto
            lavaRock.Touched:Connect(function(hit)
                if hit.Name == "Terrain" or hit.Parent:FindFirstChild("Humanoid") then
                    -- Crear explosión
                    local explosion = Instance.new("Explosion")
                    explosion.Position = lavaRock.Position
                    explosion.BlastRadius = 20
                    explosion.BlastPressure = 500000
                    explosion.Parent = workspace
                    
                    lavaRock:Destroy()
                end
            end)
            
            Debris:AddItem(lavaRock, 10)
            task.wait(0.5)
        end
        volcano:Destroy()
    end)
end

local function createLightningStorm()
    Lighting.Brightness = 0
    
    task.spawn(function()
        for i = 1, 20 do
            -- Flash de rayo
            Lighting.Brightness = 3
            
            -- Crear rayo
            local lightning = Instance.new("Part")
            lightning.Name = "Lightning"
            lightning.Size = Vector3.new(2, 200, 2)
            lightning.Position = Vector3.new(
                math.random(-200, 200),
                100,
                math.random(-200, 200)
            )
            lightning.BrickColor = BrickColor.new("Bright yellow")
            lightning.Material = Enum.Material.Neon
            lightning.Anchored = true
            lightning.CanCollide = false
            lightning.Parent = GameState.Map
            
            -- Dañar jugadores cercanos
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (player.Character.HumanoidRootPart.Position - lightning.Position).Magnitude
                    if distance < 30 then
                        local humanoid = player.Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.Health = humanoid.Health - 50
                        end
                    end
                end
            end
            
            task.wait(0.1)
            Lighting.Brightness = 0
            lightning:Destroy()
            task.wait(math.random(1, 3))
        end
        Lighting.Brightness = 1
    end)
end

-- EJECUTAR DESASTRE
local function executeDisaster(disaster)
    GameState.CurrentDisaster = disaster
    
    notifyAllClients("DisasterStart", {
        name = disaster.Name,
        description = disaster.Description,
        duration = disaster.Duration
    })
    
    -- Cambiar ambiente
    Lighting.Ambient = disaster.Color
    
    -- Ejecutar efecto específico
    if disaster.Name:find("TORNADO") then
        createTornado()
    elseif disaster.Name:find("TSUNAMI") then
        createTsunami()
    elseif disaster.Name:find("VOLCÁNICA") then
        createVolcanicEruption()
    elseif disaster.Name:find("TORMENTA") then
        createLightningStorm()
    end
    
    print("🌪️ Desastre iniciado: " .. disaster.Name)
end

-- VERIFICAR SUPERVIVIENTES
local function checkSurvivors()
    local survivors = {}
    for userId, alive in pairs(GameState.AlivePlayers) do
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                table.insert(survivors, player)
            else
                GameState.AlivePlayers[userId] = false
            end
        else
            GameState.AlivePlayers[userId] = false
        end
    end
    return survivors
end

-- INICIAR RONDA
local function startRound()
    GameState.Status = "InRound"
    GameState.Timer = GAME_CONFIG.ROUND_TIME
    GameState.RoundNumber = GameState.RoundNumber + 1
    GameState.AlivePlayers = {}
    
    -- Seleccionar mapa y desastre
    local selectedMap = MAPS[math.random(1, #MAPS)]
    local selectedDisaster = DISASTERS[math.random(1, #DISASTERS)]
    
    createMap(selectedMap)
    
    -- Spawn jugadores
    for _, player in pairs(Players:GetPlayers()) do
        spawnPlayer(player)
    end
    
    notifyAllClients("RoundStart", {
        roundNumber = GameState.RoundNumber,
        mapName = selectedMap.Name,
        disaster = selectedDisaster.Name
    })
    
    -- Esperar antes del desastre
    task.wait(10)
    executeDisaster(selectedDisaster)
    
    print("🎮 Ronda " .. GameState.RoundNumber .. " iniciada")
end

-- TERMINAR RONDA
local function endRound()
    GameState.Status = "Ending"
    
    local survivors = checkSurvivors()
    
    notifyAllClients("RoundEnd", {
        survivors = #survivors,
        winners = survivors
    })
    
    -- Limpiar efectos
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
    
    task.wait(5)
    
    GameState.Status = "Intermission"
    GameState.Timer = GAME_CONFIG.INTERMISSION_TIME
    
    print("🏁 Ronda terminada. Supervivientes: " .. #survivors)
end

-- BUCLE PRINCIPAL DEL JUEGO
task.spawn(function()
    while true do
        if GameState.Status == "Intermission" then
            local playerCount = #Players:GetPlayers()
            
            if playerCount >= GAME_CONFIG.MIN_PLAYERS then
                notifyAllClients("Intermission", {
                    timer = GameState.Timer,
                    playersNeeded = 0,
                    nextRound = GameState.RoundNumber + 1
                })
                
                if GameState.Timer <= 0 then
                    startRound()
                else
                    GameState.Timer = GameState.Timer - 1
                end
            else
                GameState.Timer = GAME_CONFIG.INTERMISSION_TIME
                notifyAllClients("Intermission", {
                    timer = GameState.Timer,
                    playersNeeded = GAME_CONFIG.MIN_PLAYERS - playerCount,
                    nextRound = GameState.RoundNumber + 1
                })
            end
            
        elseif GameState.Status == "InRound" then
            local survivors = checkSurvivors()
            
            notifyAllClients("RoundUpdate", {
                timer = GameState.Timer,
                survivors = #survivors,
                disaster = GameState.CurrentDisaster and GameState.CurrentDisaster.Name or "Ninguno"
            })
            
            if GameState.Timer <= 0 or #survivors == 0 then
                endRound()
            else
                GameState.Timer = GameState.Timer - 1
            end
        end
        
        task.wait(1)
    end
end)

-- MANEJAR JUGADORES
Players.PlayerAdded:Connect(function(player)
    notifyClient(player, "Welcome", {
        gameName = "🌪️ SUPERVIVENCIA A DESASTRES",
        version = "1.0"
    })
end)

Players.PlayerRemoving:Connect(function(player)
    GameState.AlivePlayers[player.UserId] = nil
end)

print("🌪️ Juego de Supervivencia a Desastres iniciado correctamente")