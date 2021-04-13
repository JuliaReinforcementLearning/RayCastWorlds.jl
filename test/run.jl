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

# units

const pu_per_wu = height_img_pu / height_world_wu
const tu_per_wu = height_tm_tu / height_world_wu
const pu_per_tu = height_img_pu ÷ height_tm_tu

wu_to_pu(x_wu::AbstractFloat) = floor(Int, x_wu * pu_per_wu) + 1
wu_to_tu(x_wu::AbstractFloat) = floor(Int, x_wu * tu_per_wu) + 1
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

get_agent_center_pu() = (wu_to_pu(height_world_wu - agent.position[2]), wu_to_pu(agent.position[1]))
get_agent_top_left_pu(center_pu) = center_pu .- (radius_pu - 1)
get_agent_bottom_right_pu(center_pu) = center_pu .+ (radius_pu - 1)
function get_agent_region_pu(center_pu)
    start_i, start_j = get_agent_top_left_pu(center_pu)
    stop_i, stop_j = get_agent_bottom_right_pu(center_pu)
    return CartesianIndices((start_i:stop_i, start_j:stop_j))
end
get_agent_region_pu() = get_agent_region_pu(get_agent_center_pu())

# main

function draw_tile_map()
    map(get_tile_map_region_tu()) do pos
        if tm[GW.WALL, pos]
            img[get_tile_region_pu(pos.I)] .= white
        end
        return nothing
    end

    return nothing
end

function draw_agent()
    center_pu = get_agent_center_pu()

    map(get_agent_region_pu(center_pu)) do pos
        if sum((pos.I .- center_pu) .^ 2) <= radius_pu ^ 2
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
    i0, j0 = get_agent_center_pu()
    i1 = wu_to_pu(height_world_wu - (agent.position[2] + radius_wu * agent.direction[2] / 2))
    j1 = wu_to_pu(agent.position[1] + radius_wu * agent.direction[1] / 2)
    draw_line(i0, j0, i1, j1)
    return nothing
end

function clear_agent()
    img[get_agent_region_pu()] .= black
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

    return nothing
end

render()
