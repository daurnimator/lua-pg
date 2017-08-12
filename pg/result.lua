local unpack = table.unpack or require "compat53.module".table.unpack -- 5.1's unpack doesn't work on userdata

local result = {}
local result_mt = {
	__name = "pg result";
	__index = result;
}

local function new_result(pgpsql_library, res)
	return setmetatable({
		pgsql = assert(pgpsql_library);
		raw_result = assert(res);
	}, result_mt)
end

function result_mt:__len()
	return self.raw_result:ntuples()
end

local function next_tuple(self, last)
	if last >= self.raw_result:ntuples() then -- https://github.com/arcapos/luapgsql/issues/44
		return nil
	end
	last = last + 1
	local tuple = self.raw_result[last]
	-- if tuple == nil then
	-- 	return nil
	-- end
	return last, unpack(tuple)
end

function result:fields()
	local n = self.raw_result:nfields()
	local t = {}
	for i=1, n do
		t[i] = self.raw_result:fname(i)
	end
	return unpack(t, 1, n)
end

function result:tuples()
	return next_tuple, self, 0
end

-- Helper for returning resultss
local function return_result(conn, res)
	if not res then
		return nil, conn.raw_connection:errorMessage(), conn.raw_connection:status()
	end
	local status = res:status()
	if status == conn.pgsql.PGRES_TUPLES_OK then
		return new_result(conn.pgsql, res)
	elseif status == conn.pgsql.PGRES_COMMAND_OK then
		local cmdStatus = res:cmdStatus()
		local tuples = tonumber(res:cmdTuples(), 10)
		local oid = res:oidValue()
		if oid == 0 then -- See https://github.com/arcapos/luapgsql/issues/43
			oid = nil
		end
		-- TODO: free result ASAP https://github.com/arcapos/luapgsql/issues/42
		return cmdStatus, tuples, oid
	else
		local errmsg = res:errorMessage()
		-- TODO: free result ASAP https://github.com/arcapos/luapgsql/issues/42
		return nil, errmsg, status
	end
end

return {
	new = new_result;
	return_result = return_result;
}
