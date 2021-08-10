module RayCastWorlds

import ReinforcementLearningBase as RLBase

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

function sample_empty_position(rng, tile_map, region, max_tries)
    position = rand(rng, region)

    for i in 1:max_tries
        if any(@view tile_map[:, position])
            position = rand(rng, region)
        else
            return position
        end
    end

    @warn "Could not sample an empty position in max_tries = $(max_tries). Returning non-empty position: $(position)"

    return position
end

function sample_empty_position(rng, tile_map, region)
    max_tries = 1024 * length(region)
    position = sample_empty_position(rng, tile_map, region, max_tries)
    return position
end

function sample_empty_position(rng, tile_map, max_tries::Integer)
    _, height, width = size(tile_map)
    region = CartesianIndices((1 : height, 1 : width))
    position = sample_empty_position(rng, tile_map, region, max_tries)
    return position
end

function sample_empty_position(rng, tile_map)
    _, height, width = size(tile_map)
    region = CartesianIndices((1 : height, 1 : width))
    max_tries = 1024 * height * width
    position = sample_empty_position(rng, tile_map, region, max_tries)
    return position
end

abstract type AbstractGame end

include("units.jl")
include("collision_detection.jl")
include("navigation.jl")
include("rlbase.jl")
include("single_room.jl")

end
