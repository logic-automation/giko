local timer    = require('lib.ashita.timer')
local config   = require('lib.giko.config')
local common   = require('lib.giko.common')
local death    = require('lib.giko.death')
local monster  = require('lib.giko.monster')
local chat     = require('lib.giko.chat')
local screamer = {}

local get_scream_dynamis = function(a)

    if a == '0s' then return string.format('~= Dynamis is starting now! =~') end
    if string.find(a, '^%d') then return string.format('~= Dynamis is starting in %s =~', a) end

end

local get_scream_monster = function(mob, n, a, i)
                  
    if i == #config.monsters[string.lower(mob.names.nq[1])].alerts - 1 then return string.format('~= %s window is open! =~', mob.names.nq[1]) end
    if i == #config.monsters[string.lower(mob.names.nq[1])].alerts then return string.format('~= %s window is closed =~', mob.names.nq[1]) end
    if string.find(a, '^%d') and n ~= #mob.windows then return string.format('~= W%s - %s in %s =~', n, mob.names.nq[1], a) end
    if string.find(a, '^%d') and n == #mob.windows then return string.format('~= %s force pop in %s =~', mob.names.nq[1], a) end

end

screamer.load = function()

    screamer.dynamis()
    screamer.monsters()

end

screamer.dynamis = function()

    local time = os.time()
    local dst  = os.date('*t').isdst
    local grc  = 5
    local y, m, d, h, m, s, a, d_time, d_set

    while true do

        for k, conf in ipairs(config.dynamis.schedule) do

            y, m, d, a, A = string.match(os.date('%Y-%m-%d %a %A', time), '(%d%d%d%d)%-(%d%d)%-(%d%d)%s(%w+)%s(%w+)') 
            
            if string.lower(A) == string.lower(conf.day) then
                
                d_time = os.time({year = y, month = m, day = d, hour = string.gsub(conf.gmt, '%:.*', ''), min = string.gsub(conf.gmt, '.*%:', ''), sec = 0}) + common.offset_to_seconds(os.date('%z', os.time()))

                for i,alert in ipairs(config.dynamis.alerts) do

                    if os.difftime(d_time - common.to_seconds(alert), os.time()) > 0 then

                        if config.dynamis.enabled then
                            ashita.timer.create(string.format('dynamis-%s-%s-%s-%s', m, d, k, i), os.difftime(d_time - common.to_seconds(alert) - grc, os.time()), 1, function() chat.linkshell(get_scream_dynamis(alert), os.time() + grc) if i == #config.dynamis.alerts then screamer.dynamis() end end)
                        else
                            ashita.timer.remove_timer(string.format('dynamis-%s-%s-%s-%s', m, d, k, i))
                        end
                        
                        d_set = true   
                    end

                end

            end

            if (d_set ~= nil) then
                return
            end

        end

        time = time + 86400

    end

end

screamer.monsters = function()

    for key, conf in pairs(config.monsters) do

        local tod = death.get_tod(key)
        local mob = monster.get(key)
        local grc = 5
    
        if tod ~= nil and mob ~= nil then
        
            local time = common.gmt_to_local_time(tod.gmt)
            
            for n,w in pairs(mob.windows) do

                time = time + common.to_seconds(w)

                for i,a in ipairs(conf.alerts) do

                    if conf.enabled and common.to_seconds(a) < common.to_seconds(w) and os.difftime(time - common.to_seconds(a), os.time()) > 0 then
                        ashita.timer.create(string.format('%s-%s-%s', mob.names.nq[1], n, i), os.difftime(time - common.to_seconds(a) - config.offset - grc, os.time()), 1, function() chat.linkshell(get_scream_monster(mob, n, a, i), os.time() + grc) end)
                    else
                        ashita.timer.remove_timer(string.format('%s-%s-%s', mob.names.nq[1], n, i)) 
                    end

                end
            end
        end

    end

end

screamer.reload = function()
    screamer.load()    
end

return screamer
