fx_version 'cerulean'
game 'gta5'

name        'rd-coordsmanager'
description 'RoxDev - Coords Manager | QB-Core | ESX | Standalone'
author      'RoxDev'
version     '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
   -- '@oxmysql/lib/MySQL.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png',
}

escrow_ignore {
    'config.lua',
}

lua54 'yes'
dependency '/assetpacks'