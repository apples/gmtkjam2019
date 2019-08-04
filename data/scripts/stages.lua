local player = require('archetypes.player')
local wall = require('archetypes.wall')
local spike = require('archetypes.spike')

local function add_stuff_at(layer, str, r, named, map)
    for i = 1, #str do
        local c = str:sub(i, i)

        if c == ' ' then --nothing
        elseif c == '#' then wall(layer, i, r, map)
        elseif c == '@' then player(layer, i, r)
        elseif c == '^' then spike(layer, i, r)
        else
            named[c](layer, i, r)
        end
    end
end

local function create_stage(layer)
    local r = 15

    local map = {}

    local function finalize(named)
        print('Creating stage ' .. layer .. '...')
        for i=1,15 do
            add_stuff_at(layer, map[i], i, named, map)
        end
    end

    local function next(str)
        map[r] = str
        r = r - 1
        if r == 0 then
            return finalize
        else
            return next
        end
    end

    return next
end

function stages()
    create_stage(1)
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '         #          '
        '   @     ##         '
        '         ## #       '
        '######### ##########'
        '                    '
        '                    '
        {}

end

return stages
