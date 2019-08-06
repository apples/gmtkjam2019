local engine = require('engine')
local visitor = require('visitor')

local warp = {}

function warp.visit(dt)
    visitor.visit(
        {component.warp, component.sprite},
        function (eid, warp, sprite)
            if warp.used then sprite.c = 1 else sprite.c = 0 end
        end
    )
end

return warp
