local pg = require "pg"

-- Make a connection to a database using default parameters
local conn = assert(pg.connectdb())

-- Execute a command
assert(conn:exec[[create temporary table example(col1 int, col2 text)]])

-- Prepare a command
local insert = assert(conn:prepare([[insert into example(col1, col2) values ($1, $2)]], pg.getdefaultoid(1), pg.oids.text))
assert(insert:exec(1, "one"))
assert(insert:exec(2, "two"))

-- Make a simple query
local res = assert(conn:exec[[select * from example]])
-- Print column names
print("", res:fields())
-- Iterate over result rows
for row_number, col1, col2 in res:tuples() do
	print(row_number, col1, col2)
end
print()

-- Prepare a query
local myquery = assert(conn:prepare([[select $1 * 2]], pg.getdefaultoid(1)))
-- Execute the query and get result
for row_number, x in assert(myquery:exec(42)):tuples() do
	print(row_number, x) -- 84
end
