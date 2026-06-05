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