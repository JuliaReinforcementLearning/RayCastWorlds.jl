import RayCaster as RC
import StaticArrays as SA

const T = Float32

tile_map = RC.generate_tile_map()
agent = RC.Agent(SA.SVector(convert(T, 0.5), convert(T, 0.5)),
                 SA.SVector(convert(T, 1/sqrt(2)), convert(T, 1/sqrt(2))),
                 convert(T, 0.01),
                 convert(T, 0.025))
world = RC.World(tile_map, convert(T, 1), convert(T, 1), agent)

RC.render_world(world, 512, 512)
