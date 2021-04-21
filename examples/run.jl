import GridWorlds as GW
import MiniFB as MFB
import RayCaster as RC
import StaticArrays as SA
import ReinforcementLearningBase as RLBase

const T = Float32

# units

const tu_per_wu = convert(T, 1)
const wu_per_tu = 1 / tu_per_wu
const pu_per_tu = 32
const pu_per_wu = pu_per_tu * tu_per_wu

# tile map

const height_tm_tu = 8
const width_tm_tu = 16

tm_layout = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
             1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1
             1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1
             1 0 0 1 0 0 0 0 1 0 0 0 0 0 2 1
             1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1
             1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
             1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
             1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
            ]

const tm = RC.generate_tile_map(tm_layout)

# agent

const theta_30 = convert(T, pi / 6)
const radius_wu = convert(T, 0.5)
const position_increment = convert(T, 0.05)
const theta_increment = convert(T, pi / 60)
const direction_increment = SA.SVector(cos(theta_increment), sin(theta_increment))
const direction_decrement = SA.SVector(direction_increment[1], -direction_increment[2])

agent_position = SA.SVector(convert(T, 4.5), convert(T, 2.5))
agent_direction = SA.SVector(cos(theta_30), sin(theta_30))
camera_plane = RC.rotate_minus_90(agent_direction)

const agent = RC.Agent(agent_position,
                       agent_direction,
                       camera_plane,
                      )

const circle = RC.StdCircle(radius_wu)

# rays

const num_rays = 256
const semi_fov = convert(T, pi / 6)

# world

const height_world_wu = convert(T, height_tm_tu / tu_per_wu)
const width_world_wu = convert(T, width_tm_tu / tu_per_wu)

const world = RC.World(tm, height_world_wu, width_world_wu, agent)

const tile_half_side_wu = wu_per_tu / 2
const square = RC.StdSquare(tile_half_side_wu)

# img

const height_tv_pu = pu_per_tu * height_tm_tu
const width_tv_pu = pu_per_tu * width_tm_tu

const height_av_pu = num_rays
const width_av_pu = num_rays

const height_cv_pu = max(height_tv_pu, height_av_pu)
const width_cv_pu = width_tv_pu + width_av_pu

const tv = zeros(UInt32, height_tv_pu, width_tv_pu)
const av = zeros(UInt32, height_av_pu, width_av_pu)

const fb_tv = zeros(UInt32, width_tv_pu, height_tv_pu)
const fb_av = zeros(UInt32, width_av_pu, height_av_pu)
const fb_cv = zeros(UInt32, width_cv_pu, height_cv_pu)
const fb_cv_tv = view(fb_cv, 1:width_tv_pu, 1:height_tv_pu)
const fb_cv_av = view(fb_cv, width_tv_pu + 1 : width_cv_pu, 1:height_av_pu)

# colors

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const dark_gray = MFB.mfb_rgb(95, 95, 95)
const red = MFB.mfb_rgb(255, 0, 0)
const green = MFB.mfb_rgb(0, 255, 0)
const blue = MFB.mfb_rgb(0, 0, 255)
const dark_blue = MFB.mfb_rgb(0, 0, 127)

# conversion

wu_to_pu(x_wu::AbstractFloat) = floor(Int, x_wu * pu_per_wu) + 1
wu_to_pu((x_wu, y_wu)) = (wu_to_pu(height_world_wu - y_wu), wu_to_pu(x_wu))
wu_to_tu(x_wu::AbstractFloat) = floor(Int, x_wu * tu_per_wu) + 1
wu_to_tu((x_wu, y_wu)) = (wu_to_tu(height_world_wu - y_wu), wu_to_tu(x_wu))
pu_to_tu(i_pu::Integer) = (i_pu - 1) ÷ pu_per_tu + 1

# tile map region

get_tile_map_region_tu() = CartesianIndices((1:height_tm_tu, 1:width_tm_tu))

# tile region

get_tile_bottom_left_wu((i_tu, j_tu)) = ((j_tu - 1) * wu_per_tu, (height_tm_tu - i_tu) * wu_per_tu)
get_tile_center_wu(tile_tu) = get_tile_bottom_left_wu(tile_tu) .+ tile_half_side_wu
get_tile_top_left_pu(tile_tu) = (tile_tu .- 1) .* pu_per_tu .+ 1
get_tile_bottom_right_pu(tile_tu) = tile_tu .* pu_per_tu
function get_tile_region_pu(tile_tu)
    start_i, start_j = get_tile_top_left_pu(tile_tu)
    stop_i, stop_j = get_tile_bottom_right_pu(tile_tu)
    return CartesianIndices((start_i:stop_i, start_j:stop_j))
end

# agent region

const radius_pu = wu_to_pu(radius_wu)

get_agent_center_pu() = wu_to_pu(agent.position)
get_agent_top_left_pu(center_pu) = center_pu .- (radius_pu - 1)
get_agent_bottom_right_pu(center_pu) = center_pu .+ (radius_pu - 1)
function get_agent_region_pu(center_pu)
    start_i, start_j = get_agent_top_left_pu(center_pu)
    stop_i, stop_j = get_agent_bottom_right_pu(center_pu)
    return CartesianIndices((start_i:stop_i, start_j:stop_j))
end
get_agent_region_pu() = get_agent_region_pu(get_agent_center_pu())

get_agent_bottom_left_tu(center_wu) = wu_to_tu(center_wu .- radius_wu)
get_agent_top_right_tu(center_wu) = wu_to_tu(center_wu .+ radius_wu)

function get_agent_region_tu(center_wu)
    start_i, stop_j = get_agent_top_right_tu(center_wu)
    stop_i, start_j = get_agent_bottom_left_tu(center_wu)
    return CartesianIndices((start_i:stop_i, start_j:stop_j))
end

# main

function draw_tile_map()
    map(get_tile_map_region_tu()) do pos
        if tm[GW.WALL, pos]
            tv[get_tile_region_pu(pos.I)] .= white
        elseif tm[GW.GOAL, pos]
            tv[get_tile_region_pu(pos.I)] .= blue
        else
            tv[get_tile_region_pu(pos.I)] .= black
        end
        return nothing
    end

    return nothing
end

function draw_tile_map_boundaries()
    tv[1:pu_per_tu:height_tv_pu, :] .= gray
    tv[:, 1:pu_per_tu:width_tv_pu] .= gray
    return nothing
end

draw_agent() = RC.draw_circle!(tv, get_agent_center_pu()..., radius_pu, green)

function draw_agent_direction()
    i0, j0 = get_agent_center_pu()
    i1 = wu_to_pu(height_world_wu - (agent.position[2] + radius_wu * agent.direction[2] / 2))
    j1 = wu_to_pu(agent.position[1] + radius_wu * agent.direction[1] * 3 / 4)
    RC.draw_line!(tv, i0, j0, i1, j1, red)
    return nothing
end

function clear_agent()
    tv[get_agent_region_pu()] .= black
    return nothing
end

is_agent_colliding(center_wu) = any(pos -> (tm[GW.WALL, pos] || tm[GW.GOAL, pos]) && RC.is_colliding(square, circle, center_wu .- get_tile_center_wu(pos.I)), get_agent_region_tu(center_wu))

map_to_tu((map_x, map_y)) = (height_tm_tu - map_y, map_x + 1)

function draw_rays_tv()
    ray_start_pu = get_agent_center_pu()
    agent_position = agent.position
    agent_direction = agent.direction
    ray_dirs = RC.get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(ray_dir)
        ray_stop_wu = agent_position + dist * ray_dir
        ray_stop_pu = wu_to_pu(ray_stop_wu)
        RC.draw_line!(tv, ray_start_pu..., ray_stop_pu..., red)

    end

    return nothing
end

function draw_rays_av()
    agent_position = agent.position
    agent_direction = agent.direction
    ray_dirs = RC.get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = cast_ray(ray_dir)

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

function cast_ray(ray_dir)
    pos_x, pos_y = agent.position
    map_x = wu_to_tu(pos_x) - 1
    map_y = wu_to_tu(pos_y) - 1

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

        hit_pos_tu = map_to_tu((map_x, map_y))
        if tm[GW.WALL, hit_pos_tu...] || tm[GW.GOAL, hit_pos_tu...]
            hit = 1
        end
    end

    return dist, side, hit_pos_tu
end

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        display(key)
        println()

        if key == MFB.KB_KEY_UP
            new_position = agent.position + position_increment * agent.direction
            if !is_agent_colliding(new_position)
                agent.position = new_position
            end
        elseif key == MFB.KB_KEY_DOWN
            new_position = agent.position - position_increment * agent.direction
            if !is_agent_colliding(new_position)
                agent.position = new_position
            end
        elseif key == MFB.KB_KEY_LEFT
            new_direction = RC.rotate(agent.direction, direction_increment)
            agent.direction = new_direction
            agent.camera_plane = RC.rotate_minus_90(new_direction)
        elseif key == MFB.KB_KEY_RIGHT
            new_direction = RC.rotate(agent.direction, direction_decrement)
            agent.direction = new_direction
            agent.camera_plane = RC.rotate_minus_90(new_direction)
        elseif key == MFB.KB_KEY_ESCAPE
            MFB.mfb_close(window)
        end

        draw_tile_map()
        draw_tile_map_boundaries()
        draw_agent()
        draw_agent_direction()
        draw_rays_tv()
        draw_rays_av()
    end

    return nothing
end

function render_cv()
    window = MFB.mfb_open("Combined View", width_cv_pu, height_cv_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    draw_tile_map()
    draw_tile_map_boundaries()
    draw_agent()
    draw_agent_direction()
    draw_rays_tv()
    draw_rays_av()

    while MFB.mfb_wait_sync(window)
        permutedims!(fb_cv_tv, tv, (2, 1))
        permutedims!(fb_cv_av, av, (2, 1))

        state = MFB.mfb_update(window, fb_cv)

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)

    return nothing
end

function render_tv()
    window = MFB.mfb_open("Top View", width_tv_pu, height_tv_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    draw_tile_map()
    draw_tile_map_boundaries()
    draw_agent()
    draw_agent_direction()
    draw_rays_tv()
    draw_rays_av()

    while MFB.mfb_wait_sync(window)
        permutedims!(fb_tv, tv, (2, 1))

        state = MFB.mfb_update(window, fb_tv)

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)

    return nothing
end

function render_av()
    window = MFB.mfb_open("Agent View", width_av_pu, height_av_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    draw_tile_map()
    draw_tile_map_boundaries()
    draw_agent()
    draw_agent_direction()
    draw_rays_tv()
    draw_rays_av()

    while MFB.mfb_wait_sync(window)
        permutedims!(fb_av, av, (2, 1))

        state = MFB.mfb_update(window, fb_av)

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)

    return nothing
end

render_cv()
