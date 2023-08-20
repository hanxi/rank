local M = {}

function M.get_rankid(appname, tag)
	return string.format("%s_%s", appname, tag)
end

return M
