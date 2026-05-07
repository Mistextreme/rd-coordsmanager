--[[
    rd-coordsmanager | Client
    RoxDev Development Store
    roxdev.tebex.io
]]

local isMenuOpen = false
local ESX        = nil
local QBCore     = nil

-- ─────────────────────────────────────────────
--  Framework Init
-- ─────────────────────────────────────────────
CreateThread(function()
    if Config.Framework == 'auto' or Config.Framework == 'esx' then
        local ok = pcall(function()
            ESX = exports['es_extended']:getSharedObject()
        end)
        if ok and ESX then
            Config.Framework = 'esx'
            return
        end
    end

    if Config.Framework == 'auto' or Config.Framework == 'qb' then
        local ok = pcall(function()
            QBCore = exports['qb-core']:GetCoreObject()
        end)
        if ok and QBCore then
            Config.Framework = 'qb'
            return
        end
    end

    if Config.Framework == 'auto' then
        Config.Framework = 'standalone'
    end
end)

-- ─────────────────────────────────────────────
--  Notification Helper
-- ─────────────────────────────────────────────
local function Notify(msg, notifyType)
    notifyType = notifyType or 'info'

    local system = Config.NotifySystem

    if system == 'auto' then
        if Config.Framework == 'esx' then
            system = 'esx'
        elseif Config.Framework == 'qb' then
            system = 'qb'
        else
            system = 'chat'
        end
    end

    if system == 'esx' and ESX then
        ESX.ShowNotification(msg)

    elseif system == 'qb' and QBCore then
        QBCore.Functions.Notify(msg, notifyType)

    elseif system == 'ox' then
        lib.notify({ title = 'Coords Manager', description = msg, type = notifyType })

    elseif system == 'chat' then
        TriggerEvent('chat:addMessage', {
            color = { 155, 109, 255 },
            args  = { 'CoordsManager', msg },
        })

    else
        -- Standalone fallback: floating help text
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

-- ─────────────────────────────────────────────
--  Open Menu  (asks server to validate first)
-- ─────────────────────────────────────────────
local function OpenMenu()
    if isMenuOpen then return end
    TriggerServerEvent('rd-coordsmanager:server:checkAccess')
end

-- ─────────────────────────────────────────────
--  Command Registration
-- ─────────────────────────────────────────────
if Config.Command then
    RegisterCommand(Config.Command, function()
        OpenMenu()
    end, false)
end

-- ─────────────────────────────────────────────
--  Keybind Registration
-- ─────────────────────────────────────────────
if Config.Keybind then
    local cmdForBind = Config.Command or 'rd_coordsmanager_open'

    -- Register hidden command if no slash command is enabled
    if not Config.Command then
        RegisterCommand(cmdForBind, function()
            OpenMenu()
        end, false)
    end

    RegisterKeyMapping(cmdForBind, 'Open Coords Manager', 'keyboard', Config.Keybind)
end

-- ─────────────────────────────────────────────
--  Server → Client: Access Granted → Open NUI
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:client:openMenu', function(coords)
    if isMenuOpen then return end
    isMenuOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action      = 'openMenu',
        copyFormats = Config.CopyFormats,
        defaultFmt  = Config.DefaultCopyFormat,
    })

    SendNUIMessage({
        action = 'receiveCoords',
        coords = coords or {},
    })
end)

-- ─────────────────────────────────────────────
--  Server → Client: Access Denied
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:client:accessDenied', function()
    Notify('You do not have permission to use Coords Manager.', 'error')
end)

-- ─────────────────────────────────────────────
--  Server → Client: Refreshed Coord List
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:client:receiveCoords', function(coords)
    SendNUIMessage({
        action = 'receiveCoords',
        coords = coords or {},
    })
end)

-- ─────────────────────────────────────────────
--  NUI Callbacks
-- ─────────────────────────────────────────────

-- Take current position
RegisterNUICallback('takeCoord', function(_, cb)
    local ped     = PlayerPedId()
    local pos     = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    cb({
        x       = pos.x,
        y       = pos.y,
        z       = pos.z,
        heading = heading,
    })
end)

-- Save a new named coord
RegisterNUICallback('saveCoord', function(data, cb)
    TriggerServerEvent('rd-coordsmanager:server:saveCoord', {
        name    = data.name,
        x       = data.x,
        y       = data.y,
        z       = data.z,
        heading = data.heading,
    })
    cb('ok')
end)

-- Rename an existing coord
RegisterNUICallback('renameCoord', function(data, cb)
    TriggerServerEvent('rd-coordsmanager:server:renameCoord', {
        id   = data.id,
        name = data.name,
    })
    cb('ok')
end)

-- Delete a coord
RegisterNUICallback('deleteCoord', function(data, cb)
    TriggerServerEvent('rd-coordsmanager:server:deleteCoord', { id = data.id })
    cb('ok')
end)

-- Update an existing coord to the player's current position
RegisterNUICallback('updateCoord', function(data, cb)
    local ped     = PlayerPedId()
    local pos     = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    TriggerServerEvent('rd-coordsmanager:server:updateCoord', {
        id      = data.id,
        x       = pos.x,
        y       = pos.y,
        z       = pos.z,
        heading = heading,
    })
    cb('ok')
end)

-- Teleport to a coord
RegisterNUICallback('teleport', function(data, cb)
    if not Config.AllowTeleport then
        cb('denied')
        return
    end

    local ped = PlayerPedId()
    SetEntityCoords(ped, data.x, data.y, data.z, false, false, false, true)
    SetEntityHeading(ped, data.heading)
    cb('ok')
end)

-- Request a fresh coord list from the server
RegisterNUICallback('refreshCoords', function(_, cb)
    TriggerServerEvent('rd-coordsmanager:server:refreshCoords')
    cb('ok')
end)

-- Close the menu
RegisterNUICallback('closeMenu', function(_, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)
