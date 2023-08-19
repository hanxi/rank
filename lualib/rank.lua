local skiplist = require "skiplist.c"
local mt = {}
mt.__index = mt

function mt:add(uid, score, info)
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
	-- TODO: 更新数据库数据
end

function mt:rem(uid)
    local element  = self.tbl[uid]
    if element then
        self.sl:delete(element.score, uid)
        self.tbl[uid] = nil
		-- TODO: 从数据库中删除
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
		-- TODO: 从数据库中删除
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
		-- TODO: 从数据库中删除
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

local M = {}

function M.new(db_conf, rankid)
    local obj = {}
    obj.sl = skiplist()
    obj.tbl = {}
    return setmetatable(obj, mt)
end

return M
