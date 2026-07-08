--> [table.lua] <--
--> Adds / optimises various table.* functions <--

local select = select
local pairs = RandomPairs
local setmetatable = setmetatable
local debug_getmetatable = debug.getmetatable
local istable = istable
local next = next
local table_sort = table.sort
local math_random = math.random

--- @param ... any
--- @return table, integer
function table.Pack(...)
    return {...}, select("#", ...)
end

--- @param t table
--- @param base table
--- @return table
function table.Inherit(t, base)
    for k, v in pairs(base) do
        if (t[k] == nil) then
            t[k] = v
        end
    end

    t.BaseClass = base

    return t
end

local table_Copy
--- @param t table
--- @param lookup table?
--- @return table | nil
function table.Copy(t, lookup)
    if (t == nil) then
        return nil
    end

    local copy = {}
    setmetatable(copy, debug_getmetatable(t))
    
    for i, v in pairs(t) do
        if (istable(v)) then
            if (not lookup) then
                lookup = {}
            end

            lookup[t] = copy

            local cache = lookup[v]
            if (cache) then
                copy[i] = cache
            else
                copy[i] = table_Copy(v, lookup)
            end
        else
            copy[i] = v
        end
    end

    return copy
end
table_Copy = table.Copy

--- @param tab table
--- @return nil
function table.Empty(tab)
    for k, v in pairs(tab) do
        tab[k] = nil
    end
end
local table_Empty = table.Empty

--- @param tab table
--- @return boolean
function table.IsEmpty(tab)
    return next(tab) == nil
end

local table_Merge
--- @param dest table
--- @param source table
--- @param override boolean?
--- @return table
function table.Merge(dest, source, override)
    for k, v in pairs(source) do
        if (not override and istable(v)) then
            local destk = dest[k]
            if (istable(destk)) then
                table_Merge(destk, v)
            else
                dest[k] = v
            end
        end
    end

    return dest
end
table_Merge = table.Merge

--- @param from table
--- @param to table
--- @return nil
function table.CopyFromTo(from, to)
    table_Empty(to)
    table_Merge(to, from)
end

--- @param t table
--- @param val any
--- @return boolean
function table.HasValue(t, val)
    for k, v in pairs(t) do
        if (v == val) then
            return true
        end
    end

    return false
end

--- @param dest table
--- @param source table
--- @return table
function table.Add(dest, source)
    if (dest == source) then
        return dest
    end

    if (not istable(source)) then
        return dest
    end

    if (not istable(dest)) then
        dest = {}
    end

    for k, v in pairs(source) do
        table.insert(dest, v)
    end

    return dest
end

--- @param a number
--- @param b number
--- @return boolean
local function sortdeschelper(a, b)
    return a > b
end

--- @param t table
--- @return nil
function table.SortDesc(t)
    return table_sort(t, sortdeschelper)
end

--- @param t table
--- @param desc boolean?
--- @return table
function table.SortByKey(t, desc)
    local temp = {}

    for key, _ in pairs(t) do
        table.insert(temp, key)
    end

    if (desc) then
        table_sort(temp, function(a, b) return t[a] < t[b] end)
    else
        table_sort(temp, function(a, b) return t[a] > t[b] end)
    end

    return temp
end

--- @param t table
--- @return integer
function table.Count(t)
    local i = 0
    for k, v in pairs(t) do
        i = i + 1
    end
    return i
end
local table_Count = table.Count

--- @param t table
--- @return any, any
function table.Random(t)
    local rk = math_random(1, table_Count(t))
    local i = 1
    for k, v in pairs(t) do
        if (i == rk) then
            return v, k
        end
        i = i + 1
    end
end

--- @param t table
--- @return nil
function table.Shuffle(t)
    local n = #t
    for i = 1, n - 1 do
        local j = math_random(i, n)
        t[i], t[j] = t[j], t[i]
    end
end

function table.IsSequential(t)
    local i = 1
    for k, v in pairs(t) do
        if (t[i] == nil) then
            return false
        end
        i = i + 1
    end
    return true
end