--> [input.lua] <--
--> Adds functions for safely changing viewangles with CUserCmd handles <--

local _R = lje.util.get_registry()

local CONVAR = _R.ConVar
local CUSERCMD = _R.CUserCmd
local ANGLE = _R.Angle

local math_ceil = math.ceil
local rawequal = rawequal
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

--> Sets the desired eye angles to the given angle
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
--- @return Angle
function lje.input.getangle()
    if (not hasinputcontext) then
        nonhalting("lje.input.* functions can only be called in 'lje-util/input' hooks!")
        return blankangle
    end

    return desiredangle
end

--> Adds the given delta angle to the desired angle
--- @param delta Angle
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

    local viewp = viewangles[1]
    local viewy = viewangles[2]
    desiredangle[1] = viewp
    desiredangle[2] = viewy
    desiredangle[3] = viewangles[3]

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