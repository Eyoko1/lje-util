--> [file.lua] <--
--> Re-implements some file.* functions <--

local _R = lje.util.get_registry()

local FILE = _R.File

local FILE_Read = FILE.Read
local FILE_Size = FILE.Size
local FILE_Close = FILE.Close
local FILE_Write = FILE.Write

local file_Open = file.Open

--- @param filename string
--- @param path string
--- @return string?
function file.Read(filename, path)
    if (path == true) then
        path = "GAME"
    elseif (not path) then
        path = "DATA"
    end

    local f = file_Open(filename, "rb", path)
    if (not f) then
        return nil
    end

    local str = FILE_Read(f, FILE_Size(f))
    FILE_Close(f)

    return str or ""
end

--- @param filename string
--- @param contents string
--- @return boolean
function file.Write(filename, contents)
    local f = file_Open(filename, "wb", "DATA")
    if (not f) then
        return false
    end

    FILE_Write(f, contents)
    FILE_Close(f)

    return true
end

--- @param filename string
--- @param contents string
--- @return boolean
function file.Append(filename, contents)
    local f = file_Open(filename, "ab", "DATA")
    if (not f) then
        return false
    end

    FILE_Write(f, contents)
    FILE_Close(f)

    return true
end