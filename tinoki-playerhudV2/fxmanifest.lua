fx_version 'cerulean'
game 'gta5'
version '1.0.1'
author 'TinoKi' 
description 'HUD by TinoKi V2'


ui_page 'html/index.html'
files {
	"html/index.html",
	"html/script.js",
	"html/styles.css",
	"html/img/*.svg",
	"html/img/*.png"
}

client_scripts {
	'client/client.lua',
}

server_scripts {
    'server/server.lua',
}

