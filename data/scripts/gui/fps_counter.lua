local vdom = require('vdom')

local fps_counter = vdom.component()

function fps_counter:constructor(props)
    assert(props.fps)
    self:super(props)
end

function fps_counter:render()
    return vdom.create_element(
        'label',
        {
            halign='right',
            valign='top',
            height = 8,
            color = '#f0f',
            text = self.props.fps,
        }
    )
end

return fps_counter
