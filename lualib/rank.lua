local skiplist = require "skiplist.c"
local util_table = require "util.table"
local log = require "log"

local mt = {}
mt.__index = mt

function mt:_add(uid, score, info)
    local element = self.tbl[uid]
    if element then
        if element.score == score then
            return
        end
        self.sl:delete(element.score, uid)
    end

    self.sl:insert(score, uid)
    self.tbl[uid] = {
		uid = uid,
		score = score,
		info = info,
	}
end

function mt:add(uid, score, info)
	self:_add(uid, score, info)
	self:_db_update(uid, score, info)
end

function mt:_db_update(uid, score, info)
	-- 更新数据库数据
	local data = {
		["$set"] = {
			score = score,
			info = info,
		}
	}
	local ok, err, ret = self.dbtbl:safe_update({uid = uid}, data, true, false)
	if (not ok) or (not ret) or (ret.n ~= 1) then
		log.error("save rank failed. uid:", uid, ", score:",
			score, ", info:", util_table.tostring(info), ", err:", err)
	end
end

function mt:rem(uid)
    local element  = self.tbl[uid]
    if element then
        self.sl:delete(element.score, uid)
        self.tbl[uid] = nil
		-- 从数据库中删除
		self:_db_delete(uid)
    end
end

function mt:_db_delete(uid)
	local ok, err, ret = self.dbtbl:safe_delete({uid= uid}, true)
	if (not ok) or (not ret) or (ret.n ~= 1) then
		log.error("delete from rank failed. uid:", uid, ", err:", err)
	end
end

function mt:limit(count)
    local total = self.sl:get_count()
    if total <= count then
        return 0
    end

	local from = count + 1
	local to = total

    local delete_function = function(uid)
        self.tbl[uid] = nil
		-- 从数据库中删除
		self:_db_delete(uid)
    end

    return self.sl:delete_by_rank(from, to, delete_function)
end

function mt:_reverse_rank(r)
    return self.sl:get_count() - r + 1
end

function mt:rev_limit(count)
    local total = self.sl:get_count()
    if total <= count then
        return 0
    end

    local from = self:_reverse_rank(count + 1)
    local to   = self:_reverse_rank(total)

    local delete_function = function(uid)
        self.tbl[uid] = nil
		-- 从数据库中删除
		self:_db_delete(uid)
    end

    return self.sl:delete_by_rank(from, to, delete_function)
end

function mt:rank(uid)
    local element = self.tbl[uid]
    if not element then
        return nil
    end
    return self.sl:get_rank(element.score, uid)
end

function mt:rev_rank(uid)
    local r = self:rank(uid)
    if r then
        return self:_reverse_rank(r)
    end
    return r
end

function mt:get_info(uid)
    return self.tbl[uid]
end

function mt:range(r1, r2)
    if r1 < 1 then
        r1 = 1
    end

    if r2 < 1 then
        r2 = 1
    end
    return self.sl:get_rank_range(r1, r2)
end

function mt:rev_range(r1, r2)
    r1 = self:_reverse_rank(r1)
    r2 = self:_reverse_rank(r2)
    return self:range(r1, r2)
end

function mt:dump()
    self.sl:dump()
end

function mt:_load_db()
	local ret = self.dbtbl:find({}, { _id = 0 })
    while ret:hasNext() do
        local data = ret:next()
		self:_add(data.uid, data.score, data.info)
    end
end

local M = {}

local mongo = require "skynet.db.mongo"

local function new_dbtbl(db_conf, dbname, tblname)
	log.debug("new_dbtbl:", db_conf, dbname, tblname)
	local db_conn = mongo.client(db_conf)
	local dbtbl = db_conn[dbname][tblname]
	dbtbl:createIndex({{ uid = 1 }, unique = true})
	log.debug("new_dbtbl ok")
	return dbtbl
end

function M.new(db_conf, dbname, tblname)
    local obj = {}
    obj.sl = skiplist()
    obj.tbl = {}
	obj.dbtbl = new_dbtbl(db_conf, dbname, tblname)
    setmetatable(obj, mt)
	obj:_load_db()
	return obj
end

return M
