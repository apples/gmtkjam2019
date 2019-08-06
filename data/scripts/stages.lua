local player = require('archetypes.player')
local wall = require('archetypes.wall')
local spike = require('archetypes.spike')
local warp = require('archetypes.warp')
local checkpoint = require('archetypes.checkpoint')
local box = require('archetypes.box')
local sign = require('archetypes.sign')

local function add_stuff_at(layer, str, r, named, map)
    for i = 1, #str do
        local c = str:sub(i, i)

        if c == ' ' then --nothing
        elseif c == '#' then wall(layer, i, r, map)
        elseif c == '@' then player(layer, i, r)
        elseif c == '^' then spike(layer, i, r)
        elseif c == '!' then checkpoint(layer, i, r)
        elseif c == '+' then box(layer, i, r)
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

local function tolayer(to)
    return function(layer, x, y)
        warp(layer, x, y, to, false)
    end
end

local function tolayer_single(to)
    return function(layer, x, y)
        warp(layer, x, y, to, true)
    end
end

local function msign(i)
    return function(layer, x, y)
        sign(layer, x, y, i)
    end
end

function stages()
    create_stage(1)
        '                    '
        '                    '
        '                    '
        '                    '
        '#                  #'
        '#                  #'
        '#    C             #'
        '#                  #'
        '#    ###      +    #'
        '#        #    ##   #'
        '#@       ##        #'
        '#!     A ##^#   # B#'
        '######### ##########'
        '                    '
        '                    '
        { A = tolayer(2), B = tolayer(2), C = tolayer(3) }

    create_stage(2)
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '      ####          '
        '      #             '
        '      #A      ^   B '
        '#########^##########'
        '                    '
        '                    '
        { A = tolayer(1), B = tolayer(1) }

    create_stage(3)
        '  #                #'
        '  #                #'
        '  #         A      #'
        '  #         #      #'
        '  #            #   #'
        '  #               ##'
        '  #  ! ^           #'
        '  ###### ###   #####'
        '  #           ##    '
        '  #B         ##     '
        '  ####     ###      '
        '     #^^^^^#        '
        '     #######        '
        '                    '
        '                    '
        { A = tolayer(4), B = tolayer(5) }

    create_stage(4)
        '  #    #######     #'
        '  #    #  +  #     #'
        '  #    # ###A#     #'
        '  #    #B# ###     #'
        '  #    ###     #   #'
        '  #               ##'
        '  #    ^           #'
        '  ###### ###   #####'
        '  #           ##    '
        '  #A         ##     '
        '  ####     ###      '
        '     #^^^^^#        '
        '     #######        '
        '                    '
        '                    '
        { A = tolayer(3), B = tolayer_single(3) }

    create_stage(5)
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '                    '
        '  ##########        '
        '  #  ABCD  #        '
        '  ##########        '
        '                    '
        '                    '
        '                    '
        '                    '
        { A = msign(0), B = msign(1), C = msign(2), D = msign(3) }

end

return stages
