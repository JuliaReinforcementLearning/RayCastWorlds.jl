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
