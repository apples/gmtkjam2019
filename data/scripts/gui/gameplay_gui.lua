local vdom = require('vdom')
local fps_counter = require('gui.fps_counter')
local debug_display = require('gui.debug_display')

return function(props)
    return vdom.create_element('widget', { width = '100%', height = '100%' },
        vdom.create_element(fps_counter, { fps = props.fps }),
        vdom.create_element(debug_display, { strings = props.debug_strings, vals = props.debug_vals })
    )
end
