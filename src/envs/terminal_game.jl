module TerminalGame

import ..RayCastWorlds as RCW
import REPL
import SimpleDraw as SD
import StaticArrays as SA

const WALL = 1
const BACKROUND = 2
const NUM_OBJECTS = 2
const CHARACTERS = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)
const OBJECT_REPRESENTATIONS = (RCW.BLOCK_FULL_SHADED ^ 2, RCW.BLOCK_QUARTER_SHADED ^ 2)

const MOVE_FORWARD = 1
const MOVE_BACKWARD = 2
const TURN_LEFT = 3
const TURN_RIGHT = 4

struct Game{T}
    tile_map::BitArray{3}
    num_directions::Int

    player_position_wu::SA.MVector{2, T}
    player_direction_au::Ref{Int}
    player_radius_wu::T
    position_increment_wu::T

    field_of_view_au::Int
    num_rays::Int
    top_view::Array{String, 2}
    camera_view::Array{String, 2}

    directions_wu::Array{T, 2}
end

function Game(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 32,
        field_of_view_au = 32,
        num_rays = 32,

        player_position_wu = SA.MVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 4,
        player_radius_wu = convert(T, 1 / 8),
        position_increment_wu = convert(T, 1 / 8),

        pu_per_tu = 4,
    )

    tile_map = falses(NUM_OBJECTS, height_tile_map_tu, width_tile_map_tu)
    tile_map[BACKROUND, :, :] .= true
    tile_map[WALL, :, 1] .= true
    tile_map[WALL, :, width_tile_map_tu] .= true
    tile_map[WALL, 1, :] .= true
    tile_map[WALL, height_tile_map_tu, :] .= true

    top_view = Array{String}(undef, height_tile_map_tu * pu_per_tu, width_tile_map_tu * pu_per_tu)
    camera_view = Array{String}(undef, num_rays, num_rays)

    directions_wu = Array{T}(undef, 2, num_directions)
    for i in 1:num_directions
        theta = i * 2 * pi / num_directions
        directions_wu[1, i] = convert(T, cos(theta))
        directions_wu[2, i] = convert(T, sin(theta))
    end

    game = Game(tile_map,
                num_directions,
                player_position_wu,
                Ref(player_direction_au),
                player_radius_wu,
                position_increment_wu,
                field_of_view_au,
                num_rays,
                top_view,
                camera_view,
                directions_wu,
               )

    return game
end

function update_drawings!(game::Game)
    tile_map = game.tile_map
    top_view = game.top_view
    camera_view = game.camera_view

    height_tile_map_tu, width_tile_map_tu = size(tile_map, 2), size(tile_map, 3)
    height_top_view_pu, width_top_view_pu = size(top_view)
    height_camera_view_pu, width_camera_view_pu = size(camera_view)

    pu_per_tu = height_top_view_pu ÷ height_tile_map_tu

    RCW.draw_tile_map!(top_view, tile_map, OBJECT_REPRESENTATIONS)

    i_player_position_pu, j_player_position_pu = RCW.wu_to_pu.(game.player_position_wu, pu_per_tu)
    player_radius_pu = RCW.wu_to_pu(game.player_radius_wu, pu_per_tu)

    SD.draw!(top_view, SD.Circle(i_player_position_pu, j_player_position_pu, player_radius_pu), RCW.BLOCK_THREE_QUARTER_SHADED ^ 2)

    ray_draw_string = RCW.BLOCK_HALF_SHADED ^ 2
    obstacle_map = @view tile_map[WALL, :, :]

    for (i, direction_wu) in enumerate(game.directions[1:8])
        side_dist_wu, hit_side, i_hit_position_tu, j_hit_position_tu = RCW.cast_ray(obstacle_map, game.player_position_wu, direction_wu)
        # x_ray_stop_wu, y_ray_stop_wu = game.player_position_wu + side_dist * direction_wu

        # i_ray_stop_pu = floor(Int, ray_stop_x * pu_per_tu) + 1
        # j_ray_stop_pu = floor(Int, (height_tile_map - ray_stop_y) * pu_per_tu) + 1

        i_ray_stop_pu, j_ray_stop_pu = RCW.wu_to_pu.(game.player_position_wu + side_dist * direction_wu)

        SD.draw!(top_view, SD.Line(i_player_position_pu, j_player_position_pu, i_ray_stop_pu, j_ray_stop_pu), ray_draw_string)
    end

    # for i in 1:height_top_view
        # for j in 1:width_top_view
            # print(io, top_view[i, j])
        # end

        # if i < height_top_view
            # print(io, "\n")
        # end
    # end

    return nothing
end

function print_image(io::IO, image)
    height, width = size(image)

    for i in 1:height
        for j in 1:width
            print(io, image[i, j])
        end

        if i < height
            print(io, "\n")
        end
    end

    return nothing
end

function print_tile_map(io::IO, game::Game)
    tile_map = game.tile_map
    num_objects, height, width = size(tile_map)

    image = Array{String}(undef, height, width)

    RCW.draw_tile_map!(image, tile_map, OBJECT_REPRESENTATIONS)

    print_image(io, image)

    return nothing
end

end # module
