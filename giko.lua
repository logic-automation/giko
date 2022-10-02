package.path = (string.gsub(_addon.path, '[^\\]+\\?$', '')) .. 'giko-common\\' .. '?.lua;' .. package.path

_addon.author 	= 'giko'
_addon.name 	= 'giko'
_addon.version 	= '1.0.5'

console  = require('core.console')
screamer = require('core.screamer')
listener = require('core.listener')

ashita.register_event('load', screamer.load)
ashita.register_event('command', console.input)
ashita.register_event('incoming_text', listener.listen)