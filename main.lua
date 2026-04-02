--> [main.lua] <--
--> Loads all ljeutil-related files <--

--> Do not enable this on actual servers because it can get you detected
local RUN_BENCHMARKS = false

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
if (RUN_BENCHMARKS) then
    lje.include("modules/__benchmark.lua")
end