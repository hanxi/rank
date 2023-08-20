local M = {}

M.DEFAULT_TIMEOUT = 500
M.DEFAULT_CAPACITY = 500

M.ASCENDING = "ascending" -- 从小到大
M.DESCENDING = "descending" -- 从大到小

M.DB_NAME = "rank" -- 数据库名
M.DB_TBL_CONF_NAME = "rank_config" -- 配置存储数据库表名

return M
