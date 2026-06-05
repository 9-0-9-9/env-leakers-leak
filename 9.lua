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