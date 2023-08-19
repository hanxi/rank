local M = {}

function M.string_split(str, sep)
	local arr = {}
	local i = 1
	for s in string.gmatch(str, "([^" .. sep .. "]+)") do
		arr[i] = s
		i = i + 1
	end
	return arr
end

return M
