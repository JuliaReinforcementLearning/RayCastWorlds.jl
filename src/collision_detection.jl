struct StdSquare{T}
    half_side::T
end

struct StdCircle{T}
    radius::T
end

function get_projection(square::StdSquare, position::AbstractVector)
    half_side = square.half_side
    return clamp.(position, -half_side, half_side)
end

function is_colliding(square::StdSquare, circle::StdCircle, position::AbstractVector)
    projection = get_projection(square, position)
    vec = position .- projection
    radius = circle.radius
    return sum(vec .^ 2) < radius * radius
end

function is_player_colliding(obstacle_map, player_position_wu, player_radius_wu::T) where {T}
    height_tile_map_tu, width_tile_map_tu = size(obstacle_map)

    square = StdSquare(convert(T, 0.5))
    circle = StdCircle(player_radius_wu)

    i_player_position_tu = wu_to_tu(player_position_wu[1])
    j_player_position_tu = wu_to_tu(player_position_wu[2])

    for j in j_player_position_tu - 1 : j_player_position_tu + 1
        for i in i_player_position_tu - 1 : i_player_position_tu + 1
            tile_position_wu = similar(player_position_wu)
            tile_position_wu[1] = i - convert(T, 0.5)
            tile_position_wu[2] = j - convert(T, 0.5)
            if obstacle_map[i, j] && is_colliding(square, circle, player_position_wu .- tile_position_wu)
                return true
            end
        end
    end

    return false
end
