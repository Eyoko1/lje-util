--> [util.lua] <--
--> Adds / optimises various useful functions <--

local _R = lje.util.get_registry()

--- @type Entity
ENTITY = _R.Entity

--- @type Player
PLAYER = _R.Player

--- @type Vector
VECTOR = _R.Vector

--- @type Angle
ANGLE = _R.Angle

--- @type CUserCmd
CUSERCMD = _R.CUserCmd

--- @type File
FILE = _R.File

--- @type ConVar
CONVAR = _R.ConVar

--- @type VMatrix
VMATRIX = _R.VMatrix

--- @type Weapon
WEAPON = _R.Weapon

--- @class Vector
--- @field __sub fun(self: Vector, other: Vector)

local ENTITY = _R.Entity
local player_GetAll = player.GetAll
local player_GetCount = player.GetCount
local LocalPlayer = LocalPlayer
local math_random = math.random
local table_concat = table.concat
local tonumber = tonumber
local ENTITY_DrawModel = ENTITY.DrawModel
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

local screenwidth = ScrW()
local screenheight = ScrH()

local table_remove = table.remove
local function searchandremove(tbl, value, count)
    if (count <= 0) then
        return count
    end

    local i = 1
    ::remove::
    if (tbl[i] == value) then
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
                                    --> @EDIT: (24/05/2026): I can check the flag EFL_KILLME with Entity:IsEFlagSet(), but this would be very slow - probably slower than the normal function - so I won't add that
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

local cam_GetViewMatrix = cam.GetViewMatrix
local cam_GetProjectionMatrix = cam.GetProjectionMatrix
local VMATRIX_Mul = VMATRIX.Mul
local VMATRIX_Unpack = VMATRIX.Unpack

local flmatrix = Matrix()
local m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15 = VMATRIX_Unpack(flmatrix)

--> Sets up the data required for world-to-screen operations
function lje.util.setup_viewmatrix()
    flmatrix = cam_GetProjectionMatrix()
    VMATRIX_Mul(flmatrix, cam_GetViewMatrix())
    m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15 = VMATRIX_Unpack(flmatrix)
end

--> Performs a world-to-screen calculation using the given coordinates. This is cheaper than using Vector:ToScreen() as it does not create a ToScreenData struct
-->
--> You must call lje.util.setup_viewmatrix in a 3D context before calling this function
--- @param inx number
--- @param iny number
--- @param inz number
--- @return number x
--- @return number y
--- @return boolean visible
function lje.util.world_to_screen(inx, iny, inz)
    local w = inx * m12 + iny * m13 + inz * m14 + m15
    if (w > 0.001) then
        local i = 1 / w
        local rawx = (inx * m0 + iny * m1 + inz * m2 + m3)
        local rawy = (inx * m4 + iny * m5 + inz * m6 + m7)
        local outx = ((rawx * i) * 0.5 + 0.5) * screenwidth
        local outy = (0.5 - ((rawy * i) * 0.5)) * screenheight
        local frustum = w * 1.25
        return outx, outy, rawx >= -frustum and rawx <= frustum and rawy >= -frustum and rawy <= frustum
    end

    return -1, -1, false
end

--> Does the same as lje.util.world_to_screen but takes in a vector instead of three numbers
-->
--> You must call lje.util.setup_viewmatrix in a 3D context before calling this function
--- @param vector Vector
--- @return number x
--- @return number y
--- @return boolean visible
function lje.util.world_to_screen_vector(vector)
    local inx, iny, inz = vector[1], vector[2], vector[3]
    local w = inx * m12 + iny * m13 + inz * m14 + m15
    if (w > 0.001) then
        local i = 1 / w
        local rawx = (inx * m0 + iny * m1 + inz * m2 + m3)
        local rawy = (inx * m4 + iny * m5 + inz * m6 + m7)
        local outx = ((rawx * i) * 0.5 + 0.5) * screenwidth
        local outy = (0.5 - ((rawy * i) * 0.5)) * screenheight
        local frustum = w * 2
        return outx, outy, rawx >= -frustum and rawx <= frustum and rawy >= -frustum and rawy <= frustum
    end

    return -1, -1, false
end

local util_is_player = lje.util.is_player
local debug_getmetatable = debug.getmetatable
local npc_metatable = _R.NPC
hook.pre("OnEntityCreated", "__lje_util_entities", function(entity)
    if (util_is_player(entity)) then
        playercount = playercount + 1
        players[playercount] = entity

        if (entity ~= localplayer) then
            otherplayercount = otherplayercount + 1
            otherplayers[otherplayercount] = entity
        end

        hook.callpre("lje-util/playerconnect", entity)
        hook.callpost("lje-util/playerconnect", entity)
    elseif (debug_getmetatable(entity) == npc_metatable) then
        npcdict[entity] = true
        npccount = npccount + 1
        npcs[npccount] = entity
    end

    entitycount = entitycount + 1
    entities[entitycount] = entity
end)

hook.pre("EntityRemoved", "__lje_util_entities", function(entity, fullupdate)
    if (util_is_player(entity)) then
        if (not fullupdate--[[ and not rawequal(entity, localplayer)]]) then
            playercount = searchandremove(players, entity, playercount)
            otherplayercount = searchandremove(otherplayers, entity, otherplayercount) --> This could be faster as both arrays are almost identical

            hook.callpre("lje-util/playerdisconnect", entity)
            hook.callpost("lje-util/playerdisconnect", entity)
        end
    elseif (npcdict[entity]) then
        npcdict[entity] = nil
        npccount = searchandremove(npcs, entity, npccount)
    end

    entitycount = searchandremove(entities, entity, entitycount)
end)

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

hook.pre("OnScreenSizeChanged", "__lje_util_screensize", function(oldwidth, oldheight, newwidth, newheight)
    screenwidth = newwidth
    screenheight = newheight
end)

hook.pre("InitPostEntity", "__lje_util_localplayer", function()
    localplayer = LocalPlayer()
    function LocalPlayer()
        return localplayer
    end

    playercount = player_GetCount()
    players = player_GetAll()
    
    otherplayercount = player_GetCount()
    otherplayers = player_GetAll()
    
    otherplayercount = searchandremove(otherplayers, localplayer, otherplayercount)
    hook.removepre("InitPostEntity", "__lje_util_localplayer")
end)

for _, entity in ipairs(ents.GetAll()) do
    if (lje.util.is_npc(entity)) then
        npccount = npccount + 1
        npcs[npccount] = entity
    end
end