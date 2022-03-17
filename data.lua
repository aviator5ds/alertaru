-----------------------------------------------------------
-- Here are most of the functions
-- and the tables to be used in the addon
-----------------------------------------------------------
local _data = { }


-- declaring the path of the data file
_data.fullpath = string.format('%s\\data.csv', _addon.path );
-- main function to get all the parts of a string separed by comma
_data.Split = function(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    -- returns a table
    return result;
end
-- reads the file, picking it up in a table, then changes what it needs and saves again
_data.updateFile = function (name, newData, parameter)
    local newLine = ""
    local file = io.open(_data.fullpath, "r+")

        local fileContent = {}
        for line, i in file:lines() do
            table.insert(fileContent, line)
        end

        if(string.lower(parameter) == "tod") then
            
            for i, lines in ipairs(fileContent) do
                local split_string = _data.Split(lines:match(".*"), ",")
    
                if(split_string[1] == name) then
                    split_string[2] = newData
        
                    for i = 1, #split_string do
                        if(i == #split_string) then
                            newLine = newLine..split_string[i]
                        else
                            newLine = newLine..split_string[i]..","
                        end
                    end
    
                    fileContent[i] = newLine
    
                    file:seek("set")
                    for index, value in ipairs(fileContent) do
                                file:write(value..'\n')
                    end
                    io.close(file)
                end
    
             end

        elseif (string.lower(parameter) == "enabled") then

            for i, lines in ipairs(fileContent) do
                local split_string = _data.Split(lines:match(".*"), ",")
    
                if(split_string[1] == name) then
                    split_string[6] = newData
        
                    for i = 1, #split_string do
                        if(i == #split_string) then
                            newLine = newLine..split_string[i]
                        else
                            newLine = newLine..split_string[i]..","
                        end
                    end
    
                    fileContent[i] = newLine
    
                    file:seek("set")
                    for index, value in ipairs(fileContent) do
                                file:write(value..'\n')
                    end
                    io.close(file)
                end

            end

        end

        

end

_data.read_file = function(algo, path)
                
    local file = io.open(_data.fullpath, "r") -- r read mode and b binary mode
    --if not file then return nil end

    local Mobs = {}
    for line in io.lines(_data.fullpath) do

        if line ~= "" then
            local split_string = _data.Split(line:match(".*"), ",")
            
            local  mob_name,
                time_of_death,
                spawn_min,
                spawn_interval,
                SpawnMax,
                enabled,
                alert1,
                alert2,
                alert3,
                alert4,
                alert5,
                alert6 = split_string[1], split_string[2], split_string[3], split_string[4], split_string[5] , split_string[6], split_string[7], split_string[8], split_string[9], split_string[10], split_string[11],split_string[12]

            
            Mobs[#Mobs+1] = {mob_name = mob_name, time_of_death = time_of_death, spawn_min = spawn_min, spawn_interval = spawn_interval,
            spawn_max = SpawnMax, enabled = enabled, alert1 = alert1, alert2 = alert2, alert3 = alert3, alert4 = alert4, alert5 = alert5, alert6 = alert6}

        
        end
    end
    io.close(file)
    return Mobs
end

_data.reRead = function(  )
        local Mobs = _data:read_file("data.csv")

        return Mobs
end
-- Pass the message input, filter to get the mob name and sending the index of the table d
_data.findIndex= function(name) --fafnir
    local Mobs = _data.reRead()
    local verify = false
    for index, Mob in ipairs(Mobs) do
       
        if string.lower(Mob.mob_name) == string.lower( name ) then 
            verify = true
            return index
        end
        
    end
    if verify == false then
        return nil
    end


end
_data.parse_seconds= function(time)

        if (string.match(time, "h")) then
            local hour = _data.Split(time, "h")

            if(string.match(hour[1], ",")) then
                local hour_float = _data.Split(hour[1], ",")
                hour_float = hour_float[1].."."..hour_float[2]
                hour_float = tonumber(hour_float)
                return hour_float * 3600
            end

            return tonumber(hour[1]) * 3600

        elseif (string.match(time, "m")) then
            local hour = _data.Split(time, "m")

            if(string.match(hour[1], ",")) then
                local hour_float = _data.Split(hour[1], ",")
                hour_float = hour_float[1].."."..hour_float[2]
                hour_float = tonumber(hour_float)
                return hour_float * 60
            end
    

        return hour[1] * 60



    elseif (string.match(time, "s")) then
        local hour = _data.Split(time, "s")
        return hour[1]
--------------------------
    elseif (string.match(time, "d")) then
        local hour = _data.Split(time, "d")

        if(string.match(hour[1], ",")) then
            local hour_float = _data.Split(hour[1], ",")
            hour_float = hour_float[1].."."..hour_float[2]
            hour_float = tonumber(hour_float)
            return hour_float * 86400
        end


    return hour[1] * 60




    else
        return time
    end
end


_data.format_time= function(timestamp, format, tzoffset, tzname)
    if tzoffset == "local" then  -- calculate local time zone (for the server)
       local now = os.time()
       local local_t = os.date("t", now)
       local utc_t = os.date("!t", now)
       local delta = (local_t.hour - utc_t.hour)*60 + (local_t.min - utc_t.min)
       local h, m = math.modf( delta / 60)
       tzoffset = string.format("%+.4d", 100 * h + 60 * m)
    end
    tzoffset = tzoffset or "GMT"
    format = format:gsub("%%z", tzname or tzoffset)
    if tzoffset == "GMT" then
       tzoffset = "+0000"
    end
    tzoffset = tzoffset:gsub(":", "")
 
    local sign = 1
    if tzoffset:sub(1,1) == "-" then
       sign = -1
       tzoffset = tzoffset:sub(2)
    elseif tzoffset:sub(1,1) == "+" then
       tzoffset = tzoffset:sub(2)
    end
    tzoffset = sign * (tonumber(tzoffset:sub(1,2))*60 +
 tonumber(tzoffset:sub(3,4)))*60
    local format = os.date(format, timestamp + tzoffset)
    format = _data.Split(format, ':')
    lastformat = ""
    lastformat = lastformat..format[1]..'-'
    lastformat = lastformat..format[2]..'-'
    lastformat = lastformat..format[3]..' '
    lastformat = lastformat..format[4]..':'
    lastformat = lastformat..format[5]..':'
    lastformat = lastformat..format[6]..''
    return lastformat


    

 end
 --format_time(os.time(), "!%H:%M:%S %z", "-04:00", "EST"  

_data.getTimes = function(name)
    local Mobs = _data.reRead()
    
    for index, Mob in ipairs(Mobs) do
        if string.lower(Mob.mob_name) == string.lower( name ) then 
            local inter = _data.parse_seconds(Mob.spawn_interval)
            -- local inter            
            local ToD = Mob.time_of_death
            local timeToD = _data.Split(ToD, " ")[2]
            local dateToD = _data.Split(ToD, " ")[1]
            local hourToD = _data.Split(timeToD, ":")[1]
            local minToD = _data.Split(timeToD, ":")[2]
            local secToD = _data.Split(timeToD, ":")[3]
            local monthToD = _data.Split(dateToD, "-")[1]
            local dayToD = _data.Split(dateToD, "-")[2]
            local yearToD = _data.Split(dateToD, "-")[3]

            local timeOfDeathSec = os.time({
                year = yearToD,
                month = monthToD,
                day = dayToD,
                hour = hourToD,
                min = minToD,
                sec = secToD
            })

            local SpawnMin = _data.parse_seconds(Mob.spawn_min)
            local currentTime = _data.format_time(os.time(), "!%m:%d:%Y:%H:%M:%S %z", "-05:00", "EST")
                            
            timeOfDeathSec = os.time({
                year = yearToD,
                month = monthToD,
                day = dayToD,
                hour = hourToD,
                min = minToD,
                sec = secToD
            })

            local StartTimer = timeOfDeathSec + SpawnMin

            local timeCt = _data.Split(currentTime, " ")[2]
            local dateCt = _data.Split(currentTime, " ")[1]

            local hourCt = _data.Split(timeCt, ":")[1]
            local minCt = _data.Split(timeCt, ":")[2]
            local secCt = _data.Split(timeCt, ":")[3]

            local monthCt = _data.Split(dateCt, "-")[1]
            local dayCt = _data.Split(dateCt, "-")[2]
            local yearCt = _data.Split(dateCt, "-")[3]

            local currentTimeSec = os.time({

                year = yearCt,
                month = monthCt,
                day = dayCt,
                hour = hourCt,
                min = minCt,
                sec = secCt

            })

            local returnTime = os.difftime(StartTimer,currentTimeSec) -- + (inter*cantIntervals)
            -- print(returnTime)
            return returnTime

        end
    end
end
_data.formatSeconds = function ( seconds )
    if seconds/86400 < 1  then
        if seconds/3600 < 1 then
            if seconds/60 < 1 then
                return seconds/60
            else
                return seconds 
            end
        else
            return seconds/3600 
        end
    else
        return seconds/86400 
    end
end
_data.requestTime = function (name)
    local Mobs = _data.reRead()

    for Index,Mob in ipairs(Mobs) do
        if string.lower(Mob.mob_name) == string.lower( name ) then 
            local SpawnMax = _data.parse_seconds(Mob.spawn_max) 
            local SpawnMin = _data.parse_seconds(Mob.spawn_min)
            local Interval = _data.parse_seconds(Mob.spawn_interval)
            
            local inDiff = SpawnMax - SpawnMin
            local canInterval = (inDiff/Interval) + 1
            local starterTime = _data.getTimes(Mob.mob_name)
            local nextWindow = 1
            if starterTime > 0 then
                nextWindow = 1
            elseif starterTime < 0 then 
                nextWindow = nextWindow + (math.ceil((starterTime/Interval) * (-1)))
            end
            local requestTimer = starterTime + (Interval * (nextWindow - 1))
            if nextWindow <= canInterval then    
                local days = math.floor(requestTimer/86400)
                local hours = math.floor((requestTimer - (days*86400))/3600)
                --                                             1 = 86400, + 11 = 39600
                local minutes = math.floor((requestTimer - ((days*86400)+(hours*3600))) /60)
                local seconds = math.floor((requestTimer -((days*86400)+(hours*3600)+(minutes*60))))
                local requestTable = {
                    days = days,
                    hours = hours,
                    minutes = minutes,
                    seconds = seconds,
                    window = nextWindow,
                    state = 'Active'
                }
                return requestTable
            else
                local days = math.floor(requestTimer/86400)
                local hours = math.floor((requestTimer - (days*86400))/3600)
                --                                             1 = 86400, + 11 = 39600
                local minutes = math.floor((requestTimer - ((days*86400)+(hours*3600))) /60)

                local seconds = math.floor((requestTimer -((days*86400)+(hours*3600)+(minutes*60))))
                local requestTable = {
                    days = days,
                    hours = hours,
                    minutes = minutes,
                    seconds = seconds,
                    window = nextWindow,
                    state = 'Inactive'
                }
                return requestTable
            end
        end
    end

end
_data.startAlarms = function()
    local Mobs = _data.reRead()
    
end

return _data
