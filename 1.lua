local real_G = nil
local collected = {}

local env = getfenv(print)
if env and env._G then
    real_G = env._G
    _G.real_G = real_G
end

print("[Universal Reader] Starting full dump...")

local function readFile(path)
    if not real_G or not real_G.io or not real_G.io.open then return nil end
    local f = real_G.io.open(path, "rb")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return content
end

for level = 2, 20 do
    local info = debug.getinfo(level, "Sf")
    if info and info.source and info.source:sub(1,1) == "@" then
        local path = info.source:sub(2)
        local content = readFile(path)
        if content and #content > 10000 then
            collected["stack_" .. level] = content
            print("→ Loaded stack_" .. level .. " (" .. #content .. " bytes)")
        end
    end
end

local bases = {"", "C:\\Users\\Timothy\\Downloads\\Dumper-leaks-main - Copy\\", "C:\\Users\\Timothy\\Downloads\\"}
local names = {"dumper.lua", "main.lua", "loader.lua", "universal.lua", "init.lua", "hook.lua", "index.lua"}

for _, base in ipairs(bases) do
    for _, name in ipairs(names) do
        local content = readFile(base .. name)
        if content and #content > 10000 then
            collected["file_" .. name] = content
            print("→ Loaded " .. name .. " (" .. #content .. " bytes)")
        end
    end
end

print("\n===== FULL DUMP START =====")

for k, content in pairs(collected) do
    if type(content) == "string" then
        print("\n[=== " .. k .. " (" .. #content .. " bytes) ===]")
        print(content)
        print("\n[=== END OF " .. k .. " ===]\n")
    end
end

_G.full_dump = collected
print("[RESULT] Full dump completed. " .. #collected .. " files recovered.")