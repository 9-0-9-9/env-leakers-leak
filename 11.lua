local host = gethostenv()

local real_req = host.require
local real_req_type = typeof(real_req)
print("host.require type: " .. real_req_type)

if real_req_type == "function" then
    local ok, fs = pcall(real_req, "@lune/fs")
    print("host require @lune/fs: " .. tostring(ok) .. " " .. typeof(fs))

    if ok and typeof(fs) == "table" then
        local ok2, entries = pcall(fs.readDir, ".")
        print("readDir .: " .. tostring(ok2))
        if ok2 and typeof(entries) == "table" then
            local count = #entries
            print("entries: " .. tostring(count))
            for i = 1, math.min(count, 10) do
                print("  " .. tostring(entries[i]))
            end
        end

        local ok3, content = pcall(fs.readFile, "main.luau") -- could be any file, just choose from what shows
        print("readFile: " .. tostring(ok3) .. " len=" .. tostring(#(content or "")))
    end
end