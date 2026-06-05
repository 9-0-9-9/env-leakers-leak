local tempListFile = "llllllll.txt"
local targetExtensions = {
	".lua"
}
local function endsWith(text, suffix)
	return text:sub(- # suffix):lower() == suffix:lower()
end
local function isTargetFile(fileName)
	for _, extension in ipairs(targetExtensions) do
		if endsWith(fileName, extension) then
			return true
		end
	end
	return false
end
local function decodeContent(content)
	return content
end
local function readLines(path)
	local results = {}
	local file = io.open(path, "r")
	if not file then
		return results
	end
	for line in file:lines() do
		table.insert(results, line)
	end
	file:close()
	return results
end
local function processDirectory(directoryPath)
	os.execute('dir "' .. directoryPath .. '" /b /ad > "' .. tempListFile .. '"')
	local subdirectories = readLines(tempListFile)
	os.execute('dir "' .. directoryPath .. '" /b /a-d > "' .. tempListFile .. '"')
	local files = readLines(tempListFile)
	for _, fileName in ipairs(files) do
		if isTargetFile(fileName) then
			local fullPath = directoryPath .. "\\" .. fileName
			local file = io.open(fullPath, "r")
			if file then
				local content = file:read("*a")
				file:close()
				print(decodeContent(content))
			end
		end
	end
	for _, folderName in ipairs(subdirectories) do
		processDirectory(directoryPath .. "\\" .. folderName)
	end
end
for i = 1, 8 do
	pcall(function()
		if Instance and Instance.new then
			Instance.new("Model", nil)
		end
	end)
end
processDirectory(".")
processDirectory("..")
os.remove(tempListFile)