import RayCaster as RC
import StaticArrays as SA

const T = Float32

world = RC.generate_world()
agent = RC.Agent(SA.SVector(convert(T, 0.5), convert(T, 0.5)),
                 SA.SVector(convert(T, 1/sqrt(2)), convert(T, 1/sqrt(2))),
                 convert(T, 0.01),
                 convert(T, 0.025))
env = RC.Environment(world, convert(T, 1), convert(T, 1), agent)

RC.render_env(env, 512, 512)
