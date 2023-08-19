local service = require "skynet.service"
local rankmgr_service = require "app.rank.rankmgr_service"

local function load_service(t, key)
    if key == "addr" then
        t.address = service.new("rankmgr", rankmgr_service)
        return t.address
    else
        return nil
    end
end

local rankmng = setmetatable ({} , {
    __index = load_service,
})

return rankmng
