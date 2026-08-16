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
    while (true) do
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
    end
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
    while (node) do
        if (node[NODE_NAME] == identifier) then
            last[NODE_NEXT] = node[NODE_NEXT]
            return
        end

        last = node
        node = node[NODE_NEXT]
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
    while (node) do
        local success, a, b, c, d, e, f = pcall(node[NODE_CALLBACK], ...)
        if (success) then
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
        else
            __doerror(a)
        end

        node = node[NODE_NEXT]
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
    while (node) do
        local success, a, b, c, d, e, f = pcall(node[NODE_CALLBACK], ...)
        if (success) then
            if (a ~= nil) then
                return a, b, c, d, e, f
            end
        else
            __doerror(a)
        end

        node = node[NODE_NEXT]
    end
end

--------------------------------

local type = type
local lje_proxy_copy = lje.proxy.copy
local callpath = lje.state.path(lje.state.client, "hook"):index("Call")
local copypath = callpath.copy

local hookcall

local inhookcall = false
local postnode

local shouldcheck = true

local pa, pb, pc, pd, pe, pf

lje.vm.add_pre_engine_call_hook(function(func, nargs, nresults, event, gm, a, b, c, d, e, f)
    if (func ~= hookcall) then
        if (hookcall and not shouldcheck) then
            return
        else
            hookcall = copypath(callpath)
            if (func ~= hookcall) then
                return
            end
            --> hook.Call is now available so we'll fall through
        end
    end

    local hooks = hooklist[event]
    if (not hooks) then
        return
    end

    if (nargs >= 3) then
    if (type(a) == "userdata") then a = lje_proxy_copy(a) end
    if (nargs >= 4) then
    if (type(b) == "userdata") then b = lje_proxy_copy(b) end
    if (nargs >= 5) then
    if (type(c) == "userdata") then c = lje_proxy_copy(c) end
    if (nargs >= 6) then
    if (type(d) == "userdata") then d = lje_proxy_copy(d) end
    if (nargs >= 7) then
    if (type(e) == "userdata") then e = lje_proxy_copy(e) end
    if (nargs >= 8) then
    if (type(f) == "userdata") then f = lje_proxy_copy(f) end
    end end end end end end

    local node = hooks[1--[[PRE_HOOK_NODE]]]
    if (node) then
        --> Run the pre node
        --[=[
        ::call_node::
        local x = node[2]
        --node[2--[[NODE_CALLBACK]]](a, b, c, d, e, f)
        node = node[3--[[NODE_NEXT]]]
        if (node) then
            goto call_node
        end
        ]=]

        --[=[
        repeat
            local x = node[2]
            --node[2--[[NODE_CALLBACK]]](a, b, c, d, e, f)
            node = node[3--[[NODE_NEXT]]]
        until not node
        ]=]

        --> Seems to be the fastest iteration method according to my benchmarks
        while (node) do
            --local x = node[2]
            node[2--[[NODE_CALLBACK]]](a, b, c, d, e, f)
            node = node[3--[[NODE_NEXT]]]
        end
    end

    postnode = hooks[2--[[POST_HOOK_NODE]]]
    if (postnode) then
        inhookcall = true
        pa, pb, pc, pd, pe, pf = a, b, c, d, e, f
    end
end)

lje.vm.add_pre_engine_call_hook(function()
    if (not inhookcall) then
        return
    end

    inhookcall = false

    --> Run the post node
    while (postnode) do
        postnode[2--[[NODE_CALLBACK]]](pa, pb, pc, pd, pe, pf)
        postnode = postnode[3--[[NODE_NEXT]]]
    end
end)

hook.pre("InitPostEntity", "__lje-util_hookfix", function()
    shouldcheck = false
    hook.removepre("InitPostEntity", "__lje-util_hookfix")
end)