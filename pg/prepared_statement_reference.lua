local pg_result = require "pg.result"

local prepared_statement_reference = {}
local prepared_statement_reference_mt = {
	__name = "pg prepared statement reference";
	__index = prepared_statement_reference;
}

local function new_prepared_statement_reference(conn, name)
	return setmetatable({
		conn = assert(conn);
		name = assert(name);
	}, prepared_statement_reference_mt)
end

function prepared_statement_reference:exec(...)
	local res = self.conn.raw_connection:execPrepared(assert(self.name, "prepared statement deallocated"), ...)
	return pg_result.return_result(self.conn, res)
end

return {
	new = new_prepared_statement_reference;
}
