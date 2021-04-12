function render_world(world, height_frame, width_frame)
    height_world = world.height
    width_world = world.width

    tile_map = world.tile_map
    height_tile_map = GW.get_height(tile_map)
    width_tile_map = GW.get_width(tile_map)

    height_tile = height_frame ÷ height_tile_map
    width_tile = width_frame ÷ width_tile_map

    row_indexed_buffer = zeros(UInt32, width_frame, height_frame)
    buffer = PermutedDimsArray(row_indexed_buffer, (2, 1))
    window = MFB.mfb_open_ex("Test", width_frame, height_frame, MFB.WF_RESIZABLE);
    MFB.mfb_set_keyboard_callback(window, show_key)

    while MFB.mfb_wait_sync(window)
        draw_tile_map!(buffer, tile_map, height_tile, width_tile)

        agent_radius_frame = floor(Int, width_frame * world.agent.radius / width_world)
        agent_pos_frame = CartesianIndex(floor(Int, height_frame * world.agent.position[2] / height_world), floor(Int, width_frame * world.agent.position[1] / width_world))
        for i in agent_pos_frame[1] - agent_radius_frame + 1 : agent_pos_frame[1] + agent_radius_frame - 1
            for j in agent_pos_frame[2] - agent_radius_frame + 1 : agent_pos_frame[2] + agent_radius_frame - 1
                if (i-agent_pos_frame[1])^2 + (j-agent_pos_frame[2])^2 <= agent_radius_frame^2
                    buffer[i, j] = MFB.mfb_rgb(127, 127, 127)
                else
                    buffer[i, j] = MFB.mfb_rgb(0, 0, 0)
                end
            end
        end

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

tile_map_to_frame(i_tile_map, j_tile_map, height_tile, width_tile) = ((i_tile_map - 1) * height_tile + 1, (j_tile_map - 1) * width_tile + 1)
frame_to_tile_map(i_frame, j_frame, height_tile, width_tile) = ((i_frame - 1) ÷ height_tile + 1, (j_frame - 1) ÷ width_tile + 1)

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
