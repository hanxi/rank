return function(rankid)
	local skynet = require "skynet"
	local errcode = require "app.errcode"
	local log = require "log"
	local const = require "app.const"
	local ranklib = require "rank"
	local config = require "config"

	log.info("init rank:", rankid)

	local CMD = {}
	local config_cache

	local function load_config()
		-- TODO: 从数据库加载数据
		return {
			capacity = const.DEFAULT_CAPACITY,
			order = const.ASCENDING,
		}
	end

	local function get_config()
		if config_cache then
			return config_cache
		end

		config_cache = load_config()
		return config_cache
	end

	local db_conf = config.get("app_mongodb_conf")
	local rankobj = ranklib.new(db_conf, rankid)

	function CMD.update(uid, score, info)
		rankobj:add(uid, score, info)

		local cfg = get_config()
		if cfg.order == const.ASCENDING then
			rankobj:limit(cfg.capacity)
		else
			rankobj:rev_limit(cfg.capacity)
		end
	end

	function CMD.delete(uid)
		rankobj:rem(uid)
	end

	function CMD.query(uid)
		log.info("query:", uid, type(uid))
		local element = rankobj:get_info(uid)
		if not element then
			return errcode.NOT_IN_RANK
		end

		local cfg = get_config()
		local rank
		if cfg.order == const.ASCENDING then
			rank = rankobj:rank(uid)
		else
			rank = rankobj:rev_rank(uid)
		end
		return errcode.OK, element, rank
	end

	function CMD.infos(uids)
		log.debug("infos:", uids)
		local elements = {}
		for _, uid in ipairs(uids) do
			local element = rankobj:get_info(uid)
			log.debug("infos element:", element)
			if element then
				elements[#elements + 1] = element
			end
		end
		return errcode.OK, elements
	end

	function CMD.ranklist(start, count)
		log.info("ranklist:", start, count)

		local r1 = start
		local r2 = start + count - 1

		local cfg = get_config()
		local uids
		if cfg.order == const.ASCENDING then
			uids = rankobj:range(r1, r2)
		else
			uids = rankobj:rev_range(r1, r2)
		end

		local elements = {}
		for _, uid in ipairs(uids) do
			local element = rankobj:get_info(uid)
			elements[#elements + 1] = element
		end
		return errcode.OK, elements
	end

	function CMD.clear_config_cache()
		config_cache = nil
	end

	skynet.dispatch("lua", function(_, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        else
            log.error(string.format("Unknown cmd:%s, source:%s", cmd, source))
        end
    end)
end
