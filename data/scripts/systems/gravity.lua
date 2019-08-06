local engine = require('engine')
local visitor = require('visitor')

local G = -100

local gravity = {}

function gravity.visit(dt)
    visitor.visit(
        {component.velocity, component.position, component.body},
        function (eid, velocity, position, body)
            if position.layer == game_state.layer then
                velocity.vel.y = velocity.vel.y + G * dt
            end
        end
    )
end

return gravity
