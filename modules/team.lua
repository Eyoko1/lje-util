--> [team.lua] <--
--> Adds some team.* functions <--

--> This is not guaranteed to work since some servers / anticheats can edit the team table in a way that prevents this from working

--- @TODO: Perform some form of pattern scanning in an attempt to prevent this from breaking due to additional upvalues in the function we search for the teams table

team = {}

local defaultcolor = Color(255, 255, 100, 255)

local teaminfopath = lje.state.path(lje.state.client, "team"):index("GetAllTeams"):upvalue(1)
local teaminfo = teaminfopath:copy()

local function verifyteaminfo()
    if (not teaminfo) then
        teaminfo = teaminfopath:copy()
        if (not teaminfo) then
            return false
        end
    end

    return true
end

--- @param index integer
--- @return Color
function team.GetColor(index)
    if (not verifyteaminfo()) then
        return Color(defaultcolor.r, defaultcolor.g, defaultcolor.b, defaultcolor.a)
    end

    local color = teaminfo[index].Color or defaultcolor
    return Color(color.r, color.g, color.b, color.a)
end

--- @param index integer
--- @return string
function team.GetName(index)
    if (not verifyteaminfo()) then
        return ""
    end

    return teaminfo[index].Name or ""
end

--- @param index integer
--- @return Player[]
function team.GetPlayers(index)
    if (not verifyteaminfo()) then
        return {}
    end

    local players = {}
    for i, v in ipairs(player.GetAll()) do
        if (v:Team() == index) then
            table.insert(players, v)
        end
    end
    return players
end

--- @param index integer
--- @return integer
function team.NumPlayers(index)
    if (not verifyteaminfo()) then
        return 0
    end

    local count = 0
    for i, v in ipairs(player.GetAll()) do
        if (v:Team() == index) then
            count = count + 1
        end
    end
    return count
end

local lastteamrefresh = SysTime()
hook.pre("Think", "__lje_util_teams", function()
    local time = SysTime()
    if (time - lastteamrefresh < 2) then --> Refresh teams every 2 seconds
        return
    end

    teaminfo = teaminfopath:copy()
end)