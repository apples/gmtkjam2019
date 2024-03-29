local engine = require('engine')

return function(layer, x, y)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
    position.pos.x = x
    position.pos.y = y

    local sprite = component.sprite.new()
    sprite.r = 0
    sprite.c = 0

    local body = component.body.new()
    body.dynamic = false

    local hurter = component.hurter.new()

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, sprite)
    engine.entities:add_component(ent, body)
    engine.entities:add_component(ent, hurter)

    engine.entities:add_to_layer(ent, layer)

    return ent
end
