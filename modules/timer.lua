--> [timer.lua] <--
--> Re-implements the timer.* library <--

--- @class Timer
--- @field identifier any
--- @field delay number
--- @field repetitions integer
--- @field callback fun(): nil
--- @field paused boolean
--- @field stoptime number
--- @field pausedelta number

timer = {}

--- @type Timer[]
local timers = {}
local timermap = {}
local timercount = 0

local earlieststop = math.huge

local function createtimernode(identifier, delay, repetitions, callback)
    if (delay < 0) then
        delay = 0
    end
    repetitions = math.ceil(repetitions)

    local stoptime = SysTime() + delay
    local node = {
        identifier = identifier,
        delay = delay,
        repetitions = repetitions,
        callback = callback,
        paused = false,
        stoptime = stoptime,
        pausedelta = 0
    }

    if (stoptime < earlieststop) then
        earlieststop = stoptime
    end

    timermap[identifier] = node
    table.insert(timers, node)
    timercount = timercount + 1
end

local function findtimernode(identifier)
    --[[
    for i = 1, timercount do
        local node = timers[i]
        if (node.identifier == identifier) then
            return node
        end
    end
    ]]
    return timermap[identifier]
end

local function findearliest()
    earlieststop = math.huge
    for i = 1, timercount do
        local node = timers[i]
        local stoptime = node.stoptime
        if (stoptime < earlieststop) then
            earlieststop = stoptime
        end
    end
end

local function removetimernode(identifier)
    for i = 1, timercount do
        local node = timers[i]
        if (node.identifier == identifier) then
            table.remove(timers, i)
            timermap[identifier] = nil
            findearliest()
            return
        end
    end
end

function timer.Adjust(identifier, delay, repetitions, func)
    for i = 1, timercount do
        local node = timers[i]
        if (node.identifier ~= identifier) then
            continue
        end

        node.delay = delay
        node.stoptime = SysTime() + delay
        
        if (repetitions) then
            node.repetitions = repetitions
        end

        if (func) then
            node.callback = func
        end

        return
    end
end

function timer.Check()
    --> No-op
end

timer.Create = createtimernode

timer.Destroy = removetimernode

function timer.Exists(identifier)
    return findtimernode(identifier) ~= nil
end

function timer.IsPaused(identifier)
    local node = findtimernode(identifier)
    if (node) then
        return node.paused
    end
end

function timer.Pause(identifier)
    local node = findtimernode(identifier)
    if (node) then
        node.paused = true
        node.stoptime = math.huge
        node.pausedelta = node.stoptime - SysTime()
        findearliest()
    end
end

timer.Remove = removetimernode

function timer.RepsLeft(identifier)
    local node = findtimernode(identifier)
    if (node) then
        return node.repetitions
    end
end

function timer.Simple(delay, func)
    createtimernode(lje.util.random_string(), delay, 1, func)
end

function timer.Start(identifier)
    local node = findtimernode(identifier)
    if (node and node.paused) then
        node.paused = false
        node.stoptime = SysTime() + node.delay
        findearliest()
    end
end

function timer.Stop(identifier)
    local node = findtimernode(identifier)
    if (node) then
        node.paused = true
        node.stoptime = math.huge
        node.pausedelta = 0
        findearliest()
    end
end

function timer.TimeLeft(identifier)
    local node = findtimernode(identifier)
    if (node) then
        return node.stoptime - SysTime()
    end
end

function timer.Toggle(identifier)
    local node = findtimernode(identifier)
    if (node) then
        if (node.paused) then
            node.paused = false
            node.stoptime = SysTime() + node.pausedelta
            findearliest()
        else
            node.paused = true
            node.stoptime = math.huge
            node.pausedelta = node.stoptime - SysTime()
            findearliest()
        end
    end
end

function timer.UnPause(identifier)
    local node = findtimernode(identifier)
    if (node and node.paused) then
        node.paused = false
        node.stoptime = SysTime() + node.pausedelta
        findearliest()
    end
end

--> https://wiki.facepunch.com/gmod/Lua_Hooks_Order
hook.pre("Tick", "__lje_util_timers", function()
    local time = SysTime()
    if (time < earlieststop) then
        return
    end

    earlieststop = math.huge

    local i = 1
    while (i <= timercount) do
        local node = timers[i]
        local stoptime = node.stoptime
        if (stoptime < time) then
            local repetitions = node.repetitions
            if (repetitions > 1) then
                node.repetitions = repetitions - 1
                if (stoptime < earlieststop) then
                    earlieststop = stoptime
                end
            elseif (repetitions == 1) then
                timermap[node.identifier] = nil
                table.remove(timers, i)
                i = i - 1
                timercount = timercount - 1
            end
            node.stoptime = time + node.delay
            node.callback()
        else
            if (stoptime < earlieststop) then
                earlieststop = stoptime
            end
        end
        i = i + 1
    end
end)