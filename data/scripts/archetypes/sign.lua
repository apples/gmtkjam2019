local engine = require('engine')

return function(layer, x, y, i)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
    position.layer = layer
    position.pos.x = x
    position.pos.y = y

    local sprite = component.sprite.new()
    sprite.r = 7
    sprite.c = i

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, sprite)

    return ent
end
