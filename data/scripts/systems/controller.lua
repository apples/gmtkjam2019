local engine = require('engine')
local visitor = require('visitor')

local controller = {}

function controller.visit(dt)
    visitor.visit(
        {component.controller, component.script},
        function (eid, controller, script)
            local script_impl = require('actors.' .. script.name)
            if script_impl.controller then
                script_impl.controller(eid, keys, dt, controller.data)
            end
        end
    )
end

return controller
