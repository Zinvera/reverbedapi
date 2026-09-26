assert(getscriptbytecode, "exploit does not support getscriptbytecode.")

local httprequest = request or http_request or (syn and syn.request)
assert(httprequest, "exploit does not support http requests.")

local httpservice = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")

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
    local res
    for attempt = 1, 3 do
        local sent, result = pcall(httprequest, {
            Url = base .. "/decompile/" .. httpservice:UrlEncode(key),
            Method = "POST",
            Headers = {
                ["content-type"] = "application/octet-stream"
            },
            Body = bytecode
        })
        res = sent and result or nil
        if res and res.StatusCode ~= 503 then
            break
        end
        task.wait(0.5 * attempt)
    end

    if not res or res.StatusCode ~= 200 then
        return "-- api request error" .. (res and " (" .. tostring(res.StatusCode) .. ")" or "")
            .. "\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
    end

    return res.Body
end
