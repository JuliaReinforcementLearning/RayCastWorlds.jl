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
