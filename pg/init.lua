local pg_lib = require "pg.lib"

local default_lib = pg_lib.new(require "pgsql")

local function connectdb(...)
	return default_lib:connectdb(...)
end

local function getdefaultoid(...)
	return default_lib:getdefaultoid(...)
end

return {
	connectdb = connectdb;
	oids = default_lib.oids;
	getdefaultoid = getdefaultoid;
}
