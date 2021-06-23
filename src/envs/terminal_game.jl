module TerminalGame

import ..Play
import ..RayCastWorlds as RCW
import REPL
import SimpleDraw as SD
import StaticArrays as SA

const NUM_OBJECTS = 2
const WALL = 1
const BACKROUND = 2
const OBJECT_CHARACTERS = (RCW.BLOCK_FULL_SHADED, RCW.BLOCK_QUARTER_SHADED)

const NUM_ACTIONS = 4
const MOVE_FORWARD = 1
const MOVE_BACKWARD = 2
const TURN_LEFT = 3
const TURN_RIGHT = 4
const ACTION_CHARACTERS = ('w', 's', 'a', 'd')

const NUM_VIEWS = 2
const CAMERA_VIEW = 1
const TOP_VIEW = 2

struct Game{T}
    tile_map::BitArray{3}
    num_directions::Int

    player_position_wu::SA.MVector{2, T}
    player_direction_au::Ref{Int}
    player_radius_wu::T
    position_increment_wu::T

    field_of_view_au::Int
    top_view::Array{Char, 2}
    camera_view::Array{Char, 2}

    directions_wu::Array{T, 2}
end

function Game(;
        T = Float32,
        height_tile_map_tu = 8,
        width_tile_map_tu = 8,
        num_directions = 128, # angles go from 0 to num_directions - 1 (0 corresponding to positive x-axes)
        field_of_view_au = isodd(num_directions ÷ 6) ? num_directions ÷ 6 : (num_directions ÷ 6) + 1 ,

        player_position_wu = SA.MVector(convert(T, height_tile_map_tu / 2), convert(T, width_tile_map_tu / 2)),
        player_direction_au = num_directions ÷ 8,
        player_radius_wu = convert(T, 1 / 8), # should be less than 0.5
        position_increment_wu = convert(T, 1 / 8),

        pu_per_tu = 4,
    )

    @assert isodd(field_of_view_au)


    tile_map = falses(NUM_OBJECTS, height_tile_map_tu, width_tile_map_tu)

    tile_map[BACKROUND, :, :] .= true

    tile_map[WALL, :, 1] .= true
    tile_map[WALL, :, width_tile_map_tu] .= true
    tile_map[WALL, 1, :] .= true
    tile_map[WALL, height_tile_map_tu, :] .= true


    top_view = Array{Char}(undef, height_tile_map_tu * pu_per_tu, width_tile_map_tu * pu_per_tu)
    camera_view = Array{Char}(undef, field_of_view_au, field_of_view_au)

    directions_wu = Array{T}(undef, 2, num_directions)
    for i in 1:num_directions
        theta = (i - 1) * 2 * pi / num_directions
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

    RCW.draw_tile_map!(top_view, tile_map, OBJECT_CHARACTERS)

    i_player_position_pu, j_player_position_pu = RCW.wu_to_pu.(game.player_position_wu, pu_per_tu)
    player_radius_pu = RCW.wu_to_pu(game.player_radius_wu, pu_per_tu)

    SD.draw!(top_view, SD.Circle(i_player_position_pu, j_player_position_pu, player_radius_pu), RCW.BLOCK_THREE_QUARTER_SHADED)

    ray_draw_string = RCW.BLOCK_HALF_SHADED
    obstacle_map = @view tile_map[WALL, :, :]

    player_direction_au = game.player_direction_au[]
    player_direction_wu = @view game.directions_wu[:, player_direction_au + 1]
    field_of_view_start_au = player_direction_au - (game.field_of_view_au - 1) ÷ 2
    field_of_view_end_au = player_direction_au + (game.field_of_view_au - 1) ÷ 2

    color_floor = RCW.BLOCK_FULL_SHADED
    color_wall_dim_1 = RCW.BLOCK_THREE_QUARTER_SHADED
    color_wall_dim_2 = RCW.BLOCK_HALF_SHADED
    color_ceiling = RCW.BLOCK_QUARTER_SHADED

    for (i, theta_au) in enumerate(field_of_view_start_au:field_of_view_end_au)
        idx = mod(theta_au, game.num_directions) + 1
        ray_direction_wu = @view game.directions_wu[:, idx]
        side_dist_wu, hit_dimension, i_hit_tu, j_hit_tu = RCW.cast_ray(obstacle_map, game.player_position_wu, ray_direction_wu)

        # top_view
        i_ray_stop_pu, j_ray_stop_pu = RCW.wu_to_pu.(game.player_position_wu + side_dist_wu * ray_direction_wu, pu_per_tu)

        SD.draw!(top_view, SD.Line(i_player_position_pu, j_player_position_pu, i_ray_stop_pu, j_ray_stop_pu), ray_draw_string)

        # camera_view
        perp_dist = side_dist_wu * sum(player_direction_wu .* ray_direction_wu)
        height_line_pu = floor(Int, height_camera_view_pu / perp_dist)

        if hit_dimension == 1
            color = color_wall_dim_1
        elseif hit_dimension == 2
            color = color_wall_dim_2
        end

        k = width_camera_view_pu - i + 1

        if height_line_pu >= height_camera_view_pu - 1
            camera_view[:, k] .= color
        else
            padding_pu = (height_camera_view_pu - height_line_pu) ÷ 2
            camera_view[1:padding_pu, k] .= color_ceiling
            camera_view[padding_pu + 1 : end - padding_pu, k] .= color
            camera_view[end - padding_pu + 1 : end, k] .= color_floor
        end
    end

    return nothing
end

function step!(game::Game, action::Int)
    if action == MOVE_FORWARD
        player_direction_wu = @view game.directions_wu[:, game.player_direction_au[] + 1]
        new_player_position_wu = game.player_position_wu + game.position_increment_wu * player_direction_wu
        obstacle_map = @view game.tile_map[WALL, :, :]
        if !RCW.is_player_colliding(obstacle_map, new_player_position_wu, game.player_radius_wu)
            game.player_position_wu .= new_player_position_wu
        end
    elseif action == MOVE_BACKWARD
        player_direction_wu = @view game.directions_wu[:, game.player_direction_au[] + 1]
        new_player_position_wu .= game.player_position_wu - game.position_increment_wu * player_direction_wu
        obstacle_map = @view game.tile_map[WALL, :, :]
        if !RCW.is_player_colliding(obstacle_map, new_player_position_wu, game.player_radius_wu)
            game.player_position_wu .= new_player_position_wu
        end
    elseif action == TURN_LEFT
        game.player_direction_au[] = mod(game.player_direction_au[] + 1, game.num_directions)
    elseif action == TURN_RIGHT
        game.player_direction_au[] = mod(game.player_direction_au[] - 1, game.num_directions)
    end

    return nothing
end

function play!(terminal::REPL.Terminals.UnixTerminal, game::Game; file_name::Union{Nothing, AbstractString} = nothing)
    REPL.Terminals.raw!(terminal, true)

    terminal_out = terminal.out_stream
    terminal_in = terminal.in_stream
    file = Play.open_maybe(file_name)

    Play.write_io1_maybe_io2(terminal_out, file, Play.CLEAR_SCREEN)
    Play.write_io1_maybe_io2(terminal_out, file, Play.MOVE_CURSOR_TO_ORIGIN)
    Play.write_io1_maybe_io2(terminal_out, file, Play.HIDE_CURSOR)

    update_drawings!(game)

    current_view = CAMERA_VIEW
    can_overwrite_view = true

    try
        while true
            if current_view == TOP_VIEW
                Play.show_image_block_pixels_io1_maybe_io2(terminal_out, file, MIME("text/plain"), game.top_view)
            else
                Play.show_image_block_pixels_io1_maybe_io2(terminal_out, file, MIME("text/plain"), game.camera_view)
            end

            char = read(terminal_in, Char)

            if char == 'q'
                Play.write_io1_maybe_io2(terminal_out, file, Play.SHOW_CURSOR)
                Play.close_maybe(file)
                REPL.Terminals.raw!(terminal, false)
                return nothing
            elseif char == 'v'
                current_view = mod1(current_view + 1, NUM_VIEWS)
                Play.write_io1_maybe_io2(terminal_out, file, Play.CLEAR_SCREEN_BEFORE_CURSOR)
            elseif char in ACTION_CHARACTERS
                step!(game, findfirst(==(char), ACTION_CHARACTERS))
                update_drawings!(game)
            end

            Play.write_io1_maybe_io2(terminal_out, file, Play.MOVE_CURSOR_TO_ORIGIN)
        end
    finally
        Play.write_io1_maybe_io2(terminal_out, file, Play.SHOW_CURSOR)
        Play.close_maybe(file)
        REPL.Terminals.raw!(terminal, false)
    end

    return nothing
end

play!(game::Game; file_name = nothing) = play!(REPL.TerminalMenus.terminal, game, file_name = file_name)

end # module
