function generate_world(height = 8, width = 8)
    objects = (GW.AGENT, GW.WALL)
    world = GW.GridWorldBase(objects, height, width)

    room = GW.Room(CartesianIndex(1, 1), height, width)
    GW.place_room!(world, room)

    agent_pos = CartesianIndex(2, 2)
    world[GW.AGENT, agent_pos] = true

    return world
end
