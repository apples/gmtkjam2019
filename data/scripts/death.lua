local engine = require('engine')
local visitor = require('visitor')

return function()
    visitor.visit(
        {component.checkpoint, component.position},
        function (eid, checkpoint, position)
            engine.entities:move_to_layer(eid, checkpoint.layer)
            position.pos.x = checkpoint.x
            position.pos.y = checkpoint.y

            if engine.entities:has_component(eid, component.velocity) then
                local vel = engine.entities:get_component(eid, component.velocity).vel
                vel.x = 0
                vel.y = 0
            end
        end
    )

    visitor.visit(
        {component.warp},
        function (eid, warp)
            warp.used = false
        end
    )
end
