local path = (debug.getinfo(1, "S").source):gsub("/init.lua", "")
if path:sub(1,1) == "@" then path = path:sub(2) end

package.path = "./?.lua;./?/init.lua;" ..
               path .. "/?.lua;" .. path .. "/?/init.lua;" .. package.path

local dslx = require "dslx"

require("import")

print("aaa")