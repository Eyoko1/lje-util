--> [media.lua] <--
--> Adds functions which let you load media (sound, images, etc) without it being exposed to the server <--
--> This currently is not functional as LJE has no file system <--

lje.media = {
    load = function(path, callback) end --> path is a location within the lje filesystem -> callback is passed the virtual path to be used with Material and Sound
                                        --> returns true if the media successfully loaded, and false otherwise
                                        --> also returns the value returned in callback
}

local string_sub = string.sub
local function getextension(path)
    local negativelength = -(#path)
    local i = -1
    ::get_extension_loop::
    if (string_sub(path, i, i) == ".") then
        return string_sub(path, i)
    elseif (i > negativelength) then
        i = i - 1
        goto get_extension_loop
    end
end

local PLACEHOLDER_READ_DIRECTORY = file.Read
local file_Write = file.Write
local file_Delete = file.Delete
local util_SHA256 = util.SHA256
local util_random_string = lje.util.random_string

--- @param path string
--- @param callback fun(virtualpath: string): any
--- @return boolean success Whether or not we could successfuly load media from the given path
--- @return any value The value returned by the callback
function lje.media.load(path, callback)
    local data = PLACEHOLDER_READ_DIRECTORY(path)
    local virtualpath = util_SHA256(util_random_string())..getextension(path)
    
    if (file_Write(virtualpath, data)) then
        local value = callback("data/"..virtualpath)
        file_Delete(virtualpath)
        return true, value
    else
        return false
    end
end

--[[
local success, material = lje.media.load("debug_image.jpg", function(virtualpath)
    return Material(virtualpath)
end)
hook.post("HUDPaint", "__lje_util_test", function()
    surface.SetMaterial(material)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(300, 300, 300, 300)
end)
]]