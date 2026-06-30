--> [draw.lua] <--
--> Reimplements every draw.* function <--
--> Functions in the draw.* library are expensive so avoid using them <--

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextPos = surface.SetTextPos
local surface_SetTextColor = surface.SetTextColor
local surface_DrawText = surface.DrawText
local surface_SetTexture = surface.SetTexture
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_DrawTexturedRectUV = surface.DrawTexturedRectUV
local string_find = string.find
local string_sub = string.sub
local math_ceil = math.ceil
local tostring = tostring

local TEXT_ALIGN_LEFT = 0
local TEXT_ALIGN_CENTER = 1
local TEXT_ALIGN_RIGHT = 2
local TEXT_ALIGN_TOP = 3
local TEXT_ALIGN_BOTTOM = 4

local tabwidth = 50

local white = lje.util.color_strict(255, 255, 255, 255)

local draw = {
    SimpleText = function(text, font, x, y, color, xalign, yalign) end,
    SimpleTextOutlined = function(text, font, x, y, color, xalign, yalign, outlinewidth, outlinecolor) end,
    DrawText = function(text, font, x, y, color, xalign) end,
    GetFontHeight = function(font) end,
    NoTexture = function() end,
    RoundedBoxEx = function(radius, x, y, width, height, color, topleft, topright, bottomleft, bottomright) end,
    RoundedBox = function(radius, x, y, width, height, color) end,
    Text = function(textdata) end, --> do not use this unless it is absolutely necessary
    TextShadow = function(textdata, distance, alpha) end, --> do not use this unless it is absolutely necessary
    TexturedQuad = function(texturedata) end, --> do not use this unless it is absolutely necessary
    WordBox = function(bordersize, x, y, text, font, boxcolor, textcolor, xalign, yalign) end
}
_G.draw = draw

function draw.SimpleText(text, font, x, y, colour, xalign, yalign)
    text = tostring(text)
    -- who doesn't provide these?
    --x = x or 0
    --y = y or 0

    surface_SetFont(font or "DermaDefault")

    local width, height = surface_GetTextSize(text)
    if (xalign == 1--[[TEXT_ALIGN_CENTER]]) then
        x = x - (width * 0.5)
    elseif (xalign == 2--[[TEXT_ALIGN_RIGHT]]) then
        x = x - width
    end
    if (yalign == 1--[[TEXT_ALIGN_CENTER]]) then
        y = y - (height * 0.5)
    elseif (yalign == 4--[[TEXT_ALIGN_BOTTOM]]) then
        y = y - height
    end

    surface_SetTextPos(x, y)

    if (colour) then
        surface_SetTextColor(colour.r, colour.g, colour.b, colour.a)
    else
        surface_SetTextColor(255, 255, 255, 255)
    end

    surface_DrawText(text)

    return width, height
end

function draw.SimpleTextOutlined(text, font, x, y, colour, xalign, yalign, outlinewidth, outlinecolour)
    text = tostring(text)
    -- who doesn't provide these?
    --x = math_ceil(x or 0)
    --y = math_ceil(y or 0)
    --colour = colour or white
    --xalign = xalign or TEXT_ALIGN_LEFT
    --yalign = yalign or TEXT_ALIGN_TOP
    x = x + 1 - (x % 1)
    y = y + 1 - (y % 1)

    local steps = (outlinewidth * 2) / 3
    if (steps < 1) then
        steps = 1
    end

    surface_SetFont(font or "DermaDefault")

    local width, height = surface_GetTextSize(text)
    if (xalign == 1--[[TEXT_ALIGN_CENTER]]) then
        x = x - (width * 0.5)
    elseif (xalign == 2--[[TEXT_ALIGN_RIGHT]]) then
        x = x - width
    end
    if (yalign == 1--[[TEXT_ALIGN_CENTER]]) then
        y = y - (height * 0.5)
    elseif (yalign == 4--[[TEXT_ALIGN_BOTTOM]]) then
        y = y - height
    end

    surface_SetTextColor(outlinecolour)

    local outlinewidthx = outlinewidth + x
    local outlinewidthy = outlinewidth + y

    local xcache = x - outlinewidth
    local resety = y - outlinewidth
    ::outlinex::
    local ycache = resety
    ::outliney::
    surface_SetTextPos(xcache, ycache)
    surface_DrawText(text)
    if (ycache < outlinewidthy) then
        ycache = ycache + steps
        goto outliney
    end
    if (xcache < outlinewidthx) then
        xcache = xcache + steps
        ycache = resety
        goto outlinex
    end

    surface_SetTextPos(x, y)
    surface_SetTextColor(colour)
	surface_DrawText(text)

    return width, height
end

local cachednlheights = {}
local function __getcachednlheight(font)
    local _, height = surface_GetTextSize("\n")
    height = height * 0.5
    cachednlheights[font] = height
    return height
end

local function __drawtext(text, x, y, xalign)
    local size = surface_GetTextSize(text)
    if (xalign == 1--[[TEXT_ALIGN_CENTER]]) then
        x = x - (size * 0.5)
    elseif (xalign == 2--[[TEXT_ALIGN_RIGHT]]) then
        x = x - size
    end

    surface_SetTextPos(x, y)
    surface_DrawText(text)

    return size
end

function draw.DrawText(text, font, x, y, colour, xalign)
    -- When would anyone ever not pass these arguments?
    text = tostring(text)

    surface_SetFont(font)
    local lineheight = cachednlheights[font] or __getcachednlheight(font)

    local currentx = x
    local currenty = y

    surface_SetTextColor(colour or white)

    local i = 1
    ::outer::
    local nextnewline = string_find(text, "\n", i)
    local substring = string_sub(text, i, nextnewline)

    local j = 1
    ::inner::
    local nexttab = string_find(substring, "\t", j)
    if (nexttab) then
        if (nexttab ~= j) then
            currentx = currentx + __drawtext(string_sub(substring, j, nexttab), currentx, currenty, xalign)
        end

        j = nexttab + 1
        currentx = currentx + 50--[[tabwidth]]
        goto inner
    else
        __drawtext(string_sub(substring, j), currentx, currenty, xalign)
        -- Fall through
    end

    if (nextnewline) then
        i = nextnewline + 1
        currentx = x
        currenty = currenty + lineheight
        goto outer
    end
end

local cachedheights = {}
local function __getcachedheight(font)
    surface_SetFont(font)
    local _, height = surface_GetTextSize("W")
    cachedheights[font] = height

    return height
end

function draw.GetFontHeight(font)
    return cachedheights[font] or __getcachedheight(font)
end

local blanktexture = surface.GetTextureID("vgui/white")
function draw.NoTexture()
    surface_SetTexture(blanktexture)
end

local corner8 = surface.GetTextureID("gui/corner8")
local corner16 = surface.GetTextureID("gui/corner16")
local corner32 = surface.GetTextureID("gui/corner32")
local corner64 = surface.GetTextureID("gui/corner64")
local corner512 = surface.GetTextureID("gui/corner512")
function draw.RoundedBoxEx(bordersize, x, y, width, height, color, topleft, topright, bottomleft, bottomright)
    surface_SetDrawColor(color.r, color.g, color.b, color.a)

    if (bordersize <= 0) then
        surface_DrawRect(x, y, width, height)
        return
    end
    
    -- This can be simplified but it doesn't matter and has no effect on performance
    if (width < height) then
        if (width < bordersize) then
            bordersize = width * 0.5
            bordersize = bordersize - (bordersize % 1)
        else
            bordersize = bordersize - (bordersize % 1)
        end
    else
        if (height < bordersize) then
            bordersize = height * 0.5
            bordersize = bordersize - (bordersize % 1)
        else
            bordersize = bordersize - (bordersize % 1)
        end
    end

    local twobordersize = bordersize * 2
    surface_DrawRect(x + bordersize, y, width - twobordersize, height)
    surface_DrawRect(x, y + bordersize, bordersize, height - twobordersize)
    surface_DrawRect(x + width - bordersize, y + bordersize, bordersize, height - twobordersize)

    local texture = corner8
    if (bordersize > 64) then
        texture = corner512
    elseif (bordersize > 32) then
        texture = corner64
    elseif (bordersize > 16) then
        texture = corner32
    elseif (bordersize > 8) then
        texture = corner16
    end

    surface_SetTexture(texture)

    if (topleft) then
        surface_DrawTexturedRectUV(x, y, bordersize, bordersize, 0, 0, 1, 1)
    else
        surface_DrawRect(x, y, bordersize, bordersize)
    end

    if (topright) then
        surface_DrawTexturedRectUV(x + width - bordersize, y, bordersize, bordersize, 1, 0, 0, 1)
    else
        surface_DrawRect(x + width - bordersize, y, bordersize, bordersize)
    end

    if (bottomleft) then
        surface_DrawTexturedRectUV(x, y + height - bordersize, bordersize, bordersize, 0, 1, 1, 0)
    else
        surface_DrawRect(x, y + height - bordersize, bordersize, bordersize)
    end

    if (bottomright) then
        surface_DrawTexturedRectUV(x + width - bordersize, y + height - bordersize, bordersize, bordersize, 1, 1, 0, 0)
    else
        surface_DrawRect(x + width - bordersize, y + height - bordersize, bordersize, bordersize)
    end
end

function draw.RoundedBox(bordersize, x, y, width, height, color)
    surface_SetDrawColor(color.r, color.g, color.b, color.a)

    if (bordersize <= 0) then
        surface_DrawRect(x, y, width, height)
        return
    end
    
    -- This can be simplified but it doesn't matter and has no effect on performance
    if (width < height) then
        if (width < bordersize) then
            bordersize = width * 0.5
            bordersize = bordersize - (bordersize % 1)
        else
            bordersize = bordersize - (bordersize % 1)
        end
    else
        if (height < bordersize) then
            bordersize = height * 0.5
            bordersize = bordersize - (bordersize % 1)
        else
            bordersize = bordersize - (bordersize % 1)
        end
    end

    local twobordersize = bordersize * 2
    surface_DrawRect(x + bordersize, y, width - twobordersize, height)
    surface_DrawRect(x, y + bordersize, bordersize, height - twobordersize)
    surface_DrawRect(x + width - bordersize, y + bordersize, bordersize, height - twobordersize)

    local texture = corner8
    if (bordersize > 64) then
        texture = corner512
    elseif (bordersize > 32) then
        texture = corner64
    elseif (bordersize > 16) then
        texture = corner32
    elseif (bordersize > 8) then
        texture = corner16
    end

    surface_SetTexture(texture)

    surface_DrawTexturedRectUV(x, y, bordersize, bordersize, 0, 0, 1, 1)
    surface_DrawTexturedRectUV(x + width - bordersize, y, bordersize, bordersize, 1, 0, 0, 1)
    surface_DrawTexturedRectUV(x, y + height - bordersize, bordersize, bordersize, 0, 1, 1, 0)
    surface_DrawTexturedRectUV(x + width - bordersize, y + height - bordersize, bordersize, bordersize, 1, 1, 0, 0)
end

local SimpleText = draw.SimpleText
function draw.Text(textdata)
    local pos = textdata.pos
    return SimpleText(textdata.text, textdata.font, pos[1], pos[2], textdata.color, textdata.xalign, textdata.yalign)
end

local textshadowcolor = Color(0, 0, 0, 200)
function draw.TextShadow(textdata, distance, alpha)
    -- The calls to draw.Text have been inlined to improve performance
    local text = textdata.text
    local font = textdata.font
    local pos = textdata.pos
    local x = pos[1]
    local y = pos[2]
    local xalign = textdata.xalign
    local yalign = textdata.yalign
    textshadowcolor.a = alpha or 200
    SimpleText(
        text,
        font,
        x + distance,
        y + distance,
        textshadowcolor,
        xalign,
        yalign
    )
    return SimpleText(
        text, font,
        x,
        y,
        textdata.color,
        xalign,
        yalign
    )
end

function draw.TexturedQuad(texturedata)
    local color = texturedata.color or white
    surface_SetTexture(texturedata.texture)
    surface_SetDrawColor(color.r, color.g, color.b, color.a)
    surface_DrawTexturedRect(texturedata.x, texturedata.y, texturedata.w, texturedata.h)
end

local RoundedBox = draw.RoundedBox
function draw.WordBox(bordersize, x, y, text, font, color, fontcolor, xalign, yalign)
    surface_SetFont(font)
    local width, height = surface_GetTextSize(text)

    if (xalign == 1--[[TEXT_ALIGN_CENTER]]) then
		x = x - (bordersize + width / 2)
	elseif (xalign == 2--[[TEXT_ALIGN_RIGHT]]) then
		x = x - (bordersize * 2 + width)
	end

	if (yalign == 1--[[TEXT_ALIGN_CENTER]]) then
		y = y - (bordersize + height / 2)
	elseif (yalign == 4--[[TEXT_ALIGN_BOTTOM]]) then
		y = y - (bordersize * 2 + height)
	end

    local twobordersize = bordersize * 2

    RoundedBox(bordersize, x, y, width + twobordersize, height + twobordersize, color)

    surface_SetTextColor(fontcolor.r, fontcolor.g, fontcolor.b, fontcolor.a)
    surface_SetTextPos(x + bordersize, y + bordersize)
    surface_DrawText(text)

    return width + twobordersize, height + twobordersize
end