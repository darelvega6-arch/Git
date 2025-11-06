--[[
🌪️ CLIENTE DE SUPERVIVENCIA A DESASTRES
Coloca este script en StarterPlayer/StarterPlayerScripts
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

-- Esperar RemoteEvents
local UpdateClient = ReplicatedStorage:WaitForChild("UpdateClient")
local PlayerAction = ReplicatedStorage:WaitForChild("PlayerAction")

-- CONFIGURACIÓN DE UI
local UI_COLORS = {
    Background = Color3.fromRGB(20, 20, 20),
    Primary = Color3.fromRGB(255, 100, 50),
    Secondary = Color3.fromRGB(100, 150, 255),
    Success = Color3.fromRGB(50, 255, 100),
    Warning = Color3.fromRGB(255, 200, 50),
    Danger = Color3.fromRGB(255, 50, 50),
    Text = Color3.fromRGB(255, 255, 255)
}

-- CREAR GUI PRINCIPAL
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DisasterSurvivalGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- FRAME PRINCIPAL
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = UI_COLORS.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- HEADER
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0.1, 0)
Header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0.05, 0, 0, 0)
Title.Text = "🌪️ SUPERVIVENCIA A DESASTRES"
Title.TextColor3 = UI_COLORS.Primary
Title.TextSize = 28
Title.Font = Enum.Font.SourceSansBold
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0.3, 0, 1, 0)
StatusLabel.Position = UDim2.new(0.65, 0, 0, 0)
StatusLabel.Text = "ESPERANDO..."
StatusLabel.TextColor3 = UI_COLORS.Warning
StatusLabel.TextSize = 20
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextXAlignment = Enum.TextXAlignment.Right
StatusLabel.Parent = Header

-- PANEL DE INFORMACIÓN
local InfoPanel = Instance.new("Frame")
InfoPanel.Name = "InfoPanel"
InfoPanel.Size = UDim2.new(0.4, 0, 0.3, 0)
InfoPanel.Position = UDim2.new(0.05, 0, 0.15, 0)
InfoPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = MainFrame
Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 10)

local InfoTitle = Instance.new("TextLabel")
InfoTitle.Size = UDim2.new(1, 0, 0.2, 0)
InfoTitle.Text = "📊 INFORMACIÓN DE LA RONDA"
InfoTitle.TextColor3 = UI_COLORS.Secondary
InfoTitle.TextSize = 18
InfoTitle.Font = Enum.Font.SourceSansBold
InfoTitle.BackgroundTransparency = 1
InfoTitle.Parent = InfoPanel

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "TimerLabel"
TimerLabel.Size = UDim2.new(1, 0, 0.25, 0)
TimerLabel.Position = UDim2.new(0, 0, 0.2, 0)
TimerLabel.Text = "⏰ Tiempo: --:--"
TimerLabel.TextColor3 = UI_COLORS.Text
TimerLabel.TextSize = 16
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextXAlignment = Enum.TextXAlignment.Left
TimerLabel.Parent = InfoPanel

local SurvivorsLabel = Instance.new("TextLabel")
SurvivorsLabel.Name = "SurvivorsLabel"
SurvivorsLabel.Size = UDim2.new(1, 0, 0.25, 0)
SurvivorsLabel.Position = UDim2.new(0, 0, 0.45, 0)
SurvivorsLabel.Text = "👥 Supervivientes: --"
SurvivorsLabel.TextColor3 = UI_COLORS.Text
SurvivorsLabel.TextSize = 16
SurvivorsLabel.BackgroundTransparency = 1
SurvivorsLabel.TextXAlignment = Enum.TextXAlignment.Left
SurvivorsLabel.Parent = InfoPanel

local DisasterLabel = Instance.new("TextLabel")
DisasterLabel.Name = "DisasterLabel"
DisasterLabel.Size = UDim2.new(1, 0, 0.3, 0)
DisasterLabel.Position = UDim2.new(0, 0, 0.7, 0)
DisasterLabel.Text = "🌪️ Desastre: Ninguno"
DisasterLabel.TextColor3 = UI_COLORS.Danger
DisasterLabel.TextSize = 16
DisasterLabel.BackgroundTransparency = 1
DisasterLabel.TextXAlignment = Enum.TextXAlignment.Left
DisasterLabel.TextWrapped = true
DisasterLabel.Parent = InfoPanel

-- PANEL DE ALERTAS
local AlertPanel = Instance.new("Frame")
AlertPanel.Name = "AlertPanel"
AlertPanel.Size = UDim2.new(0.5, 0, 0.15, 0)
AlertPanel.Position = UDim2.new(0.5, 0, 0.15, 0)
AlertPanel.BackgroundColor3 = UI_COLORS.Danger
AlertPanel.BorderSizePixel = 0
AlertPanel.Visible = false
AlertPanel.Parent = MainFrame
Instance.new("UICorner", AlertPanel).CornerRadius = UDim.new(0, 10)

local AlertTitle = Instance.new("TextLabel")
AlertTitle.Name = "AlertTitle"
AlertTitle.Size = UDim2.new(1, 0, 0.4, 0)
AlertTitle.Text = "⚠️ ALERTA DE DESASTRE"
AlertTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
AlertTitle.TextSize = 24
AlertTitle.Font = Enum.Font.SourceSansBold
AlertTitle.BackgroundTransparency = 1
AlertTitle.Parent = AlertPanel

local AlertDescription = Instance.new("TextLabel")
AlertDescription.Name = "AlertDescription"
AlertDescription.Size = UDim2.new(1, 0, 0.6, 0)
AlertDescription.Position = UDim2.new(0, 0, 0.4, 0)
AlertDescription.Text = "Descripción del desastre"
AlertDescription.TextColor3 = Color3.fromRGB(255, 255, 255)
AlertDescription.TextSize = 18
AlertDescription.BackgroundTransparency = 1
AlertDescription.TextWrapped = true
AlertDescription.Parent = AlertPanel

-- PANEL DE CONSEJOS
local TipsPanel = Instance.new("Frame")
TipsPanel.Name = "TipsPanel"
TipsPanel.Size = UDim2.new(0.4, 0, 0.4, 0)
TipsPanel.Position = UDim2.new(0.55, 0, 0.35, 0)
TipsPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TipsPanel.BorderSizePixel = 0
TipsPanel.Parent = MainFrame
Instance.new("UICorner", TipsPanel).CornerRadius = UDim.new(0, 10)

local TipsTitle = Instance.new("TextLabel")
TipsTitle.Size = UDim2.new(1, 0, 0.15, 0)
TipsTitle.Text = "💡 CONSEJOS DE SUPERVIVENCIA"
TipsTitle.TextColor3 = UI_COLORS.Success
TipsTitle.TextSize = 16
TipsTitle.Font = Enum.Font.SourceSansBold
TipsTitle.BackgroundTransparency = 1
TipsTitle.Parent = TipsPanel

local TipsScroller = Instance.new("ScrollingFrame")
TipsScroller.Size = UDim2.new(1, 0, 0.85, 0)
TipsScroller.Position = UDim2.new(0, 0, 0.15, 0)
TipsScroller.BackgroundTransparency = 1
TipsScroller.ScrollBarThickness = 4
TipsScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
TipsScroller.Parent = TipsPanel

local TipsLayout = Instance.new("UIListLayout")
TipsLayout.Padding = UDim.new(0, 5)
TipsLayout.Parent = TipsScroller

-- CONSEJOS DE SUPERVIVENCIA
local SURVIVAL_TIPS = {
    "🏠 Busca refugio en edificios sólidos durante tornados",
    "⛰️ Sube a terreno alto durante tsunamis",
    "🔥 Aléjate del fuego y busca agua",
    "⚡ Evita objetos metálicos durante tormentas",
    "🧊 Busca calor durante ventiscas",
    "🌍 Aléjate de estructuras durante terremotos",
    "💨 Agárrate fuerte durante huracanes",
    "🌋 Busca cobertura durante erupciones"
}

-- Agregar consejos
for _, tip in ipairs(SURVIVAL_TIPS) do
    local tipLabel = Instance.new("TextLabel")
    tipLabel.Size = UDim2.new(1, 0, 0, 30)
    tipLabel.Text = tip
    tipLabel.TextColor3 = UI_COLORS.Text
    tipLabel.TextSize = 14
    tipLabel.BackgroundTransparency = 1
    tipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tipLabel.TextWrapped = true
    tipLabel.Parent = TipsScroller
end

TipsScroller.CanvasSize = UDim2.new(0, 0, 0, TipsLayout.AbsoluteContentSize.Y)

-- LEADERBOARD
local Leaderboard = Instance.new("Frame")
Leaderboard.Name = "Leaderboard"
Leaderboard.Size = UDim2.new(0.3, 0, 0.5, 0)
Leaderboard.Position = UDim2.new(0.05, 0, 0.48, 0)
Leaderboard.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Leaderboard.BorderSizePixel = 0
Leaderboard.Parent = MainFrame
Instance.new("UICorner", Leaderboard).CornerRadius = UDim.new(0, 10)

local LeaderTitle = Instance.new("TextLabel")
LeaderTitle.Size = UDim2.new(1, 0, 0.1, 0)
LeaderTitle.Text = "🏆 JUGADORES"
LeaderTitle.TextColor3 = UI_COLORS.Primary
LeaderTitle.TextSize = 18
LeaderTitle.Font = Enum.Font.SourceSansBold
LeaderTitle.BackgroundTransparency = 1
LeaderTitle.Parent = Leaderboard

local PlayersList = Instance.new("ScrollingFrame")
PlayersList.Size = UDim2.new(1, 0, 0.9, 0)
PlayersList.Position = UDim2.new(0, 0, 0.1, 0)
PlayersList.BackgroundTransparency = 1
PlayersList.ScrollBarThickness = 4
PlayersList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayersList.Parent = Leaderboard

local PlayersLayout = Instance.new("UIListLayout")
PlayersLayout.Padding = UDim.new(0, 2)
PlayersLayout.Parent = PlayersList

-- FUNCIONES DE EFECTOS
local function showAlert(title, description, duration)
    AlertTitle.Text = title
    AlertDescription.Text = description
    AlertPanel.Visible = true
    
    -- Efecto de parpadeo
    task.spawn(function()
        for i = 1, 10 do
            AlertPanel.BackgroundColor3 = UI_COLORS.Danger
            task.wait(0.2)
            AlertPanel.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            task.wait(0.2)
        end
        
        task.wait(duration or 5)
        AlertPanel.Visible = false
    end)
end

local function updatePlayersList()
    -- Limpiar lista
    for _, child in pairs(PlayersList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Agregar jugadores
    for _, player in pairs(Players:GetPlayers()) do
        local playerLabel = Instance.new("TextLabel")
        playerLabel.Size = UDim2.new(1, 0, 0, 25)
        playerLabel.Text = "👤 " .. player.Name
        playerLabel.TextColor3 = UI_COLORS.Text
        playerLabel.TextSize = 14
        playerLabel.BackgroundTransparency = 1
        playerLabel.TextXAlignment = Enum.TextXAlignment.Left
        playerLabel.Parent = PlayersList
        
        -- Color según estado
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            if player.Character.Humanoid.Health > 0 then
                playerLabel.TextColor3 = UI_COLORS.Success
            else
                playerLabel.TextColor3 = UI_COLORS.Danger
                playerLabel.Text = "💀 " .. player.Name
            end
        end
    end
    
    PlayersList.CanvasSize = UDim2.new(0, 0, 0, PlayersLayout.AbsoluteContentSize.Y)
end

local function formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

-- MANEJAR EVENTOS DEL SERVIDOR
UpdateClient.OnClientEvent:Connect(function(eventType, data)
    if eventType == "Welcome" then
        Title.Text = data.gameName
        
    elseif eventType == "Intermission" then
        StatusLabel.Text = "INTERMISIÓN"
        StatusLabel.TextColor3 = UI_COLORS.Warning
        TimerLabel.Text = "⏰ Próxima ronda en: " .. formatTime(data.timer)
        
        if data.playersNeeded > 0 then
            SurvivorsLabel.Text = "👥 Esperando " .. data.playersNeeded .. " jugadores más"
        else
            SurvivorsLabel.Text = "👥 ¡Listos para jugar!"
        end
        
        DisasterLabel.Text = "🌪️ Ronda #" .. data.nextRound .. " próximamente"
        AlertPanel.Visible = false
        
    elseif eventType == "RoundStart" then
        StatusLabel.Text = "EN JUEGO"
        StatusLabel.TextColor3 = UI_COLORS.Success
        DisasterLabel.Text = "🗺️ Mapa: " .. data.mapName
        showAlert("🎮 RONDA " .. data.roundNumber, "¡Prepárate para: " .. data.disaster .. "!", 3)
        
    elseif eventType == "RoundUpdate" then
        TimerLabel.Text = "⏰ Tiempo restante: " .. formatTime(data.timer)
        SurvivorsLabel.Text = "👥 Supervivientes: " .. data.survivors
        DisasterLabel.Text = "🌪️ Desastre activo: " .. data.disaster
        
    elseif eventType == "DisasterStart" then
        showAlert(data.name, data.description, data.duration)
        StatusLabel.Text = "¡DESASTRE!"
        StatusLabel.TextColor3 = UI_COLORS.Danger
        
    elseif eventType == "RoundEnd" then
        StatusLabel.Text = "RONDA TERMINADA"
        StatusLabel.TextColor3 = UI_COLORS.Secondary
        
        local winText = "🏆 SUPERVIVIENTES: " .. data.survivors
        if data.survivors == 0 then
            winText = "💀 ¡NADIE SOBREVIVIÓ!"
        elseif data.survivors == 1 then
            winText = "🏆 ¡1 SUPERVIVIENTE!"
        end
        
        showAlert("🏁 RONDA TERMINADA", winText, 5)
    end
    
    updatePlayersList()
end)

-- Actualizar lista de jugadores periódicamente
task.spawn(function()
    while true do
        updatePlayersList()
        task.wait(2)
    end
end)

print("🌪️ Cliente de Supervivencia a Desastres cargado")