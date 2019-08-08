local engine = require('engine')
local stages = require('stages')

play_bgm('bgm')

config = {
}

gui_state = {
    fps = 0,
    debug_strings = {},
    debug_vals = {},
}

game_state = {
    layer = 1
}

print('loading stages')

stages()

print('init done')
