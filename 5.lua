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