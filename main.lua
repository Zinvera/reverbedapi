assert(getscriptbytecode, "exploit does not support getscriptbytecode.")

  local httprequest = request or http_request or (syn and syn.request)
  assert(httprequest, "exploit does not support http requests.")

  local httpservice = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")
  local last = 0

  getgenv().decompile = function(scr)
      local key = getgenv().REVERBED_KEY
      if type(key) ~= "string" or key == "" then
          return "-- no API key: set getgenv().REVERBED_KEY first at https://discord.gg/XDxU7a4nJU"
      end

      local ok, bytecode = pcall(getscriptbytecode, scr)
      if not ok then
          return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
      end
      if not bytecode or bytecode == "" then
          return "-- script has no bytecode"
      end

      local elapsed = os.clock() - last
      if elapsed < 0.12 then
          task.wait(0.12 - elapsed)
      end

      local base = getgenv().REVERBED_URL or "http://94.249.189.101"
      local res = httprequest({
          Url = base .. "/decompile/" .. httpservice:UrlEncode(key),
          Method = "POST",
          Headers = {
              ["content-type"] = "application/octet-stream"
          },
          Body = bytecode
      })

      last = os.clock()

      if not res or res.StatusCode ~= 200 then
          return "-- api request error" .. (res and " (" .. tostring(res.StatusCode) .. ")" or "")
              .. "\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
      end

      return res.Body
  end
