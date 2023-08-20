local wlua = require "wlua"
local rank_proxy = require "app.rank.rank_proxy"
local errcode = require "app.errcode"
local util = require "util"
local log = require "log"

local app = wlua:default()

app:get("/", function (c)
	log.info(package.cpath)
	c:send("Hello wlua rank!")
end)

app:get("/ping", function (c)
	c:send("pong")
end)

app:post("/setconfig", function (c)
	local appname = c.req.body.appname
	local config = c.req.body.config

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code = proxy:set_config(config)
	c:send_json({
		code = code
	})
end)

app:post("/update", function (c)
	local appname = c.req.body.appname
	local tags = c.req.body.tags
	local uid = c.req.body.uid
	local score = c.req.body.score
	local info = c.req.body.info

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code = proxy:update(tags, uid, score, info)
	c:send_json({
		code = code
	})
end)

app:post("/delete", function (c)
	local appname = c.req.body.appname
	local tags = c.req.body.tags
	local uid = c.req.body.uid

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code = proxy:delete(tags, uid)
	c:send_json({
		code = code
	})
end)

app:get("/query", function (c)
	local appname = c.req.query.appname
	local tag = c.req.query.tag
	local uid = c.req.query.uid

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code, element, rank = proxy:query(tag, uid)
	c:send_json({
		code = code,
		element = element,
		rank = rank,
	})
end)

app:get("/infos", function (c)
	local appname = c.req.query.appname
	local tag = c.req.query.tag
	local uids = util.string_split(c.req.query.uids, ",")

	log.debug("infos appname:", appname, ", tag:", tag, ", uids:", uids)

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code, elements = proxy:infos(tag, uids)
	c:send_json({
		code = code,
		elements = elements,
	})
end)

app:get("/ranklist", function (c)
	local appname = c.req.query.appname
	local tag = c.req.query.tag
	local start = tonumber(c.req.query.start)
	local count = tonumber(c.req.query.count)

	local proxy = rank_proxy.get(appname)
	if proxy == nil then
		c:send_json({
			code = errcode.RANK_INIT_FAIL
		})
		return
	end

	local code, elements = proxy:ranklist(tag, start, count)
	c:send_json({
		code = code,
		elements = elements,
	})
end)

app:run()

