assert(getscriptbytecode, "exploit does not support getscriptbytecode.")

local httprequest = request or http_request or (syn and syn.request)
assert(httprequest, "exploit does not support http requests.")

local httpservice = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")

local TRIES = 3
local spare = 3

local function settingsHeader()
    local settings = getgenv().REVERBED_SETTINGS
    if type(settings) ~= "table" then
        return nil
    end
    local parts = {}
    for name, value in settings do
        if type(name) == "string" and type(value) == "boolean" then
            table.insert(parts, name .. "=" .. tostring(value))
        end
    end
    return #parts > 0 and table.concat(parts, ",") or nil
end

local function post(url, body, name)
    local id = httpservice:GenerateGUID(false)
    local answers, started, pending = {}, 0, 0
    local headers = {
        ["content-type"] = "application/octet-stream",
        ["x-request-id"] = id,
        ["x-reverbed-options"] = settingsHeader(),
        ["x-script-name"] = name and httpservice:UrlEncode(name) or nil
    }

    local function try()
        started += 1
        pending += 1
        task.spawn(function()
            local sent, res = pcall(httprequest, {
                Url = url,
                Method = "POST",
                Headers = headers,
                Body = body
            })
            pending -= 1
            table.insert(answers, sent and type(res) == "table" and res or false)
        end)
    end

    spare = math.min(3, spare + 0.1)
    local patience = math.min(4, 2.5 + #body / 200000)
    local waited, since, checked, last = 0, 0, 0, nil
    try()
    while true do
        while checked < #answers do
            checked += 1
            local res = answers[checked]
            if res and res.StatusCode ~= 503 then
                return res
            end
            last = res or last
        end
        if started < TRIES and checked == started then
            task.wait(0.5 * checked)
            try()
            since = 0
        elseif started < TRIES and since >= patience and spare >= 1 then
            spare -= 1
            try()
            since = 0
        elseif pending == 0 or waited >= 60 then
            return last
        end
        local dt = task.wait()
        waited += dt
        since += dt
    end
end

getgenv().decompile = function(scr)
    local key = getgenv().REVERBED_KEY
    if type(key) ~= "string" or key == "" then
        return "-- no API key: get one at https://discord.gg/XDxU7a4nJU and set getgenv().REVERBED_KEY"
    end

    local ok, bytecode = pcall(getscriptbytecode, scr)
    if not ok then
        return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
    end
    if not bytecode or bytecode == "" then
        return "-- script has no bytecode"
    end

    local base = getgenv().REVERBED_URL or "http://94.249.189.101"
    -- (the script's full name, like Workspace.Map.Door.Script, logged with the request for 24 hours)
    local named, name = pcall(function()
        return scr:GetFullName()
    end)
    local res = post(base .. "/decompile/" .. httpservice:UrlEncode(key), bytecode, named and name or nil)

    if not res or res.StatusCode ~= 200 then
        return "-- api request error" .. (res and " (" .. tostring(res.StatusCode) .. ")" or "")
            .. "\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
    end

    return res.Body
end
