const BLOCK_EMPTY_SHADED = ' '
const BLOCK_QUARTER_SHADED = '░'
const BLOCK_HALF_SHADED = '▒'
const BLOCK_THREE_QUARTER_SHADED = '▓'
const BLOCK_FULL_SHADED = '█'

#####
##### draw tile map
#####

function draw_tile_map!(image, tile_map, colors)

    num_objects, height_tile_map, width_tile_map = size(tile_map)

    pu_per_tu = size(image, 1) ÷ height_tile_map

    for j in 1:width_tile_map
        for i in 1:height_tile_map
            i_top_left = (i - 1) * pu_per_tu + 1
            j_top_left = (j - 1) * pu_per_tu + 1

            shape = SD.FilledRectangle(i_top_left, j_top_left, pu_per_tu, pu_per_tu)

            object_id = findfirst(@view tile_map[:, i, j])
            color = colors[object_id]

            SD.draw!(image, shape, color)
        end
    end

    return nothing
end

#####
##### cast single ray
#####

function cast_ray(obstacle_map, start_position_wu::AbstractArray{T, 1}, direction_wu) where {T}
    x_start_position_wu, y_start_position_wu = start_position_wu
    i_tu, j_tu = wu_to_tu.(start_position_wu)
    zero_wu = zero(T)

    x_direction_wu, y_direction_wu = direction_wu
    delta_dist_x_wu = abs(1 / x_direction_wu)
    delta_dist_y_wu = abs(1 / y_direction_wu)

    if x_direction_wu < zero_wu
        i_step_tu = -1
        side_dist_x_wu = (x_start_position_wu - i_tu + 1) * delta_dist_x_wu
    else
        i_step_tu = 1
        side_dist_x_wu = (i_tu - x_start_position_wu) * delta_dist_x_wu
    end

    if y_direction_wu < zero_wu
        j_step_tu = -1
        side_dist_y_wu = (y_start_position_wu - j_tu + 1) * delta_dist_y_wu
    else
        j_step_tu = 1
        side_dist_y_wu = (j_tu - y_start_position_wu) * delta_dist_y_wu
    end

    has_hit = false
    side_dist_wu = Inf
    hit_dimension = 0

    while !obstacle_map[i_tu, j_tu]

        if (side_dist_x_wu <= side_dist_y_wu)
            side_dist_wu = side_dist_x_wu
            side_dist_x_wu += delta_dist_x_wu
            i_tu += i_step_tu
            hit_dimension = 1
        else
            side_dist_wu = side_dist_y_wu
            side_dist_y_wu += delta_dist_y_wu
            j_tu += j_step_tu
            hit_dimension = 2
        end

    end

    return side_dist_wu, hit_dimension, i_tu, j_tu
end
