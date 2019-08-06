local engine = require('engine')
local linq = require('linq')
local death = require('death')
local visitor = require('visitor')

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
    local jump_force = 22

    if keys.left and vel.x > -max_vel then vel.x = math.max(-max_vel, vel.x - accel * dt) end
    if keys.right and vel.x < max_vel then vel.x = math.min(max_vel, vel.x + accel * dt) end

    if not (keys.left or keys.right) then vel.x = vel.x * friction end

    if keys.jump_pressed and con.data.on_ground then
        vel.y = vel.y + jump_force
        con.data.on_ground = false
    end

    if keys.action_pressed and con.data.warp_target ~= 0 then
        game_state.layer = con.data.warp_target
        pos.layer = con.data.warp_target
    end

    con.data.warp_target = 0
end

function player.on_collide(me, other, region)
    local con = engine.entities:get_component(me.eid, component.controller)

    if other.body.solid and other.bottom < me.bottom and me.bottom < other.top then
        con.data.on_ground = true
    end

    if engine.entities:has_component(other.eid, component.warp) then
        local warp = engine.entities:get_component(other.eid, component.warp)
        if not (warp.single_use and warp.used) then
            con.data.warp_target = warp.to_layer
        end
    end

    if engine.entities:has_component(other.eid, component.hurter) then
        local pos = engine.entities:get_component(me.eid, component.position)
        death()
        game_state.layer = pos.layer
        return 'abort'
    end

    if engine.entities:has_component(other.eid, component.checkpoint_flag) then
        visitor.visit(
            {component.checkpoint, component.sprite},
            function (eid, checkpoint, sprite)
                sprite.c = 0
            end
        )

        local pos = engine.entities:get_component(other.eid, component.position)
        local spr = engine.entities:get_component(other.eid, component.sprite)
        local check = engine.entities:get_component(me.eid, component.checkpoint)

        spr.c = 1

        check.layer = pos.layer
        check.x = pos.pos.x
        check.y = pos.pos.y

        return 'abort'
    end
end

return player
