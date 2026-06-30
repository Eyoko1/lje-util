local SysTime = SysTime

local randomstringcharacters = {" ", "!", "#", "$", "%", "&", "+", ",", "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "^", "_", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
local randomstringcharactercount = #randomstringcharacters
local rstringtable = lje.util.create_table(128, 0)
local math_random = math.random
local table_concat = table.concat
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
function lje.util.__random_string(length)
    length = length or 32
    if (length <= 0) then
        return ""
    end

    for i = 1, length do
        rstringtable[i] = randomstringcharacters[math_random(1, randomstringcharactercount)]
    end

    return table_concat(rstringtable, "", 1, length)
end

local benchmarkqueue = {}

local isfirst = true
local f1delta = 0
local f2delta = 0
local f1name = ""
local f2name
local function benchmarkhandler()
    local data = table.remove(benchmarkqueue, 1)
    local func, name, count, a, b, c, d, e, f = data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9]

    local i = 1
    local start = SysTime()
    ::run_f1::
    func(a, b, c, d, e, f)
    if (i ~= count) then
        i = i + 1
        goto run_f1
    end
    local stop = SysTime()

    local delta = stop - start
    lje.con_printf("\t%.3fs", delta)
    if (isfirst) then
        f1delta = delta
        f1name = name
        isfirst = false
        timer.Simple(0.1, benchmarkhandler)
    else
        f2delta = delta
        f2name = name
        if (f2delta < f1delta) then
            lje.con_printf("%s is %.3fx faster than %s", f2name, f1delta / f2delta, f1name)
        else
            lje.con_printf("%s is %.3fx faster than %s", f1name, f2delta / f1delta, f2name)
        end
        --lje.con_printf("\t%.3fs ; %.3fs", f1delta, f2delta)

        if (#benchmarkqueue > 0) then
            isfirst = true
            timer.Simple(0.1, benchmarkhandler)
        end
    end
end

local function benchmark(f1, n1, f2, n2, args, count)
    if (not args) then
        args = {}
    end
    if (not count) then
        count = 1e6
    end

    local a, b, c, d, e, f = args[1], args[2], args[3], args[4], args[5], args[6]

    table.insert(benchmarkqueue, {f1, n1, count, a, b, c, d, e, f})
    table.insert(benchmarkqueue, {f2, n2, count, a, b, c, d, e, f})
end

local function printtable(tbl)
    for i, v in pairs(tbl) do
        lje.con_printf("%s = %s", i, v)
    end
end

timer.Simple(0.3, function()
    local teststring = "abababababababababababababababababababababab_abcabcabcabcabcabcabcabcabcabcabcabc_cbcbcbcbcbcbcbcbcbcbcbcbc"
    --benchmark(_G.string.Split, "string.Split (Base)", string.Split, "string.Split (lje-util)", {teststring, "b"}, 1e7)
    --benchmark(_G.string.StartsWith, "string.StartsWith (Base)", string.StartsWith, "string.StartsWith (lje-util)", {teststring, "b"})
    --benchmark(_G.string.EndsWith, "string.EndsWith (Base)", string.EndsWith, "string.EndsWith (lje-util)", {teststring, "b"})
    --benchmark(_G.string.ToTable, "string.ToTable (Base)", string.ToTable, "string.ToTable (lje-util)", {teststring}, 2e5)
    --benchmark(_G.player.GetAll, "player.GetAll (Base)", player.GetAll, "player.GetAll (lje-util)", {}, 1e6)
    --benchmark(_G.player.GetCount, "player.GetCount (Base)", player.GetCount, "player.GetCount (lje-util)", {}, 1e6)
    --benchmark(_G.Color, "Color (Base)", Color, "Color (lje-util)", {255, 255, 255, 255}, 1e6)
    --benchmark(_G.Color, "Color (Base)", lje.util.color_strict, "lje.util.color_strict (lje-util)", {255, 255, 255, 255}, 1e6)
    benchmark(lje.util.random_string, "lje.util.random_string (Old)", lje.util.__random_string, "lje.util.random_string (New)", {32}, 1e6)

    --benchmark(_G.draw.DrawText, "draw.DrawText (Base)", draw.DrawText, "draw.DrawText (lje-util)", {"test\n\t\n", "DermaDefault", 0, 0, color_white, TEXT_ALIGN_LEFT}, 1e6)
    
    benchmarkhandler()
end)