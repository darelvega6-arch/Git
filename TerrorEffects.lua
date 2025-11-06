--[[
EFECTOS DE TERROR EXTREMOS - MÓDULO ADICIONAL
Coloca este script en ServerScriptService para efectos de terror más intensos
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- RemoteEvent para efectos especiales
local TerrorEffects = Instance.new("RemoteEvent")
TerrorEffects.Name = "TerrorEffects"
TerrorEffects.Parent = ReplicatedStorage

-- EFECTOS DE TERROR EXTREMOS QUE SE ACTIVAN ALEATORIAMENTE
local ExtremeEffects = {
    "SCREEN_INVERT",     -- Invertir colores de pantalla
    "FAKE_DISCONNECT",   -- Simular desconexión
    "CURSOR_CONTROL",    -- Mover el cursor del jugador
    "FAKE_ERROR",        -- Mostrar error falso
    "BATTERY_WARNING",   -- Advertencia de batería baja
    "CAMERA_SHAKE",      -- Sacudir la cámara
    "FAKE_VIRUS",        -- Simular virus en pantalla
    "GHOST_TYPING"       -- Texto que se escribe solo
}

-- Mensajes de terror extremo
local ExtremeMessages = {
    "SISTEMA COMPROMETIDO - CERRANDO APLICACIÓN EN 10 SEGUNDOS",
    "ERROR CRÍTICO: ENTIDAD DESCONOCIDA DETECTADA EN EL SISTEMA",
    "ADVERTENCIA: BATERÍA AL 1% - EL DISPOSITIVO SE APAGARÁ",
    "ACCESO REMOTO DETECTADO - ALGUIEN MÁS CONTROLA TU DISPOSITIVO",
    "VIRUS DETECTADO: ELIMINANDO ARCHIVOS PERSONALES...",
    "CÁMARA ACTIVADA - GRABANDO... SONRÍE",
    "MICRÓFONO ACTIVADO - ESCUCHANDO TUS SUSURROS",
    "GPS ACTIVADO - UBICACIÓN COMPARTIDA CON DESCONOCIDO"
}

-- Función para activar efectos extremos aleatoriamente
local function triggerExtremeEffect(player)
    local effect = ExtremeEffects[math.random(1, #ExtremeEffects)]
    local message = ExtremeMessages[math.random(1, #ExtremeMessages)]
    
    TerrorEffects:FireClient(player, effect, message)
    
    print("[TERROR EXTREMO] Efecto " .. effect .. " enviado a " .. player.Name)
end

-- Activar efectos extremos cada 45-90 segundos para jugadores en chat
local lastExtremeEffect = {}

RunService.Stepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        local userId = player.UserId
        
        -- Solo aplicar a jugadores que están chateando (esto se puede mejorar con mejor detección)
        if not lastExtremeEffect[userId] then
            lastExtremeEffect[userId] = tick()
        end
        
        -- Activar efecto extremo cada 60-120 segundos
        if tick() - lastExtremeEffect[userId] > math.random(60, 120) then
            triggerExtremeEffect(player)
            lastExtremeEffect[userId] = tick()
        end
    end
end)

-- Limpiar al salir jugador
Players.PlayerRemoving:Connect(function(player)
    lastExtremeEffect[player.UserId] = nil
end)

print("Módulo de Terror Extremo cargado - Los jugadores van a temblar de miedo")