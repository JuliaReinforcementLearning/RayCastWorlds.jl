module RayCaster

import MiniFB as MFB
import GridWorlds as GW

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

include("world.jl")
include("render.jl")

end
