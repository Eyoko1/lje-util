local timer = {}
local CurTime = rawget(_G, "CurTime")
local LastCurTime = CurTime()

-- print(tostring(CurTime) .. "timer") -> Forgot to comment this out oops

local function RandomString()
    local s = "______"
    for i = 1, 16 do
        s = s .. string.char(math.random(97, 122))
    end
    return s
end

local Timers = { -- This is kind of unoptimized
    --[[[IDENTIFIER] = {
        repetitions = nil,
        func = func,
        duration = 12,
        timeLeft = 8.69

        -- INTERNAL --

        paused = false,
        start = CurTime(), # do basic CurTime() - lastTime calculation
        reps = 0, # should exist if this timer has reps
    }]]
}

-- Library --

function timer.Create(identifier, delay, repetitions, func)
    local new = {}
    new.start = CurTime()
    new.duration = delay
    new.timeLeft = delay
    new.func = func or function() end
    new.paused = false
    if repetitions then
        new.repetitions = repetitions
        new.reps = 0
    end

    Timers[identifier] = new
end

function timer.Simple(delay, func)
    local identifier = RandomString()
    timer.Create(identifier, delay, nil, func)
end

function timer.Start(identifier)
    if Timers[identifier] then
        Timers[identifier].timeLeft = Timers[identifier].timeLeft
        Timers[identifier].paused = false
    end
end

function timer.Pause(identifier)
    if Timers[identifier] then
        Timers[identifier].paused = true
    end
end

function timer.UnPause(identifier)
    if Timers[identifier] then
        Timers[identifier].paused = false
    end
end

function timer.Stop(identifier)
    if Timers[identifier] then
        Timers[identifier].timeLeft = Timers[identifier].timeLeft
        Timers[identifier].paused = true
    end
end

function timer.Toggle(identifier)
    local n = Timers[identifier]

    if n then
        n.paused = not n.paused
    end
end

function timer.TimeLeft(identifier)
    local n = Timers[identifier]

    if n then
        if n.paused then
            return -1
        end
        return n.timeLeft
    end
end

function timer.getTimers()
    return CopyTable(Timers)
end

function timer.RepsLeft(identifier)
    local n = Timers[identifier]
    if n and n.repetitions then return n.repetitions - n.reps end
end

function timer.Exists(identifier)
    return Timers[identifier] and true or false
end

function timer.Adjust(identifier, delay, repetitions, func)
    timer.Remove(identifier)
    timer.Create(identifier, delay, repetitions, func)
end

function timer.Remove(identifier)
    if Timers[identifier] then
        Timers[identifier] = nil
    end
end

-- Hook --

hook.pre("think", RandomString() .. "_timer", function()
    local dt = CurTime() - LastCurTime -- deltatime

    if dt < 0 then
        return
    end

    LastCurTime = CurTime()

    if next(Timers) then
        for Identifier, Info in pairs(Timers) do
            if Info.paused then continue end
            local timeLeft = Info.timeLeft - dt
            if timeLeft <= 0 then
                if Info.repetitions and Info.repetitions - Info.reps > 0 then
                    Info.reps = Info.reps + 1
                    Info.timeLeft = Info.duration
                    Info.func()
                    continue
                end

                Info.func()
                Timers[Identifier] = nil
                continue
            end

            Info.timeLeft = timeLeft
        end
    end
end)


lje.env.get().timer = timer
