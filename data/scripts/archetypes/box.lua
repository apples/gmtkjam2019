local engine = require('engine')

return function(layer, x, y)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
    position.layer = layer
    position.pos.x = x
    position.pos.y = y

    local velocity = component.velocity.new()

    local sprite = component.sprite.new()
    sprite.r = 6
    sprite.c = 0

    local body = component.body.new()

    local script = component.script.new()
    script.next_tick = 0
    script.name = 'box'

    local checkpoint = component.checkpoint.new()
    checkpoint.layer = layer
    checkpoint.x = x
    checkpoint.y = y

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, velocity)
    engine.entities:add_component(ent, sprite)
    engine.entities:add_component(ent, body)
    engine.entities:add_component(ent, script)
    engine.entities:add_component(ent, checkpoint)

    return ent
end
