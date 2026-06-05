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