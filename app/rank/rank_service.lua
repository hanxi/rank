return function(rankid)
	local skynet = require "skynet"
	local errcode = require "app.errcode"
	local log = require "log"
	local const = require "app.const"
	local ranklib = require "rank"
	local config = require "config"
	local db = require "app.db"

	log.info("init rank:", rankid)

	local CMD = {}
	local config_cache

	local function load_config()
		local dbtbl = db.get_config_dbtbl()
		-- 从数据库加载配置
		local data = dbtbl:findOne({ rankid = rankid }, { _id = 0, cfg = 1, })
		log.debug("load_config data:", data)
		if data then
			return {
				capacity = data.cfg.capacity,
				order = data.cfg.order,
			}
		end
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

	local db_conf = config.get_tbl("app_mongodb_conf")
	log.debug("db_conf:", db_conf)
	local rankobj = ranklib.new(db_conf, const.DB_NAME, rankid)

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
		log.info("clear_config_cache ok")
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
