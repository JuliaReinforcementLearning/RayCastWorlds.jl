# colors

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const dark_gray = MFB.mfb_rgb(95, 95, 95)
const red = MFB.mfb_rgb(255, 0, 0)
const green = MFB.mfb_rgb(0, 255, 0)
const blue = MFB.mfb_rgb(0, 0, 255)
const dark_blue = MFB.mfb_rgb(0, 0, 127)

# simple drawing method

function draw_rectangle!(img::AbstractMatrix, top_left_i::Integer, top_left_j::Integer, bottom_right_i::Integer, bottom_right_j::Integer, value)
    img[top_left_i:bottom_right_i, top_left_j:bottom_right_j] .= value
end

function draw_circle!(img::AbstractMatrix, center_i::Integer, center_j::Integer, radius::Integer, value)
    for j in center_j - radius : center_j + radius
        for i in center_i - radius : center_i + radius
            if (center_i - i) .^ 2 + (center_j - j) .^ 2 <= radius ^ 2
                img[i, j] = value
            end
        end
    end

    return nothing
end

# Ref: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
function draw_line!(img::AbstractMatrix, i0::Int, j0::Int, i1::Int, j1::Int, value)
    di = abs(i1 - i0)
    dj = -abs(j1 - j0)
    si = i0 < i1 ? 1 : -1
    sj = j0 < j1 ? 1 : -1
    err = di + dj

    while true
        img[i0, j0] = value

        if (i0 == i1 && j0 == j1)
            break
        end

        e2 = 2 * err

        if (e2 >= dj)
            err += dj
            i0 += si
        end

        if (e2 <= di)
            err += di
            j0 += sj
        end
    end

    return nothing
end

function draw_tile_map!(img::AbstractMatrix, tile_map)

    height_tm_tu = size(tile_map, 2)
    width_tm_tu = size(tile_map, 3)

    pu_per_tu = size(img, 1) ÷ height_tm_tu

    for j in 1:width_tm_tu
        for i in 1:height_tm_tu
            color = get_tile_color(tile_map, i, j)

            top_left_i = get_tile_start_pu(i, pu_per_tu)
            top_left_j = get_tile_start_pu(j, pu_per_tu)
            bottom_right_i = get_tile_stop_pu(i, pu_per_tu)
            bottom_right_j = get_tile_stop_pu(j, pu_per_tu)

            draw_rectangle!(img, top_left_i, top_left_j, bottom_right_i, bottom_right_j, color)
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

function draw_tile_map_boundaries!(img::AbstractMatrix, pu_per_tu, color)
    height_tv_pu = size(img, 1)
    width_tv_pu = size(img, 2)

    img[1:pu_per_tu:height_tv_pu, :] .= color
    img[:, 1:pu_per_tu:width_tv_pu] .= color

    return nothing
end

# cast ray

function cast_ray(tm, ray_dir, pos_wu, wu_per_tu)
    T = typeof(wu_per_tu)
    height_tm_tu = size(tm, 2)
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
        if tm[GW.WALL, hit_pos_tu...] || tm[GW.GOAL, hit_pos_tu...]
            hit = 1
        end
    end

    return dist, side, hit_pos_tu
end

# draw av

function draw_av!(av, tm, agent_position, agent_direction, semi_fov, num_rays, wu_per_tu)
    height_av_pu = size(av, 1)
    ray_dirs = get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(tm, ray_dir, agent_position, wu_per_tu)

        per_dist = dist * sum(agent_direction .* ray_dir)
        height_line_pu = floor(Int, height_av_pu / per_dist)

        idx = num_rays - ray_idx + 1

        if tm[GW.WALL, hit_pos_tu...] && side == 1
            color = dark_gray
        elseif tm[GW.WALL, hit_pos_tu...] && side == 0
            color = gray
        elseif tm[GW.GOAL, hit_pos_tu...] && side == 1
            color = dark_blue
        elseif tm[GW.GOAL, hit_pos_tu...] && side == 0
            color = blue
        end

        if height_line_pu >= height_av_pu - 1
            av[:, idx] .= color
        else
            padding_pu = (height_av_pu - height_line_pu) ÷ 2
            av[1:padding_pu, idx] .= white
            av[padding_pu + 1 : end - padding_pu, idx] .= color
            av[end - padding_pu + 1 : end, idx] .= black
        end
    end

    return nothing
end

# draw tv

function draw_tv!(tv, tm, agent_position, agent_direction, semi_fov, num_rays, wu_per_tu, pu_per_tu, pu_per_wu, height_world_wu, radius_pu)
    draw_tile_map!(tv, tm)
    draw_tile_map_boundaries!(tv, pu_per_tu, gray)
    # draw_agent
    draw_circle!(tv, get_agent_center_pu(agent_position, pu_per_wu, height_world_wu)..., radius_pu, green)

    # draw_rays
    ray_start_pu = get_agent_center_pu(agent_position, pu_per_wu, height_world_wu)
    ray_dirs = get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(tm, ray_dir, agent_position, wu_per_tu)
        ray_stop_wu = agent_position + dist * ray_dir
        ray_stop_pu = wu_to_pu(ray_stop_wu, pu_per_wu, height_world_wu)
        draw_line!(tv, ray_start_pu..., ray_stop_pu..., red)
    end

    return nothing
end
