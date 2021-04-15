mutable struct Agent{T}
    position::SA.SVector{2, T}
    direction::SA.SVector{2, T}
    camera_plane::SA.SVector{2, T}
end

struct World{T}
    tile_map::GW.GridWorldBase{Tuple{GW.Wall}}
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
    objects = (GW.WALL,)
    tile_map = GW.GridWorldBase(objects, height, width)

    for pos in keys(tm_layout)
        if tm_layout[pos] == 1
            tile_map[GW.WALL, pos] = true
        end
    end

    return tile_map
end

rotate(x, y, c, s) = SA.SVector(c * x - s * y, s * x + c * y)
rotate(vec, dir) = rotate(vec[1], vec[2], dir[1], dir[2])
rotate_plus_90(vec) = typeof(vec)(-vec[2], vec[1])
rotate_minus_90(vec) = typeof(vec)(vec[2], -vec[1])
rotate_180(vec) = -vec
