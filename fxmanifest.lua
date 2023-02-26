fx_version "bodacious"
games {"gta5"}
lua54 'yes'

client_scripts {
    'locales.lua',
    'config.lua',
    'client.lua',
}
server_scripts {
	'@oxmysql/lib/MySQL.lua',
    'locales.lua',
    'sv_config.lua',
    'config.lua',
	'server.lua',
}
