--> [util.lua] <--
--> Adds / optimises various useful functions <--

local ENTITY = cloned_mts.Entity
local player_GetAll = player.GetAll
local player_GetCount = player.GetCount
local LocalPlayer = LocalPlayer
local math_random = math.random
local table_concat = table.concat
local tonumber = tonumber
local rawequal = rawequal
local ENTITY_DrawModel = ENTITY.DrawModel
local disable_engine_calls = lje.util.disable_engine_calls
local enable_engine_calls = lje.util.enable_engine_calls
local create_table = lje.util.create_table
local ENTITY_GetClass = ENTITY.GetClass
local ents_GetCount = ents.GetCount

local randomstringcharacters = {" ", "!", "#", "$", "%", "&", "+", ",", "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "^", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
local randomstringcharactercount = #randomstringcharacters

--> Pre-allocated table for lje.util.random_string()
local rstringtable = create_table(128, 0)

local localplayer = LocalPlayer()

local playercount = player_GetCount()
local players = player_GetAll()

local otherplayercount = player_GetCount()
local otherplayers = player_GetAll()

local entities = ents.GetAll()
local entitycount = #entities --ents.GetCount(true)

local npccount = 0
local npcs = {}
local npcdict = setmetatable({}, {__mode = "k"})

local table_remove = table.remove
local function searchandremove(tbl, value, count)
    if (count <= 0) then
        return count
    end

    local i = 1
    ::remove::
    if (rawequal(tbl[i], value)) then
        table_remove(tbl, i)
        return count - 1
    elseif (i ~= count) then
        i = i + 1
        goto remove
    end

    return count
end

--> Returns whether or not the given object is valid
--- @param obj Entity?
--- @return boolean
function IsValid(obj)
    if (obj) then
        local isvalid = obj.IsValid
        if (isvalid) then
            return isvalid(obj)
        else
            return false
        end
    else
        return false
    end
end

--> Iterates over all players except the localplayer and calls the given callback for each one
--- @param callback fun(entity: Entity): nil
--- @return nil
function lje.util.iterate_players(callback)
    if (otherplayercount == 0) then
        return
    end

    local i = 1
    ::iterate_players::
    callback(otherplayers[i])

    if (i == otherplayercount) then
        return
    end

    i = i + 1
    goto iterate_players
end

--> Iterates over all NPCs and calls the given callback for each one
--- @param callback fun(entity: Entity): nil
--- @return nil
function lje.util.iterate_npcs(callback)
    if (npccount == 0) then
        return
    end

    local i = 1
    ::iterate_npcs::
    callback(npcs[i])

    if (i == npccount) then
        return
    end

    i = i + 1
    goto iterate_npcs
end

--> Iterates over all entities and calls the given callback for each one
--- @param callback fun(entity: Entity): nil
--- @return nil
function lje.util.iterate_entities(callback)
    if (entitycount == 0) then
        return
    end

    local i = 1
    ::iterate_entities::
    callback(entities[i])

    if (i == entitycount) then
        return
    end

    i = i + 1
    goto iterate_entities
end

--> Generates a random string
--- @param length integer? Default is 32
--- @return string
function lje.util.random_string(length)
    length = length or 32
    if (length <= 0) then
        return ""
    end

    local i = 1
    ::fast_random_string::
    rstringtable[i] = randomstringcharacters[math_random(1, randomstringcharactercount)]

    if (i ~= length) then
        i = i + 1
        goto fast_random_string
    end

    return table_concat(rstringtable, "", 1, length)
end

--> Very fast implementation of color - all arguments must be provided as numbers
--- @param r number
--- @param g number
--- @param b number
--- @param a number
--- @return Color
function lje.util.color_strict(r, g, b, a)
    return {
        r = r < 255 and r or 255,
        g = g < 255 and g or 255,
        b = b < 255 and b or 255,
        a = a < 255 and a or 255
    }
end

--> Safely draws the given entity's model
--- @param entity Entity
--- @param flags? number
--- @return nil
function lje.util.safe_draw_model(entity, flags)
    disable_engine_calls()
    ENTITY_DrawModel(entity, flags)
    enable_engine_calls()
end

--> Returns whether or not the given entity is a player - this should be used instead of entity:IsPlayer()
--- @param entity Entity
--- @return boolean
function lje.util.is_player(entity)
    return ENTITY_GetClass(entity) == "player"
end

--> Returns whether or not the given entity is an npc - this should be used instead of entity:IsNPC()
--- @param entity Entity
--- @return boolean
function lje.util.is_npc(entity)
    return npcdict[entity] == true
end

--> Stripped-down reimplementation of Color, lacking the usual metatable
--- @param r number
--- @param g number
--- @param b number
--- @param a number?
--- @return Color
function Color(r, g, b, a)
    r = tonumber(r) --- @diagnostic disable-line
    g = tonumber(g) --- @diagnostic disable-line
    b = tonumber(b) --- @diagnostic disable-line
    a = a and tonumber(a) or 255
    return {
        r = r < 255 and r or 255,
        g = g < 255 and g or 255,
        b = b < 255 and b or 255,
        a = a < 255 and a or 255
    }
end

--> Returns an immutable(!) array of all players - Do NOT edit the value returned by this
--- @return Player[]
function player.GetAll()
    return players
end

--> Returns the number of players on the server
--- @return integer
function player.GetCount()
    return playercount
end

--> Returns a mutable(!) array of all players - You can edit the value returned by this
--- @return Player[]
function lje.util.get_mutable_players()
    if (playercount == 0) then
        return {}
    end

    local mutable = create_table(playercount, 0)
    local i = 1
    ::get_mutable_players::
    mutable[i] = players[i]
    if (i ~= playercount) then --> playercount is guaranteed to be at least 1, since the localplayer is in it
        i = i + 1
        goto get_mutable_players
    end

    return mutable
end

--> Returns an immutable(!) array of all entities on the server - Do NOT edit the value returned by this
--- @return Entity[]
function ents.GetAll()
    return entities
end

--> Returns the number of entities on the server - Unlike the normal function, includekillme is true by default
--- @param includekillme boolean? Default is true
function ents.GetCount(includekillme)
    if (includekillme == false) then
        return ents_GetCount(false) --> I couldn't find an easy way to make this fast so I swapped the logic of the function, as I don't think includekillme has any effect on people normally
    else
        return entitycount
    end
end

--> Returns a mutable(!) array of all entities on the server - You can edit the value returned by this
--- @return Entity[]
function lje.util.get_mutable_entities()
    if (entitycount == 0) then
        return {}
    end

    local mutable = create_table(entitycount, 0)
    local i = 1
    ::get_mutable_entities::
    mutable[i] = entities[i]
    if (i ~= entitycount) then
        i = i + 1
        goto get_mutable_entities
    end

    return mutable
end

local util_is_player = lje.util.is_player
local debug_getmetatable = debug.getmetatable
local npc_metatable = FindMetaTable("NPC")
hook.pre("OnEntityCreated", "__ljeutil_entities", function(entity)
    if (util_is_player(entity)) then
        playercount = playercount + 1
        players[playercount] = entity

        if (not rawequal(entity, localplayer)) then
            otherplayercount = otherplayercount + 1
            otherplayers[otherplayercount] = entity
        end

        hook.callpre("ljeutil/playerconnect", entity)
        hook.callpost("ljeutil/playerconnect", entity)
    elseif (rawequal(debug_getmetatable(entity), npc_metatable)) then
        npcdict[entity] = true
        npccount = npccount + 1
        npcs[npccount] = entity
    end

    entitycount = entitycount + 1
    entities[entitycount] = entity
end)

hook.pre("EntityRemoved", "__ljeutil_entities", function(entity, fullupdate)
    if (util_is_player(entity)) then
        if (not fullupdate--[[ and not rawequal(entity, localplayer)]]) then
            playercount = searchandremove(players, entity, playercount)
            otherplayercount = searchandremove(otherplayers, entity, otherplayercount) --> this could be faster as both arrays are almost identical

            hook.callpre("ljeutil/playerdisconnect", entity)
            hook.callpost("ljeutil/playerdisconnect", entity)
        end
    elseif (npcdict[entity]) then
        npcdict[entity] = nil
        npccount = searchandremove(npcs, entity, npccount)
    end

    entitycount = searchandremove(entities, entity, entitycount)
end)

local screenwidth = ScrW()
local screenheight = ScrH()

--> Returns the width of the screen - This does not factor in viewports
--- @return integer
function ScrW()
    return screenwidth
end

--> Returns the height of the screen - This does not factor in viewports
--- @return integer
function ScrH()
    return screenheight
end

hook.pre("OnScreenSizeChanged", "__ljeutil_screensize", function(oldwidth, oldheight, newwidth, newheight)
    screenwidth = newwidth
    screenheight = newheight
end)

hook.pre("InitPostEntity", "__ljeutil_localplayer", function()
    localplayer = LocalPlayer()
    function LocalPlayer()
        return localplayer
    end

    playercount = player_GetCount()
    players = player_GetAll()
    
    otherplayercount = player_GetCount()
    otherplayers = player_GetAll()
    
    otherplayercount = searchandremove(otherplayers, localplayer, otherplayercount)
    hook.removepre("InitPostEntity", "__ljeutil_localplayer")
end)

--> a for loop is used here because this is only executed once so the performance overhead is not a concern
for _, entity in ipairs(ents.GetAll()) do
    if (lje.util.is_npc(entity)) then
        npccount = npccount + 1
        npcs[npccount] = entity
    end
end