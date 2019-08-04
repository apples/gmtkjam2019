local vdom = require('vdom')
local gameplay_gui = require('gui.gameplay_gui')

local vdom_root = vdom.render(vdom.create_element(gameplay_gui, { initial_state = gui_state }), root_widget)

function update_gui_state()
    vdom_root.component_instance:set_state(gui_state)
end
