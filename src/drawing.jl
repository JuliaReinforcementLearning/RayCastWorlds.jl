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
        step_x = -1
        side_dist_x = (x_start_position_wu - i_tu) * delta_dist_x
    else
        step_x = 1
        side_dist_x = (i_tu + 1 - x_start_position_wu) * delta_dist_x
    end

    if y_direction_wu < zero_wu
        step_y = -1
        side_dist_y = (y_start_position_wu - j_tu) * delta_dist_y
    else
        step_y = 1
        side_dist_y = (j_tu + 1 - y_start_position_wu) * delta_dist_y
    end

    has_hit = false
    side_dist_wu = Inf
    i_hit_position_tu = -1
    j_hit_position_tu = -1
    hit_side = 0

    while !has_hit
        side_dist_wu = min(side_dist_x, side_dist_y)

        if (side_dist_x < side_dist_y)
            side_dist_x += delta_dist_x
            i_tu += step_x
            side = 0
        else
            side_dist_y += delta_dist_y
            j_tu += step_y
            side = 1
        end

        has_hit = obstacle_map[i_hit_position_tu, j_hit_position_tu]
    end

    return side_dist_wu, hit_side, i_hit_position_tu, j_hit_position_tu
end
# function cast_ray(obstacle_map, ray_start_position::AbstractArray{T, 1}, ray_direction) where {T}
    # height_obstacle_map = size(obstacle_map, 1)

    # ray_start_position_x, ray_start_position_y = ray_start_position
    # map_x = floor(Int, ray_start_position_x)
    # map_y = floor(Int, ray_start_position_y)

    # ray_direction_x, ray_direction_y = ray_direction
    # delta_dist_x = abs(1 / ray_direction_x)
    # delta_dist_y = abs(1 / ray_direction_y)

    # if ray_direction_x < zero(T)
        # step_x = -1
        # side_dist_x = (ray_start_position_x - map_x) * delta_dist_x
    # else
        # step_x = 1
        # side_dist_x = (map_x + 1 - ray_start_position_x) * delta_dist_x
    # end

    # if ray_direction_y < zero(T)
        # step_y = -1
        # side_dist_y = (ray_start_position_y - map_y) * delta_dist_y
    # else
        # step_y = 1
        # side_dist_y = (map_y + 1 - ray_start_position_y) * delta_dist_y
    # end

    # has_hit = false
    # side_dist = Inf
    # hit_pos_tu = (1, 1)
    # side = 0

    # i_obstacle_map = height_obstacle_map - map_y
    # j_obstacle_map = map_x + 1

    # while !has_hit
        # side_dist = min(side_dist_x, side_dist_y)

        # if (side_dist_x < side_dist_y)
            # side_dist_x += delta_dist_x
            # map_x += step_x
            # side = 0
        # else
            # side_dist_y += delta_dist_y
            # map_y += step_y
            # side = 1
        # end

        # i_obstacle_map = height_obstacle_map - map_y
        # j_obstacle_map = map_x + 1
        # has_hit = obstacle_map[i_obstacle_map, j_obstacle_map]
    # end

    # return side_dist, side, CartesianIndex(i_obstacle_map, j_obstacle_map)
# end

#####
##### draw agent view
#####

function draw_av!(image, tile_map, position, direction, semi_fov, num_rays, wu_per_tu)
    height_image_pu = size(image, 1)
    ray_dirs = get_rays(direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(tile_map, ray_dir, position, wu_per_tu)

        per_dist = dist * sum(direction .* ray_dir)
        height_line_pu = floor(Int, height_image_pu / per_dist)

        idx = num_rays - ray_idx + 1

        if tile_map[GW.WALL, hit_pos_tu...] && side == 1
            color = dark_gray
        elseif tile_map[GW.WALL, hit_pos_tu...] && side == 0
            color = gray
        elseif tile_map[GW.GOAL, hit_pos_tu...] && side == 1
            color = dark_blue
        elseif tile_map[GW.GOAL, hit_pos_tu...] && side == 0
            color = blue
        end

        if height_line_pu >= height_image_pu - 1
            image[:, idx] .= color
        else
            padding_pu = (height_image_pu - height_line_pu) ÷ 2
            image[1:padding_pu, idx] .= white
            image[padding_pu + 1 : end - padding_pu, idx] .= color
            image[end - padding_pu + 1 : end, idx] .= black
        end
    end

    return nothing
end

#####
##### draw top view
#####

function draw_top_view!(image, tile_map, position, direction, semi_fov, num_rays, wu_per_tu, pu_per_tu, pu_per_wu, height_world_wu, radius_pu)
    # draw tile map
    draw_tile_map!(image, tile_map)

    # draw agent
    draw_circle!(image, get_agent_center_pu(position, pu_per_wu, height_world_wu)..., radius_pu, green)

    # draw rays
    ray_start_pu = get_agent_center_pu(position, pu_per_wu, height_world_wu)
    ray_dirs = get_rays(direction, semi_fov, num_rays)
    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(tile_map, ray_dir, position, wu_per_tu)
        ray_stop_wu = position + dist * ray_dir
        ray_stop_pu = wu_to_pu(ray_stop_wu, pu_per_wu, height_world_wu)
        draw_line!(image, ray_start_pu..., ray_stop_pu..., red)
    end

    return nothing
end

function draw_tv!(image, tile_map, position, direction, semi_fov, num_rays, wu_per_tu, pu_per_tu, pu_per_wu, height_world_wu, radius_pu)
    # draw tile map
    draw_tile_map!(image, tile_map)
    draw_tile_map_boundaries!(image, pu_per_tu, gray)

    # draw agent
    draw_circle!(image, get_agent_center_pu(position, pu_per_wu, height_world_wu)..., radius_pu, green)

    # draw rays
    ray_start_pu = get_agent_center_pu(position, pu_per_wu, height_world_wu)
    ray_dirs = get_rays(direction, semi_fov, num_rays)
    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(tile_map, ray_dir, position, wu_per_tu)
        ray_stop_wu = position + dist * ray_dir
        ray_stop_pu = wu_to_pu(ray_stop_wu, pu_per_wu, height_world_wu)
        draw_line!(image, ray_start_pu..., ray_stop_pu..., red)
    end

    return nothing
end
