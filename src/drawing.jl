#####
##### colors
#####

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const dark_gray = MFB.mfb_rgb(95, 95, 95)
const red = MFB.mfb_rgb(255, 0, 0)
const green = MFB.mfb_rgb(0, 255, 0)
const blue = MFB.mfb_rgb(0, 0, 255)
const dark_blue = MFB.mfb_rgb(0, 0, 127)

#####
##### draw tile map
#####

function draw_tile_map!(image::AbstractMatrix, tile_map)

    height_tm_tu = GW.get_height(tile_map)
    width_tm_tu = GW.get_width(tile_map)

    pu_per_tu = size(image, 1) ÷ height_tm_tu

    for j in 1:width_tm_tu
        for i in 1:height_tm_tu
            color = get_tile_color(tile_map, i, j)

            top_left_i = get_tile_start_pu(i, pu_per_tu)
            top_left_j = get_tile_start_pu(j, pu_per_tu)
            bottom_right_i = get_tile_stop_pu(i, pu_per_tu)
            bottom_right_j = get_tile_stop_pu(j, pu_per_tu)

            draw_rectangle!(image, top_left_i, top_left_j, bottom_right_i, bottom_right_j, color)
        end
    end

    return nothing
end

function get_tile_color(tile_map, i::Integer, j::Integer)
    if tile_map[GW.WALL, i, j]
        color = white
    elseif tile_map[GW.GOAL, i, j]
        color = blue
    else
        color = black
    end

    return color
end

function draw_tile_map_boundaries!(image::AbstractMatrix, pu_per_tu, color)
    height_image_pu = size(image, 1)
    width_image_pu = size(image, 2)

    image[1:pu_per_tu:height_image_pu, :] .= color
    image[:, 1:pu_per_tu:width_image_pu] .= color

    return nothing
end

#####
##### cast single ray
#####

function cast_ray(tile_map, ray_dir, pos_wu, wu_per_tu)
    T = typeof(wu_per_tu)
    # height_tm_tu = size(tm, 2)
    height_tm_tu = GW.get_height(tile_map)
    pos_x, pos_y = pos_wu
    map_x = wu_to_tu(pos_x, wu_per_tu) - 1
    map_y = wu_to_tu(pos_y, wu_per_tu) - 1

    ray_dir_x, ray_dir_y = ray_dir
    delta_dist_x = abs(1 / ray_dir_x)
    delta_dist_y = abs(1 / ray_dir_y)

    if ray_dir_x < zero(T)
        step_x = -1
        side_dist_x = (pos_x - map_x) * delta_dist_x
    else
        step_x = 1
        side_dist_x = (map_x + 1 - pos_x) * delta_dist_x
    end

    if ray_dir_y < zero(T)
        step_y = -1
        side_dist_y = (pos_y - map_y) * delta_dist_y
    else
        step_y = 1
        side_dist_y = (map_y + 1 - pos_y) * delta_dist_y
    end

    hit = 0
    dist = Inf
    hit_pos_tu = (1, 1)
    side = 0

    while (hit == 0)
        dist = min(side_dist_x, side_dist_y)

        if (side_dist_x < side_dist_y)
            side_dist_x += delta_dist_x
            map_x += step_x
            side = 0
        else
            side_dist_y += delta_dist_y
            map_y += step_y
            side = 1
        end

        hit_pos_tu = map_to_tu((map_x, map_y), height_tm_tu)
        if tile_map[GW.WALL, hit_pos_tu...] || tile_map[GW.GOAL, hit_pos_tu...]
            hit = 1
        end
    end

    return dist, side, hit_pos_tu
end

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
