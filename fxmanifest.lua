fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Neutral Studios'
name 'ns_radialmenu'
description 'Advanced radial menu'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/init.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/main.lua',
    'client/vehicle.lua',
    'client/clothing.lua',
    'client/wallet.lua',
    'client/blips.lua',
    'client/trunk.lua',
    'client/jobs.lua',
    'client/housing.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/main.lua'
}

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'locales/*.json'
}

ox_libs {
    'locale'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
