local engine = require('engine')
local linq = require('linq')

local player = {}

function player.update(eid, dt)
    local pos = engine.entities:get_component(eid, component.position)
end

function player.on_hurt(eid, other)
    play_sfx('hurt')
end

function player.controller(eid, keys, dt)
    local pos = engine.entities:get_component(eid, component.position)
    local vel = engine.entities:get_component(eid, component.velocity).vel
    local con = engine.entities:get_component(eid, component.controller)

    local accel = 300
    local max_vel = 10
    local friction = 0
    local jump_force = 20

    if keys.left and vel.x > -max_vel then vel.x = math.max(-max_vel, vel.x - accel * dt) end
    if keys.right and vel.x < max_vel then vel.x = math.min(max_vel, vel.x + accel * dt) end

    if not (keys.left or keys.right) then vel.x = vel.x * friction end

    if keys.jump_pressed  then
        vel.y = vel.y + jump_force
        con.data.on_ground = false
    end
end

function player.on_collide(me, other, region)
    local con = engine.entities:get_component(me.eid, component.controller)

    if region.bottom < me.bottom and me.bottom < region.top then
        con.data.on_ground = true
    end
end


return player
