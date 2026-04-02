--> [security.lua] <--
--> Adds various security features for LJE <--

local rawget = rawget
local rawequal = rawequal
local isentity = isentity
local _G = _G
local calldetour = hook.__calldetour
local callpre = hook.callpre
local callpost = hook.callpost
local handlecall = lje.vm.handle_engine_call
local is_lje_involved = lje.env.is_lje_involved

local ENTITY = cloned_mts.Entity
local ENTITY_DrawModel = ENTITY.DrawModel
local ENTITY___index = ENTITY.__oldIndex

local recognisedcalls = setmetatable({}, {__mode = "k"})

if (not calldetour) then
    lje.con_print("Fatal error when loading ljeutil/modules/security.lua - please report this to me")
    return
end

local detours = {
    generic = function()
        if (is_lje_involved(3)) then
            handlecall()
        end
    end,

    hookcall = function(func, ...)
        handlecall()
        return calldetour(func, ...)
    end,
    draw = function(func, entity, flags)
        if (is_lje_involved(3)) then
            ENTITY_DrawModel(entity, flags)
            handlecall()
        end
    end
}

--> These two functions could be made faster if they called set_engine_call_hook and made it a nop, but currently set_engine_call_hook cannot be called at runtime

local disableenginecalls = false

--> Disables all engine calls
function lje.util.disable_engine_calls()
    disableenginecalls = true
end

--> Re-enables engine calls
function lje.util.enable_engine_calls()
    disableenginecalls = false
end

lje.vm.set_engine_call_hook(function(func, nargs, nresults, ...)
    if (disableenginecalls) then
        return
    end

    ::do_hook::
    local callback = recognisedcalls[func]
    if (callback) then
        return callback(func, ...)
    end

    --> This area is not regularly reached so performance isn't too much of a concern
    --> This is because when a function is registered, it is automatically handled at the do_hook label

    --> Detouring hook.Call - we cannot set up a variable that is set to true once this is found, since hook.Call can be changed at any time
    local hook = rawget(_G,  "hook")
    if (hook) then
        local call = rawget(hook, "Call")
        if (rawequal(func, call)) then
            recognisedcalls[func] = detours.hookcall
            goto do_hook
        end
    end

    --> Detouring ENT:Draw for safe LJE (re)rendering
    if (isentity(...)) then
        --local entity = ... --> This is not necessary

        local draw = ENTITY___index(..., "Draw")
        if (draw and rawequal(func, draw)) then
            recognisedcalls[func] = detours.draw
            goto do_hook
        end

        local drawtranslucent = ENTITY___index(..., "DrawTranslucent")
        if (drawtranslucent and rawequal(func, drawtranslucent)) then
            recognisedcalls[func] = detours.draw
            goto do_hook
        end
    end

    callback = callpre("ljeutil/unknownenginecall", func, nargs, nresults, ...) or
               callpost("ljeutil/unknownenginecall", func, nargs, nresults, ...)
    recognisedcalls[func] = callback or detours.generic
    --goto do_hook --> This is important for security but causes issues? @TODO: Fix this ASAP
end)