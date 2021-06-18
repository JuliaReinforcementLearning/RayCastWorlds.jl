module TerminalGame

import ..RayCastWorlds as RCW
import REPL
import StaticArrays as SA

const WALL = 1
const BACKROUND = 2
const NUM_OBJECTS = 2
const CHARACTERS = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)

const MOVE_FORWARD = 1
const MOVE_BACKWARD = 2
const TURN_LEFT = 3
const TURN_RIGHT = 4

struct Game{T}
    tile_map::BitArray{3}
    num_directions::Int

    player_position::SA.MVector{2, T}
    player_direction::Ref{Int}
    player_radius::T
    position_increment::T

    field_of_view::Int
    top_view::Array{Char, 2}
    camera_view::Array{Char, 2}
end

function Game(;
        T = Float32,
        height_tile_map = 8,
        width_tile_map = 8,
        num_directions = 256,
        field_of_view = 32,

        player_position = SA.MVector(convert(T, height_tile_map / 2), convert(T, width_tile_map / 2)),
        player_direction = num_directions ÷ 4,
        player_radius = convert(T, 1 / 4),
        position_increment = convert(T, 1 / 8),

        pu_per_tu = 4,
    )

    tile_map = falses(NUM_OBJECTS, height_tile_map, width_tile_map)
    tile_map[BACKROUND, :, :] .= true
    tile_map[WALL, :, 1] .= true
    tile_map[WALL, :, width_tile_map] .= true
    tile_map[WALL, 1, :] .= true
    tile_map[WALL, height_tile_map, :] .= true

    top_view = Array{Char}(undef, height_tile_map * pu_per_tu, width_tile_map * pu_per_tu)
    camera_view = Array{Char}(undef, field_of_view * pu_per_tu, field_of_view * pu_per_tu)

    game = Game(tile_map,
                num_directions,
                player_position,
                player_direction,
                player_radius,
                position_increment,
                field_of_view,
                top_view,
                camera_view,
               )

    return game
end

function Base.show(io::IO, ::MIME"text/plain", game::Game)
    tile_map = game.tile_map
    num_objects, height, width = size(tile_map)

    for i in 1:height
        for j in 1:width
            object_id = findfirst(@view tile_map[:, i, j])
            print(io, CHARACTERS[object_id])
        end

        if i < height
            print(io, "\n")
        end
    end

    return nothing
end

end # module
