--> [string.lua] <--
--> Adds / optimises various string.* functions <--

local string_sub = string.sub
local string_find = string.find
local create_table = lje.util.create_table

local table_concat = table.concat

function string.ToTable(str)
    str = tostring(str)

    local length = #str
    local i = 1
    local tbl = create_table(length, 0)
    ::totable_loop::
    tbl[i] = string_sub(str, i, i)

    if (i == length) then
        return tbl
    end

    i = i + 1
    goto totable_loop
end

local totable = string.ToTable
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
function string.Split(str, delimiter)
    return string_Explode(delimiter, str)
end

function string.StartsWith(str, start)
    return string_sub(str, 1, #start) == start
end

function string.EndsWith(str, endstr)
    return endstr == "" or string_sub(str, -(#endstr)) == endstr
end

function string.Replace(str, tofind, toreplace)
    local tbl = string_Explode(tofind, str)
    if (tbl[1]) then
        return table_concat(tbl, toreplace)
    end

    return str
end