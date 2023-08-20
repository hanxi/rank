local mongo = require "skynet.db.mongo"
local config = require "config"
local const = require "app.const"

local M = {}

function M.new_dbtbl(dbname, tblname)
	local app_mongodb_conf = config.get_tbl("app_mongodb_conf")
	local db_conn = mongo.client(app_mongodb_conf)
	return db_conn[dbname][tblname]
end

function M.new_config_dbtbl()
	local dbtbl = M.new_dbtbl(const.DB_NAME, const.DB_TBL_CONF_NAME)
	dbtbl:createIndex({{ rankid = 1 }, unique = true})
	return dbtbl
end

local config_dbtbl
function M.get_config_dbtbl()
	if config_dbtbl then
		return config_dbtbl
	end
	config_dbtbl = M.new_config_dbtbl()
	return config_dbtbl
end

return M
