function test_mfb()
    height = 256
    width = 256
    row_indexed_buffer = zeros(UInt32, width, height)
    buffer = PermutedDimsArray(row_indexed_buffer, (2, 1))
    window = MFB.mfb_open_ex("Test", width, height, MFB.WF_RESIZABLE);

    while MFB.mfb_wait_sync(window)
        for i in 1:128
            for j in 1:64
                buffer[i, j] = MFB.mfb_rgb(0, 255, 0)
            end
        end

        state = MFB.mfb_update(window, buffer)

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)
end

function render_world(world, frame_height, frame_width)
    world_height = GW.get_height(world)
    world_width = GW.get_width(world)

    tile_height = frame_height ÷ world_height
    tile_width = frame_width ÷ world_width

    row_indexed_buffer = zeros(UInt32, frame_width, frame_height)
    buffer = PermutedDimsArray(row_indexed_buffer, (2, 1))
    window = MFB.mfb_open_ex("Test", frame_width, frame_height, MFB.WF_RESIZABLE);

    while MFB.mfb_wait_sync(window)
        for i in 1:world_height
            for j in 1:world_width
                if world[GW.WALL, i, j]
                    start_height = (i - 1) * tile_height + 1
                    stop_height = start_height + tile_height - 1
                    start_width = (j - 1) * tile_width + 1
                    stop_width = start_width + tile_width - 1
                    buffer[start_height:stop_height, start_width:stop_width] .= MFB.mfb_rgb(255, 255, 255)
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
