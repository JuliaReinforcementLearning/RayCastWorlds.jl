import GridWorlds as GW
import MiniFB as MFB
import RayCaster as RC
import StaticArrays as SA

const T = Float32

# tile map

const height_tm_tu = 8
const width_tm_tu = 16

const tm = RC.generate_tile_map(height_tm_tu, width_tm_tu)

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

# rays

const num_rays = 5
const semi_fov = convert(T, pi / 6)

function get_rays()
    agent_direction = agent.direction
    agent_angle = atan(agent_direction[2], agent_direction[1])
    return map(theta -> SA.SVector(cos(theta), sin(theta)), range(agent_angle - semi_fov, agent_angle + semi_fov, length = num_rays))
end

# world

const height_world_wu = convert(T, 8)
const width_world_wu = convert(T, 16)

const world = RC.World(tm, height_world_wu, width_world_wu, agent)

# img

const height_tv_pu = 256
const width_tv_pu = 512

const width_av_pu = 8 * num_rays

const height_fb_pu = height_tv_pu
const width_fb_pu = width_tv_pu + width_av_pu

const img = zeros(UInt32, height_fb_pu, width_fb_pu)
const tv = view(img, :, 1:width_tv_pu)
const av = view(img, :, width_tv_pu + 1 : width_fb_pu)
const fb = zeros(UInt32, width_fb_pu, height_fb_pu)

# colors

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const red = MFB.mfb_rgb(255, 0, 0)
const green = MFB.mfb_rgb(0, 255, 0)
const blue = MFB.mfb_rgb(0, 0, 255)

# units

const pu_per_wu = height_tv_pu / height_world_wu
const tu_per_wu = height_tm_tu / height_world_wu
const pu_per_tu = height_tv_pu ÷ height_tm_tu

wu_to_pu(x_wu::AbstractFloat) = floor(Int, x_wu * pu_per_wu) + 1
wu_to_pu((x_wu, y_wu)) = (wu_to_pu(height_world_wu - y_wu), wu_to_pu(x_wu))
wu_to_tu(x_wu::AbstractFloat) = floor(Int, x_wu * tu_per_wu) + 1
wu_to_tu((x_wu, y_wu)) = (wu_to_tu(height_world_wu - y_wu), wu_to_tu(x_wu))
pu_to_tu(i_pu::Integer) = (i_pu - 1) ÷ pu_per_tu + 1

# tile map region

get_tile_map_region_tu() = CartesianIndices((1:height_tm_tu, 1:width_tm_tu))

# tile region

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

# main

function clear_screen()
    tv[:, :] .= black
    return nothing
end

function draw_tile_map()
    map(get_tile_map_region_tu()) do pos
        if tm[GW.WALL, pos]
            tv[get_tile_region_pu(pos.I)] .= white
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

function draw_agent()
    center_pu = get_agent_center_pu()

    map(get_agent_region_pu(center_pu)) do pos
        if sum((pos.I .- center_pu) .^ 2) <= radius_pu ^ 2
            tv[pos] = green
        end
        return nothing
    end

    return nothing
end

# Ref: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
function draw_line(i0::Int, j0::Int, i1::Int, j1::Int)
    di = abs(i1-i0)
    dj = -abs(j1-j0)
    si = i0<i1 ? 1 : -1
    sj = j0<j1 ? 1 : -1
    err = di+dj

    while true
        tv[i0, j0] = red

        if (i0 == i1 && j0 == j1)
            break
        end

        e2 = 2*err

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

function draw_agent_direction()
    i0, j0 = get_agent_center_pu()
    i1 = wu_to_pu(height_world_wu - (agent.position[2] + radius_wu * agent.direction[2] / 2))
    j1 = wu_to_pu(agent.position[1] + radius_wu * agent.direction[1] * 3 / 4)
    draw_line(i0, j0, i1, j1)
    return nothing
end

function clear_agent()
    tv[get_agent_region_pu()] .= black
    return nothing
end

function is_agent_colliding(center_wu)
    x_wu, y_wu = center_wu
    return tm[GW.WALL, wu_to_tu((x_wu + radius_wu, y_wu))...] || tm[GW.WALL, wu_to_tu((x_wu, y_wu + radius_wu))...] || tm[GW.WALL, wu_to_tu((x_wu - radius_wu, y_wu))...] || tm[GW.WALL, wu_to_tu((x_wu, y_wu - radius_wu))...]
end

map_to_tu((map_x, map_y)) = (height_tm_tu - map_y, map_x + 1)

cast_rays() = map(ray -> cast_ray(ray), get_rays())

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

        if tm[GW.WALL, map_to_tu((map_x, map_y))...]
            hit = 1
        end
    end

    ray_start_pu = get_agent_center_pu()
    ray_stop_pu = wu_to_pu(agent.position + dist * ray_dir)
    draw_line(ray_start_pu..., ray_stop_pu...)

    return nothing
end

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        display(key)
        println()

        clear_screen()

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
        cast_rays()
    end

    return nothing
end

function render()
    window = MFB.mfb_open("Test", width_fb_pu, height_fb_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    draw_tile_map()
    draw_tile_map_boundaries()
    draw_agent()
    draw_agent_direction()
    cast_rays()
    av[:, :] .= blue

    while MFB.mfb_wait_sync(window)
        state = MFB.mfb_update(window, permutedims!(fb, img, (2, 1)))

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)

    return nothing
end

render()
