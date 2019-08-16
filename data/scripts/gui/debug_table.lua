local vdom = require('vdom')
local linq = require('linq')

local debug_table = vdom.component()

function debug_table:constructor(props)
    assert(props.strings)
    assert(props.left or props.right)
    assert(props.top)
    self:super(props)
end

function debug_table:render()
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
                        halign = self.props.align,
                        valign = 'top',
                        height = 12,
                        color = '#fff',
                        text = s,
                        top = self.props.top + 12 * (i - 1),
                        left = self.props.left,
                        right = self.props.right,
                    }
                )
            end)
            :tolist()
    )
end

return debug_table
