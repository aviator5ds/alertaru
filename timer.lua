--[[
* Ashita - Copyright (c) 2014 - 2017 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

ashita          = ashita or { };
ashita.timer    = ashita.timer or { };

-- Timer Status Definition
local TIMER_PAUSED  = 0;
local TIMER_STOPPED = 1;
local TIMER_RUNNING = 2;

-- Timer Table Definitions
ashita.timer.timers        = { };
ashita.timer.timersonce    = { };

----------------------------------------------------------------------------------------------------
-- func: create_timer
-- desc: Creates a timer object inside of the timer table.
----------------------------------------------------------------------------------------------------
local function create_timer(name)
    if (ashita.timer.timers[name] == nil) then
        ashita.timer.timers[name] = { };
        ashita.timer.timers[name].Status = TIMER_STOPPED;
        return true;
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: remove_timer
-- desc: Removes a timer from the timer table.
----------------------------------------------------------------------------------------------------
local function remove_timer(name)
    ashita.timer.timers[name] = nil;
end

----------------------------------------------------------------------------------------------------
-- func: is_timer
-- desc: Determines if the given name is a valid timer.
----------------------------------------------------------------------------------------------------
local function is_timer(name)
    return ashita.timer.timers[name] ~= nil;
end

----------------------------------------------------------------------------------------------------
-- func: once
-- desc: Creates a one-time timer that fires after the given delay.
----------------------------------------------------------------------------------------------------
local function once(delay, func, ...)
    local t = { };
    t.Finish = os.time() + delay;
    if (func) then
        t.Function = func;
    end
    t.Args = {...};

    table.insert(ashita.timer.timersonce, t);
    return true;
end

----------------------------------------------------------------------------------------------------
-- func: create
-- desc: Creates a timer.
----------------------------------------------------------------------------------------------------
local function create(name, delay, reps, func, ...)
    if (ashita.timer.is_timer(name)) then
        ashita.timer.remove_timer(name);
    end

    ashita.timer.adjust_timer(name, delay, reps, func, unpack({...}));
    ashita.timer.start_timer(name);
end

----------------------------------------------------------------------------------------------------
-- func: start_timer
-- desc: Starts a timer by its name.
----------------------------------------------------------------------------------------------------
local function start_timer(name)
    if (ashita.timer.is_timer(name)) then
        ashita.timer.timers[name].n        = 0;
        ashita.timer.timers[name].Status   = TIMER_RUNNING;
        ashita.timer.timers[name].Last     = os.time();
        return true;
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: adjust_timer
-- desc: Updates a timer objects properties.
----------------------------------------------------------------------------------------------------
local function adjust_timer(name, delay, reps, func, ...)
    ashita.timer.create_timer(name);

    ashita.timer.timers[name].Delay    = delay;
    ashita.timer.timers[name].Reps     = reps;
    ashita.timer.timers[name].Args     = {...};

    if (func ~= nil) then
        ashita.timer.timers[name].Function = func;
    end

    return true;
end

----------------------------------------------------------------------------------------------------
-- func: pause
-- desc: Pauses a timer.
----------------------------------------------------------------------------------------------------
local function pause(name)
    if (ashita.timer.is_timer(name)) then
        if (ashita.timer.timers[name].Status == TIMER_RUNNING) then
            ashita.timer.timers[name].Diff     = os.time() - ashita.timer.timers[name].Last;
            ashita.timer.timers[name].Status   = TIMER_PAUSED;
            return true;
        end
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: unpause
-- desc: Unpauses a timer.
----------------------------------------------------------------------------------------------------
local function unpause(name)
    if (ashita.timer.is_timer(name)) then
        if (ashita.timer.timers[name].Status == TIMER_RUNNING) then
            ashita.timer.timers[name].Diff     = nil;
            ashita.timer.timers[name].Status   = TIMER_RUNNING;
            return true;
        end
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: toggle
-- desc: Toggles a timers paused state.
----------------------------------------------------------------------------------------------------
local function toggle(name)
    if (ashita.timer.is_timer(name)) then
        if (ashita.timer.timers[name].Status == TIMER_PAUSED) then
            return ashita.timer.unpause(name);
        elseif (ashita.timer.timers[name].Status == TIMER_RUNNING) then
            return ashita.timer.pause(name);
        end
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: stop
-- desc: Stops a timer.
----------------------------------------------------------------------------------------------------
local function stop(name)
    if (ashita.timer.is_timer(name)) then
        ashita.timer.timers[name].Status = TIMER_STOPPED;
        return true;
    end
    return false;
end

----------------------------------------------------------------------------------------------------
-- func: pulse
-- desc: Pulses the timer tables to allow timers to run.
----------------------------------------------------------------------------------------------------
local function pulse(name)
    -- Handle the normal timers..
    for k, v in pairs(ashita.timer.timers) do
        if (v.Status == TIMER_PAUSED) then
            v.Last = os.time() - v.Diff;
        elseif (v.Status == TIMER_RUNNING and (v.Last + v.Delay) <= os.time()) then
            v.Last = os.time();
            v.n = v.n + 1;

            -- Call the timer function..
            local a, b, c, d, e, f = pcall(v.Function, unpack(v.Args));
            if (a == nil or a == false) then
                print(_addon.name .. ' - timer.lua pcall error: ' .. tostring(b));
            end

            -- Stop the timer after its reps were met..
            if (v.n >= v.Reps and v.Reps > 0) then
                ashita.timer.stop(k);
            end
        end
    end

    -- Handle the once timers..
    for k, v in pairs(ashita.timer.timersonce) do
        if (v.Finish <= os.time()) then
            local a, b, c, d, e, f = pcall(v.Function, unpack(v.Args));
            if (a == nil or a == false) then
                print(_addon.name .. ' - timer.lua pcall error: ' .. tostring(b));
            end

            -- Remove the timer..
            ashita.timer.timersonce[k] = nil;
        end
    end
end
ashita.register_event('timerpulse', pulse);

----------------------------------------------------------------------------------------------------
-- Expose The Functions
----------------------------------------------------------------------------------------------------
ashita.timer.create_timer = create_timer;
ashita.timer.remove_timer = remove_timer;
ashita.timer.is_timer = is_timer;
ashita.timer.once = once;
ashita.timer.create = create;
ashita.timer.start_timer = start_timer;
ashita.timer.adjust_timer = adjust_timer;
ashita.timer.pause = pause;
ashita.timer.unpause = unpause;
ashita.timer.toggle = toggle;
ashita.timer.stop = stop;
ashita.timer.pulse = pulse;