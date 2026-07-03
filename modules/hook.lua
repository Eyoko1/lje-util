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

=> Right now I have decided to use option 1 as I don't think lje-util hooks are called frequently enough for it to matter too much
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

--> Node traversal is faster with goto loops

local PRE_HOOK_NODE = 1
local POST_HOOK_NODE = 2

local NODE_NAME = 1
local NODE_CALLBACK = 2
local NODE_NEXT = 3

local hooklist = {}

hook = hook or {}
hook.list = hooklist

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

local type = type
local lje_proxy_copy = lje.proxy.copy
local unpack = unpack
local callpath = lje.state.path(lje.state.client, "hook"):index("Call")
local runpath = lje.state.path(lje.state.client, "hook"):index("Run")
local copypath = callpath.copy

local hookcall = nil
local hookrun = nil

local inhookcall = false
local postnode = nil
local ha, hb, hc, hd, he, hf

lje.vm.add_pre_engine_call_hook(function(func, nargs, nresults, event, gm, a, b, c, d, e, f)
    if (not func) then
        return
    end

    if (not hookcall) then
        hookcall = copypath(callpath)
        hookrun = copypath(runpath)
    end

    local copycount
    local hooks
    if (func == hookcall --[[copypath(callpath)]]) then -- hook.Call
        hooks = hooklist[event]
        if (not hooks) then
            return
        end
        copycount = nargs - 2
    elseif (func == hookrun--[[copypath(runpath)]]) then -- hook.Run (an edge case where some events are called with hook.Run such as DrawOverlay)
        hooks = hooklist[event]
        if (not hooks) then
            return
        end
        f = e
        e = d
        d = c
        c = b
        b = a
        a = gm
        copycount = nargs - 1
    else
        return -- We aren't in hook.* so let's just exit
    end

    if (copycount >= 1) then
    if (type(a) == "userdata") then a = lje_proxy_copy(a) end
    if (copycount >= 2) then
    if (type(b) == "userdata") then b = lje_proxy_copy(b) end
    if (copycount >= 3) then
    if (type(c) == "userdata") then c = lje_proxy_copy(c) end
    if (copycount >= 4) then
    if (type(d) == "userdata") then d = lje_proxy_copy(d) end
    if (copycount >= 5) then
    if (type(e) == "userdata") then e = lje_proxy_copy(e) end
    if (copycount >= 6) then
    if (type(f) == "userdata") then f = lje_proxy_copy(f) end
    end end end end end end

    local node = hooks[1--[[PRE_HOOK_NODE]]]
    if (node) then
        --> Run the pre node
        ::call_node::
        node[2--[[NODE_CALLBACK]]](a, b, c, d, e, f)
        node = node[3--[[NODE_NEXT]]]
        if (node) then
            goto call_node
        end
    end

    postnode = hooks[2--[[POST_HOOK_NODE]]]
    if (postnode) then
        inhookcall = true
        ha, hb, hc, hd, he, hf = a, b, c, d, e, f
    end
end)

lje.vm.add_post_engine_call_hook(function()
    if (not inhookcall) then
        return
    end

    inhookcall = false

    --- @cast postnode -nil

    --> Run the post node
    ::call_node::
    postnode[2--[[NODE_CALLBACK]]](ha, hb, hc, hd, he, hf)
    postnode = postnode[3--[[NODE_NEXT]]]
    if (postnode) then
        goto call_node
    end
end)