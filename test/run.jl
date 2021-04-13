import RayCaster as RC
import StaticArrays as SA
import MiniFB as MFB
import GridWorlds as GW

const T = Float32

# tile map

const height_tm_tu = 16
const width_tm_tu = 8

const tm = RC.generate_tile_map(height_tm_tu, width_tm_tu)

# agent

const radius_wu = convert(T, 0.025)
const speed_wu = convert(T, 0.01)

const agent = RC.Agent(SA.SVector(convert(T, 0.5), convert(T, 0.5)),
                 SA.SVector(convert(T, 1/sqrt(2)), convert(T, 1/sqrt(2))),
                 speed_wu,
                 radius_wu,
                )

# world

const height_world_wu = convert(T, 2)
const width_world_wu = convert(T, 1)

const world = RC.World(tm, height_world_wu, width_world_wu, agent)

# img

const height_img_pu = 512
const width_img_pu = 256

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

function render()
    window = MFB.mfb_open("Test", width_img_pu, height_img_pu)

    draw_tile_map()

    while MFB.mfb_wait_sync(window)

        state = MFB.mfb_update(window, permutedims!(fb, img, (2, 1)))

        if state != MFB.STATE_OK
            break;
        end
    end

    MFB.mfb_close(window)
end

render()
