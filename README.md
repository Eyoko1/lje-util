# lje-util
A utility library made for [LJ-Expand](https://github.com/lj-expand/lj-expand/) which re-adds a lot of functions implemented purely in GLua, as well as new functions which would be useful, and provides security features which would otherwise need to be manually created.

Before using lje-util, I recommend that you read through this file so that you are aware of all of the features that are provided and may be required.

# Information
- When rendering anything to the screen, push the safe rendertarget called 'lje.util.rendertarget'  to the screen before rendering, and then pop it after
- Do **not** modify the table returned by player.GetAll() or ents.GetAll()
- In order to use the annotations provided by lje-util, you will need an extension such as sumneko's LuaLS extension for VSCode
- If you are re-rendering the scene (for something like freecam), you must call lje.util.override_blend() before doing the rendering
- For any support related to lje-util, as well as notifications for updates, you should join the LJE discord server - you can also directly contact me on discord using my username: '@eyoko1'
- I will generate new annotations when LJE updates, but in the case that I haven't yet, you can generate them yourself by simply running 'generate_annotations.py'

# List of added hooks
```lua
{
    ----------------------------------------------------------------------
    --> Called when the safe render target is drawn to the screen
    "lje-util/render", --> (): nil
    ----------------------------------------------------------------------
    --> Called immediately after all 'lje-util/render' hooks have executed
    "lje-util/postrender", --> (): nil
    ----------------------------------------------------------------------
    --> Called when a player joins the server
    --> [1] player: Player
    "lje-util/playerconnect", --> (player: Player): nil
    ----------------------------------------------------------------------
    --> Called when a player leaves the server
    --> [1] player: Player
    "lje-util/playerdisconnect", --> (player: Player): nil
    ----------------------------------------------------------------------
    --> Provides a context where you can use lje.input.* functions - only the pre hook provides this context, while the post one does not
    --> [1] cusercmd: CUserCmd
    "lje-util/input" --> (cusercmd: CUserCmd): nil
    ----------------------------------------------------------------------
}
```

# Redundancy / deprecated notice:
- `lje.util.is_player` : You can safely replace these calls with `entity:IsPlayer()` since metatables are remapped automatically by LJE
- `lje.util.is_npc` : You can safely replace these calls with `entity:IsNPC()` since metatables are remapped automatically by LJE

# List of (re)added functions
- A more comprehensive set of documentation is available inside of the source files
```lua
draw = {
    SimpleText = function(text, font, x, y, color, xalign, yalign) end,
    SimpleTextOutlined = function(text, font, x, y, color, xalign, yalign, outlinewidth, outlinecolor) end,
    DrawText = function(text, font, x, y, color, xalign) end,
    GetFontHeight = function(font) end,
    NoTexture = function() end,
    RoundedBoxEx = function(radius, x, y, width, height, color, topleft, topright, bottomleft, bottomright) end,
    RoundedBox = function(radius, x, y, width, height, color) end,

    --> Avoid using this
    Text = function(textdata) end,

    --> Avoid using this
    TextShadow = function(textdata, distance, alpha) end,

    TexturedQuad = function(texturedata) end,
    WordBox = function(bordersize, x, y, text, font, boxcolor, textcolor, xalign, yalign) end
}

string = {
    ToTable = function(str) end,
    Explode = function(separator, str, withpattern) end,
    Split = function(str, separator) end,
    StartsWith = function(str, start) end,
    EndsWith = function(str, endstr) end,
    Replace = function(str, tofind, toreplace) end
}

math = {
    Round = function(number, idp) end,
    Clamp = function(number, low, high) end,
    Rand = function(low, high) end,
    IsNearlyEqual = function(a, b, tolerance) end,
    DistanceSqr = function(x1, y1, x2, y2) end,
    Distance = function(x1, y1, x2, y2) end,
    Dist = function(x1, y1, x2, y2) end
}

hook = {
    list = {}, --> event table

    --> Registers a callback with the given identifier to be called before the regular lua callback is executed
    --> If an identifier is not passed, one will be generated and returned
    pre = function(event, identifier, callback) end, 

    --> Registers a callback with the given identifier to be called after the regular lua callback is executed
    --> If an identifier is not passed, one will be generated and returned
    post = function(event, identifier, callback) end,
    
    --> Alias for hook.pre
    before = function(event, identifier, callback) end,

    --> Alias for hook.post
    after = function(event, identifier, callback) end,

    --> Removes an event registered with hook.pre or hook.before using its identifier
    removepre = function(event, identifier) end, 

    --> Removes an event registered with hook.post or hook.after using its identifier
    removepost = function(event, identifier) end,

    --> Alias for hook.removepre
    removebefore = function(event, identifier) end,

    --> Alias for hook.removepost
    removeafter = function(event, identifier) end,

    --> Executes all callbacks registered to the given event with hook.pre
    callpre = function(event, ...) end,

    --> Executes all callbacks registered to the given event with hook.post
    callpost = function(event, ...) end,
}

cam = {
    Start2D = function() end,
    Start3D = function(pos, ang, fov, x, y, w, h, znear, zfar) end
}

_G = {
    Color = function(r, g, b, a) end,
    IsValid = function(obj) end,
    LocalPlayer = function() end,
    ScrW = function() end,
    ScrH = function() end
}

player = {
    --> Do not modify the value returned by this as it is internally cached for speed purposes
    GetAll = function() end,

    GetCount = function() end
}

ents = {
    --> Do not modify the value returned by this as it is internally cached for speed purpose
    GetAll = function() end,

    --> Returns the number of entities on the server - unlike the normal version, includekillme is true by default for speed purposes (this may be reversed in a future update if the efficiency can be kept)
    GetCount = function(includekillme) end
}

file = {
    Read = function(filename, path) end,
    Write = function(filename, contents) end,
    Append = function(filename, contents) end
}

timer = {
    Adjust = function(identifier, delay, repetitions, func) end,
    Check = function() end,
    Create = function(identifier, delay, repetitions, func),
    Destroy = function(identifier) end,
    Exists = function(identifier) end,
    IsPaused = function(identifier) end,
    Pause = function(identifier) end,
    Remove = function(identifier) end,
    RepsLeft = function(identifier) end,
    Simple = function(identifier, func) end,
    Start = function(identifier) end,
    Stop = function(identifier) end,
    TimeLeft = function(identifier) end,
    Toggle = function(identifier) end,
    UnPause = function(identifier) end,
}

team = {
    GetColor = function(index) end,
    GetName = function(index) end,
    GetPlayers = function(index) end,
    NumPlayers = function(index) end
}

lje.util = {
    --> A render target which is safe to render on since it is invisible to screengrabs
    rendertarget = GetRenderTargetEx(...),

    --> An alias for lje.util.rendertarget
    rt = GetRenderTargetEx(...),

    --> Iterates over every player other than the local player, and calls the callback for each one, with the callback being passed the player as its only argument
    iterate_players = function(callback) end,

    --> Iterates over every NPC and calls the callback for each one, with the callback being passed the NPC as its only arguments
    iterate_npcs = function(callback) end,

    --> Generates a random string with the given length (32 by default)
    random_string = function(length) end,

    --> Equivalent to _G.Color(r, g, b, a), but is slightly faster as it does not check the validity of the arguments - all arguments must be specified
    color_strict = function(r, g, b, a) end,

    --> Equivalent to Entity:IsPlayer() - this should be used in niche situations where you cannot namecall and must for example do this: _R.Entity.IsPlayer(entity) - since this would give invalid results
    is_player = function(entity) end,

    --> Equivalent to Entity:IsNPC() - this should be used in niche situations where you cannot namecall and must for example do this: _R.Entity.IsNPC(entity) - since this would give invalid results
    is_npc = function(entity) end,

    --> Equivalent to player.GetAll(), however the return value can be modified as it is not cached
    get_mutable_players = function() end,

    --> Equivalent to ents.GetAll(), however the return value can be modified as it is not cached
    get_mutable_entities = function() end,

    --> Allows you to render a 3D thing to the entire screen without messing up the depth of it - for example, this should be called before you re-render the scene for a freecam
    override_blend = function() end,

    --> Sets up the view matrix for future calls to lje.util.world_to_screen - this should be called every frame prior to using the world-to-screen functions - this requires a 3D rendering context to be active
    setup_viewmatrix = function() end,

    --> Performs a world-to-screen calculation using the given coordinates - this is faster than calling Vector:ToScreen() as it does not allocate a new ToScreenData table for each call - this returns the x and y coordinates, as well as whether or not the point is visible
    world_to_screen = function(x, y, z) end,

    --> Equivalent to world_to_screen, but takes a vector instead of the raw coordinates
    world_to_screen_vector = function(vector) end
}

lje.input = {
    --> These functions can only be called in 'lje-util/input' hooks
    --> This library is used for safe mouse input - later on I will add FFI support for proper mouse movement, and will support keyboard input

    --> Sets the desired eye angles to the given angle
    setangle = function(angle) end,

    --> Returns the desired eye angles
    getangle = function() end,

    --> Adds the given angle to the desired eye angles
    sendangle = function(delta) end
}

lje.media = {
    --> The lje.media API is currently non-functional as LJE does not have a file-system - currently the file system reading functions within it simply use file.Read which means that it cannot actually load external media

    --> Loads external media (sounds, images, etc) from the given path in the LJE filesystem - the callback is passed the virtual path of the media once it has been loaded - lje.media.load returns whether or not it was successful, as well as the value returned by the callback
    load = function(path, callback) end, --> loads media (sounds, images, etc) from the given path in the lje filesystem - the callback is passed the virtual path of the media once it has been written to the data folder - the function returns whether or not it was successful, and the value returned by the callback
}
```