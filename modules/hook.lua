--> [hook.lua] <--
--> Adds a custom hook library, separate from the default gmod library <--

--[[ HOOK FORMATS ]]--
--[[
1. Linked List
+ Easy to implement
+ Fast removal + no need for extra upvalues in hook.Call
- Slower access (2 array accesses)

2. Array
+ Very fast (1 array access)
- Hard to implement
- Slow removal (Dictionary removal + table.remove on array + editing upvalue)

=> Right now I have decided to use option 1 as I don't think ljeutil hooks are called frequently enough for it to matter too much
=> If you really think I should change this, you can ask me and I will, but it is quite complex to make option 2
]]--

-- [[ INTERNAL FORMAT 2 (ACCORDING TO THE ABOVE) ]] --
--[[
-- Event: array
{
    [1] PRE_HOOK_NODE: node?,
    [2] POST_HOOK_NODE: node?
}
-- Node: array
{
    [1] NODE_NAME: string,
    [2] NODE_CALLBACK: function,
    [3] NODE_NEXT: node?
}
]]--

local PRE_HOOK_NODE = 1
local POST_HOOK_NODE = 2

local NODE_NAME = 1
local NODE_CALLBACK = 2
local NODE_NEXT = 3

local hooklist = {}
local hookdisabled = false
local hookdisablelje = false
local hookignorelua = true

hook = {
    list = hooklist
}
lje.env.get().hook = hook

--------------------------------

--> Prevent GLua callbacks for hooks being executed - and additionally provides the ability to do the same for LJE callbacks
--- @param disableljehooks boolean? Default is true --> if true, LJE callbacks for hooks won't be called either
function hook.disable(disableljehooks)
    hookdisabled = true
    if (disableljehooks == nil) then
        hookdisablelje = true
    else
        hookdisablelje = disableljehooks
    end
end

--> Re-enables GLua and LJE callbacks for hooks
function hook.enable()
    hookdisabled = false
end

--> Returns whether or not hooks are disabled - returns both hookdisabled, and hookdisablelje
--- @return boolean, boolean
function hook.isdisabled()
    return hookdisabled, hookdisablelje
end

--------------------------------

--> Prevent LJE callbacks from being called if the hook was invoked by lua
function hook.disallowlua()
    hookignorelua = true
end

--> Allow LJE callbacks to be called when a hook is invoked by lua
function hook.allowlua()
    hookignorelua = false
end

--------------------------------

local function __addnode(root, identifier, callback)
    local node = root
    ::add_node::
    local nextnode = node[NODE_NEXT]
    if (node[NODE_NAME] == identifier) then
        node[NODE_CALLBACK] = callback
        return
    end
    if (not nextnode) then
        node[NODE_NEXT] = {identifier, callback, nil}
        return
    end

    node = nextnode
    goto add_node
end

--> Registers a callback to be executed before the default GLua callbacks for a hook are executed
--- @param event string
--- @param identifier string
--- @param callback fun(...): ...
--- @return nil
function hook.pre(event, identifier, callback)
    local hooks = hooklist[event]
    if (hooks) then
        local root = hooks[PRE_HOOK_NODE]
        if (root) then
            __addnode(root, identifier, callback)
        else
            hooks[PRE_HOOK_NODE] = {identifier, callback, nil}
        end
    else
        hooklist[event] = {
            {identifier, callback, nil},
            nil
        }
    end
end

--> Registers a callback to be executed after the default GLua callbacks for a hook are executed
--- @param event string
--- @param identifier string
--- @param callback fun(...): ...
--- @return nil
function hook.post(event, identifier, callback)
    local hooks = hooklist[event]
    if (hooks) then
        local root = hooks[POST_HOOK_NODE]
        if (root) then
            __addnode(root, identifier, callback)
        else
            hooks[POST_HOOK_NODE] = {identifier, callback, nil}
        end
    else
        hooklist[event] = {
            nil,
            {identifier, callback, nil}
        }
    end
end

--------------------------------

local function __removenode(root, identifier)
    local last = root
    local node = root[NODE_NEXT]
    ::remove_node::
    if (node) then
        if (node[NODE_NAME] == identifier) then
            last[NODE_NEXT] = node[NODE_NEXT]
            return
        end

        last = node
        node = node[NODE_NEXT]
        goto remove_node
    end
end

--> Removes a callback which is executed before the default GLua callbacks for a hook
--- @param event string
--- @param identifier string
--- @return nil
function hook.removepre(event, identifier)
    local hooks = hooklist[event]
    if (not hooks) then
        return
    end

    local root = hooks[PRE_HOOK_NODE]
    if (not root) then
        return
    end

    if (root[NODE_NAME] == identifier) then
        hooks[PRE_HOOK_NODE] = root[NODE_NEXT]
    else
        __removenode(root, identifier)
    end
end

--> Removes a callback which is executed after the default GLua callbacks for a hook
--- @param event string
--- @param identifier string
--- @return nil
function hook.removepost(event, identifier)
    local hooks = hooklist[event]
    if (not hooks) then
        return
    end

    local root = hooks[POST_HOOK_NODE]
    if (not root) then
        return
    end

    if (root[NODE_NAME] == identifier) then
        hooks[POST_HOOK_NODE] = root[NODE_NEXT]
    else
        __removenode(root, identifier)
    end
end

--------------------------------

local function __doerror(message)
    lje.con_printf("$red{%s}", message)
end

--> Calls all events which are usually executed before the default GLua callbacks
--- @param event string
--- @param ... any
--- @return ...
function hook.callpre(event, ...)
    local hooks = hooklist[event]
    if (not hooks) then
        return
    end

    local node = hooks[PRE_HOOK_NODE]
    ::call_pre::
    if (node) then
        local success, a, b, c, d, e, f = pcall(node[NODE_CALLBACK], ...)
        if (success) then
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
        else
            __doerror(a)
        end

        node = node[NODE_NEXT]
        goto call_pre
    end
end

--> Calls all events which are usually executed after the default GLua callbacks
--- @param event string
--- @param ... any
--- @return ...
function hook.callpost(event, ...)
    local hooks = hooklist[event]
    if (not hooks) then
        return
    end

    local node = hooks[POST_HOOK_NODE]
    ::call_pre::
    if (node) then
        local success, a, b, c, d, e, f = pcall(node[NODE_CALLBACK], ...)
        if (success) then
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
        else
            __doerror(a)
        end

        node = node[NODE_NEXT]
        goto call_pre
    end
end

--------------------------------

--> The references to the enums here can be inlined but it doesn't really matter that much
local is_lua_involved = lje.env.is_lua_involved

local a2, b2, c2, d2, e2, f2

--> Returns the values that the default gmod callback returned - this will only return valid results in hook.post callbacks
--- @return any, any, any, any, any, any
function hook.getreturns()
    return a2, b2, c2, d2, e2, f2
end

--> An internal function called in an engine call hook - do not manually call this
--- @param originalcall fun(event: string, gm: GM, ...): ...
--- @param event string
--- @param gm GM
--- @param ... any
--- @return ...
function hook.__calldetour(originalcall, event, gm, ...)
    if (hookdisabled) then
        if (hookdisablelje) then
            return
        end

        if (hookignorelua and is_lua_involved(3)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        local node = hooks[1--[[PRE_HOOK_NODE]]]
        ::execute_pre_disabled::
        if (node) then
            local a, b, c, d, e, f = node[2--[[NODE_CALLBACK]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
            
            node = node[3--[[NODE_NEXT]]]
            goto execute_pre_disabled
        end

        node = hooks[2--[[POST_HOOK_NODE]]]
        ::execute_post_disabled::
        if (node) then
            local a, b, c, d, e, f = node[2--[[NODE_CALLBACK]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
            
            node = node[3--[[NODE_NEXT]]]
            goto execute_post_disabled
        end
    else
        if (hookignorelua and is_lua_involved(3)) then
            return originalcall(event, gm, ...)
        end

        local hooks = hooklist[event]
        if (not hooks) then
            return originalcall(event, gm, ...)
        end

        local node = hooks[1--[[PRE_HOOK_NODE]]]
        ::execute_pre::
        if (node) then
            local a, b, c, d, e, f = node[2--[[NODE_CALLBACK]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
            
            node = node[3--[[NODE_NEXT]]]
            goto execute_pre
        end

        --[[local ]]a2, b2, c2, d2, e2, f2 = originalcall(event, gm, ...)

        node = hooks[2--[[POST_HOOK_NODE]]]
        ::execute_post::
        if (node) then
            local a, b, c, d, e, f = node[2--[[NODE_CALLBACK]]](...)
            if (a ~= nil) then
                return a, b, c, d, e, f
            end

            node = node[3--[[NODE_NEXT]]]
            goto execute_post
        end

        return a2, b2, c2, d2, e2, f2
    end
end