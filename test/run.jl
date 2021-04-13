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

const radius_wu = convert(T, 0.05)
const speed_wu = convert(T, 0.005)
const theta_change_unit = convert(T, pi / 60)
const direction_increment = SA.SVector(cos(theta_change_unit), sin(theta_change_unit))
const direction_decrement = SA.SVector(direction_increment[1], -direction_increment[2])

const agent = RC.Agent(SA.SVector(convert(T, 0.5), convert(T, 0.25)),
                 SA.SVector(convert(T, 1/sqrt(2)), convert(T, 1/sqrt(2))),
                )

# world

const height_world_wu = convert(T, 1)
const width_world_wu = convert(T, 2)

const world = RC.World(tm, height_world_wu, width_world_wu, agent)

# img

const height_img_pu = 256
const width_img_pu = 512

const img = zeros(UInt32, height_img_pu, width_img_pu)
const fb = zeros(UInt32, width_img_pu, height_img_pu)

# colors

const black = MFB.mfb_rgb(0, 0, 0)
const white = MFB.mfb_rgb(255, 255, 255)
const gray = MFB.mfb_rgb(127, 127, 127)
const red = MFB.mfb_rgb(255, 0, 0)
const green = MFB.mfb_rgb(0, 255, 0)
const blue = MFB.mfb_rgb(0, 0, 255)

# extras

const pu_per_wu = height_img_pu / height_world_wu
const pu_per_tu = height_img_pu ÷ height_tm_tu
const tu_per_wu = height_tm_tu / height_world_wu

# main

get_start_pu(i_tu::Integer) = (i_tu - 1) * pu_per_tu + 1
get_start_pu(x_wu::AbstractFloat) = floor(Int, x_wu * pu_per_wu)
get_start_tu(i_pu::Integer) = (i_pu - 1) ÷ pu_per_tu + 1
get_start_tu(x_wu::AbstractFloat) = floor(Int, x_wu * tu_per_wu)

const radius_pu = get_start_pu(radius_wu)
const d = 2 * radius_pu - 1

get_agent_position_pu() = (get_start_pu(height_world_wu - agent.position[2]), get_start_pu(agent.position[1]))

function draw_tile_map()
    map(CartesianIndices((1:height_tm_tu, 1:width_tm_tu))) do pos
        if tm[GW.WALL, pos]
            i, j = pos.I
            start_i = get_start_pu(i)
            start_j = get_start_pu(j)
            stop_i = start_i + pu_per_tu - 1
            stop_j = start_j + pu_per_tu - 1
            img[start_i:stop_i, start_j:stop_j] .= white
        end

        return nothing
    end

    return nothing
end

function draw_agent()
    center_i, center_j = get_agent_position_pu()
    start_i = center_i - radius_pu + 1
    start_j = center_j - radius_pu + 1
    stop_i = start_i + d - 1
    stop_j = start_j + d - 1

    map(CartesianIndices((start_i:stop_i, start_j:stop_j))) do pos
        i, j = pos.I

        if (i - center_i) ^ 2 + (j - center_j) ^ 2 <= radius_pu ^ 2
            img[pos] = gray
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
        img[i0, j0] = green

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
    center_i, center_j = get_agent_position_pu()
    stop_i = get_start_pu(height_world_wu - (agent.position[2] + radius_wu * agent.direction[2] / 2))
    stop_j = get_start_pu(agent.position[1] + radius_wu * agent.direction[1] / 2)
    draw_line(center_i, center_j, stop_i, stop_j)
end

function clear_agent()
    center_i, center_j = get_agent_position_pu()
    start_i = center_i - radius_pu + 1
    start_j = center_j - radius_pu + 1
    stop_i = start_i + d - 1
    stop_j = start_j + d - 1
    img[start_i:stop_i, start_j:stop_j] .= black

    return nothing
end

function keyboard_callback(window, key, mod, isPressed)::Cvoid
    if isPressed
        display(key)
        println()

        clear_agent()

        if key == MFB.KB_KEY_UP
            agent.position = agent.position + speed_wu * agent.direction
        elseif key == MFB.KB_KEY_DOWN
            agent.position = agent.position - speed_wu * agent.direction
        elseif key == MFB.KB_KEY_LEFT
            agent.direction = RC.rotate(agent.direction, direction_increment)
        elseif key == MFB.KB_KEY_RIGHT
            agent.direction = RC.rotate(agent.direction, direction_decrement)
        elseif key == MFB.KB_KEY_ESCAPE
            MFB.mfb_close(window)
        end

        draw_agent()
        draw_agent_direction()
    end

    return nothing
end

function render()
    window = MFB.mfb_open("Test", width_img_pu, height_img_pu)
    MFB.mfb_set_keyboard_callback(window, keyboard_callback)

    draw_tile_map()
    draw_agent()
    draw_agent_direction()

    while MFB.mfb_wait_sync(window)

        state = MFB.mfb_update(window, permutedims!(fb, img, (2, 1)))

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)
end

render()
