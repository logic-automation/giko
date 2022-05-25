local timer    = require('lib.ashita.timer')
local config   = require('lib.giko.config')
local common   = require('lib.giko.common')
local death    = require('lib.giko.death')
local monster  = require('lib.giko.monster')
local chat     = require('lib.giko.chat')
local screamer = {}

local get_scream_dynamis = function(a)

    if a == '0s' then return string.format('~= %s Dynamis is starting now! =~', mob.names.nq[1]) end
    if string.find(a, '^%d') then return string.format('~= Dynamis is starting in %s =~', a) end

end

local get_scream_monster = function(mob, n, a, i)
                  
    if i == #config.alerts.monsters[string.lower(mob.names.nq[1])] - 1 then return string.format('~= %s window is open! =~', mob.names.nq[1]) end
    if i == #config.alerts.monsters[string.lower(mob.names.nq[1])] then return string.format('~= %s window is closed =~', mob.names.nq[1]) end
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
    local y, m, d, h, m, s, a, d_time, d_set

    while true do

        for k, conf in ipairs(config.dynamis) do

            y, m, d, a, A = string.match(os.date('%Y-%m-%d %a %A', time), '(%d%d%d%d)%-(%d%d)%-(%d%d)%s(%w+)%s(%w+)') 
            
            if string.lower(A) == string.lower(conf.day) then
                
                d_time = os.time({year = y, month = m, day = d, hour = string.gsub(conf.gmt, '%:.*', ''), min = string.gsub(conf.gmt, '.*%:', ''), sec = 0}) + common.offset_to_seconds(os.date('%z', os.time()))

                for i,alert in ipairs(config.alerts.dynamis) do

                    if os.difftime(d_time - common.to_seconds(alert), os.time()) > 0 then
                        
                        chat.linkshell(get_scream_dynamis(alert), d_time - common.to_seconds(alert), os.time())

                        if i == #config.alerts.dynamis then 
                            ashita.timer.create(string.format('scheduler-%s-%s-%s', m, d, k), os.difftime(d_time - common.to_seconds(alert), os.time()), 1, function() screamer.dynamis() end end)
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

    for key, alerts in pairs(config.alerts.monsters) do

        local tod = death.get_tod(key)
        local mob = monster.get(key)
    
        if tod ~= nil and mob ~= nil then
        
            local time = common.gmt_to_local_time(tod.gmt)
            
            for n,w in pairs(mob.windows) do

                time = time + common.to_seconds(w)

                for i,a in ipairs(alerts) do

                    if common.to_seconds(a) < common.to_seconds(w) and os.difftime(time - common.to_seconds(a), os.time()) > 0 then
                        chat.linkshell(get_scream_monster(mob, n, a, i), time - common.to_seconds(a) - config.offset)
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
