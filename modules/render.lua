--> [render.lua] <--
--> Adds useful rendering utilities <--

local safertname = lje.util.random_string()
local safert = GetRenderTargetEx(
    safertname,
    ScrW(),
    ScrH(),
    RT_SIZE_FULL_FRAME_BUFFER,
    MATERIAL_RT_DEPTH_SHARED,
    bit.bor(16, 256, 32768),
    0,
    IMAGE_FORMAT_RGBA8888
)
local safertmaterial = CreateMaterial(
    lje.util.random_string(),
    "UnlitGeneric",
    {
        ["$basetexture"] = safertname,
        ["$translucent"] = 1
    }
)

lje.util.rendertarget = safert
lje.util.rt = safert

local cam2dtable = {type = "2D"}
local cam3dtable = {
    type = "3D",
    origin = Vector(0, 0, 0),
    angles = Angle(0, 0, 0),
    fov = 120,
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    aspect = 0
}

local cam_Start = cam.Start
function cam.Start2D()
    cam_Start(cam2dtable)
end

function cam.Start3D(pos, ang, fov, x, y, w, h, znear, zfar)
	cam3dtable.origin = pos
	cam3dtable.angles = ang
    cam3dtable.fov = fov or nil

    if (x and y and w and h) then
		cam3dtable.x = x
		cam3dtable.y = y
		cam3dtable.w = w
		cam3dtable.h = h
		cam3dtable.aspect = w / h
    elseif (cam3dtable.x) then
        cam3dtable.x = nil
        cam3dtable.y = nil
        cam3dtable.w = nil
        cam3dtable.h = nil
        cam3dtable.aspect = nil
	end

	if (znear and zfar) then
		cam3dtable.znear = znear
		cam3dtable.zfar	= zfar
	end

	return cam_Start(cam3dtable)
end

local overrideblend = false

--> Overrides the blend for the next frame - Used to correctly render depth to the screen, for example when drawing with render.RenderView
function lje.util.overrideblend()
    overrideblend = true
end

local BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD = 1, 0, 0
local render_IsTakingScreenshot = render.IsTakingScreenshot
local cam_Start2D = cam.Start2D
local render_PushRenderTarget = render.PushRenderTarget
local hook_callpre = hook.callpre
local render_OverrideBlend = render.OverrideBlend
local render_SetMaterial = render.SetMaterial
local render_DrawScreenQuad = render.DrawScreenQuad
local render_PopRenderTarget = render.PopRenderTarget
local hook_callpost = hook.callpost
local render_Clear = render.Clear
local cam_End2D = cam.End2D
hook.post("PostRender", "__safert", function()
    --> @TODO: Remove this once LJE gets a safer built-in rendering method
    if (render_IsTakingScreenshot()) then return end

    cam_Start2D()
        render_PushRenderTarget(safert)
            hook_callpre("lje-util/render")
            hook_callpre("lje-util/postrender")

            render_PushRenderTarget(nil) --> Push main frame buffer
                if (overrideblend) then
                    --> Override blend is used for fixing the depth of fullscreen renders
                    --> For example, when calling render.RenderView on the safe rendertarget, overrideblend should be set to true
                    render_OverrideBlend(true, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
                    render_SetMaterial(safertmaterial)
                    render_DrawScreenQuad()
                    render_OverrideBlend(false)
                    overrideblend = false
                else
                    render_SetMaterial(safertmaterial)
                    render_DrawScreenQuad()
                end
            render_PopRenderTarget()

            hook_callpost("lje-util/render")
            hook_callpost("lje-util/postrender")

            render_Clear(0, 0, 0, 0, true, true)
        render_PopRenderTarget()
    cam_End2D()
end)

render.PushRenderTarget(safert)
    render.Clear(0, 0, 0, 0, true, true)
render.PopRenderTarget()
