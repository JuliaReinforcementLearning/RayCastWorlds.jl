mutable struct Agent{T}
    position::SA.SVector{2, T}
    direction::SA.SVector{2, T}
    camera_plane::SA.SVector{2, T}
end

struct World{T}
    tile_map::GW.GridWorldBase{Tuple{GW.Agent, GW.Wall}}
    height::T
    width::T
    agent::Agent{T}
end

function generate_tile_map(height = 8, width = 8)
    objects = (GW.AGENT, GW.WALL)
    tile_map = GW.GridWorldBase(objects, height, width)

    room = GW.Room(CartesianIndex(1, 1), height, width)
    GW.place_room!(tile_map, room)

    agent_pos = CartesianIndex(2, 2)
    tile_map[GW.AGENT, agent_pos] = true

    return tile_map
end

rotate(x, y, c, s) = SA.SVector(c * x - s * y, s * x + c * y)
rotate(vec, dir) = rotate(vec[1], vec[2], dir[1], dir[2])
rotate_plus_90(vec) = typeof(vec)(-vec[2], vec[1])
rotate_minus_90(vec) = typeof(vec)(vec[2], -vec[1])
rotate_180(vec) = -vec
