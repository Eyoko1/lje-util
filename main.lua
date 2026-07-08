--> [main.lua] <--
--> Loads all lje-util-related files <--

--> Do not enable this on actual servers because it can get you detected
local RUN_BENCHMARKS = false

local alreadyloaded = lje.__lje_util_loaded
lje.__lje_util_loaded = true

lje.include("modules/string.lua")
lje.include("modules/math.lua")

lje.con_print("Already loaded: " .. tostring(alreadyloaded))
if (not alreadyloaded) then --> These should not be hot-reloaded
    lje.include("modules/hook.lua")
    lje.include("modules/util.lua")
    lje.con_print("Unloaded!")
end

lje.include("modules/render.lua")
lje.include("modules/draw.lua")
lje.include("modules/file.lua")
lje.include("modules/media.lua")
lje.include("modules/input.lua")
lje.include("modules/team.lua")
lje.include("modules/timer.lua")
lje.include("modules/table.lua")
if (RUN_BENCHMARKS) then
    lje.include("modules/__benchmark.lua")
end

lje.env.on_cleanup(function()
    lje.__lje_util_loaded = false
end)