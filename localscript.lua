--[[
TÍTULO: Cliente de Chat "WhatsApp del Terror"
UBICACIÓN: StarterPlayer/StarterPlayerScripts
 
ESTE SCRIPT GESTIONA LA INTERFAZ DE USUARIO (INTRO, SALAS, CHAT),
LA COMUNICACIÓN CON EL SERVIDOR Y MANEJA LOS EFECTOS DE SONIDO.
 
¡ARREGLO CRÍTICO IMPLEMENTADO!
1. Se eliminó la dependencia de RemoteEvent 'MatchRequest' que causaba el fallo de ejecución.
2. Se verificó y aseguró la lógica de la interfaz y la gestión de salas.
--]]
 
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local task = task or game:GetService("RunService")
local HttpService = game:GetService("HttpService")
 
-- RemoteEvents (Accedidos de forma segura, el servidor ya los habrá creado)
local RoomListRequest = ReplicatedStorage:WaitForChild("RoomListRequest") 
local RoomAction = ReplicatedStorage:WaitForChild("RoomAction")         
local MessageSend = ReplicatedStorage:WaitForChild("MessageSend")   
local ReportUser = ReplicatedStorage:WaitForChild("ReportUser")     
local ClientUpdate = ReplicatedStorage:WaitForChild("ClientUpdate") 
 
--------------------------------------------------------------------------------
-- 1. CONFIGURACIÓN DE SONIDOS 
--------------------------------------------------------------------------------
 
-- Roblox Asset IDs para los sonidos - SONIDOS DE TERROR INTENSOS
local SOUND_IDS = {
-- 1. Música de Fondo del Intro (Bucle) - MÚSICA ÉPICA DE TERROR
IntroMusic = "rbxassetid://1838645651", 
-- 2. Confirmación de Conexión (One-shot)
Connected = "rbxassetid://94059490149743", 
-- 3. Efecto de Escritura
Typing = "rbxassetid://127105730240202",
-- 4. Mensaje Enviado
MessageSent = "rbxassetid://5485567028", 
-- 5. Mensaje Recibido
MessageReceived = "rbxassetid://93931612588862", 
-- 6. Desconocido Entra/Mensaje (Terror)
UnknownEnter = "rbxassetid://130976109",
-- 7. Sonido de Like/Doble Click
Like = "rbxassetid://17520503095",
-- 8. Efecto de Glitch para la intro
GlitchSound = "rbxassetid://9114397505",
-- 9. NUEVOS SONIDOS TERRORÍFICOS
Heartbeat = "rbxassetid://131961136", -- Latidos del corazón acelerados
Whisper = "rbxassetid://131961136", -- Susurros perturbadores
Scream = "rbxassetid://131961136", -- Grito de terror
StaticNoise = "rbxassetid://131961136", -- Ruido estático
Footsteps = "rbxassetid://131961136", -- Pasos acercándose
Breathing = "rbxassetid://131961136", -- Respiración pesada
DoorCreak = "rbxassetid://131961136", -- Puerta chirriando
PhoneRing = "rbxassetid://131961136", -- Teléfono sonando siniestro
}
 
-- ARREGLO DE SONIDO: Se adjunta SoundFolder a PlayerGui para mayor fiabilidad
local SoundFolder = Instance.new("Folder")
SoundFolder.Name = "ClientSounds"
SoundFolder.Parent = PlayerGui 
 
local sounds = {}
for name, id in pairs(SOUND_IDS) do
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = id
    if name == "IntroMusic" then
        sound.Looped = true
        sound.Volume = 0.7 
    elseif name == "Typing" then
        sound.Volume = 0.4
    elseif name == "Like" then 
        sound.Volume = 0.8
    elseif name == "GlitchSound" then
        sound.Volume = 0.6
    elseif name == "Heartbeat" then
        sound.Volume = 0.9
        sound.Looped = true
    elseif name == "Whisper" then
        sound.Volume = 0.5
    elseif name == "Scream" then
        sound.Volume = 1.0
    elseif name == "StaticNoise" then
        sound.Volume = 0.3
        sound.Looped = true
    elseif name == "Footsteps" then
        sound.Volume = 0.8
    elseif name == "Breathing" then
        sound.Volume = 0.7
        sound.Looped = true
    elseif name == "DoorCreak" then
        sound.Volume = 0.6
    elseif name == "PhoneRing" then
        sound.Volume = 0.9
    else
        sound.Volume = 1.0
    end
    sound.Parent = SoundFolder
    sounds[name] = sound
end
 
local function playSound(name)
    local sound = sounds[name]
    if sound and sound.SoundId ~= "" then
        -- Esperar a que cargue si no lo está
        if not sound.IsLoaded then
            sound.Loaded:Wait()
        end
        
        -- Detener y rebobinar si no está en bucle
        if not sound.Looped and sound.IsPlaying then
            sound:Stop()
        end
        
        sound:Play()
    end
end
 
--------------------------------------------------------------------------------
-- 2. CONFIGURACIÓN DE ESTILOS Y ESTADO LOCAL
--------------------------------------------------------------------------------
 
local UI_SIZE = UDim2.new(1, 0, 1, 0)
local CHAT_BG_COLOR = Color3.fromRGB(15, 15, 15)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)
local ACCENT_COLOR = Color3.fromRGB(0, 150, 136)
local MY_MESSAGE_COLOR = Color3.fromRGB(0, 70, 70)
local PARTNER_MESSAGE_COLOR = Color3.fromRGB(40, 40, 40)
local UNKNOWN_MESSAGE_COLOR = Color3.fromRGB(130, 0, 0)
local FONT_STYLE = Enum.Font.SourceSans
local FONT_SIZE = 18
 
local currentPartnerName = nil 
local currentPartnerId = nil 
local currentScreen = "Intro"
local currentRoomId = nil -- Para saber en qué sala está el jugador (solo si es HostWaiting)
local lastClickTime = 0 
local DOUBLE_CLICK_TIME = 0.3 
local lastTypingSoundTime = 0 
local TYPING_THROTTLE = 0.05 
 
--------------------------------------------------------------------------------
-- 3. CONSTRUCCIÓN DE LA UI PRINCIPAL 
--------------------------------------------------------------------------------
 
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HorrorChatGui"
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui
 
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UI_SIZE
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = CHAT_BG_COLOR
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
 
-- ** 3.1. Encabezado del Chat (Con Icono de Perfil) **
local ChatHeader = Instance.new("Frame")
ChatHeader.Name = "ChatHeader"
ChatHeader.Size = UDim2.new(1, 0, 0.08, 0)
ChatHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ChatHeader.BorderSizePixel = 0
ChatHeader.Visible = false
ChatHeader.Parent = MainFrame
 
local ProfileButton = Instance.new("ImageButton")
ProfileButton.Name = "ProfileButton"
ProfileButton.Size = UDim2.new(0, 50, 0, 50)
ProfileButton.Position = UDim2.new(0, 15, 0.5, 0)
ProfileButton.AnchorPoint = Vector2.new(0, 0.5)
ProfileButton.BackgroundTransparency = 1
ProfileButton.Image = "rbxassetid://13426021678" 
ProfileButton.ScaleType = Enum.ScaleType.Fit
ProfileButton.Parent = ChatHeader
Instance.new("UICorner", ProfileButton).CornerRadius = UDim.new(0.5, 0)
 
local TextContainer = Instance.new("Frame")
TextContainer.Size = UDim2.new(0.6, 0, 1, 0)
TextContainer.Position = UDim2.new(0, 80, 0, 0)
TextContainer.BackgroundTransparency = 1
TextContainer.Parent = ChatHeader
 
local HeaderText = Instance.new("TextLabel")
HeaderText.Name = "HeaderText"
HeaderText.Size = UDim2.new(1, 0, 0.6, 0)
HeaderText.Text = "WhatsApp del Terror"
HeaderText.TextColor3 = TEXT_COLOR
HeaderText.TextSize = 24
HeaderText.Font = Enum.Font.SourceSansBold
HeaderText.BackgroundTransparency = 1
HeaderText.TextXAlignment = Enum.TextXAlignment.Left
HeaderText.TextYAlignment = Enum.TextYAlignment.Center
HeaderText.Parent = TextContainer
 
local StatusText = Instance.new("TextLabel")
StatusText.Name = "StatusText"
StatusText.Size = UDim2.new(1, 0, 0.4, 0)
StatusText.Position = UDim2.new(0, 0, 0.6, 0)
StatusText.Text = "En línea"
StatusText.TextColor3 = ACCENT_COLOR
StatusText.TextSize = 16
StatusText.Font = FONT_STYLE
StatusText.BackgroundTransparency = 1
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = TextContainer
 
-- ** 3.2. Panel de Mensajes (Scroller) **
local ChatScroller = Instance.new("ScrollingFrame")
ChatScroller.Name = "ChatScroller"
ChatScroller.Size = UDim2.new(1, 0, 0.84, 0) 
ChatScroller.Position = UDim2.new(0, 0, 0.08, 0)
ChatScroller.BackgroundColor3 = CHAT_BG_COLOR
ChatScroller.BorderSizePixel = 0
ChatScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
ChatScroller.ScrollBarImageColor3 = ACCENT_COLOR
ChatScroller.Visible = false
ChatScroller.Parent = MainFrame
 
local ScrollerPadding = Instance.new("UIPadding")
ScrollerPadding.Name = "ScrollerPadding"
ScrollerPadding.PaddingTop = UDim.new(0, 10)
ScrollerPadding.PaddingBottom = UDim.new(0, 10)
ScrollerPadding.PaddingLeft = UDim.new(0, 10)
ScrollerPadding.PaddingRight = UDim.new(0, 10)
ScrollerPadding.Parent = ChatScroller
 
local MessageLayout = Instance.new("UIListLayout")
MessageLayout.Name = "MessageLayout"
MessageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left 
MessageLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
MessageLayout.SortOrder = Enum.SortOrder.LayoutOrder
MessageLayout.Padding = UDim.new(0, 10)
MessageLayout.Parent = ChatScroller
 
-- ** 3.3. Panel de Entrada de Texto **
local ChatInputFrame = Instance.new("Frame")
ChatInputFrame.Name = "ChatInputFrame"
ChatInputFrame.Size = UDim2.new(1, 0, 0.08, 0)
ChatInputFrame.Position = UDim2.new(0, 0, 0.92, 0)
ChatInputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ChatInputFrame.BorderSizePixel = 0
ChatInputFrame.Visible = false
ChatInputFrame.Parent = MainFrame
 
local InputBox = Instance.new("TextBox")
InputBox.Name = "InputBox"
InputBox.Size = UDim2.new(0.8, -15, 0.6, 0)
InputBox.Position = UDim2.new(0.05, 0, 0.5, 0)
InputBox.AnchorPoint = Vector2.new(0, 0.5)
InputBox.PlaceholderText = "Escribe un mensaje..."
InputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InputBox.TextColor3 = TEXT_COLOR
InputBox.TextSize = FONT_SIZE
InputBox.Font = FONT_STYLE
InputBox.Parent = ChatInputFrame
 
local SendButton = Instance.new("TextButton")
SendButton.Name = "SendButton"
SendButton.Size = UDim2.new(0.15, 0, 0.6, 0)
SendButton.Position = UDim2.new(0.95, 0, 0.5, 0)
SendButton.AnchorPoint = Vector2.new(1, 0.5)
SendButton.Text = "Enviar"
SendButton.BackgroundColor3 = ACCENT_COLOR
SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SendButton.TextSize = FONT_SIZE
SendButton.Font = FONT_STYLE
SendButton.Parent = ChatInputFrame
 
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 15)
Instance.new("UICorner", SendButton).CornerRadius = UDim.new(0, 15)
 
--------------------------------------------------------------------------------
-- 4. FUNCIONES Y PANTALLAS PRINCIPALES
--------------------------------------------------------------------------------
 
local function createReactionEffect(messageBubble, isMe)
    local heart = Instance.new("TextLabel")
    heart.Size = UDim2.new(0, 40, 0, 40)
    heart.Text = "❤️"
    heart.TextSize = 30
    heart.BackgroundTransparency = 1
    heart.ZIndex = 5 
    
    local bubblePosition = messageBubble.AbsolutePosition
    local bubbleSize = messageBubble.AbsoluteSize
    heart.Position = UDim2.new(0, bubblePosition.X + (isMe and bubbleSize.X * 0.1 or bubbleSize.X * 0.9), 0, bubblePosition.Y)
    heart.AnchorPoint = Vector2.new(0.5, 1)
    
    heart.Parent = ScreenGui
    
    local tweenService = game:GetService("TweenService")
    local info = TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
    -- Ajustar la posición Y de forma local al contenedor principal para que la animación funcione correctamente
    local goal = {Position = heart.Position - UDim2.new(0, 0, 0.15 * ScreenGui.AbsoluteSize.Y, 0), TextTransparency = 1} 
    
    local tween = tweenService:Create(heart, info, goal)
    tween:Play()
    
    Debris:AddItem(heart, 1.0)
    
    playSound("Like") 
end
 
local function handleDoubleClick(messageBubble, isMe)
    local currentTime = tick()
    if currentTime - lastClickTime < DOUBLE_CLICK_TIME then
        createReactionEffect(messageBubble, isMe)
        lastClickTime = 0
    else
        lastClickTime = currentTime
    end
end
 
-- Función para crear la etiqueta de texto del mensaje
local function createMessageText(parent, isUnknown)
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Name = "MessageLabel"
    MessageLabel.Size = UDim2.new(1, 0, 0, 0) 
    MessageLabel.Text = ""
    MessageLabel.TextColor3 = TEXT_COLOR
    MessageLabel.TextSize = FONT_SIZE
    MessageLabel.Font = FONT_STYLE
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.TextWrapped = true
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
    
    if isUnknown then
        MessageLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
        MessageLabel.TextSize = FONT_SIZE + 2
        MessageLabel.Font = Enum.Font.SourceSansBold
    end
    
    local TextSizeConstraint = Instance.new("UISizeConstraint")
    TextSizeConstraint.MinSize = Vector2.new(0, 0)
    -- Limitar el ancho al 80% del Scroller
    TextSizeConstraint.MaxSize = Vector2.new(ChatScroller.AbsoluteSize.X * 0.8, math.huge) 
    TextSizeConstraint.Parent = MessageLabel
    
    MessageLabel.Parent = parent
    return MessageLabel
end
 
-- Función para crear efecto de distorsión de pantalla (con protección contra llamadas concurrentes)
local distortionInProgress = false
local basePosition = UDim2.new(0, 0, 0, 0) -- Posición base fija
 
local function screenDistortion()
    if distortionInProgress then return end -- Prevenir llamadas concurrentes
        distortionInProgress = true
        
        task.spawn(function()
            for i = 1, 10 do
                local offsetX = math.random(-15, 15)
                local offsetY = math.random(-15, 15)
                MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
                task.wait(0.03)
            end
            MainFrame.Position = basePosition -- Siempre restaurar a la posición base fija
            distortionInProgress = false
        end)
    end
    
    -- Función para crear flash rojo de terror MEJORADO
    local function terrorFlash()
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        flash.BackgroundTransparency = 0.3
        flash.BorderSizePixel = 0
        flash.ZIndex = 100
        flash.Parent = ScreenGui
        
        task.spawn(function()
            for i = 1, 5 do
                flash.BackgroundTransparency = 0.3 + (i * 0.14)
                task.wait(0.05)
            end
            flash:Destroy()
        end)
    end
    
    -- NUEVA FUNCIÓN: Efecto de ojos que aparecen
    local function createEyesEffect()
        local eyesFrame = Instance.new("Frame")
        eyesFrame.Size = UDim2.new(1, 0, 1, 0)
        eyesFrame.BackgroundTransparency = 1
        eyesFrame.ZIndex = 150
        eyesFrame.Parent = ScreenGui
        
        for i = 1, 3 do
            local eye = Instance.new("TextLabel")
            eye.Size = UDim2.new(0, 60, 0, 60)
            eye.Position = UDim2.new(math.random(10, 90)/100, 0, math.random(10, 90)/100, 0)
            eye.Text = "👁️"
            eye.TextSize = 50
            eye.BackgroundTransparency = 1
            eye.TextTransparency = 1
            eye.ZIndex = 151
            eye.Parent = eyesFrame
            
            -- Aparecer gradualmente
            task.spawn(function()
                for j = 1, 20 do
                    eye.TextTransparency = 1 - (j / 20)
                    task.wait(0.05)
                end
                task.wait(2)
                for j = 1, 20 do
                    eye.TextTransparency = j / 20
                    task.wait(0.05)
                end
            end)
        end
        
        Debris:AddItem(eyesFrame, 5)
    end
    
    -- NUEVA FUNCIÓN: Texto que aparece y desaparece
    local function createGhostText(message)
        local ghostText = Instance.new("TextLabel")
        ghostText.Size = UDim2.new(1, 0, 0.2, 0)
        ghostText.Position = UDim2.new(0, 0, math.random(20, 60)/100, 0)
        ghostText.Text = message
        ghostText.TextColor3 = Color3.fromRGB(255, 0, 0)
        ghostText.TextSize = 36
        ghostText.Font = Enum.Font.SourceSansBold
        ghostText.BackgroundTransparency = 1
        ghostText.TextTransparency = 1
        ghostText.TextStrokeTransparency = 0.5
        ghostText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        ghostText.ZIndex = 200
        ghostText.Parent = ScreenGui
        
        task.spawn(function()
            -- Aparecer
            for i = 1, 15 do
                ghostText.TextTransparency = 1 - (i / 15)
                ghostText.Position = ghostText.Position + UDim2.new(0, math.random(-5, 5), 0, math.random(-2, 2))
                task.wait(0.05)
            end
            task.wait(1.5)
            -- Desaparecer
            for i = 1, 15 do
                ghostText.TextTransparency = i / 15
                task.wait(0.05)
            end
            ghostText:Destroy()
        end)
    end
    
    -- NUEVA FUNCIÓN: Efecto de interferencia de pantalla
    local function createStaticInterference()
        local staticFrame = Instance.new("Frame")
        staticFrame.Size = UDim2.new(1, 0, 1, 0)
        staticFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        staticFrame.BackgroundTransparency = 0.8
        staticFrame.ZIndex = 120
        staticFrame.Parent = ScreenGui
        
        playSound("StaticNoise")
        
        task.spawn(function()
            for i = 1, 20 do
                staticFrame.BackgroundTransparency = 0.8 + math.random(-20, 20)/100
                staticFrame.BackgroundColor3 = Color3.fromRGB(
                    math.random(200, 255),
                    math.random(200, 255), 
                    math.random(200, 255)
                )
                task.wait(0.05)
            end
            sounds.StaticNoise:Stop()
            staticFrame:Destroy()
        end)
    end
    
    local function addMessage(senderName, messageText)
        local isMe = (senderName == Player.Name)
        local isUnknown = (senderName == "Desconocido")
        local timestamp = os.date("%H:%M")
        
        -- Efectos especiales INTENSOS si es el Desconocido
        if isUnknown then
            screenDistortion()
            terrorFlash()
            
            -- NUEVOS EFECTOS TERRORÍFICOS
            local randomEffect = math.random(1, 6)
            
            if randomEffect == 1 then
                createEyesEffect()
                playSound("Whisper")
            elseif randomEffect == 2 then
                createGhostText("TE ESTOY VIENDO")
                playSound("Breathing")
            elseif randomEffect == 3 then
                createStaticInterference()
            elseif randomEffect == 4 then
                playSound("Heartbeat")
                createGhostText("TU CORAZÓN LATE MUY RÁPIDO")
            elseif randomEffect == 5 then
                playSound("Footsteps")
                createGhostText("PASOS... CADA VEZ MÁS CERCA")
            else
                playSound("DoorCreak")
                createEyesEffect()
            end
            
            -- Efecto adicional: hacer que el fondo parpadee MÁS INTENSO
            task.spawn(function()
                local originalColor = MainFrame.BackgroundColor3
                for i = 1, 8 do -- Más parpadeos
                    MainFrame.BackgroundColor3 = Color3.fromRGB(math.random(20, 40), 0, 0)
                    task.wait(0.08)
                    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    task.wait(0.08)
                end
                MainFrame.BackgroundColor3 = originalColor
            end)
        end
        
        -- 1. Marco contenedor del mensaje (ocupa el 100% del ancho del Scroller)
        local MessageContainer = Instance.new("Frame")
        MessageContainer.Name = "MessageContainer"
        MessageContainer.BackgroundTransparency = 1
        MessageContainer.AutomaticSize = Enum.AutomaticSize.Y
        MessageContainer.Size = UDim2.new(1, 0, 0, 0) 
        MessageContainer.Parent = ChatScroller
        -- Usar LayoutOrder para asegurar el orden correcto al agregar
        MessageContainer.LayoutOrder = MessageLayout.AbsoluteContentSize.Y 
        
        local BubbleLayout = Instance.new("UIListLayout")
        BubbleLayout.HorizontalAlignment = isMe and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
        BubbleLayout.Padding = UDim.new(0, 0)
        BubbleLayout.Parent = MessageContainer
        
        -- 2. Burbuja de Contenido 
        local BubbleContent = Instance.new("Frame")
        BubbleContent.Name = "BubbleContent"
        
        BubbleContent.BackgroundColor3 = isMe and MY_MESSAGE_COLOR or (isUnknown and UNKNOWN_MESSAGE_COLOR or PARTNER_MESSAGE_COLOR)
        
        BubbleContent.AutomaticSize = Enum.AutomaticSize.XY 
        BubbleContent.Size = UDim2.new(0, 0, 0, 0)
        BubbleContent.Parent = MessageContainer
        
        Instance.new("UICorner", BubbleContent).CornerRadius = UDim.new(0, 10)
        
        local UIPadding = Instance.new("UIPadding")
        UIPadding.PaddingTop = UDim.new(0, 8)
        UIPadding.PaddingBottom = UDim.new(0, 8)
        UIPadding.PaddingLeft = UDim.new(0, 15)
        UIPadding.PaddingRight = UDim.new(0, 15)
        UIPadding.Parent = BubbleContent
        
        local UIList = Instance.new("UIListLayout")
        UIList.HorizontalAlignment = Enum.HorizontalAlignment.Left
        UIList.Padding = UDim.new(0, -5)
        UIList.Parent = BubbleContent
        
        -- Mensaje del Sistema no tiene Sender Label
        if not isMe and senderName ~= "Sistema" and not isUnknown then
            local SenderLabel = Instance.new("TextLabel")
            SenderLabel.Size = UDim2.new(1, 0, 0, 18)
            SenderLabel.Text = senderName
            SenderLabel.TextColor3 = ACCENT_COLOR
            SenderLabel.TextSize = 14
            SenderLabel.Font = Enum.Font.SourceSansBold
            SenderLabel.BackgroundTransparency = 1
            SenderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SenderLabel.Parent = BubbleContent
        end
        
        local MessageLabel = createMessageText(BubbleContent, isUnknown)
        MessageLabel.Text = messageText
        
        -- Frame para la hora 
        local TimeFrame = Instance.new("Frame")
        TimeFrame.Size = UDim2.new(1, 0, 0, 16)
        TimeFrame.BackgroundTransparency = 1
        TimeFrame.Parent = BubbleContent
        
        local TimeLabel = Instance.new("TextLabel")
        TimeLabel.Size = UDim2.new(0, 50, 1, 0)
        TimeLabel.Position = UDim2.new(1, -5, 0, 0)
        TimeLabel.AnchorPoint = Vector2.new(1, 0)
        TimeLabel.Text = timestamp
        TimeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        TimeLabel.TextSize = 12
        TimeLabel.Font = FONT_STYLE
        TimeLabel.BackgroundTransparency = 1
        TimeLabel.TextXAlignment = Enum.TextXAlignment.Right
        TimeLabel.Parent = TimeFrame
        
        -- Conexión de Doble Click/Toque
        BubbleContent.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                handleDoubleClick(BubbleContent, isMe)
            end
        end)
        
        
        -- Asegurar el desplazamiento al final
        -- Usar un pequeño retraso para que el layout se actualice
        task.wait() 
        ChatScroller.CanvasSize = UDim2.new(0, 0, 0, MessageLayout.AbsoluteContentSize.Y + 20) 
        ChatScroller.CanvasPosition = Vector2.new(0, ChatScroller.CanvasSize.Offset.Y)
    end
    
    local function getProfilePicture(userId)
        -- Asegurar que userId sea numérico y válido
        if type(userId) ~= "number" or userId <= 0 then 
            return "rbxassetid://13426021678" -- Fallback placeholder
        end
        local thumbType = Enum.ThumbnailType.HeadShot
        local thumbSize = Enum.ThumbnailSize.Size100x100 
        local content, _ = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
        return content
    end
    
    local function switchScreen(state, partnerName, partnerId)
        currentScreen = state
        local IntroScreen = MainFrame:FindFirstChild("IntroScreen")
        local RoomSelectScreen = MainFrame:FindFirstChild("RoomSelectScreen") 
        local ProfileScreen = MainFrame:FindFirstChild("ProfileScreen")
        local ReportScreen = MainFrame:FindFirstChild("ReportScreen")
        
        local ChatScreenElements = {ChatHeader, ChatScroller, ChatInputFrame}
        
        -- Ocultar todo
        if IntroScreen then IntroScreen.Visible = false end
        if RoomSelectScreen then RoomSelectScreen.Visible = false end
        if ProfileScreen then ProfileScreen.Visible = false end
        if ReportScreen then ReportScreen.Visible = false end
        for _, element in pairs(ChatScreenElements) do element.Visible = false end
        
        -- Mostrar el estado deseado
        if state == "Intro" then
            if IntroScreen then IntroScreen.Visible = true end
            if IntroScreen and IntroScreen.PlayButton then
                IntroScreen.PlayButton.Text = "JUGAR (Buscar Sala)"
                IntroScreen.PlayButton.Active = true
            end
            
            -- Limpiar el chat cuando se vuelve al Intro
            for _, message in pairs(ChatScroller:GetChildren()) do
                if message:IsA("Frame") and message.Name == "MessageContainer" then
                    message:Destroy()
                end
            end
            
            -- Reiniciar estados de sala/partida
            currentRoomId = nil
            
            -- Música del Intro/Espera
            playSound("IntroMusic")
            
        elseif state == "RoomSelect" then 
            if RoomSelectScreen then RoomSelectScreen.Visible = true end
            
            -- Música del Intro/Espera (asegurar que siga sonando)
            if not sounds.IntroMusic.IsPlaying then playSound("IntroMusic") end
            
            -- Solicitar lista de salas disponibles
            RoomListRequest:FireServer()
            
        elseif state == "HostWaiting" then 
            if RoomSelectScreen then 
                RoomSelectScreen.Visible = true 
                local WaitingLabel = RoomSelectScreen:FindFirstChild("WaitingLabel")
                if WaitingLabel then
                    WaitingLabel.Text = "Sala Creada: Esperando a que alguien se una..."
                end
            end
            
            -- Música del Intro/Espera (asegurar que siga sonando)
            if not sounds.IntroMusic.IsPlaying then playSound("IntroMusic") end
            
        else
            -- Detener la música cuando se sale del intro/espera para entrar al chat
            if sounds.IntroMusic.IsPlaying then
                sounds.IntroMusic:Stop()
            end
        end
        
        if state == "Chat" then
            currentPartnerName = partnerName 
            currentPartnerId = partnerId
            
            for _, element in pairs(ChatScreenElements) do element.Visible = true end
            
            HeaderText.Text = partnerName or "Error"
            ProfileButton.Active = true 
            
            if partnerId and partnerId > 0 then
                -- Actualizar foto de perfil con el UserID
                ProfileButton.Image = getProfilePicture(partnerId)
            end
            
        elseif state == "Profile" then
            if ProfileScreen then ProfileScreen.Visible = true end
            
            if ProfileScreen and ProfileScreen.UsernameText then
                ProfileScreen.UsernameText.Text = currentPartnerName or "Usuario Desconocido"
            end
            
            if currentPartnerId and currentPartnerId > 0 and ProfileScreen and ProfileScreen.ProfileImage then
                ProfileScreen.ProfileImage.Image = getProfilePicture(currentPartnerId)
            elseif ProfileScreen and ProfileScreen.ProfileImage then
                ProfileScreen.ProfileImage.Image = "rbxassetid://13426021678" -- Fallback
            end
            
        elseif state == "Report" then
            if ReportScreen then ReportScreen.Visible = true end
            if ReportScreen and ReportScreen.ReportTitle then
                ReportScreen.ReportTitle.Text = "Reportar a " .. (currentPartnerName or "Usuario")
            end
        end
    end
    
    --------------------------------------------------------------------------------
    -- 5. PANTALLAS ADICIONALES (Intro, Salas, Perfil y Reporte)
    --------------------------------------------------------------------------------
    
    -- ** 5.1. INTRO SCREEN CINEMÁTICA ÉPICA **
    local IntroScreen = Instance.new("Frame")
    IntroScreen.Name = "IntroScreen"
    IntroScreen.Size = UDim2.new(1, 0, 1, 0)
    IntroScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Pantalla completamente negra
    IntroScreen.Parent = MainFrame
    IntroScreen.ZIndex = 10
    
    -- Capa de efectos glitch
    local GlitchLayer = Instance.new("Frame")
    GlitchLayer.Name = "GlitchLayer"
    GlitchLayer.Size = UDim2.new(1, 0, 1, 0)
    GlitchLayer.BackgroundTransparency = 1
    GlitchLayer.Parent = IntroScreen
    GlitchLayer.ZIndex = 15
    
    -- Efecto de partículas / líneas glitch
    local function createGlitchEffect()
        for i = 1, 8 do
            local glitchLine = Instance.new("Frame")
            glitchLine.Size = UDim2.new(1, 0, 0, math.random(2, 8))
            glitchLine.Position = UDim2.new(0, 0, math.random(0, 100) / 100, 0)
            glitchLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            glitchLine.BackgroundTransparency = 0.3
            glitchLine.BorderSizePixel = 0
            glitchLine.Parent = GlitchLayer
            glitchLine.ZIndex = 16
            
            task.spawn(function()
                while glitchLine.Parent do
                    glitchLine.Visible = math.random() > 0.7
                    glitchLine.Position = UDim2.new(math.random(-10, 10) / 100, 0, math.random(0, 100) / 100, 0)
                    task.wait(0.05 + math.random() * 0.1)
                end
            end)
        end
    end
    
    -- Título con efecto glitch
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, 0, 0.15, 0)
    TitleLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
    TitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TitleLabel.Text = "WHATSAPP DEL TERROR"
    TitleLabel.TextColor3 = Color3.fromRGB(200, 0, 0)
    TitleLabel.TextSize = 48
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextStrokeTransparency = 0.5
    TitleLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.Parent = IntroScreen
    TitleLabel.ZIndex = 12
    TitleLabel.Visible = false
    
    -- Historia narrada
    local StoryText = Instance.new("TextLabel")
    StoryText.Name = "StoryText"
    StoryText.Size = UDim2.new(0.9, 0, 0.5, 0)
    StoryText.Position = UDim2.new(0.5, 0, 0.45, 0)
    StoryText.AnchorPoint = Vector2.new(0.5, 0.5)
    StoryText.Text = ""
    StoryText.TextColor3 = Color3.fromRGB(220, 220, 220)
    StoryText.TextSize = 24
    StoryText.TextWrapped = true
    StoryText.BackgroundTransparency = 1
    StoryText.TextXAlignment = Enum.TextXAlignment.Center
    StoryText.TextYAlignment = Enum.TextYAlignment.Center
    StoryText.Font = Enum.Font.SourceSans
    StoryText.Parent = IntroScreen
    StoryText.ZIndex = 12
    StoryText.Visible = false
    
    -- Frame para el dibujo visual (mano atrapando niño)
    local SketchFrame = Instance.new("Frame")
    SketchFrame.Name = "SketchFrame"
    SketchFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
    SketchFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    SketchFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    SketchFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SketchFrame.BorderSizePixel = 0
    SketchFrame.Parent = IntroScreen
    SketchFrame.ZIndex = 11
    SketchFrame.Visible = false
    
    -- Dibujo estilo sketch con ImageLabel
    local SketchImage = Instance.new("ImageLabel")
    SketchImage.Name = "SketchImage"
    SketchImage.Size = UDim2.new(1, 0, 1, 0)
    SketchImage.BackgroundTransparency = 1
    SketchImage.Image = "rbxassetid://18787470047" -- ID de imagen de mano/terror (placeholder, puedes cambiarlo)
    SketchImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
    SketchImage.ScaleType = Enum.ScaleType.Fit
    SketchImage.Parent = SketchFrame
    SketchImage.ZIndex = 12
    
    -- Efecto de luz parpadeante
    local LightFlash = Instance.new("Frame")
    LightFlash.Name = "LightFlash"
    LightFlash.Size = UDim2.new(1, 0, 1, 0)
    LightFlash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LightFlash.BackgroundTransparency = 1
    LightFlash.BorderSizePixel = 0
    LightFlash.Parent = IntroScreen
    LightFlash.ZIndex = 20
    
    local PlayButton = Instance.new("TextButton")
    PlayButton.Name = "PlayButton"
    PlayButton.Size = UDim2.new(0.6, 0, 0.1, 0)
    PlayButton.Position = UDim2.new(0.5, 0, 0.85, 0)
    PlayButton.AnchorPoint = Vector2.new(0.5, 0.5)
    PlayButton.Text = "JUGAR (Buscar Sala)"
    PlayButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    PlayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayButton.TextSize = 28
    PlayButton.Font = Enum.Font.SourceSansBold
    PlayButton.Parent = IntroScreen
    PlayButton.ZIndex = 12
    PlayButton.Visible = false
    Instance.new("UICorner", PlayButton).CornerRadius = UDim.new(0, 10)
    
    -- ** 5.2. Room Select Screen Setup **
    local RoomSelectScreen = Instance.new("Frame")
    RoomSelectScreen.Name = "RoomSelectScreen"
    RoomSelectScreen.Size = UDim2.new(1, 0, 1, 0)
    RoomSelectScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    RoomSelectScreen.Visible = false
    RoomSelectScreen.Parent = MainFrame
    
    local RoomsBack = Instance.new("TextButton")
    RoomsBack.Name = "RoomsBack"
    RoomsBack.Size = UDim2.new(0, 50, 0, 50)
    RoomsBack.Position = UDim2.new(0, 10, 0, 10)
    RoomsBack.Text = "<-"
    RoomsBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    RoomsBack.TextColor3 = TEXT_COLOR
    RoomsBack.TextSize = 24
    RoomsBack.Font = Enum.Font.SourceSansBold
    RoomsBack.Parent = RoomSelectScreen
    RoomsBack.MouseButton1Click:Connect(function() switchScreen("Intro") end) 
        Instance.new("UICorner", RoomsBack).CornerRadius = UDim.new(0, 10)
        
        local HeaderFrame = Instance.new("Frame")
        HeaderFrame.Size = UDim2.new(1, 0, 0.15, 0)
        HeaderFrame.Position = UDim2.new(0, 0, 0.05, 0)
        HeaderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        HeaderFrame.BorderSizePixel = 0
        HeaderFrame.Parent = RoomSelectScreen
        Instance.new("UICorner", HeaderFrame).CornerRadius = UDim.new(0, 10)
        
        local WaitingLabel = Instance.new("TextLabel")
        WaitingLabel.Name = "WaitingLabel"
        WaitingLabel.Size = UDim2.new(0.7, 0, 0.6, 0)
        WaitingLabel.Position = UDim2.new(0.05, 0, 0.2, 0)
        WaitingLabel.Text = "🏠 SALAS DE TERROR DISPONIBLES"
        WaitingLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        WaitingLabel.TextSize = 22
        WaitingLabel.Font = Enum.Font.SourceSansBold
        WaitingLabel.BackgroundTransparency = 1
        WaitingLabel.TextXAlignment = Enum.TextXAlignment.Left
        WaitingLabel.Parent = HeaderFrame
        
        local RefreshButton = Instance.new("TextButton")
        RefreshButton.Name = "RefreshButton"
        RefreshButton.Size = UDim2.new(0.25, 0, 0.6, 0)
        RefreshButton.Position = UDim2.new(0.7, 0, 0.2, 0)
        RefreshButton.Text = "🔄 ACTUALIZAR"
        RefreshButton.BackgroundColor3 = ACCENT_COLOR
        RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        RefreshButton.TextSize = 16
        RefreshButton.Font = Enum.Font.SourceSansBold
        RefreshButton.Parent = HeaderFrame
        Instance.new("UICorner", RefreshButton).CornerRadius = UDim.new(0, 8)
        
        RefreshButton.MouseButton1Click:Connect(function()
            RefreshButton.Text = "🔄 Actualizando..."
            RoomListRequest:FireServer()
            task.wait(1)
            RefreshButton.Text = "🔄 ACTUALIZAR"
        end)
        
        local RoomScroller = Instance.new("ScrollingFrame")
        RoomScroller.Name = "RoomScroller"
        RoomScroller.Size = UDim2.new(0.95, 0, 0.65, 0)
        RoomScroller.Position = UDim2.new(0.5, 0, 0.48, 0)
        RoomScroller.AnchorPoint = Vector2.new(0.5, 0.5)
        RoomScroller.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
        RoomScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
        RoomScroller.ScrollBarImageColor3 = ACCENT_COLOR
        RoomScroller.ScrollBarThickness = 8
        RoomScroller.Parent = RoomSelectScreen
        Instance.new("UICorner", RoomScroller).CornerRadius = UDim.new(0, 12)
        
        local ScrollerPadding = Instance.new("UIPadding")
        ScrollerPadding.PaddingTop = UDim.new(0, 15)
        ScrollerPadding.PaddingBottom = UDim.new(0, 15)
        ScrollerPadding.PaddingLeft = UDim.new(0, 15)
        ScrollerPadding.PaddingRight = UDim.new(0, 15)
        ScrollerPadding.Parent = RoomScroller
        
        local RoomLayout = Instance.new("UIListLayout")
        RoomLayout.Name = "RoomLayout"
        RoomLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RoomLayout.Padding = UDim.new(0, 10)
        RoomLayout.Parent = RoomScroller
        
        local ButtonFrame = Instance.new("Frame")
        ButtonFrame.Size = UDim2.new(1, 0, 0.12, 0)
        ButtonFrame.Position = UDim2.new(0, 0, 0.88, 0)
        ButtonFrame.BackgroundTransparency = 1
        ButtonFrame.Parent = RoomSelectScreen
        
        local CreateRoomButton = Instance.new("TextButton")
        CreateRoomButton.Name = "CreateRoomButton"
        CreateRoomButton.Size = UDim2.new(0.45, 0, 0.7, 0)
        CreateRoomButton.Position = UDim2.new(0.05, 0, 0.15, 0)
        CreateRoomButton.Text = "🏠 CREAR SALA"
        CreateRoomButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        CreateRoomButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CreateRoomButton.TextSize = 20
        CreateRoomButton.Font = Enum.Font.SourceSansBold
        CreateRoomButton.Parent = ButtonFrame
        Instance.new("UICorner", CreateRoomButton).CornerRadius = UDim.new(0, 12)
        
        local QuickJoinButton = Instance.new("TextButton")
        QuickJoinButton.Name = "QuickJoinButton"
        QuickJoinButton.Size = UDim2.new(0.45, 0, 0.7, 0)
        QuickJoinButton.Position = UDim2.new(0.5, 0, 0.15, 0)
        QuickJoinButton.Text = "⚡ UNIÓN RÁPIDA"
        QuickJoinButton.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
        QuickJoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        QuickJoinButton.TextSize = 20
        QuickJoinButton.Font = Enum.Font.SourceSansBold
        QuickJoinButton.Parent = ButtonFrame
        Instance.new("UICorner", QuickJoinButton).CornerRadius = UDim.new(0, 12)
        
        QuickJoinButton.MouseButton1Click:Connect(function()
            QuickJoinButton.Text = "⚡ Buscando..."
            QuickJoinButton.Active = false
            RoomAction:FireServer("QuickJoin")
        end)
        
        CreateRoomButton.MouseButton1Click:Connect(function()
            CreateRoomButton.Text = "Creando..."
            CreateRoomButton.Active = false
            RoomAction:FireServer("Create")
        end)
        
        
        -- Función para dibujar las salas MEJORADA
        local function updateRoomList(roomsTable)
            for _, child in pairs(RoomScroller:GetChildren()) do
                if child:IsA("Frame") and child.Name == "RoomEntry" then
                    child:Destroy()
                end
            end
            
            if #roomsTable == 0 then
                local emptyFrame = Instance.new("Frame")
                emptyFrame.Name = "EmptyFrame"
                emptyFrame.Size = UDim2.new(1, 0, 0, 200)
                emptyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                emptyFrame.Parent = RoomScroller
                Instance.new("UICorner", emptyFrame).CornerRadius = UDim.new(0, 15)
                
                local emptyIcon = Instance.new("TextLabel")
                emptyIcon.Size = UDim2.new(1, 0, 0.4, 0)
                emptyIcon.Text = "👻"
                emptyIcon.TextSize = 60
                emptyIcon.BackgroundTransparency = 1
                emptyIcon.Parent = emptyFrame
                
                local emptyText = Instance.new("TextLabel")
                emptyText.Size = UDim2.new(1, 0, 0.6, 0)
                emptyText.Position = UDim2.new(0, 0, 0.4, 0)
                emptyText.Text = "No hay salas disponibles\n¡Sé el primero en crear una sala de terror!"
                emptyText.TextColor3 = Color3.fromRGB(150, 150, 150)
                emptyText.TextSize = 18
                emptyText.TextWrapped = true
                emptyText.BackgroundTransparency = 1
                emptyText.Parent = emptyFrame
                
                WaitingLabel.Text = "🏠 NO HAY SALAS ACTIVAS"
            else
                WaitingLabel.Text = "🏠 SALAS DE TERROR DISPONIBLES (" .. #roomsTable .. ")"
            end
            
            for i, roomData in ipairs(roomsTable) do
                local roomEntry = Instance.new("Frame")
                roomEntry.Name = "RoomEntry"
                roomEntry.Size = UDim2.new(1, 0, 0, 80)
                roomEntry.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                roomEntry.Parent = RoomScroller
                Instance.new("UICorner", roomEntry).CornerRadius = UDim.new(0, 12)
                
                -- Efecto hover
                roomEntry.MouseEnter:Connect(function()
                    roomEntry.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
                end)
                roomEntry.MouseLeave:Connect(function()
                    roomEntry.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                end)
                
                local RoomIcon = Instance.new("TextLabel")
                RoomIcon.Size = UDim2.new(0, 50, 0, 50)
                RoomIcon.Position = UDim2.new(0, 15, 0.5, 0)
                RoomIcon.AnchorPoint = Vector2.new(0, 0.5)
                RoomIcon.Text = "🏚️"
                RoomIcon.TextSize = 30
                RoomIcon.BackgroundTransparency = 1
                RoomIcon.Parent = roomEntry
                
                local InfoFrame = Instance.new("Frame")
                InfoFrame.Size = UDim2.new(0.5, 0, 1, 0)
                InfoFrame.Position = UDim2.new(0, 75, 0, 0)
                InfoFrame.BackgroundTransparency = 1
                InfoFrame.Parent = roomEntry
                
                local HostName = Instance.new("TextLabel")
                HostName.Size = UDim2.new(1, 0, 0.5, 0)
                HostName.Text = "👤 Host: " .. roomData.HostName
                HostName.TextColor3 = Color3.fromRGB(255, 200, 200)
                HostName.TextSize = 18
                HostName.Font = Enum.Font.SourceSansBold
                HostName.BackgroundTransparency = 1
                HostName.TextXAlignment = Enum.TextXAlignment.Left
                HostName.Parent = InfoFrame
                
                local RoomStatus = Instance.new("TextLabel")
                RoomStatus.Size = UDim2.new(1, 0, 0.5, 0)
                RoomStatus.Position = UDim2.new(0, 0, 0.5, 0)
                RoomStatus.Text = "🟢 Esperando jugador..."
                RoomStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
                RoomStatus.TextSize = 14
                RoomStatus.BackgroundTransparency = 1
                RoomStatus.TextXAlignment = Enum.TextXAlignment.Left
                RoomStatus.Parent = InfoFrame
                
                local JoinButton = Instance.new("TextButton")
                JoinButton.Size = UDim2.new(0.25, 0, 0.6, 0)
                JoinButton.Position = UDim2.new(1, -15, 0.5, 0)
                JoinButton.AnchorPoint = Vector2.new(1, 0.5)
                JoinButton.Text = "👻 ENTRAR"
                JoinButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                JoinButton.TextSize = 16
                JoinButton.Font = Enum.Font.SourceSansBold
                JoinButton.Parent = roomEntry
                Instance.new("UICorner", JoinButton).CornerRadius = UDim.new(0, 8)
                
                -- Efecto hover del botón
                JoinButton.MouseEnter:Connect(function()
                    JoinButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                end)
                JoinButton.MouseLeave:Connect(function()
                    JoinButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                end)
                
                JoinButton.MouseButton1Click:Connect(function()
                    JoinButton.Text = "👻 Entrando..."
                    JoinButton.Active = false
                    RoomAction:FireServer("Join", roomData.Id)
                end)
            end
            
            -- Ajustar CanvasSize para el ScrollingFrame
            RoomScroller.CanvasSize = UDim2.new(0, 0, 0, RoomLayout.AbsoluteContentSize.Y + 30)
        end
        
        -- ** 5.3. Profile Screen Setup **
        local ProfileScreen = Instance.new("Frame")
        ProfileScreen.Name = "ProfileScreen"
        ProfileScreen.Size = UDim2.new(1, 0, 1, 0)
        ProfileScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        ProfileScreen.Visible = false
        ProfileScreen.Parent = MainFrame
        
        local ProfileBack = Instance.new("TextButton")
        ProfileBack.Size = UDim2.new(0, 50, 0, 50)
        ProfileBack.Position = UDim2.new(0, 10, 0, 10)
        ProfileBack.Text = "<-"
        ProfileBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        ProfileBack.TextColor3 = TEXT_COLOR
        ProfileBack.TextSize = 24
        ProfileBack.Font = Enum.Font.SourceSansBold
        ProfileBack.Parent = ProfileScreen
        ProfileBack.MouseButton1Click:Connect(function() switchScreen("Chat", currentPartnerName, currentPartnerId) end) 
            Instance.new("UICorner", ProfileBack).CornerRadius = UDim.new(0, 10)
            
            local ProfileImage = Instance.new("ImageLabel")
            ProfileImage.Name = "ProfileImage"
            ProfileImage.Size = UDim2.new(0.4, 0, 0.3, 0)
            ProfileImage.Position = UDim2.new(0.5, 0, 0.3, 0)
            ProfileImage.AnchorPoint = Vector2.new(0.5, 0.5)
            ProfileImage.BackgroundTransparency = 1
            ProfileImage.Image = "rbxassetid://13426021678" -- Placeholder
            ProfileImage.Parent = ProfileScreen
            Instance.new("UICorner", ProfileImage).CornerRadius = UDim.new(0.5, 0)
            
            local UsernameText = Instance.new("TextLabel")
            UsernameText.Name = "UsernameText"
            UsernameText.Size = UDim2.new(1, 0, 0.05, 0)
            UsernameText.Position = UDim2.new(0.5, 0, 0.5, 0)
            UsernameText.AnchorPoint = Vector2.new(0.5, 0)
            UsernameText.Text = "Usuario"
            UsernameText.TextColor3 = TEXT_COLOR
            UsernameText.TextSize = 28
            UsernameText.Font = Enum.Font.SourceSansBold
            UsernameText.BackgroundTransparency = 1
            UsernameText.Parent = ProfileScreen
            
            local FollowButton = Instance.new("TextButton")
            FollowButton.Name = "FollowButton"
            FollowButton.Size = UDim2.new(0.3, 0, 0.07, 0)
            FollowButton.Position = UDim2.new(0.5, 0, 0.65, 0)
            FollowButton.AnchorPoint = Vector2.new(0.5, 0.5)
            FollowButton.Text = "Seguir (Ficticio)"
            FollowButton.BackgroundColor3 = ACCENT_COLOR
            FollowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            FollowButton.TextSize = 20
            FollowButton.Parent = ProfileScreen
            Instance.new("UICorner", FollowButton).CornerRadius = UDim.new(0, 10)
            FollowButton.MouseButton1Click:Connect(function() 
                FollowButton.Text = "Siguiendo..."
                task.wait(1)
                FollowButton.Text = "Seguir (Ficticio)"
            end)
            
            local ReportProfileButton = Instance.new("TextButton")
            ReportProfileButton.Name = "ReportProfileButton"
            ReportProfileButton.Size = UDim2.new(0.4, 0, 0.07, 0)
            ReportProfileButton.Position = UDim2.new(0.5, 0, 0.75, 0)
            ReportProfileButton.AnchorPoint = Vector2.new(0.5, 0.5)
            ReportProfileButton.Text = "Reportar Usuario"
            ReportProfileButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            ReportProfileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            ReportProfileButton.TextSize = 20
            ReportProfileButton.Parent = ProfileScreen
            Instance.new("UICorner", ReportProfileButton).CornerRadius = UDim.new(0, 10)
            ReportProfileButton.MouseButton1Click:Connect(function() switchScreen("Report", currentPartnerName, currentPartnerId) end)
                
                -- ** 5.4. Report Screen Setup **
                local ReportScreen = Instance.new("Frame")
                ReportScreen.Name = "ReportScreen"
                ReportScreen.Size = UDim2.new(1, 0, 1, 0)
                ReportScreen.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                ReportScreen.Visible = false
                ReportScreen.Parent = MainFrame
                
                local ReportBack = Instance.new("TextButton")
                ReportBack.Size = UDim2.new(0, 50, 0, 50)
                ReportBack.Position = UDim2.new(0, 10, 0, 10)
                ReportBack.Text = "<-"
                ReportBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                ReportBack.TextColor3 = TEXT_COLOR
                ReportBack.TextSize = 24
                ReportBack.Font = Enum.Font.SourceSansBold
                ReportBack.Parent = ReportScreen
                ReportBack.MouseButton1Click:Connect(function() switchScreen("Profile", currentPartnerName, currentPartnerId) end)
                    Instance.new("UICorner", ReportBack).CornerRadius = UDim.new(0, 10)
                    
                    local ReportTitle = Instance.new("TextLabel")
                    ReportTitle.Name = "ReportTitle"
                    ReportTitle.Size = UDim2.new(1, 0, 0.1, 0)
                    ReportTitle.Position = UDim2.new(0.5, 0, 0.05, 0)
                    ReportTitle.AnchorPoint = Vector2.new(0.5, 0)
                    ReportTitle.Text = "Reportar a Usuario"
                    ReportTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
                    ReportTitle.TextSize = 30
                    ReportTitle.Font = Enum.Font.SourceSansBold
                    ReportTitle.BackgroundTransparency = 1
                    ReportTitle.Parent = ReportScreen
                    
                    local reasonFrame = Instance.new("Frame")
                    reasonFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
                    reasonFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
                    reasonFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    reasonFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    reasonFrame.Parent = ReportScreen
                    Instance.new("UICorner", reasonFrame).CornerRadius = UDim.new(0, 15)
                    Instance.new("UIListLayout", reasonFrame).Padding = UDim.new(0, 10)
                    
                    local UIPaddingReport = Instance.new("UIPadding")
                    UIPaddingReport.PaddingTop = UDim.new(0, 10)
                    UIPaddingReport.PaddingBottom = UDim.new(0, 10)
                    UIPaddingReport.PaddingLeft = UDim.new(0, 10)
                    UIPaddingReport.PaddingRight = UDim.new(0, 10)
                    UIPaddingReport.Parent = reasonFrame
                    
                    -- Opciones de Reporte
                    local reasons = {"Acoso/bullying", "Contenido inapropiado", "Trampas/exploits", "Spam", "Otros"}
                    local selectedReason = nil
                    
                    for _, reason in ipairs(reasons) do
                        local button = Instance.new("TextButton")
                        button.Size = UDim2.new(1, 0, 0, 40)
                        button.Text = reason
                        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        button.TextColor3 = TEXT_COLOR
                        button.TextSize = 18
                        button.Font = FONT_STYLE
                        button.Parent = reasonFrame
                        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
                        
                        button.MouseButton1Click:Connect(function()
                            selectedReason = reason
                            for _, child in ipairs(reasonFrame:GetChildren()) do
                                if child:IsA("TextButton") and child.Name ~= "SubmitReportButton" then
                                    child.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                                end
                            end
                            button.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
                        end)
                    end
                    
                    local SubmitReportButton = Instance.new("TextButton")
                    SubmitReportButton.Name = "SubmitReportButton"
                    SubmitReportButton.Size = UDim2.new(0.6, 0, 0.07, 0)
                    SubmitReportButton.Position = UDim2.new(0.5, 0, 0.85, 0)
                    SubmitReportButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    SubmitReportButton.Text = "Enviar Reporte"
                    SubmitReportButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
                    SubmitReportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                    SubmitReportButton.TextSize = 24
                    SubmitReportButton.Font = Enum.Font.SourceSansBold
                    SubmitReportButton.Parent = ReportScreen
                    Instance.new("UICorner", SubmitReportButton).CornerRadius = UDim.new(0, 10)
                    
                    SubmitReportButton.MouseButton1Click:Connect(function()
                        if not selectedReason then
                            SubmitReportButton.Text = "¡Selecciona una razón!"
                            SubmitReportButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
                            task.wait(1)
                            SubmitReportButton.Text = "Enviar Reporte"
                            SubmitReportButton.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
                            return
                        end
                        
                        ReportUser:FireServer(currentPartnerName, selectedReason)
                    end)
                    
                    
                    --------------------------------------------------------------------------------
                    -- 6. MANEJADORES DE EVENTOS
                    --------------------------------------------------------------------------------
                    
                    -- ** FUNCIÓN DE INTRO CINEMÁTICA **
                    local introPlayed = false
                    
                    local function playCinematicIntro()
                        if introPlayed then 
                            switchScreen("RoomSelect")
                            return 
                        end
                        
                        introPlayed = true
                        
                        -- Iniciar música de terror
                        playSound("IntroMusic")
                        
                        -- Activar efectos glitch
                        createGlitchEffect()
                        
                        -- Flash de luz inicial
                        task.spawn(function()
                            for i = 1, 3 do
                                LightFlash.BackgroundTransparency = 0.5
                                playSound("GlitchSound")
                                task.wait(0.1)
                                LightFlash.BackgroundTransparency = 1
                                task.wait(0.3)
                            end
                        end)
                        
                        task.wait(1)
                        
                        -- Mostrar título con efecto
                        TitleLabel.Visible = true
                        TitleLabel.TextTransparency = 1
                        for i = 1, 20 do
                            TitleLabel.TextTransparency = 1 - (i / 20)
                            task.wait(0.05)
                        end
                        
                        -- Efecto glitch en el título
                        task.spawn(function()
                            for i = 1, 5 do
                                TitleLabel.Position = UDim2.new(0.5 + math.random(-5, 5) / 100, 0, 0.1, 0)
                                task.wait(0.1)
                            end
                            TitleLabel.Position = UDim2.new(0.5, 0, 0.1, 0)
                        end)
                        
                        task.wait(2)
                        
                        -- Desvanecer título
                        for i = 1, 15 do
                            TitleLabel.TextTransparency = i / 15
                            task.wait(0.05)
                        end
                        TitleLabel.Visible = false
                        
                        task.wait(0.5)
                        
                        -- HISTORIA NARRADA (textos que aparecen progresivamente)
                        local storyParts = {
                        "En la oscuridad de la noche...",
                        "Dos almas se conectan sin saber...",
                        "Que algo más los observa...",
                        "Algo que acecha en las sombras digitales...",
                        "Si detecta su presencia...",
                        "NO RESPONDAS.",
                        "TU VIDA DEPENDE DE ELLO."
                        }
                        
                        StoryText.Visible = true
                        for _, part in ipairs(storyParts) do
                            StoryText.Text = ""
                            StoryText.TextTransparency = 0
                            
                            -- Efecto de escritura letra por letra
                            for i = 1, #part do
                                StoryText.Text = string.sub(part, 1, i)
                                task.wait(0.05)
                            end
                            
                            -- Flash ocasional
                            if math.random() > 0.6 then
                                LightFlash.BackgroundTransparency = 0.7
                                task.wait(0.05)
                                LightFlash.BackgroundTransparency = 1
                            end
                            
                            task.wait(1.5)
                            
                            -- Desvanecer
                            for i = 1, 10 do
                                StoryText.TextTransparency = i / 10
                                task.wait(0.05)
                            end
                        end
                        
                        StoryText.Visible = false
                        task.wait(0.5)
                        
                        -- MOSTRAR VISUAL ESTILO DIBUJO (Mano atrapando niño)
                        SketchFrame.Visible = true
                        SketchImage.ImageTransparency = 1
                        
                        -- Aparecer gradualmente el dibujo
                        for i = 1, 20 do
                            SketchImage.ImageTransparency = 1 - (i / 20)
                            task.wait(0.05)
                        end
                        
                        -- Efecto de intensidad - el dibujo pulsa
                        task.spawn(function()
                            for i = 1, 3 do
                                SketchFrame.Size = UDim2.new(0.65, 0, 0.55, 0)
                                task.wait(0.3)
                                SketchFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
                                task.wait(0.3)
                            end
                        end)
                        
                        -- Flash final dramático
                        task.wait(2)
                        for i = 1, 5 do
                            LightFlash.BackgroundTransparency = 0.3
                            playSound("GlitchSound")
                            task.wait(0.1)
                            LightFlash.BackgroundTransparency = 1
                            task.wait(0.15)
                        end
                        
                        -- Desvanecer el dibujo
                        for i = 1, 15 do
                            SketchImage.ImageTransparency = i / 15
                            task.wait(0.05)
                        end
                        SketchFrame.Visible = false
                        
                        task.wait(0.5)
                        
                        -- Mostrar botón de jugar
                        PlayButton.Visible = true
                        PlayButton.BackgroundTransparency = 1
                        PlayButton.TextTransparency = 1
                        
                        for i = 1, 20 do
                            PlayButton.BackgroundTransparency = 1 - (i / 20)
                            PlayButton.TextTransparency = 1 - (i / 20)
                            task.wait(0.03)
                        end
                        
                        PlayButton.Active = true
                    end
                    
                    -- Click en el botón de Jugar (Ahora va a la selección de salas)
                    PlayButton.MouseButton1Click:Connect(function()
                        PlayButton.Text = "Cargando Salas..."
                        PlayButton.Active = false
                        
                        switchScreen("RoomSelect") 
                    end)
                    
                    -- Click en el icono de Perfil (EN CABECERA)
                    ProfileButton.MouseButton1Click:Connect(function()
                        if currentScreen == "Chat" and currentPartnerName and currentPartnerId then
                            switchScreen("Profile", currentPartnerName, currentPartnerId)
                        end
                    end)
                    
                    -- Manejar sonido de escritura
                    InputBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if currentScreen == "Chat" and InputBox.Text ~= "" then
                            local currentTime = tick()
                            if currentTime - lastTypingSoundTime > TYPING_THROTTLE then
                                playSound("Typing")
                                lastTypingSoundTime = currentTime
                            end
                        end
                    end)
                    
                    -- Envío de mensaje
                    local function sendMessage()
                        local message = InputBox.Text
                        if message:match("^%s*$") then return end
                        
                        MessageSend:FireServer(message)
                        InputBox.Text = "" -- Limpiar texto
                        
                        playSound("MessageSent")
                    end
                    
                    InputBox.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Return then
                            sendMessage()
                        end
                    end)
                    SendButton.MouseButton1Click:Connect(sendMessage)
                    
                    -- Listener para las actualizaciones del servidor
                    ClientUpdate.OnClientEvent:Connect(function(status, senderName, message)
                        if status == "Connected" then
                            
                            local partnerId = tonumber(message) 
                            
                            if partnerId and partnerId > 0 then
                                print("[CLIENT] Conexión Exitosa con UserID: " .. partnerId)
                                playSound("Connected") 
                                switchScreen("Chat", senderName, partnerId)
                                addMessage("Sistema", "¡Conexión exitosa! Ahora estás en un chat con: "..senderName..".")
                            else
                                warn("[CLIENT ERROR] No se recibió un UserID válido al conectar. Volviendo a Intro.")
                                switchScreen("Intro") -- Volver a Intro en caso de error crítico
                            end
                            
                        elseif status == "RoomListUpdate" then 
                            local success, roomsTable = pcall(HttpService.JSONDecode, HttpService, message)
                            if success and typeof(roomsTable) == "table" then
                                updateRoomList(roomsTable)
                            else
                                warn("[CLIENT] Error al decodificar la lista de salas.")
                                updateRoomList({})
                            end
                            -- Reactivar botón de crear sala
                            if CreateRoomButton.Text ~= "CREAR NUEVA SALA" then
                                CreateRoomButton.Text = "CREAR NUEVA SALA"
                                CreateRoomButton.Active = true
                            end
                            
                        elseif status == "RoomStatusUpdate" then 
                            if senderName == "HostWaiting" then
                                -- El jugador acaba de crear una sala y está esperando
                                currentRoomId = message -- Asumiendo que el servidor envía el RoomId o HostName aquí.
                                switchScreen("HostWaiting")
                            end
                            
                        elseif status == "NewMessage" then
                            
                            addMessage(senderName, message)
                            
                            if senderName == Player.Name then
                                -- Mensaje propio
                            elseif senderName == "Desconocido" then
                                playSound("UnknownEnter")
                                
                                -- EFECTOS ADICIONALES TERRORÍFICOS
                                local terrorEffect = math.random(1, 4)
                                
                                if terrorEffect == 1 then
                                    playSound("Scream")
                                    createGhostText("¡NO PUEDES ESCAPAR!")
                                elseif terrorEffect == 2 then
                                    playSound("PhoneRing")
                                    createStaticInterference()
                                elseif terrorEffect == 3 then
                                    playSound("Heartbeat")
                                    createEyesEffect()
                                else
                                    playSound("Whisper")
                                    createGhostText("ESTOY AQUÍ...")
                                end
                            else
                                playSound("MessageReceived")
                            end
                            
                        elseif status == "Disconnected" then
                            -- Mostrar el mensaje de desconexión antes de cambiar de pantalla
                            addMessage("Sistema", message or "¡Tu compañero se ha desconectado! La sesión ha terminado. Vuelve a Intentarlo.")
                            -- Esperar un momento para que el usuario lea
                            task.wait(1.5)
                            switchScreen("Intro")
                            
                        elseif status == "ReportSent" then
                            local submitBtn = ReportScreen:FindFirstChild("SubmitReportButton")
                            if submitBtn then
                                submitBtn.Text = "¡REPORTE ENVIADO!"
                                submitBtn.BackgroundColor3 = ACCENT_COLOR
                                task.wait(1.5)
                            end
                            switchScreen("Profile", currentPartnerName, currentPartnerId)
                        end
                    end)
                    
                    -- Solicitar lista de salas cada 5 segundos para mantenerla actualizada
                    task.spawn(function()
                        while task.wait(5) do
                            if currentScreen == "RoomSelect" then
                                RoomListRequest:FireServer()
                            end
                        end
                    end)
                    
                    -- Iniciar con la pantalla de introducción
                    switchScreen("Intro")
                    
                    -- Ejecutar la intro cinemática automáticamente
                    task.spawn(function()
                        task.wait(0.5) -- Pequeño delay para que cargue todo
                        playCinematicIntro()
                    end)
                    
