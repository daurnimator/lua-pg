local uuid = require "uuid" -- https://luarocks.org/modules/develcuy/luuid

local function generate_id()
	return "lua-pg-" .. uuid.new()
end

return {
	generate_id = generate_id;
}
