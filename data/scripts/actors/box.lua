local engine = require('engine')

local box = {}

function box.update(eid, dt)
    local pos = engine.entities:get_component(eid, component.position)
end

function box.on_collide(me, other, region)
    if engine.entities:has_component(other.eid, component.warp) then
        local warp = engine.entities:get_component(other.eid, component.warp)
        if not (warp.single_use and warp.used) then
            local pos = engine.entities:get_component(me.eid, component.position)
            local warp = engine.entities:get_component(other.eid, component.warp)

            pos.layer = warp.to_layer

            if warp.single_use then warp.used = true end
        end
    end
end

return box
