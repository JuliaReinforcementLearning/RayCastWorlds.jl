import GridWorlds as GW
import MiniFB as MFB
import RayCaster as RC
import StaticArrays as SA
import ReinforcementLearningBase as RLBase

const T = Float32

include("config.jl")

# units

const pu_per_wu = pu_per_tu / wu_per_tu

# tile map

const height_tm_tu = size(tm_layout, 1)
const width_tm_tu = size(tm_layout, 2)

const tm = RC.generate_tile_map(tm_layout)

# agent

const direction_increment = SA.SVector(cos(theta_increment), sin(theta_increment))
const direction_decrement = SA.SVector(direction_increment[1], -direction_increment[2])

camera_plane = RC.rotate_minus_90(agent_direction)

const agent = RC.Agent(agent_position,
                       agent_direction,
                       camera_plane,
                      )

const circle = RC.StdCircle(radius_wu)

# world

const height_world_wu = convert(T, height_tm_tu * wu_per_tu)
const width_world_wu = convert(T, width_tm_tu * wu_per_tu)

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

# agent region

const radius_pu = RC.wu_to_pu(radius_wu, pu_per_wu)

# main

function is_agent_colliding(tm, center_wu, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu)
    height_tm_tu = size(tm, 2)
    square = RC.StdSquare(tile_half_side_wu)
    circle = RC.StdCircle(radius_wu)
    return any(pos -> (tm[GW.WALL, pos] || tm[GW.GOAL, pos]) && RC.is_colliding(square, circle, center_wu .- RC.get_tile_center_wu(pos.I, wu_per_tu, height_tm_tu, tile_half_side_wu)), RC.get_agent_region_tu(center_wu, radius_wu, wu_per_tu, height_world_wu))
end

function draw_rays_tv()
    ray_start_pu = RC.get_agent_center_pu(agent.position, pu_per_wu, height_world_wu)
    agent_position = agent.position
    agent_direction = agent.direction
    ray_dirs = RC.get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = RC.cast_ray(tm, ray_dir, agent_position, wu_per_tu)
        ray_stop_wu = agent_position + dist * ray_dir
        ray_stop_pu = RC.wu_to_pu(ray_stop_wu, pu_per_wu, height_world_wu)
        RC.draw_line!(tv, ray_start_pu..., ray_stop_pu..., RC.red)
    end

    return nothing
end

function draw_av()
    agent_position = agent.position
    agent_direction = agent.direction
    ray_dirs = RC.get_rays(agent_direction, semi_fov, num_rays)

    for (ray_idx, ray_dir) in enumerate(ray_dirs)
        dist, side, hit_pos_tu = RC.cast_ray(tm, ray_dir, agent_position, wu_per_tu)

        per_dist = dist * sum(agent_direction .* ray_dir)
        height_line_pu = floor(Int, height_av_pu / per_dist)

        idx = num_rays - ray_idx + 1

        if tm[GW.WALL, hit_pos_tu...] && side == 1
            color = RC.dark_gray
        elseif tm[GW.WALL, hit_pos_tu...] && side == 0
            color = RC.gray
        elseif tm[GW.GOAL, hit_pos_tu...] && side == 1
            color = RC.dark_blue
        elseif tm[GW.GOAL, hit_pos_tu...] && side == 0
            color = RC.blue
        end

        if height_line_pu >= height_av_pu - 1
            av[:, idx] .= color
        else
            padding_pu = (height_av_pu - height_line_pu) ÷ 2
            av[1:padding_pu, idx] .= RC.white
            av[padding_pu + 1 : end - padding_pu, idx] .= color
            av[end - padding_pu + 1 : end, idx] .= RC.black
        end
    end

    return nothing
end

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        display(key)
        println()

        if key == MFB.KB_KEY_UP
            new_position = agent.position + position_increment * agent.direction
            if !is_agent_colliding(tm, new_position, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu)
                agent.position = new_position
            end
        elseif key == MFB.KB_KEY_DOWN
            new_position = agent.position - position_increment * agent.direction
            if !is_agent_colliding(tm, new_position, wu_per_tu, tile_half_side_wu, radius_wu, height_world_wu)
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

        RC.draw_tile_map!(tv, tm)
        RC.draw_tile_map_boundaries!(tv, pu_per_tu, RC.gray)
        # draw_agent
        RC.draw_circle!(tv, RC.get_agent_center_pu(agent.position, pu_per_wu, height_world_wu)..., radius_pu, RC.green)
        draw_rays_tv()
        draw_av()
    end

    return nothing
end

function render_cv()
    window = MFB.mfb_open("Combined View", width_cv_pu, height_cv_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    RC.draw_tile_map!(tv, tm)
    RC.draw_tile_map_boundaries!(tv, pu_per_tu, RC.gray)
    # draw_agent
    RC.draw_circle!(tv, RC.get_agent_center_pu(agent.position, pu_per_wu, height_world_wu)..., radius_pu, RC.green)
    draw_rays_tv()
    draw_av()

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

    RC.draw_tile_map!(tv, tm)
    RC.draw_tile_map_boundaries!(tv, pu_per_tu, RC.gray)
    # draw_agent
    RC.draw_circle!(tv, RC.get_agent_center_pu(agent.position, pu_per_wu, height_world_wu)..., radius_pu, RC.green)
    draw_rays_tv()
    draw_av()

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

    RC.draw_tile_map!(tv, tm)
    RC.draw_tile_map_boundaries!(tv, pu_per_tu, RC.gray)
    # draw_agent
    RC.draw_circle!(tv, RC.get_agent_center_pu(agent.position, pu_per_wu, height_world_wu)..., radius_pu, RC.green)
    draw_rays_tv()
    draw_av()

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
