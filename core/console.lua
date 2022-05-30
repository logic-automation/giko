local config  = require('lib.giko.config')
local common  = require('lib.giko.common')
local monster = require('lib.giko.monster')
local chat    = require('lib.giko.chat')
local console = { command= {} }

console.input = function(command, ntype)

    local command, args = string.match(command, '^/giko%s+(%w+)(.*)')

    if command == nil then
        return false
    end

    local registry = 
    {
        ['alerts'] = console.command.alerts,
    }

    if registry[command] then
        registry[command](args)
    end
    
    if registry[command] == nil then
        console.command.help()
    end

    return true

end

console.command.alerts = function(args)

    if args == 'reload' then
        screamer.reload()
    end

end

console.command.help = function(args)

    common.help('/giko', 
    {
        {'/giko alerts reload', 'Reload alerts.'},
    })

end

return console