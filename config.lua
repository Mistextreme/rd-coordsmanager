--[[
    rd-coordsmanager | RoxDev Development Store
    roxdev.tebex.io
]]

Config = {}

-- Framework: 'auto' | 'qb' | 'esx' | 'standalone'
Config.Framework = 'auto'

-- Notification system: 'auto' | 'qb' | 'esx' | 'ox' | 'chat' | 'standalone'
Config.NotifySystem = 'auto'

-- Command to open the menu (false to disable)
Config.Command = 'coords'

-- Default keybind to open the menu (false to disable)
-- Players can rebind it in GTA V settings > Key Bindings
Config.Keybind = 'F7'

--[[
    Allowed Discord IDs.
    Only players with a matching Discord ID can open the menu.

    How to find your Discord ID:
    Discord > Settings > Advanced > Enable Developer Mode
    Then right-click your name > Copy ID
    Prefix it with 'discord:' as shown below.
]]
Config.AllowedDiscords = {
    'discord:000000000000000000',
}

-- Maximum number of saved coords per player
Config.MaxCoords = 150

-- Format used when copying a coord from the menu
-- Available placeholders: {x} {y} {z} {heading} {name}
Config.CopyFormats = {
    vector4 = 'vector4({x}, {y}, {z}, {heading})',
    vector3 = 'vector3({x}, {y}, {z})',
    table   = '{{ x = {x}, y = {y}, z = {z}, h = {heading} }}',
    raw     = '{x}, {y}, {z}, {heading}',
}

-- Default copy format key (must match one of the keys above)
Config.DefaultCopyFormat = 'vector4'

-- Allow players to teleport to a saved coord from the menu
Config.AllowTeleport = true