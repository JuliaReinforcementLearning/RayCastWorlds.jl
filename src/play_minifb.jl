module PlayMiniFB

import MiniFB

function copy_image_to_frame_buffer!(frame_buffer, image)
    height_image, width_image = size(image)
    for j in 1:width_image
        for i in 1:height_image
            frame_buffer[j, i] = reinterpret(UInt32, image[i, j])
        end
    end

    return nothing
end

end # module
