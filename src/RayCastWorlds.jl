module RayCastWorlds

import Random
import RayCaster as RC
import StaticArrays as SA

reset!(world) = error("Method not implemented")
act!(world) = error("Method not implemented")
cast_rays!(world) = error("Method not implemented")
get_action_keys(env) = error("Method not implemented")
get_action_names(env) = error("Method not implemented")
play!(env) = error("Method not implemented")
update_top_view!(env) = error("Method not implemented")
update_camera_view!(env) = error("Method not implemented")

function copy_image_to_frame_buffer!(frame_buffer, image)
    height_image, width_image = size(image)
    for j in 1:width_image
        for i in 1:height_image
            frame_buffer[j, i] = image[i, j]
        end
    end

    return nothing
end

include("units.jl")
include("collision_detection.jl")
include("navigation.jl")
include("single_room_world.jl")
include("single_room_game.jl")

end
