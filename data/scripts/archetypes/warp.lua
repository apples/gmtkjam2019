local engine = require('engine')

return function(layer, x, y, to)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
    position.layer = layer
    position.pos.x = x
    position.pos.y = y

    local sprite = component.sprite.new()
    sprite.r = 3
    sprite.c = 0

    local body = component.body.new()
    body.dynamic = false
    body.solid = false

    local warp = component.warp.new()
    warp.to_layer = to

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, sprite)
    engine.entities:add_component(ent, body)
    engine.entities:add_component(ent, warp)

    return ent
end
