local math_type = math.type or function() return "float" end

local pg_connection = require "pg.connection"

local lib = {}
local lib_mt = {
	__name = "pg lib";
	__index = lib;
}

local function new_lib(pgpsql_library)
	-- TODO: version check?
	return setmetatable({
		pgsql = assert(pgpsql_library);
		oids = pgpsql_library.oids;
		getdefaultoid = pgpsql_library.getdefaultoid;
	}, lib_mt)
end

function lib:connectdb(c)
	local conn = self.pgsql.connectdb(c or "") -- default to empty connection string
	if conn:status() ~= self.pgsql.CONNECTION_OK then
		return nil, conn:errorMessage(), conn:status()
	end
	return pg_connection.new(self.pgsql, conn)
end

-- Hack around https://github.com/arcapos/luapgsql/issues/45
lib.oids = {
	int8 = 1;
	float8 = 1.0;
	text = "string";
	bool = true;
	unknown = nil;
}
function lib:getdefaultoid(value)
	local t_value = type(value)
	if t_value == "number" then
		if math_type(value) == "integer" then
			return self.oids.int8
		else
			return self.oids.float8
		end
	elseif t_value == "string" then
		return self.oids.text
	elseif t_value == "boolean" then
		return self.oids.bool
	elseif value == nil then
		return self.oids.unknown
	end
end

return {
	new = new_lib;
}
