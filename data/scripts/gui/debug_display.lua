local vdom = require('vdom')
local linq = require('linq')

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
        linq(self.props.strings)
            :select(function (s, i)
                return vdom.create_element(
                    'label',
                    {
                        halign='left',
                        valign='top',
                        height = 12,
                        color = '#fff',
                        text = s,
                        top = 12 * i,
                    }
                )
            end)
            :tolist(),
        linq(self.props.vals)
            :select(function (s, i)
                return vdom.create_element(
                    'label',
                    {
                        halign='left',
                        valign='top',
                        height = 12,
                        color = '#fff',
                        text = s,
                        top = 12 * i,
                        right = 250,
                    }
                )
            end)
            :tolist()
    )
end

return debug_display
