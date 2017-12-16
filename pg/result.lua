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

local return_result

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

local function get_conn_result(conn)
	local res = conn.raw_connection:getResult()
	if res == nil then
		return nil
	end
	return new_result(conn.pgsql, res)
end

local function new_copy_out(conn)
	return get_conn_result, conn
end

local copy_in = {}
local copy_in_mt = {
	__name = "pg copy-in result";
	__index = copy_in;
}

function copy_in:write(data)
	assert(not self.is_closed, "copy-in is closed")
	local ok = self.conn.raw_connection:putCopyData(data)
	if not ok then
		return nil, self.conn.raw_connection:errorMessage(), self.conn.raw_connection:status()
	end
	return ok
end

function copy_in:close(err)
	assert(not self.is_closed, "copy-in is closed")
	local ok = self.conn.raw_connection:putCopyEnd(err)
	if not ok then
		return nil, self.conn.raw_connection:errorMessage(), self.conn.raw_connection:status()
	end
	self.is_closed = true
	return return_result(self.conn, self.conn.raw_connection:getResult())
end

local function new_copy_in(conn)
	return setmetatable({
		conn = conn;
		is_closed = false;
	}, copy_in_mt);
end

-- Helper for returning resultss
return_result = function (conn, res)
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
	elseif status == conn.pgsql.PGRES_COPY_IN then
		return new_copy_in(conn)
	elseif status == conn.pgsql.PGRES_COPY_OUT then
		return new_copy_out(conn)
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
