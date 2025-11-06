--[[
CLIENTE DE EFECTOS DE TERROR EXTREMOS
Coloca este script en StarterPlayer/StarterPlayerScripts
]]

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Esperar al RemoteEvent
local TerrorEffects = ReplicatedStorage:WaitForChild("TerrorEffects")

-- EFECTOS DE TERROR EXTREMOS EN EL CLIENTE
local function createScreenInvert()
    local invertFrame = Instance.new("Frame")
    invertFrame.Size = UDim2.new(1, 0, 1, 0)
    invertFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    invertFrame.ZIndex = 1000
    invertFrame.Parent = PlayerGui
    
    -- Efecto de inversión de colores (simulado)
    task.spawn(function()
        for i = 1, 20 do
            invertFrame.BackgroundColor3 = Color3.fromRGB(
                255 - math.random(0, 255),
                255 - math.random(0, 255),
                255 - math.random(0, 255)
            )
            invertFrame.BackgroundTransparency = math.random(50, 90) / 100
            task.wait(0.1)
        end
        invertFrame:Destroy()
    end)
end

local function createFakeDisconnect()
    local disconnectGui = Instance.new("ScreenGui")
    disconnectGui.Name = "FakeDisconnect"
    disconnectGui.Parent = PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.6, 0, 0.4, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    frame.Parent = disconnectGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.3, 0)
    title.Text = "CONEXIÓN PERDIDA"
    title.TextColor3 = Color3.fromRGB(255, 0, 0)
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, 0, 0.5, 0)
    message.Position = UDim2.new(0, 0, 0.3, 0)
    message.Text = "Has sido desconectado del servidor.\nRazón: ENTIDAD DESCONOCIDA DETECTADA"
    message.TextColor3 = Color3.fromRGB(255, 255, 255)
    message.TextSize = 18
    message.TextWrapped = true
    message.BackgroundTransparency = 1
    message.Parent = frame
    
    -- Desaparecer después de 3 segundos
    task.wait(3)
    disconnectGui:Destroy()
end

local function createCursorControl()
    -- Simular control del cursor (limitado en Roblox, pero podemos hacer efectos visuales)
    local cursor = Instance.new("ImageLabel")
    cursor.Size = UDim2.new(0, 32, 0, 32)
    cursor.Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
    cursor.BackgroundTransparency = 1
    cursor.ZIndex = 1000
    cursor.Parent = PlayerGui
    
    task.spawn(function()
        for i = 1, 50 do
            cursor.Position = UDim2.new(
                math.random(0, 100) / 100, 0,
                math.random(0, 100) / 100, 0
            )
            task.wait(0.05)
        end
        cursor:Destroy()
    end)
end

local function createFakeError(message)
    local errorGui = Instance.new("ScreenGui")
    errorGui.Name = "FakeError"
    errorGui.Parent = PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.6, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 3
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    frame.Parent = errorGui
    
    local errorText = Instance.new("TextLabel")
    errorText.Size = UDim2.new(1, 0, 0.8, 0)
    errorText.Text = message
    errorText.TextColor3 = Color3.fromRGB(255, 50, 50)
    errorText.TextSize = 20
    errorText.Font = Enum.Font.SourceSansBold
    errorText.TextWrapped = true
    errorText.BackgroundTransparency = 1
    errorText.Parent = frame
    
    -- Efecto de parpadeo
    task.spawn(function()
        for i = 1, 15 do
            errorText.TextTransparency = math.random(0, 50) / 100
            frame.BackgroundColor3 = Color3.fromRGB(
                math.random(10, 30),
                0,
                0
            )
            task.wait(0.2)
        end
        errorGui:Destroy()
    end)
end

local function createBatteryWarning()
    local batteryGui = Instance.new("ScreenGui")
    batteryGui.Name = "BatteryWarning"
    batteryGui.Parent = PlayerGui
    
    local warning = Instance.new("Frame")
    warning.Size = UDim2.new(0.4, 0, 0.1, 0)
    warning.Position = UDim2.new(0.5, 0, 0.1, 0)
    warning.AnchorPoint = Vector2.new(0.5, 0)
    warning.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    warning.Parent = batteryGui
    
    local batteryText = Instance.new("TextLabel")
    batteryText.Size = UDim2.new(1, 0, 1, 0)
    batteryText.Text = "🔋 BATERÍA CRÍTICA: 1%"
    batteryText.TextColor3 = Color3.fromRGB(255, 255, 255)
    batteryText.TextSize = 18
    batteryText.Font = Enum.Font.SourceSansBold
    batteryText.BackgroundTransparency = 1
    batteryText.Parent = warning
    
    -- Parpadear y desaparecer
    task.spawn(function()
        for i = 1, 10 do
            warning.BackgroundTransparency = math.random(0, 50) / 100
            task.wait(0.3)
        end
        batteryGui:Destroy()
    end)
end

local function createCameraShake()
    local camera = workspace.CurrentCamera
    local originalCFrame = camera.CFrame
    
    task.spawn(function()
        for i = 1, 30 do
            local shake = CFrame.new(
                math.random(-2, 2),
                math.random(-2, 2),
                math.random(-2, 2)
            )
            camera.CFrame = originalCFrame * shake
            task.wait(0.05)
        end
        camera.CFrame = originalCFrame
    end)
end

local function createFakeVirus()
    local virusGui = Instance.new("ScreenGui")
    virusGui.Name = "FakeVirus"
    virusGui.Parent = PlayerGui
    
    -- Crear múltiples ventanas de "virus"
    for i = 1, 5 do
        local virusWindow = Instance.new("Frame")
        virusWindow.Size = UDim2.new(0.3, 0, 0.2, 0)
        virusWindow.Position = UDim2.new(
            math.random(0, 70) / 100, 0,
            math.random(0, 80) / 100, 0
        )
        virusWindow.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        virusWindow.BorderSizePixel = 2
        virusWindow.BorderColor3 = Color3.fromRGB(0, 0, 0)
        virusWindow.Parent = virusGui
        
        local virusText = Instance.new("TextLabel")
        virusText.Size = UDim2.new(1, 0, 1, 0)
        virusText.Text = "⚠️ VIRUS DETECTADO ⚠️\nELIMINANDO ARCHIVOS..."
        virusText.TextColor3 = Color3.fromRGB(255, 255, 255)
        virusText.TextSize = 14
        virusText.Font = Enum.Font.SourceSansBold
        virusText.TextWrapped = true
        virusText.BackgroundTransparency = 1
        virusText.Parent = virusWindow
        
        -- Mover ventanas aleatoriamente
        task.spawn(function()
            for j = 1, 20 do
                virusWindow.Position = UDim2.new(
                    math.random(0, 70) / 100, 0,
                    math.random(0, 80) / 100, 0
                )
                task.wait(0.2)
            end
        end)
    end
    
    task.wait(4)
    virusGui:Destroy()
end

local function createGhostTyping()
    -- Buscar el InputBox del chat si existe
    local chatGui = PlayerGui:FindFirstChild("HorrorChatGui")
    if chatGui then
        local inputBox = chatGui:FindFirstChild("MainFrame")
        if inputBox then
            inputBox = inputBox:FindFirstChild("ChatInputFrame")
            if inputBox then
                inputBox = inputBox:FindFirstChild("InputBox")
                if inputBox and inputBox:IsA("TextBox") then
                    local ghostMessages = {
                        "No escribí esto...",
                        "¿Quién está controlando mi teclado?",
                        "AYUDA... NO PUEDO PARAR DE ESCRIBIR",
                        "EL DESCONOCIDO ESTÁ EN MI DISPOSITIVO"
                    }
                    
                    local message = ghostMessages[math.random(1, #ghostMessages)]
                    local originalText = inputBox.Text
                    
                    -- Escribir letra por letra
                    task.spawn(function()
                        inputBox.Text = ""
                        for i = 1, #message do
                            inputBox.Text = string.sub(message, 1, i)
                            task.wait(0.1)
                        end
                        task.wait(2)
                        inputBox.Text = originalText
                    end)
                end
            end
        end
    end
end

-- Manejar efectos del servidor
TerrorEffects.OnClientEvent:Connect(function(effect, message)
    if effect == "SCREEN_INVERT" then
        createScreenInvert()
    elseif effect == "FAKE_DISCONNECT" then
        createFakeDisconnect()
    elseif effect == "CURSOR_CONTROL" then
        createCursorControl()
    elseif effect == "FAKE_ERROR" then
        createFakeError(message)
    elseif effect == "BATTERY_WARNING" then
        createBatteryWarning()
    elseif effect == "CAMERA_SHAKE" then
        createCameraShake()
    elseif effect == "FAKE_VIRUS" then
        createFakeVirus()
    elseif effect == "GHOST_TYPING" then
        createGhostTyping()
    end
end)

print("Cliente de Terror Extremo cargado - Prepárate para temblar")