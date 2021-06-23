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
