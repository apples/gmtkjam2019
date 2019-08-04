local vdom = require('vdom')
local fps_counter = require('gui.fps_counter')

local gameplay_gui = vdom.component()

function gameplay_gui:constructor(props)
    assert(props.initial_state)
    self:super(props)

    self.state = props.initial_state
end

function gameplay_gui:render()
    return vdom.create_element('widget', { width = '100%', height = '100%' },
        vdom.create_element(fps_counter, { fps = self.state.fps })
    )
end

return gameplay_gui
