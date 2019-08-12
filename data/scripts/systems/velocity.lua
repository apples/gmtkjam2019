local engine = require('engine')
local visitor = require('visitor')
local linq = require('linq')

local velocity = {}

function velocity.visit(dt)
    visitor.visit(
        {component.velocity, component.position},
        function (eid, velocity, position)
            if engine.entities:get_layer_of(eid) == game_state.layer then
                position.pos.x = position.pos.x + velocity.vel.x * dt
                position.pos.y = position.pos.y + velocity.vel.y * dt
            end
        end
    )
end

return velocity
