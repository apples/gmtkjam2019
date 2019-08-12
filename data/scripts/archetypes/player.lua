local engine = require('engine')

return function(layer, x, y)
    local player = engine.entities:create_entity()

    local position = component.position.new()
    position.pos.x = x
    position.pos.y = y
    position.z = 1

    local velocity = component.velocity.new()

    local sprite = component.sprite.new()
    sprite.r = 1
    sprite.c = 0

    local script = component.script.new()
    script.next_tick = 0
    script.name = 'player'

    local controller = component.controller.new()
    controller.data = {
        on_ground = false,
        warp_target = 0,
    }

    local body = component.body.new()

    local checkpoint = component.checkpoint.new()
    checkpoint.layer = layer
    checkpoint.x = x
    checkpoint.y = y

    engine.entities:add_component(player, position)
    engine.entities:add_component(player, velocity)
    engine.entities:add_component(player, sprite)
    engine.entities:add_component(player, script)
    engine.entities:add_component(player, controller)
    engine.entities:add_component(player, body)
    engine.entities:add_component(player, checkpoint)

    engine.entities:add_to_layer(player, layer)

    return player
end
