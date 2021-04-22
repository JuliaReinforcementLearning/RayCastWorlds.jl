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
