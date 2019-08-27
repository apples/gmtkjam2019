local vdom = require('vdom')
local linq = require('linq')

return function(props)
    assert(props.strings)
    assert(props.left or props.right)
    assert(props.top)

    return vdom.create_element(
        'panel',
        {
            halign='left',
            valign='top',
        },
        linq(props.strings)
            :select(function (s, i)
                return vdom.create_element(
                    'label',
                    {
                        halign = props.align,
                        valign = 'top',
                        height = 12,
                        color = '#fff',
                        text = s,
                        top = props.top + 12 * (i - 1),
                        left = props.left,
                        right = props.right,
                    }
                )
            end)
            :tolist()
    )
end
