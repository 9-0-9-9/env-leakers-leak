local function safe_call(description, func)
    local success, result = pcall(func)
    if success then
        print(string.format("[OK] %s â†’ %s", description, tostring(result or "nil")))
        return true, result
    else
        warn(string.format("[FAIL] %s â†’ %s", description, tostring(result)))
        return false, result
    end
end

-- Storage for found source pieces
local source_candidates = {}  -- key = description, value = string or table