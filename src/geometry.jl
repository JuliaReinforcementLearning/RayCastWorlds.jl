rotate(x, y, c, s) = (c * x - s * y, s * x + c * y)
rotate(position::SA.SVector, direction::SA.SVector) = SA.SVector(rotate(position[1], position[2], direction[1], direction[2]))
rotate_plus_90(position::SA.SVector) = SA.SVector(-position[2], position[1])
rotate_minus_90(position::SA.SVector) = SA.SVector(position[2], -position[1])
rotate_180(position::SA.SVector) = -position

struct StdSquare{T}
    half_side::T
end

get_half_side(square::StdSquare) = square.half_side

struct StdCircle{T}
    radius::T
end

get_radius(circle::StdCircle) = circle.radius

function get_projection(square::StdSquare, position::SA.SVector)
    half_side = get_half_side(square)
    return clamp.(position, -half_side, half_side)
end

function is_colliding(square::StdSquare, circle::StdCircle, position::SA.SVector)
    projection = get_projection(square, position)
    vec = position - projection
    radius = get_radius(circle)
    return sum(vec .^ 2) < radius * radius
end

function get_rays(direction::SA.SVector, semi_fov, num_rays)
    angle = atan(direction[2], direction[1])
    return map(theta -> SA.SVector(cos(theta), sin(theta)), range(angle - semi_fov, angle + semi_fov, length = num_rays))
end
