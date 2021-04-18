mutable struct Agent{T}
    position::SA.SVector{2, T}
    direction::SA.SVector{2, T}
    camera_plane::SA.SVector{2, T}
end

struct World{O, T}
    tile_map::GW.GridWorldBase{O}
    height::T
    width::T
    agent::Agent{T}
end

function generate_tile_map(height = 8, width = 8)
    objects = (GW.WALL,)
    tile_map = GW.GridWorldBase(objects, height, width)

    room = GW.Room(CartesianIndex(1, 1), height, width)
    GW.place_room!(tile_map, room)

    return tile_map
end

function generate_tile_map(tm_layout::Matrix{Int})
    height = size(tm_layout, 1)
    width = size(tm_layout, 2)
    objects = (GW.WALL, GW.GOAL)
    tile_map = GW.GridWorldBase(objects, height, width)

    for pos in keys(tm_layout)
        if tm_layout[pos] == 1
            tile_map[GW.WALL, pos] = true
        elseif tm_layout[pos] == 2
            tile_map[GW.GOAL, pos] = true
        end
    end

    return tile_map
end
