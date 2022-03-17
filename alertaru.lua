----------------------------------------------------------
--                Alertaru by Aviator5ds                --
_addon.author = 'Aviator5ds';
_addon.name = 'Alertaru';
_addon.version = '1.2.1';
----------------------------------------------------------
-- importing modules for file to work
local _data = require 'data'
local _t = require '_timers'
local _common = require '_common'
local _config = require '_config'
local timers = require 'timer'
local whitelist = {
    'Name1','Name2','Name3'
}
----------------------------------------------------------
local requestList = function (username)
    local Mobs = _data.reRead()
    
    for i, Mob in ipairs(Mobs) do
        local sendText = "Mob: "..Mob.mob_name..", ToD: "..Mob.time_of_death ..", Enabled: "..Mob.enabled..", Alerts: "..Mob.alert1..","..Mob.alert2..","..Mob.alert3..","..Mob.alert4..","..Mob.alert5..","..Mob.alert6 
        ashita.timer.create(  2* i, 2*i, 1,
                        function()
                            AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '.. sendText   , 1);
                        end)        
    end
end
local helpCommand = function ()
    local messages = 
    {   'alertaru tod mobname, this function saves the current EST time as ToD for the mob',
        'alertaru enable mobname, enables the mob alerts',
        'alertaru disable mobname, disables the mob alerts',
        'alertaru requestmob, returns the time until next window',
		'alertaru request list (/tell only), returns the full ToD dataset',
        'alertaru help, how did you get here??'}
    
    for i, helpMessage in ipairs(messages) do
        ashita.timer.create(  2 * i, 2*i, 1,
                        function()
                            AshitaCore:GetChatManager():QueueCommand('/l ~~ '.. helpMessage.. " "  , 1);
                        end)        
    end
end
----------------------------------------------------------
ashita.register_event('load', function()
    local Mobs = _data.reRead()
	AshitaCore:GetChatManager():QueueCommand('/addon unload chatmon' , 1);
    -- Iterates through the mobs to start their timers when initialized
    for index, Mob in ipairs(Mobs) do
        
        local SpawnMax = _data.parse_seconds(Mob.spawn_max) 
        local SpawnMin = _data.parse_seconds(Mob.spawn_min)
        local Interval = _data.parse_seconds(Mob.spawn_interval)
        
        local inDiff = SpawnMax - SpawnMin
        local canInterval = (inDiff/Interval) + 1
        -- Get alerts
        local alerts = {Mob.alert1,Mob.alert2,Mob.alert3,Mob.alert4,Mob.alert5,Mob.alert6}
        -- Iterates through each posible window of the mob
        -- checking if mob alerts should be on or off
        local delay = _data.getTimes(Mob.mob_name)
        if Mob.enabled == "true" then    
            -- crate the timer table, of the mob
            _t.create_timer(delay, Mob.mob_name)
            -- caninterval = 24

            if delay > 0 then
                -- Declare the fixed amount of time
                local fixedTime = 30*60
                local fixedAlert = delay - fixedTime
                if fixedAlert > 0 then
                ashita.timer.create(  fixedAlert, fixedAlert, 1,
                    function()
                        AshitaCore:GetChatManager():QueueCommand('/l ~~ RED ALERTARU ~~ '.. Mob.mob_name .. ' W1 in 30 min  ~~'   , 1);
                    end)
                end
            end
            for i=1,canInterval do
                       
                for indAlert= 1,6  do
                    if alerts[indAlert] ~= "x" then
                    -- x in alerts means empty or null alert
                        if alerts[indAlert] == "close" then
							Alert = -10;
						else
							Alert = _data.parse_seconds(alerts[indAlert])
						end
                        
                        delay = _data.getTimes(Mob.mob_name) + (Interval * (i - 1))
                        local lastWindow = false
                        if (Interval * (i - 1)) == inDiff then
                            lastWindow = true
                        end
                        delay = delay - Alert
                        -- creating the timer
                        if delay > 0 then
                            if i ~= canInterval then                                                    
                                ashita.timer.create(  delay, delay, 1,
                                function()
                                    if ((lastWindow == true) and (alerts[indAlert] ~= "close")) then 
                                        AshitaCore:GetChatManager():QueueCommand('/l ~~ '.. Mob.mob_name .. ' Force Pop in: ' .. alerts[indAlert] .. ' ~~'   , 1);
                                    elseif alerts[indAlert] == "close" then
										AshitaCore:GetChatManager():QueueCommand('/l ~~ W'.. i .. ' '.. Mob.mob_name .. ' END ~~'   , 1);
									else
                                        AshitaCore:GetChatManager():QueueCommand('/l ~~ W'.. i .. ' '.. Mob.mob_name .. ' is starting in: '  .. alerts[indAlert] .. ' ~~' , 1);
                                    end
                                end)
                            else
                                ashita.timer.create(  delay, delay, 1,
                                function()
                                    if lastWindow == true then 
                                        AshitaCore:GetChatManager():QueueCommand('/l ~~ '.. Mob.mob_name .. ' Force Pop in: ' .. alerts[indAlert] .. ' ~~'   , 1);
                                    else
                                        AshitaCore:GetChatManager():QueueCommand('/l ~~ W'.. i .. ' '.. Mob.mob_name .. ' FORCE POP in: '  .. alerts[indAlert] .. ' ~~' , 1);
                                    end
                                end)
                            end
                        end
                    
                    end
                end
            end
        end
    end
end)
ashita.register_event('incoming_text', function(mode, input, modifiedmode, modifiedmessage, blocked)
    -- catches the message and analyzes it, to determine what to do
    local message = _data.Split(string.lower( input ), " ")
    local getUsername = _data.Split( input , " ")
    -- name >> : @alertaru help
    local Mobs = _data.reRead()
    local chatmode = nil
    local username = (string.gsub(getUsername[1], "^%s*(.-)%s*$", "%1"))
    -- just accepting if the message is on linkshell
    if mode == 14 then
        chatmode = true
    elseif mode == 12 then
        chatmode = true
    end
    if chatmode ~= nil then
        -- getting a clean username
        username = string.gsub( username,' ','' )
        username = string.match( username,'%a+')
        for word= 1,#message do
            -- looking for the KEYWORD
            if message[word] == "@alertaru" then
                for i=1,#message do
                    -- looking for the KEYFUNCTION
                    if message [i] == "tod" then
                        --Get mob's name
                        local istrue = false
                        for admited = 1,#whitelist do
                            if username == whitelist[admited] or mode == 14 then 
                            istrue = true
                            end
                        end   
                        if istrue then
                                local target = message[i+1]
                                -- breakes if blank name is passed 
                                target = (string.gsub(target, "^%s*(.-)%s*$", "%1"))
                                --Get mob's index in Mobs table
                                local index = _data.findIndex(target)
                                -- checking its existance 
                                if  index ~= nil then
                                    local timeofdeath
                                    if message[i+2] ~= nil then
                                        -- format for the specific ToD 10-06-2021 19:43:56
										local date = (string.gsub(message[i+2], "^%s*(.-)%s*$", "%1")) 
										local hour = (string.gsub(message[i+3], "^%s*(.-)%s*$", "%1"))
                                        timeofdeath = date.. ' ' .. hour.. ' EST'
                                    else
                                        -- Getting the ToD and saving it to the file 
                                        timeofdeath = _data.format_time(os.time(), "!%m:%d:%Y:%H:%M:%S %z", "-05:00", "EST")
                                    end
                                    
                                        
                                    _data.updateFile(target, timeofdeath, "tod")
                                    local msgBack =  'The ToD of ' .. target .. ' now is ' .. timeofdeath
                                    msgBack = tostring(msgBack)
                                    
                                    if mode == 14 then
                                        AshitaCore:GetChatManager():QueueCommand('/l @'..username.. ': ' ..msgBack, 1);
                                    elseif mode == 12 then
                                        AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '..  msgBack , 1);
                                    end
                                    -- updating the enabled to true 
                                    if Mobs[index].enabled == "false" then
                                        _data.updateFile(target, "true", "enabled")
                                    end
									AshitaCore:GetChatManager():QueueCommand('/addon reload alertaru', 1);
                                else
                                end                            
                        end
                    elseif message [i] == "enable" then
                        local istrue = false
                        for admited = 1,#whitelist do
                            if username == whitelist[admited] or mode == 14 then 
                            istrue = true
                            end
                        end   
                        if istrue then
                            --Get mob's name
                            local target = message[i+1]
                            target = (string.gsub(target, "^%s*(.-)%s*$", "%1"))
                            
                            -- --Get mob's index in Mobs table
                            local index = _data.findIndex(target)
                            -- checking its existance 
                            
                            if  index ~= nil then
                                _data.updateFile(target, "true", "enabled")
                                AshitaCore:GetChatManager():QueueCommand('/addon reload alertaru', 1);
                                if mode == 14 then
                                    AshitaCore:GetChatManager():QueueCommand('/l @'.. username .. ': ' ..target.. ' enabled successfully!', 1);
                                elseif mode == 12 then
                                    AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '.. target.. ' enabled successfully!' , 1);
                                end
                            else
                                AshitaCore:GetChatManager():QueueCommand('/l '.. username .. ': Missing or Unknown Monster', 1);
                        
                            end
                        end
                        
                    elseif message [i] =="disable" then
                        local istrue = false
                        for admited = 1,#whitelist do
                            if username == whitelist[admited] or mode == 14 then 
                            istrue = true
                            end
                        end           
                        if istrue then            
                        --Get mob's name
                            local target = message[i+1]
                            --Get mob's index in Mobs table
                            target = (string.gsub(target, "^%s*(.-)%s*$", "%1"))
                            
                            local index = _data.findIndex(target)
                            -- checking its existance 
                            
                            if  index ~= nil then
                                _data.updateFile(target, "false", "enabled")
                                AshitaCore:GetChatManager():QueueCommand('/addon reload alertaru', 1);
                                if mode == 14 then
                                    AshitaCore:GetChatManager():QueueCommand('/l @'.. username .. ': ' ..target.. ' disabled successfully!', 1);
                                elseif mode == 12 then
                                    AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '.. target.. ' disabled successfully!' , 1);
                                end
                            else
                                AshitaCore:GetChatManager():QueueCommand('/l @'.. username .. ': , Missing or Unknown Monster', 1);
                        
                            end
                        end
                        
                    elseif message [i] == "request" then
                        
                        
                        --Get requested mob's name
                        local target = message[i+1]
                        
                        target = (string.gsub(target, "^%s*(.-)%s*$", "%1"))
                        
                        --Get mob's index in Mobs table
                        local index = _data.findIndex(target)
                        -- checking its existance 
                        if target == "list" and mode == 12 then -- and mode == 14 then
                            requestList(username)                           
                        else
                            if  index ~= nil then
                                -- Get Time of Death
                                local ToD = Mobs[index].time_of_death
                                -- local currentTime = _data.format_time(os.time(), "!%m:%d:%Y:%H:%M:%S %z", "-05:00", "EST")
                                local rtime = _data.requestTime(target)
                                local text = ''
                                local tellText =''
                                if rtime.state == 'Active' then
                                    text = rtime.days.. 'd '.. rtime.hours.. 'h '.. rtime.minutes.. 'm ' .. rtime.seconds.. 's '
                                    tellText = 'The time to W'..rtime.window..' is '.. text
                                elseif rtime.state == 'Inactive' then
                                    tellText = 'Time of death out of date'
                                end
                                    if mode == 14 then
                                        AshitaCore:GetChatManager():QueueCommand('/l '.. username.. ': '.. tellText.. ' ', 1);
                                    elseif mode == 12 then
                                        AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '.. tellText.. ' ' , 1);
                                end
                            else
                                if mode == 14 then
                                    AshitaCore:GetChatManager():QueueCommand('/l '.. username .. ': , Missing or Unknown Monster', 1);
                                elseif mode == 12 then
                                    local tellText = ', Missing or Unknown Monster'
                                    AshitaCore:GetChatManager():QueueCommand('/tell '..username.. ' '.. tellText.. ' ' , 1);
                                end
                            end
                        end
                    elseif (string.gsub(message [i], "^%s*(.-)%s*$", "%1")) == "help" then
                        helpCommand()
                    end
                
                end
        end
    end
    end
    
            

    return false;
end);