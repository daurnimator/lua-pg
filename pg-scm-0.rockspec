package = "pg"
version = "scm-0"

description = {
	summary = "Nice API to PostgreSQL";
	homepage = "https://github.com/daurnimator/lua-pg";
	license = "MIT";
}

source = {
	url = "git+https://github.com/daurnimator/lua-pg.git";
}

dependencies = {
	"lua >= 5.1";
	"compat53 >= 0.3"; -- Only if lua < 5.3
	"luuid";
	"luapgsql";
}

build = {
	type = "builtin";
	modules = {
		["pg"] = "pg/init.lua";
		["pg.connection"] = "pg/connection.lua";
		["pg.lib"] = "pg/lib.lua";
		["pg.prepared_statement_reference"] = "pg/prepared_statement_reference.lua";
		["pg.result"] = "pg/result.lua";
		["pg.util"] = "pg/util.lua";
	};
}
