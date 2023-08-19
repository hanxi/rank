return function()
	local skynet = require "skynet"
	local service = require "skynet.service"
	local rank_service = require "app.rank.rank_service"
	local log = require "log"

	local CMD = {}

	local function load_rank_service(t, rankid)
		log.info("load_rank_service rankid:", rankid)
		t[rankid] = service.new(rankid, rank_service, rankid)
		return t[rankid]
	end

	local ranks = setmetatable ({} , {
		__index = load_rank_service,
	})

	function CMD.get_rank_service(appname, tag)
		local rankid = appname .. "_".. tag
		return ranks[rankid]
	end

	function CMD.set_config(config)
		log.info("set_config", config)
		-- TODO: 写入数据库
		-- 通知所有 rank_service 清空缓存
		for _, addr in pairs(ranks) do
			skynet.send(addr, "lua", "clear_config_cache")
		end
	end

	-- TODO: 定时清理长期不用的排行榜

	skynet.dispatch("lua", function(_, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            log.error(string.format("Unknown cmd:%s, source:%s", cmd, source))
        end
    end)
end
