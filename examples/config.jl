const T = Float32

const wu_per_tu = convert(T, 1)
const pu_per_tu = 32

const tm_layout = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                   1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1
                   1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1
                   1 0 0 1 0 0 0 0 1 0 0 0 0 0 2 1
                   1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1
                   1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                   1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
                   1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                  ]


const radius_wu = convert(T, 0.5)
const position_increment = convert(T, 0.05)
const theta_increment = convert(T, pi / 60)

const theta_30 = convert(T, pi / 6)
agent_direction = SA.SVector(cos(theta_30), sin(theta_30))

agent_position = SA.SVector(convert(T, 4.5), convert(T, 2.5))

const num_rays = 256
const semi_fov = convert(T, pi / 6)
