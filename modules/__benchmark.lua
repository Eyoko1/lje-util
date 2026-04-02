local SysTime = SysTime
local function benchmark(f1, n1, f2, n2, args, count)
    if (not args) then
        args = {}
    end
    if (not count) then
        count = 1e6
    end

    local a, b, c, d, e, f = args[1], args[2], args[3], args[4], args[5], args[6]

    local i = 1
    
    local f1start = SysTime()
    ::run_f1::
    f1(a, b, c, d, e, f)
    if (i ~= count) then
        i = i + 1
        goto run_f1
    end
    local f1end = SysTime()

    i = 1

    local f2start = SysTime()
    ::run_f2::
    f2(a, b, c, d, e, f)
    if (i ~= count) then
        i = i + 1
        goto run_f2
    end
    local f2end = SysTime()

    local f1delta = f1end - f1start
    local f2delta = f2end - f2start

    if (f2delta < f1delta) then
        lje.con_printf("%s is %.3fx faster than %s", n2, f1delta / f2delta, n1)
    else
        lje.con_printf("%s is %.3fx faster than %s", n1, f2delta / f1delta, n2)
    end
end

local function printtable(tbl)
    for i, v in pairs(tbl) do
        lje.con_printf("%s = %s", i, v)
    end
end

timer.Simple(0.3, function()
    local teststring = "abababababababababababababababababababababab_abcabcabcabcabcabcabcabcabcabcabcabc_cbcbcbcbcbcbcbcbcbcbcbcbc"
    benchmark(_G.string.Split, "string.Split (Base)", string.Split, "string.Split (ljeutil)", {teststring, "b"})
    benchmark(_G.string.StartsWith, "string.StartsWith (Base)", string.StartsWith, "string.StartsWith (ljeutil)", {teststring, "b"})
    benchmark(_G.string.EndsWith, "string.EndsWith (Base)", string.EndsWith, "string.EndsWith (ljeutil)", {teststring, "b"})
    benchmark(_G.string.ToTable, "string.ToTable (Base)", string.ToTable, "string.ToTable (ljeutil)", {teststring}, 2e5)
    benchmark(_G.player.GetAll, "player.GetAll (Base)", player.GetAll, "player.GetAll (ljeutil)", {}, 1e6)
    benchmark(_G.player.GetCount, "player.GetCount (Base)", player.GetCount, "player.GetCount (ljeutil)", {}, 1e6)
    benchmark(_G.Color, "Color (Base)", Color, "Color (ljeutil)", {255, 255, 255, 255}, 1e6)
    benchmark(_G.Color, "Color (Base)", lje.util.color_strict, "lje.util.color_strict (ljeutil)", {255, 255, 255, 255}, 1e6)

    --> Drawing library tests are inaccurate since the calls get more expensive as more things are drawn - the second function to be called is always the slowest
    --benchmark(_G.draw.DrawText, "draw.DrawText (Base)", draw.DrawText, "draw.DrawText (ljeutil)", {"test\n\t\n", "DermaDefault", 0, 0, color_white, TEXT_ALIGN_LEFT}, 1e3)
end)