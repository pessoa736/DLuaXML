package = "DaviLuaXML"
version = "dev-1"
source = {
   url = "git+https://github.com/pessoa736/DaviLuaXML",
   tag = "1.5-1"
}
description = {
   summary = "Davi System Lua XML - write XML directly in your Lua code",
   detailed = [[
      Davi System Lua XML (DaviLuaXML) is a library that allows you to use XML syntax inside Lua code.
      XML tags are transformed into Lua function calls, similar to JSX in JavaScript.

      Changes in 1.5-1:
      - Added PropTypes validation (DaviLuaXML.proptypes)
      - Added runtime invoke helper used by transformed code (DaviLuaXML.runtime)
      - Added simple sourcemap support for runtime errors (DaviLuaXML.sourcemap)
      - Added tree-shaking compiler pass with --treeshake (DaviLuaXML.treeshake)
   ]],
   homepage = "https://github.com/pessoa736/DaviLuaXML",
   license = "MIT"
}
dependencies = {
   "loglua",
   "lpeg"
}

build = {
   type = "builtin",
   modules = {
      ["DaviLuaXML"]="DaviLuaXML/init.lua",
      ["DaviLuaXML.parser"]="DaviLuaXML/parser.lua",
      ["DaviLuaXML.runtime"]="DaviLuaXML/runtime.lua",
      ["DaviLuaXML.compile"]="DaviLuaXML/compile.lua"
   },
   copy_directories = {
      "doc"
   }
}
