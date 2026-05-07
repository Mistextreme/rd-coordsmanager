--[[
    rd-coordsmanager | Server
    RoxDev Development Store
    roxdev.tebex.io
]]

local ESX    = nil
local QBCore = nil

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
--  Auto-Create Table on First Start
-- ─────────────────────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `rd_coords` (
            `id`         INT          NOT NULL AUTO_INCREMENT,
            `discord_id` VARCHAR(100) NOT NULL,
            `name`       VARCHAR(60)  NOT NULL DEFAULT 'Unnamed',
            `x`          FLOAT        NOT NULL DEFAULT 0,
            `y`          FLOAT        NOT NULL DEFAULT 0,
            `z`          FLOAT        NOT NULL DEFAULT 0,
            `heading`    FLOAT        NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_discord` (`discord_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print('^2[rd-coordsmanager]^0 Database table ready.')
end)

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────

--- Returns the discord: identifier for a player, or nil.
local function GetDiscordId(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(identifier, 1, 8) == 'discord:' then
            return identifier
        end
    end
    return nil
end

--- Returns true if the discord ID is in Config.AllowedDiscords.
local function IsAllowed(discordId)
    if not discordId then return false end
    for _, allowed in ipairs(Config.AllowedDiscords) do
        if allowed == discordId then return true end
    end
    return false
end

--- Fetches the full ordered coord list for a discord ID.
local function FetchCoords(discordId)
    return MySQL.query.await(
        'SELECT * FROM rd_coords WHERE discord_id = ? ORDER BY id DESC',
        { discordId }
    ) or {}
end

-- ─────────────────────────────────────────────
--  Access Check  (triggered when player opens menu)
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:checkAccess', function()
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then
        TriggerClientEvent('rd-coordsmanager:client:accessDenied', src)
        return
    end

    local coords = FetchCoords(discordId)
    TriggerClientEvent('rd-coordsmanager:client:openMenu', src, coords)
end)

-- ─────────────────────────────────────────────
--  Refresh Coord List
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:refreshCoords', function()
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then return end

    TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
end)

-- ─────────────────────────────────────────────
--  Save New Coord
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:saveCoord', function(data)
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then return end

    -- Enforce per-player max
    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM rd_coords WHERE discord_id = ?',
        { discordId }
    ) or 0

    if count >= Config.MaxCoords then
        print(string.format(
            '^3[rd-coordsmanager]^0 Player %s (%s) hit the %d coord limit.',
            GetPlayerName(src), discordId, Config.MaxCoords
        ))
        -- Return existing list so the client stays in sync
        TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
        return
    end

    MySQL.insert.await(
        'INSERT INTO rd_coords (discord_id, name, x, y, z, heading) VALUES (?, ?, ?, ?, ?, ?)',
        {
            discordId,
            data.name    or 'Unnamed',
            data.x       or 0.0,
            data.y       or 0.0,
            data.z       or 0.0,
            data.heading or 0.0,
        }
    )

    TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
end)

-- ─────────────────────────────────────────────
--  Rename Coord
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:renameCoord', function(data)
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then return end

    MySQL.update.await(
        'UPDATE rd_coords SET name = ? WHERE id = ? AND discord_id = ?',
        { data.name or 'Unnamed', data.id, discordId }
    )

    TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
end)

-- ─────────────────────────────────────────────
--  Delete Coord
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:deleteCoord', function(data)
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then return end

    -- Use execute (not update) for DELETE statements with oxmysql
    MySQL.query.await(
        'DELETE FROM rd_coords WHERE id = ? AND discord_id = ?',
        { data.id, discordId }
    )

    TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
end)

-- ─────────────────────────────────────────────
--  Update Coord to New Position
-- ─────────────────────────────────────────────
RegisterNetEvent('rd-coordsmanager:server:updateCoord', function(data)
    local src       = source
    local discordId = GetDiscordId(src)

    if not IsAllowed(discordId) then return end

    MySQL.update.await(
        'UPDATE rd_coords SET x = ?, y = ?, z = ?, heading = ? WHERE id = ? AND discord_id = ?',
        {
            data.x       or 0.0,
            data.y       or 0.0,
            data.z       or 0.0,
            data.heading or 0.0,
            data.id,
            discordId,
        }
    )

    TriggerClientEvent('rd-coordsmanager:client:receiveCoords', src, FetchCoords(discordId))
end)
