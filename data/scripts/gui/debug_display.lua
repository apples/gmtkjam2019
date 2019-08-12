local vdom = require('vdom')
local linq = require('linq')
local debug_table = require('gui.debug_table')

local debug_display = vdom.component()

function debug_display:constructor(props)
    assert(props.strings)
    assert(props.vals)
    self:super(props)
end

function debug_display:render()
    return vdom.create_element(
        'panel',
        {
            halign='left',
            valign='top',
        },
        vdom.create_element(debug_table, { strings = self.props.strings, top = 12, left = 0 }),
        vdom.create_element(debug_table, { strings = self.props.vals, top = 12, right = 250 })
    )
end

return debug_display
