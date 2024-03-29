local engine = require('engine')

return function(layer, x, y, to, single)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
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
    warp.single_use = single
    warp.used = false

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, sprite)
    engine.entities:add_component(ent, body)
    engine.entities:add_component(ent, warp)

    engine.entities:add_to_layer(ent, layer)

    return ent
end
