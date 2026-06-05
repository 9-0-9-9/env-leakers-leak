print("[STEP 5] Enumerating stack frames for sources...")
for level = 1, 20 do
    local ok, info = pcall(debug.getinfo, level, "S")
    if not ok or not info then break end
    if info.source and info.source:sub(1,1) ~= "=" then
        source_candidates["stack_" .. level] = info.source
        print(string.format("  Stack %d: %s (linedefined %d)", level, info.source, info.linedefined or 0))
    end
end