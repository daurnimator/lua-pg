local pg_result = require "pg.result"
local pg_prepared_statement_reference = require "pg.prepared_statement_reference"
local pg_util = require "pg.util"

local connection = {}
local connection_mt = {
	__name = "pg connection";
	__index = connection;
}

local function new_connection(pgpsql_library, conn)
	local self = setmetatable({
		pgsql = assert(pgpsql_library);
		raw_connection = assert(conn);
	}, connection_mt)
	-- XXX: blocked on https://github.com/arcapos/luapgsql/issues/25
	-- conn:setNoticeReceiver()
	return self
end

function connection:close()
	self.raw_connection:close()
	return true
end

function connection:exec(...)
	local res = self.raw_connection:execParams(...)
	return pg_result.return_result(self, res)
end

function connection:prepare(...)
	local name = pg_util.generate_id()
	local res = self.raw_connection:prepare(name, ...)
	local ok, err, errno = pg_result.return_result(self, res)
	if not ok then
		return nil, err, errno
	end
	return pg_prepared_statement_reference.new(self, name)
end

return {
	new = new_connection;
}
