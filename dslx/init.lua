


local dslx = {
    parser = require("dslx.parser"),
    compile = require("dslx.compile"),
    import = require("dslx.import"),
    runtime = require("dslx.runtime"),
}

dslx.import.install()

return dslx