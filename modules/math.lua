--> [math.lua] <--
--> Re-implements math.* functions <--

local math_floor = math.floor
local math_random = math.random
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_sqrt = math.sqrt

--- @param number number
--- @param idp integer?
--- @return number
function math.Round(number, idp)
    local mult = 10 ^ (idp or 0)
    return math_floor(number * mult + 0.5) / mult
end

--- @param number number
--- @param low number
--- @param high number
--- @return number
function math.Clamp(number, low, high)
    return math_min(math_max(number, low), high)
end

--- @param low number
--- @param high number
--- @return number
function math.Rand(low, high)
    return low + (high - low) * math_random()
end

--- @param a number
--- @param b number
--- @param tolerance number?
--- @return boolean
function math.IsNearlyEqual(a, b, tolerance)
    return math_abs(a - b) <= (tolerance or 1e-8)
end

--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @return number
function math.DistanceSqr(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2) + ((y2 - y1) ^ 2)
end

--- @param x1 number
--- @param y1 number
--- @param x2 number
--- @param y2 number
--- @return number
function math.Distance(x1, y1, x2, y2)
    return math_sqrt(((x2 - x1) ^ 2) + ((y2 - y1) ^ 2))
end
math.Dist = math.Distance

--- @param delta number
--- @param a number
--- @param b number
--- @return number
function Lerp(delta, a, b)
    return a + ((b - a) * delta)
end

--- @param a number
--- @return number
function math.NormalizeAngle(a)
    return (a + 180) % 360 - 180
end

--- @param a number
--- @param b number
--- @return number
function math.AngleDifference(a, b)
    local diff = ((a - b) + 180) % 360 - 180

    if (diff < 180) then
        return diff
    end

    return diff - 360
end