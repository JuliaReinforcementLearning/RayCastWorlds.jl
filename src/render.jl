function render_world(world, height_frame, width_frame)
    height_world = world.height
    width_world = world.width
    agent = world.agent

    tile_map = world.tile_map
    height_tile_map = GW.get_height(tile_map)
    width_tile_map = GW.get_width(tile_map)

    height_tile = height_frame ÷ height_tile_map
    width_tile = width_frame ÷ width_tile_map
    pixels_per_unit_world = height_frame / height_world

    row_indexed_buffer = zeros(UInt32, width_frame, height_frame)
    buffer = PermutedDimsArray(row_indexed_buffer, (2, 1))
    window = MFB.mfb_open_ex("Test", width_frame, height_frame, MFB.WF_RESIZABLE);
    MFB.mfb_set_keyboard_callback(window, show_key)

    draw_tile_map!(buffer, tile_map, height_tile, width_tile)
    agent_radius_frame = world_to_frame(agent.radius, pixels_per_unit_world)

    while MFB.mfb_wait_sync(window)

        agent_origin_frame = get_agent_origin_frame(agent, height_world, width_world, pixels_per_unit_world)
        draw_agent!(buffer, agent_origin_frame..., agent_radius_frame)

        state = MFB.mfb_update(window, buffer)

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)
end

function show_key(window, key, mod, isPressed)::Cvoid
    if isPressed
        if key == MFB.KB_KEY_UP
            display(key)
        elseif key == MFB.KB_KEY_DOWN
            display(key)
        elseif key == MFB.KB_KEY_LEFT
            display(key)
        elseif key == MFB.KB_KEY_RIGHT
            display(key)
        elseif key == MFB.KB_KEY_ESCAPE
            MFB.mfb_close(window)
        end
    end
end

tile_map_to_frame(i_tile_map, height_tile_frame) = (i_tile_map - 1) * height_tile_frame + 1
tile_map_to_frame(i_tile_map, j_tile_map, height_tile_frame, width_tile_frame) = (tile_map_to_frame(i_tile_map, height_tile_frame), tile_map_to_frame(j_tile_map, width_tile_frame))

frame_to_tile_map(i_frame, height_tile_frame) = (i_frame - 1) ÷ height_tile_frame + 1
frame_to_tile_map(i_frame, j_frame, height_tile_frame, width_tile_frame) = (frame_to_tile_map(i_frame, height_tile_frame), frame_to_tile_map(j_frame, width_tile_frame))

world_to_frame(distance_world, pixels_per_unit_world) = floor(Int, pixels_per_unit_world * distance_world)
world_to_frame(x, y, height_world, width_world, pixels_per_unit_world) = (world_to_frame(height_world - y, pixels_per_unit_world), world_to_frame(width_world - x, pixels_per_unit_world))

function get_agent_origin_frame(agent, height_world, width_world, pixels_per_unit_world)
    radius_frame = world_to_frame(agent.radius, pixels_per_unit_world)
    i_frame, j_frame = world_to_frame(agent.position..., height_world, width_world, pixels_per_unit_world)
    return (i_frame - radius_frame + 1, j_frame - radius_frame + 1)
end

function draw_tile_map!(buffer, tile_map, height_tile, width_tile)
    height_tile_map = GW.get_height(tile_map)
    width_tile_map = GW.get_width(tile_map)

    for i in 1:height_tile_map
        for j in 1:width_tile_map
            if tile_map[GW.WALL, i, j]
                wall_start_height_frame, wall_start_width_frame = tile_map_to_frame(i, j, height_tile, width_tile)
                wall_stop_height_frame = wall_start_height_frame + height_tile - 1
                wall_stop_width_frame = wall_start_width_frame + width_tile - 1
                buffer[wall_start_height_frame:wall_stop_height_frame, wall_start_width_frame:wall_stop_width_frame] .= MFB.mfb_rgb(255, 255, 255)
            end
        end
    end
end

function draw_agent!(buffer, start_i, start_j, radius)
    distance = 2 * radius - 1
    center_i = start_i + radius - 1
    center_j = start_j + radius - 1

    map(CartesianIndices((start_i : start_i + distance - 1, start_j : start_j + distance - 1))) do pos
        color = (pos[1] - center_i) ^ 2 + (pos[2] - center_j) ^ 2 <= radius ^ 2 ? MFB.mfb_rgb(127, 127, 127) : MFB.mfb_rgb(0, 0, 0)
        buffer[pos] = color
    end

    return nothing
end
