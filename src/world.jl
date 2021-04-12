mutable struct Agent{T}
    position::SA.SVector{2, T}
    direction::SA.SVector{2, T}
    speed::T
    radius::T
end

struct Environment{T}
    world::GW.GridWorldBase{Tuple{GW.Agent, GW.Wall}}
    height::T
    width::T
    agent::Agent{T}
end

function generate_world(height = 8, width = 8)
    objects = (GW.AGENT, GW.WALL)
    world = GW.GridWorldBase(objects, height, width)

    room = GW.Room(CartesianIndex(1, 1), height, width)
    GW.place_room!(world, room)

    agent_pos = CartesianIndex(2, 2)
    world[GW.AGENT, agent_pos] = true

    return world
end
