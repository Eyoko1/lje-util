--> [main.lua] <--
--> Loads all ljeutil-related files <--

local unloaded = hook == nil

lje.include("modules/string.lua")
lje.include("modules/math.lua")

if (unloaded) then --> These should not be hot-reloaded
    lje.include("modules/hook.lua")
    lje.include("modules/security.lua")
    lje.include("modules/util.lua")
end

lje.include("modules/render.lua")
lje.include("modules/draw.lua")
lje.include("modules/file.lua")
lje.include("modules/media.lua")
lje.include("modules/convars.lua")
lje.include("modules/input.lua")