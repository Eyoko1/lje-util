--> [string.lua] <--
--> Adds / optimises various string.* functions <--

local string_sub = string.sub
local string_find = string.find
local create_table = lje.util.create_table

local table_concat = table.concat

--- @param str string
--- @return string[]
function string.ToTable(str)
    str = tostring(str)

    local length = #str
    local i = 1
    local tbl = create_table(length, 0)
    ::totable_loop::
    tbl[i] = string_sub(str, i, i)

    if (i ~= length) then
        i = i + 1
        goto totable_loop
    end
    
    return tbl
end

local totable = string.ToTable

--- @param separator string
--- @param str string
--- @param withpattern boolean?
--- @return string[]
function string.Explode(separator, str, withpattern)
	if (separator == "") then return totable(str) end

    local length = #str
    if (length == 0) then
        return {}
    end

    local dopattern = not withpattern
    local ret = {""} --> the table is guaranteed to have at least one element in it - this saves a re-allocation
	local currentpos = 1

    local i = 1
    ::explode::
    local startpos, endpos = string_find(str, separator, currentpos, dopattern)
    if (startpos) then
        ret[i] = string_sub(str, currentpos, startpos - 1)
        currentpos = endpos + 1

        i = i + 1
        if (i ~= length) then
            goto explode
        end
    end

	ret[i] = string_sub(str, currentpos)

	return ret
end

local string_Explode = string.Explode

--- @param str string
--- @param delimiter string
--- @return string[]
function string.Split(str, delimiter)
    return string_Explode(delimiter, str)
end

--- @param str string
--- @param start string
--- @return boolean
function string.StartsWith(str, start)
    return string_sub(str, 1, #start) == start
end

--- @param str string
--- @param endstr string
--- @return boolean
function string.EndsWith(str, endstr)
    return endstr == "" or string_sub(str, -(#endstr)) == endstr
end

--- @param str string
--- @param tofind string
--- @param toreplace string
--- @return string
function string.Replace(str, tofind, toreplace)
    local tbl = string_Explode(tofind, str)
    if (tbl[1]) then
        return table_concat(tbl, toreplace)
    end

    return str
end