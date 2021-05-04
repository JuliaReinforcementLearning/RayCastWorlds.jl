rotate(x, y, c, s) = (c * x - s * y, s * x + c * y)
rotate(vec::SA.SVector, dir::SA.SVector) = SA.SVector(rotate(vec[1], vec[2], dir[1], dir[2]))
rotate_plus_90(vec::SA.SVector) = SA.SVector(-vec[2], vec[1])
rotate_minus_90(vec::SA.SVector) = SA.SVector(vec[2], -vec[1])
rotate_180(vec::SA.SVector) = -vec

struct StdSquare{T}
    half_side::T
end

get_half_side(square::StdSquare) = square.half_side

struct StdCircle{T}
    radius::T
end

get_radius(circle::StdCircle) = circle.radius

function get_projection(square::StdSquare, pos::SA.SVector)
    half_side = get_half_side(square)
    return clamp.(pos, -half_side, half_side)
end

function is_colliding(square::StdSquare, circle::StdCircle, pos::SA.SVector)
    projection = get_projection(square, pos)
    vec = pos - projection
    radius = get_radius(circle)
    return sum(vec .^ 2) < radius * radius
end

function get_rays(dir::SA.SVector, semi_fov, num_rays)
    angle = atan(dir[2], dir[1])
    return map(theta -> SA.SVector(cos(theta), sin(theta)), range(angle - semi_fov, angle + semi_fov, length = num_rays))
end
