--> [input.lua] <--
--> Adds functions for safely changing viewangles with CUserCmd handles <--

local _R = lje.util.get_registry()

local CONVAR = _R.ConVar
local CUSERCMD = _R.CUserCmd
local ANGLE = _R.Angle

local math_ceil = math.ceil
local hook_callpre = hook.callpre
local hook_callpost = hook.callpost

local CUSERCMD_GetViewAngles = CUSERCMD.GetViewAngles
local CUSERCMD_SetViewAngles = CUSERCMD.SetViewAngles
local CUSERCMD_SetMouseX = CUSERCMD.SetMouseX
local CUSERCMD_SetMouseY = CUSERCMD.SetMouseY
local CUSERCMD_GetMouseX = CUSERCMD.GetMouseX
local CUSERCMD_GetMouseY = CUSERCMD.GetMouseY
local CONVAR_GetFloat = CONVAR.GetFloat
local ANGLE_Normalize = ANGLE.Normalize
local ANGLE_Unpack = ANGLE.Unpack
local ANGLE_SetUnpacked = ANGLE.SetUnpacked

local cv_sensitivity = GetConVar_Internal("sensitivity")
local cv_myaw = GetConVar_Internal("m_yaw")
local cv_mpitch = GetConVar_Internal("m_pitch")

local sensitivity = CONVAR_GetFloat(cv_sensitivity)
local myaw = CONVAR_GetFloat(cv_myaw)
local mpitch = CONVAR_GetFloat(cv_mpitch)

local blankangle = Angle(0, 0, 0)
local desiredangle = Angle(0, 0, 0)
local changedangle = false
local hasinputcontext = false

lje.input = {}

local function nonhalting(message)
    lje.con_printf("$red{lje-util error! : %s}")
end

if (ffi) then
    local MOUSEEVENTF_MOVE = 0x0001
    local MOUSEEVENTF_LEFTDOWN = 0x0002
    local MOUSEEVENTF_LEFTUP = 0x0004
    local MOUSEEVENTF_RIGHTDOWN = 0x0008
    local MOUSEEVENTF_RIGHTUP = 0x0010

    local user32 = ffi.module.find("user32.dll") --- @cast user32 -nil
    local SendInput = ffi.module.bind_export(user32, "SendInput", "uupi") --- @cast SendInput -nil
    local kernel32 = ffi.module.find("kernel32.dll") --- @cast kernel32 -nil
    local GetLastError = ffi.module.bind_export(kernel32, "GetLastError", "s") --- @cast GetLastError -nil

    ffi.struct.define([[
    struct LJE_UTIL_MOUSEINPUT {
        uint32_t type;
        padding[4];

        long dx;
        long dy;
        uint32_t mouseData;
        uint32_t dwFlags;
        uint32_t time;
        uintptr_t dwExtraInfo;
    };
    ]])

    local mousestructsize = ffi.mem.sizeof("LJE_UTIL_MOUSEINPUT")
    local mousestruct = ffi.mem.alloc(mousestructsize)
    local mousedata = {
        type = 0,
        dx = 0,
        dy = 0,
        mouseData = 0,
        dwFlags = MOUSEEVENTF_MOVE,
        time = 0,
        dwExtraInfo = 0
    }

    ffi.struct.define([[
    struct LJE_UTIL_KEYBOARDINPUT {
        uint32_t type;
        uint16_t wVk;
        uint16_t wScan;
        uint32_t dwFlags;
        uint32_t time;
        uintptr_t dwExtraInfo;
    };
    ]])

    local keyboardstructsize = ffi.mem.sizeof("LJE_UTIL_KEYBOARDINPUT")
    local keyboardstruct = ffi.mem.alloc(keyboardstructsize)
    local keyboarddata = {
        type = 1,
        wVk = 0,
        wScan = 0,
        dwFlags = 0,
        time = 0,
        dwExtraInfo = 0
    }

    local keys = {
        [KEY_BACKSPACE] = 0x08,
        [KEY_TAB] = 0x09,
        [KEY_ENTER] = 0x0D,
        [KEY_CAPSLOCK] = 0x14,
        [KEY_ESCAPE] = 0x1B,
        [KEY_SPACE] = 0x20,
        [KEY_PAGEUP] = 0x21,
        [KEY_PAGEDOWN] = 0x22,
        [KEY_END] = 0x23,
        [KEY_LEFT] = 0x25,
        [KEY_UP] = 0x26,
        [KEY_RIGHT] = 0x27,
        [KEY_DOWN] = 0x28,
        [KEY_INSERT] = 0x2D,
        [KEY_DELETE] = 0x2E,

        [KEY_LSHIFT] = 0xA0,
        [KEY_RSHIFT] = 0xA1,
        [KEY_LCONTROL] = 0xA2,
        [KEY_RCONTROL] = 0xA3,
        [KEY_LALT] = 0xA4,
        [KEY_RALT] = 0xA5,
    }

    --> '0' - '9'
    for i = 0, 9 do
        keys[KEY_0 + i] = 0x30 + i
    end

    --> 'A' - 'Z'
    for i = 0, 25 do
        keys[KEY_A + i] = 0x41 + i
    end

    --> 'NUMPAD 0' -> 'NUMPAD 9'
    for i = 0, 9 do
        keys[KEY_PAD_0 + i] = 0x60 + i
    end

    --> 'F1' -> 'F12'
    for i = 0, 11 do
        keys[KEY_F1 + i] = 0x70 + i
    end

    --> Moves the mouse by the given delta x and y using the SendInput Windows API function
    -->
    --> Requires lje-ffi in order to work
    --- @param deltax number
    --- @param deltay number
    --- @return nil
    function lje.input.sendmouse(deltax, deltay)
        mousedata.dx = deltax
        mousedata.dy = deltay
        mousedata.dwFlags = MOUSEEVENTF_MOVE

        ffi.struct.write(mousestruct, "LJE_UTIL_MOUSEINPUT", mousedata)
        SendInput(1, mousestruct, mousestructsize)
    end

    --> Presses the left mouse button (or the right mouse button if right is true)
    --- @param right boolean? If true then the right mouse button will be pressed
    --- @return nil
    function lje.input.mousedown(right)
        if (right) then
            mousedata.dwFlags = MOUSEEVENTF_RIGHTDOWN
        else
            mousedata.dwFlags = MOUSEEVENTF_LEFTDOWN
        end

        ffi.struct.write(mousestruct, "LJE_UTIL_MOUSEINPUT", mousedata)
        SendInput(1, mousestruct, mousestructsize)
    end

    --> Releases the left mouse button (or the right mouse button if right is true)
    --- @param right boolean? If true the right mouse button will be pressed
    --- @return nil
    function lje.input.mouseup(right)
        if (right) then
            mousedata.dwFlags = MOUSEEVENTF_RIGHTUP
        else
            mousedata.dwFlags = MOUSEEVENTF_LEFTUP
        end

        ffi.struct.write(mousestruct, "LJE_UTIL_MOUSEINPUT", mousedata)
        SendInput(1, mousestruct, mousestructsize)
    end

    --> Presses the given key
    --- @param key KEY | string This can either be a KEY_* enum, or a string which is the keycode
    function lje.input.keydown(key)
        if (type(key) == "string") then
            key = input.GetKeyCode(key)
        end

        local vk = keys[key]
        if (not vk) then
            nonhalting("lje.input.keydown called with invalid key: '" .. tostring(key) .. "'")
            return
        end

        keyboarddata.wVk = vk
        keyboarddata.dwFlags = 0
        ffi.struct.write(keyboardstruct, "LJE_UTIL_KEYBOARDINPUT", keyboarddata)
        SendInput(1, keyboardstruct, keyboardstructsize)
    end

    --> Releases the given key
    --- @param key KEY | string This can either be a KEY_* enum, or a string which is the keycode
    function lje.input.keyup(key)
        if (type(key) == "string") then
            key = input.GetKeyCode(key)
        end

        local vk = keys[key]
        if (not vk) then
            nonhalting("lje.input.keyup called with invalid key: '" .. tostring(key) .. "'")
            return
        end

        keyboarddata.wVk = vk
        keyboarddata.dwFlags = 0x0002
        ffi.struct.write(keyboardstruct, "LJE_UTIL_KEYBOARDINPUT", keyboarddata)
        SendInput(1, keyboardstruct, keyboardstructsize)
    end
end

--> Sets the desired eye angles to the given angle
-->
--> (DEPRECATED) lje.input.* ffi functions should be preferred over this
--- @param angle Angle
--- @return nil
function lje.input.setangle(angle)
    if (not hasinputcontext) then
        nonhalting("lje.input.* functions can only be called in 'lje-util/input' hooks!")
        return
    end

    desiredangle[1] = angle[1]
    desiredangle[2] = angle[2]
    --desiredangle[3] = angle[3]
    changedangle = true
end

--> Returns the desired eye angles
-->
--> (DEPRECATED) lje.input.* ffi functions should be preferred over this
--- @return Angle
function lje.input.getangle()
    if (not hasinputcontext) then
        nonhalting("lje.input.* functions can only be called in 'lje-util/input' hooks!")
        return blankangle
    end

    return desiredangle
end

--> Adds the given delta angle to the desired angle
-->
--> (DEPRECATED) lje.input.* ffi functions should be preferred over this
--- @param delta Angle
--- @return nil
function lje.input.sendangle(delta)
    if (not hasinputcontext) then
        nonhalting("lje.input.* functions can only be called in 'lje-util/input' hooks!")
        return
    end

    desiredangle[1] = math.Clamp(desiredangle[1] + delta[1], -89, 89)
    desiredangle[2] = desiredangle[2] + delta[2]

    ANGLE_Normalize(desiredangle)

    changedangle = true
end

hook.pre("StartCommand", "__lje_util_input", function(_, cmd)
    sensitivity = CONVAR_GetFloat(cv_sensitivity)
    myaw = CONVAR_GetFloat(cv_myaw)
    mpitch = CONVAR_GetFloat(cv_mpitch)

    local viewangles = CUSERCMD_GetViewAngles(cmd)

    local viewp, viewy, viewr = ANGLE_Unpack(viewangles)
    ANGLE_SetUnpacked(
        desiredangle,
        viewp,
        viewy,
        viewr
    )

    hasinputcontext = true
    hook_callpre("lje-util/input", cmd)
    hasinputcontext = false

    if (changedangle) then
        changedangle = false
        CUSERCMD_SetViewAngles(cmd, desiredangle)
        local x = CUSERCMD_GetMouseX(cmd)
        local y = CUSERCMD_GetMouseY(cmd)
        CUSERCMD_SetMouseX(cmd, x - math_ceil((desiredangle[2] - viewy) / (sensitivity * myaw)))
        CUSERCMD_SetMouseY(cmd, y + math_ceil((desiredangle[1] - viewp) / (sensitivity * mpitch)))
    end

    hook_callpost("lje-util/input", cmd)
end)