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