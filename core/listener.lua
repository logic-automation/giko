local timer    = require('lib.ashita.timer')
local config   = require('lib.giko.config')
local cache    = require('lib.giko.cache')
local common   = require('lib.giko.common')
local death    = require('lib.giko.death')
local monster  = require('lib.giko.monster')
local chat     = require('lib.giko.chat')
local listener = { channel = {}, reply = {} }

local channel   = {tell = tonumber(0xC), linkshell_out = tonumber(0xE), linkshell_in = tonumber(0x6)}
local userlist  = string.format('%s\\..\\giko-cache\\cache\\giko.userlist.csv', _addon.path)
local whitelist = string.format('%s\\..\\giko-cache\\cache\\giko.whitelist.csv', _addon.path)

listener.listen = function(mode, input, m_mode, m_message, blocked)

    local channels = 
    {
        [channel['tell']]          = listener.channel.tell,
        [channel['linkshell_out']] = listener.channel.linkshell,
        [channel['linkshell_in']]  = listener.channel.linkshell
    }

    if channels[mode] then
        channels[mode](input)
    end

    return false
    
end

listener.channel.linkshell = function(input)

    local replies = {'sync', 'enable', 'disable', 'get-tod', 'set-tod', 'get-day', 'set-day'}
    local username = string.sub(input, string.find(input, '%a+'))
    local tell = {}
    local linkshell = {}

    if not common.in_array_key(cache.get_all(whitelist), username) then
        cache.set(whitelist, username, os.date('%Y-%m-%d %H:%M:%S', time))
    end

    if string.find(input, '@giko') then

        input = string.gsub(input, '.*> ', '')
        input = string.gsub(input, '@giko', '')

        for k,v in pairs(replies) do
            if string.find(input, string.format('%%s%s[%%s\n]*', (string.gsub(v, '-', '%%-')))) then
                tell, linkshell = listener.reply[v](username, string.gsub(string.gsub(input, string.gsub(v, '-', '%%-'), ''), '^%s*(.-)%s*$', '%1'))
            end
        end

        for k,v in pairs(tell) do
            chat.tell(username, v)
        end

        for k,v in pairs(linkshell) do
            chat.linkshell(v)
        end
        
    end

end

listener.channel.tell = function(input)

    local replies = {'sync', 'enable', 'disable', 'get-tod', 'set-tod', 'get-day', 'set-day'}
    local username = string.sub(input, string.find(input, '%a+'))
    local tell = {}
    local linkshell = {}

    if string.find(input, '@giko') and (common.in_array(config.whitelist, username) or common.in_array_key(cache.get_all(whitelist), username)) then

        input = string.gsub(input, '.*>> ', '')
        input = string.gsub(input, '@giko', '')

        for k,v in pairs(replies) do
            if string.find(input, string.format('%%s%s[%%s\n]*', (string.gsub(v, '-', '%%-')))) then
                tell, linkshell = listener.reply[v](username, string.gsub(string.gsub(input, string.gsub(v, '-', '%%-'), ''), '^%s*(.-)%s*$', '%1'))
            end
        end

        for k,v in pairs(tell) do
            chat.tell(username, v)
        end

        for k,v in pairs(linkshell) do
            chat.linkshell(v)
        end

    end    

end
   
listener.reply['sync'] = function(username, input)
     	 
    local tell = {}
    local sets = {}
    local tods = {}

    local l = 0
    local t = {}

    if not common.in_array_key(cache.get_all(userlist), username) then
        cache.set(userlist, username, os.date('%Y-%m-%d %H:%M:%S', os.time()))
    end

    for n,set in ipairs(config.sets) do   

        local v_tod = ''

        for key,mob in ipairs(monster.notorious) do  
            for n,name in ipairs(mob.sets) do   
                if string.gsub(string.lower(name), '%s', '-') == string.lower(set) then

                    local tod  = death.get_tod(mob.names.nq[1])
                    local time = tod ~= nil and common.int_to_hex(common.gmt_to_local_time(tod.gmt)) or common.int_to_hex(0)
                    local day  = tod ~= nil and common.int_to_hex(tod.day, 1) or common.int_to_hex(0, 1)

                    v_tod = v_tod .. (mob.names.hq and day or '') .. time

                end
            end
        end

        table.insert(tods, string.format('[%s][%s]', set, v_tod))

    end
    
    for n, tod in ipairs(tods) do

        l = l + string.len(tod)

        if l <= 125 then
            table.insert(t, tod)
        else
            table.insert(tell, string.format('[ToD]%s', table.concat(t, '')))            
            t = {tod} l = 0            
        end

    end
        
    table.insert(tell, string.format('[ToD]%s', table.concat(t, '')))

    return tell, {}

end

listener.reply['get-tod'] = function(username, input)
   
    local tell   = {}
    local tokens = common.split(input, ' ')

    for n, token in pairs(tokens) do
                 
        local mob = monster.get(token)
        local set = { name='', time=''}

        if mob ~= nil then 
            
            local tod = death.get_tod(token)

            if tod ~= nil then
                table.insert(tell, string.format("[ToD][%s][%s][%s]", mob.names.nq[1], common.gmt_to_local_date(tod.gmt), tod.day)) 
            else                   
                table.insert(tell, string.format('[ToD][%s][%s][%s]', mob.names.nq[1], 'ToD Unknown', '-'))
            end
        end
        
    end

    return tell, {}

end

listener.reply['set-tod'] = function(username, input)
   
    local tell = {}
    local linkshell = {}
    local Y, m, d, H, M, S, z, D = string.match(input, '(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)%s([%-%+]%d%d%d%d)')
    local D                      = string.match(input, '%d%d%d%d%-%d%d%-%d%d%s%d%d:%d%d:%d%d%s[%-%+]%d%d%d%d%s(%d+)')
            
    local time, loc_date, gmt_date

    if string.find(input, 'now') then

        time     = os.time()
        loc_date = os.date('%Y-%m-%d %H:%M:%S %z', time)
        gmt_date = os.date('%Y-%m-%d %H:%M:%S', time - common.offset_to_seconds(os.date('%z', time)))

    elseif Y and m and d and H and M and S and z ~= nil then

        time     = os.time({year=Y, month=m, day=d, hour=H, min=M, sec=S})
        loc_date = os.date('%Y-%m-%d %H:%M:%S %z', time - common.offset_to_seconds(z) + common.offset_to_seconds(os.date('%z', os.time())))
        gmt_date = os.date('%Y-%m-%d %H:%M:%S', time - common.offset_to_seconds(z))   
        
    end

    if time ~= nil and loc_date ~= nil and gmt_date ~= nil then

        for n, token in pairs(common.split(input, ' ')) do     
            
            local win = death.get_window(token)

            if win == nil or win.count > 1 or string.find(input, '%-%-force') then
                for key,mob in ipairs(monster.notorious) do
                    for n,name in ipairs(common.flatten(mob.names)) do  
                        if string.gsub(string.lower(name), '%s', '-') == string.lower(token) then						
							if death.set_tod(name, gmt_date, D) then
                                if config.monsters[string.lower(mob.names.nq[1])] and config.monsters[string.lower(mob.names.nq[1])].enabled then
                                    table.insert(linkshell, string.format('[ToD][%s][%s]%s', common.in_array(mob.names.nq, name) and mob.names.nq[1] or mob.names.hq[1], loc_date, death.get_tod(name).day and string.format('[%s]', common.in_array(mob.names.nq, name) and death.get_tod(name).day or 0) or ''))
                                    screamer.reload()
                                else                                    
                                    for user,t in pairs(cache.get_all(userlist)) do                                        
                                        chat.tell(user, string.format('[ToD][%s][%s]%s', common.in_array(mob.names.nq, name) and mob.names.nq[1] or mob.names.hq[1], loc_date, death.get_tod(name).day and string.format('[%s]', common.in_array(mob.names.nq, name) and death.get_tod(name).day or 0) or ''))
                                    end
                                end                  
                            end
                        end
                    end
                end
            else
                if math.abs(time - common.gmt_to_local_time(death.get_tod(token).gmt)) > 2 then
                    table.insert(tell, string.format('Unable to save ToD, incompatible with previous ToD of [%s]. Use --force to overwrite.', common.gmt_to_local_date(death.get_tod(token).gmt)))
                end
            end

        end
        
    else
        table.insert(tell, string.format('Unable to find a valid timestamp. (now or YYYY-MM-DD HH:MM:SS -0000)'))
    end

    return tell, linkshell

end

listener.reply['get-day'] = function(username, input)
   
    local tell   = {}
    local tokens = common.split(input, ' ')

    for n, token in pairs(tokens) do
        for key,mob in ipairs(monster.notorious) do
            for n,name in ipairs(common.flatten(mob.names)) do    
                if string.gsub(string.lower(name), '%s', '-') == string.lower(token) then
                        
                    local win = death.get_window(mob.names.nq[1])

                    if win ~= nil then 
                        table.insert(tell, string.format("[Day][%s][%s]", win.name, win.day or 'No HQ')) 
                    else                    
                        table.insert(tell, string.format('[Day][%s][%s]', mob.names.nq[1], 'ToD unknown')) 
                    end

                end
            end
        end
    end

    return tell, {}

end

listener.reply['set-day'] = function(username, input)
   
    local tell      = {}
    local linkshell = {}
    local tokens    = common.split(input, ' ')
    local day       = string.match(input, '(%d+)')

    if day ~= nil then
        for n, token in pairs(tokens) do                 
            for key,mob in ipairs(monster.notorious) do
                for n,name in ipairs(common.flatten(mob.names)) do  
                    if string.gsub(string.lower(name), '%s', '-') == string.lower(token) then
                        if death.set_day(name, math.max(day - 1, 0)) then
                            table.insert(linkshell, string.format('[Day][%s][%s]', mob.names.nq[1], day))
                            screamer.reload()                    
                        end
                    end
                end
            end
        end
    end

    return tell, linkshell

end

listener.reply['enable'] = function(username, input)
   
    local linkshell = {}
    local tokens    = common.split(input, ' ')

    for n, token in pairs(tokens) do
        for key,mob in ipairs(monster.notorious) do
            for n,name in ipairs(common.flatten(mob.names)) do    
                if common.in_array_key(config.monsters, string.lower(mob.names.nq[1])) and string.gsub(string.lower(name), '%s', '-') == string.lower(token) then
                        
                   config.monsters[string.lower(mob.names.nq[1])].enabled = true
                   config.save()     
                    
                   table.insert(linkshell, string.format('[Alerts][%s][Enabled]', mob.names.nq[1]))

                   screamer.reload()         

                end
            end
        end
    end

    return {}, linkshell

end

listener.reply['disable'] = function(username, input)
   
    local linkshell = {}
    local tokens    = common.split(input, ' ')

    for n, token in pairs(tokens) do
        for key,mob in ipairs(monster.notorious) do
            for n,name in ipairs(common.flatten(mob.names)) do    
                if common.in_array_key(config.monsters, string.lower(mob.names.nq[1])) and string.gsub(string.lower(name), '%s', '-') == string.lower(token) then
                        
                   config.monsters[string.lower(mob.names.nq[1])].enabled = false
                   config.save()     
                    
                   table.insert(linkshell, string.format('[Alerts][%s][Disabled]', mob.names.nq[1]))
                   
                   screamer.reload()  

                end
            end
        end
    end

    return {}, linkshell

end

return listener
