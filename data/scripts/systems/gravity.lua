local engine = require('engine')
local visitor = require('visitor')

local G = -100

local gravity = {}

function gravity.visit(dt)
    visitor.visit(
        {component.velocity, component.body},
        function (eid, velocity, body)
            if engine.entities:get_layer_of(eid) == game_state.layer then
                velocity.vel.y = velocity.vel.y + G * dt
            end
        end
    )
end

return gravity
