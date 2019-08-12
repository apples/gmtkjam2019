local engine = require('engine')

return function(layer, x, y, map)
    local ent = engine.entities:create_entity()

    local position = component.position.new()
    position.pos.x = x
    position.pos.y = y

    local sprite = component.sprite.new()
    sprite.r = 2
    sprite.c = 0

    local body = component.body.new()
    body.dynamic = false

    if y > 1 and map[y-1]:sub(x,x) == '#' then body.edge_bottom = false end
    if y < 15 and map[y+1]:sub(x,x) == '#' then body.edge_top = false end
    if x > 1 and map[y]:sub(x-1,x-1) == '#' then body.edge_left = false end
    if x < 15 and map[y]:sub(x+1,x+1) == '#' then body.edge_right = false end

    engine.entities:add_component(ent, position)
    engine.entities:add_component(ent, sprite)
    engine.entities:add_component(ent, body)

    engine.entities:add_to_layer(ent, layer)

    return ent
end
